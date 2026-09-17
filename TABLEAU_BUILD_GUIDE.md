# Part 3 — Tableau Public Build Guide

Everything needed to build the dashboard in **Tableau Public (free)**. Tableau Desktop is not
required and is not used anywhere.

**Data source:** `monthly_category_revenue.csv` — the unedited Part 1 export.
36 data rows (6 categories × 6 months), columns `category, month, order_count, total_revenue, avg_revenue`.
Grand total `total_revenue` = **88,282**. If your connected data does not total 88,282, you have
connected the wrong file — stop and re-export from Part 1.

---

## Step 1 — Connect the data

1. Open Tableau Public Desktop → **Connect → To a File → Text file** → select `monthly_category_revenue.csv`.
2. On the data source tab, confirm the field types:
   - `category` → **Abc** (string)
   - `month` → **Abc** (string — leave it as a string, Step 2 converts it properly)
   - `order_count`, `total_revenue` → **#** (number, whole)
   - `avg_revenue` → **#** (number, decimal)
3. Bottom-left, confirm the row count is **36**.

> If Tableau auto-detects `month` as a date, right-click the field → **Change Data Type → String**
> before continuing, so the `Month Date` calculation below behaves predictably.

---

## Step 2 — Create the five calculated fields

Right-click in the Data pane → **Create Calculated Field** for each. Names must match exactly,
because every sheet below references them.

### 2.1 `Month Date` — turns `"2026-01"` into a real date

```
MAKEDATE(INT(LEFT([Month], 4)), INT(RIGHT([Month], 2)), 1)
```

`MAKEDATE` is used rather than `DATEPARSE` because it works on every Tableau Public connector
without regional-locale surprises. Each month becomes the 1st of that month, which is all a
monthly axis needs.

### 2.2 `Target Revenue` — the Part 1/Part 2 targets, row-level

```
CASE [Category]
WHEN "Fruits & Vegetables" THEN 12000
WHEN "Dairy & Eggs" THEN 16500
WHEN "Snacks & Beverages" THEN 13000
WHEN "Personal Care" THEN 15500
WHEN "Household Essentials" THEN 17000
WHEN "Bakery" THEN 12000
END
```

These are the same six fixed targets as the SQL `category_targets` table and the Part 2
**Category Targets** sheet. Do not invent your own.

> **Watch out:** this is a *row-level* field and each category has 6 monthly rows, so
> `SUM([Target Revenue])` returns **6× the real target**. Always aggregate it with
> `MIN()` or `AVG()`, never `SUM()`.

### 2.3 `Tier` — the three-way classification from Parts 1 and 2

```
IF [Category] = "Household Essentials"
OR [Category] = "Personal Care"
OR [Category] = "Bakery"
THEN "Above Target"
ELSEIF [Category] = "Dairy & Eggs"
THEN "Below Target - Watch"
ELSE "Below Target - Critical"
END
```

A fixed, row-level tier is used deliberately: the brief asks for the tier **as computed in Parts 1
and 2**, and keeping it fixed means a month filter re-filters the *revenue* without silently
re-classifying a category off two months of partial data.

> *Optional dynamic version* — if you would rather have tiers recompute under the filter, use this
> aggregate calculation instead. It produces identical colours on the unfiltered dashboard:
> ```
> IF SUM([Total Revenue]) >= MIN([Target Revenue]) THEN "Above Target"
> ELSEIF (MIN([Target Revenue]) - SUM([Total Revenue])) / MIN([Target Revenue]) <= 0.15
>   THEN "Below Target - Watch"
> ELSE "Below Target - Critical"
> END
> ```

### 2.4 `Average Order Value`

```
SUM([Total Revenue]) / SUM([Order Count])
```

Divide the sums — **do not** use `AVG([Avg Revenue])`. Averaging the pre-computed per-month
averages is an average-of-averages and weights a 5-order month the same as a 20-order month.
The correct value here is **₹203.41**; the average-of-averages route gives a different, wrong number.

### 2.5 `Categories Meeting Target`

```
STR(
  COUNTD(
    IF { FIXED [Category] : SUM([Total Revenue]) } >= [Target Revenue]
    THEN [Category] END
  )
) + " / 6"
```

The FIXED LOD pre-aggregates each category's six monthly rows, so the comparison against
`[Target Revenue]` happens at row level and `COUNTD` is free to count distinct categories rather
than rows. Drop this on Text on a blank sheet and it returns **3 / 6**.

> **Caveat:** FIXED LODs are computed *before* dimension filters, so the dashboard's category
> filter will not move this card unless you right-click that filter on the Filters shelf →
> **Add to Context**. Leaving it fixed is a defensible choice — "3 of 6 meeting target" is a
> statement about the whole business, not the current selection — but know which behaviour you
> have shipped.

---

## Step 3 — Set the tier colour palette once

You will assign these on the first sheet that uses `Tier`, and Tableau reuses them everywhere:

| Tier | Colour | Hex |
|---|---|---|
| Above Target | Green | `#2E7D32` |
| Below Target - Watch | Amber | `#F9A825` |
| Below Target - Critical | Red | `#C62828` |

These match the Part 2 conditional formatting and the Part 4 matplotlib charts, so the same
category is the same colour in every artifact of this project.

**Currency formatting (do this once, applies everywhere):** right-click `Total Revenue` →
**Default Properties → Number Format → Custom** → enter `₹#,##0` (or `"INR " #,##0`).
**Never use Currency (Standard), which renders a `$` sign.**

---

## Step 4 — Build the worksheets

