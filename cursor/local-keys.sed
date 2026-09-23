# Machine-local Cursor settings kept out of commits (git clean filter).
# Cursor writes top-level keys with 4-space indentation.
/^    "remote\.SSH\.remotePlatform": {.*}/d
/^    "remote\.SSH\.remotePlatform": {/,/^    }/d
/^    "window\.zoomLevel":/d
