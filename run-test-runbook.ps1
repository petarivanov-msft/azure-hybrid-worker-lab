# Helper script to run the test runbook and display its output

param(
    [string]$ResourceGroupName = "rg-hybrid-worker-lab",
    [string]$AutomationAccountName = "hwlab-automation",
    [string]$RunbookName = "Test-HybridWorker-ManagedIdentity",
    [string]$HybridWorkerGroup = "hwlab-worker-group"
)

Write-Host "Starting runbook: $RunbookName on Hybrid Worker Group: $HybridWorkerGroup" -ForegroundColor Cyan

# Start the runbook job
$job = az automation runbook start `
    --automation-account-name $AutomationAccountName `
    --resource-group $ResourceGroupName `
    --name $RunbookName `
    --run-on $HybridWorkerGroup | ConvertFrom-Json

$jobName = $job.name
$jobId = $job.jobId

Write-Host "`nJob started successfully!" -ForegroundColor Green
Write-Host "Job Name: $jobName" -ForegroundColor Yellow
Write-Host "Job ID: $jobId" -ForegroundColor Yellow
Write-Host "`nWaiting for job to complete..." -ForegroundColor Cyan

# Wait for job completion
$maxWait = 120
$waited = 0
$status = "Running"

while ($status -notin @("Completed", "Failed", "Stopped", "Suspended") -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 5
    $waited += 5
    
    $jobStatus = az automation job show `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name $jobName | ConvertFrom-Json
    
    $status = $jobStatus.status
    Write-Host "." -NoNewline
}

Write-Host "`n`nJob Status: $status" -ForegroundColor $(if ($status -eq "Completed") { "Green" } else { "Red" })

if ($status -eq "Completed") {
    Write-Host "`n========== JOB OUTPUT ==========" -ForegroundColor Green
    
    # Get job output
    $subscriptionId = (az account show --query id -o tsv)
    $outputUrl = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/jobs/$jobName/output?api-version=2023-11-01"
    
    $output = az rest --method get --url $outputUrl
    Write-Host $output
    
    Write-Host "`n========== END OUTPUT ==========" -ForegroundColor Green
    
    # Show job link
    $jobUrl = "https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/jobs/$jobName"
    Write-Host "`nView job in Azure Portal: $jobUrl" -ForegroundColor Cyan
} else {
    Write-Host "`nJob did not complete successfully. Status: $status" -ForegroundColor Red
    Write-Host "Check the Azure Portal for more details." -ForegroundColor Yellow
}
