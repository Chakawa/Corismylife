$response = Invoke-RestMethod -Uri "http://localhost:5000/api/subscriptions/questionnaire-medical/questions" -Method GET
Write-Host "✅ Success: $($response.success)" -ForegroundColor Green
Write-Host "📊 Questions count: $($response.questions.Count)" -ForegroundColor Cyan
Write-Host "`n📋 First question:" -ForegroundColor Yellow
$response.questions[0] | ConvertTo-Json
