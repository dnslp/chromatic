# chromatic

This project defines a global constant `pitchFrequencies` containing the
equal-tempered tuning table.  Previews and unit tests rely on this constant to
look up pitch information.  It is declared `public` in
`Chromatic/Models/Pitch.swift` so external contexts can reference it directly or
replace it with test data when needed.
