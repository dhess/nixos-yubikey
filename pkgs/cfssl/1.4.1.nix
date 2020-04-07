{ stdenv
, lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "cfssl";
  version = "1.4.1";

  goPackagePath = "github.com/cloudflare/cfssl";
  modSha256 = "0mqrll5dgz6i8hpk4v2i0picyc8pns39sp2l7wvm0kf3syarch01";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cfssl";
    rev = "v${version}";
    sha256 = "07qacg95mbh94fv64y577zyr4vk986syf8h5l8lbcmpr0zcfk0pd";
  };

  meta = with lib; {
    homepage = https://cfssl.org/;
    description = "Cloudflare's PKI and TLS toolkit";
    license = licenses.bsd2;
    maintainers = lib.singleton lib.maintainers.dhess;
    platforms = platforms.all;
  };
}
