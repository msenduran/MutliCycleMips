#!/usr/bin/env python3
"""
pdf_to_png.py — Convert a (vector) PDF page to a cropped, high-resolution PNG
using PyMuPDF. Used to turn the Quartus RTL Viewer PDF export into a raster
image that embeds in the report (.md / .docx).

Usage:  python pdf_to_png.py <in.pdf> <out.png> [zoom]
"""
import sys
import fitz  # PyMuPDF


def main():
    if len(sys.argv) < 3:
        print("usage: python pdf_to_png.py <in.pdf> <out.png> [zoom]")
        sys.exit(1)
    inp, out = sys.argv[1], sys.argv[2]
    zoom = float(sys.argv[3]) if len(sys.argv) > 3 else 4.0

    doc = fitz.open(inp)
    page = doc[0]
    # crop to the bounding box of the drawn content (drop page whitespace)
    rects = [d["rect"] for d in page.get_drawings() if d.get("rect")]
    if rects:
        bbox = rects[0]
        for r in rects[1:]:
            bbox |= r
        bbox = fitz.Rect(bbox.x0 - 12, bbox.y0 - 12, bbox.x1 + 12, bbox.y1 + 12)
        bbox &= page.rect
    else:
        bbox = page.rect
    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=bbox)
    pix.save(out)
    print("wrote {} ({} x {})".format(out, pix.width, pix.height))


if __name__ == "__main__":
    main()
