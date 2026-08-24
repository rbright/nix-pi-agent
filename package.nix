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
  version = "0.84.3";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${finalAttrs.version}/pi-${finalAttrs.version}-source.tar.gz";
    hash = "sha256-x76ZO6zg08EFhf+1oxPLhJhDyNNn7s5EvyTPYERehNs=";
  };

  npmDepsHash = "sha256-cDx28+c4bwtQpiy5+BCvZhZezoZb4WRqfZj2eoEeMbw=";
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

  preBuild = ''
    npx tsgo -p packages/tui/tsconfig.build.json
    npx tsgo -p packages/telemetry/tsconfig.build.json
    npx tsgo -p packages/ai/tsconfig.build.json
    npx tsgo -p packages/agent/tsconfig.build.json
    npx tsgo -p packages/protocol/tsconfig.build.json
    npx tsgo -p packages/client/tsconfig.build.json
  '';

  postInstall = ''
    workspaceRoot="$out/lib/node_modules/pi-monorepo"
    mkdir -p "$workspaceRoot/packages"

    cp -r packages/{ai,agent,client,protocol,telemetry,tui,coding-agent} "$workspaceRoot/packages/"

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
