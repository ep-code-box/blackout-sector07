-- Minimal JSON library for Lua (rxi/json inspired)
local json = { _version = "0.1.2" }

local decode

local function next_char(str, pos)
  pos = pos + 1
  return str:sub(pos, pos), pos
end

local function skip_whitespace(str, pos)
  while pos <= #str do
    local c = str:sub(pos, pos)
    if c ~= " " and c ~= "\t" and c ~= "\n" and c ~= "\r" then break end
    pos = pos + 1
  end
  return pos
end

local function parse_string(str, pos)
  local res = ""
  pos = pos + 1  -- skip opening "
  while pos <= #str do
    local c = str:sub(pos, pos)
    if c == '"' then
      return res, pos + 1
    elseif c == '\\' then
      local n = str:sub(pos + 1, pos + 1)
      if     n == '"'  then res = res .. '"'
      elseif n == '\\' then res = res .. '\\'
      elseif n == '/'  then res = res .. '/'
      elseif n == 'n'  then res = res .. '\n'
      elseif n == 'r'  then res = res .. '\r'
      elseif n == 't'  then res = res .. '\t'
      elseif n == 'b'  then res = res .. '\b'
      elseif n == 'f'  then res = res .. '\f'
      else res = res .. n
      end
      pos = pos + 2
    else
      res = res .. c
      pos = pos + 1
    end
  end
end

local function parse_number(str, pos)
  local num_str = str:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
  return tonumber(num_str), pos + #num_str
end

local function parse_array(str, pos)
  local res = {}
  pos = pos + 1
  while true do
    pos = skip_whitespace(str, pos)
    if str:sub(pos, pos) == "]" then return res, pos + 1 end
    local val, next_pos = decode(str, pos)
    table.insert(res, val)
    pos = skip_whitespace(str, next_pos)
    if str:sub(pos, pos) == "," then pos = pos + 1 end
  end
end

local function parse_object(str, pos)
  local res = {}
  pos = pos + 1
  while true do
    pos = skip_whitespace(str, pos)
    if str:sub(pos, pos) == "}" then return res, pos + 1 end
    local key, next_pos = parse_string(str, pos)
    pos = skip_whitespace(str, next_pos)
    if str:sub(pos, pos) == ":" then pos = pos + 1 end
    local val, final_pos = decode(str, pos)
    res[key] = val
    pos = skip_whitespace(str, final_pos)
    if str:sub(pos, pos) == "," then pos = pos + 1 end
  end
end

decode = function(str, pos)
  pos = skip_whitespace(str, pos)
  local c = str:sub(pos, pos)
  if c == "{" then return parse_object(str, pos)
  elseif c == "[" then return parse_array(str, pos)
  elseif c == '"' then return parse_string(str, pos)
  elseif c:match("[%d-]") then return parse_number(str, pos)
  elseif str:sub(pos, pos + 3) == "true" then return true, pos + 4
  elseif str:sub(pos, pos + 4) == "false" then return false, pos + 5
  elseif str:sub(pos, pos + 3) == "null" then return nil, pos + 4
  end
end

function json.decode(str) return decode(str, 1) end

local function encode_value(val)
    local t = type(val)
    if val == nil then return "null"
    elseif t == "boolean" then return tostring(val)
    elseif t == "number" then
        if val ~= val then return "null" end -- NaN
        return tostring(val)
    elseif t == "string" then
        return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
    elseif t == "table" then
        -- array check
        local is_array = true
        local max_n = 0
        for k, _ in pairs(val) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then is_array = false; break end
            if k > max_n then max_n = k end
        end
        if is_array and max_n == #val and max_n > 0 then
            local parts = {}
            for _, v in ipairs(val) do table.insert(parts, encode_value(v)) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(val) do
                table.insert(parts, '"' .. tostring(k) .. '":' .. encode_value(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

function json.encode(val) return encode_value(val) end

return json
