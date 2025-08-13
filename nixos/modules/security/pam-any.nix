{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.security.pam-any;

  # Helper function to generate pam-any JSON config
  mkPamAnyConfig =
    name: serviceCfg:
    pkgs.writeText "pam-any-${name}.json" (
      builtins.toJSON {
        mode = serviceCfg.mode;
        modules = serviceCfg.modules;
      }
    );
in
{
  options = {
    security.pam-any = {
      enable = mkEnableOption "pam-any module for parallel PAM authentication";

      package = mkOption {
        type = types.package;
        default = pkgs.pam-any;
        defaultText = literalExpression "pkgs.pam-any";
        description = "The pam-any package to use";
      };

      services = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              enable = mkEnableOption "pam-any for this service";

              mode = mkOption {
                type = types.enum [
                  "One"
                  "All"
                ];
                default = "One";
                description = ''
                  Authentication mode:
                  - "One": Succeeds if ANY module succeeds (OR logic)
                  - "All": Succeeds if ALL modules succeed (AND logic)
                '';
              };

              modules = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      path = mkOption {
                        type = types.str;
                        description = "Path to the PAM module .so file";
                      };
                      args = mkOption {
                        type = types.listOf types.str;
                        default = [ ];
                        description = "Arguments to pass to the PAM module";
                      };
                    };
                  }
                );
                default = [ ];
                description = "List of PAM modules to run in parallel";
                example = literalExpression ''
                  [
                    {
                      path = "''${pkgs.fprintd}/lib/security/pam_fprintd.so";
                      args = [];
                    }
                    {
                      path = "pam_unix.so";
                      args = ["nullok" "try_first_pass"];
                    }
                  ]
                '';
              };

              control = mkOption {
                type = types.enum [
                  "required"
                  "requisite"
                  "sufficient"
                  "optional"
                ];
                default = "sufficient";
                description = "PAM control flag for the pam-any module";
              };
            };
          }
        );
        default = { };
        description = "PAM services to configure with pam-any";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    environment.etc = mkMerge (
      mapAttrsToList (
        name: serviceCfg:
        mkIf serviceCfg.enable {
          "pam-any-${name}.json" = {
            source = mkPamAnyConfig name serviceCfg;
            mode = "0644";
          };
        }
      ) cfg.services
    );

    security.pam.services = mkMerge (
      mapAttrsToList (
        name: serviceCfg:
        mkIf serviceCfg.enable {
          ${name} = {
            text = mkDefault (mkBefore ''
              auth ${serviceCfg.control} ${cfg.package}/lib/security/libpam_any.so /etc/pam-any-${name}.json
            '');
          };
        }
      ) cfg.services
    );
  };
}
