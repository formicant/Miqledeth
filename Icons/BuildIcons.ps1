# Builds a resource dll with icons rasterized from Icons.svg

# Tools required:
#   Inkscape                     (http://inkscape.org)
#   convert   from ImageMagick   (http://imagemagick.org)
#   rc, link  from VisualStudio  (http://visualstudio.com)
# Font required:
#   Cousine   (https://fonts.google.com/specimen/Cousine)


# Write actual paths here:
Set-Alias -name Inkscape `
  -value "C:\Program Files\Inkscape\inkscape.com"
Set-Alias -name ImageMagickConvert `
  -value "C:\Program Files\ImageMagick\convert.exe"
Set-Alias -name ResourceCompiler `
  -value "C:\Program Files (x86)\Windows Kits\8.1\bin\x64\rc.exe"
Set-Alias -name Linker `
  -value "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.12.25827\bin\Hostx64\x64\link.exe"

$rowCount = 2         # number of icon rows in the svg
$columnCount = 5      # number of icon columns in the svg
$sizes = 16, 24, 32   # icon bitmap sizes
$colorOptions = "-alpha", "Remove", "+dither", "-colors", "16"
  # (remove transparency and convrert to 16 colors without dithering)


# Creating a temporary directory
New-Item "BuildIcons" -type directory

foreach($row in 0..($rowCount - 1)) {
  foreach($column in 0..($columnCount - 1)) {
    $index = 1 + $columnCount * $row + $column
    
    # Making png files
    foreach($size in $sizes) {
      Inkscape "Icons.svg" `
        --export-png="BuildIcons\${index}-${size}.png" `
        --export-area=$(20 * $column):$(20 * $row):$(20 * $column + 16):$(20 * $row + 16) `
        --export-dpi=$(6 * $size)
    }
    
    # Making ico files
    $pngFiles = $sizes | % { "BuildIcons\${index}-${_}.png" }
    ImageMagickConvert $pngFiles -verbose $colorOptions "BuildIcons\${index}.ico"
  }
}

$indices = 1..($rowCount * $columnCount)

# Making rc file
$indices | foreach { "$(100 + $_) ICON ${_}.ico" } | Out-File "BuildIcons\Icons.rc"

# Making res file
ResourceCompiler /r "BuildIcons\Icons.rc"

# Making dll file
Linker /dll /noentry /machine:x86 /out:"Icons.dll" "BuildIcons\Icons.res"

# Deleting the temporary directory
Remove-Item "BuildIcons" -recurse
