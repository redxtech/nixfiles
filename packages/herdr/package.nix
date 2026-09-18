{
  perSystem =
    { inputs', ... }:
    {
      packages.herdr = inputs'.llm-agents.packages.herdr.overrideAttrs (previous: {
        patches = (previous.patches or [ ]) ++ [
          ./0001-feat-listen-to-herdr-busy-from-pi-subagents.patch
          ./0002-feat-port-herdr-busy-to-omp.patch
        ];
      });
    };
}
