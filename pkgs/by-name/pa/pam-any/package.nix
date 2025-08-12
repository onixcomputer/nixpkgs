{
  lib,
  rustPlatform,
  fetchFromGitHub,
  linux-pam,
}:

rustPlatform.buildRustPackage {
  pname = "pam-any";
  version = "0.0.0-unstable-2024-11-20";

  src = fetchFromGitHub {
    owner = "ChocolateLoverRaj";
    repo = "pam-any";
    rev = "e77687709d092a6bb77e57a444403798855075c0";
    hash = "sha256-em/vifkse1Qp3iX/oE1vHQK6UAoJvbhBOowhFhgQ+qw=";
  };

  cargoHash = "sha256-se9CUBtl4mPhaiB8lY4ft5xGSByS+ycaI0q3OKvwlbU=";

  nativeBuildInputs = [
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    linux-pam # <<< this is for pam-sys and is already specified in `defaultCrateOverrides`, but is that only for `buildRustCrate`? >>>
  ];

  meta = with lib; {
    description = "A PAM module that runs multiple other PAM modules in parallel, succeeding as long as one of them succeeds.";
    homepage = "https://github.com/ChocolateLoverRaj/pam-any";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ jfly ];
    platforms = with lib.platforms; linux;
  };
}
