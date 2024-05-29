{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs, ... }:
    let
      systems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
    in flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs { inherit system; };

        buildPdf = { name, run-biber ? true }:
          let
            runXelatex = ''
              xelatex $FLAGS ${name}/index.tex
            '';
            runBiber = ''
              biber $FLAGS ${name}.out/index.bcf
              ${runXelatex}
            '';
            runBiberOptional = if run-biber then runBiber else "";
          in pkgs.writeShellScriptBin "build-pdf-${name}" ''
            #!${pkgs.stdenv.shell}
            set -e
            mkdir -p ${name}.out

            export FLAGS="-output-directory=${name}.out"

            ${runXelatex}
            ${runBiberOptional}
          '';

      in rec {
        packages = {
          default = self.packages.index;
          paper = buildPdf { name = "paper"; };
          presentation = buildPdf {
            name = "presentation";
            run-biber = false;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = (with pkgs; [ texliveFull ]);

          FONTCONFIG_FILE = pkgs.makeFontsConf {
            fontDirectories = [ pkgs.times-newer-roman ];
          };
        };
      });
}
