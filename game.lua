--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

require "powerup"

player = { x = 0, y = 0, width = 0, height = 0, speed = 0, quad = nil, hp = 0, shield = 0, shieldRegenMult = 0, shieldTimerRegen = 0 }

-- player shoot timers
canShoot = true
canShootTimerMax = 0.5
canShootTimer = canShootTimerMax

playerDyingTimer = nil
playerDyingTimerDefault = 0.5
enemyDyingTimerDefault = 0.5
dyingTimeInterval = nil

-- Image Storage
bulletPlayerImg = nil
bulletEnemyImg = nil

-- Entity Storage
playerBullets = {}
enemyBullets = {} -- array of current bullets being drawn and updated

powerUps = {}
playerExplostionImgs = {}
enemyExplostionImgs = {}

-- array of current enemies on screen
enemies = {}
deadEnemies = {}

-- array of enemies in stack ready to be spawn
enemyStack = {}

-- player global variables
isAlive = true
score = 0

-- Sounds
hitSound = nil
explosionSound = nil
shootSound = nil

-- default values
shieldRegenMultDefault = 15
shieldTimerRegenDefault = 1.5
playerHpDefault = 50
playerShieldDefault = 50
playerSpeedDefault = 300
bulletSpeedDefault = 550

--power up variables
powerUpCount = 0
powerUpSpawnChance = 20
powerUpShieldTimer = 0
shieldRegenMultPoweredUp = 25
shieldTimerRegenPoweredUp = 0.5
powerUpInvincTimer = 0


-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

-- creates new bullet
function gameCreateBullet(x, y, typeId, damage, speed, image)
  local newBullet = { x = x, y = y, img = image, type = typeId, speed = speed, damage = damage }
  return newBullet
end

-- update the positions of bullets
function gameUpdateBullets(dt)
  for i, bullet in ipairs(playerBullets) do

    if bullet.type == "player" then
      bullet.y = bullet.y - (bullet.speed * dt)

      -- remove bullets when they pass off the screen
      if bullet.y < 0 then
        table.remove(playerBullets, i)
      end
    end

  end

  for i, bullet in ipairs(enemyBullets) do

    if bullet.type == "enemy" then
      bullet.y = bullet.y + (bullet.speed * dt)

      -- remove bullets when they pass off the screen
      if bullet.y > love.graphics.getHeight() then
        table.remove(enemyBullets, i)
      end
    end

  end
end

-- generates spawn points for given x coordinates and timers array
function gameGenerateSpawnPoints(arrayX, arrayTimer)
  local resultSpawnPoints = {}

  for i = 1, table.getn(arrayX), 1 do
    local spawnPoint = {x = arrayX[i], timer = arrayTimer[i]}
    table.insert(resultSpawnPoints, spawnPoint)
  end

  return resultSpawnPoints
end

-- Time out how far apart our shots can be.
function gameChangeTimers(dt)
  canShootTimer = canShootTimer - (1 * dt)
  if canShootTimer < 0 then
    canShoot = true
  end

  if playerDyingTimer > 0 and not isAlive then
    playerDyingTimer = playerDyingTimer - dt
  end

  for i, dyingEnemy in ipairs(deadEnemies) do
    dyingEnemy.enemyDyingTimer = dyingEnemy.enemyDyingTimer - dt
    if(dyingEnemy.enemyDyingTimer <= 0) then
      table.remove(deadEnemies,i)
    end
  end

  --powerup timers
  if powerUpShieldTimer > 0 then
    powerUpShieldTimer = powerUpShieldTimer - dt
  end

  if powerUpInvincTimer > 0 then
    powerUpInvincTimer = powerUpInvincTimer - dt
  end

end

-- spawn new enemy
function gameLaunchEnemy(x, i)
  local stackedEnemy = table.remove(enemyStack, i)
  stackedEnemy.x = x
  stackedEnemy.y = -stackedEnemy.height
  table.insert(enemies, stackedEnemy)
end

