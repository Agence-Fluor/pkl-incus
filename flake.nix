{
  description = "Toolchain for generating and packaging Incus Pkl specifications";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3.withPackages (packages: [ packages.pyyaml ]);
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.pkl python ];
          };
        });
    };
}
