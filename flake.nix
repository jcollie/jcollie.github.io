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
      packages = forAllSystems (pkgs: {
        adwaita-fonts = pkgs.callPackage ./adwaita.nix { };
        american-typewriter-fonts = pkgs.callPackage ./american-typewriter.nix { };
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
        generate-favicon =
          let
            program = pkgs.writeShellScript "generate-favicon" ''
              ${pkgs.imagemagickBig}/bin/magick \
                assets/rush-starman.png \
                -bordercolor white -border 0 \
                  \( -clone 0 -resize 16x16 \) \
                  \( -clone 0 -resize 24x24 \) \
                  \( -clone 0 -resize 32x32 \) \
                  \( -clone 0 -resize 48x48 \) \
                  \( -clone 0 -resize 57x57 \) \
                  \( -clone 0 -resize 64x64 \) \
                  \( -clone 0 -resize 72x72 \) \
                  \( -clone 0 -resize 76x76 \) \
                  \( -clone 0 -resize 96x96 \) \
                  \( -clone 0 -resize 110x110 \) \
                  \( -clone 0 -resize 114x114 \) \
                  \( -clone 0 -resize 120x120 \) \
                  \( -clone 0 -resize 128x128 \) \
                  \( -clone 0 -resize 144x144 \) \
                  \( -clone 0 -resize 152x152 \) \
                  \( -clone 0 -resize 180x180 \) \
                  \( -clone 0 -resize 195x195 \) \
                  \( -clone 0 -resize 196x196 \) \
                  \( -clone 0 -resize 228x228 \) \
                  \( -clone 0 -resize 270x270 \) \
                  \( -clone 0 -resize 558x558 \) \
                  -delete 0 -alpha off -colors 256 assets/favicon.ico
            '';
          in
          {
            type = "app";
            program = "${program}";
          };
      });
    };
}
