Google関連のサービスを操作するために、`gogcli` を導入しています。

基本以下の情報をもとに作業を行ってください。
もしエラーが続くようであれば、詳細の使い方などは `https://raw.githubusercontent.com/steipete/gogcli/refs/heads/main/README.md` を見てください。

## Gmail

```
# Search and read

gog gmail search 'newer_than:7d' --max 10
gog gmail thread get <threadId>
gog gmail thread get <threadId> --download # Download attachments to current dir
gog gmail thread get <threadId> --download --out-dir ./attachments
gog gmail get <messageId>
gog gmail get <messageId> --format metadata
gog gmail attachment <messageId> <attachmentId>
gog gmail attachment <messageId> <attachmentId> --out ./attachment.bin
gog gmail url <threadId> # Print Gmail web URL
gog gmail thread modify <threadId> --add STARRED --remove INBOX

# Send and compose

gog gmail send --to a@b.com --subject "Hi" --body "Plain fallback"
gog gmail send --to a@b.com --subject "Hi" --body-file ./message.txt
gog gmail send --to a@b.com --subject "Hi" --body-file - # Read body from stdin
gog gmail send --to a@b.com --subject "Hi" --body "Plain fallback" --body-html "<p>Hello</p>"

# Reply + include quoted original message (auto-generates HTML quote unless you pass --body-html)

gog gmail send --reply-to-message-id <messageId> --quote --to a@b.com --subject "Re: Hi" --body "My reply"

# Draft reply + quote (create requires explicit reply target)

gog gmail drafts create --reply-to-message-id <messageId> --quote --subject "Re: Hi" --body "My reply"

# Draft reply + quote (update accepts explicit target; else falls back to latest non-draft, non-self message in thread)

gog gmail drafts update <draftId> --reply-to-message-id <messageId> --quote --subject "Re: Hi" --body "My reply"
gog gmail drafts update <draftId> --quote --subject "Re: Hi" --body "My reply"
gog gmail drafts list
gog gmail drafts create --subject "Draft" --body "Body"
gog gmail drafts create --to a@b.com --subject "Draft" --body "Body"
gog gmail drafts update <draftId> --subject "Draft" --body "Body"
gog gmail drafts update <draftId> --to a@b.com --subject "Draft" --body "Body"
gog gmail drafts send <draftId>

# Labels

gog gmail labels list
gog gmail labels get INBOX --json # Includes message counts
gog gmail labels create "My Label"
gog gmail labels rename "Old Label" "New Label"
gog gmail labels modify <threadId> --add STARRED --remove INBOX
gog gmail labels delete <labelIdOrName> # Deletes user label (guards system labels; confirm)

# Batch operations

gog gmail batch delete <messageId> <messageId>
gog gmail batch modify <messageId> <messageId> --add STARRED --remove INBOX

# Filters

gog gmail filters list
gog gmail filters create --from 'noreply@example.com' --add-label 'Notifications'
gog gmail filters delete <filterId>
gog gmail filters export --out ./filters.json

# Settings

gog gmail autoforward get
gog gmail autoforward enable --email forward@example.com
gog gmail autoforward disable
gog gmail forwarding list
gog gmail forwarding add --email forward@example.com
gog gmail sendas list
gog gmail sendas create --email alias@example.com
gog gmail vacation get
gog gmail vacation enable --subject "Out of office" --message "..."
gog gmail vacation disable

# Delegation (G Suite/Workspace)

gog gmail delegates list
gog gmail delegates add --email delegate@example.com
gog gmail delegates remove --email delegate@example.com

# Watch (Pub/Sub push)

gog gmail watch start --topic projects/<p>/topics/<t> --label INBOX
gog gmail watch serve --bind 127.0.0.1 --token <shared> --hook-url http://127.0.0.1:18789/hooks/agent
gog gmail watch serve --bind 0.0.0.0 --verify-oidc --oidc-email <svc@...> --hook-url <url>
gog gmail watch serve --bind 127.0.0.1 --token <shared> --fetch-delay 5 --hook-url http://127.0.0.1:18789/hooks/agent
gog gmail watch serve --bind 127.0.0.1 --token <shared> --exclude-labels SPAM,TRASH --hook-url http://127.0.0.1:18789/hooks/agent
gog gmail history --since <historyId>

```

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

## ドライブ

```
# List and search
gog drive ls --max 20
gog drive ls --parent <folderId> --max 20
gog drive ls --all --max 20               # List across all accessible files (cannot combine with --parent)
gog drive ls --no-all-drives            # Only list from "My Drive"
gog drive search "invoice" --max 20
gog drive search "invoice" --no-all-drives
gog drive search "mimeType = 'application/pdf'" --raw-query
gog drive get <fileId>                # Get file metadata
gog drive url <fileId>                # Print Drive web URL
gog drive copy <fileId> "Copy Name"

# Upload and download
gog drive upload ./path/to/file --parent <folderId>
gog drive upload ./path/to/file --replace <fileId>  # Replace file content in-place (preserves shared link)
gog drive upload ./report.docx --convert
gog drive upload ./chart.png --convert-to sheet
gog drive upload ./report.docx --convert --name report.docx
gog drive download <fileId> --out ./downloaded.bin
gog drive download <fileId> --format pdf --out ./exported.pdf     # Google Workspace files only
gog drive download <fileId> --format docx --out ./doc.docx
gog drive download <fileId> --format pptx --out ./slides.pptx

# Organize
gog drive mkdir "New Folder"
gog drive mkdir "New Folder" --parent <parentFolderId>
gog drive rename <fileId> "New Name"
gog drive move <fileId> --parent <destinationFolderId>
gog drive delete <fileId>             # Move to trash
gog drive delete <fileId> --permanent # Permanently delete

# Permissions
gog drive permissions <fileId>
gog drive share <fileId> --to user --email user@example.com --role reader
gog drive share <fileId> --to user --email user@example.com --role writer
gog drive share <fileId> --to domain --domain example.com --role reader
gog drive unshare <fileId> --permission-id <permissionId>

# Shared drives (Team Drives)
gog drive drives --max 100
```
