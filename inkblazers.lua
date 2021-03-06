dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')
local illu_name = os.getenv('illu_name')
local illu_number = os.getenv('illu_number')

local downloaded = {}
local addedtolist = {}

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  local html = nil
  
  if downloaded[url] == true or addedtolist[url] == true then
    return false
  end
  
  if string.match(url, "images%.inkblazers%.com") then
    return verdict
  elseif item_type == "illustration" and (downloaded[url] ~= true and addedtolist[url] ~= true) then
    if string.match(url, "[^0-9]"..illu_name.."[^0-9]") or string.match(url, "[^0-9]"..illu_number.."[^0-9]") then
      return verdict
    elseif html == 0 then
      return verdict
    else
      return false
    end
  elseif item_type == "manga" and (downloaded[url] ~= true and addedtolist[url] ~= true) then
    if string.match(url, "/"..illu_number.."/[0-9]+/[0-9]+") or string.match(url, "inkblazers%.com/assets/") then
      return verdict
    elseif html == 0 then
      return verdict
    else
      return false
    end
  elseif item_type == "blog" and (downloaded[url] ~= true and addedtolist[url] ~= true) then
    if (string.match(url, "/"..illu_name.."/") and string.match(url, "[^0-9]"..illu_number) and string.match(url, "inkblazers%.com")) or string.match(url, "inkblazers%.com/assets/") then
      return verdict
    elseif html == 0 then
      return verdict
    else
      return false
    end
  elseif item_type == "profile" and (downloaded[url] ~= true and addedtolist[url] ~= true) then
    if (string.match(url, "/"..illu_name.."/") and string.match(url, "[^0-9]"..illu_number) and string.match(url, "inkblazers%.com")) then
      return verdict
    elseif html == 0 then
      return verdict
    else
      return false
    end
  end
  
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  
  local function check(url)
    if downloaded[url] ~= true and addedtolist[url] ~= true then
      table.insert(urls, { url=url })
      addedtolist[url] = true
    end
  end

  if string.match(url, "images%.inkblazers%.com/[^%?]+%?") then
    local newurl = string.match(url, "(https?://[^/]+/[^%?]+)%?")
    check(newurl)
  end

  if item_type == "illustration" then
    if string.match(url, "https?://illustration%.images%.inkblazers%.com/[0-9]+/[^%?]+%?") then
      local newurl = string.match(url, "(https?://illustration%.images%.inkblazers%.com/[0-9]+/[^%?]+)%?")
      check(newurl)
    end
    if string.match(url, "inkblazers%.com/illustrations/[^/]+/detail%-page/[0-9]+") then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "images%.inkblazers%.com") then
          check(newurl)
        end
      end
      local dataurl1 = string.match(html, 'data%-url="([^"]+)"')
      local dataurl = "http://www.inkblazers.com"..dataurl1
      check(dataurl)
      local datalink = string.match(html, 'data%-link="([^"]+)"')
      if not string.match(datalink, "load%-as%-page%-by%-profile%-key%.json") then
        check(datalink)
      end
      local datapicture = string.match(html, 'data%-picture="([^"]+)"')
      check(datapicture)
    end
  elseif item_type == "manga" then
    if string.match(url, "inkblazers%.com/[^%?]+%?lang=") then
      local newurl = string.match(url, "(https?://[^/]+/[^%?]+)%?lang=")
      check(newurl)
    end
    if string.match(url, "inkblazers%.com/api/1%.0/") then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "images%.inkblazers%.com/") or string.match(newurl, "inkblazers%.com/assets/") then
          check(newurl)
        end
      end
      for newurl in string.gmatch(html, '"(/[^"]+)"') do
        local nurl = "http://www.inkblazers.com"..newurl
        if string.match(nurl, "/"..illu_number.."/[0-9]+/[0-9]+") or string.match(nurl, "/assets/") then
          check(nurl)
        end
      end
    end
    if string.match(url, "inkblazers%.com/manga%-and%-comics/"..illu_name.."/detail%-page/"..illu_number) or string.match(url, "inkblazers%.com/read%-manga/[^/]+/"..illu_number.."/[0-9]+/[0-9]+") then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "images%.inkblazers%.com") or string.match(newurl, "/"..illu_number.."/[0-9]+/[0-9]+") or string.match(newurl, "inkblazers%.com/assets/") then
          check(newurl)
        end
      end
      for newurl in string.gmatch(html, '"(/[^"]+)"') do
        local nurl = "http://www.inkblazers.com"..newurl
        if string.match(nurl, "/"..illu_number.."/[0-9]+/[0-9]+") or string.match(nurl, "/assets/") then
          check(nurl)
        end
      end
    end
  elseif item_type == "blog" then
    if string.match(url, "inkblazers%.com/api/1%.0/") or string.match(url, "load%-fans") then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "images%.inkblazers%.com/") or string.match(newurl, "inkblazers%.com/assets/") or (string.match(newurl, "inkblazers%.com") and string.match(newurl, "/"..illu_name.."/") and string.match(newurl, "/"..illu_number)) then
          check(newurl)
        end
      end
      for newurl in string.gmatch(html, '"(/[^"]+)"') do
        local nurl = "http://www.inkblazers.com"..newurl
        if (string.match(nurl, "/"..illu_name.."/") and string.match(nurl, "/"..illu_number)) or string.match(nurl, "/assets/") then
          check(nurl)
        end
      end
    end
    if (string.match(url, "inkblazers%.com") and string.match(url, "/"..illu_name.."/") and string.match(url, "/"..illu_number)) then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "images%.inkblazers%.com") or (string.match(newurl, "inkblazers%.com") and string.match(newurl, "/"..illu_name.."/") and string.match(newurl, "/"..illu_number)) or string.match(newurl, "inkblazers%.com/assets/") then
          check(newurl)
        end
      end
      for neurl in string.gmatch(html, '"(/[^"]+)"') do
        local nurl = "http://www.inkblazers.com"..neurl
        if string.match(nurl, "/blogs/"..illu_name.."/[^/]+/"..illu_number) or string.match(nurl, "/assets/") then
          check(nurl)
        end
      end
    end
  elseif item_type == "profile" then
    if string.match(url, "inkblazers%.com/api/1%.0/") or string.match(url, "load%-fans") or string.match(url, "favorites%-page") then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "images%.inkblazers%.com/") or (string.match(newurl, "inkblazers%.com") and string.match(newurl, "/"..illu_name.."/") and string.match(newurl, "/"..illu_number)) then
          check(newurl)
        end
      end
      for newurl in string.gmatch(html, '"(/[^"]+)"') do
        local nurl = "http://www.inkblazers.com"..newurl
        if (string.match(nurl, "/"..illu_name.."/") and string.match(nurl, "/"..illu_number)) then
          check(nurl)
        end
      end
    end
    if (string.match(url, "inkblazers%.com") and string.match(url, "/"..illu_name.."/") and string.match(url, "/"..illu_number)) then
      html = read_file(file)
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if string.match(newurl, "images%.inkblazers%.com") or (string.match(newurl, "inkblazers%.com") and string.match(newurl, "/"..illu_name.."/") and string.match(newurl, "/"..illu_number)) then
          check(newurl)
        end
      end
      for neurl in string.gmatch(html, '"(/[^"]+)"') do
        local nurl = "http://www.inkblazers.com"..neurl
        if string.match(nurl, "/authors%-and%-artists/"..illu_name.."/[^/]+/"..illu_number) then
          check(nurl)
        end
      end
    end
  end
  
  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  last_http_statcode = status_code
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()
  
  if (status_code >= 200 and status_code <= 399) or status_code == 403 then
    if string.match(url["url"], "https://") then
      local newurl = string.gsub(url["url"], "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url["url"]] = true
    end
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 1")

    tries = tries + 1

    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.EXIT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 10 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.EXIT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(75, 1000) / 100.0)
  local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
