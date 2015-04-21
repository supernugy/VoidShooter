--          Copyright Tomáš Nguyen 2015.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          http://www.boost.org/LICENSE_1_0.txt)

button = {}
font = nil

--creating new button at position x and y with text and id
function menuButtonSpawn(x,y,text, id)
  x = x-(font:getWidth(text)/2)
  table.insert(button,{x = x, y = y, text = text, id = id, mouseOver = false})
end

-- draw/print buttons
function menuButtonDraw()
  for i, v in ipairs(button) do

    if v.mouseOver == false then
      love.graphics.setColor(255,255,255,255)
      font = love.graphics.newFont(34)
    else
      love.graphics.setColor(100,200,20,255)
      font = love.graphics.newFont(34)
    end

    love.graphics.setFont(font)
    love.graphics.print(v.text, v.x, v.y)
  end
end

--check if clicked and do action if so
function menuButtonClick(x, y)
  for i, v in ipairs(button) do
    if x > v.x and x < v.x + font:getWidth(v.text) and
     y > v.y and y < v.y + font:getHeight(v.text) then

       if v.id == "quit" then
         love.event.push("quit")
       elseif v.id == "start" then
         font = love.graphics.newFont(20)
         love.graphics.setFont(font)
         resetVariables()
         score = 0
         levelStart(1)
       end

    end
  end
end

--check if mouse is over a button (for hover color effect)
function menuButtonCheck()
  for i, v in ipairs(button) do
    if mouseX > v.x and mouseX < v.x + font:getWidth(v.text) and
    mouseY > v.y and mouseY < v.y + font:getHeight(v.text) then
      v.mouseOver = true
    else
      v.mouseOver = false
    end
  end
end
