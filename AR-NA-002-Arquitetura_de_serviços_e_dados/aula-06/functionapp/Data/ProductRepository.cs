using System.Data;
using Ada.Aula06.ProductsApi.Models;
using Dapper;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Ada.Aula06.ProductsApi.Data;

/// <summary>
/// Dapper based implementation of <see cref="IProductRepository"/>.
/// Every statement is fully parameterized to prevent SQL injection.
/// </summary>
public sealed class ProductRepository(
    ISqlConnectionFactory connectionFactory,
    IOptions<SqlDatabaseOptions> options,
    ILogger<ProductRepository> logger) : IProductRepository
{
    private const string ProductColumns = "id AS Id, name AS Name, price AS Price";

    private readonly int _commandTimeout = options.Value.CommandTimeoutSeconds;

    public async Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken).ConfigureAwait(false);

        var command = Build($"SELECT {ProductColumns} FROM dbo.products ORDER BY id;", null, cancellationToken);
        var products = (await connection.QueryAsync<Product>(command).ConfigureAwait(false)).AsList();

        logger.LogInformation("Retrieved {ProductCount} products from the database.", products.Count);
        return products;
    }

    public async Task<Product?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken).ConfigureAwait(false);

        var parameters = new DynamicParameters();
        parameters.Add("@id", id, DbType.Int32);

        var command = Build($"SELECT {ProductColumns} FROM dbo.products WHERE id = @id;", parameters, cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Product>(command).ConfigureAwait(false);
    }

    public async Task<Product> CreateAsync(string name, decimal price, CancellationToken cancellationToken = default)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken).ConfigureAwait(false);

        var parameters = new DynamicParameters();
        parameters.Add("@name", name, DbType.AnsiString, size: 50);
        parameters.Add("@price", price, DbType.Decimal, precision: 10, scale: 2);

        const string sql = """
            INSERT INTO dbo.products (name, price)
            OUTPUT INSERTED.id AS Id, INSERTED.name AS Name, INSERTED.price AS Price
            VALUES (@name, @price);
            """;

        var created = await connection.QuerySingleAsync<Product>(Build(sql, parameters, cancellationToken)).ConfigureAwait(false);

        logger.LogInformation("Created product {ProductId}.", created.Id);
        return created;
    }

    public async Task<Product?> UpdateAsync(int id, string? name, decimal? price, CancellationToken cancellationToken = default)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken).ConfigureAwait(false);

        var parameters = new DynamicParameters();
        parameters.Add("@id", id, DbType.Int32);
        parameters.Add("@name", name, DbType.AnsiString, size: 50);
        parameters.Add("@price", price, DbType.Decimal, precision: 10, scale: 2);

        // COALESCE keeps the current value whenever the caller omitted the field.
        const string sql = """
            UPDATE dbo.products
               SET name  = COALESCE(@name, name),
                   price = COALESCE(@price, price)
            OUTPUT INSERTED.id AS Id, INSERTED.name AS Name, INSERTED.price AS Price
             WHERE id = @id;
            """;

        var updated = await connection.QuerySingleOrDefaultAsync<Product>(Build(sql, parameters, cancellationToken)).ConfigureAwait(false);

        if (updated is null)
        {
            logger.LogWarning("Update skipped because product {ProductId} does not exist.", id);
        }
        else
        {
            logger.LogInformation("Updated product {ProductId}.", id);
        }

        return updated;
    }

    public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken).ConfigureAwait(false);

        var parameters = new DynamicParameters();
        parameters.Add("@id", id, DbType.Int32);

        var affectedRows = await connection.ExecuteAsync(
            Build("DELETE FROM dbo.products WHERE id = @id;", parameters, cancellationToken)).ConfigureAwait(false);

        logger.LogInformation("Delete of product {ProductId} affected {AffectedRows} row(s).", id, affectedRows);
        return affectedRows > 0;
    }

    private CommandDefinition Build(string sql, DynamicParameters? parameters, CancellationToken cancellationToken) =>
        new(sql, parameters, commandTimeout: _commandTimeout, cancellationToken: cancellationToken);
}
