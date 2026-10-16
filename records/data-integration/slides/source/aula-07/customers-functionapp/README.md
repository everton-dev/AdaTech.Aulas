# Customer Management Azure Function API

A serverless REST API built with Azure Functions and Python that provides customer data from an Azure SQL Database.

## 🏗️ Architecture

- **Runtime**: Python 3.12
- **Platform**: Azure Functions (Consumption Plan)
- **Database**: Azure SQL Database
- **Authentication**: Anonymous (for demo purposes)

## 📋 API Documentation

### Base URL
```
https://adatech-sales-function-app-dpe0a7gkcve9a8ff.canadacentral-01.azurewebsites.net/api
```

### Endpoints

#### GET /api/customers
Retrieves all customers from the database.

**Response Format:**
```json
[
  {
    "customer_id": "52A8DF44-61BD-42A9-8F39-050EE4EF1AF2",
    "first_name": "Jessica",
    "last_name": "Hall",
    "email": "jessica.hall066@hotmail.com",
    "phone": "+14856327477",
    "date_of_birth": "1997-04-18",
    "gender": "M",
    "address_line1": "6775 Main St",
    "city": "Fort Worth",
    "state_province": "TX",
    "postal_code": "47652",
    "country": "USA",
    "registration_date": "2025-07-06 14:06:07",
    "customer_tier": "Gold",
    "credit_limit": "6101.91",
    "loyalty_points": 6907,
    "preferred_contact_method": "SMS",
    "marketing_consent": true,
    "is_active": false,
    "created_date": "2025-07-22 13:34:19.436666",
    "last_updated": "2025-07-22 13:34:19.436666"
  }
]
```

**HTTP Status Codes:**
- `200 OK`: Successful retrieval
- `500 Internal Server Error`: Database connection or query failed

## 🛠️ Local Development

### Prerequisites
- Python 3.12+
- Azure Functions Core Tools
- Azure CLI
- ODBC Driver 18 for SQL Server

### Setup
1. Clone the repository
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure local settings in `local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "",
       "FUNCTIONS_WORKER_RUNTIME": "python",
       "SQL_SERVER": "adatech-sql-server.database.windows.net",
       "SQL_DATABASE": "adatech-sql-database",
       "SQL_USERNAME": "everton",
       "SQL_PASSWORD": "your-password"
     }
   }
   ```

4. Run locally:
   ```bash
   func start
   ```

## 🚀 Deployment Guide

### Azure CLI Commands Used

#### 1. List Function Apps
```bash
az functionapp list --query "[].{Name:name, ResourceGroup:resourceGroup, State:state}" --output table
```

#### 2. Deploy Function App
```bash
func azure functionapp publish adatech-sales-function-app --build remote
```

#### 3. Configure Application Settings
```bash
# Set database connection settings
az functionapp config appsettings set \
  --name adatech-sales-function-app \
  --resource-group adatech-etl-rg \
  --settings \
    "SQL_SERVER=adatech-sql-server.database.windows.net" \
    "SQL_DATABASE=adatech-sql-database" \
    "SQL_USERNAME=everton"
```

```bash
# Set database password
az functionapp config appsettings set \
  --name adatech-sales-function-app \
  --resource-group adatech-etl-rg \
  --settings "SQL_PASSWORD=Adatech123*"
```

#### 4. Test Deployment
```bash
curl -X GET "https://adatech-sales-function-app-dpe0a7gkcve9a8ff.canadacentral-01.azurewebsites.net/api/api/customers"
```

## 🗄️ Database Schema

The API connects to the `Customer` table with the following structure:

```sql
CREATE TABLE dbo.Customer (
    customer_id UNIQUEIDENTIFIER PRIMARY KEY,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    phone NVARCHAR(20),
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    address_line1 NVARCHAR(255),
    city NVARCHAR(100),
    state_province NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100) DEFAULT 'USA',
    registration_date DATETIME2,
    customer_tier NVARCHAR(20) DEFAULT 'Bronze',
    credit_limit DECIMAL(10,2) DEFAULT 1000.00,
    loyalty_points INT DEFAULT 0,
    preferred_contact_method NVARCHAR(20) DEFAULT 'Email',
    marketing_consent BIT DEFAULT 0,
    is_active BIT DEFAULT 1,
    created_date DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE()
);
```

## 🔒 Security Best Practices Implemented

1. **Environment Variables**: Database credentials stored as application settings
2. **Connection Security**: Uses encrypted connections to Azure SQL Database
3. **Error Handling**: Proper exception handling with detailed logging
4. **Resource Management**: Ensures database connections are properly closed
5. **SQL Security**: Uses parameterized queries (prepared for future parameters)

## 📦 Dependencies

### requirements.txt
```
azure-functions
pyodbc
azure-identity
```

### host.json
```json
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "excludedTypes": "Request"
      }
    }
  },
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  }
}
```

## 🔧 Configuration

### Azure Resources
- **Function App**: `adatech-sales-function-app`
- **Resource Group**: `adatech-etl-rg`
- **SQL Server**: `adatech-sql-server.database.windows.net`
- **Database**: `adatech-sql-database`
- **Region**: Canada Central

### Application Settings
| Setting | Value |
|---------|-------|
| `FUNCTIONS_WORKER_RUNTIME` | `python` |
| `SQL_SERVER` | `adatech-sql-server.database.windows.net` |
| `SQL_DATABASE` | `adatech-sql-database` |
| `SQL_USERNAME` | `everton` |
| `SQL_PASSWORD` | `[Configured securely]` |

## 🐛 Troubleshooting

### Common Issues

1. **Table Not Found Error**
   - **Error**: `Invalid object name 'customers'`
   - **Solution**: Ensure table name is `Customer` (capitalized)

2. **Connection Timeout**
   - **Error**: Connection timeout errors
   - **Solution**: Check network connectivity and firewall rules

3. **Authentication Failed**
   - **Error**: Login failed for user
   - **Solution**: Verify credentials in application settings

### Monitoring

View logs in Azure Portal:
1. Navigate to Function App → Functions → customers
2. Go to Monitor tab
3. View Invocations and Logs

## 📊 Performance Considerations

- Uses connection pooling for database efficiency
- Implements proper resource cleanup
- Returns paginated results for large datasets (future enhancement)
- Caches connection strings using environment variables

## 🔄 Future Enhancements

- [ ] Add pagination support
- [ ] Implement POST, PUT, DELETE operations
- [ ] Add authentication and authorization
- [ ] Implement caching with Azure Redis Cache
- [ ] Add request validation
- [ ] Implement API versioning
- [ ] Add OpenAPI/Swagger documentation

## 📝 API Testing

### Using cURL
```bash
# Get all customers
curl -X GET "https://adatech-sales-function-app-dpe0a7gkcve9a8ff.canadacentral-01.azurewebsites.net/api/api/customers"
```

### Using PowerShell
```powershell
Invoke-RestMethod -Uri "https://adatech-sales-function-app-dpe0a7gkcve9a8ff.canadacentral-01.azurewebsites.net/api/api/customers" -Method GET
```

## 📞 Support

For issues or questions:
1. Check Azure Function logs in the portal
2. Verify database connectivity
3. Review application settings configuration

---

**Last Updated**: July 22, 2025  
**Version**: 1.0.0  
**Deployed By**: Azure Functions Core Tools with remote build
