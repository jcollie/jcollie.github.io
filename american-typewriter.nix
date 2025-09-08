{
  haskellPackages,
  stdenvNoCC,
  unzip,
}:
let
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "american-typewriter";
  src = ./american-typewriter.zip;
  nativeBuildInputs = [
    haskellPackages.sfnt2woff
    unzip
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
  meta = { };
})
