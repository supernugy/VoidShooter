--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

player = { x = 0, y = 0, width = 0, height = 0, speed = 0, quad = nil, hp = 0, shield = 0, shieldRegenMult = 0, shieldTimerRegen = 0 }

-- player shoot timers
canShoot = true
canShootTimerMax = 0.5
canShootTimer = canShootTimerMax

-- Image Storage
bulletPlayerImg = nil
bulletEnemyImg = nil

-- Entity Storage
bullets = {} -- array of current bullets being drawn and updated

-- array of current enemies on screen
enemies = {}

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
playerHpDefault = 100
playerShieldDefault = 100
playerSpeedDefault = 350
bulletSpeedDefault = 550

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
  for i, bullet in ipairs(bullets) do
    if bullet.type == "player" then
      bullet.y = bullet.y - (bullet.speed * dt)

      -- remove bullets when they pass off the screen
      if bullet.y < 0 then
        table.remove(bullets, i)
      end
    elseif bullet.type == "enemy" then
      bullet.y = bullet.y + (bullet.speed * dt)

      -- remove bullets when they pass off the screen
      if bullet.y > love.graphics.getHeight() then
        table.remove(bullets, i)
      end
    end
  end
end


-- Time out how far apart our shots can be.
function gameChangeTimers(dt)
	canShootTimer = canShootTimer - (1 * dt)
	if canShootTimer < 0 then
	  canShoot = true
	end
end

-- spawn new enemy
function gameLaunchEnemy(x, y, i)
  local stackedEnemy = table.remove(enemyStack, i)
  stackedEnemy.x = x
  stackedEnemy.y = y
  table.insert(enemies, stackedEnemy)
end

-- update the positions of enemies and shooting
function gameUpdateEnemy(dt)
	for i, enemy in ipairs(enemies) do
		enemy.y = enemy.y + (enemy.enemySpeed * dt)

    enemy.enemyShootTimer = enemy.enemyShootTimer - 1*dt

    -- enemy will shoot if it can
    if enemy.enemyShootTimer < 0 then
      local x = enemy.x + (enemy.width/2) - 3
      local y = enemy.y + enemy.height
      local newBullet = gameCreateBullet(x, y, "enemy", enemy.bulletDamage, enemy.bulletSpeed, bulletEnemyImg)
  		table.insert(bullets, newBullet)
      local soundClone = shootSound:clone()
      soundClone:play()
      enemy.enemyShootTimer = enemy.defaultEnemyShootTimer
    end

    -- remove enemies when they pass off the screen
		if enemy.y > 1000 then
			table.remove(enemies, i)
		end
	end
end

-- run our collision detection
-- Since there will be fewer enemies on screen than bullets we'll loop them first
-- Also, we need to see if the enemies hit our player
function gameCollisionWithEnemy(dt)
	for i, enemy in ipairs(enemies) do
		for j, bullet in ipairs(bullets) do

      -- checking collision of enemy and player bullet
			if CheckCollision(enemy.x, enemy.y, enemy.width, enemy.height, bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight())
      and bullet.type == "player" then
        local bulletDmg = bullet.damage

        -- resolving enemy hp
        enemy.hp = enemy.hp - bulletDmg
        table.remove(bullets, j)

        if enemy.hp <= 0 then
  				table.remove(enemies, i)
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
      player.shieldTimerRegen = shieldTimerRegenDefault
      local hitSoundClone = hitSound:clone()
      hitSoundClone:play()

      local explosionSoundClone = explosionSound:clone()

      if player.hp <= 0 then
        player.hp = 0
  			isAlive = false
        explosionSoundClone:play()
      end

      table.remove(enemies, i)
      explosionSoundClone:play()
		end
	end
end


-- checking collisions with bullets
function gameCollisionWithBullets(dt)
  for i, bullet in ipairs(bullets) do

    -- checking player collision with bullets
    if CheckCollision(bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight(),
    player.x, player.y, player.width, player.height) and bullet.type == "enemy"
    and isAlive then

      local bulletDmg = bullet.damage

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
      player.shieldTimerRegen = shieldTimerRegenDefault
      local hitSoundClone = hitSound:clone()
      hitSoundClone:play()

      if player.hp <= 0 then
        player.hp = 0
  			isAlive = false
        local explosionSoundClone = explosionSound:clone()
        explosionSoundClone:play()
      end

      table.remove(bullets, i)
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
		table.insert(bullets, newBullet)
    local soundClone = shootSound:clone()
    soundClone:play()
		canShoot = false
		canShootTimer = canShootTimerMax
	end
end


-- shield regeneration
function gameShieldRegen(dt)
  if isAlive then
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
  bullets = {}
  enemies = {}

  -- reset timers
  canShootTimer = canShootTimerMax

  -- move player back to default position
  player.x = 350
  player.y = 900
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
