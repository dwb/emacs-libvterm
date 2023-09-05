{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs lib.platforms.unix;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
      buildInputs = (system: with pkgs.${system}; [ libvterm-neovim ]);
      nativeBuildInputs = (system: with pkgs.${system}; [ cmake ]);
    in
      {
        packages = forAllSystems (system:
          let
            sysPkgs = pkgs.${system};
          in
            {
              default = sysPkgs.stdenv.mkDerivation {
                pname = "emacs-libvterm";
                version = "1.0.0";

                src = ./.;

                buildInputs = buildInputs system;
                nativeBuildInputs = nativeBuildInputs system;

                configurePhase = ''
                  cmake -G 'Unix Makefiles' -S . -B .
                '';

                installPhase = ''
                  mkdir -p "$out"
                  mv vterm-module.so "$out/"
                '';
              };
            });

        shells = forAllSystems (system:
          {
            default = pkgs.${system}.mkShell {
              packages = (buildInputs system) ++ (nativeBuildInputs system);
            };
          }
        );
      };
}
