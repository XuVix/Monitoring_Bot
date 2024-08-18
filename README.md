# Monitoring_Bot
A Simple Bot for Monitoring Data Usage

## Installation and Usage

To install and manage the Monitoring Bot, use the following command:

```bash
bash <(curl -s https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/install.sh)
```

This script provides an interactive menu with the following options:

1. Install/Reinstall
2. Check Status
3. Restart
4. Uninstall
5. Show Logs
0. Exit

## Manual Commands

If you prefer to manage the bot manually, you can use these commands:

### Check Status
```bash
sudo systemctl status Monitoring_Bot.service
```

### View Logs
```bash
sudo journalctl -u Monitoring_Bot.service -f
```

### Stop and Disable the Service
```bash
sudo systemctl stop Monitoring_Bot.service
sudo systemctl disable Monitoring_Bot.service
sudo rm /etc/systemd/system/Monitoring_Bot.service
sudo systemctl daemon-reload
```

### Remove the Installation Directory
```bash
sudo rm -rf /opt/Monitoring_Bot
```

<p align="center">
  <a target="_blank" href="https://t.me/XuvixC">
    <img alt="Telegram Badge" src="https://img.shields.io/badge/XuVixChanel-Telegramlink?style=1&logo=telegram&logoColor=white&color=blue&link=https%3A%2F%2Ft.me%2FXuVix&link=https%3A%2F%2Ft.me%2FXuVix">
  </a>
</p>

