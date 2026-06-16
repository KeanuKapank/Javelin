using Javelin.API.Enums;

namespace Javelin.API.Models
{
    public class UILogAction : LogAction
    {
        public required string SessionId { get; set; }
        public required UILogActionType UILogActionType { get; set; }
    }
}
