/// <reference types="bun" />

import { Glob } from "bun";
import { join, relative } from "node:path";
import { rm } from "node:fs/promises";

const ADDON_NAME = "ProfessionTraitSearch";
const root = `${import.meta.dir}/..`;

const INCLUDE_ROOTS = [
  "ProfessionTraitSearch.toc",
  "LICENSE",
  "libs",
  "core",
  "ui",
  "assets",
] as const;

function normalizeRel(path: string): string {
  return path.replace(/\\/g, "/");
}

async function stageIncludeRoot(addonDir: string, item: string): Promise<void> {
  const srcRoot = join(root, item);
  const srcFile = Bun.file(srcRoot);

  if (await srcFile.exists()) {
    await Bun.write(join(addonDir, item), srcFile);
    return;
  }

  let staged = false;
  const glob = new Glob("**/*");

  for await (const relPath of glob.scan({ cwd: srcRoot, onlyFiles: true })) {
    const rel = normalizeRel(`${item}/${relPath}`);
    staged = true;
    await Bun.write(join(addonDir, rel), Bun.file(join(srcRoot, relPath)));
  }

  if (!staged) {
    console.error(`package-local: missing required path ${item}`);
    process.exit(1);
  }
}

async function readVersion(): Promise<string> {
  const { version } = (await Bun.file(`${root}/package.json`).json()) as { version: string };
  if (!version) {
    console.error("package-local: package.json is missing version");
    process.exit(1);
  }
  return version;
}

export async function packageLocal(): Promise<string> {
  const version = await readVersion();
  const releaseDir = join(root, ".release");
  const stagingRoot = join(releaseDir, "staging");
  const addonDir = join(stagingRoot, ADDON_NAME);
  const zipName = `${ADDON_NAME}-${version}.zip`;
  const zipPath = join(releaseDir, zipName);

  await rm(stagingRoot, { recursive: true, force: true });
  await rm(zipPath, { force: true });

  for (const item of INCLUDE_ROOTS) {
    await stageIncludeRoot(addonDir, item);
  }

  const tar = await Bun.$`tar -a -c -f ${zipPath} -C ${stagingRoot} ${ADDON_NAME}`.quiet();
  if (tar.exitCode !== 0) {
    console.error("package-local: tar failed to create zip");
    process.exit(tar.exitCode);
  }

  await rm(stagingRoot, { recursive: true, force: true });

  console.log(`package-local: ${normalizeRel(relative(root, zipPath))}`);
  console.log("package-local: unzip into Interface/AddOns/ to install");
  return zipPath;
}

if (import.meta.main) {
  await packageLocal();
}
