{ self, lib, inputs, ... }:

let
  schemas = {
    # TODO: define some custom schemas here
  };
in {
  # include the schemas from the flake
  flake.schemas = inputs.flake-schemas.schemas // schemas;
}
