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
          echo '***********'
          echo $current_dir
          echo '***********'
          export HOME="$current_dir/.state/podman"
          mkdir -p "$HOME/.config/containers"
          cp "$current_dir/.config/containers/" "$HOME/.config/containers/"
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