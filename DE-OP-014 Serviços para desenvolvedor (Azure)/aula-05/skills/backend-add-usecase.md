# Skill: Add Use Case (Clean Architecture)

## Identification
- **Name**: `backend-add-usecase`
- **Layer**: Application (AdaTech.Products.Application)
- **Scope**: Create new Use Case following Clean Architecture
- **Complexity**: Medium

## Description
Creates a new Use Case in the Application layer, following the project's Clean Architecture pattern. Use Cases encapsulate business logic and orchestrate operations between Domain and Infrastructure.

## Prerequisites
- [ ] Understand the business use case
- [ ] Identify involved domain entities
- [ ] Check if required repositories exist
- [ ] Define input and output DTOs

## Affected Files
```
AdaTech.Products.Application/
├── UseCases/
│   └── {Context}/
│       ├── {UseCaseName}UseCase.cs       # Implementation
│       └── {UseCaseName}Dto.cs           # Specific DTOs
├── DTOs/
│   └── {DtoName}.cs                      # Shared DTOs
└── DependencyInjection.cs                # DI registration

AdaTech.Products.Domain/
└── Interfaces/
    └── I{Entity}Repository.cs            # If needed

AdaTech.Products.Infrastructure/
└── Persistence/
    └── {Entity}Repository.cs             # If needed
```

## Implementation Steps

### 1. Create Use Case Interface (Optional)
```csharp
// filepath: AdaTech.Products.Application/UseCases/{Context}/I{UseCaseName}UseCase.cs
namespace AdaTech.Products.Application.UseCases.{Context};

public interface I{UseCaseName}UseCase
{
    Task<{ResponseDto}> ExecuteAsync({RequestDto} request, CancellationToken cancellationToken = default);
}
```

### 2. Create Use Case
```csharp
// filepath: AdaTech.Products.Application/UseCases/{Context}/{UseCaseName}UseCase.cs
using Microsoft.Extensions.Logging;
using AdaTech.Products.Domain.Interfaces;
using AdaTech.Products.Application.DTOs;

namespace AdaTech.Products.Application.UseCases.{Context};

/// <summary>
/// [Description of the Use Case's purpose]
/// </summary>
public class {UseCaseName}UseCase : I{UseCaseName}UseCase
{
    private readonly ILogger<{UseCaseName}UseCase> _logger;
    private readonly I{Entity}Repository _repository;

    public {UseCaseName}UseCase(
        ILogger<{UseCaseName}UseCase> logger,
        I{Entity}Repository repository)
    {
        _logger = logger;
        _repository = repository;
    }

    public async Task<{ResponseDto}> ExecuteAsync(
        {RequestDto} request, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Executing {UseCase} for {Context}", 
            nameof({UseCaseName}UseCase), request.SomeIdentifier);

        try
        {
            // 1. Validate input
            ValidateRequest(request);

            // 2. Fetch data from repository
            var entities = await _repository.GetAllAsync(cancellationToken);

            // 3. Apply business logic
            var result = ProcessBusinessLogic(entities);

            // 4. Map to response DTO
            return MapToResponse(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing {UseCase}", nameof({UseCaseName}UseCase));
            throw;
        }
    }

    private void ValidateRequest({RequestDto} request)
    {
        if (request == null)
            throw new ArgumentNullException(nameof(request));
        
        // Add specific validations
    }

    private IEnumerable<{Entity}> ProcessBusinessLogic(IEnumerable<{Entity}> entities)
    {
        // Implement business logic
        return entities;
    }

    private {ResponseDto} MapToResponse(IEnumerable<{Entity}> entities)
    {
        return new {ResponseDto}
        {
            Items = entities.Select(e => new {ItemDto}
            {
                Id = e.Id,
                Name = e.Name
                // Map other properties
            }).ToList(),
            TotalCount = entities.Count()
        };
    }
}
```

