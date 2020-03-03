let

  localLib = import ./lib;
  outPath = localLib.fixedNixpkgs;

in
{ system ? "x86_64-linux"
, crossSystem ? null
, config ? { allowBroken = true; }
, supportedSystems ? [ "x86_64-linux" ]
, nixpkgs ? { inherit outPath; revCount = 56789; shortRev = "gfedcba"; }
, pkgs ? import nixpkgs { inherit system crossSystem config; }
}:

let

  drduh-gpg-conf = pkgs.callPackage pkgs/drduh-gpg-conf {};

  cfssl_1_3_4 = pkgs.callPackage pkgs/cfssl/1.3.4.nix {};

  nixos-yubikey-configuration = {

    ## Image overrides.

    isoImage.isoBaseName = pkgs.lib.mkForce "nixos-yubikey";

    # Always copytoram so that, if the image is booted from, e.g., a
    # USB stick, nothing is mistakenly written to persistent storage.

    boot.kernelParams = [ "copytoram" ];

    ## Required packages and services.
    #
    # ref: https://rzetterberg.github.io/yubikey-gpg-nixos.html
    environment.systemPackages = with pkgs; [
      cfssl_1_3_4
      cryptsetup
      diceware
      ent
      git
      gitAndTools.git-extras
      gnupg
      (haskell.lib.justStaticExecutables haskellPackages.hopenpgp-tools)
      paperkey
      parted
      pcsclite
      pcsctools
      pgpdump
      pinentry-curses
      pwgen
      yubikey-manager
      yubikey-personalization
    ];
    services.udev.packages = [
      pkgs.yubikey-personalization
    ];
    services.pcscd.enable = true;


    ## Make sure networking is disabled in every way possible.

    boot.initrd.network.enable = false;
    networking.dhcpcd.enable = false;
    networking.dhcpcd.allowInterfaces = [];
    networking.firewall.enable = true;
    networking.useDHCP = false;
    networking.useNetworkd = false;
    networking.wireless.enable = false;


    ## Make it easy to tell which nixpkgs the image was built from.
    #
    # Most of the following config is thanks to Graham Christensen,
    # from:
    # https://github.com/grahamc/network/blob/1d73f673b05a7f976d82ae0e0e61a65d045b3704/modules/standard/default.nix#L56

    nix = {
      useSandbox = true;
      nixPath = [
        # Copy the channel version from the deploy host to the target
        "nixpkgs=/run/current-system/nixpkgs"
      ];
    };
    system.extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
    environment.etc.host-nix-channel.source = pkgs.path;


    ## Secure defaults.

    boot.cleanTmpDir = true;
    boot.kernel.sysctl = {
      "kernel.unprivileged_bpf_disabled" = 1;
    };


    ## Set up the shell for making keys.

    environment.interactiveShellInit = ''
      unset HISTFILE
      export GNUPGHOME=/run/user/$(id -u)/gnupg
      [ -d $GNUPGHOME ] || install -m 0700 -d $GNUPGHOME
      cp ${drduh-gpg-conf}/gpg.conf $GNUPGHOME
      echo "\$GNUPGHOME is $GNUPGHOME"
    '';
  };


  ## Build the image.

  nixos = import (localLib.fixedNixpkgs + "/nixos/release.nix") {
    inherit supportedSystems nixpkgs;
    configuration = nixos-yubikey-configuration;
  };
  nixos-yubikey = nixos.iso_minimal;

in
{
  inherit nixos-yubikey;
}
