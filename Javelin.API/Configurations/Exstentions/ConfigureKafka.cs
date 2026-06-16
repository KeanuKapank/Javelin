using Javelin.API.Infrastructure;

namespace Javelin.API.Configurations.Exstentions
{
    public static class ConfigureKafka
    {
        public static void ConfigureKafkaServices(this IServiceCollection services)
        {
            services.AddSingleton<IProducer, Producer>();
        }
    }
}
