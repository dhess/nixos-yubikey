{ stdenv
, fetchFromGitHub
}:

let

  version = "20200213";

  src = fetchFromGitHub {
    owner = "drduh";
    repo = "config";
    rev = "681a5e2252f8097e3f0ab70fc49b0977bb3cfe0c";
    sha256 = "0d7d1ma9hxq1ysc2jq737602qnyjg1gkdyxc791a7g3axcxph98z";
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
