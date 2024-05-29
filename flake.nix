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
            runBiberShell = if run-biber then ''
              biber $FLAGS ${name}.bcf
              xelatex $FLAGS ${name}.tex
            '' else
              "";
          in pkgs.writeShellScriptBin "build-pdf-${name}" ''
            #!${pkgs.stdenv.shell}

            set -e

            mkdir -p ${name}.out

            export FLAGS="-output-directory=${name}.out"
            run_biber=${runBiberShell}

            xelatex $FLAGS ${name}.tex
            ${runBiberShell}
          '';

      in rec {
        packages = {
          default = self.packages.index;
          index = buildPdf { name = "index"; };
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
