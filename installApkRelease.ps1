# Bật bảng mã UTF-8 cho console để hiển thị đúng dấu tiếng Việt
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "    SMART SPACE - CÀI ĐẶT APK RELEASE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Kiểm tra lệnh adb
$adbExe = "adb"
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    # Thử tìm trong thư mục Android SDK mặc định trên Windows
    $fallbackAdb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $fallbackAdb) {
        $env:PATH += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
        $adbExe = $fallbackAdb
    } else {
        Write-Host "[LỖI] Không tìm thấy lệnh 'adb'. Vui lòng cài đặt Android Platform-Tools hoặc thêm vào biến môi trường PATH." -ForegroundColor Red
        exit 1
    }
}

# 2. Quét danh sách thiết bị đang kết nối
Write-Host ""
Write-Host "Đang quét các thiết bị kết nối qua adb..." -ForegroundColor Gray
$rawDevices = adb devices -l 2>&1

$devices = @()
foreach ($line in ($rawDevices -split '\r?\n')) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed -like 'List of devices attached*' -or $trimmed -like '*daemon*') {
        continue
    }
    $parts = -split $trimmed
    if ($parts.Length -ge 2) {
        $serial = $parts[0]
        $state  = $parts[1]
        $model  = $serial
        if ($trimmed -match 'model:([^\s]+)') {
            $model = $matches[1] -replace '_', ' '
        }
        $devices += [PSCustomObject]@{
            Serial = $serial
            State  = $state
            Model  = $model
        }
    }
}

if ($devices.Count -eq 0) {
    Write-Host "[!] Không tìm thấy thiết bị nào đang kết nối gỡ lỗi qua adb." -ForegroundColor Yellow
    Write-Host "Vui lòng kết nối thiết bị qua cáp USB hoặc Wifi và bật chế độ 'Gỡ lỗi USB' (USB Debugging)." -ForegroundColor Yellow
    exit 0
}

# 3. Hiển thị danh sách và hỏi người dùng muốn cài đặt cho thiết bị nào
Write-Host ""
Write-Host "Muốn tải 3 app release (admin, client và staff) cho thiết bị nào:" -ForegroundColor Green
for ($i = 0; $i -lt $devices.Count; $i++) {
    $dev = $devices[$i]
    $num = $i + 1
    $statusText = if ($dev.State -ne "device") { " [$($dev.State)]" } else { "" }
    Write-Host "[$num]: $($dev.Model) ($($dev.Serial))$statusText"
}

$selectedIndex = -1
while ($true) {
    $promptRange = if ($devices.Count -eq 1) { "1" } else { "1-$($devices.Count)" }
    $choice = Read-Host "`nchọn $promptRange hoặc bấm q để thoát chương trình"
    $choice = $choice.Trim()

    if ($choice -eq 'q' -or $choice -eq 'Q') {
        Write-Host "Đã thoát chương trình." -ForegroundColor Yellow
        exit 0
    }

    if ($choice -match '^\d+$') {
        $val = [int]$choice
        if ($val -ge 1 -and $val -le $devices.Count) {
            $selectedIndex = $val - 1
            break
        }
    }

    Write-Host "Lựa chọn không hợp lệ, vui lòng thử lại!" -ForegroundColor Red
}

