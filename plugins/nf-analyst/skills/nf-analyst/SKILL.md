---
name: nf-analyst
description: Translates natural-language questions about noon's food delivery business into correct BigQuery SQL. Use this skill whenever the user asks for SQL, a query, a number, a metric, or an analysis involving noon food/order data — including GMV, AOV, active/new/repeat customers, churn, retention, sessions, funnel/conversion, bounce, outlets/restaurants/brands, hubs and cities, ratings, cancellations, discounts/burn/promo, delivery time / O2D / SLA, Noon One, Mix/Mealplan, Flash, Ping, ROD, ADMON, dashboards (Sherlock, OUT brand/venue), or any reference to tables like daily_orders, nat_events_complete, session_segments_nat, outlet_status_complete, daily_hubz_rca_nat, food_order, food_order_item, mp_order_base_mat, mealplan_daily_orders, outlet_dod_funnel. Trigger phrases include "write a SQL", "BigQuery", "how many customers", "GMV", "funnel conversion", "live outlets", "sessions", "noon food", "shawarma context".
---

# nf-analyst

Generate correct, runnable BigQuery SQL for questions about noon's food delivery business, grounded in the curated JSON context library shipped with this skill. Output SQL plus a short reasoning trail so analysts can verify which tables, columns, and rules were applied.

## Reference library

All curated context lives in `references/` as JSON files. Read them ON DEMAND — never load all at once. The files are:

| File | When to read |
|---|---|
| `01_glossary.json` | Always read first. Defines business terms (active/new/repeat customer, GMV, AOV, sessions, live outlet, churn, hub, PID, RID, etc.) and maps user phrasing to columns. |
| `02_table_registry.json` | Always read first. Lists every table, its short name, grain, primary key, partition column, and intended use. |
| `05_global_rules.json` | Always read first. Hard rules that override everything (partition filters, country-filter-per-table, live-outlet 3-filter rule, cancel-rate filter, negative-discount columns, string-typed price casting, etc.). |
| `03_table_schemas.json` | Read when you need exact column names/types for a table you've decided to use. |
| `04_metrics.json` | Read when the question names a metric (GMV, AOV, CR%, Burn, Cancel Rate, Retention, Reactivation, TPC, HPC/LPC/LVC, O2D, SLA Breach, etc.). |
| `06_examples.json` | Read after picking tables — match the user's question to the closest example for SQL patterns. |
| `07_city_hub_mapping.json` | Read when the question names a city, area, neighborhood, hub, or country (Dubai, Abu Dhabi, Business Bay, Riyadh, Jeddah, etc.). |
| `08_sherlock_dashboard.json` | Read when the user mentions Sherlock, executive dashboard, or asks for a dashboard-style breakdown. |
| `09_admon_context.json` | Read when the question mentions ADMON, ads, sponsored placements, ad revenue, or sponsored outlets. |
| `10_ping_context.json` | Read when the question mentions Ping, courier-only deliveries, or non-food logistics. |
| `11_OUT_context.json` | Read when the question mentions brands or venues from the `out` dataset (noonbifood.out.brand / noonbifood.out.venue), brand code lookups, or venue internal names. |
| `personalisation.json` | Read when the question mentions personalisation, recommendations, ranking, surface, or relevance. |
| `search_metrics.json` | Read when the question mentions search, search funnel, query, NSR, zero-results, or search conversion. |

Use the `Read` tool with the absolute path `~/.claude/plugins/nf-analyst/references/<filename>` to load a file. If that path does not exist, fall back to the path where the skill file itself lives — replace `SKILL.md` with `references/<filename>` in the skill's own directory.

## Workflow

Follow these steps in order for every request.

### 1. Classify the question

Identify the analytical intent from the user's phrasing. Common intents:

- Order / revenue / customer metrics → `daily_orders`
- Session, funnel, event behavior → `nat_events_complete`, `session_segments_nat`, or pre-aggregated `daily_hubz_rca_nat`
- Outlet/restaurant inventory or live status → `outlet_status_complete`, `temp_outlet_status`
- Logistics / delivery time → `task`, `task_timestamp`, `mp_order_base_mat`
- Item-level analysis → `daily_orders_items` (reporting layer, preferred); `food_order_item` only for item-level price arithmetic
- Finance / commission → `food_order_finance`
- Mix / mealplan → `mealplan_daily_orders`
- Ping / non-food courier → `ping_order`
- ADMON / ads → see `09_admon_context.json`
- Brand/venue lookup → see `11_OUT_context.json`
- Dashboard-style summary → see `08_sherlock_dashboard.json`
- Daily country-level funnel → `daily_rca` (pre-agg by day+country+channel)
- Outlet-level daily funnel → `outlet_dod_funnel` (pre-agg by outlet+day)
- Discount configuration / active promos → `active_discount_outlets`
- Customer nationality breakdown → `final_final_ncc`
- A/B/C segment analysis → `abc_segments`

