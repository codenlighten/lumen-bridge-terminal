# Fresh Ubuntu Droplet Quick Start

> 🚀 **Deploy Lumen Bridge on a brand new Ubuntu server in under 5 minutes**

## Prerequisites

- Fresh Ubuntu 20.04+ droplet/VPS/VM (DigitalOcean, AWS, Linode, etc.)
- Root or sudo access
- SSH access to the server

## Installation Steps

### 1. SSH into your droplet

```bash
ssh root@your-droplet-ip
# or
ssh youruser@your-droplet-ip
```

### 2. One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

That's it! The installer will:

- ✅ Update package lists
- ✅ Install essential packages (curl, wget, git, etc.)
- ✅ Configure locale if needed
- ✅ Install Node.js 20 LTS
- ✅ Install useful utilities (tree, htop, etc.)
- ✅ Clone the Lumen Bridge repository
- ✅ Set up environment variables
- ✅ Optionally install as a system service
- ✅ Run post-install health checks

### 3. Verify installation

```bash
cd ~/lumen-terminal
./diagnose.sh
```

## Common Droplet Scenarios

### Scenario 1: Brand New Ubuntu 22.04 Droplet

```bash
# First login - everything is installed automatically
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

### Scenario 2: Minimal Ubuntu Installation

```bash
# The installer detects missing packages and installs them
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

### Scenario 3: Existing Ubuntu Server

```bash
# Works alongside existing setup - won't conflict
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

## Post-Installation

### Enable Daemon for Always-On Monitoring

```bash
cd ~/lumen-terminal
sudo systemctl enable lumen-daemon
sudo systemctl start lumen-daemon

# Check status
sudo systemctl status lumen-daemon
```

### View Logs

```bash
# Follow daemon logs
journalctl -u lumen-daemon -f

# View application logs
tail -f ~/.lumen-daemon.log
```

### Configure Daemon Check Interval

```bash
cd ~/lumen-terminal

# Interactive setup
node config.js setup

# Or set directly (e.g., check every 30 minutes)
node config.js set daemon.checkInterval 1800
```

## Droplet-Specific Tips

### 1. **DigitalOcean Droplets**

- Works on all sizes (even $6/month 1GB droplets)
- Enable weekly backups for peace of mind
- Consider enabling monitoring in DO dashboard

### 2. **AWS EC2 Instances**

- Works on Ubuntu AMIs
- Ensure security group allows outbound HTTPS (443)
- Use IAM roles if integrating with AWS services

### 3. **Linode VPS**

- Works on all Linode plans
- Consider using block storage for logs if running 24/7

### 4. **Google Cloud Compute**

- Works on e2-micro free tier
- Ensure firewall rules allow outbound connections

### 5. **Minimal/Containerized Environments**

- If locale errors occur, installer fixes them automatically
- If systemd isn't available, run manually: `node lumen-daemon.js start`

## Security Best Practices for Droplets

### 1. Keep system updated

```bash
# Let Lumen daemon help with this!
node lumen-daemon.js check
# It will detect package updates and offer to apply them
```

### 2. Configure firewall (if not done)

```bash
# Basic UFW setup
sudo ufw allow OpenSSH
sudo ufw enable
```

### 3. Review daemon permissions

```bash
# Daemon runs as your user, not root
# Check what it's allowed to do:
cat ~/.lumen-config.json
```

### 4. Enable auto-cleanup

```bash
node config.js set daemon.enabledOptimizations.diskCleanup true
node config.js set daemon.enabledOptimizations.dockerPrune true
```

## Troubleshooting Fresh Droplets

### Issue: "locale" warnings during installation

**Solution:** The installer automatically fixes this. If you see warnings, they're harmless.

### Issue: "cannot resolve hostname"

**Solution:**

```bash
# Check DNS
cat /etc/resolv.conf

# Try alternate DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### Issue: Package installation fails

**Solution:**

```bash
# Clear package cache and retry
sudo apt-get clean
sudo apt-get update
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

### Issue: Node.js version mismatch

**Solution:** The installer handles this automatically. If issues persist:

```bash
# Remove old Node.js
sudo apt-get remove nodejs
sudo apt-get autoremove

# Reinstall
curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
```

## Running in Background on Droplets

### Option 1: Systemd Service (Recommended)

```bash
cd ~/lumen-terminal
./install-daemon.sh
sudo systemctl enable lumen-daemon
sudo systemctl start lumen-daemon
```

### Option 2: Screen Session

```bash
screen -S lumen
cd ~/lumen-terminal
node lumen-daemon.js start
# Press Ctrl+A, then D to detach

# Reattach later
screen -r lumen
```

### Option 3: tmux Session

```bash
tmux new -s lumen
cd ~/lumen-terminal
node lumen-daemon.js start
# Press Ctrl+B, then D to detach

# Reattach later
tmux attach -t lumen
```

## Resource Usage on Small Droplets

### Minimum Requirements

- **RAM:** 512MB (1GB recommended)
- **Disk:** 2GB free space
- **CPU:** 1 core is plenty

### Typical Resource Usage

- **Idle:** ~50-80MB RAM
- **Active check:** ~100-150MB RAM
- **CPU:** <5% during idle, 10-30% during optimization

### For 512MB Droplets

```bash
# Reduce check frequency to save resources
node config.js set daemon.checkInterval 7200  # Every 2 hours
```

## Monitoring Your Droplet

```bash
# Quick status check
cd ~/lumen-terminal
./status.sh

# Full diagnostic
./diagnose.sh

# View recent optimizations
node lumen-daemon.js review

# Check what Lumen is doing right now
tail -f ~/.lumen-daemon.log
```

## Uninstallation

```bash
cd ~/lumen-terminal
./uninstall.sh
```

Clean removal with options to preserve logs/state or remove everything.

## Support & Resources

- **Documentation:** See README.md, GUIDE.md, ARCHITECTURE.md in install directory
- **Logs:** `~/.lumen-daemon.log`
- **Configuration:** `~/.lumen-config.json`
- **State:** `~/.lumen-daemon-state.json`

## Pro Tips for Droplet Usage

1. **Set up weekly reports**

   ```bash
   node config.js set daemon.notifyOn.dailySummary true
   ```

2. **Auto-approve safe optimizations** (after testing)

   ```bash
   node config.js set daemon.autoApprove true
   ```

3. **Monitor multiple droplets**

   - Install on each droplet
   - Each maintains its own state
   - Coordinate via Lumen Bridge API

4. **Backup your config**
   ```bash
   cp ~/.lumen-config.json ~/lumen-config-backup.json
   ```

---

**🌉 Your droplet now has an autonomous agent OS!**

Questions? Issues? Check the main [README.md](README.md) or run `./diagnose.sh`
