/// <reference types="bun" />

const root = `${import.meta.dir}/..`;

export async function syncTocVersion(): Promise<void> {
  const { version } = (await Bun.file(`${root}/package.json`).json()) as { version: string };
  const tocPath = `${root}/PerkLens.toc`;
  const toc = await Bun.file(tocPath).text();

  if (!/^## Version: .+$/m.test(toc)) {
    console.error("sync-toc-version: no ## Version line found in PerkLens.toc");
    process.exit(1);
  }

  await Bun.write(tocPath, toc.replace(/^## Version: .+$/m, `## Version: ${version}`));
  console.log(`sync-toc-version: PerkLens.toc -> ${version}`);
}

if (import.meta.main) {
  await syncTocVersion();
}
