## Sheets

```
gog sheets copy <spreadsheetId> "My Sheet Copy"
gog sheets export <spreadsheetId> --format pdf --out ./sheet.pdf
gog sheets format <spreadsheetId> 'Sheet1!A1:B2' --format-json '{"textFormat":{"bold":true}}' --format-fields 'userEnteredFormat.textFormat.bold'
gog sheets format <spreadsheetId> 'Sheet1!A1:B2' --format-json '{"borders":{"top":{"style":"SOLID"}}}' --format-fields 'userEnteredFormat.borders.top.style'
gog sheets merge <spreadsheetId> 'Sheet1!A1:B2'
gog sheets number-format <spreadsheetId> 'Sheet1!C:C' --type CURRENCY --pattern '$#,##0.00'
gog sheets freeze <spreadsheetId> --rows 1 --cols 1
gog sheets resize-columns <spreadsheetId> 'Sheet1!A:C' --auto
gog sheets read-format <spreadsheetId> 'Sheet1!A1:B2'
gog sheets insert <spreadsheetId> "Sheet1" rows 2 --count 3
gog sheets notes <spreadsheetId> 'Sheet1!A1:B10'
gog sheets find-replace <spreadsheetId> "old" "new"
gog sheets find-replace <spreadsheetId> "old" "new" --sheet Sheet1 --match-entire
gog sheets links <spreadsheetId> 'Sheet1!A1:B10'
gog sheets add-tab <spreadsheetId> <tabName>
gog sheets rename-tab <spreadsheetId> <oldName> <newName>
gog sheets delete-tab <spreadsheetId> <tabName> --force

```
