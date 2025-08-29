#!/bin/bash
# Simulate a recycle bin for file recovery

TRASH_DIR="$HOME/.trash"

mkdir -p "$TRASH_DIR"

case "$1" in
  delete)
    mv "$2" "$TRASH_DIR/"
    echo "Moved $2 to trash."
    ;;
  restore)
    mv "$TRASH_DIR/$2" .
    echo "Restored $2 from trash."
    ;;
  list)
    ls "$TRASH_DIR"
    ;;
  *)
    echo "Usage: $0 {delete <file>|restore <file>|list}"
    ;;
esac
