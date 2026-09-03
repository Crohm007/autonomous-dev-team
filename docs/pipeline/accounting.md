# Resource accounting admission

The durable resource-accounting authority lives in `lib-accounting.sh` and is described normatively by `INV-139` and `INV-141` in [`invariants.md`](invariants.md). This note documents the admission behavior for explicit acknowledgements of historical unknown usage.

## Acknowledged historical `usage-unknown`

A terminal `usage-unknown` accounting record remains immutable evidence. `accounting_ack_unknown` appends a separate `ack-unknown` audit event for one exact invocation ID; it does not rewrite or delete the accounting record and does not invent a numeric token total.

`accounting_admission_query` consumes that audit evidence when projecting admission state. An acknowledged terminal `usage-unknown` is excluded from the blocking `unknown_invocations` set, is reported separately in `acknowledged_unknown_invocations`, and contributes no fabricated tokens to `total_tokens`. The acknowledgement is part of the projection digest, so the admission decision remains bound to the exact accounting evidence used to derive it.

The exception is deliberately narrow and fail-closed:

- a later or different `usage-unknown` remains blocking until that exact invocation is explicitly acknowledged;
- malformed or non-regular acknowledgement storage is `corrupt` evidence;
- an acknowledgement whose invocation ID does not correspond to a persisted terminal `usage-unknown` is also `corrupt` evidence;
- duplicate acknowledgements are idempotent for admission and projection digest purposes;
- the underlying `usage-unknown` record remains present and auditable after acknowledgement.

This mechanism is for explicit recovery from an immutable historical accounting gap. It is not a budget reset, a token estimate, or a general fail-open rule for unknown future usage.
