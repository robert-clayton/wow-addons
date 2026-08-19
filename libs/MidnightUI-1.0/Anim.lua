local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

-- Animation helpers.
--
-- Alpha and frame translation run on native AnimationGroups (engine
-- driven, real easing curves, no per-frame Lua). Two cases have no
-- native equivalent and fall back to a lerp on a pooled driver frame:
-- window resizes (Scale distorts text instead of re-laying out) and
-- anything targeting a Texture (textures cannot own an AnimationGroup).
-- Drivers are never bound to the target's own OnUpdate — the resize
-- dragger already binds that, and a fade must be able to run alongside
-- a resize.
--
-- House curves, matching the suite this UI is modelled on:
--   entry  0.20s SetSmoothing("OUT")     — quick start, soft landing
--   exit   0.15s SetSmoothing("IN")      — soft start, decisive exit
--   move   0.20s SetSmoothing("IN_OUT")  — eased both ends
-- Entry is slower than exit on purpose: arriving should feel settled,
-- leaving should get out of the way.
--
-- Motion is a preference: with lib.animEnabled false every helper jumps
-- straight to the final state and fires onComplete on the same frame, so
-- callers never branch.

lib.animEnabled = (lib.animEnabled ~= false)

lib.ANIM_IN   = 0.20
lib.ANIM_OUT  = 0.15
lib.ANIM_MOVE = 0.20

--------------------------------------------------------------------------
-- Driver pool for the non-native cases.
--------------------------------------------------------------------------
local freeDrivers = {}
local drivers = {}   -- drivers[target][kind] = driver frame

-- Mirrors SetSmoothing("IN_OUT").
local function easeInOut(t)
    return t < 0.5 and (2 * t * t) or (1 - ((-2 * t + 2) ^ 2) / 2)
end

local function stopDriver(target, kind)
    local byKind = drivers[target]
    local d = byKind and byKind[kind]
    if not d then return end
    byKind[kind] = nil
    if not next(byKind) then drivers[target] = nil end
    d:SetScript("OnUpdate", nil)
    d:Hide()
    freeDrivers[#freeDrivers + 1] = d
end

-- step(easedProgress) runs every frame; the caller commits the final
-- state itself when t reaches 1.
local function startDriver(target, kind, duration, ease, step)
    stopDriver(target, kind)
    local d = table.remove(freeDrivers) or CreateFrame("Frame")
    local elapsed = 0
    drivers[target] = drivers[target] or {}
    drivers[target][kind] = d
    d:Show()
    d:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = elapsed / duration
        if t >= 1 then
            stopDriver(target, kind)
            step(1, true)
        else
            step(ease and ease(t) or t, false)
        end
    end)
end

--------------------------------------------------------------------------
-- Alpha. One cached group per direction per frame; starting either
-- always stops the other, so an interrupted fade-out cannot run its
-- OnFinished and hide a frame that is fading back in.
--------------------------------------------------------------------------
local function stopFades(frame)
    if frame._muiFadeIn then frame._muiFadeIn:Stop() end
    if frame._muiFadeOut then frame._muiFadeOut:Stop() end
end

function lib.FadeIn(frame, duration)
    if not frame then return end
    -- Already fully visible: don't burn a group on a no-op. Refresh
    -- paths call this on every update.
    if frame:IsShown() and frame:GetAlpha() >= 0.99
       and not (frame._muiFadeOut and frame._muiFadeOut:IsPlaying()) then
        return
    end
    local from = frame:IsShown() and frame:GetAlpha() or 0
    stopFades(frame)
    if not frame:IsShown() then
        frame:SetAlpha(0)
        frame:Show()
    end
    if not lib.animEnabled then
        frame:SetAlpha(1)
        return
    end
    if not frame._muiFadeIn then
        local ag = frame:CreateAnimationGroup()
        local a = ag:CreateAnimation("Alpha")
        a:SetSmoothing("OUT")
        ag._alpha = a
        frame._muiFadeIn = ag
    end
    local ag = frame._muiFadeIn
    ag:SetScript("OnFinished", function() frame:SetAlpha(1) end)
    ag._alpha:SetDuration(duration or lib.ANIM_IN)
    ag._alpha:SetFromAlpha(from)
    ag._alpha:SetToAlpha(1)
    ag:Play()
end

-- Fades out, then hides and restores alpha 1 so a later plain :Show()
-- isn't invisible. onComplete runs after the frame is hidden.
function lib.FadeOut(frame, duration, onComplete)
    if not frame then return end
    if not frame:IsShown() then
        if onComplete then onComplete() end
        return
    end
    local from = frame:GetAlpha()
    stopFades(frame)
    local function finish()
        frame:Hide()
        frame:SetAlpha(1)
        if onComplete then onComplete() end
    end
    if not lib.animEnabled then
        finish()
        return
    end
    if not frame._muiFadeOut then
        local ag = frame:CreateAnimationGroup()
        local a = ag:CreateAnimation("Alpha")
        a:SetSmoothing("IN")
        ag._alpha = a
        frame._muiFadeOut = ag
    end
    local ag = frame._muiFadeOut
    -- Rebound every play: the callback captures this call's onComplete.
    ag:SetScript("OnFinished", finish)
    ag._alpha:SetDuration(duration or lib.ANIM_OUT)
    ag._alpha:SetFromAlpha(from)
    ag._alpha:SetToAlpha(0)
    ag:Play()
end