-- update the positions of enemies and shooting
function gameUpdateEnemy(dt)
  for i, enemy in ipairs(enemies) do

    local moveIndex = enemy.currentMoveIndex
    local moveTimer = enemy.movePattern.time[moveIndex]
    local moveSpeedX = enemy.movePattern.speedX[moveIndex]
    local moveSpeedY = enemy.movePattern.speedY[moveIndex]

    enemy.movePattern.time[moveIndex] = moveTimer - 1*dt

    if enemy.movePattern.time[moveIndex] <= 0 then
      if(table.getn(enemy.movePattern.time) > moveIndex) then
        enemy.currentMoveIndex = enemy.currentMoveIndex + 1
      else
        enemy.movePattern.time[moveIndex] = 100
      end
    end

    enemy.y = enemy.y + (moveSpeedY * dt)
    enemy.x = enemy.x + (moveSpeedX * dt)

    enemy.enemyShootTimer = enemy.enemyShootTimer - 1*dt

    -- enemy will shoot if it can
    if enemy.enemyShootTimer < 0 then
      local x = enemy.x + (enemy.width/2) - 3
      local y = enemy.y + enemy.height
      local newBullet = gameCreateBullet(x, y, "enemy", enemy.bulletDamage, enemy.bulletSpeed, bulletEnemyImg)
      table.insert(enemyBullets, newBullet)
      local soundClone = shootSound:clone()
      soundClone:play()
      enemy.enemyShootTimer = enemy.defaultEnemyShootTimer
    end

    -- remove enemies when they pass off the screen
    if enemy.y > love.graphics.getHeight() then
      table.remove(enemies, i)
    end
  end
end

function gameUpdatePowerUps(dt)
  for i, powerUp in ipairs(powerUps) do
    powerUp.y = powerUp.y + powerUp.speed*dt

    if CheckCollision(powerUp.x, powerUp.y, powerUp.img:getWidth(), powerUp.img:getHeight(), player.x, player.y, player.width, player.height) then
      if powerUp.type == 1 then
        powerUpShieldTimer = powerUpShieldTimer + 10
      elseif powerUp.type == 2 then
        powerUpInvincTimer = powerUpInvincTimer + 5
      end
      table.remove(powerUps, i)
    elseif powerUp.y > love.graphics.getHeight() then
      table.remove(powerUps, i)
    end

  end
end

