$computers = Get-Content "C:\PatchManagement\computers.txt"
$cred = Get-Credential -UserName "PC01\admin" -Message "Connexion a PC01"

$patches = @()
$summary = @()

foreach ($computer in $computers) {

    $name, $ip = $computer.Split(";")

    try {
        if ($ip -eq "192.168.200.1") {
            $updates = @(Get-HotFix -ErrorAction Stop)
        }
        else {
            $updates = @(Invoke-Command -ComputerName $ip `
                -Credential $cred -ErrorAction Stop `
                -ScriptBlock { Get-HotFix })
        }

        foreach ($update in $updates) {
            $patches += [PSCustomObject]@{
                Poste = $name
                AdresseIP = $ip
                KB = $update.HotFixID
                Description = $update.Description
                DateInstallation = $update.InstalledOn
                InstallePar = $update.InstalledBy
            }
        }

        $latest = $updates |
            Where-Object { $_.InstalledOn } |
            Sort-Object InstalledOn -Descending |
            Select-Object -First 1

        $summary += [PSCustomObject]@{
            Poste = $name
            AdresseIP = $ip
            Etat = "Accessible"
            NombreCorrectifs = $updates.Count
            DerniereInstallation = $latest.InstalledOn
            DerniereKB = $latest.HotFixID
        }
    }
    catch {
        $summary += [PSCustomObject]@{
            Poste = $name
            AdresseIP = $ip
            Etat = "Inaccessible"
            NombreCorrectifs = 0
            DerniereInstallation = $null
            DerniereKB = ""
        }

        Write-Warning "Impossible de collecter les correctifs de $name : $($_.Exception.Message)"
    }
}

$patches |
    Sort-Object Poste, @{Expression="DateInstallation";Descending=$true} |
    Export-Csv "C:\PatchManagement\PatchesInventory.csv" -NoTypeInformation -Encoding UTF8

Write-Host "`n=== SYNTHESE DES CORRECTIFS ==="

$summary | Format-Table -AutoSize

Write-Host "`nFichier genere : C:\PatchManagement\PatchesInventory.csv"