--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

function powerUpSpawn(x, y, type)
  local newPowerup = nil

  if type == 1 then
    newPowerup = {x = x, y = y, speed = 300, type = type, img = nil}
  end

  return newPowerup
end
