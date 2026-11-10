# ==============================================================================
# SMART SPACE - TỰ ĐỘNG BUILD APK RELEASE CHO CẢ 3 APP
# (Tối ưu hóa RAM: Chạy tuần tự, tự động giám sát và retry tối đa 1 lần)
# ==============================================================================

param(
    [Parameter(Position = 0)]
    [string]$TargetApp = "all",

    [Parameter(Position = 1)]
    [string]$ExtraArgs = ""
)

# Bật bảng mã UTF-8 cho console để hiển thị đúng dấu tiếng Việt
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

$rootPath = $PSScriptRoot

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "              SMART SPACE - QUY TRÌNH BUILD APK RELEASE                         " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  * Chế độ: Chạy tuần tự từng ứng dụng nhằm tiết kiệm RAM" -ForegroundColor Gray
Write-Host "  * Cơ chế: Tự động giám sát tiến trình và Retry tối đa 1 lần nếu build lỗi" -ForegroundColor Gray
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Kiểm tra Flutter SDK
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[LỖI NGHIÊM TRỌNG] Không tìm thấy lệnh 'flutter' trong biến môi trường PATH!" -ForegroundColor Red
    Write-Host "Vui lòng cài đặt Flutter SDK hoặc cấu hình biến môi trường trước khi chạy." -ForegroundColor Yellow
    exit 1
}

# 2. Định nghĩa danh sách 3 ứng dụng
$allApps = @(
    @{
        Key       = "client"
        Name      = "Client"
        Folder    = "smartspace_client"
        ApkPaths  = @(
            "$rootPath\smartspace_client\build\app\outputs\flutter-apk\app-release.apk",
            "$rootPath\smartspace_client\build\app\outputs\apk\release\app-release.apk"
        )
    },
    @{
        Key       = "admin"
        Name      = "Admin"
        Folder    = "smartspace_admin"
        ApkPaths  = @(
            "$rootPath\smartspace_admin\build\app\outputs\flutter-apk\app-release.apk",
            "$rootPath\smartspace_admin\build\app\outputs\apk\release\app-release.apk"
        )
    },
    @{
        Key       = "staff"
        Name      = "Staff"
        Folder    = "smartspace_staff"
        ApkPaths  = @(
            "$rootPath\smartspace_staff\build\app\outputs\flutter-apk\app-release.apk",
            "$rootPath\smartspace_staff\build\app\outputs\apk\release\app-release.apk"
        )
    }
)

# Lọc ứng dụng cần build nếu có tham số chỉ định
$selectedApps = @()
if ($TargetApp -eq "all" -or [string]::IsNullOrWhiteSpace($TargetApp)) {
    $selectedApps = $allApps
} else {
    $selectedApps = $allApps | Where-Object { $_.Key -eq $TargetApp.ToLower() -or $_.Name.ToLower() -eq $TargetApp.ToLower() }
    if ($selectedApps.Count -eq 0) {
        Write-Host "[LỖI] Không tìm thấy ứng dụng '$TargetApp'. Các giá trị hợp lệ: client, admin, staff, all." -ForegroundColor Red
        exit 1
    }
}

# Hàm trợ giúp tìm file APK đã build
function Get-BuiltApkPath([string[]]$paths) {
    foreach ($p in $paths) {
        if (Test-Path $p) {
            return $p
        }
    }
    return $null
}

# Hàm chuyển đổi thời gian sang dạng đọc được
function Format-Duration([TimeSpan]$span) {
    if ($span.TotalMinutes -ge 1) {
        return "$([math]::Floor($span.TotalMinutes))m $($span.Seconds)s"
    } else {
        return "$($span.Seconds)s"
    }
}

# Hàm lấy dung lượng file
function Format-FileSize([string]$filePath) {
    if (-not (Test-Path $filePath)) { return "" }
    $bytes = (Get-Item $filePath).Length
    $mb = [math]::Round($bytes / 1MB, 2)
    return "$mb MB"
}

# 3. Tiến hành build tuần tự từng ứng dụng
$totalWatch = [System.Diagnostics.Stopwatch]::StartNew()
$results = @()
$totalCount = $selectedApps.Count
$currentIndex = 0

