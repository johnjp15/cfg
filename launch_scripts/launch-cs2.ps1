# CS2 Resolution Switcher
# This script changes resolution before launching CS2, then restores it after the game exits
#
# Usage:
#   .\Launch-CS2.ps1 -GameWidth 1024 -GameHeight 768 -DesktopWidth 2560 -DesktopHeight 1440
#   .\Launch-CS2.ps1 -GameWidth 1920 -GameHeight 1080 -DesktopWidth 3840 -DesktopHeight 2160
#   .\Launch-CS2.ps1  (uses default values)

param(
    [int]$GameWidth = 1024,
    [int]$GameHeight = 768,
    [int]$DesktopWidth = 2560,
    [int]$DesktopHeight = 1440
)

# Store resolution values
$originalWidth = $DesktopWidth
$originalHeight = $DesktopHeight
$gameWidth = $GameWidth
$gameHeight = $GameHeight

# Path to CS2 executable - Update this to match your installation
$cs2Path = "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64\cs2.exe"

# Alternative: Launch via Steam URL (recommended)
$steamLaunch = $true  # Set to $false to use direct .exe path instead

# Function to change resolution
function Set-ScreenResolution {
    param(
        [int]$Width,
        [int]$Height
    )
    
    $code = @"
using System;
using System.Runtime.InteropServices;

public class Display
{
    [StructLayout(LayoutKind.Sequential)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    [DllImport("user32.dll")]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    public const int ENUM_CURRENT_SETTINGS = -1;
    public const int CDS_UPDATEREGISTRY = 0x01;
    public const int CDS_TEST = 0x02;
    public const int DISP_CHANGE_SUCCESSFUL = 0;
    public const int DISP_CHANGE_RESTART = 1;
    public const int DISP_CHANGE_FAILED = -1;
}
"@

    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue

    $devMode = New-Object Display+DEVMODE
    $devMode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devMode)
    
    [Display]::EnumDisplaySettings($null, -1, [ref]$devMode)
    
    $devMode.dmPelsWidth = $Width
    $devMode.dmPelsHeight = $Height
    $devMode.dmFields = 0x180000  # DM_PELSWIDTH | DM_PELSHEIGHT
    
    $result = [Display]::ChangeDisplaySettings([ref]$devMode, 0)
    
    return $result
}

Write-Host "=== CS2 Resolution Switcher ===" -ForegroundColor Cyan
Write-Host ""

# Change to game resolution
Write-Host "Changing resolution to ${gameWidth}x${gameHeight}..." -ForegroundColor Yellow
$result = Set-ScreenResolution -Width $gameWidth -Height $gameHeight

if ($result -eq 0) {
    Write-Host "Resolution changed successfully!" -ForegroundColor Green
    Start-Sleep -Seconds 2
    
    # Launch CS2
    Write-Host "Launching Counter-Strike 2..." -ForegroundColor Yellow
    
    if ($steamLaunch) {
        # Launch via Steam (recommended method)
        Start-Process "steam://rungameid/730"
        Start-Sleep -Seconds 5
        
        # Wait for CS2 process
        Write-Host "Waiting for CS2 to start..." -ForegroundColor Yellow
        $process = $null
        while ($null -eq $process) {
            $process = Get-Process -Name "cs2" -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    } else {
        # Direct launch via executable
        if (Test-Path $cs2Path) {
            $process = Start-Process -FilePath $cs2Path -PassThru
        } else {
            Write-Host "ERROR: CS2 executable not found at: $cs2Path" -ForegroundColor Red
            Write-Host "Please update the `$cs2Path variable in the script or set `$steamLaunch to `$true" -ForegroundColor Red
            Write-Host ""
            Write-Host "Restoring original resolution..." -ForegroundColor Yellow
            Set-ScreenResolution -Width $originalWidth -Height $originalHeight
            Read-Host "Press Enter to exit"
            exit
        }
    }
    
    Write-Host "CS2 is running. Waiting for the game to close..." -ForegroundColor Green
    
    # Wait for CS2 to exit
    Wait-Process -Name "cs2" -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "CS2 has exited. Restoring resolution to ${originalWidth}x${originalHeight}..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    
    # Restore original resolution
    $result = Set-ScreenResolution -Width $originalWidth -Height $originalHeight
    
    if ($result -eq 0) {
        Write-Host "Resolution restored successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to restore resolution. You may need to change it manually." -ForegroundColor Red
    }
} else {
    Write-Host "Failed to change resolution!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Script complete. Window will close in 3 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
