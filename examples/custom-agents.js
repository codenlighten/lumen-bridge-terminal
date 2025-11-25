#!/usr/bin/env node
/**
 * Example: Extending Lumen Daemon with Custom User Agents
 * 
 * This shows how to register specialized agents for your specific workflows
 */

const BASE_URL = process.env.LUMENBRIDGE_URL || 'https://lumenbridge.xyz';

async function registerCustomAgent(userId, name, description, prompt) {
  const res = await fetch(`${BASE_URL}/api/agents/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId,
      name,
      description,
      prompt,
      metadata: {
        category: 'system-optimization',
        version: '1.0',
        daemon: true,
      },
    }),
  });

  const data = await res.json();
  console.log('✅ Registered:', data.agent?.name);
  return data;
}

async function invokeCustomAgent(userId, agentName, userPrompt) {
  const res = await fetch(`${BASE_URL}/api/agents/invoke-user-agent`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId,
      agentName,
      context: { userPrompt },
    }),
  });

  const data = await res.json();
  return data.result;
}

// Example 1: Development Workflow Optimizer
async function registerDevWorkflowAgent() {
  return await registerCustomAgent(
    'adelle-laptop',
    'DevWorkflowOptimizer',
    'Optimizes Ubuntu for React/Node.js/Python development workflows',
    `You are a specialized optimization agent for web development workstations.
    
    Your expertise:
    - Node.js and npm/yarn/pnpm optimization
    - React/Next.js development environment tuning
    - Python virtual environment management
    - VS Code and development tool configuration
    - Git performance optimization
    - Local development server optimization
    
    When analyzing a system:
    1. Check Node.js version and recommend LTS if outdated
    2. Optimize npm cache and global package installation
    3. Configure git for performance (core.preloadindex, gc.auto)
    4. Suggest VS Code extensions for productivity
    5. Recommend development database optimization (PostgreSQL, Redis)
    6. Check for port conflicts in common dev ports (3000, 8000, 5432, etc)
    
    Always provide idempotent, safe commands with clear explanations.`
  );
}

// Example 2: Security Hardening Agent
async function registerSecurityAgent() {
  return await registerCustomAgent(
    'adelle-laptop',
    'SecurityHardeningAgent',
    'Continuous security monitoring and hardening for Ubuntu workstations',
    `You are a security-focused system optimization agent.
    
    Your responsibilities:
    - Monitor and recommend security updates
    - Audit SSH configuration
    - Check firewall (ufw) status and rules
    - Scan for common security misconfigurations
    - Recommend fail2ban configuration
    - Audit sudo configurations
    - Check for unnecessary open ports
    - Validate SSL/TLS configurations
    
    Security principles:
    1. Least privilege access
    2. Defense in depth
    3. Regular patching
    4. Audit logging
    5. Principle of fail-safe defaults
    
    Provide actionable security recommendations with risk ratings.`
  );
}

// Example 3: Performance Tuning Agent
async function registerPerformanceAgent() {
  return await registerCustomAgent(
    'adelle-laptop',
    'PerformanceTuningAgent',
    'System performance monitoring and optimization',
    `You are a performance optimization specialist for Ubuntu systems.
    
    Your focus areas:
    - CPU governor and frequency scaling
    - Memory management (swappiness, caching)
    - Disk I/O optimization (scheduler, noatime)
    - Network stack tuning (TCP parameters)
    - Process priority and nice values
    - Systemd service optimization
    - Boot time optimization
    
    Analysis approach:
    1. Identify bottlenecks (CPU, Memory, Disk, Network)
    2. Measure current performance baselines
    3. Recommend tuning parameters
    4. Provide rollback instructions
    5. Estimate performance impact
    
    All recommendations must be non-destructive and reversible.`
  );
}

// Example Usage
async function main() {
  console.log('🌉 Registering Custom Optimization Agents...\n');

  try {
    await registerDevWorkflowAgent();
    await registerSecurityAgent();
    await registerPerformanceAgent();

    console.log('\n✅ All agents registered!\n');
    console.log('Now you can invoke them:');
    console.log('');
    console.log('  # Development optimization');
    console.log('  node lumen-daemon.js invoke DevWorkflowOptimizer "analyze my dev setup"');
    console.log('');
    console.log('  # Security audit');
    console.log('  node lumen-daemon.js invoke SecurityHardeningAgent "audit my security posture"');
    console.log('');
    console.log('  # Performance tuning');
    console.log('  node lumen-daemon.js invoke PerformanceTuningAgent "optimize for development workload"');
    console.log('');

    // Example invocation
    console.log('📋 Example: Invoking DevWorkflowOptimizer...\n');
    const result = await invokeCustomAgent(
      'adelle-laptop',
      'DevWorkflowOptimizer',
      `Analyze this system for React/Node.js development:
       - Node version: v20.19.0
       - npm version: 10.2.4
       - Has Docker, PostgreSQL, VS Code
       - Working on React + Next.js projects
       
       Suggest optimizations.`
    );

    console.log('Agent Response:');
    console.log(result.response);

  } catch (err) {
    console.error('❌ Error:', err.message);
  }
}

main();
