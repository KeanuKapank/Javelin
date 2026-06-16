using Confluent.Kafka;
using Javelin.API.Configurations.Models;

namespace Javelin.API.Infrastructure
{
    public class Producer : IProducer
    {
        private readonly ProducerConfig _producerConfig;

        public Producer(AppConfig appConfig)
        {
            _producerConfig = new()
            {
                BootstrapServers = appConfig.Kafka.BootstrapServers,
                Acks = Acks.All
            };
        }

        public async Task Produce(string topicName)
        {
            using (var producer = new ProducerBuilder<string, string>(_producerConfig).Build())
            {
                producer.Produce(topicName, new Message<string, string> { Value = "item" },
                    (deliveryReport) =>
                    {
                        if (deliveryReport.Error.Code != ErrorCode.NoError)
                        {
                            Console.WriteLine($"Failed to deliver message: {deliveryReport.Error.Reason}");
                        }
                        else
                        {
                            Console.WriteLine($"Produced event to topic {topicName}: value = item");
                        }
                    });
                

                producer.Flush(TimeSpan.FromSeconds(10));
                Console.WriteLine($"Message were produced to topic {topicName}");
            }
        }
    }
}
