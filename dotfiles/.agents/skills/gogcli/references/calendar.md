## カレンダー

```
# Calendars
gog calendar calendars
gog calendar acl <calendarId>         # List access control rules
gog calendar colors                   # List available event/calendar colors
gog calendar time --timezone America/New_York
gog calendar users                    # List workspace users (use email as calendar ID)

# Events (with timezone-aware time flags)
gog calendar events <calendarId> --today                    # Today's events
gog calendar events <calendarId> --tomorrow                 # Tomorrow's events
gog calendar events <calendarId> --week                     # This week (Mon-Sun by default; use --week-start)
gog calendar events <calendarId> --days 3                   # Next 3 days
gog calendar events <calendarId> --from today --to friday   # Relative dates
gog calendar events <calendarId> --from today --to friday --weekday   # Include weekday columns
gog calendar events <calendarId> --from 2025-01-01T00:00:00Z --to 2025-01-08T00:00:00Z
gog calendar events --all             # Fetch events from all calendars
gog calendar events --calendars 1,3   # Fetch events from calendar indices (see gog calendar calendars)
gog calendar events --cal Work --cal Personal  # Fetch events from calendars by name/ID
gog calendar event <calendarId> <eventId>
gog calendar get <calendarId> <eventId>                     # Alias for event
gog calendar search "meeting" --today
gog calendar search "meeting" --tomorrow
gog calendar search "meeting" --days 365
gog calendar search "meeting" --from 2025-01-01T00:00:00Z --to 2025-01-31T00:00:00Z --max 50

# Search defaults to 30 days ago through 90 days ahead unless you set --from/--to/--today/--week/--days.
# Tip: set GOG_CALENDAR_WEEKDAY=1 to default --weekday for calendar events output.

# JSON event output includes timezone and localized times (useful for agents).
gog calendar get <calendarId> <eventId> --json
# {
#   "event": {
#     "id": "...",
#     "summary": "...",
#     "startDayOfWeek": "Friday",
#     "endDayOfWeek": "Friday",
#     "timezone": "America/Los_Angeles",
#     "eventTimezone": "America/New_York",
#     "startLocal": "2026-01-23T20:45:00-08:00",
#     "endLocal": "2026-01-23T22:45:00-08:00",
#     "start": { "dateTime": "2026-01-23T23:45:00-05:00" },
#     "end": { "dateTime": "2026-01-24T01:45:00-05:00" }
#   }
# }

# Team calendars (requires Cloud Identity API for Google Workspace)
gog calendar team <group-email> --today           # Show team's events for today
gog calendar team <group-email> --week            # Show team's events for the week (use --week-start)
gog calendar team <group-email> --freebusy        # Show only busy/free blocks (faster)
gog calendar team <group-email> --query "standup" # Filter by event title

# Create and update
gog calendar create <calendarId> \
  --summary "Meeting" \
  --from 2025-01-15T10:00:00Z \
  --to 2025-01-15T11:00:00Z

gog calendar create <calendarId> \
  --summary "Team Sync" \
  --from 2025-01-15T14:00:00Z \
  --to 2025-01-15T15:00:00Z \
  --attendees "alice@example.com,bob@example.com" \
  --location "Zoom"

gog calendar update <calendarId> <eventId> \
  --summary "Updated Meeting" \
  --from 2025-01-15T11:00:00Z \
  --to 2025-01-15T12:00:00Z

# Send notifications when creating/updating
gog calendar create <calendarId> \
  --summary "Team Sync" \
  --from 2025-01-15T14:00:00Z \
  --to 2025-01-15T15:00:00Z \
  --send-updates all

gog calendar update <calendarId> <eventId> \
  --send-updates externalOnly

# Default: no attendee notifications unless you pass --send-updates.
gog calendar delete <calendarId> <eventId> \
  --send-updates all --force

# Recurrence + reminders
gog calendar create <calendarId> \
  --summary "Payment" \
  --from 2025-02-11T09:00:00-03:00 \
  --to 2025-02-11T09:15:00-03:00 \
  --rrule "RRULE:FREQ=MONTHLY;BYMONTHDAY=11" \
  --reminder "email:3d" \
  --reminder "popup:30m"

# Special event types via --event-type (focus-time/out-of-office/working-location)
gog calendar create primary \
  --event-type focus-time \
  --from 2025-01-15T13:00:00Z \
  --to 2025-01-15T14:00:00Z

gog calendar create primary \
  --event-type out-of-office \
  --from 2025-01-20 \
  --to 2025-01-21 \
  --all-day

gog calendar create primary \
  --event-type working-location \
  --working-location-type office \
  --working-office-label "HQ" \
  --from 2025-01-22 \
  --to 2025-01-23

# Dedicated shortcuts (same event types, more opinionated defaults)
gog calendar focus-time --from 2025-01-15T13:00:00Z --to 2025-01-15T14:00:00Z
gog calendar out-of-office --from 2025-01-20 --to 2025-01-21 --all-day
gog calendar working-location --type office --office-label "HQ" --from 2025-01-22 --to 2025-01-23
# Add attendees without replacing existing attendees/RSVP state
gog calendar update <calendarId> <eventId> \
  --add-attendee "alice@example.com,bob@example.com"

gog calendar delete <calendarId> <eventId>

# Invitations
gog calendar respond <calendarId> <eventId> --status accepted
gog calendar respond <calendarId> <eventId> --status declined
gog calendar respond <calendarId> <eventId> --status tentative
gog calendar respond <calendarId> <eventId> --status declined --send-updates externalOnly

# Propose a new time (browser-only flow; API limitation)
gog calendar propose-time <calendarId> <eventId>
gog calendar propose-time <calendarId> <eventId> --open
gog calendar propose-time <calendarId> <eventId> --decline --comment "Can we do 5pm?"

# Availability
gog calendar freebusy --calendars "primary,work@example.com" \
  --from 2025-01-15T00:00:00Z \
  --to 2025-01-16T00:00:00Z
gog calendar freebusy --cal Work --from 2025-01-15T00:00:00Z --to 2025-01-16T00:00:00Z

gog calendar conflicts --calendars "primary,work@example.com" \
  --today                             # Today's conflicts
gog calendar conflicts --all --today # Check conflicts across all calendars
```
