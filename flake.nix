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
          # The Rust CLI
          greviewer-cli = pkgs.rustPlatform.buildRustPackage {
            pname = "greviewer-cli";
            version = "0.1.0";
            src = ./cli;
            cargoLock.lockFile = ./Cargo.lock;
            
            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs; lib.optionals stdenv.isDarwin [
              libiconv
            ] ++ lib.optionals stdenv.isLinux [
              openssl
            ];
            
            # Let native-tls use system frameworks on macOS
            OPENSSL_NO_VENDOR = "1";
          };

          # The Neovim plugin
          greviewer-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "greviewer";
            version = "0.1.0";
            src = ./.;
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
