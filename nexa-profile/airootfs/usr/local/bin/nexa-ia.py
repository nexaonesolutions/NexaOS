#!/usr/bin/env python3
# ==============================================================================
#  NEXA OS - NEXA IA DESKTOP AGENT (FastAPI Backend + Game Mode Server)
#  Salvar em: airootfs/usr/local/bin/nexa-ia.py
# ==============================================================================

import os
import subprocess
import uvicorn
import random
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI(
    title="Nexa IA Core Agent",
    description="Agente local para automação e orquestração do Nexa OS",
    version="1.1"
)

# Caminho dos arquivos do Game Mode Overlay
OVERLAY_PATH = "/usr/share/nexa-overlay"

class WorkspaceCmd(BaseModel):
    id: int

class LaunchCmd(BaseModel):
    command: str
    game_name: str

@app.get("/status")
def get_status():
    try:
        kernel = subprocess.check_output(["uname", "-r"]).decode("utf-8").strip()
    except Exception:
        kernel = "Desconhecido (Modo simulação)"
    
    return {
        "system": "Nexa OS",
        "kernel": kernel,
        "environment": "Wayland + Hyprland",
        "status": "Ready",
        "power_profile": "Zen-Performance"
    }

@app.get("/gamemode")
def get_gamemode():
    try:
        res = subprocess.check_output(["gamemoded", "-s"]).decode("utf-8").strip()
        return {"gamemode_status": res}
    except Exception:
        return {"gamemode_status": "inativo ou daemon não rodando"}

# --- Endpoints da API do Game Mode ---

@app.get("/api/games")
def list_games():
    # Retorna uma lista de jogos instalados ou sugeridos para teste no Live System
    # Em produção, isso pode escanear diretórios como ~/.steam/steam/steamapps/common/
    return [
        {
            "id": "steam",
            "name": "Steam Big Picture",
            "command": "steam -gamepadui",
            "category": "Console",
            "banner": "https://images.unsplash.com/photo-1612287230202-1bf1d85d1bdf?w=400&q=80"
        },
        {
            "id": "cs2",
            "name": "Counter-Strike 2",
            "command": "steam steam://run/730",
            "category": "FPS / E-Sports",
            "banner": "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&q=80"
        },
        {
            "id": "cyberpunk",
            "name": "Cyberpunk 2077",
            "command": "steam steam://run/1091500",
            "category": "RPG / Sci-Fi",
            "banner": "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=400&q=80"
        },
        {
            "id": "retroarch",
            "name": "RetroArch (Retro Games)",
            "command": "retroarch",
            "category": "Emulador",
            "banner": "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80"
        }
    ]

@app.get("/api/telemetry")
def get_telemetry():
    # Obtém telemetria real do sistema ou simula caso esteja rodando sob WSL/VM sem sensores
    cpu_usage = 0.0
    mem_usage = 0.0
    temp = 42
    
    try:
        # Tenta ler uso de memória no Linux
        with open("/proc/meminfo", "r") as f:
            lines = f.readlines()
            total = int(lines[0].split()[1])
            free = int(lines[1].split()[1])
            mem_usage = round(((total - free) / total) * 100, 1)
    except Exception:
        mem_usage = round(random.uniform(20.0, 45.0), 1)

    try:
        # Tenta ler a temperatura da CPU no Linux
        if os.path.exists("/sys/class/thermal/thermal_zone0/temp"):
            with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
                temp = int(int(f.read().strip()) / 1000)
        else:
            temp = random.randint(45, 68)
    except Exception:
        temp = random.randint(45, 68)

    return {
        "cpu": round(random.uniform(10.0, 30.0), 1), # Simulador simplificado de oscilação de CPU
        "memory": mem_usage,
        "temperature": temp,
        "fps_estimate": random.randint(118, 120),
        "gamemode_active": True
    }

@app.post("/api/games/launch")
def launch_game(cmd: LaunchCmd):
    # Executa o jogo usando o utilitário 'gamemoderun' para otimização de hardware
    try:
        # Adiciona prefixo gamemoderun para rodar com alta performance no kernel Zen
        full_command = f"gamemoderun {cmd.command}"
        subprocess.Popen(full_command.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return {"status": "success", "detail": f"Iniciando {cmd.game_name} otimizado com Feral GameMode"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao disparar processo: {str(e)}")

# --- Rotas de Janela e Controle IPC do Hyprland ---

@app.post("/window/close")
def close_window():
    try:
        result = subprocess.run(["hyprctl", "dispatch", "killactive"], capture_output=True, text=True)
        if result.returncode == 0:
            return {"status": "success", "detail": "Janela fechada via Hyprland IPC"}
        else:
            raise HTTPException(status_code=500, detail=f"Erro Hyprland: {result.stderr}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@app.post("/workspace/switch")
def switch_workspace(cmd: WorkspaceCmd):
    try:
        result = subprocess.run(["hyprctl", "dispatch", "workspace", str(cmd.id)], capture_output=True, text=True)
        if result.returncode == 0:
            return {"status": "success", "detail": f"Workspace alterado para {cmd.id}"}
        else:
            raise HTTPException(status_code=500, detail=f"Erro Hyprland: {result.stderr}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

# --- Servir arquivos estáticos do Overlay (Se o diretório existir) ---
if os.path.exists(OVERLAY_PATH):
    app.mount("/static", StaticFiles(directory=OVERLAY_PATH), name="static")

    @app.get("/game-mode")
    def get_game_mode():
        return FileResponse(os.path.join(OVERLAY_PATH, "index.html"))

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
