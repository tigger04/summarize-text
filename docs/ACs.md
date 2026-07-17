<!-- Version: 1.0 | Last updated: 2026-07-17 -->

# Acceptance Criteria

This is the canonical specification. ACs introduced from 2026-07-17 onward live here. Pre-cutover ACs remain in their originating issues until cited or migrated.

Last migrated: AC15.3 from #15 on 2026-07-17

---

## Configuration

### AC15.1 - Given an OpenAI or Claude API-key command is configured and its environment variable is absent, the application obtains the provider key from the command's standard output.

- Introduced: #15 (closed 2026-07-17)
- Migrated: 2026-07-17
- Tests:
  - ✅ RT-15.1: OpenAI command output supplies a key.
  - ✅ RT-15.2: Claude command output supplies a key.

### AC15.2 - Given a provider API-key environment variable and a command are both configured, the application uses the environment variable without executing the command.

- Introduced: #15 (closed 2026-07-17)
- Migrated: 2026-07-17
- Tests:
  - ✅ RT-15.3: Environment key takes precedence over configured command.

### AC15.3 - Given a configured key command fails or emits no key, the application reports the failure without exposing a secret and continues to its existing missing-key behaviour.

- Introduced: #15 (closed 2026-07-17)
- Migrated: 2026-07-17
- Tests:
  - ✅ RT-15.4: Failed OpenAI command is reported and no key is set.
  - ✅ RT-15.5: Empty Claude command output is reported and no key is set.

**Key:** ✅ passing · ⏳ pending · ❌ failing · ~~🚫 removed~~
