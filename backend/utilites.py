import pandas as pd

def clean_csv(file):
    df = pd.read_csv(file)

    # Normalize column names
    df.columns = df.columns.str.strip().str.lower()

    # Strip spaces in string columns
    df['product_name'] = df['product_name'].astype(str).str.strip().str.lower()
    df['buyer'] = df['buyer'].astype(str).str.strip().str.lower()

    # Convert types safely
    df['amount'] = pd.to_numeric(df['amount'], errors='coerce')
    df['date'] = pd.to_datetime(df['date'], errors='coerce')

    # Drop invalid rows
    df.dropna(inplace=True)

    return df
def generate_analytics(df):
    results = {}

    # 💰 Total Revenue
    total_revenue = df['amount'].sum()
    results["total_revenue"] = float(total_revenue)

    # 📈 Profit (assume 20%)
    profit = total_revenue * 0.2
    results["profit"] = float(profit)

    # 👥 Customer Retention
    total_customers = df['buyer'].nunique()
    total_orders = len(df)
    retention = (total_customers / total_orders) * 100
    results["retention"] = round(retention, 2)

    # 📊 SALES OVER TIME (for graph)
    sales_over_time = (
        df.groupby(df['date'].dt.date)['amount']
        .sum()
        .reset_index()
    )

    results["sales_over_time"] = [
        {"date": str(row['date']), "sales": float(row['amount'])}
        for _, row in sales_over_time.iterrows()
    ]

    # 📦 PRODUCT SALES (for list)
    product_sales = df.groupby('product_name')['amount'].sum()

    results["products"] = [
        {
            "name": product,
            "growth": float(product_sales[product])  # using sales as growth for now
        }
        for product in product_sales.index
    ]

    return results