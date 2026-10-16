import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { DatabaseService } from '../services/database';
import { createErrorResponse, createSuccessResponse, validateProductId } from '../utils/validation';

/**
 * HTTP DELETE endpoint to delete a product by ID
 * Route: DELETE /api/products/{id}
 */
export async function deleteProduct(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('HTTP trigger function deleteProduct processed a request.');

    try {
        const id = request.params.id;
        const validation = validateProductId(id);

        if (!validation.valid) {
            return createErrorResponse(validation.error!);
        }

        const deleted = await DatabaseService.deleteProduct(validation.id!);
        
        if (!deleted) {
            return createErrorResponse('Product not found', 404);
        }

        context.log(`Deleted product with ID ${validation.id}`);
        
        return createSuccessResponse({ message: 'Product deleted successfully' }, 200);
    } catch (error) {
        context.error('Error in deleteProduct:', error);
        return createErrorResponse('Internal server error while deleting product', 500);
    }
}

app.http('deleteProduct', {
    methods: ['DELETE'],
    authLevel: 'function',
    route: 'products/{id}',
    handler: deleteProduct
});
