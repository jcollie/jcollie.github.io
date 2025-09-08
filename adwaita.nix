{
  lib,
  haskellPackages,
  stdenvNoCC,
  fetchgit,
}:
let
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "adwaita-fonts";
  version = "49.0";
  src = fetchgit {
    url = "https://gitlab.gnome.org/GNOME/adwaita-fonts";
    rev = finalAttrs.version;
    hash = "sha256-F3CG/L8DtYrzZijqXY+3jEylqcD39EBDauWpYFLIUUI=";
  };
  nativeBuildInputs = [
    haskellPackages.sfnt2woff
  ];
  buildPhase = ''
    runHook preBuild

    find . -name \*.ttf -exec sfnt2woff {} \;

    runHook postBbuild
  '';
  installPhase = ''
    runHook preInstall

    mkdir $out
    find . -name \*.ttf\* -exec cp {} $out \;
    find . -name \*.woff\* -exec cp {} $out \;

    runHook postInstall
  '';
  meta = {
    license = lib.licenses.ofl;
  };
})
