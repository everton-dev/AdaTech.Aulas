import sqlite3
import uuid
import random
from datetime import datetime, timedelta
from decimal import Decimal
import os

def create_database():
    """Create the sales_data.db database and sales table"""

    script_dir = os.path.dirname(os.path.abspath(__file__))
    db_path = os.path.join(script_dir, 'sales_data.db')
    # engine = sqlalchemy.create_engine(f'sqlite:///{db_path}')  # Criar uma conexão com o banco de dados SQLite

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create the sales table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sales (
            sale_id TEXT PRIMARY KEY,
            year INTEGER,
            month INTEGER,
            day INTEGER,
            hour INTEGER,
            minute INTEGER,
            second INTEGER,
            product_id TEXT,
            product_name TEXT,
            quantity INTEGER,
            unit_price REAL
        )
    ''')
    
    conn.commit()
    return conn, cursor

def generate_product_data():
    """Generate sample product data"""
    products = [
        {"name": "Smartphone", "base_price": 599.99},
        {"name": "Laptop", "base_price": 899.99},
        {"name": "Tablet", "base_price": 299.99},
        {"name": "Headphones", "base_price": 129.99},
        {"name": "Smart Watch", "base_price": 249.99},
        {"name": "Bluetooth Speaker", "base_price": 79.99},
        {"name": "Gaming Console", "base_price": 499.99},
        {"name": "Wireless Earbuds", "base_price": 159.99},
        {"name": "4K TV", "base_price": 699.99},
        {"name": "Coffee Machine", "base_price": 199.99},
        {"name": "Air Fryer", "base_price": 89.99},
        {"name": "Robot Vacuum", "base_price": 299.99},
        {"name": "Fitness Tracker", "base_price": 99.99},
        {"name": "Drone", "base_price": 399.99},
        {"name": "Digital Camera", "base_price": 549.99}
    ]
    
    # Generate unique product IDs for each product
    for product in products:
        product["id"] = str(uuid.uuid4())
    
    return products

def calculate_growth_factor(current_date, start_date):
    """Calculate growth factor based on time progression"""
    days_passed = (current_date - start_date).days
    total_days = (datetime.now() - start_date).days
    
    # Growth factor increases over time (1.0 to 2.5)
    growth_factor = 1.0 + (1.5 * days_passed / total_days)
    return growth_factor

def generate_sales_data(products, num_sales=10000):
    """Generate random sales data with growth trend"""
    sales_data = []

    # Define date range from December 1, 2024 to now
    start_date = datetime(2024, 12, 1)
    end_date = datetime.now()
    
    print(f"Generating {num_sales} sales records from {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}")
    
    for i in range(num_sales):
        # Generate random date between start_date and end_date
        time_delta = end_date - start_date
        random_days = random.randint(0, time_delta.days)
        random_seconds = random.randint(0, 86400)  # 24 hours in seconds
        
        sale_date = start_date + timedelta(days=random_days, seconds=random_seconds)
        
        # Calculate growth factor for this date
        growth_factor = calculate_growth_factor(sale_date, start_date)
        
        # Select random product
        product = random.choice(products)
        
        # Generate quantity with growth bias (more sales later in the year)
        base_quantity = random.randint(1, 5)
        if random.random() < growth_factor / 3:  # Higher chance of larger quantities as time progresses
            base_quantity += random.randint(1, 3)
        
        # Add some price variation (±20%)
        price_variation = random.uniform(0.8, 1.2)
        unit_price = round(product["base_price"] * price_variation, 2)
        
        # Create sale record
        sale_record = {
            'sale_id': str(uuid.uuid4()),
            'year': sale_date.year,
            'month': sale_date.month,
            'day': sale_date.day,
            'hour': sale_date.hour,
            'minute': sale_date.minute,
            'second': sale_date.second,
            'product_id': product["id"],
            'product_name': product["name"],
            'quantity': base_quantity * (i + 1),
            'unit_price': unit_price
        }
        
        sales_data.append(sale_record)
        
        # Progress indicator
        if (i + 1) % 1000 == 0:
            print(f"Generated {i + 1} sales records...")
    
    # Sort by date to show chronological growth
    sales_data.sort(key=lambda x: datetime(x['year'], x['month'], x['day'], x['hour'], x['minute'], x['second']))
    
    return sales_data

def insert_sales_data(cursor, sales_data):
    """Insert sales data into the database"""
    print("Inserting sales data into database...")
    
    for i, sale in enumerate(sales_data):
        cursor.execute('''
            INSERT INTO sales (
                sale_id, year, month, day, hour, minute, second,
                product_id, product_name, quantity, unit_price
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            sale['sale_id'], sale['year'], sale['month'], sale['day'],
            sale['hour'], sale['minute'], sale['second'], sale['product_id'],
            sale['product_name'], sale['quantity'], sale['unit_price']
        ))
        
        # Progress indicator
        if (i + 1) % 1000 == 0:
            print(f"Inserted {i + 1} sales records...")

