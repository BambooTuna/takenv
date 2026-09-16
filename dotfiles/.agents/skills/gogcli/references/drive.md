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
