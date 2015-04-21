--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

require "level1"
require "level2"

-- starts level by id
function levelStart(id)
  if id == 1 then
    level1Start()
  elseif id == 2 then
    level2Start()
  else
    gamestate = "menu"
  end
end
