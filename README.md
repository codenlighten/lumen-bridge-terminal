# Lumen Bridge Terminal

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node Version](https://img.shields.io/badge/node-%3E%3D18-brightgreen.svg)](https://nodejs.org)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-orange.svg)](https://ubuntu.com)

> 🌉 **An autonomous agent operating system for your Ubuntu laptop**

Transform your Ubuntu workstation into a self-aware, self-optimizing system powered by [Lumen Bridge](https://lumenbridge.xyz)'s multi-agent ecosystem.

## ✨ Features

- 🤖 **Autonomous Monitoring** - Background daemon checks system health every hour
- 🔍 **Multi-Agent Intelligence** - Coordinates SearchAgent, TerminalAgent, CodeGenerator, and more
- 🛡️ **Safety First** - Human approval required, full transparency, complete control
- 📊 **System Optimization** - Detects memory pressure, disk usage, package updates, Docker cleanup
- 🎯 **Custom Specialists** - Register domain-specific agents for your workflows
- 💻 **Interactive Mode** - Give high-level tasks to AI agents via CLI
- 📝 **Full Logging** - Every action tracked, reasoned, and cryptographically signed
- 🧠 **Self-Learning** - Memory API learns from past optimizations to improve over time
- 📋 **Task Tracking** - Long-term optimization goals tracked across months
- 💾 **Config Backup** - Automatic backup before modifying system files
- 🔧 **Custom Scripts** - CodeGenerator creates tailored optimization scripts with rollback

## 🚀 One-Click Install

```bash
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

**New in v2.0:**

- ✨ Enhanced installer with progress indicators
- 🔍 WSL2/WSL automatic detection
- 🐚 Multi-shell support (bash, zsh, fish)
- 🏥 Post-install health checks
- 🔄 Automatic retry logic for network operations
- 📋 Comprehensive error messages with troubleshooting tips

Or manual installation:

```bash
git clone https://github.com/codenlighten/lumen-bridge-terminal.git ~/lumen-terminal
cd ~/lumen-terminal
chmod +x install.sh
./install.sh
```

## 🎯 Quick Start

```bash
cd ~/lumen-terminal

# Interactive optimization
node terminal-optimizer.js "optimize my dev environment"

# Configuration management
node config.js setup              # Interactive setup
node config.js show               # View current config
node config.js set daemon.checkInterval 1800  # 30 min checks

# Daemon mode
node lumen-daemon.js check        # One-time check
node lumen-daemon.js review       # Review suggestions
./install-daemon.sh               # Install as service

# Diagnostics & troubleshooting
./diagnose.sh                     # Run full system diagnostic
./status.sh                       # Quick status check

# Uninstall
./uninstall.sh                    # Clean removal
```

## 📚 Documentation

- **[GUIDE.md](GUIDE.md)** - Complete walkthrough
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical details
- **[lumenbridge.md](lumenbridge.md)** - API reference

## 🌟 What Makes This Special

**Lumen Bridge as an Agent OS** - Multiple AI agents coordinate to monitor, research, plan, and optimize your system autonomously while you stay in complete control.

### 🧠 Advanced Capabilities

**Self-Learning System**

- Memory API stores every optimization outcome
- Learns from failures to avoid repeating mistakes
- Personalizes recommendations based on your system history

**Dynamic Script Generation**

- CodeGenerator creates custom optimization scripts on-the-fly
- Tailored to your specific hardware and software configuration
- Includes automatic rollback and error recovery

**Long-Term Tracking**

- Task Management API tracks optimization goals across months
- Monitors completion rates and system improvements
- Recurring optimization tasks for continuous improvement

**Safe Config Management**

- File Operations API backs up configs before modifications
- Maintains version history of system configurations
- Automatic restoration on failures

## 📝 License

MIT © [Gregory Ward (CodenLighten)](https://github.com/codenlighten)

---

**🌉 This is Lumen Bridge as "a little OS for agents"**
