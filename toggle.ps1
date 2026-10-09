# Переключает схему питания между "Обычный" и "Кодинг".
# Обычный: экран 5 мин, сон 5 мин, крышка -> сон.
# Кодинг:  экран никогда, сон никогда, крышка -> ничего.

$ErrorActionPreference = 'Stop'

$SUB_BUTTONS = '4f971e89-eebd-4455-a8de-9e59040e7347'
$LIDACTION   = '5ca83367-6e45-459f-a27b-476b1d01c936'

function Get-AcValue($sub, $setting) {
    $out = powercfg /qh SCHEME_CURRENT $sub $setting | Out-String
    $m = [regex]::Matches($out, '0x[0-9a-fA-F]{8}')
    $hex = $m[$m.Count - 2].Value  # предпоследнее — текущее "от сети"
    [Convert]::ToInt32($hex, 16)
}

function Set-Both($sub, $setting, $value) {
    powercfg /setacvalueindex SCHEME_CURRENT $sub $setting $value
    powercfg /setdcvalueindex SCHEME_CURRENT $sub $setting $value
}

$isCoding = (Get-AcValue SUB_VIDEO VIDEOIDLE) -eq 0 -and (Get-AcValue $SUB_BUTTONS $LIDACTION) -eq 0

if ($isCoding) {
    $minutes = 300; $lid = 1; $mode = 'normal'
    $msg = 'Обычный режим: экран и сон через 5 мин, крышка - сон.'
} else {
    $minutes = 0;   $lid = 0; $mode = 'coding'
    $msg = 'Режим кодинга: не спит, крышка - ничего.'
}

Set-Both SUB_VIDEO VIDEOIDLE   $minutes
Set-Both SUB_SLEEP STANDBYIDLE $minutes
Set-Both $SUB_BUTTONS $LIDACTION $lid
powercfg /setactive SCHEME_CURRENT

# Меняем иконку ярлыка на рабочем столе под текущий режим
$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Режим питания.lnk'
if (Test-Path $lnk) {
    $sc = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
    $sc.IconLocation = (Join-Path $PSScriptRoot "$mode.ico") + ',0'
    $sc.Save()
}

(New-Object -ComObject WScript.Shell).Popup($msg, 2, 'Режим питания', 64) | Out-Null
