/// <reference types="bun" />

import { join } from "node:path";
import { interfaceToGameVersion } from "./wow-interface";

function bumpPatch(version: string): string {
	const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(version);
	if (!match) {
		throw new Error(`addon-metadata: expected X.Y.Z, got ${version}`);
	}
	return `${match[1]}.${match[2]}.${Number(match[3]) + 1}`;
}

const TOC_NAME = "ProfessionTraitSearch.toc";

export type AddonVersions = {
	interface: number;
	version: string;
};

export type RetailBumpResult = {
	changed: boolean;
	reason?: string;
	dryRun: boolean;
	from?: AddonVersions;
	to?: AddonVersions & { gameVersion: string };
	files: string[];
};

function newlineOf(text: string): "\r\n" | "\n" {
	return text.includes("\r\n") ? "\r\n" : "\n";
}

async function readText(path: string): Promise<string> {
	const file = Bun.file(path);
	if (!(await file.exists())) {
		throw new Error(`addon-metadata: missing ${path}`);
	}
	return file.text();
}

async function writeText(path: string, text: string, dryRun: boolean): Promise<void> {
	if (dryRun) {
		return;
	}
	await Bun.write(path, text);
}

function replaceFirst(text: string, pattern: RegExp, replacement: string, label: string): string {
	const next = text.replace(pattern, replacement);
	if (next === text) {
		throw new Error(`addon-metadata: ${label} not found`);
	}
	return next;
}

function prependChangelogEntry(changelog: string, entry: string, nl: string): string {
	const match = changelog.match(/^(#[^\r\n]+)(\r?\n)(\r?\n)?/);
	if (!match) {
		throw new Error("addon-metadata: CHANGELOG title not found");
	}
	return changelog.replace(match[0], `${match[1]}${nl}${nl}${entry}`);
}

export async function readAddonVersions(root: string): Promise<AddonVersions & { tocVersion: string }> {
	const toc = await readText(join(root, TOC_NAME));
	const iface = toc.match(/^## Interface:\s*(\d+)\s*$/m);
	const tocVersion = toc.match(/^## Version:\s*(.+?)\s*$/m);
	if (!iface || !tocVersion) {
		throw new Error("addon-metadata: TOC missing Interface or Version");
	}
	const pkg = (await Bun.file(join(root, "package.json")).json()) as { version: string };
	if (!pkg.version) {
		throw new Error("addon-metadata: package.json missing version");
	}
	return { interface: Number(iface[1]), version: pkg.version, tocVersion: tocVersion[1] };
}

export async function applyRetailBump(opts: {
	root: string;
	interface: number;
	gameVersion?: string;
	dryRun?: boolean;
}): Promise<RetailBumpResult> {
	const dryRun = opts.dryRun === true;
	const gameVersion = opts.gameVersion ?? interfaceToGameVersion(opts.interface);
	const from = await readAddonVersions(opts.root);
	const files: string[] = [];

	if (from.interface === opts.interface) {
		return {
			changed: false,
			reason: `TOC Interface already ${opts.interface}`,
			dryRun,
			from,
			to: { interface: opts.interface, version: from.version, gameVersion },
			files,
		};
	}

	const toVersion = bumpPatch(from.version);
	const to = { interface: opts.interface, version: toVersion, gameVersion };

	const tocPath = join(opts.root, TOC_NAME);
	let toc = await readText(tocPath);
	toc = replaceFirst(toc, /^## Interface:\s*\d+\s*$/m, `## Interface: ${opts.interface}`, "TOC Interface");
	toc = replaceFirst(toc, /^## Version:\s*.+$/m, `## Version: ${toVersion}`, "TOC Version");
	await writeText(tocPath, toc, dryRun);
	files.push(TOC_NAME);

	const pkgPath = join(opts.root, "package.json");
	const pkgText = await readText(pkgPath);
	await writeText(
		pkgPath,
		replaceFirst(pkgText, /"version":\s*"[^"]+"/, `"version": "${toVersion}"`, "package.json version"),
		dryRun,
	);
	files.push("package.json");

	const changelogPath = join(opts.root, "CHANGELOG.md");
	const changelog = await readText(changelogPath);
	if (!changelog.includes(`## ${toVersion}`)) {
		const nl = newlineOf(changelog);
		const entry = [
			`## ${toVersion}`,
			"",
			"### Patch Changes",
			"",
			`- Bump Interface to ${opts.interface} for WoW ${gameVersion}`,
			"",
		].join(nl);
		await writeText(changelogPath, prependChangelogEntry(changelog, entry, nl), dryRun);
		files.push("CHANGELOG.md");
	}

	const readmePath = join(opts.root, "README.md");
	const readmeFile = Bun.file(readmePath);
	if (await readmeFile.exists()) {
		const readme = await readmeFile.text();
		if (/\*\*\d+\*\* \(see `ProfessionTraitSearch\.toc`\)/.test(readme)) {
			const next = readme.replace(
				/\*\*\d+\*\* \(see `ProfessionTraitSearch\.toc`\)/,
				`**${opts.interface}** (see \`ProfessionTraitSearch.toc\`)`,
			);
			await writeText(readmePath, next, dryRun);
			files.push("README.md");
		}
	}

	const mechanicPath = join(opts.root, "docs/mechanic-setup.md");
	const mechanicFile = Bun.file(mechanicPath);
	if (await mechanicFile.exists()) {
		const mechanic = await mechanicFile.text();
		const next = mechanic.replace(/interface `(\d+)`/g, `interface \`${opts.interface}\``);
		if (next !== mechanic) {
			await writeText(mechanicPath, next, dryRun);
			files.push("docs/mechanic-setup.md");
		}
	}

	return { changed: true, dryRun, from, to, files };
}
