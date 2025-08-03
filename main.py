import psutil
import time
import re
import collections
import requests
from telegram import Bot, ParseMode
from telegram.ext.updater import Request
from config import BOT_TOKEN, CHAT_ID, SERVER_NAME, DELAY, PERCENTAGE, LOG_STATUS, PORT_MONITORING, SYS_MONITORING, CLOUDFLARE_WORKER_URL, HTTP_PROXY

lsdt_sent, lsdt_recv = 0, 0

L_STATUS = "---"
if LOG_STATUS == 1:
    L_STATUS = "Log"
elif LOG_STATUS == 2:
    L_STATUS = "Warn"
elif LOG_STATUS == 3:
    L_STATUS = "Log-Warn"

def parse_proxy_url(proxy_url: str) -> tuple[str, str | None, str | None]:
    """
    Regex pattern to match and capture the username, password, and the rest of the proxy URL
    Args:
        proxy_url (str): pass raw proxy url and process it

    Returns:
        tuple[str, str | None, str | None]
    """
    pattern = re.compile(r'http://(?:(?P<username>[^:]+):(?P<password>[^@]+)@)?(?P<proxy_url>.*)')
    match = pattern.match(proxy_url)

    if match:
        proxy_details = match.groupdict()
        return proxy_details['proxy_url'], proxy_details.get('username'), proxy_details.get('password')
    return proxy_url, None, None

# added HTTP Proxy support
if HTTP_PROXY:
    proxy_url, PROXY_USERNAME, PROXY_PASSWORD = parse_proxy_url(HTTP_PROXY)
    
    if PROXY_USERNAME and PROXY_PASSWORD:
        request = Request(proxy_url=f"http://{proxy_url}",
                          urllib3_proxy_kwargs={
                              'username': PROXY_USERNAME,
                              'password': PROXY_PASSWORD,
                          })
    else:
        request = Request(proxy_url=HTTP_PROXY)

    bot = Bot(token=BOT_TOKEN, request=request)
else:
    bot = Bot(token=BOT_TOKEN)

def format_size(size_in_mb):
    return f"{size_in_mb / 1024:.2f}GB" if size_in_mb >= 1024 else f"{size_in_mb:.2f}MB"

def get_connections():
    connections = psutil.net_connections(kind='inet')
    port_data = collections.defaultdict(lambda: {'ips': [], 'proto': 'UNK'})

    for conn in connections:
        if not conn.raddr:
            continue

        lport = conn.laddr.port
        raddr = conn.raddr.ip

        if conn.type == 1:
            proto = 'TCP'
        elif conn.type == 2:
            proto = 'UDP'
        else:
            proto = 'UNK'

        key = (lport, proto)
        port_data[key]['ips'].append(raddr)
        port_data[key]['proto'] = proto

    if not port_data:
        return "*No active TCP/UDP connections*\n➖➖➖➖➖➖➖➖➖➖\n"

    totals = {'TCP': {'conn': 0, 'ips': set()}, 'UDP': {'conn': 0, 'ips': set()}}

    for (port, proto), data in port_data.items():
        totals.setdefault(proto, {'conn': 0, 'ips': set()})
        totals[proto]['conn'] += len(data['ips'])
        totals[proto]['ips'].update(data['ips'])

    lines = ["*Type*    *Port*          *Conn*         *IPs*"]

    for proto in ['TCP', 'UDP']:
        lines.append(f"`{proto:<5} ALL     {totals[proto]['conn']:<7} {len(totals[proto]['ips'])}`")

    filtered_ports = [
        (port, proto, len(data['ips']), len(set(data['ips'])))
        for (port, proto), data in port_data.items()
    ]

    sorted_ports = sorted(filtered_ports, key=lambda x: x[2], reverse=True)

    top_ports = sorted_ports[:7]

    for port, proto, conn_count, ip_count in top_ports:
        lines.append(f"`{proto:<5} {port:<7} {conn_count:<7} {ip_count}`")
    
    portt = sum(1 for data in port_data.values() if len(data['ips']) > 1)
    if (portt - 7) > 0:
        lines.append(f"`+ {(portt) - 7} Ports with >1 conn`")
        
    if (len(sorted_ports) - 7) > 0:
        lines.append(f"`+ {len(sorted_ports) - 7} more active ports`")
        
    return "\n".join(lines) + "\n➖➖➖➖➖➖➖➖➖➖\n"

