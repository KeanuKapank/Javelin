using Confluent.Kafka;
using Javelin.API.Configurations.Models;
using Javelin.API.Models;

namespace Javelin.API.Infrastructure
{
    public class Producer : IProducer
    {
        private readonly ILogger<Producer> _logger;
        private readonly ProducerConfig _producerConfig;

        public Producer(AppConfig appConfig, ILogger<Producer> logger)
        {
            _producerConfig = new()
            {
                BootstrapServers = appConfig.Kafka.BootstrapServers,
                Acks = Acks.All
            };
            _logger = logger;
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
                            _logger.LogError("Failed to deliver message: {Reason}", deliveryReport.Error.Reason);
                        }
                        else
                        {
                            _logger.LogInformation("Produced event to topic - {topicName}. Value: {@Value}", topicName, action);
                        }
                    });
                
                producer.Flush(TimeSpan.FromSeconds(10));
                _logger.LogInformation($"Message were produced to topic {topicName}");
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
                            _logger.LogError("Failed to deliver message: {Reason}", deliveryReport.Error.Reason);
                        }
                        else
                        {
                            _logger.LogInformation("Produced event to topic - {topicName}. Value: {@Value}", topicName, action);
                        }
                    });


                producer.Flush(TimeSpan.FromSeconds(10));
                _logger.LogInformation($"Message were produced to topic {topicName}");
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
                            _logger.LogError("Failed to deliver message: {Reason}", deliveryReport.Error.Reason);
                        }
                        else
                        {
                            _logger.LogInformation("Produced event to topic - {topicName}. Value: {@Value}", topicName, action);
                        }
                    });


                producer.Flush(TimeSpan.FromSeconds(10));
                _logger.LogInformation($"Message were produced to topic {topicName}");
            }
        }
    }
}
