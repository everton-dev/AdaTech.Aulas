using CosmosDBSample.Models;
using Microsoft.Azure.Cosmos;
using System.Text;

namespace CosmosDBSample
{
    internal class CosmosRepository
    {
        public readonly string _endpointUrl;
        public readonly string _accountKey;
        public readonly string _databaseName;
        public readonly string _containerId;

        private readonly CosmosClient _client;
        private Database _database;
        private Container _container;

        public CosmosRepository(string endpointUrl, string accountKey, string databaseId, string containerId)
        {
            _endpointUrl = endpointUrl;
            _accountKey = accountKey;
            _databaseName = databaseId;
            _containerId = containerId;
            _client = new CosmosClient(_endpointUrl, _accountKey);
            _database = _client.GetDatabase(_databaseName);
            _container = _database.GetContainer(_containerId);
        }

        public async Task UpsertItemAsync(Customer customer)
        {
            ItemResponse<Customer> response = await _container.UpsertItemAsync(
                item: customer,
                partitionKey: new Microsoft.Azure.Cosmos.PartitionKey(customer.Type)
            );
        }

        public async Task<List<Customer>> RetrieveAsync()
        {
            var items = new List<Customer>();
            var query = new QueryDefinition("SELECT * FROM c"); // SQL to retrieve all items
            using var iterator = _container.GetItemQueryIterator<Customer>(query);

            while (iterator.HasMoreResults)
            {
                var response = await iterator.ReadNextAsync();
                items.AddRange(response.Resource);
            }

            return items;
        }

        public async Task<Customer> RetrieveAsync(string id, string partitionKey)
        {
            ItemResponse<Customer> response = 
                await _container.ReadItemAsync<Customer>(id, new Microsoft.Azure.Cosmos.PartitionKey(partitionKey));

            return response.Resource;
        }

        public async Task<List<Customer>> RetrieveByAddressCityAsync(string city)
        {
            var items = new List<Customer>();
            var query = new QueryDefinition("SELECT * FROM c WHERE c.address.city = @city")
                .WithParameter("@city", city); // SQL to retrieve all items
            using var iterator = _container.GetItemQueryIterator<Customer>(query);

            while (iterator.HasMoreResults)
            {
                var response = await iterator.ReadNextAsync();
                items.AddRange(response.Resource);
            }

            return items;
        }

        public async Task<List<Customer>> RetrieveByClientsWithOrdersMoreThenTwoItemsAsync()
        {
            var items = new List<Customer>();
            var queryString = new StringBuilder();
            queryString.AppendLine("SELECT * FROM c WHERE ARRAY_LENGTH(");
            queryString.AppendLine("ARRAY(");
            queryString.AppendLine("SELECT VALUE o");
            queryString.AppendLine("FROM o IN c.orders");
            queryString.AppendLine("WHERE ARRAY_LENGTH(o.items) > 2");
            queryString.AppendLine(")");
            queryString.AppendLine(") > 0");
            var query = new QueryDefinition(queryString.ToString());
            using var iterator = _container.GetItemQueryIterator<Customer>(query);

            while (iterator.HasMoreResults)
            {
                var response = await iterator.ReadNextAsync();
                items.AddRange(response.Resource);
            }

            return items;
        }

        public async Task RemoveAsync(Customer client)
        {
            var response = await _container.DeleteItemAsync<object>(
                client.Id,
                new Microsoft.Azure.Cosmos.PartitionKey(client.Type)
            );
        }
    }
}