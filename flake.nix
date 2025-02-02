{
  description = "Configurable isolated Podman setup with rootless port binding";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        configFiles = pkgs.stdenv.mkDerivation {
          name = "podman-config";
          src = ./config;
          
          installPhase = ''
            mkdir -p $out/config
            cp -r * $out/config/
          '';
        };

        podmanWithCaps = pkgs.runCommand "podman-with-caps" {
          nativeBuildInputs = [ pkgs.libcap ];
        } ''
          cp -r ${pkgs.podman} $out
          setcap cap_net_bind_service=+ep $out/bin/podman
        '';

        mkPodmanWrapper = pkgs.writeShellScriptBin "podman" ''
          current_dir="$(pwd)" 
          export HOME="$current_dir/.state/podman"
          mkdir -p "$HOME/.config/podman"
          mkdir -p "$HOME/.config/containers"

          if [ ! -f "$HOME/.config/podman/registries.conf" ]; then
            cp ${configFiles}/config/podman/registries.conf "$HOME/.config/podman/"
            cp ${configFiles}/config/containers/containers.conf "$HOME/.config/containers/"
            cp ${configFiles}/config/containers/policy.json "$HOME/.config/containers/"
          fi

          export CONTAINERS_REGISTRIES_CONF="$HOME/.config/podman/registries.conf"

          exec ${podmanWithCaps}/bin/podman "$@"
        '';
      in {
        packages.default = mkPodmanWrapper;
        packages.configFiles = configFiles;

        devShell = pkgs.mkShell {
          buildInputs = [
            mkPodmanWrapper
            podmanWithCaps
            pkgs.runc
            pkgs.conmon
            pkgs.slirp4netns
            pkgs.fuse-overlayfs
            pkgs.libcap # Needed for setcap
          ];
        };
      });
}
