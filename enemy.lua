--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

-- returns new enemy by type
function enemyCreateNew(typeId)
  local shootTimer, hp, movePattern, damage, bulletDamage, bulletSpeed, width, height, enemyQuad, movePattern
  if typeId == 1 then
    shootTimer = 1
    hp = 30
    damage = 30
    bulletDamage = 20
    bulletSpeed = 400
    width = 34
    height = 30
    enemyQuad = love.graphics.newQuad(94, 31, width, height, allShips:getWidth(), allShips:getHeight())
    movePattern = {speedX = {0, 90, 0, -90, 0}, time = {2,1,1,1,10}, speedY = {200, -100, 100, -100, 250}}

    local newEnemy = { x = 0, y = 0, width = width, height = height, hp = hp, quad = enemyQuad, movePattern = movePattern, currentMoveIndex = 1,
    bulletSpeed = bulletSpeed, damage = damage, bulletDamage = bulletDamage, enemyShootTimer = shootTimer, defaultEnemyShootTimer = shootTimer, type = typeId }

    return newEnemy
  elseif typeId == 2 then
    shootTimer = 0.5
    hp = 10
    damage = 20
    bulletDamage = 10
    bulletSpeed = 350
    width = 24
    height = 23
    enemyQuad = love.graphics.newQuad(7, 67, width, height, allShips:getWidth(), allShips:getHeight())
    movePattern = {speedX = {love.graphics.getWidth()/2, -love.graphics.getWidth()/3, love.graphics.getWidth()/2, -love.graphics.getWidth()/2, love.graphics.getWidth()/2, 0},
      time = {1.9,2.9,1.9,1.9,1.9,10},
      speedY = {love.graphics.getHeight()/6,0,love.graphics.getHeight()/6,0,love.graphics.getHeight()/6,200}}

    local newEnemy = { x = 0, y = 0, width = width, height = height, hp = hp, quad = enemyQuad, movePattern = movePattern, currentMoveIndex = 1,
    bulletSpeed = bulletSpeed, damage = damage, bulletDamage = bulletDamage, enemyShootTimer = shootTimer, defaultEnemyShootTimer = shootTimer, type = typeId }

    return newEnemy
  else
    return nil
  end
end
