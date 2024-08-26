function Start-UDPLogger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Port = 10000,
        [Parameter(Mandatory = $false)]
        [string]$LogFile = "C:\Logs\udpserver.log",
        [Parameter(Mandatory = $false)]
        [string]$JsonFile = "C:\Logs\active_ips.json"
    )

    # Sicherstellen, dass der Log-Ordner existiert
    $logDir = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory | Out-Null
    }

    # Sicherstellen, dass die JSON-Datei existiert
    if (-not (Test-Path $JsonFile)) {
        @() | ConvertTo-Json | Set-Content -Path $JsonFile
    }

    # UDP-Client erstellen
    $UdpClient = New-Object System.Net.Sockets.UdpClient($Port)
    $RemoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

    # IP-Adressen Tracking
    $ipTracker = @{}

    # Funktion zum Schreiben in die Log-Datei
    function Write-Log {
        param (
            [string]$Message
        )
        Add-Content -Path $LogFile -Value "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message"
    }

    # Funktion zum Formatieren des Datums in DD-HH-MM
    function Format-Date {
        param (
            [datetime]$DateTime
        )
        return $DateTime.ToString('yyyy-MM-dd HH:mm:ss')
    }

    # Funktion zum Laden der IP-Daten aus der JSON-Datei
    function Load-IPData {
        if (Test-Path $JsonFile) {
            $content = Get-Content -Path $JsonFile -Raw
            return $content | ConvertFrom-Json
        } else {
            return @()
        }
    }

    # Funktion zum Speichern der IP-Daten in der JSON-Datei
    function Save-IPData {
        param (
            [array]$Data
        )
        $Data | ConvertTo-Json -Depth 3 | Set-Content -Path $JsonFile
    }

    # Initiales Laden der IP-Daten
    $ipData = Load-IPData

    Write-Log "Server ist bereit und wartet auf Verbindungen auf Port $Port..."

    try {
        while ($true) {
            try {
                # Daten empfangen
                $ReceiveBytes = $UdpClient.Receive([ref]$RemoteEndPoint)

                # Daten in String umwandeln
                $ASCIIEncoding = New-Object System.Text.ASCIIEncoding
                $ReceivedString = $ASCIIEncoding.GetString($ReceiveBytes)

                # IP-Adresse und Zeit aktualisieren
                $ipAddress = $RemoteEndPoint.Address.ToString()
                $currentTime = Get-Date
                $ipTracker[$ipAddress] = $currentTime

                # Informationen in die Log-Datei schreiben
                Write-Log "Empfangen von $($RemoteEndPoint.Address):$($RemoteEndPoint.Port) - Payload: $ReceivedString"
            }
            catch {
                Write-Log "Fehler beim Empfangen von Daten: $_"
            }

            # Überprüfen und Bereinigen von inaktiven IPs
            $fiveMinutesAgo = (Get-Date).AddMinutes(-5)
            $ipTracker.Keys | ForEach-Object {
                if ($ipTracker[$_] -lt $fiveMinutesAgo) {
                    $ipTracker.Remove($_)
                }
            }

            # IP-Daten aktualisieren
            $ipData = $ipData | Where-Object { $_.IPAddress -in $ipTracker.Keys }
            $ipData | ForEach-Object {
                $_.LastSeen = Format-Date -DateTime $ipTracker[$_.IPAddress]
            }
            foreach ($ipAddress in $ipTracker.Keys) {
                if (-not ($ipData | Where-Object { $_.IPAddress -eq $ipAddress })) {
                    $ipData += [PSCustomObject]@{ IPAddress = $ipAddress; LastSeen = Format-Date -DateTime $ipTracker[$ipAddress] }
                }
            }
            
            # IP-Daten in der JSON-Datei speichern
            Save-IPData -Data $ipData

            Start-Sleep -Seconds 10
        }
    }
    catch {
        Write-Log "Server gestoppt."
    }
    finally {
        $UdpClient.Close()
    }
}