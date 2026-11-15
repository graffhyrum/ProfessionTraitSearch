/// <reference types="bun" />

import { describe, expect, test } from "bun:test";
import {
	formatReleaseTrace,
	traceRelease,
	type ReleaseFacts,
} from "./lib/release-trace";

function facts(overrides: Partial<ReleaseFacts> = {}): ReleaseFacts {
	return {
		version: "1.0.3",
		tocVersion: "1.0.3",
		changelogHasVersion: true,
		pendingChangesets: ["retail-interface-tools.md"],
		tagExists: false,
		versionBranchExists: false,
		versionPrExists: false,
		...overrides,
	};
}

describe("traceRelease", () => {
	test("an untagged version with a pending changeset is published first", () => {
		const decision = traceRelease(facts(), "publish");
		expect(decision.publishUntagged).toBe(true);
		expect(decision.exitCode).toBe(0);
		expect(decision.stages.find((item) => item.id === "tag")?.status).toBe("wait");
		expect(decision.stages.find((item) => item.id === "version-pr")?.status).toBe("wait");
		expect(formatReleaseTrace("publish", decision)).toContain("action: publish untagged version");
	});

	test("check fails when the version tag and version pull request are missing", () => {
		const decision = traceRelease(
			facts({ versionBranchExists: true }),
			"check",
		);
		expect(decision.publishUntagged).toBe(false);
		expect(decision.exitCode).toBe(1);
		expect(decision.stages.find((item) => item.id === "tag")?.status).toBe("gap");
		expect(decision.stages.find((item) => item.id === "version-pr")?.detail).toContain(
			"Allow GitHub Actions to create pull requests",
		);
		const withRepo = traceRelease(
			facts({ versionBranchExists: true, repo: "graffhyrum/ProfessionTraitSearch" }),
			"check",
		);
		expect(withRepo.stages.find((item) => item.id === "version-pr")?.detail).toContain(
			"https://github.com/graffhyrum/ProfessionTraitSearch/compare/main...changeset-release/main?expand=1",
		);
	});

	test("check passes when the tag exists and the version pull request is open", () => {
		const decision = traceRelease(
			facts({ tagExists: true, versionBranchExists: true, versionPrExists: true }),
			"check",
		);
		expect(decision.exitCode).toBe(0);
		expect(decision.publishUntagged).toBe(false);
	});

	test("a tagged version with no changesets needs no pull request", () => {
		const decision = traceRelease(
			facts({ tagExists: true, pendingChangesets: [] }),
			"check",
		);
		expect(decision.exitCode).toBe(0);
		expect(decision.stages.find((item) => item.id === "version-pr")?.detail).toBe("not required");
	});

	test("TOC or changelog mismatch blocks the tag", () => {
		const mismatch = traceRelease(facts({ tocVersion: "1.0.2" }), "publish");
		expect(mismatch.publishUntagged).toBe(false);
		expect(mismatch.exitCode).toBe(1);

		const changelog = traceRelease(facts({ changelogHasVersion: false }), "publish");
		expect(changelog.publishUntagged).toBe(false);
		expect(changelog.exitCode).toBe(1);
	});

	test("a tag checkout must match package, TOC, and changelog", () => {
		const ok = traceRelease(facts({ headTag: "v1.0.3" }), "tagged");
		expect(ok.exitCode).toBe(0);
		expect(ok.stages.map((item) => item.id)).toEqual(["tag", "toc", "changelog"]);

		const wrong = traceRelease(facts({ headTag: "v1.0.2" }), "tagged");
		expect(wrong.exitCode).toBe(1);
		expect(wrong.stages.find((item) => item.id === "tag")?.detail).toContain("v1.0.2");
	});
});
