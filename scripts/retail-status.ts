/// <reference types="bun" />

import { resolve } from "node:path";
import { getArg } from "./lib/cli";
import { readAddonVersions } from "./lib/addon-metadata";
import { detectRetailClient, parseInterface } from "./lib/wow-interface";

const root = resolve(getArg("root") ?? `${import.meta.dir}/..`);
const from = await readAddonVersions(root);
const override = getArg("interface");
const client = override
	? { interface: parseInterface(override), gameVersion: null, build: null, exePath: null }
	: await detectRetailClient(root);

const result = {
	tocInterface: from.interface,
	tocVersion: from.tocVersion,
	packageVersion: from.version,
	client,
	outdated: client !== null && client.interface !== from.interface,
};

console.log(JSON.stringify(result, null, 2));
if (!client && !override) {
	process.stderr.write("retail-status: Wow.exe not found; set WOW_RETAIL_DIR or pass --interface\n");
	process.exit(2);
}
