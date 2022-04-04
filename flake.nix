{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
  inputs.dream2nix.url = "github:tgunnoe/dream2nix/workspace-name-fix";
  inputs.dream2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.src.url = "github:nomicfoundation/hardhat";
  inputs.src.flake = false;
  outputs = { self, nixpkgs, dream2nix, src }@inputs:
    let
      dream2nix = inputs.dream2nix.lib2.init {
        systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
        config.projectRoot = ./. ;
      };
      lib = nixpkgs.lib;
    in dream2nix.makeFlakeOutputs {
      source = src;
      pname = "hardhat-monorepo";
      packageOverrides = {
        hardhat = {
          remove-local-check = {
            patches = [
              "${./patches}/remove-local-check.patch"
            ];
          };
          correct-tsconfig-path = {
            postPatch = ''
              substituteInPlace ./tsconfig.json --replace \
                '"extends": "../../config/typescript/tsconfig.json"' \
                '"extends": "./config/typescript/tsconfig.json"'
              substituteInPlace ./src/tsconfig.json --replace \
                '"extends": "../../../config/typescript/tsconfig.json"' \
                '"extends": "../config/typescript/tsconfig.json"'
              cp -r ${src}/config/ \
                ./
            '';
          };
          add-type-notation = {
            # maybe this should be postPatch as well
            prePatch = let
              input = "src/internal/core/jsonrpc/types/input";
              output = "src/internal/core/jsonrpc/types/output";
              file2 = "src/internal/hardhat-network/provider/utils/txMapToArray.ts";
            in builtins.map (file:
              ''
          echo -e "import _ from \"hardhat/node_modules/@types/bn.js\";\n$(cat ${file})" > ${file}
        '')
              [
                "${input}/blockTag.ts"
                "${input}/callRequest.ts"
                "${input}/filterRequest.ts"
                "${input}/transactionRequest.ts"
                "${output}/block.ts"
                "${output}/log.ts"
                "${output}/receipt.ts"
                "${output}/transaction.ts"
              ] ++ [ ''
          echo -e "import _ from \"hardhat/node_modules/@ethereumjs/tx\";\n$(cat ${file2})" > ${file2}
        '' ];
          };
        };
      };
    };
}
