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
        mkPodmanWrapper = pkgs.writeShellScriptBin "podman" ''
          current_dir="$(pwd)"
          export HOME="$current_dir/.state/podman/"
          mkdir -p "$HOME/.config/podman"
          # TODO: need optimisation and move out and built / install stage only
          cp "$current_dir/.config/podman/containers.conf" "$HOME/.config/podman/containers.conf"
          cp "$current_dir/.config/podman/registries.conf" "$HOME/.config/podman/registries.conf"
          cp "$current_dir/.config/containers/policy.json" "$HOME/.config/containers/policy.json"
          exec ${pkgs.podman}/bin/podman "$@"
        '';
      in {
        packages.default = mkPodmanWrapper;
        devShell = pkgs.mkShell {
          buildInputs = [
            mkPodmanWrapper
            pkgs.runc
            pkgs.conmon
            pkgs.slirp4netns
            pkgs.fuse-overlayfs
          ];
        };
      });
}