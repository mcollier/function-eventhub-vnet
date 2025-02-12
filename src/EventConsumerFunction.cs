using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace EventProducerConsumerSample
{
    public class EventConsumerFunction
    {
        private readonly ILogger<EventConsumerFunction> _logger;

        public EventConsumerFunction(ILogger<EventConsumerFunction> logger)
        {
            _logger = logger;
        }

        [Function("EventHubTrigger")]
        public async Task EventHubTriggerFunction(
            [EventHubTrigger("%EVENTHUB_NAME%", Connection = "EVENTHUB_CONNECTION", ConsumerGroup = "%EVENTHUB_CONSUMER_GROUP_NAME%")] EventData[] events)
        {
            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    // Replace these two lines with your processing logic.
                    _logger.LogInformation($"C# Event Hub trigger function processed a message: {eventData.EventBody}");
                    await Task.Yield();
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}