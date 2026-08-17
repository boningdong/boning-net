# Experience Card Description Design

## Goal

Make every work-experience card tall enough to show a stable one-line role description when collapsed, while keeping the responsibility list available only in the expanded panel. Correct the two requested Education details without changing the accordion interaction or overall timeline design.

## Data Contract

Every file in `_experiences/` will use two explicit content layers:

- `description` in YAML front matter stores the short role or company summary shown in the fixed card.
- The markdown body stores only the responsibility bullet list used as role details.

The Apple description will be:

`Work under Apple Core OS Embedded Sensors team to support software development work for various Apple products, including iPhone iPad, Mac, etc.`

The remaining experience descriptions will preserve the introductory sentence currently embedded at the start of each markdown body. The hidden AIRTIST entry will follow the same structure so the collection has one consistent schema.

## Rendering Behavior

- The collapsed summary reads `job.description` directly rather than truncating `job.content`.
- The summary description remains a single line with an ellipsis when space is limited.
- Increase `--experience-summary-height` from 122 pixels to 148 pixels so the company, title, description, date, and control have sufficient vertical space.
- Mobile cards also show the description instead of hiding it; they retain the one-line ellipsis to protect the compact layout.
- The expanded panel renders the same description first, followed by the markdown details list.
- Existing JavaScript behavior remains unchanged: enhancement initializes all cards collapsed, and only the selected card can be open.
- The no-JavaScript fallback remains fully readable because the initial markup keeps the details panel expanded.

## Education Changes

- Add `GPA 3.88` to the Master’s degree card.
- Keep `GPA 3.95` on the Bachelor’s degree card.
- Remove `IEEE Student Branch` from the Bachelor’s degree card.

## Validation

- Add rendered-page regression checks proving the Apple description appears in both summary and expanded details, while a responsibility bullet appears only in details.
- Update the compiled geometry assertion to require a 148-pixel summary height.
- Verify the Education cards render both GPA values and no IEEE Student Branch text.
- Run the Jekyll build, Ruby integration suite, and JavaScript suite.
- Inspect collapsed and expanded cards at desktop and mobile widths, checking one-line descriptions, card alignment, timeline connectors, overflow, and accordion accessibility state.

## Success Criteria

- Collapsed cards consistently show their explicit description and never derive it from the details body.
- Expanded cards show both the description and the full responsibility list.
- Fixed cards are taller without breaking timeline connector geometry.
- Master’s GPA is 3.88, Bachelor’s GPA remains 3.95, and IEEE Student Branch is absent.
