# Architecture

`PromptRegistry` keeps a dictionary from a prompt name to the list of its versions.
Version numbers start at 1 and are positions in that list, so a version is never changed
after it was registered. Rendering always uses the latest version.

Nothing is persisted. A real service would store versions in a database and record who
registered each one.
