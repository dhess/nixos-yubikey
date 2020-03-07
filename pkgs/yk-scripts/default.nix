# A set of scripts to perform various common YubiKey configuration
# functions. In a few cases, these are just one-liners, but I think
# those are still useful because they're easier to remember, once you
# get in the habit of looking for `yk-*` scripts.

{ gnupg
, newt
, yubikey-manager
, symlinkJoin
, writeShellScriptBin
, lib
}:

let

  gpg = "${gnupg}/bin/gpg";
  whiptail = "${newt}/bin/whiptail";
  ykman = "${yubikey-manager}/bin/ykman";

  opts = ''
    basename=`basename "$0"`

    show_help() {
      echo "Usage: $basename [--help]"
      echo
      echo "--help     Show usage."
    }

    while :; do
        case $1 in
            -h|-\?|--help)
                show_help    # Display a usage synopsis.
                exit
                ;;
            -?*)
                printf 'Unknown option: %s\n' "$1" >&2
                exit 99
                ;;
            *)               # Default case: No more options, so break out of the loop.
                break
        esac
        shift
    done
  '';

  nfc-opts = ''
    basename=`basename "$0"`

    show_help() {
      echo "Usage: $basename [--nfc]"
      echo
      echo "-n, --nfc       YubiKey has NFC capabilities."
    }

    nfc=""

    while :; do
        case $1 in
            -h|-\?|--help)
                show_help    # Display a usage synopsis.
                exit
                ;;
            -n|--nfc)
                nfc="--nfc"
                ;;
            -?*)
                printf 'Unknown option: %s\n' "$1" >&2
                exit 99
                ;;
            *)               # Default case: No more options, so break out of the loop.
                break
        esac
        shift
    done
  '';

  yk-scripts = rec {
    # Run all these script in one go. Useful for YubiKey initialization
    # out of the box.
    #
    # This script uses the `yk-gpg-set-default-touch` version of the
    # OpenPGP touch settings; i.e., it requires touch for encryption and
    # signing, but not authentication.
    #
    # We sleep for 2s between operations to let everything settle.

    yk-init = writeShellScriptBin "yk-init" ''
      set -e

      pause() {
        sleep 2
      }

      ${nfc-opts}

      ${yk-reset}/bin/yk-reset
      pause
      ${yk-gpg-change-pin}/bin/yk-gpg-change-pin
      pause
      ${yk-gpg-set-default-touch}/bin/yk-gpg-set-default-touch
      pause
      ${yk-piv-change-puk}/bin/yk-piv-change-puk
      pause
      ${yk-otp-disable}/bin/yk-otp-disable $nfc
      pause
      ${yk-oath-disable}/bin/yk-oath-disable $nfc
      pause
      echo
      ${ykman} openpgp info
      echo
      ${ykman} info
      echo
      echo "Your YubiKey is now ready to be used."
    '';


    # Reset a YubiKey to its factory configuration, except for any
    # disabled modes, which will remain disabled.
    #
    # Note that OATH reset will fail if OATH has been disabled, so we
    # ignore errors from that step.

    yk-reset = writeShellScriptBin "yk-reset" ''
      set -e

      ${opts}

      if (${whiptail} --title "Reset YubiKey?" --defaultno --yesno "Do you really want to reset this YubiKey? All keys will be erased and all PINs will be reset to their default values." 8 78); then
        echo "Proceeding with YubiKey reset."
      else
        echo "Aborting YubiKey reset."
        exit 1
      fi

      echo "Resetting FIDO2 configuration (note: deletes U2F and FIDO2 keys)..."
      echo "(Note: you may need to touch the YubiKey to proceed with the FIDO2 reset.)"
      ${ykman} fido reset --force
      echo "done."

      echo "Resetting OATH configuration..."
      ${ykman} oath reset --force
      echo "done."

      echo "Resetting OpenPGP configuration (note: wipes GPG keys)..."
      ${ykman} openpgp reset --force
      echo "done."

      echo "Resetting PIV configuration (note: deletes PIV certificates)..."
      ${ykman} piv reset --force
      echo "done."
    '';


    # Disable OTP, and disable the OTP USB mode, for good measure.

    yk-otp-disable = writeShellScriptBin "yk-otp-disable" ''
      set -e

      ${nfc-opts}

      echo "Disabling OTP functions... "

      if [ "$nfc" == "--nfc" ] ; then
          ${ykman} config nfc --force --disable OTP
      fi
      ${ykman} mode --force FIDO+CCID

      # This will sometimes fail if we first set the mode as above.
      # In any case, it's not needed once we disable USB OTP mode.
      #${ykman} config usb --force --disable OTP
    '';


    # Disable OATH.
    #
    # Not all keys support NFC, so we ignore errors from the NFC bit.

    yk-oath-disable = writeShellScriptBin "yk-oath-disable" ''
      set -e

      ${nfc-opts}

      if [ "$nfc" == "--nfc" ] ; then
        ${ykman} config nfc --force --disable OATH
      fi
      ${ykman} config usb --force --disable OATH
    '';


    # Change the YubiKey OpenPGP Card PIN.
    #
    # This script can be used to change either the user PIN (answer "1"
    # at the prompt), or the Admin PIN (answer "3" at the prompt).

    yk-gpg-change-pin = writeShellScriptBin "yk-gpg-change-pin" ''
      set -e

      ${opts}

      echo "Changing the YubiKey OpenPGP (admin|user) PIN... "
      ${gpg} --change-pin
      echo "done."
    '';


    # Enforce touch on OpenPGP encryption and signing.
    #
    # We don't enforce touch on OpenPGP authentication, because if
    # you're using your OpenPGP key for SSH authentication, it's often
    # not apparent that your SSH client is waiting for you to touch the
    # YubiKey. (If you have a YubiKey with a blinking LED, you may want
    # to use the `yk-gpg-set-all-touch` script, instead.)
    #
    # Note that changing these touch settings requires knowledge of the
    # YubiKey's OpenPGP Admin PIN.

    yk-gpg-set-default-touch = writeShellScriptBin "yk-gpg-set-default-touch" ''
      set -e

      ${opts}      

      echo "Configuring OpenPGP to require touch for signing and encryption."
      echo
      echo "You'll be prompted for the YubiKey's OpenPGP admin PIN once"
      echo "for each operation."
      echo

      echo "Disabling touch for OpenPGP authentication... "
      ${ykman} openpgp set-touch --force aut off
      echo "done."

      echo "Requiring touch for OpenPGP encryption... "
      ${ykman} openpgp set-touch --force enc on
      echo "done."

      echo "Requiring touch for OpenPGP signing... "
      ${ykman} openpgp set-touch --force sig on
      echo "done."
    '';


    # Enforce touch on all OpenPGP operations.
    #
    # Note that changing these touch settings requires knowledge of the
    # YubiKey's OpenPGP Admin PIN.

    yk-gpg-set-all-touch = writeShellScriptBin "yk-gpg-set-all-touch" ''
      set -e

      ${opts}

      echo "Configuring OpenPGP to require touch for all operations."
      echo
      echo "You'll be prompted for the YubiKey's OpenPGP admin PIN once"
      echo "for each operation."
      echo

      echo "Requiring touch for OpenPGP authentication... "
      ${ykman} openpgp set-touch --force aut on
      echo "done."

      echo "Requiring touch for OpenPGP encryption... "
      ${ykman} openpgp set-touch --force enc on
      echo "done."

      echo "Requiring touch for OpenPGP signing... "
      ${ykman} openpgp set-touch --force sig on
      echo "done."
    '';


    # Change the PIV PUK.

    yk-piv-change-puk = writeShellScriptBin "yk-piv-change-puk" ''
      set -e

      ${opts}

      echo "Changing the PIV PUK... "
      ${ykman} piv change-puk
      echo "done."
    '';
  };

in
symlinkJoin {
  name = "yk-scripts";
  paths = lib.attrValues yk-scripts;
}
