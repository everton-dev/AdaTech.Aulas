# Azure Functions TypeScript CRUD API

A production-ready Azure Functions app built with TypeScript for managing products in Azure SQL Database.

## Features

- ✅ **Azure Functions v4** with TypeScript
- ✅ **Full CRUD Operations** for products
- ✅ **Connection Pooling** for optimal database performance
- ✅ **Input Validation** with type guards
- ✅ **SQL Injection Protection** using parameterized queries
- ✅ **Error Handling** with proper HTTP status codes
- ✅ **RESTful API Design**
- ✅ **Type Safety** throughout the codebase

## API Endpoints

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| GET | `/api/products` | Get all products | - |
| GET | `/api/products/{id}` | Get product by ID | - |
| POST | `/api/products` | Create new product | `{"name": "string"}` |
| PUT | `/api/products/{id}` | Update product | `{"name": "string"}` |
| DELETE | `/api/products/{id}` | Delete product | - |

## Prerequisites

- Node.js 18+ or later
- Azure Functions Core Tools v4
- Azure SQL Database with a `product` table
- npm or yarn

## Database Schema

```sql
CREATE TABLE product (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Database Connection

Update the `local.settings.json` file with your Azure SQL Database credentials:

```json
{
  "Values": {
    "SQL_SERVER": "your-server.database.windows.net",
    "SQL_DATABASE": "your-database-name",
    "SQL_USER": "your-username",
    "SQL_PASSWORD": "your-password"
  }
}
```

### 3. Build the Project

```bash
npm run build
```

### 4. Run Locally

```bash
npm start
```

The Functions app will start on `http://localhost:7071`

## Testing the API

### Get All Products
```bash
curl http://localhost:7071/api/products
```

### Get Product by ID
```bash
curl http://localhost:7071/api/products/1
```

### Create Product
```bash
curl -X POST http://localhost:7071/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "New Product"}'
```

### Update Product
```bash
curl -X PUT http://localhost:7071/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Product"}'
```

### Delete Product
```bash
curl -X DELETE http://localhost:7071/api/products/1
```

## Project Structure

```
typescript/
├── src/
│   ├── app.ts                    # Main entry point
│   ├── functions/                # HTTP trigger functions
│   │   ├── getAllProducts.ts
│   │   ├── getProductById.ts
│   │   ├── createProduct.ts
│   │   ├── updateProduct.ts
│   │   └── deleteProduct.ts
│   ├── services/
│   │   └── database.ts           # Database operations & connection pool
│   ├── models/
│   │   └── product.ts            # TypeScript interfaces
│   └── utils/
│       └── validation.ts         # Input validation utilities
├── host.json                     # Functions host configuration
├── local.settings.json           # Local environment variables
├── package.json
└── tsconfig.json
```

## Deployment to Azure

### Using Azure CLI

1. Create a Function App:
```bash
az functionapp create --name <APP_NAME> --storage-account <STORAGE> \
  --resource-group <RESOURCE_GROUP> --consumption-plan-location <LOCATION> \
  --runtime node --runtime-version 18 --functions-version 4
```

2. Configure application settings:
```bash
az functionapp config appsettings set --name <APP_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --settings SQL_SERVER=<SERVER> SQL_DATABASE=<DB> \
  SQL_USER=<USER> SQL_PASSWORD=<PASSWORD>
```

3. Deploy:
```bash
func azure functionapp publish <APP_NAME>
```

### Using Azure Developer CLI (azd)

Recommended approach using Flex Consumption plan for better performance:

```bash
azd init
azd up
```

## Best Practices Implemented

1. **Connection Pooling**: Reuses database connections for better performance
2. **Parameterized Queries**: Prevents SQL injection attacks
3. **Input Validation**: Validates all inputs before processing
4. **Error Handling**: Comprehensive error handling with logging
5. **Type Safety**: Full TypeScript types throughout
6. **Environment Variables**: Secure credential management
7. **RESTful Design**: Proper HTTP methods and status codes
8. **Code Organization**: Clear separation of concerns

## Security Notes

- All endpoints use function-level authentication by default
- Database connections use SSL encryption (required for Azure SQL)
- Never commit `local.settings.json` with real credentials
- Use Azure Key Vault for production secrets

## License

MIT
