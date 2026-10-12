{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    go_1_27
    gopls
    golangci-lint
    delve
    gotools
  ];

  shellHook = ''
    export GOPATH="$PWD/.claudetanamo/state/go"
    export PATH="$GOPATH/bin:$PATH"
  '';
}
