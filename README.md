# BigBasket Category Performance Diagnostic

## Overview

BigBasket's category management team sets a monthly revenue target for each of its six product
categories, but the read on who is hitting those targets has been split across four tools that do
not always agree. This project settles it with one deterministic dataset carried end to end through
SQL, a spreadsheet, Tableau and Pandas. Part 1 builds a SQLite database of 500 orders and exports a
single monthly-revenue-by-category CSV; Part 2 rebuilds those totals in a spreadsheet and reconciles
them to the rupee against the SQL output; Part 3 turns the same CSV into a Tableau Public dashboard
and a written recommendation; and Part 4 starts over from a deliberately messy raw export of the
same transactions, cleans it independently in Pandas, and checks whether an analyst who never saw
the database reaches the same diagnosis. **It does:** both pipelines name **Household Essentials**
as the top category and **HomeEssentials Traders** as the dominant supplier, even though their
revenue totals differ by 4.1% because Part 4 removes duplicates, excludes unknown revenue and caps
outliers while Part 1 does none of those things. The business finding is that the platform is
₹2,282 *above* its combined target while **3 of its 6 categories are below theirs** — the winners
are covering for the losers, and the two worst performers have a basket-size problem rather than a
demand problem.

---

## 🔗 Live Tableau Public dashboard

