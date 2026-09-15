# AI-Assisted Prompting Log

Two prompts total across this project, each structured against all five RCTCF elements

## Prompt #1 — SQL Query Draft/Debug

### Role
You are a careful SQLite data analyst working on a grocery category-management capstone.

### Context
The database `bigbasket_capstone.db` contains `orders` and `products` tables. The category team needs monthly revenue by category using Delivered orders only. The result must be deterministic and suitable for direct CSV export.

### Task
Write a SQLite query that returns monthly revenue by category with the columns `category`, `month`, `order_count`, `total_revenue`, and `avg_revenue`.

### Constraints
Use SQLite syntax. Join `orders` to `products` using `product_id`. Include only `Delivered` orders. Derive month as `strftime('%Y-%m', order_date)`. Group by category and month. Do not manually alter the exported results.

### Format
Return one runnable SQL SELECT statement and a short explanation of the grouping and filters.

### Verification actually performed
I ran the resulting query against `bigbasket_capstone.db`, checked the returned schema and row count, and manually checked sample rows before exporting the results to `monthly_category_revenue.csv`.


## Prompt #2 — Part 4, Pandas (IQR outlier capping)

### Role
Act as a senior data analyst who reviews Pandas cleaning pipelines for a retail
analytics team.

### Context
I have a 500-row DataFrame `df` of BigBasket orders with columns `order_id`,
`status`, `amount_inr`, `quantity` and `category`. `amount_inr` has 10 missing values and a handful
of values roughly 40× too large from a bad export. I need to cap the high outliers using the IQR
rule, computed only on Delivered orders that have a non-null amount, and I must cap rather than
drop because the rest of each row (customer, city, date, quantity) is still valid data. My current
code is:

```python
delivered_amounts = df.loc[revenue_rows, "amount_inr"]
Q1 = delivered_amounts.quantile(0.25)
Q3 = delivered_amounts.quantile(0.75)
IQR = Q3 - Q1
upper_fence = Q3 + 1.5 * IQR
df["amount_inr"] = df["amount_inr"].clip(upper=upper_fence)
```

### Task
Explain, line by line, what this IQR block is doing, and tell me specifically whether
applying `.clip(upper=upper_fence)` to the **whole** `amount_inr` column — when the fence was
derived from Delivered rows only — is a bug.

### Constraints
Pandas only, no scipy or sklearn. Do not fill the missing `amount_inr` values;
they must stay `NaN` and be excluded from sums, not imputed. Do not drop any rows. Do not rename
any of my variables. Use the standard 1.5 × IQR convention.

### Format
A numbered line-by-line explanation, then a short verdict paragraph headed
"Is this a bug?", then a one-line code correction only if one is genuinely needed.

**Verification actually performed** — I re-ran the `.clip()` line and manually checked three
previously-extreme rows against the printed upper fence of ₹552.50: order 199 (₹5,400 → ₹552.50),
order 250 (₹5,200 → ₹552.50) and order 323 (₹7,600 → ₹552.50), all now sitting at exactly the
fence. I then asserted `df["amount_inr"].max() <= upper_fence`, which passed, and confirmed the
capped-row count printed as **16 Delivered rows**, matching the count of rows above the fence that
I had computed *before* the clip ran. To test the AI's specific claim that clipping the full column
is not a bug — its argument being that Cancelled and Pending rows are excluded from every revenue
sum by the `revenue_rows` mask regardless — I re-ran the Task 7(a) category `groupby` a second time
with the clip restricted to the Delivered subset only. The category totals came back identical
(Household Essentials ₹20,910.00, total ₹84,637.00), which confirmed the claim rather than taking
it on trust.

**Outcome:** the AI's explanation was kept, no code change was needed, and the verification above
turned "it should be fine" into a checked fact. Its one genuinely useful catch was that
`.quantile()` skips `NaN` automatically, so the `notna()` condition in my `revenue_rows` mask is
belt-and-braces for the fence calculation — but still strictly necessary for the revenue `sum()`
downstream, which is why it stayed in.