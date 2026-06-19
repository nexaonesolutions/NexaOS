// ==============================================================================
//  NEXA OS - AGS BAR CONFIG (TypeScript)
//  Aylur's Gtk Shell — Barra Superior Modular (macOS Killer Style)
//  Salvar em: airootfs/etc/skel/.config/ags/config.ts
// ==============================================================================

import App from "resource:///com/github/Aylur/ags/app.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import { Variable, GLib } from "resource:///com/github/Aylur/ags/variables.js";

// --- IMPORTAÇÕES DOS SERVIÇOS NATIVOS DO AGS ---
const Hyprland   = (await import("resource:///com/github/Aylur/ags/service/hyprland.js")).default;
const SystemTray = (await import("resource:///com/github/Aylur/ags/service/systemtray.js")).default;
const Network    = (await import("resource:///com/github/Aylur/ags/service/network.js")).default;
const Battery    = (await import("resource:///com/github/Aylur/ags/service/battery.js")).default;

// ==============================================================================
// 1. MÓDULO ESQUERDO: Workspaces do Hyprland
// ==============================================================================
const Workspaces = () =>
    Widget.Box({
        class_name: "workspaces",
        children: Hyprland.bind("workspaces").transform((workspaces) =>
            workspaces
                .sort((a, b) => a.id - b.id)
                .map((ws) =>
                    Widget.Button({
                        on_clicked: () => Hyprland.sendMessage(`dispatch workspace ${ws.id}`),
                        child: Widget.Label({ label: `${ws.id}` }),
                        class_name: Hyprland.bind("active-workspace").transform(
                            (active) => (active.id === ws.id ? "workspace active" : "workspace")
                        ),
                    })
                )
        ),
    });

// ==============================================================================
// 2. MÓDULO CENTRAL: Relógio com Data
// ==============================================================================
const clock = Variable("", {
    poll: [1000, "date '+%H:%M  %a %d %b'"],
});

const Clock = () =>
    Widget.Label({
        class_name: "clock",
        label: clock.bind(),
    });

// ==============================================================================
// 3. MÓDULO DIREITO: System Tray + Rede + Bateria
// ==============================================================================

// Ícones de rede
const NetworkIcon = () =>
    Widget.Icon({
        class_name: "network-icon",
        icon: Network.wifi.bind("icon-name"),
        tooltip_text: Network.wifi.bind("ssid"),
    });

// Ícone e percentual da bateria
const BatteryLabel = () =>
    Widget.Box({
        class_name: "battery",
        children: [
            Widget.Icon({
                icon: Battery.bind("icon-name"),
            }),
            Widget.Label({
                label: Battery.bind("percent").transform((p) => `${p}%`),
                class_name: Battery.bind("charging").transform(
                    (charging) => (charging ? "charging" : "")
                ),
            }),
        ],
        visible: Battery.bind("available"),
    });

// Ícones da Bandeja do Sistema
const SysTray = () =>
    Widget.Box({
        class_name: "systray",
        children: SystemTray.bind("items").transform((items) =>
            items.map((item) =>
                Widget.Button({
                    child: Widget.Icon({ icon: item.bind("icon"), size: 16 }),
                    on_primary_click: (_, event) => item.activate(event),
                    on_secondary_click: (_, event) => item.openMenu(event),
                    tooltip_markup: item.bind("tooltip-markup"),
                })
            )
        ),
    });

// ==============================================================================
// COMPOSIÇÃO DA BARRA SUPERIOR
// ==============================================================================
const TopBar = (monitor: number = 0) =>
    Widget.Window({
        name: `bar-${monitor}`,
        class_name: "top-bar",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        margins: [8, 12, 0, 12],
        child: Widget.CenterBox({
            class_name: "bar-inner",
            start_widget: Widget.Box({
                class_name: "bar-left",
                children: [Workspaces()],
            }),
            center_widget: Widget.Box({
                class_name: "bar-center",
                children: [Clock()],
            }),
            end_widget: Widget.Box({
                class_name: "bar-right",
                hpack: "end",
                children: [SysTray(), NetworkIcon(), BatteryLabel()],
            }),
        }),
    });

// ==============================================================================
// CONFIGURAÇÃO FINAL DO APP
// ==============================================================================
App.config({
    style: App.configDir + "/style.css",
    windows: [TopBar(0)],
});
