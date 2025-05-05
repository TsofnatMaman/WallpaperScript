# Path to the file that stores the current day (0 to 39)
$dayFilePath = "$env:LOCALAPPDATA\WallpaperDay.txt"

# If the file doesn't exist, create it starting at 0
if (-not (Test-Path $dayFilePath)) {
    Set-Content $dayFilePath "0"
}

# Read the current day number from the file
$currentDay = [int](Get-Content $dayFilePath)

# Define the wallpaper URL based on the current day (Slide1.JPG to Slide40.JPG)
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

# Update the day index (loop from 0 to 39)
$nextDay = ($currentDay + 1) % 40
Set-Content $dayFilePath $nextDay

# Register a daily scheduled task if it doesn't already exist
$taskName = "ChangeWallpaperEveryDay"
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSCommandPath`""
    $taskTrigger = New-ScheduledTaskTrigger -Daily -At 00:00
    Register-ScheduledTask -Action $taskAction -Trigger $taskTrigger -TaskName $taskName -Description "Change wallpaper daily"
    Write-Host "Scheduled task created."
} else {
    Write-Host "Scheduled task already exists."
}

Write-Host "Wallpaper changed successfully to: $wallpaperUrl"
