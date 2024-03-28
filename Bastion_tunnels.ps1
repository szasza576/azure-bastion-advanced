# Reading the config file
$config = 
    Get-Content -Path Bastion_config.json |
        ConvertFrom-Json

# Switching to the proper subscription
Write-Host "Switching subscription to: " $config.Subscription
az account set --subscription $config.Subscription
if (! $?) {
    Write-Host "Subscription change failed. Maybe it is time to login again: az login"
    exit 0
} else
{
    Write-Host "Successfully changed subscription"
}

# Check Jumpserver and start if needed.
Write-Host "Checking JumpServer's state..."
$vmState=(az vm show --ids $config.JumpServerResourceID --show-details --query powerState -o tsv)
if (! $?) {
    Write-Host "VM is not found. Please check the resource ID in the config file."
    exit 0
}
if ($vmState = "VM running") {
    Write-Host "VM is running"
} else
{
    Write-Host "VM is not running. Waking up VM."
    az vm start --ids $config.JumpServerResourceID
    if (! $?) {
        Write-Host "VM wake up failed."
        exit 0
    }
} 

# Starting the tunnels
$jobs = @()
foreach ($tunnel in $config.Tunnels) {
    if ($tunnel.Enabled) {
        $jobs += Start-ThreadJob -StreamingHost $Host -ThrottleLimit 200 -ScriptBlock {
            $c = $using:config
            $t = $using:tunnel
            while ($true) {
                Write-Host "Opening Bastion tunnel via jumpserver to: " $t.Description
                &{az network bastion tunnel `
                  --target-resource-id $c.JumpServerResourceID `
                  --ids $c.BastionResourceID `
                  --port $t.LocalAggregatorPort `
                  --resource-port 22} *>&1 | Out-Host
                Write-Host "Bastion tunnel failed to: " $t.Description
                Start-Sleep -Seconds 5
            }
        }
        # Wait 5 seconds to establish the Bastion tunnel
        Start-Sleep -Seconds 5
        $jobs += Start-ThreadJob -StreamingHost $Host -ScriptBlock {
            $c = $using:config
            $t = $using:tunnel
            while ($true) {
                Write-Host "Opening SSH aggregator tunnel for: " $t.Description
                &{ssh -L "$($t.LocalPort):$($t.RemoteHost):$($t.RemotePort)" `
                    -p "$($t.LocalAggregatorPort)" `
                    -N `
                    -o TCPKeepAlive=false `
                    -o ServerAliveInterval=10 `
                    -o ServerAliveCountMax=525600 `
                    -o StrictHostKeyChecking="no" `
                    "$($c.JumpServerUser)@127.0.0.1" `
                    -i "$($c.JumpServerKeyPath)"} *>&1 | Out-Host
                Write-Host "SSH aggregator tunnel failed to: " $t.Description
                Start-Sleep -Seconds 5
            }
        }
    }
}


Start-Sleep -Seconds 5
Write-Host "`n`nTunnels are configured..."
Wait-Job -Job $jobs