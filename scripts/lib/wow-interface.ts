/// <reference types="bun" />

import { dirname, join, resolve } from "node:path";
import { existsSync } from "node:fs";

const FILE_VERSION = /^(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?$/;
const INTERFACE = /^(\d{6,})$/;

export type RetailClient = {
	interface: number;
	gameVersion: string;
	build: number | null;
	exePath: string;
};

export function gameVersionToInterface(gameVersion: string): number {
	const match = FILE_VERSION.exec(gameVersion);
	if (!match) {
		throw new Error(`wow-interface: expected X.Y.Z, got ${gameVersion}`);
	}
	const major = Number(match[1]);
	const minor = Number(match[2]);
	const patch = Number(match[3]);
	return major * 10000 + minor * 100 + patch;
}

export function interfaceToGameVersion(iface: number): string {
	if (!Number.isInteger(iface) || iface < 10000) {
		throw new Error(`wow-interface: invalid Interface ${iface}`);
	}
	const major = Math.floor(iface / 10000);
	const minor = Math.floor((iface % 10000) / 100);
	const patch = iface % 100;
	return `${major}.${minor}.${patch}`;
}

export function parseInterface(value: string): number {
	if (!INTERFACE.test(value)) {
		throw new Error(`wow-interface: invalid Interface ${value}`);
	}
	return Number(value);
}

export function parseWowFileVersion(fileVersion: string): {
	gameVersion: string;
	build: number | null;
	interface: number;
} {
	const match = FILE_VERSION.exec(fileVersion.trim());
	if (!match) {
		throw new Error(`wow-interface: expected FileVersion X.Y.Z[.build], got ${fileVersion}`);
	}
	const gameVersion = `${match[1]}.${match[2]}.${match[3]}`;
	const build = match[4] ? Number(match[4]) : null;
	return {
		gameVersion,
		build,
		interface: gameVersionToInterface(gameVersion),
	};
}

export function findWowExe(startDir: string): string | null {
	const envDir = process.env.WOW_RETAIL_DIR;
	if (envDir) {
		const envExe = join(envDir, "Wow.exe");
		if (existsSync(envExe)) {
			return envExe;
		}
	}

	let dir = resolve(startDir);
	for (let i = 0; i < 8; i++) {
		const exe = join(dir, "Wow.exe");
		if (existsSync(exe)) {
			return exe;
		}
		const parent = dirname(dir);
		if (parent === dir) {
			break;
		}
		dir = parent;
	}
	return null;
}

export async function readWowExeFileVersion(exePath: string): Promise<string> {
	const proc = Bun.spawn(
		[
			"powershell.exe",
			"-NoLogo",
			"-NonInteractive",
			"-Command",
			"(Get-Item -LiteralPath $env:WOW_EXE_PATH).VersionInfo.FileVersion",
		],
		{
			env: { ...process.env, WOW_EXE_PATH: exePath },
			stdout: "pipe",
			stderr: "pipe",
		},
	);
	const stdout = (await new Response(proc.stdout).text()).trim();
	const stderr = (await new Response(proc.stderr).text()).trim();
	const code = await proc.exited;
	if (code !== 0 || !stdout) {
		throw new Error(`wow-interface: failed to read FileVersion from ${exePath}: ${stderr || stdout || code}`);
	}
	return stdout;
}

export async function detectRetailClient(repoRoot: string): Promise<RetailClient | null> {
	const exePath = findWowExe(repoRoot);
	if (!exePath) {
		return null;
	}
	const parsed = parseWowFileVersion(await readWowExeFileVersion(exePath));
	return {
		interface: parsed.interface,
		gameVersion: parsed.gameVersion,
		build: parsed.build,
		exePath,
	};
}
