#!/usr/bin/env node
/**
 * Simple Lumen Bridge TerminalAgent client (CommonJS)
 * - Sends a high-level "optimize this Ubuntu dev machine" task
 * - Prints the suggested command + reasoning
 * - Asks user for confirmation
 * - Executes the command locally if confirmed
 *
 * Usage: `node terminal-optimizer.js` (Node.js >= 18 recommended)
 */

const readlinePromises = require('readline').promises;
const { stdin: input, stdout: output } = require('process');
const { spawn } = require('child_process');

const BASE_URL = process.env.LUMENBRIDGE_URL || 'https://lumenbridge.xyz';

async function callTerminalAgent(task) {
  if (typeof fetch === 'undefined') {
    throw new Error('global fetch not available. Please run with Node.js >= 18');
  }

  const body = { task, context: { shell: 'bash', os: 'linux' } };

  const res = await fetch(`${BASE_URL}/api/agents/terminal`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`TerminalAgent HTTP ${res.status}: ${res.statusText} ${text || ''}`);
  }

  const data = await res.json();
  if (!data.success) {
    throw new Error(data.error || 'TerminalAgent returned success=false');
  }

  return data.result;
}

function runCommandStreaming(command) {
  return new Promise((resolve, reject) => {
    console.log('\n▶ Executing command:\n', command, '\n');

    const child = spawn(command, {
      shell: '/bin/bash',
      stdio: 'inherit',
    });

    child.on('exit', (code) => {
      if (code === 0) {
        console.log('\n✅ Command finished successfully.');
        resolve();
      } else {
        reject(new Error(`Command exited with code ${code}`));
      }
    });

    child.on('error', (err) => {
      reject(err);
    });
  });
}

async function main() {
  const taskFromCli = process.argv.slice(2).join(' ');
  const defaultTask = `You are a Senior Linux Systems Administrator and DevOps Engineer, specializing in the provisioning and optimization of secure, high-performance development workstations for an enterprise environment. Your mission is to generate a comprehensive, idempotent, and fully non-interactive Bash script to transform a fresh Ubuntu Desktop installation into a robust development workstation.

# Mission Objective
Provision a production-ready Ubuntu development workstation with the following characteristics and components:

## Core Principles
*   **Idempotency**: The script must be runnable multiple times without adverse effects.
*   **Non-Interactive Execution**: Utilize \`-y\` flags and appropriate \`DEBIAN_FRONTEND=noninteractive\` settings to ensure zero user prompts.
*   **Security First**: Prioritize secure installation practices (e.g., adding official GPG keys for PPAs).
*   **System Stability**: Avoid any changes that could compromise the base system's stability or data integrity.
*   **Performance Optimization**: While installing, ensure that system resources are managed efficiently.

## Required Software & Tools
1.  **System Base**: Fully update and upgrade all existing packages.
2.  **Build Essentials**: \`build-essential\` and necessary development libraries.
3.  **Version Control**: \`git\` (latest stable).
4.  **Networking & Transfer**: \`curl\`, \`wget\`, \`gnupg\`, \`lsb-release\`, \`ca-certificates\`.
5.  **Node.js**: The latest Long Term Support (LTS) version of Node.js, installed via the official \`nodesource\` repository for system-wide availability and easy updates.
6.  **Docker Engine**: The latest stable Docker Engine, installed via the official Docker repository. Configure the current user to be part of the \`docker\` group to run commands without \`sudo\` (requires user re-login).
7.  **Python Development**: \`python3\`, \`python3-dev\`, \`python3-pip\`, and \`python3-venv\` for isolated virtual environments. Consider a note on \`pyenv\` for multi-version management but stick to system packages for base setup.
8.  **Database Clients**: Command-line clients for \`PostgreSQL\` (\`postgresql-client\`) and \`MySQL\` (\`mysql-client\`).
9.  **Essential Developer Utilities**: 
    *   \`tmux\` (terminal multiplexer)
    *   \`vim\` or \`neovim\` (advanced text editor, prefer \`vim-nox\` for full features if \`neovim\` is too involved)
    *   \`zsh\` (shell, with a prompt to optionally install \`oh-my-zsh\` for user setup)
    *   \`htop\` (process viewer)
    *   \`jq\` (JSON processor)
    *   \`tree\` (directory lister)
    *   \`net-tools\` (legacy networking utilities)
    *   \`iputils-ping\` (ping utility)
    *   \`dnsutils\` (for \`dig\`)
    *   \`ansible\` (for general automation/config management)

## Workflow & Output Requirements
*   **Output Format**: A single, complete Bash script within a Markdown code block.
*   **Error Handling**: The script must start with \`set -euxo pipefail\` to exit immediately on error, unset variables, and non-zero exit codes in pipes.
*   **User Check**: Include a check at the beginning to ensure the script is run with \`sudo\` privileges.
*   **Comments**: Use clear comments within the script to explain each major section.
*   **Reboot**: The script should only indicate a \`systemctl reboot\` as *necessary* at the very end, and it should be commented out with an instruction for the user to execute it manually.
*   **No Preamble/Postamble**: Do NOT include any conversational text outside of the Bash script Markdown block itself.
*   **No GUI Configuration**: Do not include any graphical user interface specific configurations; focus solely on CLI and system-level tools.

Generate the Bash script now.`;

  const task = taskFromCli || defaultTask;

  console.log('🌉 Lumen Bridge Terminal Optimizer');
  console.log('Base URL:', BASE_URL);
  console.log('\n🧠 Task sent to TerminalAgent:\n', task, '\n');

  const result = await callTerminalAgent(task);

  const {
    terminalCommand,
    reasoning,
    shell,
    requiresSudo,
    isDestructive,
    riskLevel,
    safetyWarnings = [],
    estimatedTime,
  } = result;

  console.log('=== Suggested Command ===');
  console.log(terminalCommand);
  console.log('\n=== Details ===');
  console.log('Shell:         ', shell || 'bash');
  console.log('Risk level:    ', riskLevel);
  console.log('Destructive?:  ', isDestructive ? 'YES' : 'no');
  console.log('Requires sudo?:', requiresSudo ? 'YES' : 'no');
  console.log('Estimated time:', estimatedTime || 'unknown');
  console.log('\n=== Reasoning ===');
  console.log(reasoning || '(no reasoning provided)');

  if (safetyWarnings.length) {
    console.log('\n⚠️ Safety Warnings:');
    for (const w of safetyWarnings) {
      console.log(' -', w);
    }
  }

  const rl = readlinePromises.createInterface({ input, output });
  const answer = await rl.question('\nDo you want to RUN this command on this machine now? (y/N): ');
  rl.close();

  if (answer.trim().toLowerCase() !== 'y') {
    console.log('\n❌ Command NOT executed. Exiting.');
    return;
  }

  try {
    // Wrap with sudo if the command requires it
    let commandToRun = terminalCommand;
    if (requiresSudo) {
      console.log('\n🔐 This command requires sudo privileges. You may be prompted for your password.\n');
      commandToRun = `sudo bash -c ${JSON.stringify(terminalCommand)}`;
    }
    
    await runCommandStreaming(commandToRun);
    console.log('\n🎉 Optimization step complete.');
  } catch (err) {
    console.error('\n💥 Error running command:', err.message);
    process.exitCode = 1;
  }
}

main().catch((err) => {
  console.error('\n💥 Fatal error:', err.message);
  process.exit(1);
});
