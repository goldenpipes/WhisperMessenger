param([string]$Out, [int]$Size = 384, [int]$Spread = 6, [int]$Blur = 9)
# Glow that follows the two chat bubbles of make_glyph.ps1: their outline
# (gap between them filled), grown by $Spread px, softened by three box
# blurs of $Blur px, then the bubbles cut back out so only the halo outside
# them remains. The canvas is 1.5x the glyph's, glyph centred, so the halo
# has room past the glyph's edges. White; the game tints it, drawn ADD.
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
public static class GlowMath {
  public static float[] BoxBlur(float[] a, int n, int r) {
    var t = new float[a.Length]; var o = new float[a.Length];
    for (int y = 0; y < n; y++) for (int x = 0; x < n; x++) {
      float s = 0; int c = 0;
      for (int k = -r; k <= r; k++) { int xx = x + k; if (xx >= 0 && xx < n) { s += a[y * n + xx]; c++; } }
      t[y * n + x] = s / (2 * r + 1);
    }
    for (int y = 0; y < n; y++) for (int x = 0; x < n; x++) {
      float s = 0;
      for (int k = -r; k <= r; k++) { int yy = y + k; if (yy >= 0 && yy < n) s += t[yy * n + x]; }
      o[y * n + x] = s / (2 * r + 1);
    }
    return o;
  }
  public static float[] Grow(float[] a, int n, int r) {
    var o = new float[a.Length];
    for (int y = 0; y < n; y++) for (int x = 0; x < n; x++) {
      float m = 0;
      for (int dy = -r; dy <= r; dy++) for (int dx = -r; dx <= r; dx++) {
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

# Same shapes and 1024 units as make_glyph.ps1.
$back = Bubble 120 170 540 390 110 @((Pt 200 500), (Pt 340 540), (Pt 170 690))
$front = Bubble 370 400 534 380 110 @((Pt 730 760), (Pt 870 700), (Pt 870 900))

$n = $Size
$bmp = New-Object System.Drawing.Bitmap $n, $n, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
# 1024 glyph units -> the middle 2/3 of the canvas.
$k = ($n / 1.5) / 1024
$g.TranslateTransform($n / 6, $n / 6)
$g.ScaleTransform($k, $k)
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$g.FillPath($white, $back)
$g.FillPath($white, $front)
$gapPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 60
$gapPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.DrawPath($gapPen, $front)
$g.Dispose()

$shape = New-Object float[] ($n * $n)
for ($y = 0; $y -lt $n; $y++) { for ($x = 0; $x -lt $n; $x++) { $shape[$y * $n + $x] = $bmp.GetPixel($x, $y).A / 255.0 } }

$glow = [GlowMath]::Grow($shape, $n, $Spread)
for ($i = 0; $i -lt 3; $i++) { $glow = [GlowMath]::BoxBlur($glow, $n, $Blur) }

for ($y = 0; $y -lt $n; $y++) {
  for ($x = 0; $x -lt $n; $x++) {
    $i = $y * $n + $x
    $a = [Math]::Max(0.0, [Math]::Min(1.0, $glow[$i] * 1.3)) * (1 - $shape[$i])
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int][Math]::Round(255 * $a), 255, 255, 255))
  }
}
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"wrote $Out"
