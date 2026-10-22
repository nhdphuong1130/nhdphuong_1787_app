# Stitch Design System DNA: ChildGuard (Modern & Clean)

## 1. Visual Theme and Atmosphere
- **Atmosphere**: Modern, trustworthy, calm, minimal, and child-safe.
- **Surface**: Ultra-clean `#F8FAFC` (Slate-50) root background with crisp white `#FFFFFF` elevation cards.
- **Visual Weight**: Eliminates walls of text, replacing technical explanations with self-explanatory iconography, compact metric chips, and intuitive colored status pills.
- **Roundness Token**: `ROUND_XL` (16px to 24px) for cards, `ROUND_FULL` (999px pill) for badges and status indicators.

## 2. Color Palette and Roles
- **Brand Primary**: Deep Indigo `#3730A3` / `#4F46E5` (Professional, calming protection for Parents & Kids).
- **Admin Accent**: Crimson Red `#991B1B` / `#DC2626` (Authoritative, high-visibility control).
- **Kid Fun Accent**: Bright Purple `#7C3AED` & Coral `#F43F5E`.
- **Status Tokens**:
  - `Safe / Normal`: Emerald `#059669` (Background: `#ECFDF5`, Border: `#A7F3D0`).
  - `Attention / Warning`: Amber `#D97706` (Background: `#FFFBEB`, Border: `#FDE68A`).
  - `Hazard / Danger / Locked`: Rose `#E11D48` (Background: `#FFF1F2`, Border: `#FECDD3`).
  - `Neutral Informational`: Sky Blue `#0284C7` (Background: `#F0F9FF`, Border: `#BAE6FD`).

## 3. Typography & Information Hierarchy
- **Glanceable Metrics**: Large bold value (18-22px, `FontWeight.w700`) + compact micro-label (10-11px, `FontWeight.w600`).
- **Headlines**: Semi-bold 16-18px, high contrast `#0F172A`.
- **Subtexts**: Compact, purposeful 11-12px `#64748B`, strictly limited to 1 line (no multi-line paragraphs).
- **Microcopy**: Replaces redundant explanations with standard UI conventions (e.g. icon + tooltip, color-coded status badges).

## 4. Component Patterns
- **Metric Pill / Metric Tile**:
  Compact rounded container (radius 12-14px) with subtle tonal fill, leading icon, bold value, and state indicator dot.
- **Action Pills**:
  Pill-shaped tonal action buttons (`ROUND_FULL`) with clean icon + single-word action label (`Bản đồ`, `Quy tắc`, `Lịch`, `Khóa`).
- **Profile / Device Card**:
  Airy spacing, clear visual divider between child identity and live telemetry, zero clutter.
- **Kid Shield View**:
  Playful, friendly central shield illustration with prominent pairing QR & 6-digit code, plus sleek bottom indicators.
