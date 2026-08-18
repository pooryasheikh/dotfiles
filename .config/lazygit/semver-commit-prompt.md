Generate a git commit message for the staged diff piped to you.

Format: `<type>(<scope>): <subject>`

## The type is a release decision, not a label

It feeds semantic-release (angular preset), which cuts the version from it. Choose from
the *effect* of the change, never from how many lines it touches:

| type | meaning | release |
|---|---|---|
| `fix` | corrects behaviour that was wrong or broken | patch |
| `feat` | adds a capability that did not exist before | minor |
| `perf` | same behaviour, measurably faster | patch |
| `refactor` | restructures code, behaviour identical | none |
| `docs` | documentation, comments, README only | none |
| `test` | tests only | none |
| `build` | Dockerfile, dependencies, packaging | none |
| `ci` | pipeline config only | none |
| `chore` | anything else with no user-visible effect | none |

## Rules, in priority order

1. If the change **repairs something that was broken**, it is `fix` — even if it adds a
   lot of code, and even if it also tidies things up along the way.
2. Use `feat` **only** when someone using this code can now do something they could not
   do before. "Improved", "better", "more robust" are usually `fix` or `refactor`.
3. If it changes an existing interface, config key, or default incompatibly, keep the
   type and add a body paragraph starting exactly `BREAKING CHANGE: ` describing what
   breaks and what to do instead.
4. When two types genuinely both apply, pick the one with the **smaller** release
   impact. An unnecessary minor bump is worse than a conservative patch.
5. Configuration and infrastructure changes that fix a broken deployment are `fix`,
   not `chore` — a broken deploy is broken behaviour.

## Subject line

- Imperative mood: "add", "correct", "remove" — not "added" or "adds".
- Lower case after the colon, no trailing full stop.
- Under 70 characters. Say what changed and why it matters, not which files moved.
- If one sentence cannot cover it, write a short body instead of a longer subject.

## Scope

Use exactly this scope, unchanged: `@SCOPE@`

(It is the branch name, which is the Jira ticket. Conventionally a scope names a
component rather than a ticket, but this repo group uses the ticket for traceability —
match the existing history rather than "correcting" it.)

## Output

Output ONLY the raw commit message. No markdown, no code fences, no backticks, no
commentary, no leading or trailing blank lines.
