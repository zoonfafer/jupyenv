{lib, config, self}:
let
  inherit (lib) types;
  kernelName = if (config ? kernelName) then config.kernelName else "";
  default' = if kernelName == "python3" then [
    self.inputs.poetry2nix.overlay
  ] else if kernelName == "rust" then [
    self.inputs.rust-overlay.overlays.default
  ] else [];
in
lib.mkOption {
  type = types.listOf types.anything;
  default = default';
  description = lib.mdDoc ''
    List of overlays to apply to the kernel derivation.
 '';
}
