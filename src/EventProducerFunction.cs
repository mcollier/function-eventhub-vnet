using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace EventProducerConsumerSample
{
    public class EventProducerFunction
    {
        private readonly ILogger<EventProducerFunction> _logger;

        public EventProducerFunction(ILogger<EventProducerFunction> logger)
        {
            _logger = logger;
        }

        [Function("TimerTriggerToEventHub")]
        [EventHubOutput("%EVENTHUB_NAME%", Connection = "EVENTHUB_CONNECTION")]
        public string TimerTriggerToEventHubFunction(
            [TimerTrigger("0 */1 * * * *")] TimerInfo myTimer)
        {
            string messageBody = $"C# Timer trigger function executed at: {DateTime.Now}";
            _logger.LogInformation(messageBody);

            // Send message to output Event Hub
            return messageBody;
        }
    }
}