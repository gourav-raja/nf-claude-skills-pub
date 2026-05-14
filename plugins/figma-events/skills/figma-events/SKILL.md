# figma-events

Generate a Noon Food analytics event spec from a Figma URL.

## Usage
```
/figma-events <figma_url>
```

## What this skill does

Given a Figma URL, this skill:
1. Extracts `fileKey` and `nodeId` from the URL
2. Fetches a screenshot of the design via the Figma MCP
3. Analyses every visible section and interactive element
4. Produces impression + tap event pairs for each element, following the Noon event structure
5. Writes the spec as YAML files (grouped by section) into `~/Desktop/noon-food-events/<screen_name>/`

---

## Step-by-step instructions

### 1. Parse the URL

Extract from the Figma URL:
- `fileKey` — the segment after `/design/`, `/proto/`, or `/board/`
- `nodeId` — from `node-id` query param, converting `-` to `:`
- `screenName` — slugify the file name segment of the URL (e.g. `Homepage` → `homepage`)

### 2. Fetch the design

Call `mcp__claude_ai_Figma__get_screenshot` with `nodeId`, `fileKey`, and `maxDimension: 1920`.
Download the returned image URL with `curl -s -o /tmp/figma_screen.png "<url>"` then Read the file to view it.

If `get_screenshot` fails or times out, try `mcp__claude_ai_Figma__get_design_context` (with `excludeScreenshot: false`).

### 3. Analyse the design

Carefully examine the screenshot. Identify every distinct section and every interactive element within each section:
- Named sections (e.g. "Deals starting at $10", "Restaurants near you")
- Cards (restaurant cards, dish cards, deal cards, video cards)
- Chips / filter buttons
- CTAs ("See all", "View more")
- Search bars, location selectors, icons (cart, notification, search)
- Banners, carousels, overlays

For each element, decide:
- Does it get an **impression** event? (yes — fire when it enters the viewport)
- Does it get a **click** event? (yes — fire on user click/tap)
- What **extra fields** does it carry in `event_misc`? (ids, names, positions, ratings, etc.)

### 4. Name the events

Follow this convention:
```
<screen_name>_<element_name>_impression
<screen_name>_<element_name>_tapped
```

Examples:
- `homepage_restaurant_card_impression`
- `homepage_restaurant_card_tapped`
- `homepage_deal_card_impression`
- `homepage_deal_card_tapped`

One screen-load event with no `_impression`/`_tapped` suffix:
- `<screen_name>_impression`

### 5. Build the event structure

Every event must follow this exact Noon event structure:

```yaml
event_type: <event_name>
event_misc:
  an: noon
  av: '4.82'
  mc: food
  mpe: food
  sid: <session_id>
  # ... event-specific fields below
locale: en-ae
platform: android
device:
  aid: <android_id>
  d: Handset
  dm: <device_model>
  dos: <device_os>
  gaid: <google_advertising_id>
  ip_address: <ip_address>
  ipcountry: ae
  sr: <screen_resolution>
  ua: <user_agent>
  vps: <viewport_size>
event_time: <utc_timestamp>
event_date: <event_date>
```

**Rules:**
- `mpe` is always `food`
- `mc` is always `food`
- `an` is always `noon`
- All numeric values (positions, ratings, prices) are quoted strings: `'1'`, `'4.5'`
- `card_position` starts at `'1'`
- Use `<placeholder>` syntax for all runtime values
- `sid` is always present on every event

**Common extra fields by element type:**

| Element | Extra `event_misc` fields |
|---|---|
| Screen load | `sections_loaded` (comma-separated list of section keys) |
| Category chip | `chip_name`, `chip_position` |
| Deal card | `rid`, `rname`, `deal_value`, `card_position` |
| Restaurant card | `rid`, `rname`, `section`, `card_position`, `rating` |
| Video card | `rid`, `vid`, `card_position` |
| Dish card | `did`, `dname`, `rid`, `card_position` |
| Banner | `banner_id`, `banner_position` |
| See all / CTA | `section` |
| Search bar | (no extra fields) |

If you encounter an element type not in this table, infer sensible field names using the same short-key pattern (`rid`, `rname`, `did`, `dname`, `vid`, etc.).

### 6. Group events into files

Group events by section, one YAML file per section. Use a list (`-`) when a file contains multiple events.

Suggested file names:
- `screen.yaml` — the top-level screen impression
- `search.yaml` — search bar events
- `category_chips.yaml` — chip/filter events
- `deal_cards.yaml` — deal card events
- `restaurant_cards.yaml` — restaurant card events
- `featured_videos.yaml` — video card events
- `dish_cards.yaml` — dish card events
- `banners.yaml` — banner events (if present)
- `navigation.yaml` — see-all / CTA events

Only create a file if that section exists in the design.

### 7. Write the files

Output directory: `~/Desktop/noon-food-events/<screen_name>/`

Create the directory if needed, then write each YAML file.

After writing, print the final directory tree:
```
noon-food-events/
└── <screen_name>/
    ├── screen.yaml
    ├── search.yaml
    └── ...
```

And print a summary table:

| File | Events |
|---|---|
| screen.yaml | `<screen_name>_impression` |
| search.yaml | `search_bar_impression`, `search_bar_tapped` |
| ... | ... |

---

## Notes

- If the Figma MCP rate limit is hit, use the screenshot you already have (if any) and proceed with analysis based on visible content.
- If no nodeId is present in the URL, use `0:1` to get the root page metadata first, then pick the most relevant node.
- Proto URLs (`figma.com/proto/...`) use the same fileKey extraction as design URLs.
- Always check for the Figma session with `mcp__claude_ai_Figma__whoami` if tools return "session expired".
