import csv
import uuid
import random
from datetime import datetime, timedelta
import sys

print("Starting Sales CSV generation using existing Customer and Inventory data...")

# Read customer IDs from customers.csv
customer_ids = []
try:
    with open('customers.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            customer_ids.append(row['customer_id'])
    print(f"Loaded {len(customer_ids)} customer IDs from customers.csv")
except FileNotFoundError:
    print("Error: customers.csv not found. Please run generate_customer_csv.py first.")
    sys.exit(1)

# Read product IDs from inventory.csv
product_ids = []
try:
    with open('inventory.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            product_ids.append(row['product_id'])
    print(f"Loaded {len(product_ids)} product IDs from inventory.csv")
except FileNotFoundError:
    print("Error: inventory.csv not found. Please run generate_inventory_csv.py first.")
    sys.exit(1)

# Sales data configuration
payment_methods = ['Credit Card', 'Debit Card', 'Cash', 'PayPal', 'Bank Transfer']
sales_reps = ['Alice Cooper', 'Bob Johnson', 'Charlie Brown', 'Diana Prince', 'Edward Norton']
regions = ['North', 'South', 'East', 'West', 'Central']

filename = 'sales_data_15k.csv'
num_sales = 15000

print(f"Generating {num_sales} sales transactions to {filename}...")

# Generate random datetime between 2023-01-01 and 2024-12-31
start_date = datetime(2023, 1, 1)
end_date = datetime(2024, 12, 31)

try:
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = [
            'sale_id', 'customer_id', 'product_id', 'sale_date', 'quantity', 
            'unit_price', 'total_price', 'discount_percentage', 'final_price',
            'payment_method', 'sales_rep', 'region'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        # Write header
        writer.writeheader()
        print("Header written")
        
        # Generate sales data
        for i in range(num_sales):
            if i % 2000 == 0:
                print(f"Generated {i} sales...")
            
            # Random timestamp
            random_date = start_date + timedelta(
                seconds=random.randint(0, int((end_date - start_date).total_seconds()))
            )
            
            quantity = random.randint(1, 10)
            unit_price = round(random.uniform(9.99, 1999.99), 2)
            total_price = round(quantity * unit_price, 2)
            discount_percentage = random.choice([0, 5, 10, 15, 20, 25])
            discount_amount = round(total_price * (discount_percentage / 100), 2)
            final_price = round(total_price - discount_amount, 2)
            
            row = {
                'sale_id': str(uuid.uuid4()),
                'customer_id': random.choice(customer_ids),  # Link to actual customers
                'product_id': random.choice(product_ids),    # Link to actual products
                'sale_date': random_date.strftime('%Y-%m-%d %H:%M:%S'),
                'quantity': quantity,
                'unit_price': unit_price,
                'total_price': total_price,
                'discount_percentage': discount_percentage,
                'final_price': final_price,
                'payment_method': random.choice(payment_methods),
                'sales_rep': random.choice(sales_reps),
                'region': random.choice(regions)
            }
            writer.writerow(row)
    
    print(f"Successfully generated {num_sales} sales transactions in '{filename}'")
    print(f"Sales data links to:")
    print(f"  - {len(customer_ids)} customers from customers.csv")
    print(f"  - {len(product_ids)} products from inventory.csv")
    print(f"  - All relationships use actual GUIDs from the CSV files")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
