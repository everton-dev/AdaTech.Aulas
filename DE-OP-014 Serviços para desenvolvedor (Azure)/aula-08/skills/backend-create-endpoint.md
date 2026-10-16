# Skill: Create Azure Function Endpoint

## Identification
- **Name**: `backend-create-endpoint`
- **Layer**: Backend (AdaTech.ProductsBE)
- **Scope**: Create new HTTP Azure Function endpoint
- **Complexity**: Medium

## Description
Creates a new HTTP endpoint using Azure Functions (.NET 8 Isolated Worker) following project standards, including OpenAPI documentation, error handling, and authentication.

## Prerequisites
- [ ] Clearly understand the endpoint's purpose
- [ ] Define HTTP method (GET, POST, PUT, DELETE)
- [ ] Identify input and output parameters
- [ ] Check if similar endpoint already exists
- [ ] Determine authentication/authorization requirements

## Affected Files
```
AdaTech.ProductsBE/
├── Functions/
│   └── {FunctionName}.cs          # New file
├── Models/DTOs/
│   └── {Request/Response}Dto.cs   # If needed
```

## Implementation Steps

### 1. Create Function File
```csharp
// filepath: AdaTech.ProductsBE/Functions/{FunctionName}.cs
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.OpenApi.Models;
using System.Net;
using AdaTech.ProductsBE.Extensions;

namespace AdaTech.ProductsBE.Functions;

/// <summary>
/// [Description of the function's purpose]
/// </summary>
public class {FunctionName}
{
    private readonly ILogger<{FunctionName}> _logger;
    // Inject required dependencies

    public {FunctionName}(ILogger<{FunctionName}> logger)
    {
        _logger = logger;
    }

    [Function("{EndpointName}")]
    [OpenApiOperation(
        operationId: "{EndpointName}",
        tags: new[] { "{Category}" },
        Summary = "{Short summary}",
        Description = "{Detailed description}",
        Visibility = OpenApiVisibilityType.Important
    )]
    [OpenApiParameter(
        name: "paramName",
        In = ParameterLocation.Query,
        Required = true,
        Type = typeof(string),
        Description = "Parameter description"
    )]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.OK,
        contentType: "application/json",
        bodyType: typeof(ResponseDto),
        Description = "Return description"
    )]
    [OpenApiResponseWithBody(
        statusCode: HttpStatusCode.BadRequest,
        contentType: "application/json",
        bodyType: typeof(ErrorResponse),
        Description = "Invalid request"
    )]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "{method}", Route = "{route}")] 
        HttpRequest req,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Processing {EndpointName} request");

        try
        {
            // Validate authentication if needed
            // var claims = req.GetClaims();
            
            // Implement logic
            
            return new OkObjectResult(new { success = true });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in {EndpointName}");
            return new StatusCodeResult(StatusCodes.Status500InternalServerError);
        }
    }
}
```

### 2. Create DTOs (if needed)
```csharp
// filepath: AdaTech.ProductsBE/Models/DTOs/{Name}Dto.cs
namespace AdaTech.ProductsBE.Models.DTOs;

public class {Name}RequestDto
{
    public string Property { get; set; } = string.Empty;
}

public class {Name}ResponseDto
{
    public bool Success { get; set; }
    public string? Message { get; set; }
}
```

### 3. Register Dependencies (if needed)
In `Program.cs`, add dependency injection:
```csharp
services.AddScoped<IRequiredService, ServiceImplementation>();
```

## Required Patterns

### OpenAPI Documentation
- **Always** include `[OpenApiOperation]` with tags, summary, and description
- **Always** document parameters with `[OpenApiParameter]`
- **Always** document all possible responses

### Error Handling
```csharp
[OpenApiResponseWithBody(
    statusCode: HttpStatusCode.BadRequest,
    contentType: "application/json",
    bodyType: typeof(ErrorResponse),
    Description = "Invalid request")]
[OpenApiResponseWithBody(
    statusCode: HttpStatusCode.Unauthorized,
    contentType: "application/json",
    bodyType: typeof(ErrorResponse),
    Description = "Not authenticated")]
[OpenApiResponseWithBody(
    statusCode: HttpStatusCode.Forbidden,
    contentType: "application/json",
    bodyType: typeof(ErrorResponse),
    Description = "No permission")]
[OpenApiResponseWithBody(
    statusCode: HttpStatusCode.InternalServerError,
    contentType: "application/json",
    bodyType: typeof(ErrorResponse),
    Description = "Internal error")]
```

### Logging
```csharp
_logger.LogInformation("Processing request for {Operation}", operationName);
_logger.LogWarning("Validation failed: {Reason}", reason);
_logger.LogError(ex, "Error processing {Operation}", operationName);
```

### Authentication
```csharp
// For endpoints that require authentication
var claims = req.GetClaims();
if (claims == null)
{
    return new UnauthorizedObjectResult(new { error = "Authentication required" });
}

var userId = claims.FindFirst("userId")?.Value;
```

## Available Tag Categories
- `Authentication` - Login, logout, OAuth
- `Users` - User management
- `Dynamics` - Dynamics 365 integration
- `Questionnaires` - Onboarding questionnaires
- `Admin` - Administrative functions
- `Configuration` - System configuration
- `Diagnostics` - Health checks and diagnostics

## Validation

### Review Checklist
- [ ] Endpoint compiles without errors
- [ ] OpenAPI documentation is complete
- [ ] Error handling implemented
- [ ] Proper logging
- [ ] Correct authentication/authorization
- [ ] DTOs created if needed
- [ ] Route doesn't conflict with existing ones

### Manual Testing
```bash
# Start Azure Functions locally
cd AdaTech.ProductsBE
func start

# Test endpoint (adjust URL and method)
curl -X GET "http://localhost:7071/api/{route}" -H "Content-Type: application/json"
```

### Verify Swagger
Access `http://localhost:7071/api/swagger/ui` to verify documentation.

## Reference Examples

### Existing GET Endpoints
- `Functions/GetDynamicsUsers.cs`
- `Functions/GetQuestionnaires.cs`
- `Functions/ListDynamicsInstances.cs`

### Existing POST Endpoints
- `Functions/AuthCallback.cs`
- `Functions/CreateDynamicsUser.cs`
- `Functions/BatchImportUsersFunction.cs`

## Relationships
- **Depends on**: [backend-add-usecase](backend-add-usecase.md) (if using Clean Architecture)
- **Related**: [documentation](documentation.md) (for additional documentation)

## Notes
- Prefer injecting Use Cases for complex logic
- For simple CRUD operations, you can use DbContext directly
- Always use `CancellationToken` in async operations
