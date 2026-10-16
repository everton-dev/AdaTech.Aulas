using System.Data;
using Microsoft.Data.SqlClient;
using System.Globalization;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace BlobStorageFunctionApp
{
    public class Function1
    {
        private readonly ILogger<Function1> _logger;
        private readonly string _sqlConnectionString = Environment.GetEnvironmentVariable("SqlConnection");
        private readonly string _blobConnectionString = Environment.GetEnvironmentVariable("StorageConnection");

        public Function1(ILogger<Function1> logger)
        {
            _logger = logger;
        }

        [Function(nameof(Function1))]
        public async Task Run([BlobTrigger("lote-vendas/{name}", Connection = "StorageConnection")] Stream stream, string name)
        {
            try
            {
                using var reader = new StreamReader(stream);
                var content = await reader.ReadToEndAsync();

                var products = ParseCsv(content, name);
                await BulkInsertProducts(products);
                await DeleteBlobAsync(name);

                _logger.LogInformation($"Successfully processed and deleted blob: {name}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error processing blob {name}: {ex.Message}");
                throw;
            }
        }

        private List<ProductSale> ParseCsv(string csvContent, string fileName)
        {
            var lines = csvContent.Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
            var products = new List<ProductSale>();
            var now = DateTime.UtcNow;
            var totalRows = lines.Length - 1; // Exclude header

            for (int i = 1; i < lines.Length; i++) // skip header
            {
                var columns = lines[i].Split(',');

                if (columns.Length < 4) continue;

                var productId = Guid.Parse(columns[0]);
                var productName = columns[1].Trim();
                var quantity = short.Parse(columns[2]);
                var unitPrice = decimal.Parse(columns[3], CultureInfo.InvariantCulture);
                var totalAmount = quantity * unitPrice;

                products.Add(new ProductSale
                {
                    ProductId = productId,
                    ProductName = productName,
                    Quantity = quantity,
                    UnitPrice = unitPrice,
                    TotalAmount = totalAmount,
                    FileName = fileName,
                    TotalFileRows = totalRows,
                    TimeStamp = now
                });
            }

            return products;
        }

        private async Task BulkInsertProducts(List<ProductSale> products)
        {
            using var sqlConnection = new SqlConnection(_sqlConnectionString);
            
            await sqlConnection.OpenAsync();

            using var bulkCopy = new SqlBulkCopy(sqlConnection)
            {
                DestinationTableName = "dbo.Sales" // Make sure your table name matches
            };

            var table = new DataTable();
            table.Columns.Add("ProductId", typeof(Guid));
            table.Columns.Add("ProductName", typeof(string));
            table.Columns.Add("Quantity", typeof(short));
            table.Columns.Add("UnitPrice", typeof(decimal));
            table.Columns.Add("TotalAmount", typeof(decimal));
            table.Columns.Add("FileName", typeof(string));
            table.Columns.Add("TotalFileRows", typeof(short));
            table.Columns.Add("TimeStamp", typeof(DateTime));

            foreach (var p in products)
            {
                table.Rows.Add(p.ProductId, p.ProductName, p.Quantity, p.UnitPrice, p.TotalAmount, p.FileName, p.TotalFileRows, p.TimeStamp);
            }

            await bulkCopy.WriteToServerAsync(table);
        }

        private async Task DeleteBlobAsync(string blobName)
        {
            var containerClient = new BlobContainerClient(_blobConnectionString, "lote-vendas");
            var blobClient = containerClient.GetBlobClient(blobName);
            await blobClient.DeleteIfExistsAsync();
        }
    }
}