### Sheet 1: `Monthly Revenue Trend` (time series)

1. Drag `Month Date` to **Columns** → right-click the pill → select the **continuous green
   MONTH(Month Date)** option, so the axis runs Jan → Jun rather than grouping all Januaries.
2. Drag `Total Revenue` to **Rows**.
3. Marks card → **Line**; drag `Total Revenue` to **Label** to print the value at each point.
4. Title: **"Total revenue climbed to a May peak of ₹17,231, then fell 21% in June"**

Expected values: Jan 11,057 · Feb 15,085 · Mar 14,695 · Apr 16,606 · May 17,231 · Jun 13,608.

### Sheet 2: `Category Revenue by Tier` (sorted bar chart)

1. `Category` to **Rows**, `Total Revenue` to **Columns**.
2. `Tier` to **Colour** → assign the three hex colours from Step 3.
3. Sort descending: click the sort icon on the `Total Revenue` axis, or right-click `Category` →
   **Sort → Field → Descending → Total Revenue**.
4. `Total Revenue` to **Label**.
5. *(Optional, strongly recommended)* add a target reference line: right-click the revenue axis →
   **Add Reference Line → Per Cell → Value: `Target Revenue` → Minimum** → dashed grey. Each bar
   then visibly crosses or misses its own target.
6. Title: **"Household Essentials leads at ₹21,715; Fruits & Vegetables trails 18.4% below target"**

Expected order: Household Essentials 21,715 · Personal Care 16,382 · Bakery 15,410 ·
Dairy & Eggs 14,090 · Snacks & Beverages 10,895 · Fruits & Vegetables 9,790.

### Sheets 3–6: the four KPI cards

Build each as its own worksheet — drag the measure to **Text** on the Marks card, then
**Format → Font → size 28–36, bold**, and hide the column/row headers.

| Sheet name | Field on Text | Aggregation | Expected value | Sheet title |
|---|---|---|---|---|
| `KPI Total Revenue` | `Total Revenue` | SUM | **₹88,282** | Total Revenue (INR), Jan–Jun 2026 |
| `KPI Delivered Orders` | `Order Count` | SUM | **434** | Total Delivered Orders |
| `KPI Avg Order Value` | `Average Order Value` | (calculated) | **₹203.41** | Average Order Value (INR) |
| `KPI Categories On Target` | `Categories Meeting Target` | (calculated) | **3** | Categories Meeting Target (of 6) |

For the last card, edit the title to read literally **"Categories Meeting Target (of 6)"** so the
"out of 6" is on screen, as the brief requires. Format `Average Order Value` as `₹#,##0.00`.

---

## Step 5 — Assemble the dashboard

1. **Dashboard → New Dashboard**. Size: **Automatic**, or Fixed 1200 × 900.
2. Set **Objects → Floating** (bottom-left of the Dashboard pane) *before* dragging sheets in, as
   the brief requires floating layout.
3. Suggested arrangement:

```
┌──────────────────────────────────────────────────────────────┐
│  Title: BigBasket Category Performance — Jan–Jun 2026        │
├────────────┬────────────┬────────────┬────────────┬──────────┤
│  ₹88,282   │    434     │  ₹203.41   │    3 / 6   │  Tier    │
│  Revenue   │  Delivered │    AOV     │ On Target  │  Legend  │
├────────────┴────────────┴────────────┴────────────┤          │
│                                                   │ Category │
│   Monthly Revenue Trend (line)                    │  Filter  │
│                                                   │          │
├───────────────────────────────────────────────────┤          │
│   Category Revenue by Tier (sorted bar)           │          │
└───────────────────────────────────────────────────┴──────────┘
```

KPI cards sit across the top (most prominent), the two charts are stacked below, and the filter
plus tier legend are docked on the right.

4. **Add the dashboard-wide filter:**
   - On `Category Revenue by Tier`, right-click `Category` in the Data pane → **Show Filter**.
   - On the filter card's dropdown (▾) → **Apply to Worksheets → All Using This Data Source**.
     This is the step that makes it affect *every* worksheet including the KPI cards — without it
     the filter only touches one sheet and the requirement is not met.
   - Set the filter to **Multiple Values (dropdown)** and tick **Show "All" Value**.
   - Confirm the **Tier colour legend is visible** on the dashboard (drag it from the sheet's
     legend if Tableau did not add it automatically).
   - Test it: deselect *Household Essentials* → the Total Revenue KPI must drop from ₹88,282 to
     ₹66,567 and the bar chart must fall to five bars. If the KPI cards do not move, you skipped
     the "All Using This Data Source" step.
   - The Categories Meeting Target card will stay at 3 / 6 unless you added its filter to context
     (see the caveat in Step 2.5). That is expected behaviour, not a fault.
5. Consistency pass: one font family throughout, the same three tier colours on every mark, every
   currency figure with `₹` and **no `$` anywhere**.

---

## Step 6 — Publish and link

1. **File → Save to Tableau Public As…** → sign in to your free Tableau Public account → name it
   e.g. `BigBasket Category Performance Diagnostic`.
2. After it opens in the browser, click **Edit Details** (or the profile → workbook settings) and
   make sure **"Show workbook on profile"** / visibility is **ON**.
3. **Verify it is publicly viewable:** copy the URL, open it in a **private/incognito window while
   logged out**. If it loads without a login prompt, it is public. A grader who cannot open the
   link scores this section zero, so do not skip this test.
4. Paste the live URL into `README.md` as plain text — a URL, not an uploaded file, not a
   screenshot, not a PDF.

---
