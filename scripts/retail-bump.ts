/// <reference types="bun" />

import { resolve } from "node:path";
import { getArg, hasFlag } from "./lib/cli";
import { applyRetailBump } from "./lib/addon-metadata";
import { detectRetailClient, interfaceToGameVersion, parseInterface } from "./lib/wow-interface";

const root = resolve(getArg("root") ?? `${import.meta.dir}/..`);
const override = getArg("interface");
const iface = override ? parseInterface(override) : null;
const client = iface
	? { interface: iface, gameVersion: interfaceToGameVersion(iface), build: null, exePath: null }
	: await detectRetailClient(root);

if (!client) {
	process.stderr.write("retail-bump: Wow.exe not found; set WOW_RETAIL_DIR or pass --interface\n");
	process.exit(1);
}

const result = await applyRetailBump({
	root,
	interface: client.interface,
	gameVersion: client.gameVersion,
	dryRun: hasFlag("dry-run"),
});

console.log(JSON.stringify(result, null, 2));
