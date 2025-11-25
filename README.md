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

## 🚀 One-Click Install

```bash
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

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

# Daemon mode
node lumen-daemon.js check    # One-time check
node lumen-daemon.js review   # Review suggestions
./install-daemon.sh           # Install as service
```

## 📚 Documentation

- **[GUIDE.md](GUIDE.md)** - Complete walkthrough
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical details
- **[lumenbridge.md](lumenbridge.md)** - API reference

## 🌟 What Makes This Special

**Lumen Bridge as an Agent OS** - Multiple AI agents coordinate to monitor, research, plan, and optimize your system autonomously while you stay in complete control.

## 📝 License

MIT © [Gregory Ward (CodenLighten)](https://github.com/codenlighten)

---

**🌉 This is Lumen Bridge as "a little OS for agents"**
