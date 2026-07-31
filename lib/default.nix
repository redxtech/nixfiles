lib:

let
  args = { inherit lib; };
in
{
  # functions to help with containers
  containers = import ./containers args;

  # server service helpers
  server = import ./server args;

  # gpu helpers
  gpu = import ./gpu args;
}
