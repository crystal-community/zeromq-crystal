{ pkgs, ... }:

{
  languages.c.enable = true;

  packages = [ pkgs.zeromq pkgs.pkg-config ];
}
