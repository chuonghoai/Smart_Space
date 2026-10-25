param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# -----------------------------------------------------------------------------
# 1. Danh sach dinh nghia cac lenh va file Test tuong ung
# -----------------------------------------------------------------------------
$TestRegistry = @{
    "CreateReport" = @{
        TestClass   = "com.vn.smart_space.controller.report.CreateReportTest"
        Description = "Mo phong 1 Client tao phan anh su co thuc te (100% giong app) & kich hoat realtime websocket/FCM"
    }
    "AssignReport" = @{
        TestClass   = "com.vn.smart_space.controller.report.AssignReportTest"
        Description = "Mo phong Client tao report, sau do Admin phan cong cho Staff de test realtime notification cho Client"
    }
    "ReportFeed" = @{
        TestClass   = "com.vn.smart_space.controller.report.ReportFeedTest"
        Description = "Client xem Bang tin: khong co phan anh bi tu choi, khong lo SDT/email, an danh khong lo ten"
    }
    "MapReports" = @{
        TestClass   = "com.vn.smart_space.controller.report.MapReportsTest"
        Description = "Ban do Client theo khung nhin: 401/400, chi tra report trong khung, loai rejected, limit + truncated"
    }
    "AdminUsers" = @{
        TestClass   = "com.vn.smart_space.controller.admin.AdminUserManagementTest"
        Description = "Admin quan ly nguoi dung: danh sach chi client, thong ke, trend zero-fill, chi tiet khong lo phan anh an danh"
    }
    "StaffDashboard" = @{
        TestClass   = "com.vn.smart_space.controller.staff.StaffDashboardTest"
        Description = "Dashboard nhan vien: KPI, trend assigned/resolved, quyen truy cap, khoa gia dinh processed la trang thai cuoi"
    "HandleReport" = @{
        TestClass   = "com.vn.smart_space.controller.report.HandleReportTest"
        Description = "Mo phong luong e2e: Client tao phan anh -> Admin phan cong cho Staff -> Staff hoan tat xu ly phan anh va gui thong bao cho Client"
    }
    "ReviewReportResolved" = @{
        TestClass   = "com.vn.smart_space.controller.report.ReviewReportResolvedTest"
        Description = "Mo phong Client danh gia phan anh la 'Da xu ly' (Resolved) kem danh gia 5 sao cho nhan vien"
    }
    "ReviewReportUnresolved" = @{
        TestClass   = "com.vn.smart_space.controller.report.ReviewReportUnresolvedTest"
        Description = "Mo phong Client danh gia phan anh la 'Chua duoc xu ly' (Unresolved) kem ly do, anh chup va thong bao cho Admin"
    }
    "ReviewReportRehandled" = @{
        TestClass   = "com.vn.smart_space.controller.report.ReviewReportRehandledTest"
        Description = "Mo phong quy trinh xu ly lai: Unresolved -> Admin Reopen -> Staff xu ly lai -> Client danh gia lai ghi de"
    }
    "NewsIntegration" = @{
        TestClass   = "com.vn.smart_space.controller.news.NewsIntegrationTest"
        Description = "Kiem tra toan bo luong CRUD tin tuc (News) va kiem tra phan quyen role ADMIN vs CLIENT"
    }
}

# -----------------------------------------------------------------------------
# 2. Ham hien thi tro giup (Help Menu)
# -----------------------------------------------------------------------------
function Show-Help {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                   SMARTSPACE BACKEND API TEST RUNNER                           " -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Cu phap su dung:" -ForegroundColor White
    Write-Host "    .\testapi.ps1 <CommandName> [Tuy chon Maven bo sung]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Danh sach cac lenh kha dung:" -ForegroundColor White
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

    foreach ($key in ($TestRegistry.Keys | Sort-Object)) {
        $item = $TestRegistry[$key]
        Write-Host "  $($key.PadRight(18))" -NoNewline -ForegroundColor Green
        Write-Host " -> " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($item.TestClass)" -ForegroundColor Cyan
        Write-Host "                     Mo ta: $($item.Description)" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Vi du:" -ForegroundColor White
    Write-Host "    .\testapi.ps1 help" -ForegroundColor DarkYellow
    Write-Host "    .\testapi.ps1 CreateReport" -ForegroundColor DarkYellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# -----------------------------------------------------------------------------
# 3. Kiem tra tham so va xu ly
# -----------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Command) -or $Command -in @("help", "-h", "--help", "/?", "-?")) {
    Show-Help
    exit 0
}

# Tim kiem lenh khop (khong phan biet hoa/thuong)
$matchedKey = $TestRegistry.Keys | Where-Object { $_ -like $Command } | Select-Object -First 1

if (-not $matchedKey) {
    Write-Host ""
    Write-Host "[LOI] Khong tim thay lenh '$Command' trong he thong test runner." -ForegroundColor Red
    Show-Help
    exit 1
}

$target = $TestRegistry[$matchedKey]
$testClass = $target.TestClass
$description = $target.Description

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ">> DANG CHAY TEST : " -NoNewline -ForegroundColor Yellow
Write-Host "$matchedKey" -ForegroundColor Green
Write-Host ">> Target Class   : $testClass" -ForegroundColor Cyan
Write-Host ">> Nghiep vu      : $description" -ForegroundColor Gray
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Duong dan thu muc backend va file pom.xml
$BackendDir = Join-Path $PSScriptRoot "SmartSpace_Backend"
$PomPath = Join-Path $BackendDir "pom.xml"
$MvnwCmd = Join-Path $BackendDir "mvnw.cmd"

# Xac dinh cong cu chay Maven (mvn hoac mvnw)
$MvnExecutable = "mvn"
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    if (Test-Path $MvnwCmd) {
        $MvnExecutable = $MvnwCmd
    } else {
        Write-Host "[LOI] Khong tim thay Maven ('mvn' hoac '$MvnwCmd') trong he thong!" -ForegroundColor Red
        exit 1
    }
}

# Thiet lap moi truong UTF-8 va Heap size cho JVM va Console
$env:JAVA_TOOL_OPTIONS = "-Xms64m -Xmx256m -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8"
$env:MAVEN_OPTS = "-Xms64m -Xmx256m"

# Thuc thi lenh maven test
$mvnArgs = @(
    "test",
    "-Dtest=$testClass",
    "-Dfile.encoding=UTF-8",
    "-DargLine=-Xmx256m -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8",
    "-f",
    "$PomPath"
)

if ($RemainingArgs) {
    $mvnArgs += $RemainingArgs
}

Write-Host ">> Thuc thi: $MvnExecutable $($mvnArgs -join ' ')" -ForegroundColor DarkCyan
Write-Host ""

& $MvnExecutable @mvnArgs

$exitCode = $LASTEXITCODE
Write-Host ""
if ($exitCode -eq 0) {
    Write-Host ">> [THANH CONG] Da hoan tat thuc thi test '$matchedKey'!" -ForegroundColor Green
} else {
    Write-Host ">> [THAT BAI] Test '$matchedKey' tra ve ma loi: $exitCode" -ForegroundColor Red
}
Write-Host "================================================================================" -ForegroundColor Cyan

exit $exitCode
