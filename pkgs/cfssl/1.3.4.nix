{ stdenv
, buildGoPackage
, fetchFromGitHub
}:

buildGoPackage rec {
  pname = "cfssl";
  version = "1.3.4";

  goPackagePath = "github.com/cloudflare/cfssl";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cfssl";
    rev = version;
    sha256 = "0fpj7234xfqpbnjfrz45sx9grmr9wwsnhaz0mpfbswjll9v2d9rk";
  };

  meta = with stdenv.lib; {
    homepage = https://cfssl.org/;
    description = "Cloudflare's PKI and TLS toolkit";
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
