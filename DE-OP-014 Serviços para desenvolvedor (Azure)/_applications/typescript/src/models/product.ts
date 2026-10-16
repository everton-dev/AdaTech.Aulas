/**
 * Product model representing the database schema
 */
export interface Product {
    id: number;
    name: string;
}

/**
 * Product input for create/update operations (without id)
 */
export interface ProductInput {
    name: string;
}

/**
 * Type guard to check if object is a valid ProductInput
 */
export function isProductInput(obj: any): obj is ProductInput {
    return (
        typeof obj === 'object' &&
        obj !== null &&
        typeof obj.name === 'string' &&
        obj.name.trim().length > 0 &&
        obj.name.length <= 100
    );
}
