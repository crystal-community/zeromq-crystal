{ pkgs, ... }:

{
  packages = [ pkgs.zeromq pkgs.pkg-config ];
}
