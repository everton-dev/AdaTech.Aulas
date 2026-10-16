using Newtonsoft.Json;

namespace CosmosDBSample.Models
{
    public record Order
    {
        [JsonProperty("id")]
        public string Id { get; set; }
        [JsonProperty("createdAt")]
        public DateTime CreatedAt { get; set; }
        [JsonProperty("updatedAt")]
        public DateTime UpdatedAt { get; set; }
        [JsonProperty("status")]
        public string Status { get; set; }
        [JsonProperty("items")]
        public List<Item> Items { get; set; }
    }
}