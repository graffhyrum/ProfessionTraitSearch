/// <reference types="bun" />

const root = `${import.meta.dir}/..`;

export async function syncTocVersion(): Promise<void> {
  const { version } = (await Bun.file(`${root}/package.json`).json()) as { version: string };
  const tocPath = `${root}/ProfessionTraitSearch.toc`;
  const toc = await Bun.file(tocPath).text();
  const next = toc.replace(/^## Version: .+$/m, `## Version: ${version}`);
  if (next === toc) {
    console.error("sync-toc-version: no ## Version line found in ProfessionTraitSearch.toc");
    process.exit(1);
  }
  await Bun.write(tocPath, next);
  console.log(`sync-toc-version: ProfessionTraitSearch.toc -> ${version}`);
}

if (import.meta.main) {
  await syncTocVersion();
}
