-- Exercises WhatsNew version comparison, entry selection and the login gate
-- without a WoW client. MC.version is pinned here rather than read from the
-- TOC: these assertions describe ordering behaviour, not the shipping version.
local MC = { version = "1.13.1" }
_G.LibStub = function() return { Theme = { font = "", colors = {} }, FontFlags = function() return "" end } end
_G.C_Timer = { After = function() end, NewTimer = function() return { Cancel = function() end } end }
_G.CollectionistDB = nil

assert(loadfile("addons/Collectionist/Data/Changelog.lua"))("Collectionist", MC)
assert(loadfile("addons/Collectionist/WhatsNew.lua"))("Collectionist", MC)

local W, pass, fail = MC.WhatsNew, 0, 0
local function check(label, got, want)
    if got == want then pass = pass + 1
    else fail = fail + 1; print(("  FAIL %s: got %s want %s"):format(label, tostring(got), tostring(want))) end
end

-- ordering
check("1.13.1 > 1.13.0", W.VersionValue("1.13.1") > W.VersionValue("1.13.0"), true)
check("1.13.0 > 1.12.1", W.VersionValue("1.13.0") > W.VersionValue("1.12.1"), true)
check("1.12.1 > 1.12.0", W.VersionValue("1.12.1") > W.VersionValue("1.12.0"), true)
check("1.9.0 < 1.10.0",  W.VersionValue("1.9.0")  < W.VersionValue("1.10.0"), true)  -- not string order
check("two-part 1.7",    W.VersionValue("1.7") > W.VersionValue("1.6.2"), true)
check("nil is lowest",   W.VersionValue(nil), -1)
check("garbage lowest",  W.VersionValue("wat"), -1)

-- entry selection
check("since 1.13.0 -> 1", #W:EntriesSince("1.13.0"), 1)
check("since 1.12.0 -> 3", #W:EntriesSince("1.12.0"), 3)   -- 1.12.1, 1.13.0, 1.14.0
check("since current -> 0", #W:EntriesSince("1.13.1"), 0)
check("since future -> 0", #W:EntriesSince("9.9.9"), 0)
check("nil -> all",        #W:EntriesSince(nil), #MC.CHANGELOG)
check("newest first",      W:EntriesSince("1.12.0")[1].version, "1.13.1")

-- /mc whatsnew floor should surface exactly the running version
check("floor is 1.13.0",   W.PreviousVersionFloor(), "1.13.0")
check("floor yields 1",    #W:EntriesSince(W.PreviousVersionFloor()), 1)

-- fresh install records silently
_G.CollectionistDB = {}
W:CheckOnLogin()
check("fresh install stamps", CollectionistDB.lastSeenVersion, "1.13.1")
check("fresh install quiet",  W.win, nil)

-- opted out: stamp, do not show
_G.CollectionistDB = { lastSeenVersion = "1.12.0", whatsNewDisabled = true }
W._toastPending = false
W:CheckOnLogin()
check("opt-out stamps",   CollectionistDB.lastSeenVersion, "1.13.1")
check("opt-out quiet",    W.win, nil)
check("opt-out no toast", W._toastPending, false)

-- upgrade: arm the toast, and do NOT stamp yet (unread must survive to the
-- next time the panel opens)
_G.CollectionistDB = { lastSeenVersion = "1.12.0" }
W._toastPending = false
W:CheckOnLogin()
check("upgrade arms toast",   W._toastPending, true)
check("upgrade keeps since",  W._toastSince, "1.12.0")
check("upgrade defers stamp", CollectionistDB.lastSeenVersion, "1.12.0")

-- dismissing is what marks it read
W:DismissToast()
check("dismiss stamps",   CollectionistDB.lastSeenVersion, "1.13.1")
check("dismiss disarms",  W._toastPending, false)

-- same version (and, by the same path, a downgrade): nothing armed
_G.CollectionistDB = { lastSeenVersion = "1.13.1" }
W._toastPending = false
W:CheckOnLogin()
check("same version quiet", W._toastPending, false)

print(("%d passed, %d failed"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
