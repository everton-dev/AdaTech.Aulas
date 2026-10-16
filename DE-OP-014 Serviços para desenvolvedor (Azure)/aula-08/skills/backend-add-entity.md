# Skill: Create Domain Entity

## Identification
- **Name**: `backend-add-entity`
- **Layer**: Domain (AdaTech.Products.Domain)
- **Scope**: Create new domain entity
- **Complexity**: Low

## Description
Creates a new domain entity following project patterns. Entities represent business concepts and should be framework-agnostic.

## Prerequisites
- [ ] Understand the business concept being represented
- [ ] Identify properties and relationships
- [ ] Check if similar entity already exists
- [ ] Define validation rules

## Affected Files
```
AdaTech.Products.Domain/
├── Entities/
│   └── {EntityName}.cs                # New entity
└── Interfaces/
    └── I{EntityName}Repository.cs     # Repository interface

AdaTech.ProductsBE/
├── Data/
│   └── AppDbContext.cs                # Add DbSet
└── Migrations/
    └── {Timestamp}_{MigrationName}.cs # New migration
```

## Implementation Steps

### 1. Create Entity
```csharp
// filepath: AdaTech.Products.Domain/Entities/{EntityName}.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AdaTech.Products.Domain.Entities;

/// <summary>
/// [Description of the business concept]
/// </summary>
[Table("{table_name}")]
public class {EntityName}
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Timestamps
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    
    // Relationships
    public Guid? ParentId { get; set; }
    
    [ForeignKey(nameof(ParentId))]
    public virtual ParentEntity? Parent { get; set; }
    
    public virtual ICollection<ChildEntity> Children { get; set; } = new List<ChildEntity>();
}
```

### 2. Create Repository Interface
```csharp
// filepath: AdaTech.Products.Domain/Interfaces/I{EntityName}Repository.cs
namespace AdaTech.Products.Domain.Interfaces;

/// <summary>
/// Repository for {EntityName} operations
/// </summary>
public interface I{EntityName}Repository
{
    Task<{EntityName}?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<{EntityName}>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<{EntityName}>> GetByFilterAsync(
        Expression<Func<{EntityName}, bool>> predicate, 
        CancellationToken cancellationToken = default);
    Task<{EntityName}> CreateAsync({EntityName} entity, CancellationToken cancellationToken = default);
    Task<{EntityName}> UpdateAsync({EntityName} entity, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
}
```

### 3. Add DbSet to Context
```csharp
// filepath: AdaTech.ProductsBE/Data/AppDbContext.cs
// Add to AppDbContext class:

public DbSet<{EntityName}> {EntityName}s { get; set; }

// In OnModelCreating method, add configurations if needed:
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // ...existing configurations...
    
    modelBuilder.Entity<{EntityName}>(entity =>
    {
        entity.HasIndex(e => e.Name);
        entity.HasIndex(e => e.IsActive);
        
        // Relationships
        entity.HasOne(e => e.Parent)
            .WithMany(p => p.Children)
            .HasForeignKey(e => e.ParentId)
            .OnDelete(DeleteBehavior.Restrict);
    });
}
```

### 4. Implement Repository
```csharp
// filepath: AdaTech.Products.Infrastructure/Persistence/{EntityName}Repository.cs
using Microsoft.EntityFrameworkCore;
using AdaTech.Products.Domain.Entities;
using AdaTech.Products.Domain.Interfaces;
using AdaTech.ProductsBE.Data;

namespace AdaTech.Products.Infrastructure.Persistence;

public class {EntityName}Repository : I{EntityName}Repository
{
    private readonly AppDbContext _context;

    public {EntityName}Repository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<{EntityName}?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.{EntityName}s
            .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);
    }

    public async Task<IEnumerable<{EntityName}>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _context.{EntityName}s
            .Where(e => e.IsActive)
            .OrderBy(e => e.Name)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<{EntityName}>> GetByFilterAsync(
        Expression<Func<{EntityName}, bool>> predicate, 
        CancellationToken cancellationToken = default)
    {
        return await _context.{EntityName}s
            .Where(predicate)
            .ToListAsync(cancellationToken);
    }

    public async Task<{EntityName}> CreateAsync({EntityName} entity, CancellationToken cancellationToken = default)
    {
        entity.Id = Guid.NewGuid();
        entity.CreatedAt = DateTime.UtcNow;
        
        _context.{EntityName}s.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        
        return entity;
    }

    public async Task<{EntityName}> UpdateAsync({EntityName} entity, CancellationToken cancellationToken = default)
    {
        entity.UpdatedAt = DateTime.UtcNow;
        
        _context.{EntityName}s.Update(entity);
        await _context.SaveChangesAsync(cancellationToken);
        
        return entity;
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await GetByIdAsync(id, cancellationToken);
        if (entity != null)
        {
            _context.{EntityName}s.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
        }
    }

    public async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.{EntityName}s.AnyAsync(e => e.Id == id, cancellationToken);
    }
}
```

