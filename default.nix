with (import <nixpkgs> {});
let env = bundlerEnv {
    name = "jeffs-stuff";
    inherit ruby;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };
in stdenv.mkDerivation {
  name = "jeffs-stuff";
  buildInputs = [env bundler jekyll ruby];
}
