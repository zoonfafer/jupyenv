let
  jupyter = import ../.. {};

  iPythonWithPackages = jupyter.kernels.iPythonWith {
      name = "nixpkgs-graph-degree-distribution";
      packages = p: with p; [
            numpy
            scipy
            pandas
            matplotlib
            seaborn
            umaplearn
            scikitlearn
            ];
      };

  jupyterlabWithKernels = jupyter.jupyterlabWith {
      kernels = [ iPythonWithPackages ];
  };
in
  jupyterlabWithKernels.env
