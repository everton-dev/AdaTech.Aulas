import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { DatabaseService } from '../services/database';
import { createErrorResponse, createSuccessResponse, validateProductId } from '../utils/validation';

/**
 * HTTP GET endpoint to retrieve a product by ID
 * Route: GET /api/products/{id}
 */
export async function getProductById(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('HTTP trigger function getProductById processed a request.');

    try {
        const id = request.params.id;
        const validation = validateProductId(id);

        if (!validation.valid) {
            return createErrorResponse(validation.error!);
        }

        const product = await DatabaseService.getProductById(validation.id!);
        
        if (!product) {
            return createErrorResponse('Product not found', 404);
        }

        context.log(`Retrieved product with ID ${validation.id}`);
        
        return createSuccessResponse(product);
    } catch (error) {
        context.error('Error in getProductById:', error);
        return createErrorResponse('Internal server error while retrieving product', 500);
    }
}

app.http('getProductById', {
    methods: ['GET'],
    authLevel: 'function',
    route: 'products/{id}',
    handler: getProductById
});
