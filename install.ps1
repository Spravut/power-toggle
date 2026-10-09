# Один раз: рисует две иконки и кладёт ярлык "Режим питания" на рабочий стол.

Add-Type -AssemblyName System.Drawing

function New-Icon($path, $bg, $text) {
    $size = 256
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $bg), 8, 8, $size - 16, $size - 16)
    $font = New-Object System.Drawing.Font 'Segoe UI', 96, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $g.DrawString($text, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, 0, $size, $size), $fmt)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $png = $ms.ToArray()

    # ICO с одним PNG-кадром 256x256
    $fs = [System.IO.File]::Create($path)
    $w = New-Object System.IO.BinaryWriter $fs
    $w.Write([UInt16]0); $w.Write([UInt16]1); $w.Write([UInt16]1)
    $w.Write([byte]0); $w.Write([byte]0); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([UInt16]1); $w.Write([UInt16]32)
    $w.Write([UInt32]$png.Length); $w.Write([UInt32]22)
    $w.Write($png)
    $w.Close()
}

New-Icon (Join-Path $PSScriptRoot 'normal.ico') ([System.Drawing.Color]::FromArgb(70, 90, 140))  'Zz'
New-Icon (Join-Path $PSScriptRoot 'coding.ico') ([System.Drawing.Color]::FromArgb(30, 160, 90))  '</>'

$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Режим питания.lnk'
$sc = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$sc.TargetPath = 'wscript.exe'
$sc.Arguments = '"' + (Join-Path $PSScriptRoot 'toggle.vbs') + '"'
$sc.WorkingDirectory = $PSScriptRoot

$out = powercfg /q SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | Out-String
$m = [regex]::Matches($out, '0x[0-9a-fA-F]{8}')
$mode = if ($m[$m.Count - 2].Value -eq '0x00000000') { 'coding' } else { 'normal' }
$sc.IconLocation = (Join-Path $PSScriptRoot "$mode.ico") + ',0'
$sc.Save()

"Готово: $lnk"
