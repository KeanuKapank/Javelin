namespace Javelin.API.Configurations.Models
{
    public class Kafka
    {
        public string BootstrapServers { get; set; } = string.Empty;
        public List<string> Topics { get; set; } = [];
    }
}
