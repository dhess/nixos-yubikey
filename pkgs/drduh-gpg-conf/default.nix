{ stdenv
, fetchFromGitHub
}:

let

  version = "20190106";

  src = fetchFromGitHub {
    owner = "drduh";
    repo = "config";
    rev = "1d69c9c6be427b1c3b9febe8defc36594a3f75b5";
    sha256 = "0dhx5lki4y5w058vrw2i55xwja8mj1agsr9dxhap05b5pp88psbm";
  };

in
stdenv.mkDerivation {
  name = "drduh-gpg-conf-${version}";

  inherit src;

  dontBuild = true;

  installPhase = ''
    mkdir $out
    cp $src/gpg.conf $out/gpg.conf
  '';

  meta = with stdenv.lib; {
    description = "drduh's gpg.conf";
    homepage    = https://github.com/drduh/config;
    license     = licenses.mit;
  };
}
