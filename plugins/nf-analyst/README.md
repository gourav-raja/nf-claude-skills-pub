# food-analytics-sql

A Claude plugin that converts natural-language questions about noon's food delivery business into correct BigQuery SQL.

The plugin packages a curated context library — business glossary, table registry, schemas, metrics definitions, global SQL rules, worked examples, geographic mappings, and dashboard/product context — so that anyone in the org can ask analytics questions in plain English and get back a runnable BigQuery query plus a short reasoning trail.

## What it covers

- Order, customer, and revenue metrics from `daily_orders` (GMV, AOV, active/new/repeat customers, churn, retention, reactivation, TPC/HPC/LPC, cancel rate, burn, promo rate)
- Session and funnel analytics from `nat_events_complete`, `session_segments_nat`, and pre-aggregated `daily_hubz_rca_nat`
- Outlet/restaurant inventory from `outlet_status_complete` and `temp_outlet_status`
- Logistics and SLA from `task`, `task_timestamp`, `mp_order_base_mat`
- Item-level revenue from `food_order_item`
- Finance from `food_order`
- Mix / Mealplan, Flash, Ping, ADMON, OUT brand/venue
- Sherlock executive dashboard, personalisation, and search metrics

## How it behaves

When a user asks a SQL or analytics question, Claude:

1. Loads the small core context (glossary, table registry, global rules).
2. Selectively reads only the additional reference files relevant to the question (schemas, metrics, examples, city/hub map, etc.).
3. Asks one clarifying question only if a real ambiguity would change the query.
4. Outputs a single BigQuery SQL statement plus a tight reasoning block listing the tables, metric mapping, rules applied, and assumptions.

## Install

Distribute the `.plugin` file produced from this directory. Org members install it once into Cowork or Claude Code; the skill auto-triggers on analytics questions matching its description.

## Update flow

The context library lives at `skills/food-analytics-sql/references/`. To update business definitions, table schemas, or rules:

1. Edit the relevant `*.json` in that directory.
2. Bump `version` in `.claude-plugin/plugin.json`.
3. Re-zip and re-share the `.plugin` file.

## File map

```
food-analytics-sql/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── food-analytics-sql/
│       ├── SKILL.md
│       └── references/
│           ├── 01_glossary.json
│           ├── 02_table_registry.json
│           ├── 03_table_schemas.json
│           ├── 04_metrics.json
│           ├── 05_global_rules.json
│           ├── 06_examples.json
│           ├── 07_city_hub_mapping.json
│           ├── 08_sherlock_dashboard.json
│           ├── 09_admon_context.json
│           ├── 10_ping_context.json
│           ├── 11_OUT_context.json
│           ├── personalisation.json
│           └── search_metrics.json
└── README.md
```
