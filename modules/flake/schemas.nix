{ self, lib, inputs, ... }:

let
  schemas = {
    # TODO: define some custom schemas here
    # https://determinate.systems/posts/flake-schemas/#defining-your-own-schemas
  };
in {
  # include the schemas from the flake
  flake.schemas = inputs.flake-schemas.schemas // schemas;
}
