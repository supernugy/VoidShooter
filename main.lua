--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

require "menu"
require "game"
require "levelLauncher"

--debug = true

--gamestates
gamestate = nil
currentLevel = nil

--level timers
endLevelTimer = nil
beginLevelTimer = nil

--menu clicking
function love.mousepressed(x,y)
  if(gamestate == "menu") then
    menuButtonClick(x,y)
  end
end

function love.load(arg)
  --loading assets
  allShips = love.graphics.newImage('assets/ships/shipsall.gif')
  player.width = 57
  player.height = 61
  player.quad = love.graphics.newQuad(68, 124, player.width, player.height, allShips:getWidth(), allShips:getHeight())
  bulletPlayerImg = love.graphics.newImage('assets/effects/bulletBlue.png')
  bulletEnemyImg = love.graphics.newImage('assets/effects/bulletRed.png')
  hitSound = love.audio.newSource('assets/sounds/hit.wav')
  explosionSound = love.audio.newSource('assets/sounds/explosion.wav')
  shootSound = love.audio.newSource('assets/sounds/playerShoot.wav','static')

  powerUpShieldImg = love.graphics.newImage('assets/powerup/circle_star_icon_blue.png')
  powerUpInvinvImg = love.graphics.newImage('assets/powerup/circle_star_icon_yellow.png')

  table.insert(playerExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_06_0008.png'))
  table.insert(playerExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_06_0012.png'))
  table.insert(playerExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_06_0015.png'))
  table.insert(playerExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_06_0019.png'))

  table.insert(enemyExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_04_0008.png'))
  table.insert(enemyExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_04_0012.png'))
  table.insert(enemyExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_04_0015.png'))
  table.insert(enemyExplostionImgs, love.graphics.newImage('assets/effects/explosion/expl_04_0019.png'))

  --initializing gamestate
  gamestate = "menu"

  --setting up font
  love.graphics.setColor(255,255,255,255)
  font = love.graphics.newFont(34)

  --setting up level timers
  endLevelTimer = 3
  beginLevelTimer = 3

  math.randomseed(os.time())
  math.random(); math.random(); math.random()

  --creating buttons
  menuButtonSpawn(love.graphics.getWidth()/2, 200, "Start", "start")
  menuButtonSpawn(love.graphics.getWidth()/2, 550, "Quit", "quit")
end


function love.update(dt)

  if gamestate == "ingame" then
    if currentLevel == 1 then
      level1Update(dt)
    elseif currentLevel == 2 then
      level2Update(dt)
    end
    gameMovePlayer(dt)
    gamePlayerShoot(dt)
    gameUpdateBullets(dt)
    gameChangeTimers(dt)
    gameUpdateEnemy(dt)
    gameCollisionWithEnemy(dt)
    gameCollisionWithBullets(dt)
    gameShieldRegen(dt)
    gameUpdatePowerUps(dt)
    gameReset()
  elseif gamestate == "menu" then
    mouseX = love.mouse.getX()
    mouseY = love.mouse.getY()
    menuButtonCheck()
  elseif gamestate == "levelend" then
    --decreasing timer
    endLevelTimer = endLevelTimer - 1*dt
    if endLevelTimer < 0 then
      endLevelTimer = 3
      resetVariables()
      levelStart(currentLevel + 1)
    end
  elseif gamestate == "levelbegin" then
    --decreasing timer
    beginLevelTimer = beginLevelTimer - 1*dt
    if beginLevelTimer < 0 then
      beginLevelTimer = 3
      resetVariables()
      gamestate = "ingame"
    end
  end

end


function love.draw(dt)

  if gamestate == "ingame" or gamestate == "pause" then
    --love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10)

    love.graphics.print("Score:"..score, 10, love.graphics:getHeight()-30)

    if isAlive then
      --drawing player
      love.graphics.draw(allShips, player.quad, player.x, player.y)
    else
      --drawing message on death
      local message1 = "Press 'R' to restart"
      local message2 = "or press 'Esc' to go to menu"

      if playerDyingTimer > 0 then

        if dyingTimeInterval ~= nil then
          local index = math.floor(playerDyingTimer/dyingTimeInterval)+1

          for i, explImg in ipairs(playerExplostionImgs) do
            if i == index then
              love.graphics.draw(explImg,player.x, player.y)
            end
          end
        end

      end

      love.graphics.print(message1, love.graphics:getWidth()/2-(font:getWidth(message1)/2), love.graphics:getHeight()/2-10)
      love.graphics.print(message2, love.graphics:getWidth()/2-(font:getWidth(message2)/2), love.graphics:getHeight()/2+10)
    end

    --drawing player bullets
    for i, bullet in ipairs(playerBullets) do
      love.graphics.draw(bullet.img, bullet.x, bullet.y)
    end

    --drawing enemy bullets
    for i, bullet in ipairs(enemyBullets) do
      love.graphics.draw(bullet.img, bullet.x, bullet.y)
    end

    --drawing power ups
    for i, powerUp in ipairs(powerUps) do
      love.graphics.draw(powerUp.img, powerUp.x, powerUp.y)
    end

    if powerUpShieldTimer > 0 then
      love.graphics.draw(powerUpShieldImg, 0, 0)
      local intTimer = math.ceil(powerUpShieldTimer)
      love.graphics.print(intTimer, 0, 45)
    end

    if powerUpInvincTimer > 0 then
      love.graphics.draw(powerUpInvinvImg, 45, 0)
      local intTimer = math.ceil(powerUpInvincTimer)
      love.graphics.print(intTimer, 45, 45)
    end


    --drawing enemies
    for i, enemy in ipairs(enemies) do
      love.graphics.draw(allShips, enemy.quad, enemy.x, enemy.y, math.pi, 1, 1, enemy.width, enemy.height)
    end

    for i, dyingEnemy in ipairs(deadEnemies) do
      local index = math.floor(dyingEnemy.enemyDyingTimer/dyingEnemy.enemyDyingTimeInterval)+1

      for i, explImg in ipairs(enemyExplostionImgs) do
        if i == index then
          --love.graphics.draw(explImg,dyingEnemy.x, dyingEnemy.y)
          love.graphics.draw(explImg,dyingEnemy.x, dyingEnemy.y, 0, dyingEnemy.explScale, explScale, 0, 0)
        end
      end
    end

    --drawing player health bar
    love.graphics.setColor(250,0,0,120)
    local barHeight = (player.hp/playerHpDefault)*200
    love.graphics.rectangle("fill", 10, love.graphics:getHeight()-60, 10, -barHeight )

    --drawing player shiled bar
    love.graphics.setColor(0,0,250,120)
    barHeight = (player.shield/playerShieldDefault)*200
    love.graphics.rectangle("fill", 30, love.graphics:getHeight()-60, 10, -barHeight )
    love.graphics.setColor(255,255,255,255)
  elseif gamestate == "menu" then
    menuButtonDraw()
  elseif gamestate == "levelend" then
    local message = "Level "..currentLevel.." ended"
    local messageScore = "Current score: "..score
    love.graphics.print(message, love.graphics:getWidth()/2-(font:getWidth(message)/2), love.graphics:getHeight()/2-10)
    love.graphics.print(messageScore, love.graphics:getWidth()/2-(font:getWidth(messageScore)/2), love.graphics:getHeight()/2+10)
  elseif gamestate == "levelbegin" then
    local message = "Level "..currentLevel
    love.graphics.print(message, love.graphics:getWidth()/2-(font:getWidth(message)/2), love.graphics:getHeight()/2-10)
  end

  if gamestate == "pause" then
    love.graphics.print("Press 'Esc' to continue", love.graphics:getWidth()/2-120, love.graphics:getHeight()/2-10)
    love.graphics.print("or press 'Enter' to go to menu", love.graphics:getWidth()/2-120, love.graphics:getHeight()/2+10)
  end

end
