# Azure Function App - Product CRUD API

A production-ready Azure Functions application in Python that provides RESTful API endpoints for CRUD operations on a Product table in Azure SQL Database.

## Features

- ✅ **Python v2 Programming Model** - Uses the latest Azure Functions programming model
- ✅ **RESTful API** - 5 endpoints for complete CRUD operations
- ✅ **Azure SQL Database** - Secure connection with proper error handling
- ✅ **Input Validation** - Comprehensive request validation
- ✅ **Error Handling** - Proper HTTP status codes and error messages
- ✅ **Logging** - Structured logging for monitoring and debugging
- ✅ **Security** - Function-level authentication and encrypted connections
- ✅ **Best Practices** - Follows Azure Functions and Python best practices

## Project Structure

```
.
├── function_app.py           # Main application with all endpoints
├── shared/
│   ├── __init__.py          # Shared module initialization
│   └── database.py          # Database connection and CRUD operations
├── host.json                # Function host configuration
├── local.settings.json      # Local development settings (not in git)
├── requirements.txt         # Python dependencies
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Prerequisites

1. **Python 3.9 or higher**
2. **Azure Functions Core Tools** (v4.x)
3. **ODBC Driver 18 for SQL Server**
4. **Azure SQL Database** with a `product` table

### Database Schema

```sql
CREATE TABLE product (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```

## Installation

### 1. Install Azure Functions Core Tools

**Windows (PowerShell):**
```powershell
winget install Microsoft.Azure.FunctionsCoreTools
```

**macOS:**
```bash
brew tap azure/functions
brew install azure-functions-core-tools@4
```

**Linux:**
```bash
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install azure-functions-core-tools-4
```

### 2. Install ODBC Driver for SQL Server

**Windows:**
- Download and install from: https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server

**macOS:**
```bash
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
brew install msodbcsql18 mssql-tools18
```

**Linux (Ubuntu):**
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

### 3. Set Up Python Environment

```bash
# Create and activate virtual environment
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS/Linux
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Configuration

### Local Development

1. Copy the example environment file:
   ```bash
   cp .env.example local.settings.json
   ```

2. Edit `local.settings.json` with your Azure SQL Database credentials:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "python",
       "SQL_SERVER": "your-server.database.windows.net",
       "SQL_DATABASE": "your-database-name",
       "SQL_USERNAME": "your-username",
       "SQL_PASSWORD": "your-password",
       "SQL_DRIVER": "{ODBC Driver 18 for SQL Server}"
     }
   }
   ```

### Azure Deployment

When deploying to Azure, configure these Application Settings in your Function App:

- `SQL_SERVER`
- `SQL_DATABASE`
- `SQL_USERNAME`
- `SQL_PASSWORD`
- `SQL_DRIVER`

**Security Tip:** Use Azure Key Vault references for sensitive values:
```
@Microsoft.KeyVault(SecretUri=https://myvault.vault.azure.net/secrets/SqlPassword/)
```

## Running Locally

```bash
# Start the Azure Functions runtime
func start
```

The API will be available at: `http://localhost:7071/api`

## API Endpoints

All endpoints require authentication. Include the function key in the `x-functions-key` header or as a `code` query parameter.

### 1. Get All Products
```http
GET /api/products
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Product 1"
  },
  {
    "id": 2,
    "name": "Product 2"
  }
]
```

### 2. Get Product by ID
```http
GET /api/products/{id}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Product 1"
}
```

**Response (404 Not Found):**
```json
{
  "error": "Product not found"
}
```

### 3. Create Product
```http
POST /api/products
Content-Type: application/json

{
  "name": "New Product"
}
```

**Response (201 Created):**
```json
{
  "message": "Product created successfully",
  "id": 3,
  "name": "New Product"
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Product name is required and must be a string"
}
```

### 4. Update Product
```http
PUT /api/products/{id}
Content-Type: application/json

{
  "name": "Updated Product Name"
}
```

**Response (200 OK):**
```json
{
  "message": "Product updated successfully",
  "id": 1,
  "name": "Updated Product Name"
}
```

**Response (404 Not Found):**
```json
{
  "error": "Product not found"
}
```

### 5. Delete Product
```http
DELETE /api/products/{id}
```

**Response (200 OK):**
```json
{
  "message": "Product deleted successfully",
  "id": 1
}
```

**Response (404 Not Found):**
```json
{
  "error": "Product not found"
}
```

## Testing with cURL

```bash
# Set your function key
FUNC_KEY="your-function-key-here"

# Get all products
curl -H "x-functions-key: $FUNC_KEY" http://localhost:7071/api/products

# Get product by ID
curl -H "x-functions-key: $FUNC_KEY" http://localhost:7071/api/products/1

# Create product
curl -X POST -H "Content-Type: application/json" -H "x-functions-key: $FUNC_KEY" \
  -d '{"name":"Test Product"}' http://localhost:7071/api/products

# Update product
curl -X PUT -H "Content-Type: application/json" -H "x-functions-key: $FUNC_KEY" \
  -d '{"name":"Updated Product"}' http://localhost:7071/api/products/1

# Delete product
curl -X DELETE -H "x-functions-key: $FUNC_KEY" http://localhost:7071/api/products/1
```

## Deployment to Azure

### Option 1: Using Azure Functions Core Tools

```bash
# Login to Azure
az login

# Create a Function App (if not exists)
az functionapp create \
  --resource-group <resource-group> \
  --consumption-plan-location <region> \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --name <function-app-name> \
  --storage-account <storage-account> \
  --os-type Linux

# Deploy the function app
func azure functionapp publish <function-app-name>
```

### Option 2: Using VS Code

1. Install the Azure Functions extension
2. Right-click on the project folder
3. Select "Deploy to Function App..."
4. Follow the prompts

### Option 3: CI/CD with GitHub Actions

Create `.github/workflows/deploy.yml` for automated deployments.

## Best Practices Implemented

### Security
- ✅ Function-level authentication (`auth_level=func.AuthLevel.FUNCTION`)
- ✅ Encrypted SQL connections (`Encrypt=yes`)
- ✅ Certificate validation (`TrustServerCertificate=no`)
- ✅ Environment variable management for secrets
- ✅ SQL injection protection (parameterized queries)

### Performance
- ✅ Context manager for proper connection handling
- ✅ Connection timeout settings
- ✅ Efficient query execution

### Reliability
- ✅ Comprehensive error handling
- ✅ Input validation
- ✅ Proper HTTP status codes
- ✅ Detailed logging
- ✅ Transaction support

### Code Quality
- ✅ Type hints
- ✅ Docstrings
- ✅ Clean code structure
- ✅ Separation of concerns (database logic in separate module)
- ✅ Python v2 programming model

## Monitoring and Logging

### View Logs Locally
Logs are displayed in the console when running `func start`.

### View Logs in Azure
```bash
# Stream logs
func azure functionapp logstream <function-app-name>
```

Or use Azure Portal → Function App → Log Stream

### Application Insights
Enable Application Insights in your Function App for:
- Request tracking
- Performance monitoring
- Failure analysis
- Custom metrics

## Troubleshooting

### ODBC Driver Not Found
**Error:** `[Microsoft][ODBC Driver Manager] Data source name not found`

**Solution:** Install ODBC Driver 18 for SQL Server (see Prerequisites)

### Connection Timeout
**Error:** `Connection Timeout Expired`

**Solution:** 
- Check firewall rules in Azure SQL Database
- Verify your IP address is allowed
- Check connection string settings

### Import Errors
**Error:** `ModuleNotFoundError: No module named 'azure'`

**Solution:**
```bash
pip install -r requirements.txt
```

## Contributing

1. Follow PEP 8 style guide
2. Add type hints to all functions
3. Include docstrings
4. Test locally before committing
5. Update documentation as needed

## License

MIT License

## Support

For issues and questions:
- Azure Functions documentation: https://learn.microsoft.com/azure/azure-functions/
- Azure SQL Database documentation: https://learn.microsoft.com/azure/azure-sql/

## Author

Created with Azure Functions best practices and security in mind.
