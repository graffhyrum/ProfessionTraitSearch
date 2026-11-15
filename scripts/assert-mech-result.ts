/// <reference types="bun" />

export type MechError = {
	code?: string;
	message?: string;
};

export type MechTestData = {
	passed?: boolean;
	total?: number;
	passed_count?: number;
	failed_count?: number;
	[key: string]: unknown;
};

export type MechResult = {
	success?: boolean;
	data?: MechTestData | null;
	error?: MechError | null;
};

export function extractJsonObject(text: string): unknown {
	const start = text.indexOf("{");
	if (start < 0) {
		throw new Error("No JSON object in Mechanic output");
	}
	return JSON.parse(text.slice(start)) as unknown;
}

export function assertMechResult(result: MechResult): void {
	if (result.success === false) {
		const code = result.error?.code ? `${result.error.code}: ` : "";
		const message = result.error?.message ?? "Mechanic call failed";
		throw new Error(`${code}${message}`);
	}

	const data = result.data;
	if (!data || typeof data !== "object") {
		return;
	}

	if (typeof data.passed === "boolean" && data.passed !== true) {
		const failed = data.failed_count ?? "?";
		const passed = data.passed_count ?? "?";
		const total = data.total ?? "?";
		throw new Error(
			`Mechanic tests failed: ${failed} failed, ${passed} passed (total ${total})`,
		);
	}

	// sandbox.test / addon.test report `total`. A 0-test "pass" previously
	// hid Core/ vs core/ discovery failures on Linux.
	if (typeof data.total === "number" && data.total < 1) {
		throw new Error("Mechanic reported 0 tests; refusing to pass an empty run");
	}
}

export async function main(argv = process.argv.slice(2)): Promise<number> {
	const path = argv[0];
	if (!path) {
		console.error("usage: bun scripts/assert-mech-result.ts <mech-json-file>");
		return 2;
	}

	const file = Bun.file(path);
	if (!(await file.exists())) {
		console.error(`Mechanic result file not found: ${path}`);
		return 1;
	}

	const text = await file.text();
	try {
		assertMechResult(extractJsonObject(text) as MechResult);
	} catch (err) {
		console.error(err instanceof Error ? err.message : err);
		console.error(text);
		return 1;
	}
	return 0;
}

if (import.meta.main) {
	process.exit(await main());
}
