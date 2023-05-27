{
  pkgs,
  name,
  displayName,
  requiredRuntimePackages,
  runtimePackages,
  env,
  nixpkgsPath ? pkgs.path,
}: let
  allRuntimePackages = requiredRuntimePackages ++ runtimePackages;

  wrappedEnv =
    pkgs.runCommand "wrapper-${env.name}"
    {nativeBuildInputs = [pkgs.makeWrapper];}
    ''
      mkdir -p $out/bin
      for i in ${env}/bin/*; do
        filename=$(basename $i)
        ln -s ${env}/bin/$filename $out/bin/$filename
        wrapProgram $out/bin/$filename \
          --set PATH "${pkgs.lib.makeSearchPath "bin" allRuntimePackages}"\
          --set NIX_PATH "nixpkgs=${nixpkgsPath}"
      done
    '';
in {
  inherit name displayName;
  language = "Nix";
  argv = [
    "${wrappedEnv}/bin/python"
    "-m"
    "nix-kernel"
    "-f"
    "{connection_file}"
  ];
  logo64 = ./logo-64x64.png;
}