$targetDevice = $devices[$selectedIndex]
if ($targetDevice.State -ne "device") {
    Write-Host ""
    Write-Host "[CẢNH BÁO] Thiết bị $($targetDevice.Serial) đang ở trạng thái '$($targetDevice.State)'." -ForegroundColor Yellow
    if ($targetDevice.State -eq "unauthorized") {
        Write-Host "Vui lòng mở khóa điện thoại và nhấn 'Cho phép gỡ lỗi USB' (Allow USB Debugging)." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Đã chọn thiết bị: $($targetDevice.Model) ($($targetDevice.Serial))" -ForegroundColor Cyan

# 4. Kiểm tra sự tồn tại của 3 file APK release
$rootPath = $PSScriptRoot
$appList = @(
    @{
        Key   = "client"
        Name  = "Client"
        Paths = @(
            "$rootPath\smartspace_client\build\app\outputs\flutter-apk\app-release.apk",
            "$rootPath\smartspace_client\build\app\outputs\apk\release\app-release.apk"
        )
    },
    @{
        Key   = "admin"
        Name  = "Admin"
        Paths = @(
            "$rootPath\smartspace_admin\build\app\outputs\flutter-apk\app-release.apk",
            "$rootPath\smartspace_admin\build\app\outputs\apk\release\app-release.apk"
        )
    },
    @{
        Key   = "staff"
        Name  = "Staff"
        Paths = @(
            "$rootPath\smartspace_staff\build\app\outputs\flutter-apk\app-release.apk",
            "$rootPath\smartspace_staff\build\app\outputs\apk\release\app-release.apk"
        )
    }
)

$foundApps = @()
$missingApps = @()

Write-Host ""
Write-Host "Kiểm tra các file APK release..." -ForegroundColor Gray
foreach ($app in $appList) {
    $existingPath = $null
    foreach ($p in $app.Paths) {
        if (Test-Path $p) {
            $existingPath = $p
            break
        }
    }

    if ($null -ne $existingPath) {
        $foundApps += [PSCustomObject]@{
            Name = $app.Name
            Path = $existingPath
        }
        Write-Host "  [OK] $($app.Name): Tìm thấy file APK release ($existingPath)" -ForegroundColor Green
    } else {
        $missingApps += $app.Name
        Write-Host "  [X]  $($app.Name): Chưa có file APK release" -ForegroundColor Red
    }
}

# Xử lý số lượng file tìm thấy
if ($foundApps.Count -eq 0) {
    Write-Host ""
    Write-Host "[LỖI] Không tìm thấy bất kỳ file APK release nào!" -ForegroundColor Red
    Write-Host "Vui lòng thực hiện build release trước bằng lệnh: npm run build-all:release" -ForegroundColor Yellow
    exit 1
} elseif ($foundApps.Count -lt 3) {
    Write-Host ""
    $confirm = Read-Host "hiện phát hiện $($foundApps.Count) file apk, có tiến hành cài đặt hay ko? (y/n)"
    if ($confirm.Trim() -notmatch '^(y|yes)$') {
        Write-Host "Đã hủy tiến trình cài đặt." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host ""
    Write-Host "Đã tìm thấy đầy đủ 3/3 file APK release." -ForegroundColor Green
}

# 5. Tiến hành cài đặt các app vào thiết bị đã chọn với hiệu ứng xoay vòng
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TIẾN HÀNH CÀI ĐẶT VÀO $($targetDevice.Model) ($($targetDevice.Serial))..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$successCount = 0
foreach ($app in $foundApps) {
    Write-Host ""
    Write-Host "[+] Cài đặt app $($app.Name)..." -ForegroundColor Yellow
    Write-Host "    File: $($app.Path)" -ForegroundColor Gray

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $adbExe
    $psi.Arguments = "-s $($targetDevice.Serial) install -r `"$($app.Path)`""
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)

    $spinner = @('|', '/', '-', '\')
    $idx = 0
    while (-not $proc.HasExited) {
        $frame = $spinner[$idx % $spinner.Length]
        $sec = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
        Write-Host "`r    [$frame] Đang tiến hành cài đặt (${sec}s)..." -NoNewline -ForegroundColor Cyan
        [System.Threading.Thread]::Sleep(100)
        $idx++
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $stopwatch.Stop()
    $totalSec = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)

    $result = ($stdout + "`n" + $stderr).Trim()

    # Xóa dòng xoay vòng khi hoàn thành
    Write-Host "`r                                                                 `r" -NoNewline

    if ($result -match "Success") {
        Write-Host "    -> Cài đặt $($app.Name) THÀNH CÔNG! (${totalSec}s)" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "    -> Cài đặt $($app.Name) THẤT BẠI! (${totalSec}s)" -ForegroundColor Red
        Write-Host "    Chi tiết lỗi: $result" -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
$summaryColor = if ($successCount -eq $foundApps.Count) { "Green" } else { "Yellow" }
Write-Host "KẾT QUẢ: Cài đặt thành công $successCount/$($foundApps.Count) ứng dụng." -ForegroundColor $summaryColor
Write-Host "==========================================" -ForegroundColor Cyan