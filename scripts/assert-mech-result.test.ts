/// <reference types="bun" />

import { describe, expect, test } from "bun:test";
import { assertMechResult, extractJsonObject } from "./assert-mech-result";

describe("assert-mech-result", () => {
	test("extracts JSON after log prefix", () => {
		const result = extractJsonObject('Calling sandbox.test...\n{"success":true,"data":{"passed":true,"total":3}}');
		expect(result).toEqual({ success: true, data: { passed: true, total: 3 } });
	});

	test("rejects a failed Mechanic command even if the process exits 0", () => {
		expect(() =>
			assertMechResult({
				success: false,
				data: null,
				error: { code: "ADDON_NOT_FOUND", message: "Addon missing" },
			}),
		).toThrow("ADDON_NOT_FOUND: Addon missing");
	});

	test("rejects a test run with passed=false", () => {
		expect(() =>
			assertMechResult({
				success: true,
				data: { passed: false, total: 91, passed_count: 90, failed_count: 1 },
			}),
		).toThrow("Mechanic tests failed: 1 failed, 90 passed (total 91)");
	});

	test("rejects a 0-test run", () => {
		expect(() =>
			assertMechResult({
				success: true,
				data: { passed: true, total: 0, passed_count: 0, failed_count: 0 },
			}),
		).toThrow("Mechanic reported 0 tests");
	});

	test("accepts a passing test run", () => {
		expect(() =>
			assertMechResult({
				success: true,
				data: { passed: true, total: 17, passed_count: 17, failed_count: 0 },
			}),
		).not.toThrow();
	});

	test("accepts generate-style success without a test total", () => {
		expect(() =>
			assertMechResult({
				success: true,
				data: { stubs: 4519 },
			}),
		).not.toThrow();
	});
});
