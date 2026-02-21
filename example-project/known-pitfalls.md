# Known Pitfalls & Safeguards

- Data loss on crash → always atomic write (temp → rename)
- Silent JSON errors → loud, helpful messages
- Duplicate tasks → check by ID first
- Color output in CI → add --no-color flag

Never repeat these.
