using Javelin.API.Models;

namespace Javelin.API.Infrastructure
{
    public interface IProducer
    {
        Task Produce(string topicName, UILogAction action);
        Task Produce(string topicName, APILogAction action);
        Task Produce(string topicName, DBLogAction action);
    }
}