# Dovetail Maker 2026 — SketchUp Through Dovetail Extension

> **Traditional joinery, accelerated by AI.**  
> A SketchUp 2026 Pro extension for creating **through dovetail joints** with a **Tail-first** workflow.

[繁體中文 README](README.md)

## About

I work with traditional woodworking methods and prefer joinery-based construction over screws whenever possible. In my own furniture and woodworking projects, dovetails are not just structural details—they are part of the craft itself.

While designing woodworking projects in SketchUp, I found that manually drawing dovetails is repetitive and time-consuming. Each joint requires laying out tails and pins, calculating slope, spacing the geometry, and repeating the same modeling steps.

With the help of AI, I developed **Dovetail Maker 2026** to automate those repetitive geometric tasks so woodworkers can spend more time on design and craftsmanship instead of rebuilding the same dovetail geometry by hand.

If you are interested in traditional joinery, woodworking, furniture design, or SketchUp modeling, you are welcome to download and use the extension. Feedback, bug reports, and suggestions are also welcome through GitHub Issues.

## Features

- Built for SketchUp 2026 Pro
- Through dovetail joints
- Tail-first workflow
- Adjustable tail count
- Common woodworking slopes: `1:4 / 1:5 / 1:6 / 1:7 / 1:8`
- Adjustable left and right half pins
- Automatic tail and pin geometry calculation
- Live green preview
- Left/right flip control
- Create matching tails on the opposite end
- Pin geometry generated from the finished tail geometry
- Supports Groups and Components

## Download

**[Download DovetailMaker2026.rbz](https://github.com/echohook/DovetailMaker2026/raw/main/dist/DovetailMaker2026.rbz)**

Install the RBZ directly through SketchUp Extension Manager. Do not extract it first.

## Requirements

- SketchUp 2026 Pro
- Version: 1.2.6
- Release date: 2026-08-31
- Clearance: 0 mm in V1

## Installation

1. Download `DovetailMaker2026.rbz`.
2. Open SketchUp 2026 Pro.
3. Go to **Window → Extension Manager**.
4. Click **Install Extension**.
5. Select `DovetailMaker2026.rbz`.
6. Launch it from **Extensions → Dovetail Maker 2026**.

## Basic Workflow

1. Position two equal-thickness rectangular solid boards at their intended 90° assembled position.
2. Select only the Tail Board. It must be a Group or Component.
3. Launch Dovetail Maker 2026.
4. Set board thickness, tail count, dovetail slope, left half pin, and right half pin.
5. Check the live preview and use **Flip** when needed.
6. Click **Create Tail**.
7. Optionally create the same tail pattern on the opposite end.
8. Select the matching Pin Board face.
9. Check the pin preview and click **Create Pin**.
10. Finish the operation.

## V1 Limitations

- Supports closed, rectangular, equal-thickness Group / Component boards only.
- Boards must already be positioned at their intended 90° assembly location.
- Raw loose geometry is not supported.
- Angled boards, curved boards, and non-rectangular end faces are not supported.
- Half-blind dovetails are not supported.
- Sliding dovetails are not supported.
- CNC tool compensation is not supported.
- Clearance is fixed at 0 in V1.
- Pin geometry is derived from the completed tail geometry rather than recalculated independently.

## Why This Tool Exists

Dovetails are a classic and reliable form of woodworking joinery, but reproducing each tail and pin manually in a digital model can consume a significant amount of design time.

Dovetail Maker 2026 is not intended to replace woodworking knowledge. Its purpose is to remove repetitive SketchUp drafting work and make traditional joinery faster to model.

## Bug Reports and Suggestions

Please use GitHub Issues for:

- Installation problems
- Board detection problems
- Tail or pin geometry issues
- SketchUp compatibility issues
- Feature requests

When reporting a problem, include your SketchUp version, Dovetail Maker version, steps to reproduce, any error message, and screenshots when possible.

## Project Information

- Creator: James Hook
- Version: 1.2.6
- Platform: SketchUp 2026 Pro
- Language: Ruby / SketchUp Ruby API

## Keywords

`SketchUp dovetail extension` · `SketchUp woodworking plugin` · `through dovetail` · `dovetail maker` · `woodworking joinery` · `traditional joinery` · `SketchUp Ruby extension` · `furniture design` · `tail first dovetail`

---

**Dovetail Maker 2026** — Traditional joinery, accelerated by AI.