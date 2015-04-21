--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

-- returns new enemy by type
function enemyCreateNew(typeId)
  local shootTimer, speed, hp, movePatern, damage
  if typeId == 1 then
    local shootTimer = 1
    local speed = 175
    local hp = 30
    local damage = 30
    local bulletDamage = 20
    local bulletSpeed = 400
    local width = 34
    local height = 30
    local enemyQuad = love.graphics.newQuad(94, 31, width, height, allShips:getWidth(), allShips:getHeight())
    --movePatern = {angles = {0.7853981634, 3.14, 5.4977871438, 0}, time = {1,2,1,10}}

    newEnemy = { x = 0, y = 0, width = width, height = height, hp = hp, quad = enemyQuad, enemySpeed = speed, bulletSpeed = bulletSpeed,
    damage = damage, bulletDamage = bulletDamage, enemyShootTimer = shootTimer, defaultEnemyShootTimer = shootTimer, type = typeId }

    return newEnemy
  elseif typeId == 2 then
    local shootTimer = 0.5
    local speed = 200
    local hp = 10
    local damage = 20
    local bulletDamage = 10
    local bulletSpeed = 350
    local width = 24
    local height = 23
    local enemyQuad = love.graphics.newQuad(7, 67, width, height, allShips:getWidth(), allShips:getHeight())

    newEnemy = { x = 0, y = 0, width = width, height = height, hp = hp, quad = enemyQuad, enemySpeed = speed, bulletSpeed = bulletSpeed,
    damage = damage, bulletDamage = bulletDamage, enemyShootTimer = shootTimer, defaultEnemyShootTimer = shootTimer, type = typeId }

    return newEnemy
  else
    return nil
  end
end