### 2. Load context (lazy, minimum necessary)

Always read `01_glossary.json`, `02_table_registry.json`, and `05_global_rules.json` first — they are small and govern everything.

Then read the specific files implied by step 1 (schemas for chosen tables, metric definitions, examples, geo mapping if a place was named, etc.). Do NOT read files that are clearly irrelevant to the question.

### 3. Resolve the request precisely

Map every user phrase to a glossary term or column. If a phrase has ambiguity that meaningfully changes the query (e.g. "discount" could mean noon-funded burn vs. partner-funded vs. channel discount; "customers" could be active vs. registered; "last week" could be calendar week vs. trailing 7 days), ask ONE clarifying question before generating SQL. If everything is unambiguous, proceed.

### 4. Build the SQL

Write a single BigQuery SQL statement. Apply every relevant rule from `05_global_rules.json`. Common non-negotiables:

- Always filter the partition column on partitioned tables (default last 7 days if no date specified — R05).
- Use the correct country filter per table — never mix (R03).
- `order_status='delivered'` for any customer/GMV metric (R02). Cancel rate uses `IN ('delivered','canceled')`.
- Live outlets always need all three: `bq_activation_status='Activated by Ops' AND is_consumer_visible='1' AND outlet_deleted=0`. `is_consumer_visible` is STRING `'1'`, not int. Do NOT use `status='active'` — that returns wrong results (R30).
- Discount columns `bank_funded`, `noon_funded`, `rest_funded`, `Channel_discount` are stored negative — multiply by -1 or use `ABS()`. `Outlet_discount` is positive (R09).
- `food_order_item.price` is STRING — `CAST(price AS NUMERIC)` before arithmetic (R13).
- `food_order_item` is item-grain — use `COUNT(DISTINCT order_nr)` for order counts (R14).
- For hub/city funnel use pre-aggregated `daily_hubz_rca_nat` first (R07); only fall through to `nat_events_complete` for user/session-level detail.
- Bounce / move flags live in `session_segments_nat`, NOT `nat_events_complete` (R06).
- `outlet_status_complete` / `temp_outlet_status` have no partition — never add a day filter (R11).
- For inter-order gap, use timestamp `order_placed_at` (not `day`) (R12).
- For Mix product queries, ALWAYS use `noonbifood.growthv1.mealplan_daily_orders`, not `daily_orders`.
- Always use `SAFE_DIVIDE` for ratios.
- Always fully qualify tables with project.dataset.table.
- `daily_orders` has native `city` (abbreviated, e.g. `Dxb`) and `Burn` columns — no JOIN to `temp_outlet_status` needed for city-level GMV/burn queries.
- `nat_events_complete` ↔ `daily_orders` join is on `uid=customer_id` AND `day` only — do NOT add `outlet_code=restaurant_code` (that is not part of the join key).

Match the structure of the closest example in `06_examples.json` when one exists.

### 5. Output format

Reply with exactly two sections:

````
## SQL
```sql
<the BigQuery query, fully qualified, ready to paste>
```

## Reasoning
- Tables: <short_name(s) with one-line justification each>
- Metric mapping: <user phrase → column/formula>
- Rules applied: <Rxx ids from global_rules>
- Assumptions: <date range, country, granularity defaults you used>
````

Keep "Reasoning" to a tight bulleted block — usually 4–8 bullets. Do not narrate the entire workflow. Do not paste schemas. Do not include explanations the analyst doesn't need.

### 6. When to ask vs. assume

Ask ONE concise question (and only when needed) if:

- Country is not implied and the tables differ in country filter syntax.
- "Discount" / "promo" is ambiguous between noon-funded, partner-funded, channel, and outlet discount.
- The user names a metric whose denominator is non-obvious (e.g. "conversion" → session-based or order-based).
- The user names a time period that could mean calendar week/month vs. trailing N days.

Otherwise, state your assumption in the Reasoning block and proceed. Default to UAE (`country='ae'`) and trailing 7 days (`R05`) only if no other signal is present.

## Anti-patterns to avoid

