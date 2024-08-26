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

    # Ensure the log directory exists
    $logDir = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory | Out-Null
    }

    # Ensure the JSON file exists
    if (-not (Test-Path $JsonFile)) {
        @() | ConvertTo-Json | Set-Content -Path $JsonFile
    }

    # Create UDP client
    $UdpClient = New-Object System.Net.Sockets.UdpClient($Port)
    $RemoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

    # IP Address Tracking
    $ipTracker = @{}

    # Function to write to the log file
    function Write-Log {
        param (
            [string]$Message
        )
        Add-Content -Path $LogFile -Value "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message"
    }

    # Function to format date in DD-HH-MM
    function Format-Date {
        param (
            [datetime]$DateTime
        )
        return $DateTime.ToString('dd-HH-mm')
    }

    # Function to load IP data from the JSON file
    function Load-IPData {
        if (Test-Path $JsonFile) {
            $content = Get-Content -Path $JsonFile -Raw
            return $content | ConvertFrom-Json
        } else {
            return @()
        }
    }

    # Function to save IP data to the JSON file
    function Save-IPData {
        param (
            [array]$Data
        )
        $Data | ConvertTo-Json -Depth 3 | Set-Content -Path $JsonFile
    }

    # Initial loading of IP data
    $ipData = Load-IPData

    Write-Log "Server is ready and waiting for connections on port $Port..."

    try {
        while ($true) {
            try {
                # Receive data
                $ReceiveBytes = $UdpClient.Receive([ref]$RemoteEndPoint)

                # Convert data to string
                $ASCIIEncoding = New-Object System.Text.ASCIIEncoding
                $ReceivedString = $ASCIIEncoding.GetString($ReceiveBytes)

                # Update IP address and time
                $ipAddress = $RemoteEndPoint.Address.ToString()
                $currentTime = Get-Date
                $ipTracker[$ipAddress] = $currentTime

                # Write information to the log file
                Write-Log "Received from $($RemoteEndPoint.Address):$($RemoteEndPoint.Port) - Payload: $ReceivedString"
            }
            catch {
                Write-Log "Error receiving data: $_"
            }

            # Check and clean up inactive IPs
            $fiveMinutesAgo = (Get-Date).AddMinutes(-5)
            $ipTracker.Keys | ForEach-Object {
                if ($ipTracker[$_] -lt $fiveMinutesAgo) {
                    $ipTracker.Remove($_)
                }
            }

            # Update IP data
            $ipData = $ipData | Where-Object { $_.IPAddress -in $ipTracker.Keys }
            $ipData | ForEach-Object {
                $_.LastSeen = Format-Date -DateTime $ipTracker[$_.IPAddress]
            }
            foreach ($ipAddress in $ipTracker.Keys) {
                if (-not ($ipData | Where-Object { $_.IPAddress -eq $ipAddress })) {
                    $ipData += [PSCustomObject]@{ IPAddress = $ipAddress; LastSeen = Format-Date -DateTime $ipTracker[$ipAddress] }
                }
            }
            
            # Save IP data to the JSON file
            Save-IPData -Data $ipData

            Start-Sleep -Seconds 10
        }
    }
    catch {
        Write-Log "Server stopped."
    }
    finally {
        $UdpClient.Close()
    }
}
