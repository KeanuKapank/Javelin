using Asp.Versioning;
using Javelin.API.Infrastructure;
using Javelin.API.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Javelin.API.Controllers.v1
{
    [Route("api/v{version:apiVersion}/[controller]")]
    [ApiController]
    [ApiVersion("1.0")]
    public class ActionController : ControllerBase
    {
        private readonly IProducer _producer;

        public ActionController(IProducer producer)
        {
            _producer = producer;
        }

        [HttpPost("ui")]
        public async Task<IActionResult> LogUIAction([FromBody] UILogAction action)
        {
            await _producer.Produce("ui-log-action", action);
            return Ok(action);
        }

        [HttpPost("api")]
        public async Task<IActionResult> LogAPIAction([FromBody] APILogAction action)
        {
            await _producer.Produce("api-log-action", action);
            return Ok(action);
        }

        [HttpPost("db")]
        public async Task<IActionResult> LogDBAction([FromBody] DBLogAction action)
        {
            await _producer.Produce("db-log-action", action);
            return Ok(action);
        }
    }
}
