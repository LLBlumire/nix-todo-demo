{
  # A basic description of the project
  description = "Demo Nix Project";

  # Our input dependencies that need to be version locked
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  # Specifies our build outputs
  outputs = { self, nixpkgs, rust-overlay, ... }: let

    # This demo was only written for x86_64-linux, change this if building on mac
    system = "x86_64-linux";

    # Overlays add new 'plugins' to nix's default functionality
    overlays = [

      # The rust overlay makes working with rust much easier
      (import rust-overlay)

      # This custom overlay gives us a nicer name alias for 'current stable rust'
      (self: super: {
        rustToolchain = super.rust-bin.stable.latest.default;
      })
    ];

    # This applies our current system and our overlays to the package manager in this flake
    pkgs = import nixpkgs { inherit system overlays; };

  in {

    # Our first actual build output, a development shell with the software we need installed
    devShells."${system}".default = pkgs.mkShell {
      buildInputs = with pkgs; [
        rustToolchain
	sqlx-cli
	just
	sccache
      ];
    };
    
    # Our next build output will specify the packages we are able to build
    packages."${system}".default = (pkgs.makeRustPlatform {
      cargo = pkgs.rustToolchain;
      rustc = pkgs.rustToolchain;
    }).buildRustPackage {
      name = "nix-demo-project";
      src = ./.;
      cargoLock = {
        lockFile = ./Cargo.lock;
      };
      env = {
        SQLX_OFFLINE = "true";
      };
    };
  };
}
