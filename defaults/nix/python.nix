{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python314
    python314Packages.pip
    python314Packages.virtualenv
    uv
    ruff
    pyright
    black
  ];

  shellHook = ''
    export PIP_PREFIX="$PWD/.claudetanamo/state/.pip"
    export PATH="$PIP_PREFIX/bin:$PATH"
  '';
}
