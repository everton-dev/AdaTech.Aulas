using Newtonsoft.Json;

namespace CosmosDBSample.Models
{
    public record Contact
    {
        [JsonProperty("id")]
        public string Id { get; set; }
        [JsonProperty("countryCode")]
        public string CountryCode { get; set; }
        [JsonProperty("areaCode")]
        public string AreaCode { get; set; }
        [JsonProperty("number")]
        public string Number { get; set; }
        [JsonProperty("type")]
        public string Type { get; set; }
        [JsonProperty("preferred")]
        public bool Preferred { get; set; }
    }
}