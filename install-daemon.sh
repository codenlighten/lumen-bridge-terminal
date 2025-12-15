#!/usr/bin/env node
/**
 * Lumen Daemon - Autonomous System Optimization Agent
 * * Lives in your laptop, continuously monitoring and optimizing the system
 * using the full power of Lumen Bridge's agent ecosystem.
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
      tasks: [],
      optimizationHistory: []
    };
  }

  async log(message, level = 'INFO') {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] [${level}] ${message}\n`;
    // Only console log if not 'DEBUG' or if explicit
    if (level !== 'DEBUG') console.log(logLine.trim());
    await fs.appendFile(LOG_FILE, logLine).catch(() => {});
  }

  async loadState() {
    try {
      const data = await fs.readFile(STATE_FILE, 'utf8');
      this.state = { ...this.state, ...JSON.parse(data) };
    } catch (err) {
      await this.log('No previous state found, starting fresh', 'WARN');
    }
  }

  // ATOMIC WRITE FIX: Prevents JSON corruption on crash
  async saveState() {
    const tempFile = `${STATE_FILE}.tmp`;
    try {
      await fs.writeFile(tempFile, JSON.stringify(this.state, null, 2));
      await fs.rename(tempFile, STATE_FILE);
    } catch (err) {
      await this.log(`Failed to save state: ${err.message}`, 'ERROR');
    }
  }

  async callAgent(endpoint, body) {
    // Basic check for fetch availability
    if (typeof fetch === 'undefined') {
      throw new Error('Node.js version too low: fetch API not found. Please upgrade to Node 18+');
    }

    try {
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
    } catch (error) {
      // Graceful fallback if offline
      await this.log(`Connection to Lumen Bridge failed: ${error.message}`, 'WARN');
      return null;
    }
  }

  async gatherSystemInfo() {
    await this.log('Gathering system information...');
    
    // Helper to run command with timeout
    const execCommand = (cmd) => this.execSafe(cmd, 5000); 

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
      nodeVersion: process.version,
    };

    this.state.systemProfile = profile;
    await this.saveState();
    return profile;
  }

  async planOptimization(task, context) {
    await this.log(`Planning: "${task.substring(0, 50)}..."`);
    
    // 1. Get Terminal Analysis
    const terminalResult = await this.callAgent('terminal', { task, context });
    if (!terminalResult) return null;

    // 2. Generate Custom Script (if needed)
    const codeGenResult = await this.callAgent('code', {
      prompt: `Create a safe, idempotent bash script for: ${task}
Requirements:
- Include error handling with set -e
- Add rollback functionality
- Backup modified files before changes
- Log all actions to syslog
- Target: ${context.shell || 'bash'} on ${context.os || 'linux'}`,
      language: 'bash',
      context: { systemInfo: this.state.systemProfile },
    });

    return {
      ...terminalResult,
      generatedScript: codeGenResult?.code,
      scriptExplanation: codeGenResult?.explanation,
      scriptPath: codeGenResult?.suggestedFilename,
    };
  }

  async backupConfigFile(filePath, reason) {
    await this.log(`📁 Backing up ${filePath}: ${reason}`);
    try {
      const backupPath = `${filePath}.lumen-backup-${Date.now()}`;
      // In production, use 'cp' via spawn to handle permissions better than fs.copyFile
      await this.execSafe(`cp "${filePath}" "${backupPath}"`);
      await this.log(`✅ Backup created: ${backupPath}`);
      return backupPath;
    } catch (err) {
      await this.log(`❌ Backup failed: ${err.message}`, 'ERROR');
      return null;
    }
  }

  async storeOptimizationMemory(optimization, outcome) {
    if (!this.state.optimizationHistory) this.state.optimizationHistory = [];

    this.state.optimizationHistory.push({
      description: optimization.description,
      type: optimization.type,
      command: optimization.plan?.command,
      outcome,
      timestamp: Date.now(),
      success: outcome.success,
    });

    // Keep memory clean (last 50)
    if (this.state.optimizationHistory.length > 50) {
      this.state.optimizationHistory = this.state.optimizationHistory.slice(-50);
    }
    await this.saveState();
  }

  async checkPastOptimizations(type) {
    if (!this.state.optimizationHistory) return { hasFailures: false };
    const failures = this.state.optimizationHistory
      .filter(h => h.type === type && !h.success)
      .slice(-3); // Check last 3 failures

    if (failures.length >= 2) {
      return { hasFailures: true, failures };
    }
    return { hasFailures: false };
  }

  async detectOptimizationOpportunities() {
    await this.log('🔍 Analyzing telemetry...');
    
    const profile = this.state.systemProfile;
    const opportunities = [];

    // 1. Memory Pressure
    const memUsagePercent = ((profile.totalMem - profile.freeMem) / profile.totalMem) * 100;
    if (memUsagePercent > 85) {
      opportunities.push({
        type: 'memory',
        severity: 'medium',
        description: `Memory usage critical (${memUsagePercent.toFixed(1)}%)`,
        suggestion: 'Clear page cache and identify zombie processes',
      });
    }

    // 2. Disk Space
    const diskUsage = parseInt(profile.diskUsage);
    if (diskUsage > 90) {
      opportunities.push({
        type: 'disk',
        severity: 'high',
        description: `Disk usage critical (${diskUsage}%)`,
        suggestion: 'Clean apt cache, old kernels, and temp files',
      });
    }

    // 3. Docker Maintenance
    if (profile.dockerRunning === 'active') {
       // Only run this check if we haven't done it in 24 hours
       opportunities.push({
         type: 'docker',
         severity: 'low',
         description: 'Docker system prune check',
         suggestion: 'Remove unused containers and dangling images',
       });
    }

    return opportunities;
  }

  // TIMEOUT FIX: Prevents hanging processes
  async execSafe(command, timeoutMs = 300000) { // Default 5 min timeout
    return new Promise((resolve, reject) => {
      const child = spawn(command, { shell: '/bin/bash' });
      let output = '';
      let errorOut = '';

      const timeout = setTimeout(() => {
        child.kill();
        resolve(`TIMEOUT: Command took longer than ${timeoutMs}ms`);
      }, timeoutMs);

      child.stdout.on('data', (data) => (output += data.toString()));
      child.stderr.on('data', (data) => (errorOut += data.toString()));
      
      child.on('close', (code) => {
        clearTimeout(timeout);
        if (code === 0) resolve(output.trim());
        else resolve(`ERROR (Code ${code}): ${errorOut.trim() || output.trim()}`);
      });
      
      child.on('error', (err) => {
        clearTimeout(timeout);
        resolve(`SPAWN ERROR: ${err.message}`);
      });
    });
  }

  async executeOptimization(optimization) {
    await this.log(`🚀 Executing: ${optimization.description}`);
    
    const outcome = { success: false, output: '', error: null };

    try {
      // 1. Config Backups
      if (optimization.plan?.command?.includes('/etc/')) {
        const configMatch = optimization.plan.command.match(/\/etc\/[\w\/.-]+/);
        if (configMatch) {
          await this.backupConfigFile(configMatch[0], optimization.description);
        }
      }

      // 2. Execute
      const command = optimization.plan?.command || optimization.suggestion;
      
      // If we have a generated script, we might want to write it to a file and run it
      // For now, we assume simple commands, or that the 'command' is a one-liner
      const result = await this.execSafe(command);
      
      if (result.startsWith('ERROR') || result.startsWith('TIMEOUT') || result.startsWith('SPAWN ERROR')) {
         throw new Error(result);
      }
      
      outcome.success = true;
      outcome.output = result;
      await this.log(`✅ Execution successful`);

    } catch (error) {
      outcome.error = error.message;
      await this.log(`❌ Execution failed: ${error.message}`, 'ERROR');
    }

    await this.storeOptimizationMemory(optimization, outcome);
    return outcome;
  }

  async runMaintenanceCycle() {
    await this.log('🔄 Maintenance cycle starting...');

    try {
      const profile = await this.gatherSystemInfo();
      const opportunities = await this.detectOptimizationOpportunities();
      
      if (opportunities.length === 0) {
        await this.log('✅ System healthy');
        return;
      }

      for (const opp of opportunities) {
        // Skip if recently failed
        const history = await this.checkPastOptimizations(opp.type);
        if (history.hasFailures) {
            await this.log(`Skipping ${opp.type} due to recent failures`, 'WARN');
            continue;
        }

        // Plan
        const plan = await this.planOptimization(
          `${opp.suggestion}. Context: ${JSON.stringify(profile)}`,
          { shell: 'bash', os: 'linux' }
        );
        
        if (!plan) continue;

        const optimizationEntry = {
          ...opp,
          plan: {
            command: plan.terminalCommand,
            reasoning: plan.reasoning,
            riskLevel: plan.riskLevel,
            requiresSudo: plan.requiresSudo,
          },
          taskId: `task-${Date.now()}-${Math.floor(Math.random()*1000)}`,
          status: 'pending',
          timestamp: Date.now(),
        };

        // Auto-approve logic
        if (this.state.autoApprove && plan.riskLevel === 'low') {
             await this.executeOptimization(optimizationEntry);
        } else {
             this.state.optimizations.push(optimizationEntry);
             await this.log(`📝 Optimization queued: ${opp.description}`);
        }
      }

      await this.saveState();

    } catch (err) {
      await this.log(`Cycle error: ${err.message}`, 'ERROR');
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
      console.log(`   Suggestion: ${opt.plan?.reasoning || opt.suggestion}`);
      console.log(`   Command: ${opt.plan?.command}`);
      console.log(`   Risk: ${opt.plan?.riskLevel || 'Unknown'}\n`);
    });

    console.log('Commands:');
    console.log('  node lumen-daemon.js execute <number>');
    console.log('  node lumen-daemon.js clear');
  }
  
  async executePending(index) {
      const pending = this.state.optimizations.filter((o) => o.status === 'pending');
      const target = pending[index - 1]; // 1-based index for user
      
      if (!target) {
          console.log('❌ Invalid optimization number');
          return;
      }
      
      console.log(`\nExecuting: ${target.description}...`);
      const outcome = await this.executeOptimization(target);
      
      // Remove from pending list regardless of outcome (it's in history now)
      this.state.optimizations = this.state.optimizations.filter(o => o.taskId !== target.taskId);
      await this.saveState();
      
      if (outcome.success) {
          console.log(`\n✅ Success!\nOutput:\n${outcome.output}`);
      } else {
          console.log(`\n❌ Failed: ${outcome.error}`);
      }
  }

  async start() {
    await this.log('bridge established. daemon active.');
    await this.loadState();
    
    // Initial Run
    await this.runMaintenanceCycle();
    
    // Loop (Hourly)
    setInterval(async () => {
      await this.runMaintenanceCycle();
    }, 60 * 60 * 1000);
  }
}

// --- CLI HANDLER ---

async function main() {
  const daemon = new LumenDaemon();
  const command = process.argv[2];
  const arg = process.argv[3];

  await daemon.loadState(); // Always load state first

  switch (command) {
    case 'start':
      await daemon.start();
      break;
    
    case 'check':
      await daemon.runMaintenanceCycle();
      process.exit(0);
      break;
    
    case 'review':
      await daemon.reviewOptimizations();
      process.exit(0);
      break;
      
    case 'execute':
      if (!arg) {
          console.log('Usage: node lumen-daemon.js execute <number>');
          process.exit(1);
      }
      await daemon.executePending(parseInt(arg));
      process.exit(0);
      break;
      
    case 'auto-approve':
      if (arg === 'on') {
          daemon.state.autoApprove = true;
          console.log('⚠️  Auto-approve ENABLED for low-risk tasks.');
      } else if (arg === 'off') {
          daemon.state.autoApprove = false;
          console.log('🔒 Auto-approve DISABLED.');
      } else {
          console.log(`Current setting: ${daemon.state.autoApprove ? 'ON' : 'OFF'}`);
          console.log('Usage: node lumen-daemon.js auto-approve <on/off>');
      }
      await daemon.saveState();
      process.exit(0);
      break;
    
    case 'clear':
      daemon.state.optimizations = [];
      await daemon.saveState();
      console.log('🗑️  Pending optimizations cleared.');
      process.exit(0);
      break;
    
    case 'status':
      await daemon.gatherSystemInfo();
      console.log(JSON.stringify(daemon.state.systemProfile, null, 2));
      process.exit(0);
      break;
    
    default:
      console.log(`
🌉 Lumen Daemon - Agent Interface

Commands:
  start          Start continuous background daemon
  check          Run immediate system analysis
  review         List pending optimization tasks
  execute <#>    Execute a pending task
  auto-approve   Toggle automatic execution for low-risk tasks
  status         Show current system profile
  clear          Clear pending tasks
      `);
      process.exit(0);
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
