{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ripgrep
    fd
    jq
    git
    curl
    python3
    go
    cmake
    ninja
  ];
}
