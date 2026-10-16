using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Data.SqlClient;

namespace AdaAPI.Repositories
{
    public class CarRepository
    {
        private readonly ILogger _logger;
        private readonly IConfiguration _configuration;
        private readonly SqlConnection _sqlConnection;

        private const string SQL_CARS = "SELECT * FROM Car";
        private const string SQL_CARS_BY_ID = "SELECT * FROM Car WHERE Id = @Id";
        private const string SQL_IDENTITY = "SELECT @@IDENTITY AS Id";
        private const string SQL_INSERT = "INSERT INTO Car (Brand, Model, Year) VALUES (@Brand, @Model, @Year)";
        private const string SQL_UPDATE = "UPDATE FROM Car SET Brand = @Brand, Model = @Model, Year = @Year WHERE Id = @Id";
        private const string SQL_DELETE = "DELETE FROM Car WHERE Id = @Id";

        public CarRepository(ILogger logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration; 
            _sqlConnection = new SqlConnection(_configuration["SqlServerConnectionString"]);
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

        public async Task<Car> RetrieveById(int id)
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

        private async Task<int> RetrieveIdentityId(SqlCommand command)
        {
            _logger.LogInformation($"SQL {SQL_IDENTITY} [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            try
            {
                command.CommandText = SQL_IDENTITY;
                var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return reader.GetInt32(0);
                }
            }
            catch (Exception)
            {
                throw;
            }

            return 0;
        }

        public async Task<int> Insert(Car car)
        {
            if (car == null)
                throw new ArgumentNullException(nameof(car));

            _logger.LogInformation($"{SQL_INSERT} | @Brand = {car.Brand}, @Model = {car.Model}, @Year = {car.Year}, | [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            try
            {
                await _sqlConnection.OpenAsync();
                var command = new SqlCommand(SQL_INSERT, _sqlConnection);
                command.Parameters.AddWithValue("@Brand", car.Brand);
                command.Parameters.AddWithValue("@Model", car.Model);
                command.Parameters.AddWithValue("@Year", car.Year);
                var rows = await command.ExecuteNonQueryAsync();
                _logger.LogInformation($"Result: {SQL_INSERT} | @Brand = {car.Brand}, @Model = {car.Model}, @Year = {car.Year}, | [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}] | Rows affected: {rows}.");

                return await this.RetrieveIdentityId(command);
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

        public async Task<int> Update(int id, Car car)
        {
            if (car == null)
                throw new ArgumentNullException(nameof(car));

            _logger.LogInformation($"{SQL_UPDATE} | @Id = {car.Id}, @Brand = {car.Brand}, @Model = {car.Model}, @Year = {car.Year}, | [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            try
            {
                await _sqlConnection.OpenAsync();
                var command = new SqlCommand(SQL_UPDATE, _sqlConnection);
                command.Parameters.AddWithValue("@Brand", car.Brand);
                command.Parameters.AddWithValue("@Id", car.Id);
                command.Parameters.AddWithValue("@Model", car.Model);
                command.Parameters.AddWithValue("@Year", car.Year);
                var rows = await command.ExecuteNonQueryAsync();
                _logger.LogInformation($"Result: {SQL_UPDATE} | @Id = {car.Id}, @Brand = {car.Brand}, @Model = {car.Model}, @Year = {car.Year}, | [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}] | Rows affected: {rows}.");

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
            _logger.LogInformation($"{SQL_DELETE} | @Id = {id} | [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}].");
            try
            {
                await _sqlConnection.OpenAsync();
                var command = new SqlCommand(SQL_DELETE, _sqlConnection);
                command.Parameters.AddWithValue("@Id", id);
                var rows = await command.ExecuteNonQueryAsync();
                _logger.LogInformation($"Result: {SQL_DELETE} | @Id = {id} | [{DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")}] | Rows affected: {rows}.");

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
}