def display_statistics(cursor):
    """Display some statistics about the generated data"""
    print("\n=== DATABASE STATISTICS ===")
    
    # Total records
    cursor.execute("SELECT COUNT(*) FROM sales")
    total_records = cursor.fetchone()[0]
    print(f"Total sales records: {total_records:,}")
    
    # Date range
    cursor.execute("SELECT MIN(year || '-' || month || '-' || day), MAX(year || '-' || month || '-' || day) FROM sales")
    date_range = cursor.fetchone()
    print(f"Date range: {date_range[0]} to {date_range[1]}")
    
    # Total revenue
    cursor.execute("SELECT SUM(quantity * unit_price) FROM sales")
    total_revenue = cursor.fetchone()[0]
    print(f"Total revenue: ${total_revenue:,.2f}")
    
    # Monthly sales growth
    cursor.execute('''
        SELECT year, month, COUNT(*) as sales_count, SUM(quantity * unit_price) as monthly_revenue
        FROM sales 
        GROUP BY year, month 
        ORDER BY year, month
    ''')
    
    monthly_data = cursor.fetchall()
    print(f"\nMonthly Sales Summary:")
    print("Month\t\tSales Count\tRevenue")
    print("-" * 40)
    
    for row in monthly_data:
        year, month, count, revenue = row
        month_name = datetime(year, month, 1).strftime("%B %Y")
        print(f"{month_name}\t{count:,}\t\t${revenue:,.2f}")
    
    # Top products
    cursor.execute('''
        SELECT product_name, COUNT(*) as sales_count, SUM(quantity) as total_quantity, 
               SUM(quantity * unit_price) as product_revenue
        FROM sales 
        GROUP BY product_name 
        ORDER BY product_revenue DESC 
        LIMIT 5
    ''')
    
    top_products = cursor.fetchall()
    print(f"\nTop 5 Products by Revenue:")
    print("Product\t\t\tSales\tQuantity\tRevenue")
    print("-" * 55)
    
    for row in top_products:
        name, sales, quantity, revenue = row
        print(f"{name[:15]:<15}\t{sales}\t{quantity}\t\t${revenue:,.2f}")

def main():
    """Main function to create database and generate sales data"""
    print("Creating sales database with growth trend data...")
    
    # Create database and table
    conn, cursor = create_database()
    
    # Clear existing data if any
    cursor.execute("DELETE FROM sales")
    conn.commit()
    
    # Generate products
    products = generate_product_data()
    print(f"Generated {len(products)} products")
    
    # Generate sales data with growth trend
    sales_data = generate_sales_data(products, 20000)  # Generate 20,000 sales

    # Insert data into database
    insert_sales_data(cursor, sales_data)
    conn.commit()
    
    # Display statistics
    display_statistics(cursor)
    
    # Close connection
    conn.close()
    
    print(f"\nDatabase 'sales_data.db' created successfully!")
    print("The database shows sales growth from January 2025 to present.")

if __name__ == "__main__":
    main()
