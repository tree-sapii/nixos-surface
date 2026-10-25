{
  config,
  lib,
  pkgs,
  ...
}:
let # this is to be transfered to default.nix and options.nix to be removed
  inherit (lib)
    mkDefault
    mkOption
    types
    optionals
    ;
  kernelVersions = import ./kernels.nix;
  inherit (pkgs.callPackage ./common.nix { }) buildSurfaceKernel patches;
  chosenKernel = kernelVersions.${config.hardware.nixos-surface.version};
  kernelPackages = buildSurfaceKernel {
    inherit (chosenKernel) version sha256;
    inherit patches;
  };
in
{
  options.hardware.nixos-surface.version = mkOption {
    description = "Choose the kernel version you want.";
    type = types.enum (builtins.attrNames kernelVersions);
    default = "6.18"; # current LTS til 2028
  };
  config = {
    boot = {
      inherit kernelPackages;
      kernelParams = mkDefault [ "mem_sleep_default=deep" ];
    };
    hardware = {
      enableRedistributableFirmware = mkDefault true;
      sensor.iio.enable = mkDefault true;
      blacklistedKernelModules = optionals (!config.hardware.enableRedistributableFirmware) [
        "ath3k"
      ];
      cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
    services.fstrim.enable = lib.mkDefault true;
    services.iptsd.enable = lib.mkDefault true;
    environment.systemPackages = [ pkgs.surface-control ];

  };
}
