# Quick setup script for pushing to GitHub
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  GitHub Repository Setup Helper" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Current directory: $PWD`n" -ForegroundColor Yellow

# Check git status
$gitPath = "C:\Program Files\Git\bin\git.exe"

Write-Host "Step 1: Checking repository status..." -ForegroundColor Green
& $gitPath status

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n1. Create a new GitHub repository:" -ForegroundColor White
Write-Host "   Go to: https://github.com/new" -ForegroundColor Cyan
Write-Host "   - Name: azure-hybrid-worker-lab" -ForegroundColor Gray
Write-Host "   - Description: Complete Terraform lab for Azure Automation Hybrid Worker" -ForegroundColor Gray
Write-Host "   - Public or Private (your choice)" -ForegroundColor Gray
Write-Host "   - DO NOT initialize with README" -ForegroundColor Red

Write-Host "`n2. After creating the repo, run these commands:" -ForegroundColor White
Write-Host "   (Using your GitHub username: petarivanov-msft)`n" -ForegroundColor Gray

$commands = @"
git remote add origin https://github.com/petarivanov-msft/azure-hybrid-worker-lab.git
git branch -M main
git push -u origin main
"@

Write-Host $commands -ForegroundColor Cyan

Write-Host "`n3. Then use Azure Cloud Shell:" -ForegroundColor White
Write-Host "   Go to: https://shell.azure.com`n" -ForegroundColor Cyan

$cloudShellCommands = @"
git clone https://github.com/petarivanov-msft/azure-hybrid-worker-lab.git
cd azure-hybrid-worker-lab
terraform init
terraform apply -auto-approve
"@

Write-Host $cloudShellCommands -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Files ready for commit:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
& $gitPath ls-files

Write-Host "`n✅ Repository is ready to push to GitHub!" -ForegroundColor Green
Write-Host "📖 See SETUP_GUIDE.md for detailed instructions`n" -ForegroundColor Yellow
