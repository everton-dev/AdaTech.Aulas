import pandas as pd
import sqlalchemy
import os

# 01 - Extract

script_directory = os.path.dirname(os.path.abspath(__file__))
database_path = os.path.join(script_directory, 'sales_data.db')

engine = sqlalchemy.create_engine(f'sqlite:///{database_path}')  # Create a connection to the SQLite database
query = "SELECT * FROM sales"  # Define the SQL query to extract sales data
data = pd.read_sql(query, engine)  # Read the data from the SQL query into a pandas DataFrame

print(data.head())  # Display the first few rows of the extracted data

# 02 - Transform
data['sales_amount'] = data['quantity'] * data['unit_price']  # Calculate the total sales amount
monthly_sales = data.groupby(['year', 'month']).agg(total_sales=('sales_amount', 'sum'))  # Aggregate monthly sales
monthly_sales['sales_growth'] = monthly_sales['total_sales'].pct_change()  # Calculate sales growth

# Reset index to make year and month regular columns
monthly_sales = monthly_sales.reset_index()

# Add month_name column
month_names = {
    1: 'January', 
    2: 'February', 
    3: 'March', 
    4: 'April', 
    5: 'May', 
    6: 'June', 
    7: 'July', 
    8: 'August',
    9: 'September', 
    10: 'October', 
    11: 'November', 
    12: 'December'
}
monthly_sales['month_name'] = monthly_sales['month'].map(month_names)
print(monthly_sales.head())  # Display the first few rows of the transformed data

# 03 - Load
monthly_sales.to_sql('monthly_sales', engine, if_exists='replace', index=False)  # Load the transformed data into a new table in the database
print("Data loaded successfully!")  # Confirmation message for successful loading
