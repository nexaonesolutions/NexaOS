@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
::  NEXA OS - DOCKER BUILD LAUNCHER (Windows Host)
::  Compila a ISO do Nexa OS dentro de um container Arch Linux isolado.
::
::  PRÉ-REQUISITOS:
::    - Docker Desktop instalado e em execução
::    - A pasta do projeto NexaOS deve ser o diretório corrente
::    - Conexão com a internet (para git clone do Oh My Zsh + mirrors Arch)
:: ==============================================================================

cls
echo.
echo  ============================================================
echo    NEXA OS - Pipeline de Compilação Isolada via Docker
echo    Powered by Nexa Solutions DevOps Engine
echo  ============================================================
echo.

:: Verificar se o Docker está instalado e em execução
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERRO] Docker nao encontrado. Instale em: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERRO] Docker Desktop nao esta em execucao. Inicie-o e tente novamente.
    pause
    exit /b 1
)

echo  [1/3] Docker detectado. Construindo a imagem de build do Nexa OS...
echo        (Isto pode levar alguns minutos na primeira execucao)
echo.

docker build -t nexaos-builder -f Dockerfile.build .
if %errorlevel% neq 0 (
    echo.
    echo  [ERRO] Falha ao construir a imagem Docker. Verifique o Dockerfile.build.
    pause
    exit /b 1
)

echo.
echo  [2/3] Imagem construida com sucesso. Iniciando compilacao da ISO...
echo        (Estimativa: 15 a 30 minutos dependendo do hardware e internet)
echo.

:: --privileged necessário para o archiso montar loops de dispositivo (loop devices)
docker run --rm ^
    -v "%cd%:/build" ^
    --privileged ^
    --name nexa-build ^
    nexaos-builder

if %errorlevel% neq 0 (
    echo.
    echo  [ERRO] O processo de build falhou. Verifique os logs acima.
    pause
    exit /b 1
)

echo.
echo  ============================================================
echo    BUILD CONCLUIDO COM SUCESSO!
echo    A ISO esta disponivel na pasta: output\
echo    Arquivo: NexaOS-Installer-XXXXXX.iso
echo  ============================================================
echo.
echo  Proximos passos:
echo    1. Grave a ISO em um pendrive com o Rufus (modo DD)
echo    2. Ou importe a ISO no VirtualBox/QEMU para teste
echo    3. Selecione a opcao 'Instalar Nexa OS' no Calamares
echo.

pause
