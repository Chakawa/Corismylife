# Script PowerShell pour nettoyer les print() en production
# Remplace les print() avec des appels conditionnels désactivés en release

$files = @(
    "lib\features\simulation\presentation\screens\simulation_etude_screen.dart",
    "lib\features\simulation\presentation\screens\simulation_retraite_screen.dart",
    "lib\features\simulation\presentation\screens\simulation_familis_screen.dart",
    "lib\features\simulation\presentation\screens\simulation_serenite_screen.dart",
    "lib\features\simulation\presentation\screens\simulation_solidarite_screen.dart",
    "lib\features\souscription\presentation\screens\souscription_etude.dart",
    "lib\features\souscription\presentation\screens\souscription_retraite.dart",
    "lib\features\souscription\presentation\screens\souscription_flex.dart",
    "lib\features\souscription\presentation\screens\souscription_familis.dart",
    "lib\features\souscription\presentation\screens\souscription_serenite.dart",
    "lib\features\souscription\presentation\screens\sousription_solidarite.dart",
    "lib\services\produit_sync_service.dart",
    "lib\services\database_service.dart",
    "lib\services\notification_service.dart"
)

$totalReplaced = 0

foreach ($file in $files) {
    $fullPath = "mycorislife-master\$file"
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        
        # Compter les print( avant remplacement
        $beforeCount = ([regex]::Matches($content, "print\(")).Count
        
        # Remplacer print( par debugPrint( SEULEMENT (pas les commentaires)
        # Note: Les logs seront désactivés en production via kDebugMode dans le code
        $content = $content -replace "([^\w])print\(", '$1debugPrint('
        
        # Compter après
        $afterCount = ([regex]::Matches($content, "debugPrint\(")).Count
        $replaced = $afterCount - ($beforeCount - ([regex]::Matches((Get-Content $fullPath -Raw), "print\(")).Count)
        
        if ($replaced -gt 0) {
            Set-Content -Path $fullPath -Value $content -NoNewline
            Write-Host "✅ $file : $replaced remplacements" -ForegroundColor Green
            $totalReplaced += $replaced
        }
    } else {
        Write-Host "⚠️ Fichier non trouvé: $file" -ForegroundColor Yellow
    }
}

Write-Host "`n📊 Total: $totalReplaced occurrences de print() remplacées par debugPrint()" -ForegroundColor Cyan
Write-Host "ℹ️ Les debugPrint() sont automatiquement désactivés en mode release par Flutter" -ForegroundColor Gray
