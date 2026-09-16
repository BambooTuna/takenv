## Slides

```
gog slides info <presentationId>
gog slides create "My Deck"
gog slides create-from-markdown "My Deck" --content-file ./slides.md
gog slides create-from-template <templateId> "My Deck" --replace "name=John" --replace "date=2026-02-15"
gog slides copy <presentationId> "My Deck Copy"
gog slides export <presentationId> --format pdf --out ./deck.pdf
gog slides list-slides <presentationId>
gog slides add-slide <presentationId> ./slide.png --notes "Speaker notes"
gog slides update-notes <presentationId> <slideId> --notes "Updated notes"
gog slides replace-slide <presentationId> <slideId> ./new-slide.png --notes "New notes"

```
