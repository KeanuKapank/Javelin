using Javelin.API.Enums;

namespace Javelin.API.Models
{
    public class APILogAction : LogAction
    {
        public required string TraceId { get; set; }
        public APILogActionType APILogActionType { get; set; }
    }
}
