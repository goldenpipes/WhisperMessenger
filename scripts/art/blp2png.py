"""BLP2 -> PNG (mip 0): palette, DXT1/3/5 and raw BGRA. Usage: blp2png.py in.blp out.png"""
import struct, sys, zlib


def png(path, w, h, rgba):
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + bytes(rgba[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(data)


def c565(c):
    r, g, b = (c >> 11) & 31, (c >> 5) & 63, c & 31
    return (r * 255 // 31, g * 255 // 63, b * 255 // 31)


def dxt(data, w, h, kind):
    out = bytearray(w * h * 4)
    bs = 8 if kind == 1 else 16
    i = 0
    for by in range(0, h, 4):
        for bx in range(0, w, 4):
            blk = data[i:i + bs]; i += bs
            alpha = [255] * 16
            if kind == 3:
                bits = int.from_bytes(blk[0:8], "little")
                alpha = [((bits >> (4 * k)) & 15) * 17 for k in range(16)]
                col = blk[8:16]
            elif kind == 5:
                a0, a1 = blk[0], blk[1]
                bits = int.from_bytes(blk[2:8], "little")
                if a0 > a1:
                    pal = [a0, a1] + [((7 - k) * a0 + k * a1) // 7 for k in range(1, 7)]
                else:
                    pal = [a0, a1] + [((5 - k) * a0 + k * a1) // 5 for k in range(1, 5)] + [0, 255]
                alpha = [pal[(bits >> (3 * k)) & 7] for k in range(16)]
                col = blk[8:16]
            else:
                col = blk
            c0, c1 = struct.unpack("<HH", col[0:4])
            p0, p1 = c565(c0), c565(c1)
            if c0 > c1 or kind != 1:
                p2 = tuple((2 * a + b) // 3 for a, b in zip(p0, p1)); p3 = tuple((a + 2 * b) // 3 for a, b in zip(p0, p1)); t3 = 255
            else:
                p2 = tuple((a + b) // 2 for a, b in zip(p0, p1)); p3 = (0, 0, 0); t3 = 0
            pal = [p0 + (255,), p1 + (255,), p2 + (255,), p3 + (t3,)]
            idx = struct.unpack("<I", col[4:8])[0]
            for k in range(16):
                x, y = bx + k % 4, by + k // 4
                if x < w and y < h:
                    r, g, b, a = pal[(idx >> (2 * k)) & 3]
                    if kind != 1:
                        a = alpha[k]
                    o = (y * w + x) * 4
                    out[o:o + 4] = bytes((r, g, b, a))
    return out


def main(src, dst):
    d = open(src, "rb").read()
    assert d[:4] == b"BLP2", "not BLP2"
    comp, adepth, atype, mips = d[8], d[9], d[10], d[11]
    w, h = struct.unpack("<II", d[12:20])
    offs = struct.unpack("<16I", d[20:84]); sizes = struct.unpack("<16I", d[84:148])
    data = d[offs[0]:offs[0] + sizes[0]]
    print(f"{src}: {w}x{h} compression={comp} alphaDepth={adepth} alphaType={atype}")
    if comp == 1:
        palette = [d[148 + 4 * k:152 + 4 * k] for k in range(256)]
        n = w * h
        out = bytearray(n * 4)
        for k in range(n):
            b, g, r, _ = palette[data[k]]
            if adepth == 8:
                a = data[n + k]
            elif adepth == 1:
                a = 255 if (data[n + k // 8] >> (k % 8)) & 1 else 0
            elif adepth == 4:
                a = ((data[n + k // 2] >> (4 * (k % 2))) & 15) * 17
            else:
                a = 255
            out[4 * k:4 * k + 4] = bytes((r, g, b, a))
    elif comp == 2:
        kind = 1 if adepth <= 1 else (3 if atype == 1 else 5)
        out = dxt(data, w, h, kind)
    else:
        out = bytearray()
        for k in range(w * h):
            b, g, r, a = data[4 * k:4 * k + 4]
            out += bytes((r, g, b, a))
    png(dst, w, h, out)


main(sys.argv[1], sys.argv[2])
