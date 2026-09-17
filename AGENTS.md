# ItemRack development rules

For every user-reported bug, follow the user-report regression workflow in
`TESTING.md`. A resolved reproducible bug must have a named permanent regression
in the standard `npm test` gate. Extend an existing focused suite when appropriate;
create a new suite only when the existing suites do not fit the owning behavior.
Do not claim a report is verified from a guessed reproduction or a green test
that does not exercise the reported failure. Record missing evidence and
client-only acceptance checks explicitly.

For release work, follow `.agent/workflows/release.md`. Never modify or retag an
accepted release candidate to add later policy, documentation, or code changes;
make those changes on `dev` for the next candidate.
