-- Monitor layouts for the legion laptop.
--
-- The legion is used at two offices with different HP E24i G4 pairs, so the
-- same internal panel has to sit either to the left (office A) or to the right
-- (office B) of the HPs. A static hl.monitor list cannot express that: two
-- rules for the same panel would fight over its position. Instead the offices
-- are described as ordered layouts below and the one whose monitors are all
-- connected is applied.
--
-- Hyprland matches `desc:` against the EDID description as a PREFIX and the
-- connector names are not stable across boots (eDP-1 <-> eDP-2 and DP-2 <->
-- DP-3 have both been observed), so outputs are selected by description only.
--
-- Layouts are re-applied whenever a monitor appears or disappears, which makes
-- both offices, and the laptop on its own, work without touching wdisplays.

local laptop = {
  desc = "Samsung Display Corp. ATNA60HS03-0",
  mode = "2560x1600",
  scale = "1.3333334",
  -- Logical width: 2560 / 1.3333334. Positions are in scaled pixels.
  width = 1920,
}

local hp = function(serial)
  return {
    desc = "HP Inc. HP E24i G4 " .. serial,
    mode = "1920x1200",
    scale = "1",
    width = 1920,
  }
end

-- Ordered left to right.
local layouts = {
  -- Office A: laptop on the left, both HPs on the right.
  { laptop, hp("6CM406371S"), hp("6CM40635HR") },
  -- Office B: both HPs on the left, laptop on the right.
  { hp("6CM40635X7"), hp("6CM406358B"), laptop },
}

local function connected(desc)
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.description:sub(1, #desc) == desc then
      return true
    end
  end

  return false
end

local function place(layout)
  local x = 0

  for _, monitor in ipairs(layout) do
    hl.monitor({
      output = "desc:" .. monitor.desc,
      mode = monitor.mode,
      position = x .. "x0",
      scale = monitor.scale,
    })
    x = x + monitor.width
  end
end

local function apply()
  for _, layout in ipairs(layouts) do
    local complete = true

    for _, monitor in ipairs(layout) do
      if not connected(monitor.desc) then
        complete = false
        break
      end
    end

    if complete then
      place(layout)
      return
    end
  end

  -- No office is complete (laptop alone, or only some of its monitors): keep
  -- the panel in its usual place and let Hyprland place anything else with the
  -- default auto rule.
  hl.monitor({
    output = "desc:" .. laptop.desc,
    mode = laptop.mode,
    position = "0x0",
    scale = laptop.scale,
  })
end

hl.on("hyprland.start", apply)
hl.on("monitor.added", apply)
hl.on("monitor.removed", apply)

apply()