foreach ($app in $selectedApps) {
    $currentIndex++
    $appPath = Join-Path $rootPath $app.Folder
    
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[$currentIndex/$totalCount] BẮT ĐẦU TIẾN TRÌNH BUILD: $($app.Name) ($($app.Folder))" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

    if (-not (Test-Path $appPath)) {
        Write-Host "[LỖI] Không tìm thấy thư mục '$($app.Folder)' tại $appPath" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Name      = $app.Name
            Folder    = $app.Folder
            Success   = $false
            Attempts  = 0
            Duration  = "0s"
            ApkPath   = "-"
            FileSize  = "-"
            Note      = "Thư mục không tồn tại"
        }
        continue
    }

    # Xóa file APK cũ nếu có để tránh nhận nhầm file cũ
    foreach ($p in $app.ApkPaths) {
        if (Test-Path $p) {
            Remove-Item $p -Force -ErrorAction SilentlyContinue
        }
    }

    $appWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $attempts = 0
    $isSuccess = $false
    $maxAttempts = 2 # 1 lần đầu + tối đa 1 lần retry

    while ($attempts -lt $maxAttempts -and -not $isSuccess) {
        $attempts++

        if ($attempts -gt 1) {
            Write-Host ""
            Write-Host "[RETRY 1/1] ĐANG THỬ LẠI TIẾN TRÌNH BUILD CHO $($app.Name)..." -ForegroundColor Yellow
            Write-Host "[INFO] Đang dọn dẹp bộ nhớ Gradle daemon trước khi thử lại..." -ForegroundColor Gray
            
            $gradlew = Join-Path $appPath "android\gradlew.bat"
            if (Test-Path $gradlew) {
                try {
                    Push-Location (Join-Path $appPath "android")
                    & .\gradlew.bat --stop 2>&1 | Out-Null
                    Pop-Location
                } catch {
                    # Bỏ qua nếu có lỗi
                }
            }
            Start-Sleep -Seconds 3
        } else {
            Write-Host "[RUN] Thực thi lệnh: flutter build apk $ExtraArgs" -ForegroundColor Gray
        }

        # Đổi thư mục làm việc sang app cần build
        Push-Location $appPath

        try {
            if ([string]::IsNullOrWhiteSpace($ExtraArgs)) {
                & flutter build apk
            } else {
                Invoke-Expression "flutter build apk $ExtraArgs"
            }
            $buildExitCode = $LASTEXITCODE
        } catch {
            Write-Host "[LỖI NGOẠI LỆ] $($_.Exception.Message)" -ForegroundColor Red
            $buildExitCode = 1
        } finally {
            Pop-Location
        }

        # Kiểm tra sự tồn tại của file APK sau khi build
        $apkFile = Get-BuiltApkPath $app.ApkPaths

        if ($buildExitCode -eq 0 -and $null -ne $apkFile) {
            $isSuccess = $true
            Write-Host ""
            Write-Host "[THÀNH CÔNG] Build $($app.Name) hoàn tất ở lần thử thứ $attempts!" -ForegroundColor Green
            Write-Host "             Đường dẫn file: $apkFile" -ForegroundColor Gray
            Write-Host "             Dung lượng: $(Format-FileSize $apkFile)" -ForegroundColor Gray
        } else {
            Write-Host ""
            Write-Host "[THẤT BẠI] Lần build thứ $attempts của $($app.Name) không thành công (Exit Code: $buildExitCode)!" -ForegroundColor Red
        }
    }

    $appWatch.Stop()

    $finalApk = Get-BuiltApkPath $app.ApkPaths
    $results += [PSCustomObject]@{
        Name      = $app.Name
        Folder    = $app.Folder
        Success   = $isSuccess
        Attempts  = $attempts
        Duration  = Format-Duration $appWatch.Elapsed
        ApkPath   = if ($isSuccess -and $null -ne $finalApk) { $finalApk } else { "-" }
        FileSize  = if ($isSuccess -and $null -ne $finalApk) { Format-FileSize $finalApk } else { "-" }
        Note      = if ($isSuccess) { if ($attempts -eq 1) { "Thành công lần 1" } else { "Thành công sau Retry" } } else { "Thất bại sau 2 lần" }
    }

    Write-Host ""
}

$totalWatch.Stop()

# 4. Hiển thị bảng tổng kết chi tiết
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    TỔNG KẾT TIẾN TRÌNH BUILD APK RELEASE                       " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "================================================================================" -ForegroundColor Cyan
$header = "{0,-12} | {1,-14} | {2,-10} | {3,-10} | {4,-10} | {5}" -f "Ứng dụng", "Trạng thái", "Lần thử", "Thời gian", "Dung lượng", "Ghi chú"
Write-Host $header -ForegroundColor White
$divider = "{0,-12}-|-{1,-14}-|-{2,-10}-|-{3,-10}-|-{4,-10}-|-{5}" -f ("-" * 12), ("-" * 14), ("-" * 10), ("-" * 10), ("-" * 10), ("-" * 20)
Write-Host $divider -ForegroundColor DarkGray

$successCount = 0
$failCount = 0

foreach ($res in $results) {
    $statusText = if ($res.Success) { "THÀNH CÔNG" } else { "THẤT BẠI" }
    $statusColor = if ($res.Success) { "Green" } else { "Red" }
    
    if ($res.Success) {
        $successCount++
    } else {
        $failCount++
    }

    Write-Host ("{0,-12} | " -f $res.Name) -NoNewline
    Write-Host ("{0,-14}" -f $statusText) -ForegroundColor $statusColor -NoNewline
    Write-Host (" | {0,-10} | {1,-10} | {2,-10} | {3}" -f "$($res.Attempts) lần", $res.Duration, $res.FileSize, $res.Note)
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Tổng thời gian toàn bộ tiến trình: $(Format-Duration $totalWatch.Elapsed)" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "[OK] TẤT CẢ $successCount ỨNG DỤNG ĐÃ ĐƯỢC BUILD THÀNH CÔNG!" -ForegroundColor Green
    Write-Host "Bạn có thể tiến hành cài đặt APK bằng lệnh: npm run install:release" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
} else {
    Write-Host "[!] CẢNH BÁO: Có $failCount/$totalCount ứng dụng build THẤT BẠI!" -ForegroundColor Red
    Write-Host "Vui lòng kiểm tra lại log chi tiết ở trên để xử lý lỗi." -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
