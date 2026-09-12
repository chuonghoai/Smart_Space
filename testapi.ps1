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

# Thiet lap moi truong UTF-8 cho JVM va Console
$env:JAVA_TOOL_OPTIONS = "-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8"

# Thuc thi lenh maven test
$mvnArgs = @(
    "test",
    "-Dtest=$testClass",
    "-Dfile.encoding=UTF-8",
    "-DargLine=-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8",
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
