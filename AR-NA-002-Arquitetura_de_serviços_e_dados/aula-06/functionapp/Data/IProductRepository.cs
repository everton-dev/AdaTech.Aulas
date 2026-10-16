using Ada.Aula06.ProductsApi.Models;

namespace Ada.Aula06.ProductsApi.Data;

/// <summary>
/// Persistence operations for the <c>products</c> table.
/// </summary>
public interface IProductRepository
{
    Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<Product?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<Product> CreateAsync(string name, decimal price, CancellationToken cancellationToken = default);

    /// <summary>Applies a partial update and returns the resulting row, or <c>null</c> when the id does not exist.</summary>
    Task<Product?> UpdateAsync(int id, string? name, decimal? price, CancellationToken cancellationToken = default);

    /// <summary>Returns <c>true</c> when a row was removed.</summary>
    Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
