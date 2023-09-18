{ pkgs, ... }:

{
  languages.crystal.enable = true;

  packages = [ pkgs.zeromq ];
}
