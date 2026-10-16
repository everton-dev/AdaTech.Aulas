"""
Test script to verify the function app logic without Azure Functions runtime.
This allows you to test the database operations independently.
"""
import os
import sys
import json

# Add the parent directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Set environment variables for testing
os.environ['SQL_SERVER'] = 'your-server.database.windows.net'
os.environ['SQL_DATABASE'] = 'your-database-name'
os.environ['SQL_USERNAME'] = 'your-username'
os.environ['SQL_PASSWORD'] = 'your-password'
os.environ['SQL_DRIVER'] = '{ODBC Driver 18 for SQL Server}'

from shared.database import DatabaseManager


def test_database_connection():
    """Test the database connection."""
    print("Testing database connection...")
    try:
        db = DatabaseManager()
        print("✓ Database manager initialized successfully")
        return db
    except Exception as e:
        print(f"✗ Failed to initialize database: {e}")
        return None


def test_get_all_products(db):
    """Test getting all products."""
    print("\nTesting get_all_products...")
    try:
        products = db.get_all_products()
        print(f"✓ Retrieved {len(products)} products:")
        print(json.dumps(products, indent=2))
        return True
    except Exception as e:
        print(f"✗ Failed to get products: {e}")
        return False


def test_create_product(db):
    """Test creating a product."""
    print("\nTesting create_product...")
    try:
        product_id = db.create_product("Test Product")
        print(f"✓ Created product with ID: {product_id}")
        return product_id
    except Exception as e:
        print(f"✗ Failed to create product: {e}")
        return None


def test_get_product_by_id(db, product_id):
    """Test getting a product by ID."""
    print(f"\nTesting get_product_by_id with ID {product_id}...")
    try:
        product = db.get_product_by_id(product_id)
        if product:
            print(f"✓ Retrieved product:")
            print(json.dumps(product, indent=2))
            return True
        else:
            print(f"✗ Product not found")
            return False
    except Exception as e:
        print(f"✗ Failed to get product: {e}")
        return False


def test_update_product(db, product_id):
    """Test updating a product."""
    print(f"\nTesting update_product with ID {product_id}...")
    try:
        success = db.update_product(product_id, "Updated Test Product")
        if success:
            print(f"✓ Updated product successfully")
            return True
        else:
            print(f"✗ Product not found for update")
            return False
    except Exception as e:
        print(f"✗ Failed to update product: {e}")
        return False


def test_delete_product(db, product_id):
    """Test deleting a product."""
    print(f"\nTesting delete_product with ID {product_id}...")
    try:
        success = db.delete_product(product_id)
        if success:
            print(f"✓ Deleted product successfully")
            return True
        else:
            print(f"✗ Product not found for deletion")
            return False
    except Exception as e:
        print(f"✗ Failed to delete product: {e}")
        return False


def main():
    """Run all tests."""
    print("=" * 60)
    print("Azure Function App - Database Tests")
    print("=" * 60)
    
    # Initialize database
    db = test_database_connection()
    if not db:
        print("\n❌ Cannot proceed without database connection")
        print("\nPlease update the environment variables in this script:")
        print("- SQL_SERVER")
        print("- SQL_DATABASE")
        print("- SQL_USERNAME")
        print("- SQL_PASSWORD")
        return
    
    # Run tests
    print("\n" + "=" * 60)
    print("Running CRUD Tests")
    print("=" * 60)
    
    # Test Get All
    test_get_all_products(db)
    
    # Test Create
    product_id = test_create_product(db)
    
    if product_id:
        # Test Get By ID
        test_get_product_by_id(db, product_id)
        
        # Test Update
        test_update_product(db, product_id)
        
        # Verify update
        test_get_product_by_id(db, product_id)
        
        # Test Delete
        test_delete_product(db, product_id)
        
        # Verify deletion
        test_get_product_by_id(db, product_id)
    
    print("\n" + "=" * 60)
    print("Tests completed!")
    print("=" * 60)


if __name__ == "__main__":
    main()
