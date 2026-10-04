/// <reference types="bun" />

export type TraceStatus = "ok" | "gap" | "wait";

export type TraceStage = {
	id: string;
	status: TraceStatus;
	detail: string;
};

export type ReleaseFacts = {
	version: string;
	tocVersion: string;
	changelogHasVersion: boolean;
	pendingChangesets: string[];
	tagExists: boolean;
	versionBranchExists: boolean;
	versionPrExists: boolean;
	headTag?: string;
	repo?: string;
};

/** publish: before Version Packages. check: after it. tagged: a v* tag checkout. */
export type ReleasePhase = "publish" | "check" | "tagged";

export type ReleaseDecision = {
	stages: TraceStage[];
	publishUntagged: boolean;
	exitCode: number;
};

export const VERSION_BRANCH = "changeset-release/main";

const PR_PERMISSION =
	"Allow GitHub Actions to create pull requests (Settings, Actions, General, Workflow permissions).";

function stage(id: string, status: TraceStatus, detail: string): TraceStage {
	return { id, status, detail };
}

function versionStages(facts: ReleaseFacts): TraceStage[] {
	const stages: TraceStage[] = [];
	stages.push(
		facts.tocVersion === facts.version
			? stage("toc", "ok", `TOC ${facts.tocVersion}`)
			: stage("toc", "gap", `TOC ${facts.tocVersion} != package ${facts.version}`),
	);
	stages.push(
		facts.changelogHasVersion
			? stage("changelog", "ok", `CHANGELOG has ## ${facts.version}`)
			: stage("changelog", "gap", `CHANGELOG missing ## ${facts.version}`),
	);
	return stages;
}

function versionsAlign(facts: ReleaseFacts): boolean {
	return facts.tocVersion === facts.version && facts.changelogHasVersion;
}

function tagStage(facts: ReleaseFacts, phase: ReleasePhase): TraceStage {
	const tag = `v${facts.version}`;
	if (facts.tagExists) {
		return stage("tag", "ok", `${tag} is on origin`);
	}
	const detail = `${tag} is not on origin. Publish this version before a version PR.`;
	return stage("tag", phase === "check" ? "gap" : "wait", detail);
}

function versionPrStage(facts: ReleaseFacts, phase: ReleasePhase): TraceStage {
	if (facts.pendingChangesets.length === 0) {
		return stage("version-pr", "ok", "not required");
	}
	if (facts.versionPrExists) {
		return stage("version-pr", "ok", `${VERSION_BRANCH} has an open pull request`);
	}
	if (phase === "publish") {
		const detail = facts.tagExists
			? "Version Packages will open the pull request"
			: "after the untagged version is published";
		return stage("version-pr", "wait", detail);
	}
	const link =
		facts.repo && facts.versionBranchExists
			? ` Open https://github.com/${facts.repo}/compare/main...${VERSION_BRANCH}?expand=1`
			: "";
	const where = facts.versionBranchExists
		? `${VERSION_BRANCH} exists and has no pull request. ${PR_PERMISSION}${link}`
		: `No version pull request. ${PR_PERMISSION}`;
	return stage("version-pr", "gap", where);
}

export function traceRelease(facts: ReleaseFacts, phase: ReleasePhase): ReleaseDecision {
	if (phase === "tagged") {
		const tag = `v${facts.version}`;
		const head = facts.headTag ?? "";
		const stages = [
			head === tag
				? stage("tag", "ok", `${head} matches package ${facts.version}`)
				: stage("tag", "gap", `checkout ${head || "(none)"} is not ${tag}`),
			...versionStages(facts),
		];
		return {
			stages,
			publishUntagged: false,
			exitCode: stages.some((item) => item.status === "gap") ? 1 : 0,
		};
	}

	const stages = [...versionStages(facts), tagStage(facts, phase)];
	stages.push(
		facts.pendingChangesets.length === 0
			? stage("changesets", "ok", "none")
			: stage("changesets", "wait", facts.pendingChangesets.join(", ")),
	);
	stages.push(versionPrStage(facts, phase));

	return {
		stages,
		publishUntagged: phase === "publish" && !facts.tagExists && versionsAlign(facts),
		exitCode: stages.some((item) => item.status === "gap") ? 1 : 0,
	};
}

export function formatReleaseTrace(phase: ReleasePhase, decision: ReleaseDecision): string {
	const lines = [`release-trace phase=${phase}`];
	for (const item of decision.stages) {
		lines.push(`${item.status.padEnd(4)} ${item.id.padEnd(12)} ${item.detail}`);
	}
	if (decision.publishUntagged) {
		lines.push("action: publish untagged version");
	}
	return lines.join("\n");
}

export function formatReleaseSummary(phase: ReleasePhase, decision: ReleaseDecision): string {
	const rows = decision.stages
		.map((item) => `| ${item.id} | ${item.status} | ${item.detail.replaceAll("|", "/")} |`)
		.join("\n");
	const action = decision.publishUntagged ? "\n\nAction: publish untagged version.\n" : "\n";
	return `### Release trace (${phase})\n\n| Stage | Status | Detail |\n| --- | --- | --- |\n${rows}${action}`;
}
