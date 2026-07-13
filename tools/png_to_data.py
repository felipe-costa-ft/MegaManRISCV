#!/usr/bin/env python3
"""Converte PNG para o formato RGB332 .data usado pelo MegaManRISCV."""

import argparse
from pathlib import Path

from PIL import Image


def rgb332(red: int, green: int, blue: int) -> int:
    return ((blue >> 6) << 6) | ((green >> 5) << 3) | (red >> 5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("label")
    parser.add_argument("--transparent", type=int, default=199)
    args = parser.parse_args()

    image = Image.open(args.input).convert("RGBA")
    pixels = []
    for red, green, blue, alpha in image.getdata():
        pixels.append(args.transparent if alpha < 128 else rgb332(red, green, blue))

    lines = [f"{args.label}:", f".word {image.width}, {image.height}"]
    for offset in range(0, len(pixels), 32):
        lines.append(".byte " + ", ".join(str(value) for value in pixels[offset:offset + 32]))
    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
