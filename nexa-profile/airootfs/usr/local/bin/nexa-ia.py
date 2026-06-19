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

@app.get("/api/drives")
async def get_drives():
    try:
        # Run lsblk to get block devices in JSON format
        result = subprocess.run(["lsblk", "-J", "-o", "NAME,SIZE,TYPE,MODEL"], capture_output=True, text=True)
        import json
        data = json.loads(result.stdout)
        
        # Filter only disks (ignore partitions and loop devices)
        drives = []
        for dev in data.get("blockdevices", []):
            if dev.get("type") == "disk" and not dev.get("name").startswith("loop"):
                drives.append({
                    "name": f"/dev/{dev.get('name')}",
                    "size": dev.get("size"),
                    "model": dev.get("model", "Unknown Drive")
                })
        return {"drives": drives}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

from pydantic import BaseModel

class InstallRequest(BaseModel):
    drive: str
    username: str
    password: str
    hostname: str

@app.post("/api/install")
async def trigger_install(req: InstallRequest):
    import json
    
    # 1. Create archinstall configuration JSONs
    # This is a highly simplified representation for the scope of this project.
    # We enforce BTRFS and auto-partitioning on the selected drive.
    
    # Disk layout config (wiping everything on the selected drive)
    disk_layout = {
        req.drive: {
            "partitions": [
                {
                    "boot": True,
                    "encrypted": False,
                    "filesystem": {"format": "fat32"},
                    "mountpoint": "/boot",
                    "size": "512MiB",
                    "start": "1MiB",
                    "type": "primary",
                    "wipe": True
                },
                {
                    "encrypted": False,
                    "filesystem": {"format": "btrfs"},
                    "mountpoint": "/",
                    "size": "100%",
                    "start": "513MiB",
                    "type": "primary",
                    "wipe": True
                }
            ],
            "wipe": True
        }
    }
    
    # Credentials config
    creds = {
        "!root-password": req.password,
        "!users": [
            {
                "!password": req.password,
                "sudo": True,
                "username": req.username
            }
        ]
    }
    
    # Write configs to temp files
    with open("/tmp/disk_layout.json", "w") as f:
        json.dump(disk_layout, f)
        
    with open("/tmp/creds.json", "w") as f:
        json.dump(creds, f)
        
    # The main command to execute archinstall unattended
    # Note: In a real environment, we'd spawn a background task and stream logs.
    # For now, we mock the execution log for UI feedback if not running as root.
    if os.geteuid() == 0:
        # Run actual archinstall (commented out to prevent accidental wipes during dev, uncomment in prod ISO)
        # subprocess.Popen(["archinstall", "--silent", "--config", "/tmp/creds.json", "--disk_layouts", "/tmp/disk_layout.json"])
        subprocess.Popen(["logger", "[Nexa Native Installer] Iniciando Archinstall..."])
    else:
        subprocess.Popen(["logger", "[Nexa Native Installer] Simulated installation started."])
        
    return {"status": "success", "message": "Installation started in background."}

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
