using Javelin.API.Enums;

namespace Javelin.API.Models
{
    public class LogAction
    {
        public ApplicationType ApplicationType { get; set; }
        public DateTimeOffset TimeStamp { get; set; }
        public string? ActionData { get; set; }
    }
}
