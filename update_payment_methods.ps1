# Script pour ajouter les nouveaux moyens de paiement à tous les fichiers de souscription

$files = @(
    "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_familis.dart",
    "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_flex.dart",
    "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_prets_scolaire.dart",
    "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_mon_bon_plan.dart",
    "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_epargne.dart",
    "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_assure_prestige.dart",
    "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_etude.dart"
)

foreach ($file in $files) {
    Write-Host "Traitement de $file..." -ForegroundColor Cyan
    
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Étape 1: Ajouter les controllers et les options
        $old1 = "  final _numeroMobileMoneyController = TextEditingController();`n  final List<String> _modePaiementOptions = [`n    'Virement',`n    'Wave',`n    'Orange Money'`n  ];"
        $new1 = @"
  final _numeroMobileMoneyController = TextEditingController();
  final _nomStructureController = TextEditingController(); // Pour Prélèvement à la source
  final _numeroMatriculeController = TextEditingController(); // Pour Prélèvement à la source
  final _corisMoneyPhoneController = TextEditingController(); // Pour CORIS Money
  final List<String> _modePaiementOptions = [
    'Virement',
    'Wave',
    'Orange Money',
    'Prélèvement à la source',
    'CORIS Money'
  ];
"@
        
        if ($content -match [regex]::Escape($old1)) {
            $content = $content -replace [regex]::Escape($old1), $new1
            Write-Host "  ✓ Controllers et options ajoutés" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Pattern pour controllers non trouvé" -ForegroundColor Yellow
        }
        
        Set-Content $file -Value $content -NoNewline
        Write-Host "  Fichier sauvegardé" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Fichier non trouvé" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "Terminé !" -ForegroundColor Green
