{
  description = "GitHub PR reviewer for Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          greviewer-cli = pkgs.rustPlatform.buildRustPackage {
            pname = "greviewer-cli";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
            
            cargoBuildFlags = [ "-p" "greviewer-cli" ];
            cargoTestFlags = [ "-p" "greviewer-cli" ];
            
            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs; lib.optionals stdenv.isDarwin [
              apple-sdk_15
            ] ++ lib.optionals stdenv.isLinux [
              openssl
            ];
          };

          # The Neovim plugin
          greviewer-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "greviewer";
            version = "0.1.0";
            src = ./.;
            doCheck = false;
          };

          default = self.packages.${system}.greviewer-cli;
        };
      }
    ) // {
      # Overlay for easy integration
      overlays.default = final: prev: {
        greviewer-cli = self.packages.${prev.system}.greviewer-cli;
        vimPlugins = prev.vimPlugins // {
          greviewer-nvim = self.packages.${prev.system}.greviewer-nvim;
        };
      };
    };
}
