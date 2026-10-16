using Newtonsoft.Json;

namespace CosmosDBSample.Models
{
    public record Customer
    {
        [JsonProperty("id")]
        public string Id { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("email")]
        public string Email { get; set; }

        [JsonProperty("type")]
        public string Type { get; set; }

        [JsonProperty("contacts")]
        public List<Contact> Contacts { get; set; }

        [JsonProperty("address")]
        public Address Address { get; set; }

        [JsonProperty("orders")]
        public List<Order> Orders { get; set; }

        [JsonProperty("createdAt")]
        public DateTime CreatedAt { get; set; }

        [JsonProperty("updatedAt")]
        public DateTime UpdatedAt { get; set; }
    }
}