[text](https://public.tableau.com/views/BigBasket_Capstone_17893942536920/BigBasketCategoryPerformance?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## Repository structure

```
.
├── README.md                        ← you are here (overview, links, structure)
├── DATA_STORY.md                    ← Part 3 written data story + 2 recommendations
├── TABLEAU_BUILD_GUIDE.md           ← Part 3 dashboard build steps & calculated fields
├── ai_log.md                        ← both RCTCF prompts + their verification steps
│
├── generate_data.py                 ← Part 1 Task 1 — builds the DB and both raw CSVs
├── bigbasket_capstone.db            ← SQLite DB: 31 products, 50 customers, 500 orders, 6 targets
│
├── verify.sql                       ← Part 1 Task 2 — row-count & status verification
├── 01_foundations.sql               ← Part 1 Task 3 — WHERE, DISTINCT, ORDER BY+LIMIT, AS,
│                                      IN, BETWEEN / NOT BETWEEN, IS NULL
├── 02_aggregation_joins.sql         ← Part 1 Task 4 — (a) INNER JOIN + GROUP BY + HAVING
│                                      (b) LEFT JOIN with COUNT(o.order_id)
├── 03_reporting.sql                 ← Part 1 Task 5 — (a) CASE WHEN tiering
│                                      (b) category × month report  (c) variance vs targets
│
├── monthly_category_revenue.csv     ← Part 1 Task 6 export — the fixed input for Parts 2 & 3
│                                      36 rows, grand total total_revenue = 88,282
├── orders_raw.csv                   ← messy raw export — Part 4 input only (508 rows)
├── products.csv                     ← product catalogue with supplier — Part 4 merge input
│
├── BigBasket_category_analysis.xlsx ← Part 2 workbook (Monthly Data · Category Targets ·
│                                      Pivot · Category Summary)
└── analysis.ipynb                   ← Part 4 notebook — cleaning, analysis, cross-validation
```

---

## How to regenerate the data

The entire dataset is deterministic — `random.seed(42)` is fixed, so re-running the script
reproduces byte-identical files. **Do not edit the seed or any of the fixed lists/weights**; every
acceptance number in this project depends on that exact output.

```bash
python3 generate_data.py
```

This writes three files: `bigbasket_capstone.db` (Parts 1–3), plus `orders_raw.csv` and
`products.csv` (Part 4 only). No dependencies beyond the Python 3 standard library — `sqlite3`,
`random`, `csv` and `datetime` all ship with Python.

**Verification after running** — expect exactly:

| Check | Expected |
|---|---|
| `products` | 31 rows |
| `customers` | 50 rows |
| `orders` | 500 rows |
| `category_targets` | 6 rows |
| `orders.status` | Delivered 434 · Cancelled 42 · Pending 24 |
| `orders_raw.csv` | 508 data rows (500 + 8 injected duplicates) |
| `monthly_category_revenue.csv` | 36 rows, `SUM(total_revenue)` = 88,282 |

---

## Where to find each Part

### Part 1 — SQL data setup & diagnostic

| Task | File | Contents |
|---|---|---|
| 1 | `generate_data.py` | Database + raw CSV generation |
| 2 | `verify.sql` | Row counts on all four tables, `GROUP BY status` |
| 3 | `01_foundations.sql` | `SELECT/WHERE`, `DISTINCT`, `ORDER BY`+`LIMIT`, alias `AS`, `IN`, `BETWEEN`, `NOT BETWEEN`, `IS NULL` |
| 4 | `02_aggregation_joins.sql` | (a) INNER JOIN aggregation with `HAVING total_revenue > 10000`; (b) LEFT JOIN using `COUNT(o.order_id)` so *Premium Face Cream 50g* correctly appears with **0** orders |
| 5 | `03_reporting.sql` | (a) three-tier `CASE WHEN`; (b) category × month report via `strftime('%Y-%m', order_date)`; (c) variance and percentage variance against `category_targets`, using `* 100.0` to avoid SQLite integer-division truncation |
| 6 | `monthly_category_revenue.csv` | Direct unedited export of Task 5(b) |
| 7 | `ai_log.md` | ## Prompt #1 — SQL Query Draft/Debug + verification |

### Part 2 — Spreadsheet cross-check

**Workbook: `BigBasket_Category_Analysis.xlsx`** — four sheets: 
`Monthly Data` (unmodified CSV
import), 
`Category Targets` (the 6 fixed targets), 
a Pivot Table (category × SUM of total_revenue and order_count), and 
`Category Summary` (pivot-referenced revenue, `XLOOKUP` with a not-found
default, variance and percentage variance, a nested `IF` three-way tag with conditional formatting,
and the `Matches Part 1 SQL total?` reconciliation column — **Yes** on all six rows).

Reconciled category totals, identical to the rupee in SQL and the spreadsheet:

| Category | Total revenue |
|---|---:|
| Household Essentials | 21,715 |
| Personal Care | 16,382 |
| Bakery | 15,410 |
| Dairy & Eggs | 14,090 |
| Snacks & Beverages | 10,895 |
| Fruits & Vegetables | 9,790 |
| **Total** | **88,282** |

### Part 3 — Tableau dashboard & data story

- **Live dashboard:** link at the top of this README
- **Build guide, calculated fields, publishing steps:** [`TABLEAU_BUILD_GUIDE.md`](TABLEAU_BUILD_GUIDE.md)
- **📖 Data story and the two recommendations:** [`DATA_STORY.md`](DATA_STORY.md)

Dashboard contents: a Jan–Jun 2026 monthly revenue time series; a category bar chart sorted
descending and colour-coded by tier (green Above Target · amber Watch · red Critical); four KPI
cards — **Total Revenue ₹88,282**, **Delivered Orders 434**, **Average Order Value ₹203.41**,
**Categories Meeting Target 3 of 6**; and a category filter applied to every worksheet with the
tier legend visible.

### Part 4 — Python/Pandas cleaning, analysis & cross-validation

**📓 Notebook: [`analysis.ipynb`](analysis.ipynb)** — runs from `orders_raw.csv` (508 rows) and
`products.csv`.

Also contains four matplotlib charts with finding-stating titles and three
What / Why it matters / Next step insight observations.

### AI-assisted prompting log

**[`ai_log.md`](ai_log.md)** — both required RCTCF-structured prompts (Role, Context, Task,
Constraints, Format), each with the concrete verification step actually performed on the AI's
suggestion: prompt #1 on a Part 1 SQL query, prompt #2 on the Part 4 Pandas IQR capping logic.

---

## Headline findings

1. **Three of six categories are below target**, while the platform total sits ₹2,282 *above* the
   combined ₹86,000 target. Household Essentials (+₹4,715) and Bakery (+₹3,410) are covering for
   Fruits & Vegetables (−₹2,210) and Snacks & Beverages (−₹2,105).
2. **The two Critical categories have a basket problem, not a demand problem.** They account for
   36% of all delivered orders but only 23% of revenue, at average order values around ₹131–134
   against a ₹203.41 platform average.
3. **Revenue peaked at ₹17,231 in May and fell 21% in June** — the first decline of the half-year,
   across four of the six categories.
4. **One supplier, HomeEssentials Traders, carries 24.7% of revenue** and is the sole source for the
   entire top-performing category — a concentration risk invisible in any category-level report.
5. **The ranking is robust; the exact totals are not.** Two independent pipelines starting from
   different files agree on the top category and top supplier while differing 4.1% on total revenue.

---

## Tooling

Every tool used is free. SQLite via Python's built-in `sqlite3`; Google Sheets (workbook downloaded
as `.xlsx`); Tableau **Public** (never Tableau Desktop); pandas and matplotlib in Jupyter. No paid
licence, cloud warehouse, API key or credit card is needed to reproduce any part of this project.
