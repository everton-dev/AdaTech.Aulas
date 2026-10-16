using System.Data.SqlClient;

namespace AdaAPI.Repositories
{
    public class CarRepository
    {
        private readonly string _connectionString;
        private readonly SqlConnection _sqlConnection;

        private const string SQL_CARS = "SELECT * FROM Car";
        private const string SQL_CARS_BY_ID = "SELECT * FROM Car WHERE Id = @Id";

        public CarRepository()
        {
            var server = "cars-sql-server.database.windows.net";
            var database = "cars-sql-server-database";
            var user = "ada";
            var password = "@datech123";
            _connectionString = $"Server=tcp:{server},1433;Initial Catalog={database};Persist Security Info=False;User ID={user};Password={password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
            _sqlConnection = new SqlConnection(_connectionString);
        }

        public async Task<IEnumerable<Car>> RetrieveAll()
        {
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

        public async Task<Car> RetrieveById(int id)
        {
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