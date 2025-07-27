# 🛰 Monitoring_Bot

A simple yet powerful **Telegram-based server monitoring bot** that reports **network usage** (upload/download) periodically or when a drop in activity is detected.

> ⚡️ Made by [@XuVixC](https://t.me/XuVixC)

---

## 📌 Features

- Custom monitoring interval (1–1440 minutes)
- Traffic drop alert (based on percentage)
- Log mode, Warn mode, or both
- HTTP Proxy support (optional)
- Auto setup with `systemd`
- Written in Python using:
  - `python-telegram-bot`
  - `psutil`
  - `schedule`

---

## 🚀 Installation

```bash
bash <(curl -sSL https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/install.sh)
```

You'll be asked to enter:
- Your bot token
- Telegram chat ID
- Server name
- Delay in minutes
- Log mode:
  - `1 = Log only`
  - `2 = Warn only`
  - `3 = Log + Warn`
- Drop percentage (for warn mode)
- Optional HTTP proxy (e.g. `http://ip:port`)

---

## 🛠 Menu Options

You can re-run the installer to:
- Reinstall or update
- Check status
- Restart the bot
- Uninstall the bot
- View live logs

---

## ⚙️ Configuration Example

Located at `/opt/Monitoring_Bot/config.py`:

```python
BOT_TOKEN = "123456:ABCDEF..."
CHAT_ID = "123456789"
SERVER_NAME = "⚡️XuVix"
DELAY = 30
LOG_STATUS = 3
PERCENTAGE = -50
HTTP_PROXY = "http://127.0.0.1:1080"
```

---

## 📦 Dependencies

Installer handles everything:
- `python3`, `pip`, `venv`, `curl`
- Python packages:
  - `python-telegram-bot==13.7`
  - `psutil`
  - `schedule`
  - `urllib3==1.26.15`

---

## 🧰 Requirements

- Debian/Ubuntu with `apt`
- Python 3.6+
- Root access (`sudo`)

---

## 📝 License

MIT © [XuVix](https://github.com/XuVix)

---

## 🙋‍♂️ Support

Telegram: [@XuVixC](https://t.me/XuVixC)
