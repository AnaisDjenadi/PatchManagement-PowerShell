$computers = Get-Content "C:\PatchManagement\computers.txt"

$cred = Get-Credential -UserName "PC01\admin" -Message "Connexion a PC01"

$inventory = foreach ($computer in $computers) {

    $name, $ip = $computer.Split(";")

    try {
        if ($ip -eq "192.168.200.1") {
            $info = & {
                $pc = Get-CimInstance Win32_ComputerSystem
                $bios = Get-CimInstance Win32_BIOS
                $os = Get-CimInstance Win32_OperatingSystem
                $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
                $updates = @(Get-HotFix | Sort-Object InstalledOn -Descending)
                $service = Get-Service wuauserv

                [PSCustomObject]@{
                    NomPoste = $env:COMPUTERNAME
                    Modele = $pc.Model
                    BIOS = $bios.SMBIOSBIOSVersion
                    Windows = $os.Caption
                    Architecture = $os.OSArchitecture
                    DernierDemarrage = $os.LastBootUpTime
                    RAM_Go = [math]::Round($pc.TotalPhysicalMemory / 1GB, 2)
                    DisqueLibre_Go = [math]::Round($disk.FreeSpace / 1GB, 2)
                    DerniereMAJ = if ($updates.Count -gt 0) { $updates[0].InstalledOn } else { $null }
                    NombreMAJ = $updates.Count
                    WindowsUpdate = $service.Status
                }
            }
        }
        else {
            $info = Invoke-Command -ComputerName $ip -Credential $cred -ErrorAction Stop -ScriptBlock {
                $pc = Get-CimInstance Win32_ComputerSystem
                $bios = Get-CimInstance Win32_BIOS
                $os = Get-CimInstance Win32_OperatingSystem
                $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
                $updates = @(Get-HotFix | Sort-Object InstalledOn -Descending)
                $service = Get-Service wuauserv

                [PSCustomObject]@{
                    NomPoste = $env:COMPUTERNAME
                    Modele = $pc.Model
                    BIOS = $bios.SMBIOSBIOSVersion
                    Windows = $os.Caption
                    Architecture = $os.OSArchitecture
                    DernierDemarrage = $os.LastBootUpTime
                    RAM_Go = [math]::Round($pc.TotalPhysicalMemory / 1GB, 2)
                    DisqueLibre_Go = [math]::Round($disk.FreeSpace / 1GB, 2)
                    DerniereMAJ = if ($updates.Count -gt 0) { $updates[0].InstalledOn } else { $null }
                    NombreMAJ = $updates.Count
                    WindowsUpdate = $service.Status
                }
            }
        }

        [PSCustomObject]@{
            Poste = $name
            AdresseIP = $ip
            Etat = "Accessible"
            NomPoste = $info.NomPoste
            Modele = $info.Modele
            BIOS = $info.BIOS
            Windows = $info.Windows
            Architecture = $info.Architecture
            DernierDemarrage = $info.DernierDemarrage
            RAM_Go = $info.RAM_Go
            DisqueLibre_Go = $info.DisqueLibre_Go
            DerniereMAJ = $info.DerniereMAJ
            NombreMAJ = $info.NombreMAJ
            WindowsUpdate = $info.WindowsUpdate
            Erreur = ""
        }
    }
    catch {
        [PSCustomObject]@{
            Poste = $name
            AdresseIP = $ip
            Etat = "Inaccessible"
            NomPoste = ""
            Modele = ""
            BIOS = ""
            Windows = ""
            Architecture = ""
            DernierDemarrage = $null
            RAM_Go = $null
            DisqueLibre_Go = $null
            DerniereMAJ = $null
            NombreMAJ = $null
            WindowsUpdate = ""
            Erreur = $_.Exception.Message
        }
    }
}

$inventory | Format-Table Poste, AdresseIP, Windows, Architecture, DernierDemarrage, WindowsUpdate, Etat -AutoSize

$inventory | Export-Csv "C:\PatchManagement\Inventory.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Inventaire exporte dans C:\PatchManagement\Inventory.csv"