{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_22,
  pkg-config,
  cairo,
  pango,
  libjpeg,
  giflib,
  librsvg,
  pixman,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-agent";
  version = "1.0.2";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${finalAttrs.version}/pi-${finalAttrs.version}-source.tar.gz";
    hash = "sha256-Bhz9AADdGRX3Igi1K2ODb50o3MibRJAa9eJ8Me4+W08=";
  };

  npmDepsHash = "sha256-gW0JO84SrPl3PDUu7eBzOKaNGSif23J1xY1tpS/oVhQ=";
  npmWorkspace = "packages/coding-agent";
  npmFlags = [ "--legacy-peer-deps" ];
  makeCacheWritable = true;
  patches = lib.optionals (builtins.pathExists ./package-lock.patch) [ ./package-lock.patch ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    cairo
    pango
    libjpeg
    giflib
    librsvg
    pixman
  ];

  # Upstream replaced tsgo with TypeScript 7 tsc. Build the workspace
  # dependencies of coding-agent; ai uses build:offline to skip model fetches.
  preBuild = ''
    npm run build --workspace=packages/chord
    npm run build --workspace=packages/tui
    npm run build --workspace=packages/telemetry
    npm run build --workspace=packages/codemode
    npm run build --workspace=packages/mcp
    npm run build:offline --workspace=packages/ai
    npm run build --workspace=packages/agent
  '';

  postInstall = ''
    workspaceRoot="$out/lib/node_modules/pi-monorepo"
    mkdir -p "$workspaceRoot/packages"

    cp -r packages/{ai,agent,chord,codemode,mcp,telemetry,tui,coding-agent} "$workspaceRoot/packages/"

    # Keep required workspace links and drop only unresolved leftovers.
    find "$workspaceRoot/node_modules" -xtype l -delete
  '';

  meta = {
    description = "Minimal terminal coding harness for agentic workflows";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
