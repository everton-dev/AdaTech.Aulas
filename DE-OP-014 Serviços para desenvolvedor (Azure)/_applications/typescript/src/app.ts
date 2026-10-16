/**
 * Azure Functions App Entry Point
 * 
 * This file serves as the main entry point for the Azure Functions application.
 * All HTTP trigger functions are imported here to ensure they are registered
 * with the Azure Functions runtime.
 * 
 * The functions are automatically discovered and registered by the @azure/functions
 * framework through the app.http() calls in each function file.
 */

// Import all function definitions to register them with the runtime
import './functions/getAllProducts';
import './functions/getProductById';
import './functions/createProduct';
import './functions/updateProduct';
import './functions/deleteProduct';

/**
 * Available API Endpoints:
 * 
 * GET    /api/products        - Get all products
 * GET    /api/products/{id}   - Get a product by ID
 * POST   /api/products        - Create a new product
 * PUT    /api/products/{id}   - Update an existing product
 * DELETE /api/products/{id}   - Delete a product
 * 
 * All endpoints require function-level authentication by default.
 * Use the function key from Azure Portal or local.settings.json for testing.
 */

console.log('Azure Functions app initialized successfully');
