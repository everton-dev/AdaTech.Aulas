import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { DatabaseService } from '../services/database';
import { createErrorResponse, createSuccessResponse, validateProductInput } from '../utils/validation';

/**
 * HTTP POST endpoint to create a new product
 * Route: POST /api/products
 * Body: { "name": "Product Name" }
 */
export async function createProduct(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('HTTP trigger function createProduct processed a request.');

    try {
        const validation = validateProductInput(request);

        if (!validation.valid) {
            return createErrorResponse(validation.error!);
        }

        const newProduct = await DatabaseService.createProduct(validation.data!);
        
        context.log(`Created product with ID ${newProduct.id}`);
        
        return createSuccessResponse(newProduct, 201);
    } catch (error) {
        context.error('Error in createProduct:', error);
        return createErrorResponse('Internal server error while creating product', 500);
    }
}

app.http('createProduct', {
    methods: ['POST'],
    authLevel: 'function',
    route: 'products',
    handler: createProduct
});
