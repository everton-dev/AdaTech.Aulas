// See https://aka.ms/new-console-template for more information
using CosmosDBSample;
using CosmosDBSample.Models;

Console.WriteLine("Hello, World!");

string endpointUrl = "https://ada-nosql-cosmosdb.documents.azure.com";
string accountKey = Environment.GetEnvironmentVariable("COSMOSDB_ACCOUNT_KEY")
    ?? throw new InvalidOperationException("Set the COSMOSDB_ACCOUNT_KEY environment variable.");
string databaseId = "shopping";
string containerId = "customer";

var repository = new CosmosRepository(endpointUrl, accountKey, databaseId, containerId);


await repository.UpsertItemAsync(new Customer
{
    Id = Guid.NewGuid().ToString(),
    Name = "John Doe",
    Email = "john.doe@ada.com.br",
    Type = "NORMAL",
    Contacts = new List<Contact>
    {
        new Contact
        {
            Id = Guid.NewGuid().ToString(),
            CountryCode = "+351",
            Number = "912345678",
            Type = "MOBILE"
        }
    },
    Address = new Address
    {
        Id = Guid.NewGuid().ToString(),
        Street = "Rua do Ouro",
        Number = "123",
        Country = "Portugal",
        City = "Braga",
        PostalCode = "4000-000"
    },
    Orders = new List<Order>
    {
        new Order
        {
            Id = Guid.NewGuid().ToString(),
            CreatedAt = DateTime.Now,
            UpdatedAt = DateTime.Now,
            Status = "ON_GOING",
            Items = new List<Item>
            {
                new Item
                {
                    Id = Guid.NewGuid().ToString(),
                    Name = "Laptop",
                    Price = 1000,
                    Quantity = 1
                },
                new Item
                {
                    Id = Guid.NewGuid().ToString(),
                    Name = "Mouse",
                    Price = 20,
                    Quantity = 1
                }
            }
        }
    },
    CreatedAt = DateTime.Now,
    UpdatedAt = DateTime.Now
});


// SELECT * FROM c
var clients = await repository.RetrieveAsync();
Console.WriteLine($"Retrieved {clients.Count} clients");
foreach (var client in clients)
{
    Console.WriteLine($"Customer: {client.Name}");
}
Console.WriteLine("=========================================================");

// SELECT * FROM c WHERE c.id = "c73d2994-3c42-4a77-a30c-247fb0004259"
var clientFound = await repository.RetrieveAsync("c73d2994-3c42-4a77-a30c-247fb0004259", "PREMIUM");
Console.WriteLine($"Customer: {clientFound.Name}");
Console.WriteLine("=========================================================");

// SELECT * FROM c WHERE c.address.city = "Porto"
clients = await repository.RetrieveByAddressCityAsync("Porto");
Console.WriteLine($"Retrieved by address city: {clients.Count} clients");
foreach (var client in clients)
{
    Console.WriteLine($"Customer from Porto: {client.Name}");
}
Console.WriteLine("=========================================================");

// SELECT * FROM c WHERE c.address.city = "Lisboa"
clients = await repository.RetrieveByAddressCityAsync("Lisboa");
Console.WriteLine($"Retrieved by address city: {clients.Count} clients");
foreach (var client in clients)
{
    Console.WriteLine($"Customer from Lisboa: {client.Name}");
}
Console.WriteLine("=========================================================");

// SELECT * FROM c
// WHERE ARRAY_LENGTH(
//     ARRAY(
//         SELECT VALUE o
//         FROM o IN c.orders
//         WHERE ARRAY_LENGTH(o.items) > 2
//     )
// ) > 0
clients = await repository.RetrieveByClientsWithOrdersMoreThenTwoItemsAsync();
Console.WriteLine($"Retrieved by clients with orders more then two items: {clients.Count} clients");
foreach (var client in clients)
{
    Console.WriteLine($"Customer from Lisboa: {client.Name}");
}
Console.WriteLine("=========================================================");