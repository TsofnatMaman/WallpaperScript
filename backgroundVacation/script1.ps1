Add-Type -AssemblyName System.Drawing

# נתיב הסקריפט המקומי (הקובץ שרץ כרגע)
$localScriptPath = $PSCommandPath

# כתובת הסקריפט המקורית מה-GitHub
$remoteScriptUrl = "https://raw.githubusercontent.com/TsofnatMaman/WallpaperScript/main/backgroundVacation/script1.ps1"

# הורד לגרסה זמנית
$tempScriptPath = "$env:TEMP\script1_temp.ps1"

try {
    Invoke-WebRequest -Uri $remoteScriptUrl -OutFile $tempScriptPath -UseBasicParsing

    # השוואת Hash כדי לבדוק אם יש הבדל
    $currentHash = Get-FileHash $localScriptPath
    $newHash = Get-FileHash $tempScriptPath

    if ($currentHash.Hash -ne $newHash.Hash) {
        #Copy-Item $tempScriptPath -Destination $localScriptPath -Force
        Write-Host "Script updated from GitHub. Relaunching..." -ForegroundColor Yellow

        # הפעלת הגרסה המעודכנת ויציאה
        #Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$localScriptPath`""
        exit
    } else {
        Remove-Item $tempScriptPath -Force
    }
}
catch {
    Write-Host "Failed to download updated script." -ForegroundColor Red
}

$startDay = Get-Date "2025-5-15"
$today = Get-Date
$currentDay = ($today - $startDay).Days

if ($currentDay -ge 49) {
    exit
}

$baseImagePath = "$env:APPDATA\Microsoft\Windows\v.jpg"
$tempImagePath = "$env:TEMP\wallpaper_temp.jpg"

$text = "עוד $(49 - $currentDay) ימים..."

# אם קובץ התמונה לא קיים, הורד אותו
if (-not (Test-Path $baseImagePath)) {
    write-host "image not found, try download"
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TsofnatMaman/WallpaperScript/main/backgroundVacation/v.JPG" -OutFile $baseImagePath
        write-host "download success"
    }
    catch {
        write-host "error in web request"
        exit
    }
}

$image = [System.Drawing.Image]::FromFile($baseImagePath)
$graphics = [System.Drawing.Graphics]::FromImage($image)

# הגדרת גופן גדול ומעובה
$fontFamily = New-Object System.Drawing.FontFamily("David")
$fontSize = 72
$font = New-Object System.Drawing.Font($fontFamily, $fontSize, [System.Drawing.FontStyle]::Bold)

# צבעים - טקסט לבן והצללה שחורה שקופה
$brushText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$brushShadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 0, 0, 0)) # שחור חצי שקוף

# פורמט טקסט - ימין לשמאל ומרכזי
$stringFormat = New-Object System.Drawing.StringFormat
$stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
$stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
$stringFormat.FormatFlags = [System.Drawing.StringFormatFlags]::DirectionRightToLeft

# חשב גודל הטקסט כדי למקם במדויק במרכז
$textSize = $graphics.MeasureString($text, $font)
$centerX = $image.Width / 2
$centerY = $image.Height / 2

# ריבוע רקע שקוף כהה מתחת לטקסט להבלטה נוספת
$padding = 30
$rectX = $centerX - $textSize.Width / 2 - $padding
$rectY = $centerY - $textSize.Height / 2 - $padding
$rectWidth = $textSize.Width + $padding * 2
$rectHeight = $textSize.Height + $padding * 2
$backgroundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
$graphics.FillRectangle($backgroundBrush, $rectX, $rectY, $rectWidth, $rectHeight)

# ציור הצללה - מעט שמאלה ומטה מהטקסט הלבן
$shadowOffsetX = 4
$shadowOffsetY = 4
$shadowPoint = New-Object System.Drawing.PointF($centerX + $shadowOffsetX, $centerY + $shadowOffsetY)
$graphics.DrawString($text, $font, $brushShadow, $shadowPoint, $stringFormat)

# ציור הטקסט הלבן במרכז
$point = New-Object System.Drawing.PointF($centerX, $centerY)
$graphics.DrawString($text, $font, $brushText, $point, $stringFormat)

$graphics.Dispose()

$image.Save($tempImagePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$image.Dispose()

if (-not ("Wallpaper" -as [type])) {
    Add-Type -TypeDefinition @"
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@
}

[Wallpaper]::SystemParametersInfo(20, 0, $tempImagePath, 3)

Write-Host "background setting success: $text"

# Register a daily scheduled task if it doesn't already exist
$taskName = "ChangeWallpaperEveryDay"
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Minimized -File `"$PSCommandPath`""
    $taskTrigger = New-ScheduledTaskTrigger -Daily -At 00:30
    $taskSetting = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew

    Register-ScheduledTask -Action $taskAction -Setting $taskSetting -Trigger $taskTrigger -TaskName $taskName -Description "Change wallpaper daily"
    Write-Host "Scheduled task created."
} else {
    Write-Host "Scheduled task already exists."
}

Write-Host "Wallpaper changed successfully to: $wallpaperUrl"
