#!/usr/bin/env python3
# Tolga Erok
# 26-3-2025
# Version:                  3.1a

# APP IMAGE LOCATION:      /usr/local/bin/LinuxTweaks/images/LinuxTweak.png
# APP LOCATION:            /usr/local/bin/LinuxTweaks/LinuxTweaks.py
# PYTHON ONLINE FORMATTER: https://codebeautify.org/python-formatter-beautifier#
# SYMLINK:                 sudo ln -s /usr/local/bin/LinuxTweaks/LinuxTweaks.py /usr/local/bin/linuxtweaks
# Installer:               curl -sL https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/installer.sh | sudo bash

from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QVBoxLayout,
    QLabel,
    QPushButton,
    QSystemTrayIcon,
    QMenu,
    QListWidget,
    QMessageBox,
)
from PyQt6.QtGui import QAction, QIcon
from PyQt6.QtCore import Qt, QTimer
import subprocess
import sys

# My custom systemd services to monitor
services = [
    "tolga-apply-cake-qdisc-wake.service",
    "tolga-apply-cake-qdisc.service",
    "tolga-flatpak-update.service",
]

app_icon = "/home/tolga/Documents/MEGA/Documents/LINUX/LinuxTweaks/LinuxTweak.png"
icon_amber = "🛠️"
icon_green = "✔️"
icon_red = "❌️"


def check_service_status(service):
    """Returns status icons for each service, handling 'exited' states properly"""
    try:
        # Get detailed service info
        status_output = subprocess.run(
            ["systemctl", "show", service, "--no-pager"],
            capture_output=True,
            text=True,
        ).stdout

        # Extract key status values
        active_state = next(
            (
                line.split("=")[1]
                for line in status_output.splitlines()
                if line.startswith("ActiveState=")
            ),
            "unknown",
        )
        exit_code = next(
            (
                line.split("=")[1]
                for line in status_output.splitlines()
                if line.startswith("Result=")
            ),
            "unknown",
        )

        if active_state == "active" or (
            active_state == "inactive" and exit_code == "success"
        ):
            return icon_green, " Active   "
        elif active_state == "inactive":
            return icon_red, " Inactive"
        else:
            return icon_amber, " Unknown "

    except Exception:
        return icon_red, " Error"


class LinuxTweakMonitor(QWidget):
    def __init__(self, tray_icon):
        super().__init__()
        self.tray_icon = tray_icon
        self.setWindowTitle("LinuxTweak Service Monitor")
        self.setGeometry(100, 100, 350, 300)
        self.layout = QVBoxLayout()

        # My service list
        self.service_list = QListWidget()
        self.layout.addWidget(self.service_list)

        # Buttons
        self.start_button = QPushButton("Start Service")
        self.stop_button = QPushButton("Stop Service")
        self.restart_button = QPushButton("Restart Service")
        self.layout.addWidget(self.start_button)
        self.layout.addWidget(self.stop_button)
        self.layout.addWidget(self.restart_button)

        # Button actions
        self.start_button.clicked.connect(lambda: self.manage_service("start"))
        self.stop_button.clicked.connect(lambda: self.manage_service("stop"))
        self.restart_button.clicked.connect(lambda: self.manage_service("restart"))

        self.setLayout(self.layout)
        self.refresh_status()

    def refresh_status(self):
        """Update service status in my list box"""
        self.service_list.clear()

        service_statuses = [
            (service, *check_service_status(service)) for service in services
        ]
        service_statuses.sort(key=lambda x: ("Active" not in x[2], "Disabled" in x[2]))

        for service, icon, status in service_statuses:
            self.service_list.addItem(f"{icon}{status} :  {service}")

        self.tray_icon.update_status()

    def manage_service(self, action):
        """Start/Stop/Restart my service"""
        selected_item = self.service_list.currentItem()
        if not selected_item:
            QMessageBox.warning(self, "No Service Selected", "Please select a service.")
            return

        service_name = selected_item.text().split(":")[-1].strip()

        subprocess.run(["systemctl", "daemon-reload"], check=True, capture_output=True)
        subprocess.run(["systemctl", action, service_name], capture_output=True)
        subprocess.run(
            ["systemctl", "is-enabled", service_name], check=True, capture_output=True
        )

        self.refresh_status()
        QTimer.singleShot(100, self.tray_icon.update_status)

    def closeEvent(self, event):
        """Override close event to hide window instead of quitting the app."""
        event.ignore()  # Prevent the window from closing
        self.hide()  # Hide the window instead


class LinuxTweakTray:
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.tray = QSystemTrayIcon(QIcon(app_icon))
        self.tray.setToolTip("Flatpak Service Monitor")

        if self.tray.icon().isNull():
            print("Error: Icon is invalid!")
        else:
            print("App icon loaded successfully.")

        self.menu = QMenu()
        self.show_app_action = QAction("Open Service Monitor")
        self.show_app_action.triggered.connect(self.open_app)

        self.refresh_action = QAction("Refresh")
        self.refresh_action.triggered.connect(self.update_status)

        self.exit_action = QAction("Exit")
        self.exit_action.triggered.connect(self.app.quit)

        self.menu.addAction(self.show_app_action)
        self.menu.addAction(self.refresh_action)
        self.menu.addSeparator()
        self.menu.addAction(self.exit_action)

        self.tray.setContextMenu(self.menu)
        self.tray.activated.connect(self.tray_clicked)

        self.window = LinuxTweakMonitor(self)
        self.update_status()

        # Timer for auto-refreshing the tooltip every 5 seconds
        self.tooltip_timer = QTimer()
        self.tooltip_timer.timeout.connect(self.update_tooltip)
        self.tooltip_timer.start(5000)  # 5 seconds interval

        self.tray.show()
        print("Tray shown.")

    def update_status(self):
        """Update my tray icon and group services by status"""
        service_statuses = [
            (service, *check_service_status(service)) for service in services
        ]

        active_services = [
            f"{icon}{status} : {service}"
            for service, icon, status in service_statuses
            if "Active" in status
        ]
        disabled_services = [
            f"{icon}{status} : {service}"
            for service, icon, status in service_statuses
            if "Disabled" in status
        ]
        inactive_services = [
            f"{icon}{status} : {service}"
            for service, icon, status in service_statuses
            if "Inactive" in status or "Error" in status
        ]

        tooltip_text = ""
        if active_services:
            tooltip_text += "Active services:\n" + "\n".join(active_services) + "\n\n"
        if disabled_services:
            tooltip_text += (
                "Disabled services:\n" + "\n".join(disabled_services) + "\n\n"
            )
        if inactive_services:
            tooltip_text += (
                "Inactive services:\n" + "\n".join(inactive_services) + "\n\n"
            )

        self.tray.setToolTip(tooltip_text.strip())
        self.tray.setIcon(QIcon(app_icon))

    def update_tooltip(self):
        """Auto-refresh the tooltip text every 5 seconds"""
        self.update_status()

    def tray_clicked(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.Trigger:
            self.open_app()

    def open_app(self):
        self.window.refresh_status()
        self.window.show()

    def run(self):
        self.app.exec()


if __name__ == "__main__":
    tray = LinuxTweakTray()
    tray.run()
