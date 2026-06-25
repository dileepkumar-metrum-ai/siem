# Wazuh SIEM — One-Command Installer

Automated setup of a full Wazuh security stack on Ubuntu 24.04:
- **Wazuh Manager** — collects and analyzes security events from agents
- **Wazuh Indexer** — stores all events and alerts (OpenSearch-based)
- **Wazuh Dashboard** — web UI for alerts, agents, vulnerabilities, compliance

---

## Requirements

| What | Minimum |
|---|---|
| OS | Ubuntu 24.04 LTS |
| RAM | 4 GB (8 GB recommended) |
| Disk | 50 GB |
| AWS Security Group (inbound) | `443`, `1514`, `1515` open |

### Open these ports in AWS EC2 → Security Groups → Inbound rules

| Port | Protocol | Purpose |
|---|---|---|
| `443` | TCP | Dashboard (browser access) |
| `1514` | TCP | Agent data |
| `1515` | TCP | Agent enrollment |

---

## Install

```bash
git clone https://github.com/YOUR_USERNAME/wazuh-setup
cd wazuh-setup
sudo bash install.sh
```

Takes ~3 minutes. At the end you'll see:

```
=========================================
 Wazuh installed successfully!
=========================================
 Dashboard : https://<your-ip>
 Username  : admin
 Password  : admin

 To add a Windows agent, run:
   bash add-agent.sh <agent-name>
=========================================
```

---

## Access the Dashboard

Open your browser and go to:
```
https://<your-aws-public-ip>
```

Accept the SSL warning (self-signed certificate) and login:
- **Username:** `admin`
- **Password:** `admin`

---

## Connect a Windows Agent

### Step 1 — Generate an auth key (on the server)

```bash
sudo bash add-agent.sh my-laptop
```

This prints a long base64 key. Copy it.

### Step 2 — Install the agent on Windows

Download the Wazuh agent installer from:
```
https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.1-1.msi
```

Run the installer, or install silently via PowerShell (as Administrator):

```powershell
msiexec.exe /i wazuh-agent-4.9.1-1.msi /q
```

### Step 3 — Configure the agent

Open **Wazuh Agent** from the Start menu and fill in:

| Field | Value |
|---|---|
| Manager IP | Your AWS public IP |
| Authentication key | The key from Step 1 |

Click **Save** → **Manage → Start**

### Step 4 — Verify connection (on the server)

```bash
sudo /var/ossec/bin/agent_control -l
```

You should see your agent listed as `Active`.

---

## What the Agent Collects from Windows

| Source | What |
|---|---|
| Windows Event Log (Security) | Logins, failed passwords, privilege use |
| Windows Event Log (System) | Service crashes, driver errors |
| Windows Event Log (Application) | App errors and warnings |
| File Integrity Monitoring | Changes to System32, registry, startup folder |
| Registry Monitoring | Persistence keys (Run, RunOnce, Services) |
| Syscollector | Installed software, running processes, open ports |
| SCA | CIS benchmark compliance checks |
| Vulnerability Scanner | CVE matches against installed packages |

---

## Troubleshooting

**Agent shows "Never connected"**
→ Ports 1514/1515 are likely blocked. Check AWS Security Group inbound rules.

**Dashboard not loading**
→ Port 443 is likely blocked. Check AWS Security Group inbound rules.

**Manager not starting**
→ Check logs: `sudo tail -50 /var/ossec/logs/ossec.log`

**Indexer not starting**
→ Check logs: `sudo journalctl -u wazuh-indexer -n 50`
