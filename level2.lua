--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

require "game"
require "enemy"

boss = nil
enemyLaunchTimer = 2
endTimer = nil

--start level by creating enemies and changing gamestates
function level2Start()
  gamestate = "levelbegin"
  currentLevel = 2
  endTimer = 3
  for i = 1, 5, 1 do
    newEnemy = enemyCreateNew(1)
		table.insert(enemyStack, newEnemy)
  end
end

--update level
function level2Update(dt)

  --decrease and check enemy spawn timer - spawn enemy if < 0
  enemyLaunchTimer = enemyLaunchTimer - 1*dt
  if enemyLaunchTimer <= 0 and table.getn(enemyStack) > 0 then
    enemyLaunchTimer = 2
    local size = table.getn(enemyStack)

    randomX = math.random(10, love.graphics.getWidth() - 60)

    --spawn new enemy
    gameLaunchEnemy(randomX, -10, size)
  end

  --check for level end conditions
  if table.getn(enemyStack) == 0 and table.getn(enemies) == 0 and isAlive then
    endTimer = endTimer - 1*dt
    if endTimer < 0 then
      gamestate = "levelend"
    end
  end
end
