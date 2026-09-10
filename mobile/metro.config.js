// Monorepo support (the official Expo pattern): Metro needs to watch the
// workspace root — not just mobile/ — so edits to packages/shared are
// picked up, and needs to look in both this package's node_modules and
// the hoisted root node_modules to resolve @mauit/shared.
const { getDefaultConfig } = require("expo/metro-config");
const path = require("path");

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, "..");

const config = getDefaultConfig(projectRoot);

config.watchFolders = [workspaceRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
];

module.exports = config;
