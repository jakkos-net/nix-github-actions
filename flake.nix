{
  description = "Nix + GitHub Actions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , rust-overlay
    }:
    # Non-system-specific logic
    let
      # Borrow project metadata from the Rust config
      meta = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package;
      inherit (meta) name version;

      overlays = [
        # Rust helpers
        (import rust-overlay)
        # Build Rust toolchain using helpers from rust-overlay
        (self: super: {
          # This supplies cargo, rustc, rustfmt, etc.
          rustToolchain = super.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        })
      ];
    in
    # System-specific logic
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit overlays system; };
      in
      {
        devShells = {
          # Unified shell environment
          default = pkgs.mkShell
            {
              buildInputs = (with pkgs; [
                # Rust stuff (CI + dev)
                rustToolchain
                cargo-deny

                # Rust stuff (dev only)
                cargo-edit
                cargo-watch
              ]);
            };
        };

        packages = rec {
          default = testprog;

          testprog = pkgs.rustPlatform.buildRustPackage {
            pname = name;
            inherit version;
            src = ./.;
            cargoSha256 = "sha256-EzVn+486AQ0KVsWyS8T8/c4ZZZsFu+HowTSyCEQMLQY=";
            release = true;
          };
        };
      });
}
