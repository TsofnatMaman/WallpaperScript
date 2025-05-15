$startDay = Get-Date "2025-5-15"
$today = Get-Date
$currentDay = ($today - $startDay).Days

# Define the wallpaper URL based on the current day
$baseUrl = "https://raw.githubusercontent.com/TsofnatMaman/WallpaperScript/main/Images/Slide"
$wallpaperUrl = "${baseUrl}$($currentDay + 1).JPG"

# Download the image to a temporary path
$tempImagePath = "$env:TEMP\wallpaper.jpg"
try {
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $tempImagePath -UseBasicParsing
} catch {
    Write-Host "Unable to download the image: $wallpaperUrl"
    exit
}

# Load the Wallpaper class only if it's not already loaded
if (-not ("Wallpaper" -as [type])) {
    Add-Type -TypeDefinition @"
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@
}

# Set the desktop wallpaper
[Wallpaper]::SystemParametersInfo(20, 0, $tempImagePath, 3)

# Remove the temporary image file
Remove-Item $tempImagePath -ErrorAction SilentlyContinue

# Register a daily scheduled task if it doesn't already exist
$taskName = "ChangeWallpaperEveryDay"
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -WindowStyle hidden -Argument "-File `"$PSCommandPath`""
    $taskTrigger = New-ScheduledTaskTrigger -Daily -At 00:10
    $taskSetting = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -Action $taskAction -Setting $taskSetting -Trigger $taskTrigger -TaskName $taskName -Description "Change wallpaper daily"
    Write-Host "Scheduled task created."
} else {
    Write-Host "Scheduled task already exists."
}

Write-Host "Wallpaper changed successfully to: $wallpaperUrl"
