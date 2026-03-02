# Brazilian E-Commerce Marketplace — SQL Analysis

Exploratory analysis of a Brazilian e-commerce marketplace using SQL and Python. The dataset covers orders, customers, payments, deliveries, products, and reviews. The analysis focuses on revenue trends, customer retention, delivery performance, product mix, and satisfaction.

---

## At a Glance

| Total Orders | Total Revenue | Avg Delivery Time | Customer Retention | Avg Review Score |
|---|---|---|---|---|
| 99,441 | R$ 16,008,872 | 12.5 days | 3.1% | 4.1 / 5 |

---

## Key Findings

- **Growth is volume-driven** — strong expansion through 2017, stabilizing in 2018, with average order value staying flat throughout
- **Retention is the biggest gap** — only ~3% of customers ever buy again, making growth almost entirely acquisition-dependent
- **Delivery is solid on average, but uneven** — 12.5 days nationally, with some states pushing close to 30
- **Customers are happy** — 77% of reviews are 4 or 5 stars, making low retention a structural puzzle rather than a service failure
- **Revenue is moderately concentrated** — the top 10 categories account for 63% of total revenue

---

## Revenue & Growth

The platform grew strongly through 2017 and stabilized in 2018. Digging into what drove that growth, it comes down almost entirely to order volume — average spend per order stayed flat the whole time. More customers buying, not the same customers spending more.

The last two months of 2018 show lower numbers, but that's likely incomplete data rather than an actual slowdown.

![Revenue over time](growth_vs_month.png)
![Average price per order](average_price_per_order_vs_month.png)

---

## Customer Retention

Only 3% of customers ever place a second order. The business runs on acquisition — it needs a constant flow of new customers to sustain revenue.

![New customers per month](new_customers_vs_month.png)

What's worth noting is that repeat customers generate around 6% of total revenue despite being just 3% of the base. They're more valuable per head, which means retention is a real opportunity even if small gains are hard to achieve.

The obvious question is what's driving people away. Late deliveries aren't the answer — customers who experienced delays returned at the same rate as everyone else. Satisfaction scores are high too. The low retention seems to reflect what's being sold more than anything operational.

---

## Delivery Performance

The national average is 12.5 days with about 8% of orders arriving later than estimated. Reasonable for a country the size of Brazil.

The regional picture is more uneven. Fastest states average around 9 days; slowest approach 30. That's a big gap in customer experience depending on location.

One nuance worth mentioning: slow states don't always have the worst late-delivery rates. Delivery estimates seem to be calibrated to local conditions, so longer transit times don't automatically mean more missed deadlines. The reliability issues tend to show up more in mid-range states where estimates and reality don't quite align.

![Delivery performance by state](late_deliveries_vs_state.png)

---

## Product Mix

The top 10 categories account for 63% of total revenue. There's real concentration there — performance in those categories has an outsized effect on overall results. That said, the platform isn't dependent on any single category, and the remaining 37% is spread across a wide range of smaller segments.

![Revenue by product category](revenue_percent_vs_product_category_name.png)

---

## Customer Satisfaction

77% of reviews are 4 or 5 stars. Only around 15% fall in the 1–2 range. By any reasonable measure, customers are happy with their experience.

That makes the retention picture more interesting. The issue isn't that people had a bad time — it's that they don't have a reason to come back. That's a product mix problem more than a service problem.

---

## Conclusion

Strong acquisition, low retention, solid delivery, healthy satisfaction. The platform works well. The clearest opportunity is retention — not by fixing something broken, but by identifying which categories and customers have the highest potential for repeat purchases and focusing there.

---

## Tools

- **SQL** (PostgreSQL)
- **Python** (pandas, matplotlib/seaborn)

---

## Files

| File | Description |
|------|-------------|
| `data_quality.sql` | Check nulls and inconsistencies |
| `analysis.sql` | Full analysis query |
| `visualization_script.py` | Visualization scripts |
| `plots/` | Charts used in this README |







## How to Reproduce

1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Run `schema.sql` to create the tables
3. Load the CSVs — two options:

   **Option A — pgAdmin:** 

   **Option B — psql terminal:** run the following commands, replacing the path with your CSV:
```sql
   \copy customers FROM 'your/path/olist_customers_dataset.csv' DELIMITER ',' CSV HEADER;
   \copy geolocation FROM 'your/path/olist_geolocation_dataset.csv' DELIMITER ',' CSV HEADER;
   \copy order_items FROM 'your/path/olist_order_items_dataset.csv' DELIMITER ',' CSV HEADER;
   \copy order_payments FROM 'your/path/olist_order_payments_dataset.csv' DELIMITER ',' CSV HEADER;
   \copy reviews FROM 'your/path/olist_order_reviews_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'LATIN1';
   \copy orders FROM 'your/path/olist_orders_dataset.csv' DELIMITER ',' CSV HEADER;
   \copy products FROM 'your/path/olist_products_dataset.csv' DELIMITER ',' CSV HEADER;
   \copy product_category_translation FROM 'your/path/product_category_name_translation.csv' DELIMITER ',' CSV HEADER;
   \copy sellers FROM 'your/path/olist_sellers_dataset.csv' DELIMITER ',' CSV HEADER;
```

3. Run `data_quality.sql` to check for nulls and inconsistencies
4. Run `analysis.sql`
5. Update the `.env` file with your database credentials (see `.env`)
6. Run `visualization_script.py` to generate the plots
