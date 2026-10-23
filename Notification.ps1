$cheminCSV = "C:\PatchManagement\ComplianceReport.csv"

$rapport = @(Import-Csv -Path $cheminCSV)

$anomalies = @(
    $rapport | Where-Object {
        $_.Etat -eq "NON CONFORME" -or
        $_.Etat -eq "INACCESSIBLE"
    }
)

if ($anomalies.Count -eq 0) {
    Write-Host "Aucune anomalie detectee. Notification inutile."
    return
}

$message = @"
[PATCH MANAGEMENT] Anomalies detectees

Date du controle : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")

Postes controles : $($rapport.Count)
Postes non conformes : $( @($rapport | Where-Object { $_.Etat -eq "NON CONFORME" }).Count )
Postes inaccessibles : $( @($rapport | Where-Object { $_.Etat -eq "INACCESSIBLE" }).Count )

DETAIL DES ANOMALIES :
"@

foreach ($poste in $anomalies) {
    $message += "`n`n$($poste.Poste) : $($poste.Etat)"

    if ($poste.ListeKBManquantes) {
        $message += "`nKB manquantes : $($poste.ListeKBManquantes)"
    }
}

Write-Host "`n=== NOTIFICATION PREPAREE ==="
Write-Host $message
# ENVOI DE LA NOTIFICATION VIA MAILPIT

$logFile = "C:\PatchManagement\PatchManager.log"
$pieceJointe = "C:\PatchManagement\SecurityReport.html"

$smtp = $null
$mail = $null

try {
    if (-not (Test-Path $pieceJointe)) {
        throw "Rapport HTML introuvable."
    }

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = "patchmanager@entreprise.test"
    $mail.To.Add("admin@entreprise.test")
    $mail.Subject = "[PATCH MANAGEMENT] Anomalies detectees"
    $mail.Body = $message

    $attachment = New-Object System.Net.Mail.Attachment($pieceJointe)
    $mail.Attachments.Add($attachment)

    $smtp = New-Object System.Net.Mail.SmtpClient("127.0.0.1", 1025)
    $smtp.EnableSsl = $false

    $smtp.Send($mail)

    Write-Host "Notification envoyee avec succes !"

    Add-Content $logFile -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') ; Notification envoyee via Mailpit"
}
catch {
    Write-Host "ERREUR : $($_.Exception.Message)"

    Add-Content $logFile -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') ; ERREUR ; Notification non envoyee ; $($_.Exception.Message)"
}
finally {
    if ($mail) { $mail.Dispose() }
    if ($smtp) { $smtp.Dispose() }
}