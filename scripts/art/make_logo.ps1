param([string]$Out, [int]$Size = 256, [switch]$NoRim)
# WhisperMessenger's logo (Media/icon.png) redrawn sharp: a steel rim, a thin
# gold ring, a dark navy disc lit from the middle, and the same two chat
# bubbles as chat_glyph_*.png (blue back bubble, white front bubble with
# see-through dots). Drawn at 1024 and scaled down.
Add-Type -AssemblyName System.Drawing

$S = 1024
$big = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($big)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
function C([int]$r, [int]$gg, [int]$b, [int]$a = 255) { [System.Drawing.Color]::FromArgb($a, $r, $gg, $b) }
function Circle([float]$r) { New-Object System.Drawing.RectangleF (512 - $r), (512 - $r), (2 * $r), (2 * $r) }
function LinearFill([float]$r, $top, $bottom) {
  $rect = Circle $r
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $top, $bottom, 90.0
  $g.FillEllipse($br, $rect); $br.Dispose()
}

# Rim: steel, lit from the top; black gap; gold ring; black gap; disc.
# -NoRim: the disc alone, filling the canvas (for inside a game ring).
$discR = 510
if (-not $NoRim) {
  LinearFill 510 (C 178 182 192) (C 70 72 80)
  LinearFill 486 (C 10 10 12) (C 10 10 12)
  LinearFill 472 (C 236 198 64) (C 150 112 14)
  LinearFill 456 (C 8 8 10) (C 8 8 10)
  $discR = 446
}
$disc = New-Object System.Drawing.Drawing2D.GraphicsPath
$disc.AddEllipse((Circle $discR))
$rad = New-Object System.Drawing.Drawing2D.PathGradientBrush $disc
$rad.CenterColor = C 26 76 118
$rad.SurroundColors = @(C 5 16 28)
$rad.FocusScales = New-Object System.Drawing.PointF 0.25, 0.25
$g.FillPath($rad, $disc)
# a soft sheen across the top of the disc: a radial fade with no edge
$sheenPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$sheenPath.AddEllipse((New-Object System.Drawing.RectangleF 150, 20, 724, 520))
$sheen = New-Object System.Drawing.Drawing2D.PathGradientBrush $sheenPath
$sheen.CenterPoint = New-Object System.Drawing.PointF 512, 170
$sheen.CenterColor = C 255 255 255 30
$sheen.SurroundColors = @(C 255 255 255 0)
$g.SetClip($disc)
$g.FillPath($sheen, $sheenPath)
$g.ResetClip()

# Bubbles: make_glyph.ps1's shapes, scaled to 0.66 of the logo and centred.
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
$k = 0.66
$m = New-Object System.Drawing.Drawing2D.Matrix
$m.Translate(512 - 512 * $k, 512 - 512 * $k)
$m.Scale($k, $k)
$back.Transform($m); $front.Transform($m)

$layer = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$lg = [System.Drawing.Graphics]::FromImage($layer)
$lg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$lg.Clear([System.Drawing.Color]::Transparent)
$blue = New-Object System.Drawing.Drawing2D.LinearGradientBrush $back.GetBounds(), (C 40 168 240), (C 0 118 200), 90.0
$lg.FillPath($blue, $back)
$lg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$clear = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Transparent)
$gap = New-Object System.Drawing.Pen ([System.Drawing.Color]::Transparent), (60 * $k)
$gap.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$lg.DrawPath($gap, $front)
$lg.FillPath($clear, $front)
$lg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
$lg.FillPath((New-Object System.Drawing.SolidBrush (C 250 251 255)), $front)
$lg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$cy = 512 + (590 - 512) * $k; $r = 40 * $k
foreach ($cx0 in 517, 637, 757) {
  $cx = 512 + ($cx0 - 512) * $k
  $lg.FillEllipse($clear, $cx - $r, $cy - $r, 2 * $r, 2 * $r)
}
$lg.Dispose()
$g.DrawImage($layer, 0, 0)
$g.Dispose()

$small = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.DrawImage($big, 0, 0, $Size, $Size)
$gs.Dispose()
$small.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose(); $big.Dispose(); $layer.Dispose()
"wrote $Out"
