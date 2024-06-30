-- This file is subject to LGPL-2.1 and installed from:
-- https://github.com/f-person/lua-timeago
--
-- TODO: Understand lua require weirdness and properly include this as a git submodule

local language = {
  justnow = "just now",
  minute = { singular = "a minute ago", plural = "minutes ago" },
  hour = { singular = "an hour ago", plural = "hours ago" },
  day = { singular = "a day ago", plural = "days ago" },
  week = { singular = "a week ago", plural = "weeks ago" },
  month = { singular = "a month ago", plural = "months ago" },
  year = { singular = "a year ago", plural = "years ago" },
}

local function round(num)
  return math.floor(num + 0.5)
end

local function timeago(time)
  local now = os.time()
  local diff_seconds = os.difftime(now, time)
  if diff_seconds < 45 then
    return language.justnow
  end

  local diff_minutes = diff_seconds / 60
  if diff_minutes < 1.5 then
    return language.minute.singular
  end
  if diff_minutes < 59.5 then
    return round(diff_minutes) .. " " .. language.minute.plural
  end

  local diff_hours = diff_minutes / 60
  if diff_hours < 1.5 then
    return language.hour.singular
  end
  if diff_hours < 23.5 then
    return round(diff_hours) .. " " .. language.hour.plural
  end

  local diff_days = diff_hours / 24
  if diff_days < 1.5 then
    return language.day.singular
  end
  if diff_days < 7.5 then
    return round(diff_days) .. " " .. language.day.plural
  end

  local diff_weeks = diff_days / 7
  if diff_weeks < 1.5 then
    return language.week.singular
  end
  if diff_weeks < 4.5 then
    return round(diff_weeks) .. " " .. language.week.plural
  end

  local diff_months = diff_days / 30
  if diff_months < 1.5 then
    return language.month.singular
  end
  if diff_months < 11.5 then
    return round(diff_months) .. " " .. language.month.plural
  end

  local diff_years = diff_days / 365.25
  if diff_years < 1.5 then
    return language.year.singular
  end
  return round(diff_years) .. " " .. language.year.plural
end

return { timeago = timeago }
