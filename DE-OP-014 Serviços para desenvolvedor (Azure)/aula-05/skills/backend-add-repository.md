# Skill: Implement Repository

## Identification
- **Name**: `backend-add-repository`
- **Layer**: Infrastructure (AdaTech.Products.Infrastructure)
- **Scope**: Implement repository for data access
- **Complexity**: Low

## Description
Implements a repository following the Repository Pattern, isolating data access logic from business logic. The interface lives in Domain, the implementation in Infrastructure.

## Prerequisites
- [ ] Domain entity exists
- [ ] Repository interface defined in Domain
- [ ] DbContext configured with entity's DbSet

## Affected Files
```
AdaTech.Products.Domain/
└── Interfaces/
    └── I{Entity}Repository.cs        # Interface (if not exists)

AdaTech.Products.Infrastructure/
├── Persistence/
│   └── {Entity}Repository.cs         # Implementation
└── DependencyInjection.cs            # DI registration
```

## Implementation Steps

### 1. Verify/Create Interface in Domain
```csharp
// filepath: AdaTech.Products.Domain/Interfaces/I{Entity}Repository.cs
using System.Linq.Expressions;
using AdaTech.Products.Domain.Entities;

namespace AdaTech.Products.Domain.Interfaces;

public interface I{Entity}Repository
{
    // Read
    Task<{Entity}?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<{Entity}>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<{Entity}>> FindAsync(
        Expression<Func<{Entity}, bool>> predicate, 
        CancellationToken cancellationToken = default);
    Task<{Entity}?> FirstOrDefaultAsync(
        Expression<Func<{Entity}, bool>> predicate, 
        CancellationToken cancellationToken = default);
    
    // Write
    Task<{Entity}> AddAsync({Entity} entity, CancellationToken cancellationToken = default);
    Task<{Entity}> UpdateAsync({Entity} entity, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    
    // Utilities
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    Task<int> CountAsync(CancellationToken cancellationToken = default);
    Task<int> CountAsync(
        Expression<Func<{Entity}, bool>> predicate, 
        CancellationToken cancellationToken = default);
}
```

### 2. Implement Repository
```csharp
// filepath: AdaTech.Products.Infrastructure/Persistence/{Entity}Repository.cs
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Linq.Expressions;
using AdaTech.Products.Domain.Entities;
using AdaTech.Products.Domain.Interfaces;
using AdaTech.Products.Data;

namespace AdaTech.Products.Infrastructure.Persistence;

/// <summary>
/// Repository implementation for {Entity}
/// </summary>
public class {Entity}Repository : I{Entity}Repository
{
    private readonly AppDbContext _context;
    private readonly ILogger<{Entity}Repository> _logger;
    private readonly DbSet<{Entity}> _dbSet;

    public {Entity}Repository(
        AppDbContext context, 
        ILogger<{Entity}Repository> logger)
    {
        _context = context;
        _logger = logger;
        _dbSet = context.Set<{Entity}>();
    }

    #region Read

    public async Task<{Entity}?> GetByIdAsync(
        Guid id, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Getting {Entity} by ID: {Id}", nameof({Entity}), id);
        
        return await _dbSet
            .AsNoTracking()
            .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);
    }

    public async Task<IEnumerable<{Entity}>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Getting all {Entity} records", nameof({Entity}));
        
        return await _dbSet
            .AsNoTracking()
            .OrderBy(e => e.Name) // Adjust sort field
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<{Entity}>> FindAsync(
        Expression<Func<{Entity}, bool>> predicate, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Finding {Entity} with predicate", nameof({Entity}));
        
        return await _dbSet
            .AsNoTracking()
            .Where(predicate)
            .ToListAsync(cancellationToken);
    }

    public async Task<{Entity}?> FirstOrDefaultAsync(
        Expression<Func<{Entity}, bool>> predicate, 
        CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .AsNoTracking()
            .FirstOrDefaultAsync(predicate, cancellationToken);
    }

    #endregion

    #region Write

    public async Task<{Entity}> AddAsync(
        {Entity} entity, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Adding new {Entity}", nameof({Entity}));
        
        if (entity.Id == Guid.Empty)
            entity.Id = Guid.NewGuid();
        
        entity.CreatedAt = DateTime.UtcNow;
        
        await _dbSet.AddAsync(entity, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        
        _logger.LogInformation("Added {Entity} with ID: {Id}", nameof({Entity}), entity.Id);
        
        return entity;
    }

    public async Task<{Entity}> UpdateAsync(
        {Entity} entity, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Updating {Entity} with ID: {Id}", nameof({Entity}), entity.Id);
        
        entity.UpdatedAt = DateTime.UtcNow;
        
        _context.Entry(entity).State = EntityState.Modified;
        await _context.SaveChangesAsync(cancellationToken);
        
        return entity;
    }

    public async Task DeleteAsync(
        Guid id, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Deleting {Entity} with ID: {Id}", nameof({Entity}), id);
        
        var entity = await _dbSet.FindAsync(new object[] { id }, cancellationToken);
        
        if (entity != null)
        {
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
        }
    }

    #endregion

    #region Utilities

    public async Task<bool> ExistsAsync(
        Guid id, 
        CancellationToken cancellationToken = default)
    {
        return await _dbSet.AnyAsync(e => e.Id == id, cancellationToken);
    }

    public async Task<int> CountAsync(CancellationToken cancellationToken = default)
    {
        return await _dbSet.CountAsync(cancellationToken);
    }

    public async Task<int> CountAsync(
        Expression<Func<{Entity}, bool>> predicate, 
        CancellationToken cancellationToken = default)
    {
        return await _dbSet.CountAsync(predicate, cancellationToken);
    }

    #endregion
}
```

