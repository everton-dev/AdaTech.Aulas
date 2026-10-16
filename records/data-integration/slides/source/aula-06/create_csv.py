import csv
import uuid
import random
from datetime import datetime, timedelta
import sys

print("Starting CSV generation...")

# Sample product names
product_names = [
    "Laptop", "Mouse", "Keyboard", "Monitor", "Headphones", 
    "Smartphone", "Tablet", "Printer", "Scanner", "Webcam",
    "Speaker", "Router", "Hard Drive", "SSD", "RAM",
    "Graphics Card", "Motherboard", "Power Supply", "CPU Cooler", "Case",
    "USB Cable", "HDMI Cable", "Ethernet Cable", "Charger", "Battery",
    "Camera", "Microphone", "TV", "Gaming Chair", "Desk Lamp"
]

filename = 'random_sales_data.csv'
num_rows = 20000

print(f"Generating {num_rows} rows to {filename}...")

# Generate random datetime between 2023-01-01 and 2024-12-31
start_date = datetime(2023, 1, 1)
end_date = datetime(2024, 12, 31)

try:
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['order_id', 'product_id', 'timestamp', 'product_name', 'quantity', 'unit_price']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        # Write header
        writer.writeheader()
        print("Header written")
        
        # Generate random data
        for i in range(num_rows):
            if i % 2000 == 0:
                print(f"Generated {i} rows...")
            
            # Random timestamp
            random_date = start_date + timedelta(
                seconds=random.randint(0, int((end_date - start_date).total_seconds()))
            )
            
            row = {
                'order_id': str(uuid.uuid4()),
                'product_id': str(uuid.uuid4()),
                'timestamp': random_date.strftime('%Y-%m-%d %H:%M:%S'),
                'product_name': random.choice(product_names),
                'quantity': random.randint(1, 100),
                'unit_price': round(random.uniform(5.99, 999.99), 2)
            }
            writer.writerow(row)
    
    print(f"Successfully generated {num_rows} rows of random sales data in '{filename}'")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
