import csv
import uuid
import random
from datetime import datetime, timedelta
import sys

print("Starting Inventory CSV generation...")

# Sample product data
product_names = [
    'Laptop Dell XPS 13', 'Wireless Mouse Logitech', 'Mechanical Keyboard Corsair', 
    '4K Monitor LG', 'Gaming Headphones Sony', 'iPhone 15 Pro', 'iPad Air', 
    'HP LaserJet Printer', 'Document Scanner Canon', 'HD Webcam Logitech',
    'Bluetooth Speaker JBL', 'WiFi Router Netgear', 'External Hard Drive Seagate', 
    'NVMe SSD Samsung', 'DDR4 RAM Corsair', 'RTX 4080 Graphics Card', 
    'ASUS Gaming Motherboard', 'Modular Power Supply Seasonic', 'CPU Cooler Noctua', 
    'Gaming Case Fractal Design', 'USB-C Cable Anker', 'HDMI 2.1 Cable', 
    'Cat6 Ethernet Cable', 'Fast Charger Apple', 'Power Bank RAVPower',
    'DSLR Camera Canon EOS', 'USB Microphone Blue Yeti', 'Smart TV Samsung 55"', 
    'Ergonomic Gaming Chair', 'LED Desk Lamp Philips', 'MacBook Air M2', 
    'Magic Mouse Apple', 'Apple Keyboard', 'Studio Display Apple', 'AirPods Pro',
    'Samsung Galaxy S24', 'Surface Pro Microsoft', 'Canon Pixma Printer', 
    'Epson Scanner V600', 'Logitech C920 Webcam', 'JBL Charge Speaker', 
    'Netgear Nighthawk Router', 'Seagate Backup Drive', 'Samsung T7 SSD', 
    'Corsair Vengeance RAM', 'NVIDIA RTX 4070', 'MSI Gaming Motherboard', 
    'Seasonic Focus PSU', 'Noctua NH-D15 Cooler', 'Fractal Define Case'
]

categories = [
    'Computers & Laptops', 'Computer Accessories', 'Mobile Devices', 'Audio & Video',
    'Printers & Scanners', 'Networking', 'Storage', 'Gaming', 'Office Supplies',
    'Electronics'
]

brands = [
    'Apple', 'Samsung', 'Dell', 'HP', 'Lenovo', 'ASUS', 'MSI', 'Corsair',
    'Logitech', 'Sony', 'Canon', 'Epson', 'LG', 'Philips', 'JBL', 
    'Netgear', 'Seagate', 'Western Digital', 'NVIDIA', 'AMD', 'Intel'
]

suppliers = [
    'Tech Distributors Inc', 'Global Electronics Ltd', 'Hardware Solutions Corp',
    'Digital Supply Chain', 'Component Warehouse LLC', 'Premium Tech Partners',
    'Advanced Electronics Group', 'Innovation Suppliers Co'
]

warehouses = [
    'Warehouse A - North Wing', 'Warehouse B - South Wing', 
    'Warehouse C - East Wing', 'Warehouse D - West Wing',
    'Central Storage Facility', 'Distribution Center 1',
    'Distribution Center 2', 'Overflow Storage Unit'
]

filename = 'inventory.csv'
num_products = 500

print(f"Generating {num_products} products to {filename}...")

try:
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = [
            'product_id', 'product_name', 'category', 'brand', 'supplier_name',
            'cost_price', 'selling_price', 'stock_quantity', 'reorder_level',
            'warehouse_location', 'date_added', 'weight_kg', 'dimensions_cm',
            'barcode', 'warranty_months', 'is_active'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        # Write header
        writer.writeheader()
        print("Header written")
        
        # Generate product data
        for i in range(num_products):
            if i % 50 == 0:
                print(f"Generated {i} products...")
            
            # Choose base product and modify name slightly for variety
            base_product = random.choice(product_names)
            if random.random() > 0.7:  # 30% chance to add variant
                variants = ['Pro', 'Max', 'Plus', 'Lite', 'Standard', 'Premium', 'Basic']
                product_name = f"{base_product} {random.choice(variants)}"
            else:
                product_name = base_product
            
            cost_price = round(random.uniform(10, 1000), 2)
            markup = random.uniform(1.2, 2.5)  # 20% to 150% markup
            selling_price = round(cost_price * markup, 2)
            
            # Generate date added (within last year)
            date_added = datetime.now() - timedelta(days=random.randint(1, 365))
            
            row = {
                'product_id': str(uuid.uuid4()),
                'product_name': product_name,
                'category': random.choice(categories),
                'brand': random.choice(brands),
                'supplier_name': random.choice(suppliers),
                'cost_price': cost_price,
                'selling_price': selling_price,
                'stock_quantity': random.randint(0, 1000),
                'reorder_level': random.randint(5, 50),
                'warehouse_location': random.choice(warehouses),
                'date_added': date_added.strftime('%Y-%m-%d %H:%M:%S'),
                'weight_kg': round(random.uniform(0.1, 50.0), 3),
                'dimensions_cm': f"{random.randint(5, 50)}x{random.randint(5, 50)}x{random.randint(5, 50)}",
                'barcode': f"BAR{random.randint(1000000000, 9999999999)}",
                'warranty_months': random.choice([6, 12, 24, 36]),
                'is_active': random.choice([True, True, True, False])  # 75% active
            }
            writer.writerow(row)
    
    print(f"Successfully generated {num_products} products in '{filename}'")
    print("Inventory CSV file is ready!")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
