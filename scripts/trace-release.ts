/// <reference types="bun" />

import { appendFileSync } from "node:fs";
import { join } from "node:path";
import { hasFlag } from "./lib/cli";
import {
	formatReleaseSummary,
	formatReleaseTrace,
	traceRelease,
	VERSION_BRANCH,
	type ReleaseFacts,
	type ReleasePhase,
} from "./lib/release-trace";
import { publishTag } from "./publish-tag";

const root = `${import.meta.dir}/..`;

async function readVersion(): Promise<string> {
	const { version } = (await Bun.file(join(root, "package.json")).json()) as { version: string };
	if (!version) {
		throw new Error("trace-release: package.json missing version");
	}
	return version;
}

async function readTocVersion(): Promise<string> {
	const toc = await Bun.file(join(root, "ProfessionTraitSearch.toc")).text();
	const match = toc.match(/^## Version:\s*(.+?)\s*$/m);
	if (!match) {
		throw new Error("trace-release: TOC missing ## Version");
	}
	return match[1];
}

async function changelogHasVersion(version: string): Promise<boolean> {
	const changelog = await Bun.file(join(root, "CHANGELOG.md")).text();
	return new RegExp(`^## ${version.replaceAll(".", "\\.")}\\s*$`, "m").test(changelog);
}

async function pendingChangesets(): Promise<string[]> {
	const dir = join(root, ".changeset");
	const glob = new Bun.Glob("*.md");
	const names: string[] = [];
	for await (const file of glob.scan({ cwd: dir, onlyFiles: true })) {
		if (file === "README.md") {
			continue;
		}
		names.push(file);
	}
	return names.sort();
}

async function remoteRef(kind: "tags" | "heads", ref: string): Promise<boolean> {
	const remote = await Bun.$`git ls-remote --${kind} origin refs/${kind}/${ref}`.quiet().nothrow();
	if (remote.exitCode !== 0) {
		throw new Error(`trace-release: git ls-remote failed for ${ref}`);
	}
	return remote.stdout.toString().includes(`refs/${kind}/${ref}`);
}

async function versionPrExists(): Promise<boolean> {
	if (!process.env.GITHUB_TOKEN && !process.env.GH_TOKEN) {
		return false;
	}
	const listed = await Bun.$`gh pr list --head ${VERSION_BRANCH} --base main --state open --json number`
		.quiet()
		.nothrow();
	if (listed.exitCode !== 0) {
		const err = listed.stderr.toString().trim();
		console.error(`trace-release: could not list version pull requests${err ? `: ${err}` : ""}`);
		return false;
	}
	const rows = JSON.parse(listed.stdout.toString() || "[]") as unknown[];
	return rows.length > 0;
}

async function headTag(): Promise<string | undefined> {
	if (process.env.GITHUB_REF?.startsWith("refs/tags/") && process.env.GITHUB_REF_NAME) {
		return process.env.GITHUB_REF_NAME;
	}
	const described = await Bun.$`git describe --tags --exact-match HEAD`.quiet().nothrow();
	if (described.exitCode !== 0) {
		return undefined;
	}
	return described.stdout.toString().trim();
}

export async function loadReleaseFacts(): Promise<ReleaseFacts> {
	const version = await readVersion();
	const [tocVersion, changelogOk, changesets, tagExists, versionBranchExists, prExists, tag] =
		await Promise.all([
			readTocVersion(),
			changelogHasVersion(version),
			pendingChangesets(),
			remoteRef("tags", `v${version}`),
			remoteRef("heads", VERSION_BRANCH),
			versionPrExists(),
			headTag(),
		]);
	return {
		version,
		tocVersion,
		changelogHasVersion: changelogOk,
		pendingChangesets: changesets,
		tagExists,
		versionBranchExists,
		versionPrExists: prExists,
		headTag: tag,
		repo: process.env.GITHUB_REPOSITORY,
	};
}

function phaseFromArgs(argv: string[]): ReleasePhase {
	if (hasFlag("tagged", argv)) {
		return "tagged";
	}
	if (hasFlag("check", argv)) {
		return "check";
	}
	return "publish";
}

function writeSummary(phase: ReleasePhase, decision: ReturnType<typeof traceRelease>): void {
	const path = process.env.GITHUB_STEP_SUMMARY;
	if (!path) {
		return;
	}
	appendFileSync(path, `${formatReleaseSummary(phase, decision)}\n`);
}

export async function runTraceRelease(argv = process.argv): Promise<number> {
	const phase = phaseFromArgs(argv);
	let facts = await loadReleaseFacts();
	let decision = traceRelease(facts, phase);
	console.log(formatReleaseTrace(phase, decision));

	if (hasFlag("publish-untagged", argv) && decision.publishUntagged) {
		await publishTag();
		facts = await loadReleaseFacts();
		decision = traceRelease(facts, phase);
		console.log(formatReleaseTrace(phase, decision));
	}

	writeSummary(phase, decision);
	return decision.exitCode;
}

if (import.meta.main) {
	process.exit(await runTraceRelease());
}
