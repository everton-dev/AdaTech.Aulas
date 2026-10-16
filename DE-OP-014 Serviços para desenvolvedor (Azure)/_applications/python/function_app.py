"""
Azure Functions App for Product CRUD Operations
Python v2 Programming Model
"""
import logging
import json
import azure.functions as func
from shared.database import DatabaseManager

# Initialize the Function App
app = func.FunctionApp()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route(route="products", methods=["GET"], auth_level=func.AuthLevel.FUNCTION)
def get_all_products(req: func.HttpRequest) -> func.HttpResponse:
    """
    Get all products from the database.
    
    Returns:
        200: List of all products
        500: Internal server error
    """
    logger.info('Processing GET request for all products')
    
    try:
        db = DatabaseManager()
        products = db.get_all_products()
        
        return func.HttpResponse(
            body=json.dumps(products),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logger.error(f"Error retrieving products: {str(e)}")
        return func.HttpResponse(
            body=json.dumps({"error": "Internal server error", "message": str(e)}),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="products/{id}", methods=["GET"], auth_level=func.AuthLevel.FUNCTION)
def get_product_by_id(req: func.HttpRequest) -> func.HttpResponse:
    """
    Get a specific product by ID.
    
    Args:
        id: Product ID from route parameter
        
    Returns:
        200: Product details
        404: Product not found
        400: Invalid ID format
        500: Internal server error
    """
    logger.info('Processing GET request for product by ID')
    
    try:
        # Get ID from route parameters
        product_id = req.route_params.get('id')
        
        # Validate ID
        try:
            product_id = int(product_id)
        except (ValueError, TypeError):
            return func.HttpResponse(
                body=json.dumps({"error": "Invalid product ID format"}),
                mimetype="application/json",
                status_code=400
            )
        
        db = DatabaseManager()
        product = db.get_product_by_id(product_id)
        
        if product:
            return func.HttpResponse(
                body=json.dumps(product),
                mimetype="application/json",
                status_code=200
            )
        else:
            return func.HttpResponse(
                body=json.dumps({"error": "Product not found"}),
                mimetype="application/json",
                status_code=404
            )
            
    except Exception as e:
        logger.error(f"Error retrieving product: {str(e)}")
        return func.HttpResponse(
            body=json.dumps({"error": "Internal server error", "message": str(e)}),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="products", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def create_product(req: func.HttpRequest) -> func.HttpResponse:
    """
    Create a new product.
    
    Request Body:
        {
            "name": "Product Name"
        }
        
    Returns:
        201: Product created successfully
        400: Invalid request body
        500: Internal server error
    """
    logger.info('Processing POST request to create product')
    
    try:
        # Parse request body
        try:
            req_body = req.get_json()
        except ValueError:
            return func.HttpResponse(
                body=json.dumps({"error": "Invalid JSON in request body"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Validate required fields
        product_name = req_body.get('name')
        if not product_name or not isinstance(product_name, str):
            return func.HttpResponse(
                body=json.dumps({"error": "Product name is required and must be a string"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Validate name length (max 100 characters as per database schema)
        if len(product_name) > 100:
            return func.HttpResponse(
                body=json.dumps({"error": "Product name must not exceed 100 characters"}),
                mimetype="application/json",
                status_code=400
            )
        
        db = DatabaseManager()
        product_id = db.create_product(product_name)
        
        return func.HttpResponse(
            body=json.dumps({
                "message": "Product created successfully",
                "id": product_id,
                "name": product_name
            }),
            mimetype="application/json",
            status_code=201
        )
        
    except Exception as e:
        logger.error(f"Error creating product: {str(e)}")
        return func.HttpResponse(
            body=json.dumps({"error": "Internal server error", "message": str(e)}),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="products/{id}", methods=["PUT"], auth_level=func.AuthLevel.FUNCTION)
def update_product(req: func.HttpRequest) -> func.HttpResponse:
    """
    Update an existing product.
    
    Args:
        id: Product ID from route parameter
        
    Request Body:
        {
            "name": "Updated Product Name"
        }
        
    Returns:
        200: Product updated successfully
        404: Product not found
        400: Invalid request
        500: Internal server error
    """
    logger.info('Processing PUT request to update product')
    
    try:
        # Get ID from route parameters
        product_id = req.route_params.get('id')
        
        # Validate ID
        try:
            product_id = int(product_id)
        except (ValueError, TypeError):
            return func.HttpResponse(
                body=json.dumps({"error": "Invalid product ID format"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Parse request body
        try:
            req_body = req.get_json()
        except ValueError:
            return func.HttpResponse(
                body=json.dumps({"error": "Invalid JSON in request body"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Validate required fields
        product_name = req_body.get('name')
        if not product_name or not isinstance(product_name, str):
            return func.HttpResponse(
                body=json.dumps({"error": "Product name is required and must be a string"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Validate name length
        if len(product_name) > 100:
            return func.HttpResponse(
                body=json.dumps({"error": "Product name must not exceed 100 characters"}),
                mimetype="application/json",
                status_code=400
            )
        
        db = DatabaseManager()
        success = db.update_product(product_id, product_name)
        
        if success:
            return func.HttpResponse(
                body=json.dumps({
                    "message": "Product updated successfully",
                    "id": product_id,
                    "name": product_name
                }),
                mimetype="application/json",
                status_code=200
            )
        else:
            return func.HttpResponse(
                body=json.dumps({"error": "Product not found"}),
                mimetype="application/json",
                status_code=404
            )
            
    except Exception as e:
        logger.error(f"Error updating product: {str(e)}")
        return func.HttpResponse(
            body=json.dumps({"error": "Internal server error", "message": str(e)}),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="products/{id}", methods=["DELETE"], auth_level=func.AuthLevel.FUNCTION)
def delete_product(req: func.HttpRequest) -> func.HttpResponse:
    """
    Delete a product by ID.
    
    Args:
        id: Product ID from route parameter
        
    Returns:
        200: Product deleted successfully
        404: Product not found
        400: Invalid ID format
        500: Internal server error
    """
    logger.info('Processing DELETE request for product')
    
    try:
        # Get ID from route parameters
        product_id = req.route_params.get('id')
        
        # Validate ID
        try:
            product_id = int(product_id)
        except (ValueError, TypeError):
            return func.HttpResponse(
                body=json.dumps({"error": "Invalid product ID format"}),
                mimetype="application/json",
                status_code=400
            )
        
        db = DatabaseManager()
        success = db.delete_product(product_id)
        
        if success:
            return func.HttpResponse(
                body=json.dumps({
                    "message": "Product deleted successfully",
                    "id": product_id
                }),
                mimetype="application/json",
                status_code=200
            )
        else:
            return func.HttpResponse(
                body=json.dumps({"error": "Product not found"}),
                mimetype="application/json",
                status_code=404
            )
            
    except Exception as e:
        logger.error(f"Error deleting product: {str(e)}")
        return func.HttpResponse(
            body=json.dumps({"error": "Internal server error", "message": str(e)}),
            mimetype="application/json",
            status_code=500
        )
