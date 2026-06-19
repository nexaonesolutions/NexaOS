# Nexa OS 🌌

> Elegant, Minimalist, and Ultra-Performance Wayland/Hyprland OS for Backend Developers & Gamers.

Nexa OS is a premium, custom Arch Linux-based distribution designed to feel like a "macOS Killer" while retaining the absolute speed of Linux. It features a fully-customized workspace with Hyprland, Aylur's Gtk Shell (AGS), Calamares offline installer, and the built-in FastAPI-powered **Nexa IA** assistant daemon.

---

## 🚀 Key Features

* **Visual Layer:** Hyprland window manager with customized Bézier curves, dual-kawase blur, and premium glassmorphism.
* **Developer Terminal:** Zsh customized offline with Oh My Zsh, Agnoster theme, auto-suggestions, and syntax highlighting.
* **Game Mode:** High-performance PlayStation-style Web UI overlay with real-time telemetry, activated via `SUPER+G`.
* **Automation (Nexa IA):** Local FastAPI-powered daemon exposing endpoints for workspace control and system operations.

---

## 🛠️ How to Compile (Cloud Architecture)

This repository includes a pre-configured GitHub Actions pipeline to compile the bootable `.ISO` image.

1. **Fork or Push** this project to your GitHub repository: `https://github.com/nexaonesolutions/NexaOS.git`
2. Go to the **Actions** tab on your repository.
3. The build workflow will trigger automatically on pushes to `main`.
4. Once completed, download the `.ISO` from the run's **Artifacts** section.
