{
  description = "zine-blog";
  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    };
    zine = {
      url = "git+https://github.com/jcollie/zine.git?ref=jeff";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      zine,
      ...
    }:
    let
      makePackages =
        system:
        import nixpkgs {
          inherit system;
        };
      forAllSystems = (
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
        ] (system: function (makePackages system))
      );
    in
    {
      devShells = forAllSystems (pkgs: {
        zig_0_15 = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.zig_0_15
            pkgs.pinact
            zine.packages.${pkgs.system}.zine
          ];
        };
        default = self.devShells.${pkgs.system}.zig_0_15;
      });
      apps = forAllSystems (pkgs: {
        release =
          let
            program = pkgs.writeShellScript "build-website" ''
              ${pkgs.lib.getExe zine.packages.${pkgs.system}.zine} release
            '';
          in
          {
            type = "app";
            program = "${program}";
          };
      });
    };
}
