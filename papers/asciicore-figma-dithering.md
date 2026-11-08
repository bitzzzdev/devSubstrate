# Vector Dithering and VGA Glitch Generation in Figma: Asciicore

Author: Dev Borah (bitzzdev)  
Date: November 2026  
Status: Evaluated

## Abstract

This paper analyzes the Asciicore plugin (`vga asciicore.exe`) within the Figma design ecosystem. We explore matrix dithering algorithms (Floyd-Steinberg and Bayer ordered dithering), color reduction palettes, and vectorization workflows for retro user interface prototyping.

## 1. Dithering Mathematics in Vector Design

Standard vector design tools lack native pixel-manipulation shaders. The Asciicore plugin injects procedural dithering and ASCII quantization directly into Figma's node graph.

Key algorithms implemented:
- Bayer ordered dithering: Applies a fixed threshold matrix ($4\times4$ or $8\times8$) to evaluate whether a pixel activates a high-contrast foreground color, producing clean geometric cross-hatch patterns.
- Floyd-Steinberg error diffusion: Distributes quantization error to neighboring pixels according to standard diffusion coefficients:
  $$E_{x+1, y} += \frac{7}{16}E, \quad E_{x-1, y+1} += \frac{3}{16}E, \quad E_{x, y+1} += \frac{5}{16}E, \quad E_{x+1, y+1} += \frac{1}{16}E$$
- ASCII cell replacement: Evaluates image blocks and substitutes vector glyphs matched to local brightness levels.

## 2. Figma Integration Workflow

To use Asciicore inside a production UI design workflow:
1. Place target raster graphic or complex illustration on an artboard.
2. Open `vga asciicore.exe` via Figma Plugins.
3. Configure target color palette (VGA 16-color, Game Boy 4-shade green, monochrome 1-bit).
4. Select sampling density and export directly as clean SVG vector paths or flattened PNG layers.

## 3. Practical Value

Asciicore bridges vintage computing aesthetics with modern design systems, allowing developers and designers to produce cyber-retro interfaces, cyberpunk posters, and terminal-inspired application mockups with accurate dithered gradients.
