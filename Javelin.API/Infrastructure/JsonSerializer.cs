using Confluent.Kafka;
using System.Text.Json;

namespace Javelin.API.Infrastructure
{
    public class JsonSerializer<T> : ISerializer<T>
    {
        public byte[] Serialize(T data, SerializationContext context)
        {
            try
            {
                return JsonSerializer.SerializeToUtf8Bytes(data);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to serialize JSON: {ex.Message}");
                throw;
            }
        }
    }
}
