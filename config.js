#!/usr/bin/env node
/**
 * Lumen Bridge Terminal - Configuration Manager
 *
 * Manages user preferences, API endpoints, and agent configurations
 */

const fs = require("fs").promises;
const path = require("path");
const os = require("os");
const readline = require("readline");

const CONFIG_FILE = path.join(os.homedir(), ".lumen-config.json");

const DEFAULT_CONFIG = {
	version: "1.0.0",
	api: {
		baseUrl: process.env.LUMENBRIDGE_URL || "https://lumenbridge.xyz",
		timeout: 30000,
		retries: 3,
	},
	daemon: {
		checkInterval: 3600, // seconds (1 hour)
		autoApprove: false,
		enabledOptimizations: {
			diskCleanup: true,
			packageUpdates: true,
			dockerPrune: true,
			memoryOptimization: true,
			logRotation: true,
		},
		notifyOn: {
			criticalIssues: true,
			optimizationComplete: false,
			dailySummary: false,
		},
	},
	agents: {
		terminal: {
			enabled: true,
			maxExecutionTime: 300, // seconds
		},
		search: {
			enabled: true,
			searchEngines: ["google", "github", "stackoverflow"],
		},
		codeGenerator: {
			enabled: true,
			languages: ["javascript", "python", "bash", "typescript"],
		},
	},
	customAgents: [],
	preferences: {
		verboseLogging: false,
		colorOutput: true,
		confirmBeforeExecution: true,
		backupBeforeModification: true,
	},
	paths: {
		installDir: path.join(os.homedir(), "lumen-terminal"),
		logDir: os.homedir(),
		stateDir: os.homedir(),
	},
};

class ConfigManager {
	constructor() {
		this.config = null;
	}

	async load() {
		try {
			const data = await fs.readFile(CONFIG_FILE, "utf8");
			this.config = { ...DEFAULT_CONFIG, ...JSON.parse(data) };
			return this.config;
		} catch (err) {
			console.log("No config found, using defaults");
			this.config = DEFAULT_CONFIG;
			return this.config;
		}
	}

	async save() {
		await fs.writeFile(CONFIG_FILE, JSON.stringify(this.config, null, 2));
		console.log(`✅ Configuration saved to ${CONFIG_FILE}`);
	}

	get(path) {
		const keys = path.split(".");
		let value = this.config;
		for (const key of keys) {
			value = value?.[key];
		}
		return value;
	}

	set(path, value) {
		const keys = path.split(".");
		let obj = this.config;
		for (let i = 0; i < keys.length - 1; i++) {
			if (!obj[keys[i]]) obj[keys[i]] = {};
			obj = obj[keys[i]];
		}
		obj[keys[keys.length - 1]] = value;
	}

	async reset() {
		this.config = DEFAULT_CONFIG;
		await this.save();
		console.log("✅ Configuration reset to defaults");
	}

	display() {
		console.log("\n📋 Current Configuration:\n");
		console.log(JSON.stringify(this.config, null, 2));
	}

	async interactiveSetup() {
		const rl = readline.createInterface({
			input: process.stdin,
			output: process.stdout,
		});

		const question = (prompt) =>
			new Promise((resolve) => {
				rl.question(prompt, resolve);
			});

		console.log("\n🔧 Interactive Configuration Setup\n");

		// API Configuration
		const apiUrl = await question(
			`API Base URL [${this.config.api.baseUrl}]: `
		);
		if (apiUrl) this.set("api.baseUrl", apiUrl);

		// Daemon Configuration
		const interval = await question(
			`Daemon check interval (seconds) [${this.config.daemon.checkInterval}]: `
		);
		if (interval) this.set("daemon.checkInterval", parseInt(interval));

		const autoApprove = await question(
			"Auto-approve safe optimizations? (y/N): "
		);
		this.set("daemon.autoApprove", autoApprove.toLowerCase() === "y");

		// Preferences
		const verbose = await question("Enable verbose logging? (y/N): ");
		this.set("preferences.verboseLogging", verbose.toLowerCase() === "y");

		const confirmExec = await question("Confirm before execution? (Y/n): ");
		this.set(
			"preferences.confirmBeforeExecution",
			confirmExec.toLowerCase() !== "n"
		);

		rl.close();

		await this.save();
		console.log("\n✅ Configuration updated successfully!\n");
	}
}

// CLI Interface
async function main() {
	const manager = new ConfigManager();
	await manager.load();

	const command = process.argv[2];
	const args = process.argv.slice(3);

	switch (command) {
		case "show":
		case "display":
			manager.display();
			break;

		case "get":
			if (!args[0]) {
				console.error("❌ Usage: config.js get <path>");
				process.exit(1);
			}
			console.log(manager.get(args[0]));
			break;

		case "set":
			if (args.length < 2) {
				console.error("❌ Usage: config.js set <path> <value>");
				process.exit(1);
			}
			const value =
				args[1] === "true" ? true : args[1] === "false" ? false : args[1];
			manager.set(args[0], value);
			await manager.save();
			break;

		case "reset":
			await manager.reset();
			break;

		case "setup":
		case "init":
			await manager.interactiveSetup();
			break;

		case "path":
			console.log(CONFIG_FILE);
			break;

		default:
			console.log(`
🔧 Lumen Bridge Configuration Manager

Usage:
  node config.js <command> [args]

Commands:
  show                    Display current configuration
  get <path>              Get a specific config value
  set <path> <value>      Set a specific config value
  reset                   Reset to default configuration
  setup                   Interactive configuration setup
  path                    Show config file location

Examples:
  node config.js show
  node config.js get daemon.checkInterval
  node config.js set daemon.autoApprove true
  node config.js setup

Config paths:
  api.baseUrl
  daemon.checkInterval
  daemon.autoApprove
  daemon.enabledOptimizations.diskCleanup
  preferences.verboseLogging
  preferences.confirmBeforeExecution
      `);
			break;
	}
}

if (require.main === module) {
	main().catch((err) => {
		console.error("❌ Error:", err.message);
		process.exit(1);
	});
}

module.exports = ConfigManager;
