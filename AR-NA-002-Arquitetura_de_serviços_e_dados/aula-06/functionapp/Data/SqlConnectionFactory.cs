using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace Ada.Aula06.ProductsApi.Data;

/// <summary>
/// Creates open connections against the Azure SQL database that hosts the <c>products</c> table.
/// </summary>
public interface ISqlConnectionFactory
{
    Task<IDbConnection> CreateOpenConnectionAsync(CancellationToken cancellationToken = default);
}

/// <inheritdoc />
public sealed class SqlConnectionFactory(IOptions<SqlDatabaseOptions> options) : ISqlConnectionFactory
{
    private readonly SqlDatabaseOptions _options = options.Value;

    public async Task<IDbConnection> CreateOpenConnectionAsync(CancellationToken cancellationToken = default)
    {
        var connection = new SqlConnection(_options.ConnectionString);
        await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
        return connection;
    }
}
