# Lumen Daemon - Architecture & Design

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Ubuntu Laptop                      │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │            Lumen Daemon (Background Service)           │  │
│  │                                                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             │  │
│  │  │ Monitor  │  │ Analyze  │  │ Execute  │             │  │
│  │  │  System  │→ │ & Plan   │→ │ (Safely) │             │  │
│  │  └──────────┘  └──────────┘  └──────────┘             │  │
│  │       ↓              ↓              ↓                   │  │
│  │  [State File]   [Log File]   [Optimizations]          │  │
│  └──────────────────────┬───────────────────────────────────┘  │
│                         │                                       │
│                         │ HTTPS API Calls                      │
│                         ↓                                       │
└─────────────────────────────────────────────────────────────┘
                          │
                          │
                 ┌────────▼────────┐
                 │  Lumen Bridge   │
                 │ lumenbridge.xyz │
                 └────────┬────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────▼────┐      ┌─────▼──────┐   ┌─────▼─────┐
   │ Search  │      │ Terminal   │   │   Code    │
   │  Agent  │      │   Agent    │   │ Generator │
   └─────────┘      └────────────┘   └───────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                    ┌─────▼──────┐
                    │   Router   │
                    │   Agent    │
                    └────────────┘
```

## 🔄 Workflow Example

### Scenario: Daemon detects low disk space

1. **Monitor**: Daemon runs `df -h` and detects 87% disk usage
2. **Search**: Queries SearchAgent for "Ubuntu disk cleanup best practices"
3. **Plan**: TerminalAgent generates safe cleanup commands:
   ```bash
   sudo apt-get autoremove -y
   sudo apt-get autoclean
   docker system prune -f
   ```
4. **Store**: Saves optimization with risk assessment to state file
5. **Notify**: Logs recommendation to `~/.lumen-daemon.log`
6. **Wait**: Requires human approval (safety first!)

User reviews:
```bash
$ node lumen-daemon.js review
📋 1 Pending Optimization:

1. [HIGH] Disk usage at 87%
   Type: disk
   Suggestion: Clean up old kernels, package cache, and temporary files
   Command: sudo apt-get autoremove -y && sudo apt-get autoclean && docker...
   Risk: low | Sudo: YES
```

## 🧬 Agent Coordination

The daemon leverages **all** Lumen Bridge capabilities:

| Agent/API | Purpose | When Used |
|-----------|---------|-----------|
| **SearchAgent** | Research best practices | Before planning optimizations |
| **TerminalAgent** | Generate safe commands | Main optimization planning |
| **CodeGenerator** | Custom optimization scripts | Complex multi-step operations with rollback |
| **ToolRouterAgent** | Multi-agent orchestration | Coordinating complex workflows |
| **SchemaAgent** | Config validation | Validating system configurations |
| **File Operations** | Config backup/restore | Before modifying system files |
| **Task Management** | Long-term tracking | Track optimizations across months |
| **Memory API** | Learning from history | Avoid repeating failed optimizations |
| **ToolRouterAgent** | Task routing | Determine which agent to use |
| **SchemaAgent** | Config validation | Validate state files & configs |

## 🎯 Key Design Principles

### 1. **Safety First**
- Human approval required by default
- Risk assessment on every action
- Detailed logging and state tracking
- No destructive operations without explicit consent

### 2. **Multi-Agent Intelligence**
- Uses SearchAgent to research before acting
- TerminalAgent validates command safety
- Router intelligently delegates tasks
- Each agent brings specialized knowledge

### 3. **Continuous Learning**
- Memory API stores optimization outcomes
- Learns from past failures and successes
- Avoids repeating failed optimizations
- Adapts recommendations based on history
- Builds knowledge base over time

### 4. **Autonomous but Transparent**
- Runs in background but logs everything
- State file shows what it's thinking
- Review command shows pending actions
- Full visibility into agent reasoning
- Task tracking for long-term monitoring

## 📊 State Management

The daemon maintains state in `~/.lumen-daemon-state.json`:

```json
{
  "lastCheck": "2025-11-25T14:21:09.853Z",
  "optimizations": [
    {
      "type": "disk",
      "severity": "high",
      "description": "Disk usage at 87%",
      "searchInsights": "Best practices include removing old kernels...",
      "plan": {
        "command": "sudo apt-get autoremove -y && ...",
        "reasoning": "This combination of commands will...",
        "riskLevel": "low",
        "requiresSudo": true
      },
      "status": "pending",
      "timestamp": 1732545669853
    }
  ],
  "systemProfile": {
    "hostname": "adelle-Inspiron-7386",
    "diskUsage": "87%",
    "dockerRunning": "active",
    ...
  },
  "autoApprove": false
}
```

## 🔐 Security Considerations

1. **No Auto-Execute by Default**: All optimizations require approval
2. **Sudo Handling**: Commands requiring sudo are clearly marked
3. **Risk Assessment**: Every command rated (safe/low/medium/high/critical)
4. **Audit Trail**: Complete log of all daemon activities
5. **State Validation**: Schema validation on all data structures

## 🚀 Future Enhancements

### Phase 2: User Agent Registration
```javascript
// Register custom optimization agent
await daemon.registerUserAgent({
  name: 'MyWorkstationOptimizer',
  description: 'Custom optimizations for my dev workflow',
  prompt: 'You specialize in optimizing for React/Node.js development...'
});
```

### Phase 3: Cluster Coordination
- Multiple Lumen Daemons communicate via Lumen Bridge
- Share optimization strategies across team
- Centralized monitoring dashboard

### Phase 4: Predictive Optimization
- Machine learning on system patterns
- Preemptive optimization before issues arise
- Scheduled maintenance windows

## 🎓 Learn More

- **Lumen Bridge Docs**: See `lumenbridge.md` for API details
- **TerminalAgent**: Specialized for safe command generation
- **SearchAgent**: Web research with strategy planning
- **Router**: Intelligent task delegation

---

**This is Lumen Bridge as a "little OS for agents"** - A self-aware, multi-agent system that lives in your laptop and continuously works to make it better.
