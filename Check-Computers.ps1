$computers = Get-Content "C:\PatchManagement\computers.txt"

foreach ($computer in $computers) {

    $name, $ip = $computer.Split(";")

    $result = ping.exe -n 2 $ip

    if ($LASTEXITCODE -eq 0) {
        $status = "Accessible"
    }
    else {
        $status = "Inaccessible"
    }

    [PSCustomObject]@{
        Poste     = $name
        AdresseIP = $ip
        Etat      = $status
    }
}