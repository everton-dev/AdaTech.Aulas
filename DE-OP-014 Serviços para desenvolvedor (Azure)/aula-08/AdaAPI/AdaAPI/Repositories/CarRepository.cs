using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AdaAPI.Repositories
{
    public class CarRepository
    {
        private readonly ILogger _logger;
        private readonly string _connectionString;
        private readonly SqlConnection _sqlConnection;

        private const string SQL_CARS = "SELECT * FROM Car";
        private const string SQL_CARS_BY_ID = "SELECT * FROM Car WHERE Id = @Id";

        public CarRepository(ILogger logger, IConfiguration configuration)
        {
            _logger = logger;
            _connectionString = configuration["SQL_SERVER_CONNECTION_STRING"] ?? throw new ArgumentNullException("SQL_SERVER_CONNECTION_STRING");
            _sqlConnection = new SqlConnection(_connectionString);
        }

        public async Task<IEnumerable<Car>> RetrieveAll()
        {
            _logger.LogInformation($"SQL {SQL_CARS} [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            var cars = new List<Car>();
            try
            {
                await _sqlConnection.OpenAsync();
                var command = new SqlCommand(SQL_CARS, _sqlConnection);
                var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    cars.Add(new Car
                    {
                        Id = reader.GetInt32(0),
                        Brand = reader.GetString(1),
                        Model = reader.GetString(2),
                        Year = reader.GetInt32(3)
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

            return cars;
        }

        public async Task<Car?> RetrieveById(int id)
        {
            _logger.LogInformation($"SQL {SQL_CARS_BY_ID} [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            var car = default(Car);
            try
            {
                await _sqlConnection.OpenAsync();
                var command = new SqlCommand(SQL_CARS_BY_ID, _sqlConnection);
                command.Parameters.AddWithValue("@Id", id);
                var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    car = new Car
                    {
                        Id = reader.GetInt32(0),
                        Brand = reader.GetString(1),
                        Model = reader.GetString(2),
                        Year = reader.GetInt32(3)
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

            return car;
        }
    }
}