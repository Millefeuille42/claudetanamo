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
    export GOPATH="$CLAUDE_CONFIG_DIR/go"
    export PATH="$GOPATH/bin:$PATH"
  '';
}
