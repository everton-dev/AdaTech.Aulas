import azure.functions as func
import logging
import pyodbc
import json
import os

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

def get_db_connection():
    """
    Establishes connection to Azure SQL Server
    Returns database connection object
    Best Practice: Using environment variables for sensitive data
    """
    # Use environment variables for sensitive information
    server = os.environ.get('SQL_SERVER', 'adatech-sql-server.database.windows.net')
    database = os.environ.get('SQL_DATABASE', 'adatech-sql-database')
    username = os.environ.get('SQL_USERNAME', 'everton')
    password = os.environ.get('SQL_PASSWORD', 'Adatech123*')
    driver = '{ODBC Driver 18 for SQL Server}'
    
    # Connection string with encryption and trust settings for Azure SQL
    connection_string = f'DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
    
    try:
        connection = pyodbc.connect(connection_string)
        logging.info('Successfully connected to Azure SQL Database')
        return connection
    except Exception as e:
        logging.error(f'Error connecting to database: {str(e)}')
        raise

@app.route(route="api/customers", methods=["GET"])
def customers(req: func.HttpRequest) -> func.HttpResponse:
    """
    GET endpoint to retrieve customers from the database
    Returns JSON list of customers
    Best Practice: Proper resource management and error handling
    """
    logging.info('Processing GET request for customers endpoint')
    
    connection = None
    cursor = None
    
    try:
        # Establish database connection
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Execute query to get all customers
        # Using parameterized query for security (even though no params here)
        query = "SELECT * FROM Customer"
        cursor.execute(query)
        
        # Fetch all results
        rows = cursor.fetchall()
        
        # Get column names for JSON formatting
        columns = [column[0] for column in cursor.description]
        
        # Convert rows to list of dictionaries
        customers_list = []
        for row in rows:
            customer_dict = dict(zip(columns, row))
            customers_list.append(customer_dict)
        
        logging.info(f'Successfully retrieved {len(customers_list)} customers')
        
        # Return JSON response
        return func.HttpResponse(
            json.dumps(customers_list, default=str),  # default=str handles datetime serialization
            status_code=200,
            mimetype="application/json"
        )
        
    except pyodbc.Error as db_error:
        logging.error(f'Database error: {str(db_error)}')
        return func.HttpResponse(
            json.dumps({"error": "Database connection or query failed", "details": str(db_error)}),
            status_code=500,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f'Unexpected error: {str(e)}')
        return func.HttpResponse(
            json.dumps({"error": "Internal server error", "details": str(e)}),
            status_code=500,
            mimetype="application/json"
        )
    finally:
        # Best Practice: Always clean up resources in finally block
        if cursor:
            try:
                cursor.close()
            except:
                pass
        if connection:
            try:
                connection.close()
            except:
                pass