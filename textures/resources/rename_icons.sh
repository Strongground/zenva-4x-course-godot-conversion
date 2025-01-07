#!/bin/bash

# Pfad zum Zielordner
TARGET_FOLDER="./"

# Durchlaufe alle Dateien im Ordner
for file in "$TARGET_FOLDER"*; do
    # Überprüfe, ob der Dateiname mit dem Muster "_XXXX_" beginnt
    if [[ "$(basename "$file")" =~ ^_[0-9]{4}_(.+) ]]; then
        # Extrahiere den neuen Namen nach der Regex
        NEW_NAME="${BASH_REMATCH[1]}"
        # Benenne die Datei um
        mv "$file" "$TARGET_FOLDER$NEW_NAME"
        echo "Umbenannt: $file -> $TARGET_FOLDER$NEW_NAME"
    fi
done