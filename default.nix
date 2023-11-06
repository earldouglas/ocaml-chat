{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {

  name = "chat";

  src = ./.;

  buildInputs = [
    pkgs.ocamlPackages.base64
    pkgs.ocamlPackages.dune_3
    pkgs.ocamlPackages.janeStreet.async
    pkgs.ocamlPackages.janeStreet.core_unix
    pkgs.ocamlPackages.janeStreet.ppx_let
    pkgs.ocamlPackages.ocaml
    pkgs.ocamlPackages.utop
    pkgs.ocamlformat
  ];

  buildPhase = ''
    dune build
  '';

  installPhase = ''
    install -D -m 0755 _build/default/bin/chat.exe $out/bin/chat
  '';
}
