# 🛰️ Monitoring_Bot

A lightweight yet powerful **Telegram-based server monitoring bot** that watches your system's **network usage, system resources, and open connections** — with smart alerts and full automation.

> ⚡ Built with love by [@XuVixC](https://t.me/XuVixC)

---

## 🧠 Features

✅ Network traffic monitoring (TX/RX)  
✅ CPU, RAM, and Disk usage checks (optional)  
✅ Top active TCP connections by port  
✅ Alerts when traffic drops below a threshold  
✅ Proxy & Cloudflare Worker support  
✅ Auto setup with `systemd` and virtualenv  
✅ Modular configuration & update-friendly  
✅ Designed for multiple servers — one bot, many agents!

---

## 🚀 Installation

Run the following one-liner:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/install.sh)
```

🧩 The installer will:
- Install all required packages
- Set up a virtual environment
- Download the latest version of the bot
- Create a `systemd` service for auto-start
- Prompt you to configure:

| Parameter       | Description                                                     |
|----------------|------------------------------------------------------------------|
| Bot Token       | From [@BotFather](https://t.me/BotFather)                       |
| Chat ID         | Telegram user or group ID From [@myidbot](https://t.me/myidbot) |
| Server Name     | Friendly name to identify your server                           |
| Delay (min)     | Interval between checks (e.g., `10`)                            |
| Drop % Alert    | Warn if traffic drops below X% (e.g., `-50`)                    |
| Log Status      | `1=Log only`, `2=Warn only`, `3=Log + Warn`                     |
| HTTP Proxy      | Optional (e.g., `http://127.0.0.1:1080`) `Server Iran`          |
| Worker URL      | Optional Cloudflare Worker endpoint      `Server Iran`          |

---

## ⚙️ Configuration

The bot stores its settings at:

```
/opt/Monitoring_Bot/config.py
```

Sample config:
```python
BOT_TOKEN = "123456:ABCDEF..."
CHAT_ID = "123456789"
SERVER_NAME = "⚡ XuVix"
DELAY = 30
PERCENTAGE = -50
LOG_STATUS = 3
SYS_MONITORING = 1
PORT_MONITORING = 1
CLOUDFLARE_WORKER_URL = ""
HTTP_PROXY = ""
```

---

## 📊 What Gets Reported?

- ✅ TX/RX bandwidth usage
- ✅ Top 10 ports by active connections
- ✅ CPU, RAM, and Disk usage (if enabled)
- ✅ Optional drop-alert mode for low activity
- ✅ Messages sent through your Worker (optional)

---

## 🛠 Control Menu

You can re-run the installer anytime to:
- ✅ Reinstall/update the bot
- 🔁 Restart the monitoring service
- 🛑 Stop/uninstall the bot
- 📄 View live logs with `journalctl`
- ⚙️ Edit or reset the config

---

## 📦 Dependencies

These are handled automatically by the installer:

### System:
- `python3`, `pip`, `venv`, `curl`, `net-tools`, `psutil`

### Python:
- `python-telegram-bot==13.7`
- `psutil`
- `schedule`
- `urllib3==1.26.15`

---

## 🧰 Requirements

- 🐧 Debian, Ubuntu, or derivatives with `apt`
- 🔧 Python 3.6 or newer
- 🧑‍💻 Root privileges (for `systemd` & netstats)

---

## 📁 File Structure

```
/opt/Monitoring_Bot/
├── main.py
├── config.py
├── requirements.txt
└── .venv/               # Isolated Python environment
```

---

## 🧠 Support / Contact

If you need help or want to suggest improvements:

- Telegram: [@XuVixC](https://t.me/XuVixC)
- GitHub: [XuVix](https://github.com/XuVix)

---

## ⭐️ Show your support

If you find this project helpful ⭐️ Star the repository 

