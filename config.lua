Config = {}

Config.Framework = 'qbcore' -- 'qbcore' vagy 'esx' | 'qbcore' or 'esx'

-- Ez az alapértelmezett sebességlimit (km/h), amit felajánl létrehozáskor [HUN]
-- This is the default speed limit (km/h) that is suggested when creating the route [ENG]


Config.DefaultSpeedLimit = 30.0

Config.EnableEntrySound = true -- Hang lejátszása zónába lépéskor | -- Play sound when entering a zone

Config.EnableWarningText = true -- Figyelmeztető ("LASSÍTS!") szöveg mutatása a képernyőn | -- Display a warning message ("SLOW DOWN!") on the screen
Config.Language = 'hu' -- A szöveg nyelve ('hu' vagy 'en') | -- The language of the text ('hu' or 'en')

Config.ExcludedJobs = { -- Ezekre a munkákra (ha szolgálatban vannak) nem hat a lassító | -- These vehicles (when on duty) are not affected by the speed limiter
    ['police'] = false,
    ['ambulance'] = false
}