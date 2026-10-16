import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { DatabaseService } from '../services/database';
import { createErrorResponse, createSuccessResponse } from '../utils/validation';

/**
 * HTTP GET endpoint to retrieve all products
 * Route: GET /api/products
 */
export async function getAllProducts(_request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('HTTP trigger function getAllProducts processed a request.');

    try {
        const products = await DatabaseService.getAllProducts();
        
        context.log(`Retrieved ${products.length} products from database`);
        
        return createSuccessResponse(products);
    } catch (error) {
        context.error('Error in getAllProducts:', error);
        return createErrorResponse('Internal server error while retrieving products', 500);
    }
}

app.http('getAllProducts', {
    methods: ['GET'],
    authLevel: 'function',
    route: 'products',
    handler: getAllProducts
});
