{
  buildLinux,
  linuxPackagesFor,
  lib,
  fetchFromGitHub,
  fetchurl,
}:
{

  patches = fetchFromGitHub {
    owner = "linux-surface";
    repo = "linux-surface";
    rev = "master"; # change this to an actaull tagged release ( can be recent )
    hash = "sha256-oAgs2x4eJtdEehX4mQSgsEbGC71DvETQZy2VwOj0oTU=";
  };
  buildSurfaceKernel =
    {
      version,
      sha256,
      patches,
    }:
    linuxPackagesFor (buildLinux {
      inherit version;
      src = fetchurl {
        url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
        inherit sha256;
      };
      configfile = "${patches}/configs/${lib.versions.majorMinor version}";
      kernelPatches =
        lib.mapAttrsToList
          (name: _: {
            inherit name;
            patch = "${patches}/patches/${lib.versions.majorMinor version}/${name}";
          })
          # the BASE file doesn't do anything and breaks the build during patchPhase
          (removeAttrs (builtins.readDir "${patches}/patches/${lib.versions.majorMinor version}") [ "BASE" ]);
      modDirVersion = lib.versions.pad 3 version;
    });

}
