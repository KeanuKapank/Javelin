using Confluent.Kafka;
using Javelin.API.Configurations.Models;
using Javelin.API.Models;

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

        public async Task Produce(string topicName, UILogAction action)
        {
            using (var producer = new ProducerBuilder<string, UILogAction>(_producerConfig)
                .SetValueSerializer(new JsonSerializer<UILogAction>())
                .Build())
            {
                producer.Produce(topicName, new Message<string, UILogAction> { Value = action },
                    (deliveryReport) =>
                    {
                        if (deliveryReport.Error.Code != ErrorCode.NoError)
                        {
                            Console.WriteLine($"Failed to deliver message: {deliveryReport.Error.Reason}");
                        }
                        else
                        {
                            Console.WriteLine($"Produced event to topic {topicName}: value = {action}");
                        }
                    });
                

                producer.Flush(TimeSpan.FromSeconds(10));
                Console.WriteLine($"Message were produced to topic {topicName}");
            }
        }

        public async Task Produce(string topicName, APILogAction action)
        {
            using (var producer = new ProducerBuilder<string, APILogAction>(_producerConfig)
                .SetValueSerializer(new JsonSerializer<APILogAction>())
                .Build())
            {
                producer.Produce(topicName, new Message<string, APILogAction> { Value = action },
                    (deliveryReport) =>
                    {
                        if (deliveryReport.Error.Code != ErrorCode.NoError)
                        {
                            Console.WriteLine($"Failed to deliver message: {deliveryReport.Error.Reason}");
                        }
                        else
                        {
                            Console.WriteLine($"Produced event to topic {topicName}: value = {action}");
                        }
                    });


                producer.Flush(TimeSpan.FromSeconds(10));
                Console.WriteLine($"Message were produced to topic {topicName}");
            }
        }

        public async Task Produce(string topicName, DBLogAction action)
        {
            using (var producer = new ProducerBuilder<string, DBLogAction>(_producerConfig)
                .SetValueSerializer(new JsonSerializer<DBLogAction>())
                .Build())
            {
                producer.Produce(topicName, new Message<string, DBLogAction> { Value = action },
                    (deliveryReport) =>
                    {
                        if (deliveryReport.Error.Code != ErrorCode.NoError)
                        {
                            Console.WriteLine($"Failed to deliver message: {deliveryReport.Error.Reason}");
                        }
                        else
                        {
                            Console.WriteLine($"Produced event to topic {topicName}: value = {action}");
                        }
                    });


                producer.Flush(TimeSpan.FromSeconds(10));
                Console.WriteLine($"Message were produced to topic {topicName}");
            }
        }
    }
}
