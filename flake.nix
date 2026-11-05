{
  description = "Flake providing up to date linux-surface kernels and modules.";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
    nixosModules = {
      default = import ./.;
    };
    packages = builtins.mapAttrs (
      system: pkgs:
      let

        kernelVersions = import ./kernels.nix;
        inherit (pkgs.callPackage ./common.nix { }) buildSurfaceKernel patches;
        kernels = pkgs.lib.mapAttrs' (n: v: {
          name = pkgs.lib.replaceStrings [ "." ] [ "_" ] n;
          value = (
            buildSurfaceKernel {
              inherit (v) version sha256;
              inherit patches;
            }
          );
        }

        ) kernelVersions;

      in
      kernels
      // {
        default = inputs.self.packages.${system}."6_12";
        build-and-push = pkgs.writeShellApplication {
          name = "build-and-push";
          runtimeInputs = [
            pkgs.nix
            pkgs.cachix
          ];
          text = "nix build ${
            builtins.concatStringsSep " " (
              map (v: ".#${pkgs.lib.replaceStrings [ "." ] [ "_" ] v}.kernel") (
                pkgs.lib.attrNames (import ./kernels.nix)
              )
            )
          } --no-link --print-out-paths | cachix push nixos-on-surface ";
        };
      }
    ) inputs.nixpkgs.legacyPackages;
    apps = builtins.mapAttrs (system: pkgs: {
      default = {
        type = "app";
        program = pkgs.lib.getExe inputs.self.packages.${system}.build-and-push;
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
