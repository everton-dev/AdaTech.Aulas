import pandas as pd
import uuid

# Define a function to generate a proper GUID
def generate_valid_guid():
    return str(uuid.uuid4())

# Define a function to clean and fix the product_id column
def clean_product_id(product_id):
    # Remove any non-hexadecimal characters except hyphens
    cleaned_id = ''.join(c for c in product_id if c.lower() in '0123456789abcdef-')
    
    # Check if it's a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
    parts = cleaned_id.split('-')
    if len(parts) == 5 and len(parts[0]) == 8 and len(parts[1]) == 4 and len(parts[2]) == 4 and len(parts[3]) == 4 and len(parts[4]) == 12:
        # Check if all parts contain only hex characters
        try:
            for part in parts:
                int(part, 16)  # This will raise ValueError if not hex
            return cleaned_id
        except ValueError:
            pass
    
    # If not valid, generate a new GUID
    return generate_valid_guid()

# Process each file individually
files = ['products_01.csv', 'products_02.csv', 'products_03.csv', 'products_04.csv']

for file in files:
    print(f"Processing {file}...")
    df = pd.read_csv(file)
    
    # Show original format
    print(f"Original GUID example: {df['product_id'].iloc[0]}")
    
    # Apply the cleaning function to the 'product_id' column
    df['product_id'] = df['product_id'].apply(clean_product_id)
    
    # Show cleaned format
    print(f"Cleaned GUID example: {df['product_id'].iloc[0]}")
    
    # Save back to the same file
    df.to_csv(file, index=False)
    print(f"Updated {file} with valid GUIDs\n")

print("All files have been updated with valid GUID formats compatible with .NET!")