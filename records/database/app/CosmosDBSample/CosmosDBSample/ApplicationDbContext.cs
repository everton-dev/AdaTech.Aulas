using CosmosDBSample.Models;
using Microsoft.Azure.Cosmos.Linq;
using Microsoft.EntityFrameworkCore;

namespace CosmosDBSample
{
    public class ApplicationDbContext : DbContext
    {
        public readonly string _endpointUrl;
        public readonly string _accountKey;
        public readonly string _databaseName;
        public readonly string _containerId;
        public DbSet<Customer> Users { get; set; }

        public ApplicationDbContext(string endpointUrl, string accountKey, string databaseId, string containerId)
        {
            _endpointUrl = endpointUrl;
            _accountKey = accountKey;
            _databaseName = databaseId;
            _containerId = containerId;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseCosmos(_endpointUrl, _accountKey, _databaseName)
                          .EnableSensitiveDataLogging()
                          .LogTo(Console.WriteLine);
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Customer>().ToContainer(_containerId);
            modelBuilder.Entity<Customer>().HasPartitionKey(c => c.Type);
            modelBuilder.Entity<Customer>().OwnsMany(c => c.Contacts);
            modelBuilder.Entity<Customer>().OwnsOne(c => c.Address);
            modelBuilder.Entity<Customer>().OwnsMany(c => c.Orders, o =>
            {
                o.OwnsMany(order => order.Items);
            });
        }
    }
}