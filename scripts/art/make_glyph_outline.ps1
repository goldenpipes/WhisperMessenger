param([string]$Out, [int]$Size = 256, [int]$Work = 512, [float]$Width = 40)
# Outline of the two chat bubbles of make_glyph.ps1, same canvas: the
# bubbles grown by $Width glyph units (of 1024) with the bubbles themselves
# cut back out, so it fills the gap between them but leaves the dots and
# the bubbles clear. White; the game tints it black.
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
public static class OutlineMath {
  public static float[] Grow(float[] a, int n, int r) {
    var o = new float[a.Length];
    for (int y = 0; y < n; y++) for (int x = 0; x < n; x++) {
      float m = 0;
      for (int dy = -r; dy <= r && m < 1; dy++) for (int dx = -r; dx <= r; dx++) {
        if (dx * dx + dy * dy > r * r) continue;
        int xx = x + dx, yy = y + dy;
        if (xx >= 0 && xx < n && yy >= 0 && yy < n && a[yy * n + xx] > m) m = a[yy * n + xx];
      }
      o[y * n + x] = m;
    }
    return o;
  }
}
"@

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

# The bubbles as drawn (back bubble with the gap cut out), front without its dots.
$n = $Work
$bmp = New-Object System.Drawing.Bitmap $n, $n, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
$k = $n / 1024; $g.ScaleTransform($k, $k)
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$clear = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Transparent)
$g.FillPath($white, $back)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$gap = New-Object System.Drawing.Pen ([System.Drawing.Color]::Transparent), 60
$gap.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.DrawPath($gap, $front)
$g.FillPath($clear, $front)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
$g.FillPath($white, $front)
$g.Dispose()

$shape = New-Object float[] ($n * $n)
for ($y = 0; $y -lt $n; $y++) { for ($x = 0; $x -lt $n; $x++) { $shape[$y * $n + $x] = $bmp.GetPixel($x, $y).A / 255.0 } }
$grown = [OutlineMath]::Grow($shape, $n, [int][Math]::Round($Width * $k))
for ($y = 0; $y -lt $n; $y++) {
  for ($x = 0; $x -lt $n; $x++) {
    $i = $y * $n + $x
    $a = [Math]::Max(0.0, $grown[$i] - $shape[$i])
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int][Math]::Round(255 * $a), 255, 255, 255))
  }
}

$small = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.DrawImage($bmp, 0, 0, $Size, $Size)
$gs.Dispose()
$small.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose(); $bmp.Dispose()
"wrote $Out"