### 3. Create DTOs
```csharp
// filepath: AdaTech.Products.Application/DTOs/{UseCaseName}Dtos.cs
namespace AdaTech.Products.Application.DTOs;

/// <summary>
/// Request DTO for {UseCaseName}
/// </summary>
public class {UseCaseName}RequestDto
{
    public string? Filter { get; set; }
    public int PageSize { get; set; } = 50;
    public int PageNumber { get; set; } = 1;
}

/// <summary>
/// Response DTO for {UseCaseName}
/// </summary>
public class {UseCaseName}ResponseDto
{
    public List<{Item}Dto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public bool Success { get; set; } = true;
    public string? Message { get; set; }
}

/// <summary>
/// Item DTO for {UseCaseName}
/// </summary>
public class {Item}Dto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    // Add required properties
}
```

### 4. Register in DI
```csharp
// filepath: AdaTech.Products.Application/DependencyInjection.cs
using Microsoft.Extensions.DependencyInjection;
using AdaTech.Products.Application.UseCases.{Context};

namespace AdaTech.Products.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Existing Use Cases...
        
        // New Use Case
        services.AddScoped<I{UseCaseName}UseCase, {UseCaseName}UseCase>();
        
        return services;
    }
}
```

### 5. Use in Azure Function
```csharp
// filepath: AdaTech.ProductsBE/Functions/{FunctionName}.cs
public class {FunctionName}
{
    private readonly I{UseCaseName}UseCase _useCase;

    public {FunctionName}(I{UseCaseName}UseCase useCase)
    {
        _useCase = useCase;
    }

    [Function("{EndpointName}")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req,
        CancellationToken cancellationToken)
    {
        var request = new {UseCaseName}RequestDto
        {
            Filter = req.Query["filter"]
        };

        var result = await _useCase.ExecuteAsync(request, cancellationToken);
        
        return new OkObjectResult(result);
    }
}
```

## Required Patterns

### Use Case Structure
```
ExecuteAsync()
├── Validate input
├── Fetch data (Repository)
├── Apply business logic
├── Map to DTO
└── Return result
```

### Dependency Rules (Clean Architecture)
```
✅ Use Case CAN depend on:
   - Repository interfaces (Domain)
   - Entities (Domain)
   - DTOs (Application)
   - Logger

❌ Use Case CANNOT depend on:
   - DbContext directly
   - Repository implementations
   - HttpRequest/HttpResponse
   - External frameworks
```

### Naming Conventions
- Use Cases: `{Verb}{Noun}UseCase` (e.g., `ListDynamicsInstancesUseCase`)
- DTOs: `{UseCaseName}RequestDto`, `{UseCaseName}ResponseDto`
- Interfaces: `I{UseCaseName}UseCase`

### Error Handling
```csharp
// Create specific exceptions in Domain
public class EntityNotFoundException : Exception
{
    public EntityNotFoundException(string entityName, Guid id)
        : base($"{entityName} with ID {id} not found") { }
}

// In Use Case
if (entity == null)
    throw new EntityNotFoundException(nameof(DynamicsInstance), id);
```

## Complete Reference Example

See implementation in:
- `AdaTech.Products.Application/UseCases/DynamicsInstances/ListDynamicsInstancesUseCase.cs`
- Documentation: `docs/CLEAN_ARCHITECTURE_GUIDE.md`

## Validation

### Review Checklist
- [ ] Use Case doesn't depend on concrete implementations
- [ ] DTOs are simple (no business logic)
- [ ] Input validation implemented
- [ ] Proper logging
- [ ] CancellationToken propagated
- [ ] Registered in DependencyInjection.cs
- [ ] Unit tests created (see [testing-unit](testing-unit.md))

### Build Test
```bash
cd AdaTech.Products.Application
dotnet build
```

## Relationships
- **Requires**: [backend-add-entity](backend-add-entity.md) (if new entity)
- **Requires**: [backend-add-repository](backend-add-repository.md) (if new repository)
- **Used by**: [backend-create-endpoint](backend-create-endpoint.md)
- **Related**: [testing-unit](testing-unit.md)

## Notes
- Use Cases should be small and focused (Single Responsibility)
- For complex operations, create multiple coordinated Use Cases
- Avoid complex mapping logic - use libraries like AutoMapper if needed