-- run our collision detection
-- Since there will be fewer enemies on screen than bullets we'll loop them first
-- Also, we need to see if the enemies hit our player
function gameCollisionWithEnemy(dt)
  for i, enemy in ipairs(enemies) do
    for j, bullet in ipairs(playerBullets) do

      -- checking collision of enemy and player bullet
      if CheckCollision(enemy.x + bullet.img:getWidth()/2, enemy.y + bullet.img:getHeight()*0.2, enemy.width - bullet.img:getWidth(), enemy.height - bullet.img:getHeight()*0.6, bullet.x, bullet.y + bullet.img:getHeight()*0.2, bullet.img:getWidth(), bullet.img:getHeight()*0.6)
      and bullet.type == "player" then
        local bulletDmg = bullet.damage

        -- resolving enemy hp
        enemy.hp = enemy.hp - bulletDmg
        table.remove(playerBullets, j)

        if enemy.hp <= 0 then
          local enemyDyingTimer = enemyDyingTimerDefault
          local enemyDyingTimeInterval = enemyDyingTimer/table.getn(enemyExplostionImgs)
          local explScale = (enemy.width/100)/(enemyExplostionImgs[1]:getWidth()/100)
          local deadEnemy = {x = enemy.x, y = enemy.y, enemyDyingTimer = enemyDyingTimer, enemyDyingTimeInterval = enemyDyingTimeInterval, explScale = explScale}

          table.insert(deadEnemies, deadEnemy)

          --removes enemy with a chance to spawn power up
          table.remove(enemies, i)

          if powerUpCount > 0 then
            local randomNumber = math.random()*100
            if powerUpSpawnChance > randomNumber then
              local num = math.random()*100
              local num2 = math.ceil(num/(100/#powerUpTypes))
              local type = powerUpTypes[num2]

              local newPowerUp = powerUpSpawn(deadEnemy.x, deadEnemy.y, type)
              table.insert(powerUps, newPowerUp)
            end
            powerUpCount = powerUpCount - 1
          end

          score = score + 1
          local explosionSoundClone = explosionSound:clone()
          explosionSoundClone:play()
        else
          local hitSoundClone = hitSound:clone()
          hitSoundClone:play()
        end
      end
    end

    -- checking player collision with enemy
    if CheckCollision(enemy.x, enemy.y, enemy.width, enemy.height, player.x, player.y, player.width, player.height)
    and isAlive then
      local enemyDmg = enemy.damage

      -- when player isn't invincible
      if (powerUpInvincTimer <= 0) then

        --resolving shields first
        if player.shield > 0 then
          if player.shield >= enemyDmg then
            player.shield = player.shield - enemyDmg
            enemyDmg = 0
          else
            enemyDmg = enemyDmg - player.shield
            player.shield = 0
          end
        end

        --resolving hp
        player.hp = player.hp - enemyDmg

        if powerUpShieldTimer > 0 then
          player.shieldTimerRegen = shieldTimerRegenPoweredUp
        else
          player.shieldTimerRegen = shieldTimerRegenDefault
        end

      end

      local hitSoundClone = hitSound:clone()
      hitSoundClone:play()

      local explosionSoundClone = explosionSound:clone()

      if player.hp <= 0 then
        player.hp = 0
        isAlive = false
        explosionSoundClone:play()
      end

      local enemyDyingTimer = enemyDyingTimerDefault
      local enemyDyingTimeInterval = enemyDyingTimer/table.getn(enemyExplostionImgs)
      local explScale = (enemy.width/100)/(enemyExplostionImgs[1]:getWidth()/100)
      local deadEnemy = {x = enemy.x, y = enemy.y, enemyDyingTimer = enemyDyingTimer, enemyDyingTimeInterval = enemyDyingTimeInterval, explScale = explScale}

      table.insert(deadEnemies, deadEnemy)

      table.remove(enemies, i)
      explosionSoundClone:play()
    end
  end
end


-- checking collisions with bullets
function gameCollisionWithBullets(dt)
  for i, bullet in ipairs(enemyBullets) do

    -- checking player collision with bullets
    if CheckCollision(bullet.x, bullet.y - bullet.img:getHeight()/2, bullet.img:getWidth(), bullet.img:getHeight(),
    player.x  + bullet.img:getWidth()/2, player.y + bullet.img:getHeight()*0.2, player.width - bullet.img:getWidth(), player.height - bullet.img:getHeight()*0.6) and bullet.type == "enemy"
    and isAlive then

      local bulletDmg = bullet.damage

      -- when player isn't invincible
      if (powerUpInvincTimer <= 0) then

        --resolving shields first
        if player.shield > 0 then
          if player.shield >= bulletDmg then
            player.shield = player.shield - bulletDmg
            bulletDmg = 0
          else
            bulletDmg = bulletDmg - player.shield
            player.shield = 0
          end
        end

        --resolving hp
        player.hp = player.hp - bulletDmg

        if powerUpShieldTimer > 0 then
          player.shieldTimerRegen = shieldTimerRegenPoweredUp
        else
          player.shieldTimerRegen = shieldTimerRegenDefault
        end

      end

      local hitSoundClone = hitSound:clone()
      hitSoundClone:play()

      if player.hp <= 0 then
        player.hp = 0
        local explosionSoundClone = explosionSound:clone()
        explosionSoundClone:play()
        isAlive = false
      end

      table.remove(enemyBullets, i)
    end
  end
end


-- player movements
function gameMovePlayer(dt)
  if isAlive then
    if love.keyboard.isDown('left','a') and love.keyboard.isDown('up','w') then
      if player.x > 0 then -- binds us to the map
        player.x = player.x - (player.speed*dt)
      end
      if player.y > 0 then
        player.y = player.y - (player.speed*dt)
      end
    elseif love.keyboard.isDown('left','a') and love.keyboard.isDown('down','s') then
      if player.x > 0 then -- binds us to the map
        player.x = player.x - (player.speed*dt)
      end
      if player.y < (love.graphics.getHeight() - player.height) then
        player.y = player.y + (player.speed*dt)
      end
    elseif love.keyboard.isDown('right','d') and love.keyboard.isDown('up','w') then
      if player.x < (love.graphics.getWidth() - player.width) then
        player.x = player.x + (player.speed*dt)
      end
      if player.y > 0 then
        player.y = player.y - (player.speed*dt)
      end
    elseif love.keyboard.isDown('right','d') and love.keyboard.isDown('down','s') then
      if player.x < (love.graphics.getWidth() - player.width) then
        player.x = player.x + (player.speed*dt)
      end
      if player.y < (love.graphics.getHeight() - player.height) then
        player.y = player.y + (player.speed*dt)
      end
    elseif love.keyboard.isDown('left','a') then
      if player.x > 0 then -- binds us to the map
        player.x = player.x - (player.speed*dt)
      end
    elseif love.keyboard.isDown('right','d') then
      if player.x < (love.graphics.getWidth() - player.width) then
        player.x = player.x + (player.speed*dt)
      end
    elseif love.keyboard.isDown('up','w') then
      if player.y > 0 then
        player.y = player.y - (player.speed*dt)
      end
    elseif love.keyboard.isDown('down','s') then
      if player.y < (love.graphics.getHeight() - player.height) then
        player.y = player.y + (player.speed*dt)
      end
    end
  end
end

-- Shooting
function gamePlayerShoot(dt)
  if love.keyboard.isDown(' ', 'rctrl', 'lctrl', 'ctrl') and canShoot and isAlive then
    -- Create some bullets
    local x = player.x + (player.width/2) - 3
    local y = player.y
    local newBullet = gameCreateBullet(x, y, "player", 20, 400, bulletPlayerImg)
    table.insert(playerBullets, newBullet)
    local soundClone = shootSound:clone()
    soundClone:play()
    canShoot = false
    canShootTimer = canShootTimerMax
  end
end


-- shield regeneration
function gameShieldRegen(dt)
  if isAlive then

    if powerUpShieldTimer > 0 then

      player.shieldTimerRegen = player.shieldTimerRegen - 1*dt

      if player.shieldTimerRegen <= 0 then
        if(player.shield < playerShieldDefault) then
          player.shield = player.shield + shieldRegenMultPoweredUp*dt
          if(player.shield > playerShieldDefault)then
            player.shield = playerShieldDefault
          end
        end
      end

    else
      player.shieldTimerRegen = player.shieldTimerRegen - 1*dt

      if player.shieldTimerRegen <= 0 then
        if(player.shield < playerShieldDefault) then
          player.shield = player.shield + player.shieldRegenMult*dt
          if(player.shield > playerShieldDefault)then
            player.shield = playerShieldDefault
          end
        end
      end

    end
  end
end

-- game reset after death
function gameReset()
  if not isAlive and love.keyboard.isDown('r') then
    resetVariables()
    levelStart(currentLevel)
    score = 0
  elseif not isAlive and love.keyboard.isDown('escape') then
    gamestate = "menu"
  end
end

-- reseting game variable
function resetVariables()
  -- remove all our bullets and enemies from screen
  enemyBullets = {}
  playerBullets = {}
  enemies = {}
  deadEnemies = {}

  -- reset timers
  canShootTimer = canShootTimerMax
  playerDyingTimer = playerDyingTimerDefault
  dyingTimeInterval = playerDyingTimer/table.getn(playerExplostionImgs)
  powerUpShieldTimer = 0
  powerUpInvincTimer = 0

  -- move player back to default position
  player.x = love.graphics.getWidth()/2
  player.y = love.graphics.getHeight() - player.height - 10
  player.speed = playerSpeedDefault
  player.hp = playerHpDefault
  player.shield = playerShieldDefault
  player.shieldTimerRegen = shieldTimerRegenDefault
  player.shieldRegenMult = shieldRegenMultDefault

  -- reset our game state
  isAlive = true
end

-- checking for key presses
function love.keyreleased(key)
   if key == "escape" and gamestate == "ingame" and isAlive then
     gamestate = "pause"
   elseif key == "return" and gamestate == "pause" and isAlive then
     gamestate = "menu"
   elseif key == "escape" and gamestate == "pause" and isAlive then
     gamestate = "ingame"
   end
end
