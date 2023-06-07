local utils = {}
utils.get_dir_contents_blocking = function (path)
  local i, t = 0, {}
  local ls = io.popen('ls "'..path..'"')
  if ls == nil then
    return t
  end

  for file in ls:lines() do
    i = 1 + i
    t[i] = file
  end

  ls:close()
  return t
end

utils.get_random_file_blocking = function (path)
  local contents = utils.get_dir_contents_blocking(path)
  if contents == nil then
    return nil
  end

  local count = #contents
  if count == 0 then
    return nil
  end

  return contents[math.random(count)]
end

return utils
