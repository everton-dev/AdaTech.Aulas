import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { DatabaseService } from '../services/database';
import { createErrorResponse, createSuccessResponse, validateProductId, validateProductInput } from '../utils/validation';

/**
 * HTTP PUT endpoint to update an existing product
 * Route: PUT /api/products/{id}
 * Body: { "name": "Updated Product Name" }
 */
export async function updateProduct(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('HTTP trigger function updateProduct processed a request.');

    try {
        const id = request.params.id;
        const idValidation = validateProductId(id);

        if (!idValidation.valid) {
            return createErrorResponse(idValidation.error!);
        }

        const bodyValidation = validateProductInput(request);

        if (!bodyValidation.valid) {
            return createErrorResponse(bodyValidation.error!);
        }

        const updatedProduct = await DatabaseService.updateProduct(idValidation.id!, bodyValidation.data!);
        
        if (!updatedProduct) {
            return createErrorResponse('Product not found', 404);
        }

        context.log(`Updated product with ID ${idValidation.id}`);
        
        return createSuccessResponse(updatedProduct);
    } catch (error) {
        context.error('Error in updateProduct:', error);
        return createErrorResponse('Internal server error while updating product', 500);
    }
}

app.http('updateProduct', {
    methods: ['PUT'],
    authLevel: 'function',
    route: 'products/{id}',
    handler: updateProduct
});
