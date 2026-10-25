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
        inherit (pkgs.callPackage ./common.nix) buildSurfaceKernel patches;
        kernels = pkgs.lib.mapAttrs (
          _: v:
          buildSurfaceKernel {
            inherit (v) version sha256;
            inherit patches;
          }
        ) kernelVersions;

      in
      kernels
      // {
        default = inputs.self.packages.${system}."6.18";
      }
    ) inputs.nixpkgs.legacyPackages;
  };
}
