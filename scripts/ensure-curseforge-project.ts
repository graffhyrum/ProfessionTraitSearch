/// <reference types="bun" />

const root = `${import.meta.dir}/..`;
const TOC = `${root}/ProfessionTraitSearch.toc`;
const WOW_GAME_ID = 432;
const SEARCH = "Profession Trait Search";

function apiToken(): string {
  const key = process.env.CF_API_KEY ?? process.env.CURSEFORGE_API_KEY;
  if (!key) {
    console.error("ensure-curseforge-project: CF_API_KEY or CURSEFORGE_API_KEY required");
    process.exit(1);
  }
  return key;
}

async function cfFetch(url: string, init?: RequestInit): Promise<Response> {
  return fetch(url, {
    ...init,
    headers: {
      Accept: "application/json",
      "x-api-token": apiToken(),
      ...(init?.headers ?? {}),
    },
  });
}

async function searchProject(): Promise<number | null> {
  const url = `https://api.curseforge.com/v1/mods/search?gameId=${WOW_GAME_ID}&searchFilter=${encodeURIComponent(SEARCH)}&pageSize=25`;
  const res = await cfFetch(url);
  if (!res.ok) {
    console.error(`ensure-curseforge-project: search failed (${res.status})`);
    process.exit(1);
  }
  const body = (await res.json()) as {
    data?: Array<{ id: number; name: string; slug: string }>;
  };
  const mods = body.data ?? [];
  const exact = mods.find(
    (mod) => mod.name.toLowerCase() === SEARCH.toLowerCase() || mod.slug === "profession-trait-search",
  );
  return exact?.id ?? mods[0]?.id ?? null;
}

async function readTocProjectId(): Promise<number | null> {
  const toc = await Bun.file(TOC).text();
  const match = toc.match(/^## X-Curse-Project-ID:\s*(\d+)\s*$/m);
  return match ? Number(match[1]) : null;
}

async function writeTocProjectId(id: number): Promise<void> {
  const toc = await Bun.file(TOC).text();
  if (/^## X-Curse-Project-ID:\s*\d+\s*$/m.test(toc)) {
    await Bun.write(TOC, toc.replace(/^## X-Curse-Project-ID:\s*\d+\s*$/m, `## X-Curse-Project-ID: ${id}`));
    return;
  }
  const anchor = "## Category-enUS: Professions";
  if (!toc.includes(anchor)) {
    console.error("ensure-curseforge-project: Category-enUS anchor missing in TOC");
    process.exit(1);
  }
  await Bun.write(TOC, toc.replace(anchor, `${anchor}\n\n## X-Curse-Project-ID: ${id}`));
}

export async function ensureCurseForgeProjectId(): Promise<number> {
  const existing = await readTocProjectId();
  if (existing) {
    console.log(`ensure-curseforge-project: TOC already has ${existing}`);
    return existing;
  }

  const id = await searchProject();
  if (!id) {
    console.error(
      "ensure-curseforge-project: no CurseForge project found — create one at https://authors.curseforge.com/#/projects/create/432 and re-run",
    );
    process.exit(1);
  }

  await writeTocProjectId(id);
  console.log(`ensure-curseforge-project: wrote X-Curse-Project-ID ${id} to ProfessionTraitSearch.toc`);
  return id;
}

if (import.meta.main) {
  await ensureCurseForgeProjectId();
}
