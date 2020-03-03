let

  # Fetch (from GitHub) a Nix expression (i.e., repo), as specified by
  # its revision.
  fixedNixSrc = pathOverride: src:
  let
    try = builtins.tryEval (builtins.findFile builtins.nixPath pathOverride);
  in
    if try.success
      then builtins.trace "Using <${pathOverride}>" try.value
      else src;

  sources = import ../nix/sources.nix;

  fixedNixpkgs = fixedNixSrc "nixpkgs_override" sources.nixpkgs;
  nixpkgs = import fixedNixpkgs;
  pkgs = nixpkgs {};
  lib = pkgs.lib;

in lib //
{
  inherit fixedNixSrc fixedNixpkgs;
  inherit nixpkgs pkgs;
}
