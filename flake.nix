{
  description = "Configurable isolated Podman setup";
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
        mkPodmanWrapper = pkgs.writeShellScriptBin "podman" ''
          # Check if running as root
          if [ "$(id -u)" != "0" ]; then
            echo "This script must be run as root"
            exit 1
          fi
          
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
          
          # Set required capabilities
          ${pkgs.libcap}/bin/setcap cap_sys_admin,cap_net_admin,cap_sys_chroot+ep ${pkgs.podman}/bin/podman
          
          exec ${pkgs.podman}/bin/podman "$@"
        '';
      in {
        packages.default = mkPodmanWrapper;
        packages.configFiles = configFiles;
        devShell = pkgs.mkShell {
          buildInputs = [
            mkPodmanWrapper
            pkgs.runc
            pkgs.conmon
            pkgs.slirp4netns
            pkgs.fuse-overlayfs
            pkgs.libcap  # Added for setcap
          ];
        };
      });
}