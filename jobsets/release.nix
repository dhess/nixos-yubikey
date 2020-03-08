let

  lib = import ../lib;
  inherit (lib) fixedNixpkgs;
  localPkgs = (import ../.) {};

in

{ supportedSystems ? [ "x86_64-linux" ]
, scrubJobs ? true
, pkgs ? lib.pkgs
, nixpkgsArgs ? {
    config = { inHydra = true; };
  }
}:

with import (fixedNixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs nixpkgsArgs;
  packageSet = import ../.;
};

let

in pkgs.lib.fix (jobsets: {
  x86_64-linux = pkgs.releaseTools.aggregate {
    name = "nixos-yubikey-x86_64-linux";
    meta.description = "nixos-yubikey (x86_64-linux)";
    constituents = with jobs; [
      localPkgs.nixos-yubikey.x86_64-linux
      localPkgs.nixos-yubikey-uk.x86_64-linux
    ];
  };
})