### 3. Register in DI
```csharp
// filepath: AdaTech.Products.Infrastructure/DependencyInjection.cs
using Microsoft.Extensions.DependencyInjection;
using AdaTech.Products.Domain.Interfaces;
using AdaTech.Products.Infrastructure.Persistence;

namespace AdaTech.Products.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {
        // Existing repositories...
        
        // New repository
        services.AddScoped<I{Entity}Repository, {Entity}Repository>();
        
        return services;
    }
}
```

## Required Patterns

### Standard Repository Methods
| Method | Description |
|--------|-------------|
| `GetByIdAsync` | Get by ID |
| `GetAllAsync` | List all |
| `FindAsync` | Search with predicate |
| `FirstOrDefaultAsync` | First matching predicate |
| `AddAsync` | Insert new record |
| `UpdateAsync` | Update existing record |
| `DeleteAsync` | Remove record |
| `ExistsAsync` | Check existence |
| `CountAsync` | Count records |

### Best Practices
```csharp
// ✅ USE AsNoTracking for read-only queries
return await _dbSet
    .AsNoTracking()
    .ToListAsync(cancellationToken);

// ✅ USE CancellationToken in all async operations
public async Task<Entity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)

// ✅ USE appropriate logging
_logger.LogDebug("Getting entity by ID: {Id}", id);
_logger.LogInformation("Entity created with ID: {Id}", entity.Id);
_logger.LogWarning("Entity not found: {Id}", id);

// ✅ VALIDATE inputs
if (entity == null)
    throw new ArgumentNullException(nameof(entity));

// ❌ DON'T expose DbContext or IQueryable
// ❌ DON'T include business logic in repository
```

### Repository with Includes (Relationships)
```csharp
public async Task<{Entity}?> GetByIdWithRelationsAsync(
    Guid id, 
    CancellationToken cancellationToken = default)
{
    return await _dbSet
        .Include(e => e.RelatedEntity)
        .Include(e => e.Children)
        .AsNoTracking()
        .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);
}
```

### Repository with Pagination
```csharp
public async Task<(IEnumerable<{Entity}> Items, int TotalCount)> GetPagedAsync(
    int pageNumber, 
    int pageSize, 
    CancellationToken cancellationToken = default)
{
    var totalCount = await _dbSet.CountAsync(cancellationToken);
    
    var items = await _dbSet
        .AsNoTracking()
        .OrderBy(e => e.Name)
        .Skip((pageNumber - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync(cancellationToken);
    
    return (items, totalCount);
}
```

### Soft Delete
```csharp
public async Task SoftDeleteAsync(Guid id, CancellationToken cancellationToken = default)
{
    var entity = await _dbSet.FindAsync(new object[] { id }, cancellationToken);
    
    if (entity != null)
    {
        entity.IsActive = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(cancellationToken);
    }
}

// Automatically filter inactive
public async Task<IEnumerable<{Entity}>> GetAllActiveAsync(
    CancellationToken cancellationToken = default)
{
    return await _dbSet
        .AsNoTracking()
        .Where(e => e.IsActive)
        .ToListAsync(cancellationToken);
}
```

## Reference Examples
- `AdaTech.Products.Infrastructure/Persistence/DynamicsInstanceRepository.cs`

## Validation

### Review Checklist
- [ ] Interface defined in Domain
- [ ] Implementation in Infrastructure
- [ ] AsNoTracking used in read queries
- [ ] CancellationToken in all async methods
- [ ] Logging implemented
- [ ] Timestamps updated (CreatedAt, UpdatedAt)
- [ ] Registered in DependencyInjection.cs
- [ ] Unit tests created

### Build Test
```bash
dotnet build AdaTech.Products.Domain
dotnet build AdaTech.Products.Infrastructure
```

## Relationships
- **Requires**: [backend-add-entity](backend-add-entity.md)
- **Used by**: [backend-add-usecase](backend-add-usecase.md)
- **Related**: [database-migration](database-migration.md)

## Notes
- Repositories should be simple and focused on data access
- Don't put business logic in repositories
- Consider using Generic Repository for common operations
- For complex queries, consider creating specific methods
