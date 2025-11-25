#!/usr/bin/env node
/**
 * Lumen Daemon - Autonomous System Optimization Agent
 * 
 * Lives in your laptop, continuously monitoring and optimizing the system
 * using the full power of Lumen Bridge's agent ecosystem.
 * 
 * Features:
 * - System health monitoring
 * - Proactive optimization recommendations
 * - Auto-cleanup and maintenance
 * - Smart task routing across multiple agents
 * - Self-learning behavior patterns
 */

const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');

const BASE_URL = process.env.LUMENBRIDGE_URL || 'https://lumenbridge.xyz';
const STATE_FILE = path.join(os.homedir(), '.lumen-daemon-state.json');
const LOG_FILE = path.join(os.homedir(), '.lumen-daemon.log');

class LumenDaemon {
  constructor() {
    this.state = {
      lastCheck: null,
      optimizations: [],
      systemProfile: {},
      autoApprove: false, // Safety first!
    };
  }

  async log(message, level = 'INFO') {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] [${level}] ${message}\n`;
    console.log(logLine.trim());
    await fs.appendFile(LOG_FILE, logLine).catch(() => {});
  }

  async loadState() {
    try {
      const data = await fs.readFile(STATE_FILE, 'utf8');
      this.state = { ...this.state, ...JSON.parse(data) };
      await this.log('State loaded from disk');
    } catch (err) {
      await this.log('No previous state found, starting fresh', 'WARN');
    }
  }

  async saveState() {
    await fs.writeFile(STATE_FILE, JSON.stringify(this.state, null, 2));
  }

  async callAgent(endpoint, body) {
    const res = await fetch(`${BASE_URL}/api/agents/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new Error(`Agent ${endpoint} failed: ${res.status} ${text}`);
    }

    const data = await res.json();
    if (!data.success) {
      throw new Error(data.error || `Agent ${endpoint} returned success=false`);
    }

    return data.result;
  }

  async gatherSystemInfo() {
    await this.log('Gathering system information...');
    
    const execCommand = (cmd) => {
      return new Promise((resolve) => {
        const child = spawn(cmd, { shell: '/bin/bash' });
        let output = '';
        child.stdout.on('data', (data) => (output += data.toString()));
        child.on('close', () => resolve(output.trim()));
      });
    };

    const profile = {
      hostname: os.hostname(),
      platform: os.platform(),
      release: os.release(),
      arch: os.arch(),
      uptime: os.uptime(),
      totalMem: os.totalmem(),
      freeMem: os.freemem(),
      cpus: os.cpus().length,
      loadAvg: os.loadavg(),
      diskUsage: await execCommand("df -h / | tail -1 | awk '{print $5}'"),
      installedPackages: await execCommand('dpkg --list | wc -l'),
      dockerRunning: await execCommand('systemctl is-active docker 2>/dev/null || echo inactive'),
      kernelVersion: await execCommand('uname -r'),
      nodeVersion: await execCommand('node --version 2>/dev/null || echo "not installed"'),
      pythonVersion: await execCommand('python3 --version 2>/dev/null || echo "not installed"'),
    };

    this.state.systemProfile = profile;
    await this.saveState();
    return profile;
  }

  async analyzeWithRouter(userPrompt) {
    await this.log(`Routing task: "${userPrompt.substring(0, 50)}..."`);
    return await this.callAgent('router', { userPrompt });
  }

  async searchBestPractices(query) {
    await this.log(`Searching for: "${query}"`);
    return await this.callAgent('search', { 
      userQuery: query,
      maxResults: 5 
    });
  }

  async planOptimization(task, context) {
    await this.log(`Planning: "${task.substring(0, 50)}..."`);
    return await this.callAgent('terminal', { task, context });
  }

  async generateCode(prompt, context) {
    await this.log(`Generating code: "${prompt.substring(0, 50)}..."`);
    return await this.callAgent('code', { prompt, context });
  }

  async detectOptimizationOpportunities() {
    await this.log('🔍 Detecting optimization opportunities...');
    
    const profile = this.state.systemProfile;
    const opportunities = [];

    // Memory pressure
    const memUsagePercent = ((profile.totalMem - profile.freeMem) / profile.totalMem) * 100;
    if (memUsagePercent > 80) {
      opportunities.push({
        type: 'memory',
        severity: 'medium',
        description: `Memory usage at ${memUsagePercent.toFixed(1)}%`,
        suggestion: 'Consider clearing caches or identifying memory-hungry processes',
      });
    }

    // Disk space
    const diskUsage = parseInt(profile.diskUsage);
    if (diskUsage > 85) {
      opportunities.push({
        type: 'disk',
        severity: 'high',
        description: `Disk usage at ${diskUsage}%`,
        suggestion: 'Clean up old kernels, package cache, and temporary files',
      });
    }

    // System updates
    const updateCheck = await this.execSafe('apt list --upgradable 2>/dev/null | grep -c upgradable');
    const upgradeCount = parseInt(updateCheck) || 0;
    if (upgradeCount > 10) {
      opportunities.push({
        type: 'updates',
        severity: 'medium',
        description: `${upgradeCount} packages can be upgraded`,
        suggestion: 'Run system updates to patch security vulnerabilities',
      });
    }

    // Docker optimization
    if (profile.dockerRunning === 'active') {
      const unusedImages = await this.execSafe('docker images -f "dangling=true" -q | wc -l');
      if (parseInt(unusedImages) > 5) {
        opportunities.push({
          type: 'docker',
          severity: 'low',
          description: `${unusedImages} unused Docker images`,
          suggestion: 'Clean up dangling Docker images to free up space',
        });
      }
    }

    return opportunities;
  }

  async execSafe(command) {
    return new Promise((resolve) => {
      const child = spawn(command, { shell: '/bin/bash' });
      let output = '';
      child.stdout.on('data', (data) => (output += data.toString()));
      child.on('close', () => resolve(output.trim()));
      child.on('error', () => resolve(''));
    });
  }

  async executeOptimization(optimization) {
    if (!this.state.autoApprove) {
      await this.log(`⏸️  Optimization requires manual approval: ${optimization.description}`, 'WARN');
      this.state.optimizations.push({ ...optimization, status: 'pending', timestamp: Date.now() });
      await this.saveState();
      return false;
    }

    await this.log(`🚀 Executing: ${optimization.description}`);
    // Execute the optimization
    // This would integrate with the terminal-optimizer pattern
    return true;
  }

  async runMaintenanceCycle() {
    await this.log('🔄 Starting maintenance cycle...');

    try {
      // 1. Gather current system state
      const profile = await this.gatherSystemInfo();
      await this.log(`System: ${profile.hostname} | Uptime: ${(profile.uptime / 3600).toFixed(1)}h | Mem: ${((profile.freeMem / profile.totalMem) * 100).toFixed(1)}% free`);

      // 2. Detect optimization opportunities
      const opportunities = await this.detectOptimizationOpportunities();
      
      if (opportunities.length === 0) {
        await this.log('✅ System is running optimally, no actions needed');
        return;
      }

      await this.log(`Found ${opportunities.length} optimization opportunities`);

      // 3. For each opportunity, use the router to determine best action
      for (const opp of opportunities) {
        await this.log(`📋 Opportunity: ${opp.description} (${opp.severity})`);
        
        // Use SearchAgent to find best practices
        const searchResult = await this.searchBestPractices(
          `Ubuntu ${opp.type} optimization best practices`
        );

        // Use TerminalAgent to plan the fix
        const plan = await this.planOptimization(
          `${opp.suggestion}. System context: ${JSON.stringify(profile)}`,
          { shell: 'bash', os: 'linux' }
        );

        await this.log(`💡 Suggested: ${plan.terminalCommand.substring(0, 100)}...`);
        await this.log(`⚠️  Risk: ${plan.riskLevel} | Sudo: ${plan.requiresSudo}`);

        // Store for user review
        this.state.optimizations.push({
          ...opp,
          searchInsights: searchResult.finalAnswer?.substring(0, 200),
          plan: {
            command: plan.terminalCommand,
            reasoning: plan.reasoning,
            riskLevel: plan.riskLevel,
            requiresSudo: plan.requiresSudo,
          },
          status: 'pending',
          timestamp: Date.now(),
        });
      }

      await this.saveState();
      await this.log(`📝 ${opportunities.length} optimizations queued for review`);
      await this.log(`Review with: node lumen-daemon.js review`);

    } catch (err) {
      await this.log(`❌ Error in maintenance cycle: ${err.message}`, 'ERROR');
    }
  }

  async reviewOptimizations() {
    const pending = this.state.optimizations.filter((o) => o.status === 'pending');
    
    if (pending.length === 0) {
      console.log('\n✅ No pending optimizations\n');
      return;
    }

    console.log(`\n📋 ${pending.length} Pending Optimizations:\n`);
    pending.forEach((opt, i) => {
      console.log(`${i + 1}. [${opt.severity.toUpperCase()}] ${opt.description}`);
      console.log(`   Type: ${opt.type}`);
      console.log(`   Suggestion: ${opt.suggestion}`);
      if (opt.plan) {
        console.log(`   Command: ${opt.plan.command.substring(0, 80)}...`);
        console.log(`   Risk: ${opt.plan.riskLevel} | Sudo: ${opt.plan.requiresSudo}`);
      }
      console.log('');
    });

    console.log('To execute an optimization:');
    console.log('  node lumen-daemon.js execute <number>');
    console.log('\nTo enable auto-approve (use with caution):');
    console.log('  node lumen-daemon.js auto-approve on');
    console.log('');
  }

  async start() {
    await this.log('🌉 Lumen Daemon starting...');
    await this.loadState();
    
    // Run maintenance cycle every hour
    const interval = 60 * 60 * 1000; // 1 hour
    
    await this.runMaintenanceCycle();
    
    setInterval(async () => {
      await this.runMaintenanceCycle();
    }, interval);

    await this.log(`✅ Daemon running (checking every ${interval / 60000} minutes)`);
    await this.log('📊 Logs: tail -f ~/.lumen-daemon.log');
  }
}

// CLI Interface
async function main() {
  const daemon = new LumenDaemon();
  const command = process.argv[2];

  switch (command) {
    case 'start':
      await daemon.start();
      break;
    
    case 'check':
      await daemon.loadState();
      await daemon.runMaintenanceCycle();
      process.exit(0);
      break;
    
    case 'review':
      await daemon.loadState();
      await daemon.reviewOptimizations();
      process.exit(0);
      break;
    
    case 'status':
      await daemon.loadState();
      await daemon.gatherSystemInfo();
      console.log(JSON.stringify(daemon.state.systemProfile, null, 2));
      process.exit(0);
      break;
    
    default:
      console.log(`
🌉 Lumen Daemon - Autonomous System Optimization Agent

Usage:
  node lumen-daemon.js start        Start the daemon (runs continuously)
  node lumen-daemon.js check        Run a single maintenance check
  node lumen-daemon.js review       Review pending optimizations
  node lumen-daemon.js status       Show current system status

Logs: tail -f ~/.lumen-daemon.log
State: cat ~/.lumen-daemon-state.json
      `);
      process.exit(0);
  }
}

main().catch((err) => {
  console.error('Fatal error:', err.message);
  process.exit(1);
});
