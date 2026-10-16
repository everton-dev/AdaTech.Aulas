import * as sql from 'mssql';
import { Product, ProductInput } from '../models/product';

/**
 * Database configuration from environment variables
 */
const config: sql.config = {
    server: process.env.SQL_SERVER || '',
    database: process.env.SQL_DATABASE || '',
    user: process.env.SQL_USER || '',
    password: process.env.SQL_PASSWORD || '',
    options: {
        encrypt: true, // Required for Azure SQL
        trustServerCertificate: false,
        enableArithAbort: true,
        connectTimeout: 30000,
        requestTimeout: 30000
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

/**
 * Connection pool instance
 */
let pool: sql.ConnectionPool | null = null;

/**
 * Get or create database connection pool
 */
async function getPool(): Promise<sql.ConnectionPool> {
    if (!pool || !pool.connected) {
        pool = await sql.connect(config);
    }
    return pool;
}

/**
 * Database service for Product CRUD operations
 */
export class DatabaseService {
    /**
     * Get all products from the database
     */
    static async getAllProducts(): Promise<Product[]> {
        try {
            const dbPool = await getPool();
            const result = await dbPool.request()
                .query<Product>('SELECT id, name FROM product ORDER BY id');
            
            return result.recordset;
        } catch (error) {
            console.error('Error getting all products:', error);
            throw new Error('Failed to retrieve products from database');
        }
    }

    /**
     * Get a single product by ID
     */
    static async getProductById(id: number): Promise<Product | null> {
        try {
            const dbPool = await getPool();
            const result = await dbPool.request()
                .input('id', sql.Int, id)
                .query<Product>('SELECT id, name FROM product WHERE id = @id');
            
            return result.recordset.length > 0 ? result.recordset[0] : null;
        } catch (error) {
            console.error('Error getting product by ID:', error);
            throw new Error('Failed to retrieve product from database');
        }
    }

    /**
     * Create a new product
     */
    static async createProduct(product: ProductInput): Promise<Product> {
        try {
            const dbPool = await getPool();
            const result = await dbPool.request()
                .input('name', sql.VarChar(100), product.name)
                .query<{ id: number }>('INSERT INTO product (name) OUTPUT INSERTED.id VALUES (@name)');
            
            if (result.recordset.length === 0) {
                throw new Error('Failed to create product');
            }

            return {
                id: result.recordset[0].id,
                name: product.name
            };
        } catch (error) {
            console.error('Error creating product:', error);
            throw new Error('Failed to create product in database');
        }
    }

    /**
     * Update an existing product
     */
    static async updateProduct(id: number, product: ProductInput): Promise<Product | null> {
        try {
            const dbPool = await getPool();
            
            // First check if product exists
            const existing = await this.getProductById(id);
            if (!existing) {
                return null;
            }

            // Update the product
            await dbPool.request()
                .input('id', sql.Int, id)
                .input('name', sql.VarChar(100), product.name)
                .query('UPDATE product SET name = @name WHERE id = @id');
            
            return {
                id,
                name: product.name
            };
        } catch (error) {
            console.error('Error updating product:', error);
            throw new Error('Failed to update product in database');
        }
    }

    /**
     * Delete a product by ID
     */
    static async deleteProduct(id: number): Promise<boolean> {
        try {
            const dbPool = await getPool();
            
            const result = await dbPool.request()
                .input('id', sql.Int, id)
                .query('DELETE FROM product WHERE id = @id; SELECT @@ROWCOUNT as rowsAffected');
            
            return result.recordset[0].rowsAffected > 0;
        } catch (error) {
            console.error('Error deleting product:', error);
            throw new Error('Failed to delete product from database');
        }
    }

    /**
     * Close the database connection pool (for cleanup)
     */
    static async closePool(): Promise<void> {
        if (pool) {
            await pool.close();
            pool = null;
        }
    }
}

/**
 * Graceful shutdown handler
 */
process.on('SIGTERM', async () => {
    console.log('SIGTERM received, closing database connections...');
    await DatabaseService.closePool();
});
