namespace Javelin.API.Infrastructure
{
    public interface IProducer
    {
        Task produce(string topicName);
    }
}