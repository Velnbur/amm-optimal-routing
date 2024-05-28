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

        buildPdf = { name }:
          pkgs.writeScript "build-pdf" ''
            #!${pkgs.stdenv.shell}

            mkdir -p ${name}.out

            export FLAGS="-output-directory=${name}.out"

            xelatex $FLAGS ${name}.tex
            biber $FLAGS -aux_directory=${name}.out ${name}
            xelatex $FLAGS ${name}.tex
          '';

      in rec {
        packages.default = buildPdf { name = "index"; };

        devShells.default = pkgs.mkShell {
          buildInputs = (with pkgs; [ texliveFull ]);

          FONTCONFIG_FILE = pkgs.makeFontsConf {
            fontDirectories = [ pkgs.times-newer-roman ];
          };
        };
      });
}
