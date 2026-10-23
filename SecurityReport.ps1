$inventory = Import-Csv "C:\PatchManagement\Inventory.csv"
$compliance = Import-Csv "C:\PatchManagement\ComplianceReport.csv"

$rapport = foreach ($poste in $inventory) {

    $controle = $compliance |
        Where-Object { $_.Poste -eq $poste.Poste } |
        Select-Object -First 1

    if ($null -eq $controle) {
        $etat = "NON CONTROLE"
    }
    else {
        $etat = $controle.Etat
    }

    [PSCustomObject]@{
        Poste = $poste.Poste
        AdresseIP = $poste.AdresseIP
        Accessibilite = if ($etat -eq "INACCESSIBLE") {
            "Inaccessible"
        } else {
            $poste.Etat
        }
        Windows = $poste.Windows
        DernierDemarrage = $poste.DernierDemarrage
        WindowsUpdate = $poste.WindowsUpdate
        KBRequises = $controle.KBRequises
        KBManquantes = $controle.KBManquantes
        ListeKBManquantes = $controle.ListeKBManquantes
        Conformite = $etat
        DateControle = $controle.DateControle
    }
}

$rapport | Format-List
$total = @($rapport).Count
$accessibles = @($rapport | Where-Object { $_.Accessibilite -eq "Accessible" })
$inaccessibles = @($rapport | Where-Object { $_.Conformite -eq "INACCESSIBLE" })
$conformes = @($rapport | Where-Object { $_.Conformite -eq "CONFORME" })
$nonConformes = @($rapport | Where-Object { $_.Conformite -eq "NON CONFORME" })

$totalKBManquantes = ($rapport | Measure-Object -Property KBManquantes -Sum).Sum

if ($accessibles.Count -gt 0) {
    $taux = [math]::Round(($conformes.Count / $accessibles.Count) * 100, 2)
} else {
    $taux = $null
}

Write-Host "`n=== SYNTHESE GLOBALE DU PARC ==="
Write-Host "Nombre total de postes : $total"
Write-Host "Postes accessibles : $($accessibles.Count)"
Write-Host "Postes inaccessibles : $($inaccessibles.Count)"
Write-Host "Postes conformes : $($conformes.Count)"
Write-Host "Postes non conformes : $($nonConformes.Count)"
Write-Host "Nombre total de KB manquantes : $totalKBManquantes"

if ($null -ne $taux) {
    Write-Host "Taux global de conformite : $taux %"
} else {
    Write-Host "Taux global de conformite : Non calculable"
}
Write-Host "`n=== POSTES NECESSITANT UNE INTERVENTION ==="

$interventions = @(
    $rapport | Where-Object {
        $_.Conformite -eq "NON CONFORME" -or
        $_.Conformite -eq "INACCESSIBLE"
    }
)

if ($interventions.Count -gt 0) {
    $interventions |
        Select-Object Poste, AdresseIP, Conformite, ListeKBManquantes |
        Format-Table -AutoSize
}
else {
    Write-Host "Aucune intervention necessaire."
}
$cheminHTML = "C:\PatchManagement\SecurityReport.html"

$style = @"
<style>
body {
    font-family: Arial, sans-serif;
    margin: 30px;
    background-color: #f4f6f9;
    color: #243247;
}
h1, h2 { color: #17365d; }
table {
    border-collapse: collapse;
    width: 100%;
    background-color: white;
    margin-bottom: 25px;
}
th, td {
    border: 1px solid #ddd;
    padding: 10px;
    text-align: left;
}
th { background-color: #dbeafe; }
</style>
"@

$synthese = [PSCustomObject]@{
    TotalPostes = $total
    Accessibles = $accessibles.Count
    Inaccessibles = $inaccessibles.Count
    Conformes = $conformes.Count
    NonConformes = $nonConformes.Count
    KBManquantes = $totalKBManquantes
    TauxConformite = if ($null -ne $taux) {
        "$taux %"
    } else {
        "Non calculable"
    }
}

$html = @(
    $rapport | ConvertTo-Html -Fragment -PreContent "<h2>Inventaire et conformite des postes</h2>"
    $synthese | ConvertTo-Html -Fragment -PreContent "<h2>Synthese globale</h2>"
    $interventions | ConvertTo-Html -Fragment -PreContent "<h2>Postes necessitant une intervention</h2>"
) -join "`n"

ConvertTo-Html -Head $style `
    -Title "Rapport de securite Windows" `
    -Body "<h1>Rapport de securite du parc Windows</h1><p>Date de generation : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>$html" |
    Set-Content -Path $cheminHTML -Encoding UTF8

Write-Host "Rapport HTML genere : $cheminHTML"
# JOURNALISATION DE L'AUDIT

$logFile = "C:\PatchManagement\PatchManager.log"

function Write-Log {
    param([string]$Message)

    $date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    Add-Content -Path $logFile -Value "$date ; $Message"
}

Write-Log "Debut de l'audit du parc Windows"

foreach ($poste in $rapport) {

    Write-Log "$($poste.Poste) ; Verification du poste"

    if ($poste.Conformite -eq "INACCESSIBLE") {

        Write-Log "$($poste.Poste) ; WinRM ou collecte inaccessible"

    }
    else {

        Write-Log "$($poste.Poste) ; Accessible"

        if ($poste.Conformite -eq "CONFORME") {

            Write-Log "$($poste.Poste) ; CONFORME"

        }
        elseif ($poste.Conformite -eq "NON CONFORME") {

            Write-Log "$($poste.Poste) ; NON CONFORME ; KB manquantes : $($poste.ListeKBManquantes)"

        }
    }
}

Write-Log "Rapport HTML genere : $cheminHTML"
Write-Log "Taux global de conformite : $taux %"
Write-Log "Fin de l'audit"

Write-Host "Journal mis a jour : $logFile"