using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Request members:"
$Request | Get-Member | Out-String | Write-Host

Write-Host "Trigger metadata members:"
$TriggerMetadata | Get-Member | Out-String | Write-Host

try {
    # 1. Récupérer le corps brut et la signature GitHub
$rawBody = $Request.RawBody
$signature = $Request.Headers['x-hub-signature-256']
$secret = $env:GitHubWebhookSecret

    if ([string]::IsNullOrWhiteSpace($secret)) {
        throw "La variable GitHubWebhookSecret est absente."
    }

    if ($null -eq $rawBody) {
        throw "Le corps brut de la requête est indisponible."
    }

    if ($rawBody -is [byte[]]) {
        $rawBytes = $rawBody
    }
    else {
        $rawBytes = [System.Text.Encoding]::UTF8.GetBytes([string]$rawBody)
    }

    if ([string]::IsNullOrWhiteSpace($secret)) {
        throw "La variable GitHubWebhookSecret est absente."
    }

    if ([string]::IsNullOrWhiteSpace($rawBody)) {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = "Corps brut de la requête indisponible."
        })
        return
    }

    # 2. Vérifier la signature HMAC-SHA256
    if ($signature -notmatch '^sha256=([0-9a-fA-F]{64})$') {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::Unauthorized
            Body = "Signature GitHub absente ou invalide."
        })
        return
    }

    $hmac = [System.Security.Cryptography.HMACSHA256]::new(
        [System.Text.Encoding]::UTF8.GetBytes($secret)
    )

    try {
        $hashBytes = $hmac.ComputeHash($rawBytes)
    }
    finally {
        $hmac.Dispose()
    }

    $expectedBytes = [Convert]::FromHexString($Matches[1])

    if (-not [System.Security.Cryptography.CryptographicOperations]::FixedTimeEquals(
        $hashBytes, $expectedBytes
    )) {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::Unauthorized
            Body = "Signature GitHub invalide."
        })
        return
    }

    # 3. Analyser le JSON uniquement après authentification
    $body = $Request.Body

    if ($body -is [System.Collections.IDictionary]) {
        $commits = $body['commits']
    }
    else {
        $commits = $body.commits
    }

    $eventType = $Request.Headers['x-github-event']

    if ($eventType -eq 'ping') {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        ContentType = "text/plain"
        Body = "Pong"
    })
    return
}

    Write-Host "Type de body : $($body.GetType().FullName)"
    Write-Host "Propriétés de body : $(($body.PSObject.Properties.Name) -join ', ')"
    Write-Host "Type de Request.Body : $($Request.Body.GetType().FullName)"

    if ($null -eq $commits) {
        throw "Payload GitHub invalide : aucun commit."
    }

    Import-Module Az.Storage -ErrorAction Stop

    $connectionString = $env:AzureWebJobsStorageForGitHubLogs
    if ([string]::IsNullOrWhiteSpace($connectionString)) {
        throw "Variable de connexion au stockage absente."
    }

    $context = New-AzStorageContext -ConnectionString $connectionString
    $containerName = "githubeventslogs"
    $timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $events = @()

    foreach ($commit in $commits) {
        $changes = @(
            foreach ($file in $commit.added) {
                [PSCustomObject]@{ file = $file; event = "added" }
            }
            foreach ($file in $commit.modified) {
                [PSCustomObject]@{ file = $file; event = "modified" }
            }
            foreach ($file in $commit.removed) {
                [PSCustomObject]@{ file = $file; event = "removed" }
            }
        )

        foreach ($change in $changes) {
            $entry = [PSCustomObject]@{
                file      = $change.file
                event     = $change.event
                timestamp = $timestamp
                commit    = $commit.id
            }

            $json = $entry | ConvertTo-Json -Compress
            $blobName = "{0}_{1}_{2}.json" -f `
                [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssfffffffZ"), `
                [Guid]::NewGuid().ToString("N"), `
                $change.event

            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) `
                ([Guid]::NewGuid().ToString("N") + ".json")

            try {
                [System.IO.File]::WriteAllText(
                    $tempFile,
                    $json,
                    [System.Text.UTF8Encoding]::new($false)
                )

                Set-AzStorageBlobContent `
                    -File $tempFile `
                    -Container $containerName `
                    -Blob $blobName `
                    -Context $context `
                    -ErrorAction Stop | Out-Null
            }
            finally {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }

            $events += $entry
        }
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        ContentType = "application/json"
        Body = @{
            message = "Événements authentifiés et enregistrés."
            count   = $events.Count
            events  = @($events)
        } | ConvertTo-Json -Depth 5
    })
}
catch {
    Write-Error $_
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        ContentType = "text/plain"
        Body = "Erreur interne lors du traitement du webhook."
    })
}
