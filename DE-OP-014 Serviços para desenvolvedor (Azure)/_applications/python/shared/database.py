"""
Database Manager Module for Azure SQL Database
Implements connection pooling and CRUD operations for the product table
"""
import os
import logging
import pyodbc
from typing import Optional, List, Dict, Any
from contextlib import contextmanager

logger = logging.getLogger(__name__)


class DatabaseManager:
    """
    Manages database connections and CRUD operations for products.
    Uses Azure SQL Database with pyodbc driver.
    """
    
    def __init__(self):
        """Initialize database connection parameters from environment variables."""
        self.server = os.environ.get('SQL_SERVER')
        self.database = os.environ.get('SQL_DATABASE')
        self.username = os.environ.get('SQL_USERNAME')
        self.password = os.environ.get('SQL_PASSWORD')
        self.driver = os.environ.get('SQL_DRIVER', '{ODBC Driver 18 for SQL Server}')
        
        # Validate required environment variables
        if not all([self.server, self.database, self.username, self.password]):
            raise ValueError(
                "Missing required database configuration. "
                "Please set SQL_SERVER, SQL_DATABASE, SQL_USERNAME, and SQL_PASSWORD."
            )
    
    def _get_connection_string(self) -> str:
        """
        Build connection string for Azure SQL Database.
        
        Returns:
            Formatted connection string with security settings
        """
        return (
            f'DRIVER={self.driver};'
            f'SERVER=tcp:{self.server};'
            f'PORT=1433;'
            f'DATABASE={self.database};'
            f'UID={self.username};'
            f'PWD={self.password};'
            f'Encrypt=yes;'
            f'TrustServerCertificate=no;'
            f'Connection Timeout=30;'
        )
    
    @contextmanager
    def _get_connection(self):
        """
        Context manager for database connections.
        Ensures proper connection closure and error handling.
        
        Yields:
            pyodbc.Connection: Active database connection
        """
        conn = None
        try:
            conn = pyodbc.connect(self._get_connection_string())
            yield conn
        except pyodbc.Error as e:
            logger.error(f"Database connection error: {str(e)}")
            raise
        finally:
            if conn:
                conn.close()
    
    def get_all_products(self) -> List[Dict[str, Any]]:
        """
        Retrieve all products from the database.
        
        Returns:
            List of product dictionaries with id and name
            
        Raises:
            Exception: If database query fails
        """
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT id, name FROM product ORDER BY id")
                
                products = []
                for row in cursor.fetchall():
                    products.append({
                        "id": row.id,
                        "name": row.name
                    })
                
                logger.info(f"Retrieved {len(products)} products")
                return products
                
        except Exception as e:
            logger.error(f"Error in get_all_products: {str(e)}")
            raise
    
    def get_product_by_id(self, product_id: int) -> Optional[Dict[str, Any]]:
        """
        Retrieve a specific product by ID.
        
        Args:
            product_id: ID of the product to retrieve
            
        Returns:
            Product dictionary if found, None otherwise
            
        Raises:
            Exception: If database query fails
        """
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT id, name FROM product WHERE id = ?",
                    (product_id,)
                )
                
                row = cursor.fetchone()
                if row:
                    product = {
                        "id": row.id,
                        "name": row.name
                    }
                    logger.info(f"Retrieved product with id {product_id}")
                    return product
                else:
                    logger.info(f"Product with id {product_id} not found")
                    return None
                    
        except Exception as e:
            logger.error(f"Error in get_product_by_id: {str(e)}")
            raise
    
    def create_product(self, name: str) -> int:
        """
        Create a new product in the database.
        
        Args:
            name: Name of the product (max 100 characters)
            
        Returns:
            ID of the newly created product
            
        Raises:
            Exception: If database insert fails
        """
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO product (name) VALUES (?)",
                    (name,)
                )
                conn.commit()
                
                # Get the last inserted ID
                cursor.execute("SELECT @@IDENTITY AS id")
                product_id = cursor.fetchone().id
                
                logger.info(f"Created product with id {product_id}")
                return product_id
                
        except Exception as e:
            logger.error(f"Error in create_product: {str(e)}")
            raise
    
    def update_product(self, product_id: int, name: str) -> bool:
        """
        Update an existing product's name.
        
        Args:
            product_id: ID of the product to update
            name: New name for the product (max 100 characters)
            
        Returns:
            True if product was updated, False if product not found
            
        Raises:
            Exception: If database update fails
        """
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "UPDATE product SET name = ? WHERE id = ?",
                    (name, product_id)
                )
                conn.commit()
                
                rows_affected = cursor.rowcount
                if rows_affected > 0:
                    logger.info(f"Updated product with id {product_id}")
                    return True
                else:
                    logger.info(f"Product with id {product_id} not found for update")
                    return False
                    
        except Exception as e:
            logger.error(f"Error in update_product: {str(e)}")
            raise
    
    def delete_product(self, product_id: int) -> bool:
        """
        Delete a product from the database.
        
        Args:
            product_id: ID of the product to delete
            
        Returns:
            True if product was deleted, False if product not found
            
        Raises:
            Exception: If database delete fails
        """
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "DELETE FROM product WHERE id = ?",
                    (product_id,)
                )
                conn.commit()
                
                rows_affected = cursor.rowcount
                if rows_affected > 0:
                    logger.info(f"Deleted product with id {product_id}")
                    return True
                else:
                    logger.info(f"Product with id {product_id} not found for deletion")
                    return False
                    
        except Exception as e:
            logger.error(f"Error in delete_product: {str(e)}")
            raise