### 5. Register in DI
```csharp
// filepath: AdaTech.Products.Infrastructure/DependencyInjection.cs
services.AddScoped<I{EntityName}Repository, {EntityName}Repository>();
```

### 6. Create Migration
```bash
cd AdaTech.ProductsBE
dotnet ef migrations add Add{EntityName}
dotnet ef database update
```

## Required Patterns

### Entity Structure
```csharp
public class Entity
{
    // 1. Primary key
    [Key]
    public Guid Id { get; set; }
    
    // 2. Business properties (with validation)
    [Required]
    [MaxLength(200)]
    public string Name { get; set; }
    
    // 3. Status/flags
    public bool IsActive { get; set; } = true;
    
    // 4. Audit timestamps
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // 5. Foreign keys
    public Guid? RelatedEntityId { get; set; }
    
    // 6. Navigation properties
    public virtual RelatedEntity? RelatedEntity { get; set; }
}
```

### Naming Conventions
| Element | Convention | Example |
|---------|------------|---------|
| Class | PascalCase singular | `DynamicsInstance` |
| Table | snake_case plural | `dynamics_instances` |
| FK | `{RelatedEntity}Id` | `InstanceId` |
| Collections | Plural | `Users`, `Roles` |

### Common Data Annotations
```csharp
[Required]                    // Required field
[MaxLength(100)]              // Maximum length
[MinLength(1)]                // Minimum length
[Range(0, 100)]               // Numeric range
[EmailAddress]                // Email validation
[Url]                         // URL validation
[RegularExpression(@"")]      // Custom regex
[Column("column_name")]       // Column name
[Table("table_name")]         // Table name
[Index(nameof(Prop))]         // Index
```

## Entity Types

### Simple Entity
```csharp
public class Category
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public bool IsActive { get; set; }
}
```

### Entity with 1:N Relationship
```csharp
public class Parent
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public virtual ICollection<Child> Children { get; set; } = new List<Child>();
}

public class Child
{
    public Guid Id { get; set; }
    public Guid ParentId { get; set; }
    public virtual Parent Parent { get; set; }
}
```

### Entity with N:N Relationship
```csharp
public class User
{
    public Guid Id { get; set; }
    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}

public class Role
{
    public Guid Id { get; set; }
    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}

// Junction table
public class UserRole
{
    public Guid UserId { get; set; }
    public Guid RoleId { get; set; }
    public virtual User User { get; set; }
    public virtual Role Role { get; set; }
}
```

## Reference Examples
- `AdaTech.Products.Domain/Entities/DynamicsInstance.cs`
- `AdaTech.ProductsBE/Models/Questionnaire.cs`
- `AdaTech.ProductsBE/Models/BusinessRole.cs`

## Validation

### Review Checklist
- [ ] Entity is framework-agnostic
- [ ] All properties have validation
- [ ] Relationships are correct
- [ ] Repository interface created
- [ ] Repository implementation created
- [ ] DbSet added to Context
- [ ] Migration created and applied
- [ ] DI registered

### Build Test
```bash
dotnet build AdaTech.Products.Domain
dotnet build AdaTech.Products.Infrastructure
dotnet build AdaTech.ProductsBE
```

## Relationships
- **Used by**: [backend-add-repository](backend-add-repository.md)
- **Used by**: [backend-add-usecase](backend-add-usecase.md)
- **Used by**: [database-migration](database-migration.md)

## Notes
- Entities should be simple and represent business concepts
- Avoid business logic in entities (use Use Cases)
- Use soft delete (IsActive) instead of physical delete when possible
- Always include audit fields (CreatedAt, UpdatedAt)
