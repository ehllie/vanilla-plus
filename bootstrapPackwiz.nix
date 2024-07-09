# Copied and reworked from https://github.com/Infinidoge/nix-minecraft/blob/master/pkgs/tools/fetchPackwizModpack/default.nix
{ lib, stdenvNoCC, fetchurl, jre_headless, jq, moreutils, curl, cacert, updog }:

let
  bootstrapPackwiz =
    { src
    , packHash ? ""
      # Either 'server' or 'both' (to get client mods as well)
    , side ? "server"
    , ...
    }@args:
    let
      toml = builtins.fromTOML (builtins.readFile (src + "/pack.toml"));
      pname = args.pname or toml.name;
      version = args.version or toml.version;
      drv = bootstrapPackwiz args;
    in

    stdenvNoCC.mkDerivation (finalAttrs: {
      inherit pname version;

      packwizInstaller = fetchurl rec {
        pname = "packwiz-installer";
        version = "0.5.8";
        url = "https://github.com/packwiz/${pname}/releases/download/v${version}/${pname}.jar";
        hash = "sha256-+sFi4ODZoMQGsZ8xOGZRir3a0oQWXjmRTGlzcXO/gPc=";
      };

      packwizInstallerBootstrap = fetchurl rec {
        pname = "packwiz-installer-bootstrap";
        version = "0.0.3";
        url = "https://github.com/packwiz/${pname}/releases/download/v${version}/${pname}.jar";
        hash = "sha256-qPuyTcYEJ46X9GiOgtPZGjGLmO/AjV2/y8vKtkQ9EWw=";
      };

      dontUnpack = true;

      nativeBuildInputs = [ updog ];

      buildInputs = [ jre_headless jq moreutils curl cacert ];

      buildPhase = ''
        runHook preBuild

        cd $src
        updog &
        UPDOG_PID=$!
        cd -

        until curl 127.0.0.1:9090/pack.toml > /dev/null; do
          sleep 1
          echo "Waiting for server to start..."
        done

        java -jar "$packwizInstallerBootstrap" \
          --bootstrap-main-jar "$packwizInstaller" \
          --bootstrap-no-update \
          --no-gui \
          --side "${side}" \
          "http://127.0.0.1:9090/pack.toml"

        kill $UPDOG_PID

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        # Fix non-determinism
        rm env-vars -r
        jq -Sc '.' packwiz.json | sponge packwiz.json

        mkdir -p $out
        cp * -r $out/
        cp $src/pack.toml $out/

        runHook postInstall
      '';

      dontFixup = true;

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = packHash;

      passthru.addFiles = files: stdenvNoCC.mkDerivation {
        inherit pname version;
        src = null;
        dontUnpack = true;
        dontConfig = true;
        dontBuild = true;
        dontFixup = true;

        installPhase = ''
          cp -as "${drv}" $out
          chmod u+w -R $out
        '' + lib.concatLines (lib.mapAttrsToList
          (name: file: ''
            mkdir -p "$out/$(dirname "${name}")"
            cp -as "${file}" "$out/${name}"
          '')
          files
        );

        passthru = { inherit (drv) manifest; };
        meta = drv.meta or { };
      };
    } // args);
in
bootstrapPackwiz
