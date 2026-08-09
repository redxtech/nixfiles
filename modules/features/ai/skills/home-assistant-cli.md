---
name: home-assistant-cli
description: "Operate Home Assistant through hass-cli. Use for entity states, history, devices, areas, events, templates, and service calls."
---

# Home Assistant CLI

Use `hass-cli` as the narrow interface to Home Assistant.

## Workflow

1. Confirm `hass-cli` is available and authentication is supplied through `HASS_SERVER` and `HASS_TOKEN`. Keep the token out of commands and output.
2. Inspect the relevant command with `hass-cli <group> --help` before composing an unfamiliar operation.
3. Read the smallest useful scope. Prefer a specific entity or domain over an unfiltered state/service listing.
4. Request structured output with `--output json` and project large responses with `jq` before they enter context.
5. Before a service call, identify the exact domain, service, target, and data. Read the current target state when it affects safety or correctness.
6. Execute the service call, then read the affected entity state to verify the intended transition.

The task is complete when the requested data is returned in compact form or the mutation is verified against Home Assistant's resulting state.

## Interface choices

- Use `state` for entity state and history.
- Use `service` for listing and calling services.
- Use `device`, `area`, `entity`, and `integration` for registry operations.
- Use `template` for Home Assistant template evaluation.
- Use `raw` only when no typed command covers the endpoint.

Use the Home Assistant MCP only when the requested behavior is not represented by `hass-cli`, and state that capability gap.