- Reading every JSON file regardless of the question.
- Generating SQL without filtering the partition column on partitioned tables.
- Mixing country filters across tables (e.g. `country='ae'` on `nat_events_complete` — wrong; that table uses `locale LIKE '%ae%'`).
- Using unsuffixed event names on `nat_events_complete` (e.g. `transaction`, `page_outlet`) — both `nat_events_complete` and `raw_events_v2` use `_v2` suffixed names. Only exception: `item_impression` has no suffix.
- Computing cancel rate with `order_status='delivered'` only (returns 0%).
- Using `food_order_item` for item volume/top-item queries — always prefer `daily_orders_items` (reporting layer, correct column names). Use `food_order_item` only when you need item-level price arithmetic (`price` column, but cast to NUMERIC).
- Using wrong column names on `daily_orders_items`: item name is `Item_name`, item unit price is `Item_price`, pre-computed line total is `Total_Price`, partition is `order_date` (not `day`). `QTY` exists in the schema but is a derived column — do not use it for quantity aggregations; use `Total_Price` directly for revenue, or derive from `Item_price` if needed. No `country`/`order_status` columns on `daily_orders_items` — always JOIN `daily_orders` on `order_nr=order_id` to apply those filters (R31).
- Using `status='active'` as the live-outlet filter on `outlet_status_complete` — always use `bq_activation_status='Activated by Ops'` (R30).
- Joining `nat_events_complete` to `daily_orders` on `outlet_code=restaurant_code` — the correct join is `uid=customer_id` (+ align `day`). The `outlet_code` in events is not the same grain as `restaurant_code` in orders.
- Using `restaurant_code` as a PID/RID filter.
- Treating `is_consumer_visible` as an integer.
- Forgetting to flip the sign on `noon_funded` / `Channel_discount`.
- Using raw `$.wt` SAFE_OFFSET values in ELSE branches without `lower()` — always wrap with `lower()` (R36).
- Producing SQL plus a long essay. Keep reasoning to bullets.
- Joining `task_misc` directly to `daily_orders` — must go through `task` first (R22).
- Using `COUNT(*)` on multi-row-per-order tables (`order_discount`, `food_order_discount_detail`) — always `COUNT(DISTINCT order_nr)` (R15).
- Using `REGEXP_CONTAINS` for controlled-enum columns like `Cuisine`, `main_Cuisine`, `CRM_Cuisine`, `order_status`, `delivery_type` — these are enumerated values, use exact match: `LOWER(Cuisine) = 'cake'`. Reserve `REGEXP_CONTAINS` for free-text fields (item names, outlet names, brand names per R57).
- Confusing cuisine filter with item name filter: if the user says "cake orders" or "orders for [food name]", default to filtering `daily_orders_items.Item_name` via `REGEXP_CONTAINS` (R57) — NOT `daily_orders.Cuisine`. Only use `Cuisine` when the user explicitly says "cuisine = X" or "restaurants in X cuisine".

## Canonical item query pattern

For top items, item volume, or item revenue — always use `daily_orders_items` joined to `daily_orders`:

```sql
SELECT
  doi.Item_name,
  SUM(doi.Total_Price)  AS total_revenue
FROM noonbifood.reporting.daily_orders_items AS doi
JOIN noonbifood.reporting.daily_orders AS do
  ON doi.order_nr = do.order_id
WHERE do.order_status = 'delivered'
  AND do.country      = 'ae'
  AND doi.order_date BETWEEN <start_date> AND <end_date>
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 10
```

Key rules: `Item_name` (capital I, capital n) · `Total_Price` for revenue (pre-computed line total) · `Item_price` is the unit price per item · `QTY` is a derived column — do not aggregate it; rely on `Total_Price` instead · `order_date` is the partition column · no `country`/`order_status` on `daily_orders_items` — filter via JOIN to `daily_orders` (R31).

## Canonical widget + page pattern

When breaking down funnel by page and widget, always use this structure:

```sql
CASE
  WHEN lower(SPLIT(JSON_EXTRACT_SCALAR(event_misc,'$.wt'),'/')[SAFE_OFFSET(0)]) LIKE '%d1%' THEN 'D1'
  WHEN lower(SPLIT(JSON_EXTRACT_SCALAR(event_misc,'$.wt'),'/')[SAFE_OFFSET(0)]) LIKE '%d2%' THEN 'D2'
  WHEN lower(SPLIT(JSON_EXTRACT_SCALAR(event_misc,'$.wt'),'/')[SAFE_OFFSET(0)]) LIKE '%dp%' THEN 'DP'
  ELSE lower(SPLIT(JSON_EXTRACT_SCALAR(event_misc,'$.wt'),'/')[SAFE_OFFSET(0)])
END AS Page,
<widget CASE on SAFE_OFFSET(1) per R34> AS Widget
```

Canonical event list for `nat_events_complete`:
```sql
event_type IN (
  'outlet_impression_v2','page_outlet_v2','transaction_v2',
  'place_click_v2','page_checkout_v2','add_to_cart_v2',
  'item_click_v2','item_impression','place_order_v2'
)
```

Transaction count:
```sql
COUNT(DISTINCT CASE WHEN event_type = 'transaction_v2' THEN sid END) AS transactions
```

## Table quick-reference

Non-obvious things an LLM commonly gets wrong per table. Read `03_table_schemas.json` for full column lists.

