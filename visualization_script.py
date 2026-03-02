import matplotlib.pyplot as plt
from sqlalchemy import create_engine
import pandas as pd
from dotenv import load_dotenv
import os
import seaborn as sns
import matplotlib.dates as mdates
import matplotlib.cm as cm

# Global style
sns.set_theme(style="ticks", palette="muted", font_scale=1.1)
SAVE_DPI = 150
LINE_COLOR = "steelblue"

load_dotenv()

# Database connection
engine = create_engine(
    f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
    f"@localhost:5432/{os.getenv('DB_NAME')}"
)

growth         = pd.read_sql("SELECT * FROM growth_overall",  engine)
deliveries     = pd.read_sql("SELECT * FROM deliveries",      engine)
new_customers  = pd.read_sql("SELECT * FROM new_customers",   engine)
customer_repeat= pd.read_sql("SELECT * FROM customer_repeat", engine)
product_orders = pd.read_sql("SELECT * FROM product_orders",  engine)
product_revenue= pd.read_sql("SELECT * FROM product_revenue", engine)
reviews        = pd.read_sql("SELECT * FROM score",           engine)

growth = growth.rename(columns={"average": "average_order_value",
                                 "round":   "revenue_per_month"})

# Shared x-axis date formatting
def format_month_axis(ax):
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
    ax.xaxis.set_major_locator(mdates.MonthLocator())
    plt.xticks(rotation=45, ha="right")


# Revenue vs Month 
fig, ax = plt.subplots(figsize=(10, 6))
sns.lineplot(data=growth[:-2], x="month", y="revenue_per_month",
             ax=ax, color=LINE_COLOR, linewidth=2.5)
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"{x/1e6:.1f}M"))
ax.set_ylim(bottom=0)
ax.set_title("Monthly Revenue", fontsize=14, fontweight="bold")
ax.set_xlabel("Month")
ax.set_ylabel("Revenue (M)")
ax.yaxis.grid(True, linestyle="--", linewidth=0.6, alpha=0.7)
ax.set_axisbelow(True)
sns.despine(ax=ax)
format_month_axis(ax)
plt.tight_layout()
plt.savefig("growth_vs_month.png", dpi=SAVE_DPI)
plt.close()

# Orders vs Month 
fig, ax = plt.subplots(figsize=(10, 6))
sns.lineplot(data=growth[:-2], x="month", y="num_orders",
             ax=ax, color=LINE_COLOR, linewidth=2.5)
ax.set_ylim(bottom=0)
ax.set_title("Monthly Orders", fontsize=14, fontweight="bold")
ax.set_xlabel("Month")
ax.set_ylabel("Number of Orders")
ax.yaxis.grid(True, linestyle="--", linewidth=0.6, alpha=0.7)
ax.set_axisbelow(True)
sns.despine(ax=ax)
format_month_axis(ax)
plt.tight_layout()
plt.savefig("orders_vs_month.png", dpi=SAVE_DPI)
plt.close()

# Average Order Value vs Month 
fig, ax = plt.subplots(figsize=(10, 6))
sns.lineplot(data=growth[5:-2], x="month", y="average_order_value",
             ax=ax, color=LINE_COLOR, linewidth=2.5)
ax.set_ylim(0, 200)
ax.set_title("Average Order Value per Month", fontsize=14, fontweight="bold")
ax.set_xlabel("Month")
ax.set_ylabel("Average Order Value ($)")
ax.yaxis.grid(True, linestyle="--", linewidth=0.6, alpha=0.7)
ax.set_axisbelow(True)
sns.despine(ax=ax)
format_month_axis(ax)
plt.tight_layout()
plt.savefig("average_order_value_vs_month.png", dpi=SAVE_DPI)
plt.close()

# Delivery Performance by State 
deliveries_sorted = deliveries.sort_values("avg_delivery_days", ascending=True)

norm   = plt.Normalize(deliveries_sorted["late_delivery_percent"].min(),
                       deliveries_sorted["late_delivery_percent"].max())
colors = cm.RdYlGn_r(norm(deliveries_sorted["late_delivery_percent"]))

fig, ax = plt.subplots(figsize=(10, max(6, len(deliveries_sorted) * 0.35)))
ax.barh(deliveries_sorted["customer_state"],
        deliveries_sorted["avg_delivery_days"], color=colors)
sm = plt.cm.ScalarMappable(cmap="RdYlGn_r", norm=norm)
sm.set_array([])
plt.colorbar(sm, ax=ax, label="Late Delivery %")
ax.set_xlabel("Avg Delivery Days")
ax.set_title("Delivery Performance by State", fontsize=14, fontweight="bold")
ax.tick_params(axis="y", labelsize=9)
sns.despine(ax=ax)
plt.tight_layout()
plt.savefig("late_deliveries_vs_state.png", dpi=SAVE_DPI)
plt.close()

# New Customers per Month
new_customers["cohort_month"] = pd.to_datetime(new_customers["cohort_month"], unit="ms")
plot_nc = new_customers.iloc[5:-2]

fig, ax = plt.subplots(figsize=(10, 6))
ax.bar(plot_nc["cohort_month"], plot_nc["new_customers"],
       color=LINE_COLOR, width=25)          # width in days — more robust
ax.set_ylim(bottom=0)
ax.set_title("New Customers per Month", fontsize=14, fontweight="bold")
ax.set_xlabel("Month")
ax.set_ylabel("New Customers")
ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
ax.xaxis.set_major_locator(mdates.MonthLocator())
ax.tick_params(labelsize=11)
plt.xticks(rotation=45, ha="right")
sns.despine()
plt.tight_layout()
plt.savefig("new_customers_vs_month.png", dpi=SAVE_DPI)
plt.close()

# Revenue % by Product Category 
product_revenue_sorted = product_revenue.sort_values("revenue_percent", ascending=False)

# Truncate long category names for readability
product_revenue_sorted = product_revenue_sorted.copy()
product_revenue_sorted["category_label"] = (
    product_revenue_sorted["product_category_name"].str.replace("_", " ").str.title().str[:30]
)

fig, ax = plt.subplots(figsize=(10, max(6, len(product_revenue_sorted) * 0.4)))
sns.barplot(data=product_revenue_sorted,
            y="category_label", x="revenue_percent",
            color=LINE_COLOR, ax=ax)
ax.set_title("Revenue Share by Product Category", fontsize=14, fontweight="bold")
ax.set_ylabel("Product Category")
ax.set_xlabel("Revenue (%)")
ax.tick_params(axis="y", labelsize=9)
sns.despine()
plt.tight_layout()
plt.savefig("revenue_percent_vs_product_category.png", dpi=SAVE_DPI)
plt.close()

print("All plots saved successfully.")

