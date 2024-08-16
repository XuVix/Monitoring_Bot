#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    clear
    echo "You should run this script with root!"
    echo "Use sudo -i to change user to root"
    exit 1
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 BOT_TOKEN CHAT_ID"
    exit 1
fi

BOT_TOKEN=$1
CHAT_ID=$2

clear
echo "---------------------------------------------------"
read -p "Enter SERVER_NAME [default: ⚡️XuVix]: " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-⚡️XuVix}

echo "---------------------------------------------------"
while true; do
    read -p "Enter DELAY (in minutes) [default: 30, range: 1-1440]: " DELAY
    DELAY=${DELAY:-30}
    if [[ $DELAY =~ ^[0-9]+$ ]] && ((DELAY >= 1 && DELAY <= 1440)); then
        break
    else
        echo "Invalid input. Please enter a valid DELAY between 1 and 1440 minutes."
    fi
done

echo "---------------------------------------------------"
while true; do
    read -p "Enter LOG_STATUS (1=Log, 2=Warn, 3=Log-Warn) [default: 3]: " LOG_STATUS
    LOG_STATUS=${LOG_STATUS:-3}
    if [[ $LOG_STATUS =~ ^[1-3]$ ]]; then
        break
    else
        echo "Invalid input. Please enter 1 for Log, 2 for Warn, or 3 for Log-Warn."
    fi
done

echo "---------------------------------------------------"
if [[ $LOG_STATUS -ne 1 ]]; then
    while true; do
        read -p "Enter PERCENTAGE (-100 to 0) [default: -50]: " PERCENTAGE
        PERCENTAGE=${PERCENTAGE:--50}
        if [[ $PERCENTAGE =~ ^-?[0-9]+$ ]] && ((PERCENTAGE >= -100 && PERCENTAGE <= 0)); then
            break
        else
            echo "Invalid input. Please enter a valid PERCENTAGE between -100 and 0."
        fi
    done
else
    PERCENTAGE=0
fi

SERVICE_NAME="Monitoring_Bot.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
INSTALL_DIR="/opt/Monitoring_Bot"

cleanup_old_installation() {
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "Stopping the existing service..."
        sudo systemctl stop $SERVICE_NAME
    fi

    if [ -f "$SERVICE_PATH" ]; then
        echo "Disabling and removing the existing service..."
        sudo systemctl disable $SERVICE_NAME
        sudo rm "$SERVICE_PATH"
    fi

    if [ -d "$INSTALL_DIR" ]; then
        echo "Removing old installation directory..."
        sudo rm -rf "$INSTALL_DIR"
    fi

    sudo systemctl daemon-reload
}

install_dependencies() {
    echo "Updating package lists and installing dependencies..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip curl
}

setup_python_environment() {
    echo "Creating installation directory and setting up virtual environment..."
    sudo mkdir -p $INSTALL_DIR
    python3 -m venv $INSTALL_DIR/venv
    source $INSTALL_DIR/venv/bin/activate

    echo "Upgrading pip and installing Python packages..."
    pip install --upgrade pip
    pip uninstall -y python-telegram-bot || true
    pip install "python-telegram-bot==13.7" "psutil>=5.9.0" "schedule>=1.1.0"
}

download_script_and_create_config() {
    echo "Downloading the latest Python script..."
    curl -sSLo $INSTALL_DIR/main.py https://raw.githubusercontent.com/XuVix/Monitoring_Bot/main/main.py

    echo "Creating configuration file..."
    cat <<EOF > $INSTALL_DIR/config.py
BOT_TOKEN = "${BOT_TOKEN}"
CHAT_ID = "${CHAT_ID}"
SERVER_NAME = "${SERVER_NAME}"
DELAY = ${DELAY}
LOG_STATUS = ${LOG_STATUS}
PERCENTAGE = ${PERCENTAGE}
EOF
}

setup_systemd_service() {
    echo "Creating systemd service file..."
    cat <<EOF | sudo tee $SERVICE_PATH > /dev/null
[Unit]
Description=Telegram Monitoring Bot for ${SERVER_NAME}
After=network.target

[Service]
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/main.py
Restart=always
User=root
WorkingDirectory=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

    echo "Reloading systemd daemon and enabling the service..."
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
}

cleanup_old_installation
install_dependencies
setup_python_environment
download_script_and_create_config
setup_systemd_service

echo "Telegram Monitoring Bot is now installed and running for ${SERVER_NAME} "
echo "DELAY=${DELAY} min, LOG_STATUS=${LOG_STATUS}, PERCENTAGE=${PERCENTAGE}. "