| Table (short name) | Partition col | Country filter | Key gotchas |
|---|---|---|---|
| `daily_orders` | `day` | `country='ae'` | Has native `city` (abbrev, e.g. `Dxb`) and `Burn` — no JOIN to temp_outlet_status needed for city/burn queries. Join key to nat_events_complete: `customer_id=uid` (+ align `day`). |
| `nat_events_complete` | `day` | `locale LIKE '%ae%'` | All event names are `_v2` suffixed (e.g. `transaction_v2`). Exception: `item_impression` has no suffix. Join to `daily_orders` on `uid=customer_id` only — NOT `outlet_code=restaurant_code`. |
| `daily_orders_items` | `order_date` | no country col — JOIN `daily_orders` | No `country`, no `order_status` columns. Use `Total_Price` for revenue. `QTY` is derived — do not aggregate. `Item_price` is unit price. Always JOIN `daily_orders` ON `order_nr=order_id` to filter. |
| `food_order_item` | `day` | `country='ae'` | `price` is STRING — CAST to NUMERIC. Item-grain: use `COUNT(DISTINCT order_nr)` for orders. Use for price arithmetic only; prefer `daily_orders_items` for reporting. |
| `outlet_status_complete` | none (snapshot) | `country='ae'` | Live outlet filter: `bq_activation_status='Activated by Ops' AND is_consumer_visible='1' AND outlet_deleted=0`. Never use `status='active'` (R30). `is_consumer_visible` is STRING '1'. |
| `temp_outlet_status` | none (snapshot) | `outlet_country='ae'` | Enrichment only (city, hub, area, cuisine). No date filter ever. |
| `mp_order_base_mat` | `ops_order_date` | `country_code='ae'` | All time cols (O2D, O2A, P2D, etc.) in SECONDS — divide by 60 for minutes. `ops_order_date` filter is REQUIRED (BigQuery enforces). |
| `session_segments_nat` | `day` | `country='ae'` | Bounce/move flags live here, NOT in nat_events_complete. Join to nat_events_complete on `sid`. |
| `daily_hubz_rca_nat` | `Day` (capital D) | `Country='ae'` | Pre-agg hub/city funnel. Use SUM() on metric cols — never COUNT(). Much cheaper than nat_events_complete for geo funnel questions (R07). |
| `daily_rca` | `day` | `country='ae'` | Pre-agg national funnel by day+country+channel. Always add country filter or data doubles (R21). Use SUM() not COUNT(). |
| `outlet_dod_funnel` | `Day` (capital D) | `Country='Ae'` | Pre-agg per outlet per day. Country value is title-case `'Ae'`. Use SUM() not COUNT(). |
| `food_order_finance` | `created_at` | `country_code='ae'` | Finance/settlement only. Not for business GMV or customer counts. |
| `task` / `task_timestamp` / `task_misc` | `created_at` | filter via `daily_orders` | `task_misc` has no direct path to `daily_orders` — must go through `task` (R22). |
| `active_discount_outlets` | `snapshot_date` | (filter by `snapshot_date`) | Always filter `snapshot_date`. Use to check live discounts per outlet, funding type, campaign. |
| `final_final_ncc` | none | — | Customer nationality: `customer_id → Final_nationality`. JOIN `daily_orders` on `customer_id`. |
| `abc_segments` | none | — | A/B/C test segments. Join to `raw_events_v2` on `uid=customer_id`. Values: `test_a`, `test_b`, `test_c`, `control`. |
| `raw_events_v2` | `event_date` | `LOWER(locale) LIKE '%ae%'` | Food context filter required: `JSON_VALUE(event_misc,'$.szf') IS NOT NULL OR JSON_VALUE(event_misc,'$.mpe')='food'` (R28). Session key is `session_id` (not `sid`). |
| `order_discount` / `food_order_discount_detail` | `created_at` | — | Multi-row per order — always `COUNT(DISTINCT order_nr)` (R15). |
| `rod_category_tagging` | none | — | Partner/brand category lookup. Join on `id_partner_owner`. Small, safe for LEFT JOIN. |
| `food_order_review` | none | — | Only reviewed orders. Always join `daily_orders` for denominators. |
| `session_zone` | `day` | `Country` (e.g. `'ae'`) | Cheaper than nat_events_complete for geo session distribution. Session key is `sessionid`. |

## Examples of trigger phrases (non-exhaustive)

- "Active customers in Dubai last month"
- "Funnel conversion per hub yesterday"
- "GMV vs burn by city this week"
- "Live outlet count in Riyadh"
- "Cancellation rate trend last 30 days"
- "AOV for VIP customers in May"
- "Bounce rate per hub last week"
- "How many Mix orders in UAE this month"
- "Outlet impressions vs conversions for brand X"
- "Brand and venue list from the OUT dataset"

When in doubt about whether to trigger: if the question is answerable from the tables in `02_table_registry.json`, use this skill.
