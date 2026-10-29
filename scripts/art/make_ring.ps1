param([string]$Out, [ValidateSet("modern", "classic")][string]$Style, [int]$Size = 256)
# Hi-res, centred redraw of Blizzard's MiniMap-TrackingBorder, measured from
# the retail (modern) and Classic Era 64px files. Units are the original's
# pixels: the ring's outer edge is radius 16, the canvas spans radius 22 so
# the shadow fits. Each pixel is shaded from its radius and a top-left light,
# rendered 4x and averaged down.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing;
public static class Ring {
  static double S(double e0, double e1, double x) { double t = Math.Max(0, Math.Min(1, (x - e0) / (e1 - e0))); return t * t * (3 - 2 * t); }
  static double Band(double r, double a, double b, double aa) { return S(a - aa, a + aa, r) * (1 - S(b - aa, b + aa, r)); }
  static double[] Lerp(double[] p, double[] q, double t) { return new double[] { p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t, p[2] + (q[2] - p[2]) * t }; }
  // over: composite colour c with coverage a onto (rgb, A)
  static void Over(double[] acc, double[] c, double a) {
    double outA = a + acc[3] * (1 - a);
    if (outA <= 0) return;
    for (int i = 0; i < 3; i++) acc[i] = (c[i] * a + acc[i] * acc[3] * (1 - a)) / outA;
    acc[3] = outA;
  }
  // A band from radius a to b shaded as a rounded metal bar: its normal
  // tilts inward/outward across the band; lit from the top left and a little
  // toward the viewer; diffuse + a tight specular + a dark lower reflection.
  static double[] Metal(double x, double y, double r, double a, double b, double[] baseC, double[] hiC, double[] darkC, double specAmt) {
    double u = Math.Max(-0.98, Math.Min(0.98, (r - (a + b) / 2) / ((b - a) / 2)));
    double cx = r > 0 ? x / r : 0, cy = r > 0 ? y / r : 0;
    double nx = u * cx, ny = u * cy, nz = Math.Sqrt(1 - u * u);
    double lx = -0.45, ly = -0.62, lz = 0.64; // normalised light
    double diff = Math.Max(0, nx * lx + ny * ly + nz * lz);
    // reflect the light about the normal, compare with the view (0,0,1)
    double d = nx * lx + ny * ly + nz * lz, rz = 2 * d * nz - lz;
    double spec = Math.Pow(Math.Max(0, rz), 18);
    // fake environment: the lower half of the bar reflects a dark ground
    double env = Math.Max(0, ny) * 0.5;
    var c = new double[3];
    for (int i = 0; i < 3; i++) {
      double v = baseC[i] * (0.28 + 0.9 * diff);
      v = v * (1 - env) + darkC[i] * env;
      v = v + (hiC[i] - v) * Math.Min(1, spec * specAmt);
      c[i] = Math.Max(0, Math.Min(255, v));
    }
    return c;
  }
  public static Bitmap Render(int size, bool classic) {
    int ss = 4, n = size * ss;
    double unit = (n / 2.0) / 22.0, aa = 0.35;
    var acc = new double[size * size * 4];
    for (int py = 0; py < n; py++) for (int px = 0; px < n; px++) {
      double x = (px + 0.5 - n / 2.0) / unit, y = (py + 0.5 - n / 2.0) / unit;
      double r = Math.Sqrt(x * x + y * y);
      double l = r > 0 ? (-0.6 * x - 0.8 * y) / r : 0; // light from the top left, -1..1
      var p = new double[4];
      // drop shadow, down and to the right; none inside the ring's hole
      double sx = classic ? 0.6 : 0.6, sy = classic ? 0.9 : 1.0, outer = classic ? 18.2 : 20.0;
      double rs = Math.Sqrt((x - sx) * (x - sx) + (y - sy) * (y - sy));
      double shadow = (1 - S(15.5, outer, rs)) * S(11.0, 12.0, r) * (classic ? 0.65 : 0.6);
      if (!classic) Over(p, new double[] { 0, 0, 0 }, shadow); // Classic draws its own, measured
      if (!classic) {
        double[] dark = { 70, 54, 18 }, gold = { 200, 163, 64 }, hi = { 236, 210, 130 };
        double bump = Math.Max(0, 1 - Math.Abs(r - 14.0) / 2.0);
        var c = Lerp(dark, gold, bump);
        c = Lerp(c, l > 0 ? hi : new double[] { 40, 30, 10 }, Math.Abs(l) * (l > 0 ? 0.35 : 0.3) * bump);
        Over(p, new double[] { 30, 22, 8 }, Band(r, 11.9, 16.2, aa) * 0.55);
        Over(p, c, Band(r, 12.3, 15.6, aa));
      } else {
        // A copy of Classic Era's minimap border (UI-Minimap-Border, outer
        // radius 72.5px there, 16 units here): its proportions and its
        // brightness at each angle, measured every 45 degrees. Angles count
        // anticlockwise from the right (90 = top). From the centre out: a
        // shadow inside the hole (heaviest at the top), a thin gold ring
        // (bright top and bottom, dim at the sides), a gunmetal ring whose
        // outer half is lit at the top left and inner half at the bottom
        // right, and a drop shadow toward the bottom right.
        double ang = Math.Atan2(-y, x);
        double km = 16.0 / 72.5;
        double rIn = 65.5 * km, rGold = 67.5 * km, rMid = 69.5 * km, rOut = 72.5 * km;
        double wob = 0.02 * Math.Sin(5 * ang + 1.1) + 0.015 * Math.Sin(13 * ang + 0.4);
        double rr = r - wob;
        int gx = px / ss, gy = py / ss;
        uint h = (uint)(gx * 73856093) ^ (uint)(gy * 19349663);
        h ^= h >> 13; h *= 0x5bd1e995; h ^= h >> 15;
        double grain = ((h & 1023) / 1023.0 - 0.5);
        double sinA = Math.Sin(ang);
        // inner shadow: alpha 50..220 at the hole's edge, fading 2.5px inward
        double inA = (50 + 170 * Math.Pow(Math.Max(0, sinA), 2)) / 255.0;
        Over(p, new double[] { 0, 0, 0 }, inA * S(rIn - 2.5 * km, rIn, rr) * (1 - S(rIn, rIn + 0.05, rr)));
        // outer drop shadow: 30..170 toward the bottom right, out to 76px
        double outA = (30 + 140 * Math.Max(0, Math.Cos(ang - 300 * Math.PI / 180))) / 255.0;
        Over(p, new double[] { 0, 0, 0 }, outA * (1 - S(rOut, 76.5 * km, rr)) * S(rOut - 0.1, rOut, rr));
        // gold ring
        {
          double lvl = 0.5 + 0.5 * Math.Abs(sinA);
          var gold = Lerp(new double[] { 112, 90, 12 }, new double[] { 246, 206, 0 }, lvl);
          double v = grain * 14;
          gold = new double[] { Math.Max(0, Math.Min(255, gold[0] + v)), Math.Max(0, Math.Min(255, gold[1] + v)), Math.Max(0, Math.Min(255, gold[2] + v * 0.3)) };
          Over(p, gold, Band(rr, rIn, rGold, aa * 0.6));
        }
        // gunmetal ring: inner half lit at the bottom right, outer half at the top left
        {
          double innerLv = 20 + 108 * Math.Pow(Math.Max(0, Math.Cos(ang - 292 * Math.PI / 180)), 1.5);
          double outerLv = 30 + 183 * Math.Pow(Math.Max(0, Math.Cos(ang - 140 * Math.PI / 180)), 1.6);
          // The whole band takes the outer half's light; the inner half only
          // brightens further where it catches light (bottom right). A thin
          // dark line, not a dark half, separates it from the gold.
          double t = S(rMid - 0.35, rMid + 0.35, rr);
          double innerHalf = Math.Max(outerLv * 0.85, innerLv);
          double lv = innerHalf + (outerLv - innerHalf) * t + grain * 18;
          lv = Math.Max(0, Math.Min(255, lv));
          Over(p, new double[] { lv, lv * 0.985, lv * 0.97 }, Band(rr, rGold, rOut, aa * 0.6));
          Over(p, new double[] { 14, 12, 8 }, Band(rr, rGold, rGold + 0.7 * km, aa * 0.4) * 0.7);
        }
      }
      int ox = px / ss, oy = py / ss, o = (oy * size + ox) * 4;
      acc[o] += p[0] * p[3]; acc[o + 1] += p[1] * p[3]; acc[o + 2] += p[2] * p[3]; acc[o + 3] += p[3];
    }
    var bmp = new Bitmap(size, size, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
    int k = ss * ss;
    for (int y = 0; y < size; y++) for (int x = 0; x < size; x++) {
      int o = (y * size + x) * 4; double a = acc[o + 3];
      if (a <= 0) { bmp.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0)); continue; }
      bmp.SetPixel(x, y, Color.FromArgb((int)Math.Round(255 * a / k), (int)Math.Round(acc[o] / a), (int)Math.Round(acc[o + 1] / a), (int)Math.Round(acc[o + 2] / a)));
    }
    return bmp;
  }
}
"@
$bmp = [Ring]::Render($Size, $Style -eq "classic")
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"wrote $Out"
