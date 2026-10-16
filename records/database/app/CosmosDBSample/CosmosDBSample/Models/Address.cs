using Newtonsoft.Json;

namespace CosmosDBSample.Models
{
    public record Address
    {
        [JsonProperty("id")]
        public string Id { get; set; }
        [JsonProperty("street")]
        public string Street { get; set; }
        [JsonProperty("number")]
        public string Number { get; set; }
        [JsonProperty("complement")]
        public string Complement { get; set; }
        [JsonProperty("postalCode")]
        public string PostalCode { get; set; }
        [JsonProperty("city")]
        public string City { get; set; }
        [JsonProperty("country")]
        public string Country { get; set; }
    }
}