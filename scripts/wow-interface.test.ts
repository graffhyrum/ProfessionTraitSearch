/// <reference types="bun" />

import { describe, expect, test } from "bun:test";
import {
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
});