-- Fade an already-shown frame to an arbitrary alpha (no show/hide).
function lib.FadeTo(frame, to, duration)
    if not frame then return end
    local from = frame:GetAlpha()
    stopFades(frame)
    if not lib.animEnabled or math.abs(from - to) < 0.01 then
        frame:SetAlpha(to)
        return
    end
    if not frame._muiFadeIn then
        local ag = frame:CreateAnimationGroup()
        local a = ag:CreateAnimation("Alpha")
        a:SetSmoothing("OUT")
        ag._alpha = a
        frame._muiFadeIn = ag
    end
    local ag = frame._muiFadeIn
    ag:SetScript("OnFinished", function() frame:SetAlpha(to) end)
    ag._alpha:SetDuration(duration or lib.ANIM_IN)
    ag._alpha:SetFromAlpha(from)
    ag._alpha:SetToAlpha(to)
    ag:Play()
end

--------------------------------------------------------------------------
-- Slide. A Translation animation only offsets a frame visually; the
-- anchor must be committed in OnFinished or it snaps back. An
-- interrupted slide commits its pending target first, so re-targeting
-- mid-flight continues from where it looks like it is.
--------------------------------------------------------------------------
local function commitPending(region)
    local p = region._muiSlidePending
    if not p then return end
    region._muiSlidePending = nil
    region:ClearAllPoints()
    region:SetPoint(p.point, p.rel, p.relPoint, p.x, p.y)
end

-- The region must already be anchored with the same point/relativeTo/
-- relativePoint — only the offsets move. A different anchor snaps.
-- Frames get a native Translation; textures lerp on a driver.
function lib.SlideTo(region, point, relativeTo, relativePoint, x, y, duration, onComplete)
    if not region then return end
    if region._muiSlide then
        region._muiSlide:Stop()
        commitPending(region)
    end
    stopDriver(region, "slide")
    local curPoint, curRel, curRelPoint, fx, fy = region:GetPoint()
    local sameAnchor = curPoint == point and curRel == relativeTo
        and curRelPoint == relativePoint
    local function place()
        region:ClearAllPoints()
        region:SetPoint(point, relativeTo, relativePoint, x, y)
        if onComplete then onComplete() end
    end
    if not lib.animEnabled or not sameAnchor
       or (math.abs((fx or 0) - x) < 0.5 and math.abs((fy or 0) - y) < 0.5) then
        place()
        return
    end
    duration = duration or lib.ANIM_MOVE
    if not region.CreateAnimationGroup then
        startDriver(region, "slide", duration, easeInOut, function(e, done)
            region:ClearAllPoints()
            region:SetPoint(point, relativeTo, relativePoint,
                fx + (x - fx) * e, fy + (y - fy) * e)
            if done and onComplete then onComplete() end
        end)
        return
    end
    if not region._muiSlide then
        local ag = region:CreateAnimationGroup()
        local t = ag:CreateAnimation("Translation")
        t:SetSmoothing("IN_OUT")
        ag._trans = t
        region._muiSlide = ag
    end
    local ag = region._muiSlide
    region._muiSlidePending = { point = point, rel = relativeTo,
        relPoint = relativePoint, x = x, y = y }
    ag:SetScript("OnFinished", function()
        commitPending(region)
        if onComplete then onComplete() end
    end)
    ag._trans:SetDuration(duration)
    ag._trans:SetOffset(x - fx, y - fy)
    ag:Play()
end

--------------------------------------------------------------------------
-- Size lerp (no native equivalent that re-lays out children).
--------------------------------------------------------------------------
function lib.SizeTo(frame, w, h, duration, onComplete)
    if not frame then return end
    stopDriver(frame, "size")
    local fw, fh = frame:GetWidth(), frame:GetHeight()
    if not lib.animEnabled
       or (math.abs(fw - w) < 0.5 and math.abs(fh - h) < 0.5) then
        frame:SetSize(w, h)
        if onComplete then onComplete() end
        return
    end
    startDriver(frame, "size", duration or lib.ANIM_MOVE, easeInOut,
        function(e, done)
            if done then
                frame:SetSize(w, h)
                if onComplete then onComplete() end
            else
                frame:SetSize(fw + (w - fw) * e, fh + (h - fh) * e)
            end
        end)
end

--------------------------------------------------------------------------
-- Texture vertex-alpha fade, for washes and hairlines that are textures
-- rather than frames (hover states, active bars).
--------------------------------------------------------------------------
function lib.FadeTexture(tex, r, g, b, toAlpha, duration)
    if not tex then return end
    local from = tex._muiAlpha
    if from == nil then
        local _, _, _, a = tex:GetVertexColor()
        from = a or 0
    end
    stopDriver(tex, "texfade")
    if not lib.animEnabled or math.abs(from - toAlpha) < 0.01 then
        tex._muiAlpha = toAlpha
        tex:SetColorTexture(r, g, b, toAlpha)
        return
    end
    startDriver(tex, "texfade", duration or lib.ANIM_OUT, nil,
        function(e, done)
            local a = done and toAlpha or (from + (toAlpha - from) * e)
            tex._muiAlpha = a
            tex:SetColorTexture(r, g, b, a)
        end)
end

-- Cancel every animation on a region, leaving it where it got to.
-- Frame pools must call this before reusing a frame so a stale driver
-- can't keep writing to it.
function lib.StopAnims(region)
    if not region then return end
    if region._muiFadeIn then region._muiFadeIn:Stop() end
    if region._muiFadeOut then region._muiFadeOut:Stop() end
    if region._muiSlide then
        region._muiSlide:Stop()
        region._muiSlidePending = nil
    end
    local byKind = drivers[region]
    if byKind then
        local kinds = {}
        for kind in pairs(byKind) do kinds[#kinds + 1] = kind end
        for _, kind in ipairs(kinds) do stopDriver(region, kind) end
    end
end
