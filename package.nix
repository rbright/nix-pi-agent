{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
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
  version = "0.80.7";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    rev = "v${finalAttrs.version}";
    hash = "sha256-s7dD82fugvWRvqL1VTcEwCIR5JI6t7VeFHR9NdMtG00=";
  };

  npmDepsHash = "sha256-Bd/NIt3lyQR5Y7P+HksPxMQvJc0AjVfDi1M1bH3/eOg=";
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
    npx tsgo -p packages/ai/tsconfig.build.json
    npx tsgo -p packages/agent/tsconfig.build.json
  '';

  postInstall = ''
    workspaceRoot="$out/lib/node_modules/pi-monorepo"
    mkdir -p "$workspaceRoot/packages"

    cp -r packages/{ai,agent,tui,coding-agent} "$workspaceRoot/packages/"

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
