# E2E breaker / actionability reconciliation

INV-122 must not let historical same-HEAD/rc counts suppress the first valid INV-150/INV-92 handoff.

Reuse existing INV-85 no-progress-substantive-attempt:<HEAD> as the authoritative proof that the bounded DEV correction for that exact HEAD was already consumed. No breaker generation, reset marker, migration state, or second actionability authority is introduced.

For dev-actionable=true, INV-122 may preempt only after its existing threshold is reached and machine-authored current-HEAD INV-85 evidence proves correction consumption. For dev-actionable=false, INV-122 does not preempt: INV-150 persists the required disposition/verdict and INV-92 owns the no-DEV stall. Missing, malformed, human-authored, or other-HEAD correction evidence resolves to not-consumed.
