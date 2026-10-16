import csv
import uuid
import random
from datetime import datetime, timedelta
import sys

print("Starting Customer CSV generation...")

# Sample data for customers
first_names = [
    'John', 'Mary', 'Robert', 'Patricia', 'Michael', 'Linda', 'William', 'Barbara',
    'David', 'Susan', 'James', 'Jessica', 'Christopher', 'Sarah', 'Daniel', 'Karen',
    'Matthew', 'Nancy', 'Anthony', 'Lisa', 'Mark', 'Helen', 'Steven', 'Michelle',
    'Paul', 'Carol', 'Joshua', 'Amanda', 'Andrew', 'Donna', 'Kenneth', 'Ruth',
    'Brian', 'Sharon', 'Kevin', 'Betty', 'Edward', 'Cynthia', 'Timothy', 'Amy',
    'Jose', 'Angela', 'Jacob', 'Brenda', 'Harold', 'Emma', 'Walter', 'Olivia',
    'Henry', 'Marie', 'Arthur', 'Julie', 'Roger', 'Joyce', 'Joe', 'Virginia'
]

last_names = [
    'Smith', 'Johnson', 'Brown', 'Davis', 'Wilson', 'Moore', 'Taylor', 'Anderson',
    'Thomas', 'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez',
    'Rodriguez', 'Lewis', 'Lee', 'Walker', 'Hall', 'Allen', 'Young', 'King',
    'Wright', 'Lopez', 'Hill', 'Scott', 'Green', 'Adams', 'Baker', 'Nelson',
    'Carter', 'Mitchell', 'Perez', 'Roberts', 'Turner', 'Phillips', 'Campbell', 'Parker',
    'Evans', 'Edwards', 'Collins', 'Stewart', 'Sanchez', 'Morris', 'Rogers', 'Reed',
    'Cook', 'Bailey', 'Cooper', 'Richardson', 'Cox', 'Howard', 'Ward', 'Torres'
]

cities_states = [
    ('New York', 'NY'), ('Los Angeles', 'CA'), ('Chicago', 'IL'), ('Houston', 'TX'),
    ('Phoenix', 'AZ'), ('Philadelphia', 'PA'), ('San Antonio', 'TX'), ('San Diego', 'CA'),
    ('Dallas', 'TX'), ('San Jose', 'CA'), ('Austin', 'TX'), ('Jacksonville', 'FL'),
    ('Fort Worth', 'TX'), ('Columbus', 'OH'), ('Charlotte', 'NC'), ('San Francisco', 'CA'),
    ('Indianapolis', 'IN'), ('Seattle', 'WA'), ('Denver', 'CO'), ('Washington', 'DC'),
    ('Boston', 'MA'), ('El Paso', 'TX'), ('Nashville', 'TN'), ('Detroit', 'MI'),
    ('Oklahoma City', 'OK'), ('Portland', 'OR'), ('Las Vegas', 'NV'), ('Memphis', 'TN'),
    ('Louisville', 'KY'), ('Baltimore', 'MD')
]

email_domains = [
    'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'aol.com', 
    'icloud.com', 'protonmail.com', 'live.com'
]

customer_tiers = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond']
contact_methods = ['Email', 'Phone', 'SMS']

filename = 'customers.csv'
num_customers = 100

print(f"Generating {num_customers} customers to {filename}...")

try:
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = [
            'customer_id', 'first_name', 'last_name', 'email', 'phone', 
            'date_of_birth', 'gender', 'address_line1', 'city', 'state_province',
            'postal_code', 'country', 'registration_date', 'customer_tier',
            'credit_limit', 'loyalty_points', 'preferred_contact_method',
            'marketing_consent', 'is_active'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        # Write header
        writer.writeheader()
        print("Header written")
        
        # Generate customer data
        for i in range(num_customers):
            if i % 20 == 0:
                print(f"Generated {i} customers...")
            
            first_name = random.choice(first_names)
            last_name = random.choice(last_names)
            city, state = random.choice(cities_states)
            domain = random.choice(email_domains)
            
            # Generate date of birth (18-65 years old)
            birth_date = datetime.now() - timedelta(days=random.randint(18*365, 65*365))
            
            # Generate registration date (within last 3 years)
            reg_date = datetime.now() - timedelta(days=random.randint(1, 1095))
            
            row = {
                'customer_id': str(uuid.uuid4()),
                'first_name': first_name,
                'last_name': last_name,
                'email': f"{first_name.lower()}.{last_name.lower()}{i+1:03d}@{domain}",
                'phone': f"+1{random.randint(2000000000, 9999999999)}",
                'date_of_birth': birth_date.strftime('%Y-%m-%d'),
                'gender': random.choice(['M', 'F']),
                'address_line1': f"{random.randint(100, 9999)} {random.choice(['Main St', 'Oak Ave', 'Pine Rd', 'Elm Dr', 'Cedar Ln', 'Maple St'])}",
                'city': city,
                'state_province': state,
                'postal_code': f"{random.randint(10000, 99999)}",
                'country': 'USA',
                'registration_date': reg_date.strftime('%Y-%m-%d %H:%M:%S'),
                'customer_tier': random.choice(customer_tiers),
                'credit_limit': round(random.uniform(1000, 10000), 2),
                'loyalty_points': random.randint(0, 10000),
                'preferred_contact_method': random.choice(contact_methods),
                'marketing_consent': random.choice([True, False]),
                'is_active': random.choice([True, True, True, False])  # 75% active
            }
            writer.writerow(row)
    
    print(f"Successfully generated {num_customers} customers in '{filename}'")
    print("Customer CSV file is ready!")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
