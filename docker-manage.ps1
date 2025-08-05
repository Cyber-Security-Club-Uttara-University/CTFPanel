# CTFd Docker Management Script
# Usage: .\docker-manage.ps1 [start|stop|restart|logs|backup|reset]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "logs", "backup", "reset", "status")]
    [string]$Action
)

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

function Test-DockerRunning {
    try {
        $null = docker version 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Start-CTFd {
    Write-Host "Starting CTFd..." -ForegroundColor Green
    
    # Check if Docker is running
    if (-not (Test-DockerRunning)) {
        Write-Host "Docker Desktop is not running!" -ForegroundColor Red
        Write-Host "Please start Docker Desktop and wait for it to fully load, then try again." -ForegroundColor Yellow
        Write-Host "You can start Docker Desktop from the Windows Start menu." -ForegroundColor Cyan
        return
    }
    
    # Check if .env exists
    if (-not (Test-Path ".env")) {
        Write-Host "Creating .env file from template..." -ForegroundColor Yellow
        Copy-Item ".env.example" ".env"
        Write-Host "Please edit .env file and change the default passwords before proceeding!" -ForegroundColor Red
        Write-Host "Press any key to continue once you've updated the passwords..."
        Read-Host
    }
    
    # Create data directories
    $DataDirs = @(".data", ".data/mysql", ".data/redis", ".data/CTFd", ".data/CTFd/logs", ".data/CTFd/uploads")
    foreach ($dir in $DataDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "CTFd started successfully!" -ForegroundColor Green
        Write-Host "Access CTFd at: http://localhost" -ForegroundColor Cyan
        Write-Host "Direct CTFd access: http://localhost:8000" -ForegroundColor Cyan
    } else {
        Write-Host "Failed to start CTFd. Check logs with: .\docker-manage.ps1 logs" -ForegroundColor Red
    }
}

function Stop-CTFd {
    Write-Host "Stopping CTFd..." -ForegroundColor Yellow
    docker-compose down
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "CTFd stopped successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to stop CTFd." -ForegroundColor Red
    }
}

function Restart-CTFd {
    Write-Host "Restarting CTFd..." -ForegroundColor Yellow
    Stop-CTFd
    Start-Sleep -Seconds 3
    Start-CTFd
}

function Show-Logs {
    Write-Host "Showing CTFd logs (Press Ctrl+C to exit)..." -ForegroundColor Cyan
    docker-compose logs -f
}

function Backup-CTFd {
    $BackupDir = "backups"
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    
    Write-Host "Creating backup..." -ForegroundColor Yellow
    
    # Create backup directory
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }
    
    # Backup database
    Write-Host "Backing up database..." -ForegroundColor Green
    docker-compose exec -T db mysqldump -u ctfd -pctfd ctfd > "$BackupDir/ctfd_db_$Timestamp.sql"
    
    # Backup data directory
    Write-Host "Backing up data directory..." -ForegroundColor Green
    Compress-Archive -Path ".data" -DestinationPath "$BackupDir/ctfd_data_$Timestamp.zip" -Force
    
    Write-Host "Backup completed!" -ForegroundColor Green
    Write-Host "Database backup: $BackupDir/ctfd_db_$Timestamp.sql" -ForegroundColor Cyan
    Write-Host "Data backup: $BackupDir/ctfd_data_$Timestamp.zip" -ForegroundColor Cyan
}

function Reset-CTFd {
    Write-Host "WARNING: This will delete ALL CTFd data!" -ForegroundColor Red
    $Confirm = Read-Host "Type 'DELETE' to confirm"
    
    if ($Confirm -eq "DELETE") {
        Write-Host "Stopping containers..." -ForegroundColor Yellow
        docker-compose down -v
        
        Write-Host "Removing data directory..." -ForegroundColor Yellow
        if (Test-Path ".data") {
            Remove-Item -Recurse -Force ".data"
        }
        
        Write-Host "CTFd reset completed. Run 'start' to begin fresh setup." -ForegroundColor Green
    } else {
        Write-Host "Reset cancelled." -ForegroundColor Yellow
    }
}

function Show-Status {
    Write-Host "CTFd Container Status:" -ForegroundColor Cyan
    docker-compose ps
    
    Write-Host "`nData Directory Status:" -ForegroundColor Cyan
    if (Test-Path ".data") {
        $DataSize = (Get-ChildItem -Recurse ".data" | Measure-Object -Property Length -Sum).Sum
        Write-Host "Data directory size: $([math]::Round($DataSize / 1MB, 2)) MB"
        
        Write-Host "`nData subdirectories:"
        Get-ChildItem ".data" -Directory | ForEach-Object {
            $Size = (Get-ChildItem -Recurse $_.FullName | Measure-Object -Property Length -Sum).Sum
            Write-Host "  $($_.Name): $([math]::Round($Size / 1MB, 2)) MB"
        }
    } else {
        Write-Host "No data directory found."
    }
}

# Main execution
switch ($Action) {
    "start" { Start-CTFd }
    "stop" { Stop-CTFd }
    "restart" { Restart-CTFd }
    "logs" { Show-Logs }
    "backup" { Backup-CTFd }
    "reset" { Reset-CTFd }
    "status" { Show-Status }
}

Write-Host "`nAvailable commands:"
Write-Host "  start   - Start CTFd"
Write-Host "  stop    - Stop CTFd"
Write-Host "  restart - Restart CTFd"
Write-Host "  logs    - View logs"
Write-Host "  backup  - Create backup"
Write-Host "  status  - Show status"
Write-Host "  reset   - Reset all data (WARNING: Destructive!)"
