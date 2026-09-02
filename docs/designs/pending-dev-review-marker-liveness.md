# Pending-dev review-marker liveness

A review dispatch marker remains fresh for the controller cold-start/dedup TTL. After review has durably handed the Issue to `pending-dev`, that marker cannot represent a competing DEV launch. Reusing the any-mode terminal-stall predicate therefore created a false `stale-verdict` wait on the real #70 canary.

The fix keeps one liveness implementation: `_dispatch_marker_recent` accepts a mode scope and `may_stall_now` accepts `--dev-dispatch-only`. Only the same-HEAD pending-dev recovery call uses that scope. DEV markers and DEV PID/heartbeat liveness still defer; all existing stall callers keep any-mode semantics. No new state, queue, retry budget, or product special case is added.

The later `stale-verdict` deferral itself creates no review-verdict event, so it cannot create an additional policy escalation; the preceding review's explicit `failed-substantive` remains a separate existing policy event.
