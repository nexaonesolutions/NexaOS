#!/usr/bin/env python3
import os
import subprocess
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
import uvicorn

app = FastAPI(title="Nexa Control Center API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Routes
@app.post("/api/theme/opacity")
async def set_opacity(level: int):
    if not 0 <= level <= 100:
        raise HTTPException(status_code=400, detail="Opacity must be between 0 and 100")
    
    # Calculate opacity alpha from percentage
    alpha = level / 100.0
    css_file = os.path.expanduser("~/.config/waybar/style.css")
    
    try:
        # Simplistic implementation: replace rgba(..., 0.xx) with the new alpha
        # For a production app, we would parse CSS properly
        with open(css_file, "r") as f:
            content = f.read()
            
        import re
        new_content = re.sub(
            r"background-color: rgba\((\d+),\s*(\d+),\s*(\d+),\s*[0-9.]+\)",
            f"background-color: rgba(\\1, \\2, \\3, {alpha})",
            content
        )
        
        with open(css_file, "w") as f:
            f.write(new_content)
            
        # Reload waybar
        subprocess.run(["pkill", "-SIGUSR2", "waybar"], check=False)
        return {"status": "success", "opacity": alpha}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/system/adshield")
async def toggle_adshield(enabled: bool):
    try:
        if enabled:
            # Download and apply StevenBlack hosts (mocked for safety)
            # subprocess.run(["sudo", "curl", "-o", "/etc/hosts", "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"])
            subprocess.run(["logger", "[Nexa AdShield] Ativado"])
        else:
            # Revert to standard hosts (mocked)
            # subprocess.run(["sudo", "cp", "/etc/hosts.backup", "/etc/hosts"])
            subprocess.run(["logger", "[Nexa AdShield] Desativado"])
        return {"status": "success", "enabled": enabled}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Mount static frontend
frontend_dir = "/usr/share/nexa-cc"
if os.path.exists(frontend_dir):
    app.mount("/", StaticFiles(directory=frontend_dir, html=True), name="frontend")
else:
    @app.get("/")
    async def fallback():
        return {"message": "Nexa Control Center API is running. Frontend not found."}

if __name__ == "__main__":
    uvicorn.run("nexa-ia:app", host="127.0.0.1", port=8000, reload=False)
