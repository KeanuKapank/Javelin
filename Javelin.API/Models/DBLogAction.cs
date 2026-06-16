using Javelin.API.Enums;

namespace Javelin.API.Models
{
    public class DBLogAction : LogAction
    {
        public required string TransactionId { get; set; }
        public DBLogActionType DBLogActionType { get; set; }
    }
}
