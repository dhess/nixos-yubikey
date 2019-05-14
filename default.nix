let

  localLib = import ./lib;
  outPath = localLib.fixedNixpkgs;

in
{ supportedSystems ? [ "x86_64-linux" ]
, nixpkgs ? { inherit outPath; revCount = 56789; shortRev = "gfedcba"; }
}:

let

  nixos = import (localLib.fixedNixpkgs + "/nixos/release.nix") {
    inherit supportedSystems nixpkgs;
  };
  nixos-yubikey = nixos.iso_minimal;

in
nixos-yubikey

