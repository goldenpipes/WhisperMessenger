param([string]$Out, [int]$Size = 256, [ValidateSet("both", "back", "front")][string]$Part = "both")
# Two speech bubbles: gray back bubble (top left), white front bubble (bottom
# right) with three see-through dots, a transparent gap between them. Drawn at
# 4x and scaled down for clean edges. White so the game can tint it.
Add-Type -AssemblyName System.Drawing

$S = 1024
$big = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($big)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

function Bubble([float]$x, [float]$y, [float]$w, [float]$h, [float]$r, $tail) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath ([System.Drawing.Drawing2D.FillMode]::Winding)
  $d = 2 * $r
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  $p.AddPolygon([System.Drawing.PointF[]]$tail)
  return $p
}
function Pt([float]$x, [float]$y) { New-Object System.Drawing.PointF $x, $y }

$back = Bubble 120 170 540 390 110 @((Pt 200 500), (Pt 340 540), (Pt 170 690))
$front = Bubble 370 400 534 380 110 @((Pt 730 760), (Pt 870 700), (Pt 870 900))

# The back bubble is white in its own part, so the game tints it exactly.
$grayValue = 150
if ($Part -eq "back") { $grayValue = 255 }
$gray = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, $grayValue, $grayValue, $grayValue))
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$clear = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Transparent)

# Back bubble, then clear a gap around the front bubble, then the front bubble.
if ($Part -ne "front") {
  $g.FillPath($gray, $back)
  $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
  $gap = New-Object System.Drawing.Pen ([System.Drawing.Color]::Transparent), 60
  $gap.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $g.DrawPath($gap, $front)
  $g.FillPath($clear, $front)
  $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
}
if ($Part -ne "back") {
  $g.FillPath($white, $front)
}

# Dots punched out of the front bubble.
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$cy = 590; $r = 40
foreach ($cx in 517, 637, 757) { $g.FillEllipse($clear, $cx - $r, $cy - $r, 2 * $r, 2 * $r) }
$g.Dispose()

$small = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.DrawImage($big, 0, 0, $Size, $Size)
$gs.Dispose()
$small.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose(); $big.Dispose()
"wrote $Out"
