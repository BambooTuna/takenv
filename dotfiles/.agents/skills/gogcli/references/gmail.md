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
