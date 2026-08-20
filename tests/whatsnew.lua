-- Exercises WhatsNew version comparison, entry selection and the login gate
-- without a WoW client.
--
-- Deliberately version-agnostic: expectations are derived from whatever
-- Data/Changelog.lua currently holds, and MC.version is pinned to its newest
-- entry. An earlier revision hardcoded "1.14.0" everywhere and broke on every
-- single release, which made it noise rather than a check.

local MC = {}
_G.LibStub = function() return { Theme = { font = "", colors = {} }, FontFlags = function() return "" end } end
_G.C_Timer = { After = function() end, NewTimer = function() return { Cancel = function() end } end }
_G.CollectionistDB = nil

assert(loadfile("addons/Collectionist/Data/Changelog.lua"))("Collectionist", MC)
assert(type(MC.CHANGELOG) == "table" and #MC.CHANGELOG >= 3,
    "Data/Changelog.lua should carry at least three versions")

-- The addon reads MC.version from TOC metadata at runtime; stand in with the
-- newest changelog entry so "current" means the same thing here.
MC.version = MC.CHANGELOG[1].version
assert(loadfile("addons/Collectionist/WhatsNew.lua"))("Collectionist", MC)

local W, pass, fail = MC.WhatsNew, 0, 0
local function check(label, got, want)
    if got == want then pass = pass + 1
    else fail = fail + 1; print(("  FAIL %s: got %s want %s"):format(label, tostring(got), tostring(want))) end
end

local newest, second = MC.CHANGELOG[1].version, MC.CHANGELOG[2].version
local third = MC.CHANGELOG[3].version

-- Ordering. The numeric-vs-string case is the one that actually bites: plain
-- string comparison puts "1.9.0" above "1.10.0".
check("newest > second",  W.VersionValue(newest) > W.VersionValue(second), true)
check("second > third",   W.VersionValue(second) > W.VersionValue(third), true)
check("1.9.0 < 1.10.0",   W.VersionValue("1.9.0") < W.VersionValue("1.10.0"), true)
check("patch beats none", W.VersionValue("1.13.1") > W.VersionValue("1.13"), true)
check("two-part parses",  W.VersionValue("1.7") > W.VersionValue("1.6.2"), true)
check("nil is lowest",    W.VersionValue(nil), -1)
check("garbage lowest",   W.VersionValue("wat"), -1)

-- Entry selection.
check("since second -> 1",  #W:EntriesSince(second), 1)
check("since third -> 2",   #W:EntriesSince(third), 2)
check("since newest -> 0",  #W:EntriesSince(newest), 0)
check("since future -> 0",  #W:EntriesSince("99.0.0"), 0)
check("nil -> everything",  #W:EntriesSince(nil), #MC.CHANGELOG)
check("newest first",       W:EntriesSince(third)[1].version, newest)

-- /mc whatsnew: floor must surface exactly the running version's notes.
check("floor is second",  W.PreviousVersionFloor(), second)
check("floor yields 1",   #W:EntriesSince(W.PreviousVersionFloor()), 1)

-- Fresh install: record silently. Onboarding.lua covers the intro, and a new
-- player has no "what changed" to care about.
_G.CollectionistDB = {}
W._toastPending = false
W:CheckOnLogin()
check("fresh stamps",   CollectionistDB.lastSeenVersion, newest)
check("fresh no toast", W._toastPending, false)

-- Opted out: stamp so it stays quiet next login too.
_G.CollectionistDB = { lastSeenVersion = third, whatsNewDisabled = true }
W._toastPending = false
W:CheckOnLogin()
check("opt-out stamps",   CollectionistDB.lastSeenVersion, newest)
check("opt-out no toast", W._toastPending, false)

-- Upgrade: arm the toast but do NOT stamp. An unread notice has to survive to
-- the next time the panel opens.
_G.CollectionistDB = { lastSeenVersion = third }
W._toastPending = false
W:CheckOnLogin()
check("upgrade arms",    W._toastPending, true)
check("upgrade since",   W._toastSince, third)
check("upgrade defers",  CollectionistDB.lastSeenVersion, third)

-- Dismissing is what marks it read.
W:DismissToast()
check("dismiss stamps",  CollectionistDB.lastSeenVersion, newest)
check("dismiss disarms", W._toastPending, false)

-- Same version, and the downgrade case, stay quiet.
for _, stored in ipairs({ newest, "99.0.0" }) do
    _G.CollectionistDB = { lastSeenVersion = stored }
    W._toastPending = false
    W:CheckOnLogin()
    check("quiet when stored=" .. stored, W._toastPending, false)
end

print(("%d passed, %d failed"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
