/// <reference types="bun" />

import { describe, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
	findWowExe,
	gameVersionToInterface,
	interfaceToGameVersion,
	parseInterface,
	parseWowFileVersion,
} from "./lib/wow-interface";

describe("wow-interface", () => {
	test("encodes retail versions", () => {
		expect(gameVersionToInterface("12.1.0")).toBe(120100);
		expect(gameVersionToInterface("12.0.7")).toBe(120007);
		expect(gameVersionToInterface("11.2.7")).toBe(110207);
	});

	test("decodes Interface numbers", () => {
		expect(interfaceToGameVersion(120100)).toBe("12.1.0");
		expect(interfaceToGameVersion(120007)).toBe("12.0.7");
	});

	test("parses Wow.exe FileVersion", () => {
		expect(parseWowFileVersion("12.1.0.69814")).toEqual({
			gameVersion: "12.1.0",
			build: 69814,
			interface: 120100,
		});
	});

	test("parses Interface flag", () => {
		expect(parseInterface("120100")).toBe(120100);
		expect(() => parseInterface("12.1.0")).toThrow();
	});

	test("WOW_RETAIL_DIR _retail_ Wow.exe wins over parent walk", () => {
		const prevRetail = process.env.WOW_RETAIL_DIR;
		const prevMechanic = process.env.MECHANIC_WOW_ROOT;
		const root = mkdtempSync(join(tmpdir(), "wow-iface-retail-"));
		const walkRoot = mkdtempSync(join(tmpdir(), "wow-iface-walk-"));
		const retailExe = join(root, "_retail_", "Wow.exe");
		const walkExe = join(walkRoot, "Wow.exe");
		try {
			mkdirSync(join(root, "_retail_"), { recursive: true });
			writeFileSync(retailExe, "MZ");
			writeFileSync(walkExe, "MZ");
			process.env.WOW_RETAIL_DIR = root;
			delete process.env.MECHANIC_WOW_ROOT;
			expect(findWowExe(walkRoot)).toBe(retailExe);
		} finally {
			if (prevRetail === undefined) {
				delete process.env.WOW_RETAIL_DIR;
			} else {
				process.env.WOW_RETAIL_DIR = prevRetail;
			}
			if (prevMechanic === undefined) {
				delete process.env.MECHANIC_WOW_ROOT;
			} else {
				process.env.MECHANIC_WOW_ROOT = prevMechanic;
			}
			rmSync(root, { recursive: true, force: true });
			rmSync(walkRoot, { recursive: true, force: true });
		}
	});

	test("MECHANIC_WOW_ROOT Wow.exe wins when WOW_RETAIL_DIR unset", () => {
		const prevRetail = process.env.WOW_RETAIL_DIR;
		const prevMechanic = process.env.MECHANIC_WOW_ROOT;
		const root = mkdtempSync(join(tmpdir(), "wow-iface-mech-"));
		const walkRoot = mkdtempSync(join(tmpdir(), "wow-iface-walk2-"));
		const mechExe = join(root, "Wow.exe");
		const walkExe = join(walkRoot, "Wow.exe");
		try {
			writeFileSync(mechExe, "MZ");
			writeFileSync(walkExe, "MZ");
			delete process.env.WOW_RETAIL_DIR;
			process.env.MECHANIC_WOW_ROOT = root;
			expect(findWowExe(walkRoot)).toBe(mechExe);
		} finally {
			if (prevRetail === undefined) {
				delete process.env.WOW_RETAIL_DIR;
			} else {
				process.env.WOW_RETAIL_DIR = prevRetail;
			}
			if (prevMechanic === undefined) {
				delete process.env.MECHANIC_WOW_ROOT;
			} else {
				process.env.MECHANIC_WOW_ROOT = prevMechanic;
			}
			rmSync(root, { recursive: true, force: true });
			rmSync(walkRoot, { recursive: true, force: true });
		}
	});
});
