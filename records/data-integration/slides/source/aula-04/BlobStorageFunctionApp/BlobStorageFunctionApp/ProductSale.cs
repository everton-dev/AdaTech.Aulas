namespace BlobStorageFunctionApp
{
    public class ProductSale
    {
        public Guid ProductId { get; set; }
        public string ProductName { get; set; }
        public short Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal TotalAmount { get; set; }
        public string FileName { get; set; }
        public int TotalFileRows { get; set; }
        public DateTime TimeStamp { get; set; }
    }
}