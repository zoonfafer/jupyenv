{ writeScriptBin
, haskellPackages
, stdenv
, extraIHaskellFlags ? ""
, name ? "nixpkgs"
, packages ? (_:[])
, Rpackages ? (_:[])
, inline-r ? false
, pkgs
, rWrapper
, runCommand
, rPackages
}:

let
  ihaskellEnv = haskellPackages.ghcWithPackages (self: [ self.ihaskell ] ++ packages self);

  ghciBin = writeScriptBin "ghci-${name}" ''
    ${ihaskellEnv}/bin/ghci "$@"
  '';

  ghcBin = writeScriptBin "ghc-${name}" ''
    ${ihaskellEnv}/bin/ghc "$@"
  '';

  r-bin-path  = rWrapper.override{ packages = with rPackages; [] ++ (Rpackages rPackages);};

  r-libs-site = runCommand "r-libs-site" (if inline-r then {
    buildInputs = with pkgs; [  R
                             ] ++ (Rpackages rPackages);
  } else {}) ''echo $R_LIBS_SITE > $out'' ;

  ihaskellSh = writeScriptBin "ihaskell" ''
    #! ${stdenv.shell}
    export GHC_PACKAGE_PATH="$(echo ${ihaskellEnv}/lib/*/package.conf.d| tr ' ' ':'):$GHC_PACKAGE_PATH"
    ${if inline-r then ''
    export LD_LIBRARY_PATH=${pkgs.R}/lib/R/lib
    export R_LIBS_SITE=${builtins.readFile r-libs-site}
    export PATH="${stdenv.lib.makeBinPath ([ ihaskellEnv r-bin-path ] )}:$PATH"
''
     else ''
     export PATH="${stdenv.lib.makeBinPath ([ ihaskellEnv ] )}:$PATH"
''}
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
