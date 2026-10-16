import { HttpRequest, HttpResponseInit } from '@azure/functions';
import { ProductInput, isProductInput } from '../models/product';

/**
 * Validates request body for product creation/update
 */
export function validateProductInput(req: HttpRequest): { valid: boolean; data?: ProductInput; error?: string } {
    try {
        const body = req.body;
        
        if (!body) {
            return { valid: false, error: 'Request body is required' };
        }

        if (isProductInput(body)) {
            return { valid: true, data: body };
        }

        return { 
            valid: false, 
            error: 'Invalid product data. Name is required and must be a string (max 100 characters)' 
        };
    } catch (error) {
        return { valid: false, error: 'Invalid JSON in request body' };
    }
}

/**
 * Validates product ID from route parameters
 */
export function validateProductId(id: string | undefined): { valid: boolean; id?: number; error?: string } {
    if (!id) {
        return { valid: false, error: 'Product ID is required' };
    }

    const numId = parseInt(id, 10);
    
    if (isNaN(numId) || numId <= 0) {
        return { valid: false, error: 'Product ID must be a positive integer' };
    }

    return { valid: true, id: numId };
}

/**
 * Creates error response
 */
export function createErrorResponse(message: string, status: number = 400): HttpResponseInit {
    return {
        status,
        jsonBody: {
            error: message
        }
    };
}

/**
 * Creates success response
 */
export function createSuccessResponse(data: any, status: number = 200): HttpResponseInit {
    return {
        status,
        jsonBody: data
    };
}
