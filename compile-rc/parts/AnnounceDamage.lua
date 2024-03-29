local Messages = {
  ["HPSimple"] = function(delta)
    return withColor(COLORS.white,
      string.format("HP[%s]", delta_color(0 - delta))
    )
  end,
  ["HPMax"] = function (color, hp, hpm, delta)
    crawl.mpr(
      withColor(COLORS.lightgreen,
        string.format("You now have %s max hp (%s).", hpm, delta_color(delta))
      )
    )
  end,
  ["HPLoss"] = function (color, hp, hpm, loss)
    crawl.mpr(
      string.format("%s%s",
        withColor(COLORS.red, string.format("You take %s damage,", loss)),
        withColor(color, string.format(" and now have %s/%s hp.", hp, hpm))
      )
    )
  end,
  ["HPGain"] = function (color, hp, hpm, gain)
    crawl.mpr(
      string.format("%s%s",
        withColor(COLORS.lightgreen, string.format("You regained %s hp,", gain)),
        withColor(color, string.format(" and now have %s/%s hp.", hp, hpm))
      )
    )
  end,
  ["HPFull"] = function (color, hp)
    crawl.mpr(
      withColor(COLORS.lightgreen,
        string.format("Your hp is fully restored (%s).", hp)
      )
    )
  end,
  ["HPMassivePause"] = function ()
    crawl.mpr(
      withColor(COLORS.lightred,
        string.format("MASSIVE DAMAGE!! (%s)", PAUSE_MORE)
      )
    )
  end,
  ["MPSimple"] = function(delta)
    return withColor(COLORS.white,
      string.format("MP[%s]", delta_color(0 - delta))
    )
  end,
  ["MPLoss"] = function (color, mp, mpm, loss)
    crawl.mpr(
      string.format("%s%s",
        withColor(COLORS.cyan, string.format("You lost %s mp,", loss)),
        withColor(color, string.format(" and now have %s/%s mp.", mp, mpm))
      )
    )
  end,
  ["MPGain"] = function (color, mp, mpm, gain)
    crawl.mpr(
      string.format("%s%s",
        withColor(COLORS.cyan, string.format("You regained %s mp,", gain)),
        withColor(color, string.format(" and now have %s/%s mp.", mp, mpm))
      )
    )
  end,
  ["MPFull"] = function (color, mp)
    crawl.mpr(
      withColor(COLORS.cyan, string.format("Your mp is fully restored (%s).", mp))
    )
  end,
[""]=""}

local prev_hp = 0
local prev_hp_max = 0
local prev_mp = 0
local prev_mp_max = 0

function delta_color(delta)
  local color = delta < 0 and COLORS.red or COLORS.green
  local signDelta = delta < 0 and delta or "+"..delta
  return string.format("<%s>%s</%s>", color, signDelta, color)
end

-- Simplified condensed HP and MP output
-- Print a single condensed line showing HP & MP change
-- e.g.😨 HP[-2] MP[-1]
function simple_announce_damage(curr_hp, max_hp, hp_diff, mp_diff)
  local emoji = ""
  local message = nil

  -- MP[-1]
  if hp_diff == 0 and mp_diff ~= 0 then
    message = Messages.MPSimple(mp_diff)
  -- HP[-2]
  elseif hp_diff ~= 0 and mp_diff == 0 then
    message = Messages.HPSimple(hp_diff)
  -- HP[-2] MP[-1]
  elseif hp_diff ~= 0 and mp_diff ~= 0 then
    message = string.format("%s %s", Messages.HPSimple(hp_diff), Messages.MPSimple(mp_diff))
  else
    -- No changes
  end

  if message ~= nil then
    if curr_hp <= (max_hp * 0.25) then
      emoji = "😱"
    elseif curr_hp <= (max_hp * 0.50) then
      emoji = "😨"
    elseif curr_hp <= (max_hp *  0.75) then
      emoji = "😮"
    elseif curr_hp < max_hp then
      emoji = "😕"
    else
      emoji = "😎"
    end

    if CONFIG.emojis then
      crawl.mpr(string.format("\n%s %s", emoji, message))
    else
      crawl.mpr(string.format("\n%s", message))
    end

  end
end

-- Try to sync with colors defined in Interface.rc
function color_by_max(message_func, curr, max, diff)
  if curr <= (max * 0.25) then
    message_func(COLORS.red, curr, max, diff)
  elseif curr <= (max * 0.50) then
    message_func(COLORS.lightred, curr, max, diff)
  elseif curr <= (max *  0.75) then
    message_func(COLORS.yellow, curr, max, diff)
  else
    message_func(COLORS.lightgrey, curr, max, diff)
  end
end

function announce_damage()
  -- TODO Define Colors.Red, Colors.Green, etc.

  -- TODO Move current/previous into array pair
  -- Save previous as last_hp
  -- Shift current into previous
  -- Early return if last_hp was == 0

  local curr_hp, max_hp = you.hp()
  local curr_mp, max_mp = you.mp()

  --Skips message on initializing game
  if prev_hp > 0 then
    local hp_diff = prev_hp - curr_hp
    local max_hp_diff = max_hp - prev_hp_max
    local mp_diff = prev_mp - curr_mp
    local max_mp_diff = max_mp - prev_mp_max

    -- Simplified condensed HP and MP output
    simple_announce_damage(curr_hp, max_hp, hp_diff, mp_diff)

    -- HP Max
    if max_hp_diff > 0 then
      Messages.HPMax(COLORS.green, curr_hp, max_hp, max_hp_diff)
    elseif max_hp_diff < 0 then
      Messages.HPMax(COLORS.yellow, curr_hp, max_hp, max_hp_diff)
    end

    -- HP Loss
    -- Ensure we lost MORE than the change in max hp
    -- i.e. a change in max hp should not be considered damage
    if (hp_diff > 0 and hp_diff > math.abs(max_hp_diff)) then
      color_by_max(Messages.HPLoss, curr_hp, max_hp, hp_diff)

      if hp_diff > (max_hp * 0.20) then
        Messages.HPMassivePause()
      end
    end

    -- HP Gain
    -- More than 1 HP gained
    if (hp_diff < 0) then
      -- Remove the negative sign by taking absolute value
      local hp_gain = math.abs(hp_diff)

      if (hp_gain > 1) and not (curr_hp == max_hp) then
        color_by_max(Messages.HPGain, curr_hp, max_hp, hp_gain)
      end

      if (curr_hp == max_hp) then
        Messages.HPFull(nil, curr_hp)
      end
    end

    -- MP Gain
    -- More than 1 MP gained
    if (mp_diff < 0) then
      -- Remove the negative sign by taking absolute value
      local mp_gain = math.abs(mp_diff)

      if (mp_gain > 1) and not (curr_mp == max_mp) then
        color_by_max(Messages.MPGain, curr_mp, max_mp, mp_gain)
      end

      if (curr_mp == max_mp) then
        Messages.MPFull(nil, curr_mp)
      end
    end

    -- MP Loss
    -- Ensure we lost MORE than the change in max mp
    -- i.e. a change in max mp should not be considered loss
    if (mp_diff > 0 and mp_diff > math.abs(max_mp_diff)) then
      color_by_max(Messages.MPLoss, curr_mp, max_mp, mp_diff)
    end

  end

  --Set previous hp/mp and form at end of turn
  prev_hp = curr_hp
  prev_hp_max = max_hp
  prev_mp = curr_mp
  prev_mp_max = max_mp
end
