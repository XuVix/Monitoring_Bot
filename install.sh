#!/bin/bash

usage() {
    echo "Usage: $0 BOT_TOKEN CHAT_ID [SERVER_NAME] [DELAY] [LOG_STATUS] [PERCENTAGE]"
    exit 1
}

if [[ $EUID -ne 0 ]]; then
    clear
    echo "You should run this script with root!"
    echo "Use sudo -i to change user to root"
    exit 1
fi

if [ "$#" -lt 2 ]; then
    usage
fi

BOT_TOKEN=$1
CHAT_ID=$2
SERVER_NAME=${3:-⚡️XuVix}

DELAY=${4:-30}
LOG_STATUS=${5:-3}
PERCENTAGE=${6:--50}

get_Variable (){
    echo "Enter DELAY (in minutes):"
    read DELAY
    echo "Enter LOG_STATUS (1=Log, 2=Warn, 3=Log-Warn):"
    read LOG_STATUS
    echo "Enter PERCENTAGE (-100 to 0):"
    read PERCENTAGE
}

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
