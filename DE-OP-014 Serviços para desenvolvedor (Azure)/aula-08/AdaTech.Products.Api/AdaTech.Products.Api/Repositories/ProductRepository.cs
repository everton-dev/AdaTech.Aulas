using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AdaTech.Products.Api.Repositories;

public class ProductRepository
{
    private readonly ILogger<ProductRepository> _logger;
    private readonly IConfiguration _configuration;
    private readonly SqlConnection _sqlConnection;

    private const string SQL_PRODUCTS = "SELECT * FROM Product";
    private const string SQL_PRODUCTS_BY_ID = "SELECT * FROM Product WHERE Id = @Id";
    private const string SQL_INSERT = "INSERT INTO Product (Name, Description, Price, Quantity) VALUES (@Name, @Description, @Price, @Quantity); SELECT SCOPE_IDENTITY();";
    private const string SQL_UPDATE = "UPDATE Product SET Name = @Name, Description = @Description, Price = @Price, Quantity = @Quantity WHERE Id = @Id";
    private const string SQL_DELETE = "DELETE FROM Product WHERE Id = @Id";

    public ProductRepository(ILogger<ProductRepository> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
        _sqlConnection = new SqlConnection(_configuration["SqlServerConnectionString"]);
    }

    public async Task<IEnumerable<Product>> RetrieveAll()
    {
        _logger.LogInformation("SQL {Sql} [{Timestamp}].", SQL_PRODUCTS, DateTime.Now);
        var products = new List<Product>();
        try
        {
            await _sqlConnection.OpenAsync();
            var command = new SqlCommand(SQL_PRODUCTS, _sqlConnection);
            var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(new Product
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1),
                    Description = reader.GetString(2),
                    Price = reader.GetDecimal(3),
                    Quantity = reader.GetInt32(4)
                });
            }
        }
        catch (Exception)
        {
            throw;
        }
        finally
        {
            if (_sqlConnection.State == System.Data.ConnectionState.Open)
                await _sqlConnection.CloseAsync();
        }

        return products;
    }

    public async Task<Product?> RetrieveById(int id)
    {
        _logger.LogInformation("SQL {Sql} [@Id={Id}] [{Timestamp}].", SQL_PRODUCTS_BY_ID, id, DateTime.Now);
        Product? product = null;
        try
        {
            await _sqlConnection.OpenAsync();
            var command = new SqlCommand(SQL_PRODUCTS_BY_ID, _sqlConnection);
            command.Parameters.AddWithValue("@Id", id);
            var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                product = new Product
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1),
                    Description = reader.GetString(2),
                    Price = reader.GetDecimal(3),
                    Quantity = reader.GetInt32(4)
                };
            }
        }
        catch (Exception)
        {
            throw;
        }
        finally
        {
            if (_sqlConnection.State == System.Data.ConnectionState.Open)
                await _sqlConnection.CloseAsync();
        }

        return product;
    }

    public async Task<int> Insert(Product product)
    {
        if (product == null)
            throw new ArgumentNullException(nameof(product));

        _logger.LogInformation("SQL {Sql} [@Name={Name}, @Price={Price}] [{Timestamp}].", SQL_INSERT, product.Name, product.Price, DateTime.Now);
        try
        {
            await _sqlConnection.OpenAsync();
            var command = new SqlCommand(SQL_INSERT, _sqlConnection);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", product.Description);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@Quantity", product.Quantity);
            var result = await command.ExecuteScalarAsync();
            var newId = result != null && result != DBNull.Value ? Convert.ToInt32(result) : 0;
            _logger.LogInformation("New product ID: {Id}.", newId);

            return newId;
        }
        catch (Exception)
        {
            throw;
        }
        finally
        {
            if (_sqlConnection.State == System.Data.ConnectionState.Open)
                await _sqlConnection.CloseAsync();
        }
    }

    public async Task<int> Update(int id, Product product)
    {
        if (product == null)
            throw new ArgumentNullException(nameof(product));

        _logger.LogInformation("SQL {Sql} [@Id={Id}] [{Timestamp}].", SQL_UPDATE, id, DateTime.Now);
        try
        {
            await _sqlConnection.OpenAsync();
            var command = new SqlCommand(SQL_UPDATE, _sqlConnection);
            command.Parameters.AddWithValue("@Id", id);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", product.Description);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@Quantity", product.Quantity);
            var rows = await command.ExecuteNonQueryAsync();
            _logger.LogInformation("Rows affected: {Rows}.", rows);

            return rows;
        }
        catch (Exception)
        {
            throw;
        }
        finally
        {
            if (_sqlConnection.State == System.Data.ConnectionState.Open)
                await _sqlConnection.CloseAsync();
        }
    }

    public async Task<int> Delete(int id)
    {
        _logger.LogInformation("SQL {Sql} [@Id={Id}] [{Timestamp}].", SQL_DELETE, id, DateTime.Now);
        try
        {
            await _sqlConnection.OpenAsync();
            var command = new SqlCommand(SQL_DELETE, _sqlConnection);
            command.Parameters.AddWithValue("@Id", id);
            var rows = await command.ExecuteNonQueryAsync();
            _logger.LogInformation("Rows affected: {Rows}.", rows);

            return rows;
        }
        catch (Exception)
        {
            throw;
        }
        finally
        {
            if (_sqlConnection.State == System.Data.ConnectionState.Open)
                await _sqlConnection.CloseAsync();
        }
    }
}
