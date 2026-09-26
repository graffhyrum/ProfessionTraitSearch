/// <reference types="bun" />

export function hasFlag(name: string, argv = process.argv): boolean {
	return argv.includes(`--${name}`);
}

export function getArg(name: string, argv = process.argv): string | undefined {
	const index = argv.indexOf(`--${name}`);
	if (index === -1) {
		return undefined;
	}
	const value = argv[index + 1];
	if (!value || value.startsWith("--")) {
		return undefined;
	}
	return value;
}
