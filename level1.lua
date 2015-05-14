--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

require "game"
require "enemy"

boss = nil
spawnPoints = {}
spawnIndex = 0
endTimer = nil

--start level by creating enemies and changing gamestates
function level1Start()
  gamestate = "levelbegin"
  currentLevel = 1
  endTimer = 3

  local numberOfEnemies = 10

  local spawnArrayX = {20,450,50,400,100,350,150,300,200,250}
  local spawnArrayTimers = {2,0.1,4,0.1,4,0.1,4,0.1,4,0.1}
  spawnIndex = 1
  powerUpCount = 2

  spawnPoints = gameGenerateSpawnPoints(spawnArrayX, spawnArrayTimers)
  if table.getn(spawnPoints) < numberOfEnemies then
    numberOfEnemies = table.getn(spawnPoints)
  end

  for i = 1, numberOfEnemies, 1 do
    newEnemy = enemyCreateNew(1)
    table.insert(enemyStack, newEnemy)
  end
end

--update level
function level1Update(dt)

  --decrease and check enemy spawn timer - spawn enemy if < 0
  spawnPoints[spawnIndex].timer = spawnPoints[spawnIndex].timer - 1*dt
  if spawnPoints[spawnIndex].timer <= 0 and table.getn(enemyStack) > 0 then
    local size = table.getn(enemyStack)
    local x = spawnPoints[spawnIndex].x

    if table.getn(spawnPoints) > spawnIndex then
      spawnIndex = spawnIndex + 1
    end

    --spawn new enemy
    gameLaunchEnemy(x, size)
  end

  --check for level end conditions
  if table.getn(enemyStack) == 0 and table.getn(enemies) == 0 and isAlive then
    endTimer = endTimer - 1*dt
    if endTimer < 0 then
      gamestate = "levelend"
    end
  end
end
