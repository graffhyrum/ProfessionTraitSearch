import { Resvg } from "@resvg/resvg-js";
import { join } from "node:path";

const root = import.meta.dir.replace(/\\/g, "/").replace(/\/scripts$/, "");
const assets = join(root, "assets");

type ExportSpec = {
  svg: string;
  png: string;
  width: number;
  height?: number;
};

const exports: ExportSpec[] = [
  { svg: "pts-icon.svg", png: "pts-icon-512.png", width: 512, height: 512 },
  { svg: "pts-icon.svg", png: "pts-icon-64.png", width: 64, height: 64 },
  { svg: "pts-logo-banner.svg", png: "pts-logo-banner.png", width: 1200, height: 400 },
];

for (const spec of exports) {
  const svgPath = join(assets, spec.svg);
  const svg = await Bun.file(svgPath).text();
  const resvg = new Resvg(svg, {
    fitTo: { mode: "width", value: spec.width },
  });
  const pngData = resvg.render().asPng();
  const outPath = join(assets, spec.png);
  await Bun.write(outPath, pngData);
  console.log(`wrote ${outPath} (${spec.width}${spec.height ? `x${spec.height}` : ""})`);
}
