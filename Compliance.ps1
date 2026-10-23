$required = @(Get-Content "C:\PatchManagement\required-patches.txt")
$installed = @(Import-Csv "C:\PatchManagement\PatchesInventory.csv")
$computers = Get-Content "C:\PatchManagement\computers.txt"

$cred = Get-Credential -UserName "PC01\admin" -Message "Connexion a PC01"

$results = foreach ($computer in $computers) {

    $name, $ip = $computer.Split(";")
    $dateControle = Get-Date

    try {
        if ($ip -eq "192.168.200.1") {
            $kbInstallees = @(
                Get-HotFix -ErrorAction Stop |
                Select-Object -ExpandProperty HotFixID
            )
        }
        else {
            $kbInstallees = @(
                Invoke-Command -ComputerName $ip `
                    -Credential $cred `
                    -ErrorAction Stop `
                    -ScriptBlock {
                        Get-HotFix -ErrorAction Stop |
                        Select-Object -ExpandProperty HotFixID
                    }
            )
        }

        $kbManquantes = @(
            $required | Where-Object {
                $_ -notin $kbInstallees
            }
        )

        if ($kbManquantes.Count -eq 0) {
            $etat = "CONFORME"
        }
        else {
            $etat = "NON CONFORME"
        }

        $nombreManquantes = $kbManquantes.Count
        $listeManquantes = $kbManquantes -join ", "
    }
    catch {
        $etat = "INACCESSIBLE"
        $nombreManquantes = $null
        $listeManquantes = ""
    }

    [PSCustomObject]@{
        Poste = $name
        AdresseIP = $ip
        KBRequises = $required.Count
        KBManquantes = $nombreManquantes
        ListeKBManquantes = $listeManquantes
        Etat = $etat
        DateControle = $dateControle
    }
}

$results | Export-Csv -Path "C:\PatchManagement\ComplianceReport.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Rapport de conformite genere : C:\PatchManagement\ComplianceReport.csv"

$accessibles = @($results | Where-Object { $_.Etat -ne "INACCESSIBLE" })
$conformes = @($results | Where-Object { $_.Etat -eq "CONFORME" })

if ($accessibles.Count -gt 0) {
    $taux = [math]::Round(($conformes.Count / $accessibles.Count) * 100, 2)
    Write-Host "Taux global de conformite : $taux %"
} else {
    Write-Host "Taux global de conformite : Non calculable"
}