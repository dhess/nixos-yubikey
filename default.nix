let

  localLib = import ./lib;
  outPath = localLib.fixedNixpkgs;

in
{ supportedSystems ? [ "x86_64-linux" ]
, nixpkgs ? { inherit outPath; revCount = 56789; shortRev = "gfedcba"; }
}:

let

  pkgs = import nixpkgs { system = "x86_64-linux"; };

  nixos-yubikey-configuration = {

    ## Required packages and services.
    #
    # ref: https://rzetterberg.github.io/yubikey-gpg-nixos.html
    environment.systemPackages = with pkgs; [
      cryptsetup
      gnupg
      paperkey
      parted
      pcsclite
      pcsctools
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

    # Disable HISTFILE globally.
    environment.interactiveShellInit = ''
      unset HISTFILE
    '';

    boot.cleanTmpDir = true;
    boot.kernel.sysctl = {
      "kernel.unprivileged_bpf_disabled" = 1;
    };
  };


  ## Build the image.

  nixos = import (localLib.fixedNixpkgs + "/nixos/release.nix") {
    inherit supportedSystems nixpkgs;
    configuration = nixos-yubikey-configuration;
  };
  nixos-yubikey = nixos.iso_minimal;

in
nixos-yubikey
