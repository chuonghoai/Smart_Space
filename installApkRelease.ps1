# Set UTF-8 encoding for console output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " SMART SPACE - CÀI ĐẶT APK RELEASE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Kiem tra adb
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    # Thu tim trong thu muc Android SDK mac dinh tren Windows
    $fallbackAdb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $fallbackAdb) {
        $env:PATH += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
    } else {
        Write-Host "[LỖI] Không tìm thấy lệnh 'adb'. Vui lòng cài đặt Android Platform-Tools hoặc thêm vào biến môi trường PATH." -ForegroundColor Red
        exit 1
    }
}

# 2. Lay danh sach thiet bi dang ket noi
Write-Host "`nĐang quét các thiết bị kết nối qua adb..." -ForegroundColor Gray
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
        $state = $parts[1]
        $model = $serial
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
    Write-Host "Vui lòng kết nối thiết bị qua USB/Wifi và bật chế độ 'Gỡ lỗi USB' (USB Debugging)." -ForegroundColor Yellow
    exit 0
}

# 3. Hien thi danh sach va hoi nguoi dung muon cai dat cho thiet bi nao
Write-Host "`nMuốn tải 3 app release (admin, client và staff) cho thiết bị nào:" -ForegroundColor Green
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
    Write-Host "`n[CẢNH BÁO] Thiết bị $($targetDevice.Serial) đang ở trạng thái '$($targetDevice.State)'." -ForegroundColor Yellow
    if ($targetDevice.State -eq "unauthorized") {
        Write-Host "Vui lòng mở khóa điện thoại và nhấn 'Cho phép gỡ lỗi USB' (Allow USB Debugging)." -ForegroundColor Yellow
    }
}

Write-Host "`nĐã chọn thiết bị: $($targetDevice.Model) ($($targetDevice.Serial))" -ForegroundColor Cyan

# 4. Kiem tra su ton tai cua 3 file APK release
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

Write-Host "`nKiểm tra các file APK release..." -ForegroundColor Gray
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

# Xu ly tinh huong so luong file tim thay
if ($foundApps.Count -eq 0) {
    Write-Host "`n[LỖI] Không tìm thấy bất kỳ file APK release nào!" -ForegroundColor Red
    Write-Host "Vui lòng thực hiện build release trước bằng lệnh: npm run build-all:release" -ForegroundColor Yellow
    exit 1
} elseif ($foundApps.Count -lt 3) {
    Write-Host ""
    $confirm = Read-Host "hiện phát hiện $($foundApps.Count) file apk, có tiến hành cài đặt hay không? (y/n)"
    if ($confirm.Trim() -notmatch '^(y|yes)$') {
        Write-Host "Đã hủy tiến trình cài đặt." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "`nĐã tìm thấy đầy đủ 3/3 file APK release." -ForegroundColor Green
}

# 5. Tien hanh cai dat cac app vao thiet bi da chon
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "TIẾN HÀNH CÀI ĐẶT VÀO $($targetDevice.Model) ($($targetDevice.Serial))..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$successCount = 0
foreach ($app in $foundApps) {
    Write-Host "`n[+] Đang cài đặt app $($app.Name)..." -ForegroundColor Yellow
    Write-Host "    File: $($app.Path)" -ForegroundColor Gray

    # Cai dat qua adb install -r de ghi de neu app da ton tai
    $result = adb -s $targetDevice.Serial install -r "$($app.Path)" 2>&1

    if ($result -match "Success") {
        Write-Host "    -> Cài đặt $($app.Name) THÀNH CÔNG!" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "    -> Cài đặt $($app.Name) THẤT BẠI!" -ForegroundColor Red
        Write-Host "    Chi tiết lỗi: $result" -ForegroundColor DarkRed
    }
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ: Cài đặt thành công $successCount/$($foundApps.Count) ứng dụng." -ForegroundColor $(if ($successCount -eq $foundApps.Count) { "Green" } else { "Yellow" })
Write-Host "==========================================" -ForegroundColor Cyan

