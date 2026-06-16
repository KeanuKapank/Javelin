namespace Javelin.API.Infrastructure
{
    public interface IProducer
    {
        Task Produce(string topicName);
    }
}