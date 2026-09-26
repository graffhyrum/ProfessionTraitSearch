/// <reference types="bun" />

import { describe, expect, test } from "bun:test";
import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { applyRetailBump, readAddonVersions } from "./lib/addon-metadata";

async function fixtureRoot(): Promise<string> {
	const dir = await mkdtemp(join(tmpdir(), "pts-bump-"));
	await mkdir(join(dir, "docs"), { recursive: true });
	await Bun.write(
		join(dir, "ProfessionTraitSearch.toc"),
		"## Interface: 120007\r\n## Version: 1.0.2\r\n",
	);
	await Bun.write(
		join(dir, "package.json"),
		'{\n  "name": "profession-trait-search",\n  "version": "1.0.2"\n}\n',
	);
	await Bun.write(join(dir, "CHANGELOG.md"), "# profession-trait-search\n\n## 1.0.2\n\n- old\n");
	await Bun.write(
		join(dir, "README.md"),
		"- Interface version: **120007** (see `ProfessionTraitSearch.toc`)\n",
	);
	await Bun.write(join(dir, "docs/mechanic-setup.md"), "| `just validate` | interface `120007` flagged |\n");
	return dir;
}

describe("applyRetailBump", () => {
	test("bumps Interface, patch version, and docs", async () => {
		const root = await fixtureRoot();
		try {
			const result = await applyRetailBump({
				root,
				interface: 120100,
				gameVersion: "12.1.0",
			});
			expect(result.changed).toBe(true);
			expect(result.to).toEqual({ interface: 120100, version: "1.0.3", gameVersion: "12.1.0" });
			expect(result.files).toContain("ProfessionTraitSearch.toc");
			expect(result.files).toContain("package.json");
			expect(result.files).toContain("CHANGELOG.md");
			expect(result.files).toContain("README.md");
			expect(result.files).toContain("docs/mechanic-setup.md");

			const versions = await readAddonVersions(root);
			expect(versions.interface).toBe(120100);
			expect(versions.version).toBe("1.0.3");
			expect(versions.tocVersion).toBe("1.0.3");

			const toc = await Bun.file(join(root, "ProfessionTraitSearch.toc")).text();
			expect(toc).toContain("## Interface: 120100");
			expect(toc.includes("\r\n")).toBe(true);

			const changelog = await Bun.file(join(root, "CHANGELOG.md")).text();
			expect(changelog).toContain("## 1.0.3");
			expect(changelog).toContain("120100");
			expect(changelog).toContain("12.1.0");

			const readme = await Bun.file(join(root, "README.md")).text();
			expect(readme).toContain("**120100**");

			const mechanic = await Bun.file(join(root, "docs/mechanic-setup.md")).text();
			expect(mechanic).toContain("interface `120100`");
		} finally {
			await rm(root, { recursive: true, force: true });
		}
	});

	test("is a no-op when Interface already matches", async () => {
		const root = await fixtureRoot();
		try {
			const result = await applyRetailBump({
				root,
				interface: 120007,
				gameVersion: "12.0.7",
			});
			expect(result.changed).toBe(false);
			expect(result.files).toEqual([]);
			expect((await readAddonVersions(root)).version).toBe("1.0.2");
		} finally {
			await rm(root, { recursive: true, force: true });
		}
	});

	test("CLI dry-run uses --root and --interface", async () => {
		const root = await fixtureRoot();
		try {
			const proc = Bun.spawn(
				["bun", "scripts/retail-bump.ts", "--root", root, "--interface", "120100", "--dry-run"],
				{ cwd: join(import.meta.dir, ".."), stdout: "pipe", stderr: "pipe" },
			);
			const stdout = await new Response(proc.stdout).text();
			const code = await proc.exited;
			expect(code).toBe(0);
			const parsed = JSON.parse(stdout) as { changed: boolean; dryRun: boolean; to: { version: string } };
			expect(parsed.changed).toBe(true);
			expect(parsed.dryRun).toBe(true);
			expect(parsed.to.version).toBe("1.0.3");
			expect((await readAddonVersions(root)).interface).toBe(120007);
		} finally {
			await rm(root, { recursive: true, force: true });
		}
	});
});
