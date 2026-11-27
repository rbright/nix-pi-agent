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
  version = "1.7.0";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${finalAttrs.version}/pi-${finalAttrs.version}-source.tar.gz";
    hash = "sha256-9fz0YHSCRSN2awvCYyXaObY+/2B/qG7kjE0uvs1dd44=";
  };

  npmDepsHash = "sha256-ca1P7AdtYPeJ77N9qjLXCav5ZwcNxrANm+qrybmdtiI=";
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

  # Build the workspace dependencies of coding-agent in upstream order; chord,
  # ai, and agent import schema and telemetry. ai uses build:offline to skip
  # model fetches.
  preBuild = ''
    npm run build --workspace=packages/telemetry
    npm run build --workspace=packages/schema
    npm run build --workspace=packages/chord
    npm run build --workspace=packages/tui
    npm run build --workspace=packages/codemode
    npm run build --workspace=packages/mcp
    npm run build:offline --workspace=packages/ai
    npm run build --workspace=packages/agent
  '';

  postInstall = ''
    workspaceRoot="$out/lib/node_modules/pi-monorepo"
    mkdir -p "$workspaceRoot/packages"

    cp -r packages/{ai,agent,chord,codemode,mcp,schema,telemetry,tui,coding-agent} "$workspaceRoot/packages/"

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
