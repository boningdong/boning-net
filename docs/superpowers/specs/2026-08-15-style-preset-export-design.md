# Mock Style Preset Export Design

## Goal

Add a mock-only export action that downloads the current Interactive Design Lab tuning state as a stable, machine-readable JSON file for reuse in later Codex sessions.

## Scope

- Add an `Export preset` action beside `Reset` and `Save default`.
- Reuse the existing `captureTuningState()` result as the single source of tuning values.
- Download a JSON file without changing the current tuning state or browser default.
- Do not add preset importing or modify production Jekyll pages.

## File format

The downloaded object has this shape:

```json
{
  "schemaVersion": 1,
  "kind": "boning-net-style-preset",
  "source": "homepage-mock-v3",
  "exportedAt": "2026-08-15T21:30:00.000Z",
  "tuning": {
    "activeOptions": [],
    "ranges": {},
    "globalLinks": {},
    "globalTint": "ice",
    "work": "projects"
  }
}
```

`schemaVersion`, `kind`, and `source` let a future reader identify and validate the file. `exportedAt` records provenance only. `tuning` preserves the complete state already used by Save and Reset.

## Download behavior

- The filename follows `boning-net-style-preset-YYYY-MM-DD-HHmm.json` using local time.
- JSON is formatted with two-space indentation and downloaded as `application/json`.
- The temporary object URL is revoked after the download is triggered.
- A successful action displays `Exported · preset downloaded` in the existing status area.
- If browser download APIs are unavailable, the status area displays `Export failed · browser download unavailable` and the current tuning remains unchanged.

## Interface

`Export preset` uses the existing secondary action style. `Save default` remains the only primary action because it changes the mock's refresh behavior; export is a portable snapshot rather than a persistent page setting.

## Verification

- The exported filename follows the specified convention.
- The downloaded JSON parses successfully and contains the expected metadata and current tuning state.
- Export does not mutate the tuning state or local storage.
- Save default and Reset retain their existing behavior.
- The action remains usable on desktop and mobile panel widths.
