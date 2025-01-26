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
         ];
       };
     });
}