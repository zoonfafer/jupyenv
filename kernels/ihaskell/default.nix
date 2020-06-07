{ writeScriptBin
, haskellPackages
, stdenv
, extraIHaskellFlags ? ""
, name ? "nixpkgs"
, packages ? (_:[])
, extraRuntimePackages ? (_:[])
, extraEnvVars ? ""
, pkgs
, runCommand
}:

let
  ihaskellEnv = haskellPackages.ghcWithPackages (self: [ self.ihaskell ] ++ packages self);

  ghciBin = writeScriptBin "ghci-${name}" ''
    ${ihaskellEnv}/bin/ghci "$@"
  '';

  ghcBin = writeScriptBin "ghc-${name}" ''
    ${ihaskellEnv}/bin/ghc "$@"
  '';

  extraEnvVars_Command = runCommand "extraEnvVars_PATH" {
    buildInputs = with pkgs; [
    ] ++ (extraRuntimePackages pkgs);
  }'' mkdir -p $out
  echo $R_LIBS_SITE > $out/R-LIB
  echo $PATH > $out/PATH
'';

  extraEnvVars_PATH = "${builtins.readFile "${extraEnvVars_Command}/PATH"}";

  ihaskellSh = writeScriptBin "ihaskell" ''
    #! ${stdenv.shell}
    export extraEnvVars_PATH="${extraEnvVars_PATH}"
    ${extraEnvVars}
    export $R_LIBS_SITE="${builtins.readFile "${extraEnvVars_Command}/R-LIB"}"
    export GHC_PACKAGE_PATH="$(echo ${ihaskellEnv}/lib/*/package.conf.d| tr ' ' ':'):$GHC_PACKAGE_PATH"
    export PATH="${stdenv.lib.makeBinPath ([ ihaskellEnv extraEnvVars_PATH ])}:$PATH"
    ${ihaskellEnv}/bin/ihaskell ${extraIHaskellFlags} -l $(${ihaskellEnv}/bin/ghc --print-libdir) "$@"'';

  kernelFile = {
    display_name = "Haskell - " + name;
    language = "haskell";
    argv = [
      "${ihaskellSh}/bin/ihaskell"
      "kernel"
      "{connection_file}"
      "+RTS"
      "-M3g"
      "-N2"
      "-RTS"
    ];
    logo64 = "logo-64x64.svg";
  };

  ihaskellKernel = stdenv.mkDerivation {
    name = "ihaskell-kernel";
    phases = "installPhase";
    src = ./haskell.svg;
    buildInputs = [ ihaskellEnv ];
    installPhase = ''
      mkdir -p $out/kernels/ihaskell_${name}
      cp $src $out/kernels/ihaskell_${name}/logo-64x64.svg
      echo '${builtins.toJSON kernelFile}' > $out/kernels/ihaskell_${name}/kernel.json
    '';
  };
in
  {
    spec = ihaskellKernel;
    runtimePackages = [
      # Give access to compiler and interpreter with the libraries accessible
      # from the kernel.
      ghcBin
      ghciBin
    ];
  }
