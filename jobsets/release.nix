let

  lib = import ../lib;
  inherit (lib) fixedNixpkgs;
  localPkgs = (import ../.) {};

in

{ supportedSystems ? [ "x86_64-linux" ]
, scrubJobs ? true
, nixpkgsArgs ? {
    config = { inHydra = true; };
  }
}:

with import (fixedNixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs nixpkgsArgs;
};

let

  x86_64 = [ "x86_64-linux" "x86_64-darwin" ];
  x86_64_linux = [ "x86_64-linux" ];
  linux = [ "x86_64-linux" "aarch64-linux" ];

  jobs = (mapTestOn (rec {

    localPkgs.nixos-yubikey = x86_64_linux;

  })) // (rec {

    x86_64-linux = pkgs.releaseTools.aggregate {
      name = "nixos-yubikey-x86_64-linux";
      meta.description = "nixos-yubikey (x86_64-linux)";
      constituents = with jobs; [
        localPkgs.nixos-yubikey.x86_64-linux
      ];
    };

  });

in
jobs