def get_system_usage():
    cpu = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory()
    disk = psutil.disk_usage("/")

    ram_used = ram.used / (1024 ** 3)
    ram_total = ram.total / (1024 ** 3)
    ram_percent = ram.percent

    disk_used = disk.used / (1024 ** 3)
    disk_total = disk.total / (1024 ** 3)
    disk_percent = disk.percent

    sys = [
        f"*CPU  :* `{cpu:.1f}%`",
        f"*RAM :* `{ram_used:.1f}GB / {ram_total:.1f}GB  ({ram_percent:.0f}%)`",
        f"*Disk  :* `{disk_used:.1f}GB / {disk_total:.1f}GB  ({disk_percent:.0f}%)`",
        "➖➖➖➖➖➖➖➖➖➖"
    ]

    return "\n".join(sys)
 
def get_network_usage():
    global last_net_io
    net_io = psutil.net_io_counters()
    
    dt_sent = (net_io.bytes_sent - last_net_io.bytes_sent) / (1024 * 1024)
    dt_recv = (net_io.bytes_recv - last_net_io.bytes_recv) / (1024 * 1024)
    
    last_net_io = net_io
    
    return dt_sent, dt_recv
    
def send_msg(msg):
    if CLOUDFLARE_WORKER_URL:
        payload = {
            "token": BOT_TOKEN,
            "chat_id": CHAT_ID,
            "text": msg
        }
        requests.post(CLOUDFLARE_WORKER_URL, json=payload)
    else:
        bot.send_message(CHAT_ID, msg, parse_mode=ParseMode.MARKDOWN)
      
def send():
    global lsdt_sent, lsdt_recv, L_STATUS
    dt_sent, dt_recv = get_network_usage()

    sent_diff = 100 * ((dt_sent - lsdt_sent) / dt_sent) if lsdt_sent != 0 else 0
    recv_diff = 100 * ((dt_recv - lsdt_recv) / dt_recv) if lsdt_recv != 0 else 0

    lsdt_sent, lsdt_recv = dt_sent, dt_recv

    dt_sent_str = format_size(dt_sent)
    dt_recv_str = format_size(dt_recv)

    conn_table = get_connections() if PORT_MONITORING == 1 else ""
    sys_table = get_system_usage() if SYS_MONITORING == 1 else ""

    msg = (
        f"‼️ #Warning\n"
        f"`{SERVER_NAME}`\n"
        f"➖➖➖➖➖➖➖➖➖➖\n"
        f"*ULoad :* `{dt_sent_str}`  `{sent_diff:.2f}%`\n"
        f"*DLoad :* `{dt_recv_str}`  `{recv_diff:.2f}%`\n"
        f"➖➖➖➖➖➖➖➖➖➖\n"
    )
    
    if sys_table:
        msg += f"{sys_table}\n"
    
    if conn_table:
        msg += f"{conn_table}"

    msg += f"`[{DELAY} min]`  `[{PERCENTAGE}%]`  `[{L_STATUS}]`\n"

    if LOG_STATUS in [2, 3] and (sent_diff <= PERCENTAGE or recv_diff <= PERCENTAGE):
        send_msg(msg)

    elif LOG_STATUS in [1, 3]:
        msg = (
            f"`{SERVER_NAME}`\n"
            f"➖➖➖➖➖➖➖➖➖➖\n"
            f"*ULoad :* `{dt_sent_str}`\n"
            f"*DLoad :* `{dt_recv_str}`\n"
            f"➖➖➖➖➖➖➖➖➖➖\n"
        )
        if sys_table:
            msg += f"{sys_table}\n"
        if conn_table:
            msg += f"{conn_table}"
        msg += f"`[{DELAY} min]`  `[{L_STATUS}]`\n"

        send_msg(msg)

def main():
    global last_net_io
    last_net_io = psutil.net_io_counters()

    msg = (
        f"`{SERVER_NAME}`\n"
        f"- Delay: `{DELAY} min`\n"
        f"- Percentage: `{PERCENTAGE} %`\n"
        f"- PORT Monitoring: `{PORT_MONITORING}`\n"
        f"- SYS Monitoring: `{SYS_MONITORING}`\n"
        f"- Mode: `{L_STATUS}`\n\n"
        f"✅ *Monitoring Bot is running!*\n\n📡 Channel: [@XuVixC](https://t.me/XuVixC)\n📦 Source: [GitHub](https://github.com/XuVix/Monitoring_Bot)"
    )
    send_msg(msg)

    last_sent_minute = -1

    while True:
        now = time.localtime()
        total_minutes = now.tm_hour * 60 + now.tm_min 

        if total_minutes % DELAY == 0 and total_minutes != last_sent_minute:
            send()
            last_sent_minute = total_minutes

        time.sleep(1)

if __name__ == "__main__":
    main()
