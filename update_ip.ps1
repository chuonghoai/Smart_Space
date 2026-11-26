$ErrorActionPreference = "Stop"

try {
    # Lay IPv4 cua cac network interface co status Up
    $ipInfo = Get-NetIPAddress -AddressFamily IPv4 | 
              Where-Object { 
                  $_.InterfaceAlias -notmatch "(Loopback|vEthernet|Virtual|WSL|Docker)" -and 
                  (Get-NetAdapter -Name $_.InterfaceAlias).Status -eq "Up" 
              } | 
              Select-Object -First 1

    if ($null -eq $ipInfo -or [string]::IsNullOrWhiteSpace($ipInfo.IPAddress)) {
        Write-Host "ERROR: Khong tim thay dia chi IPv4 hop le dang hoat dong." -ForegroundColor Red
        Write-Host "Vui long kiem tra lai ket noi mang." -ForegroundColor Red
        exit 1
    }

    $lanIp = $ipInfo.IPAddress
    Write-Host "Da tim thay IPv4: $lanIp" -ForegroundColor Green

    # Dam bao thu muc ton tai
    $assetsDir = "mobile_shared\assets"
    if (-not (Test-Path $assetsDir)) {
        New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null
    }

    # Ghi ra local.json
    $jsonPath = Join-Path $assetsDir "local.json"
    $jsonContent = "{ `"lanIp`": `"$lanIp`" }"
    
    Set-Content -Path $jsonPath -Value $jsonContent -Encoding UTF8
    Write-Host "Da ghi IP vao $jsonPath" -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: Loi trong qua trinh cap nhat IP:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
exit 0
