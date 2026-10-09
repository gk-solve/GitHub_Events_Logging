# GitHub-Events-Logging
Events tracking on GitHub using a webhook and Azure function + Blob storage to process and host the log

In this project, a webhook reads the modfications brought to a GitHub repository.
Each commit & push will call an HTTP-triggered Azure function, which will process the payload released by the webhook.
This HTTP_triggered Azure function will read and process the payload, and create a new Blob in an Azure Blob storage containing the event details recorded in the payload (file added, modified or removed + date).
