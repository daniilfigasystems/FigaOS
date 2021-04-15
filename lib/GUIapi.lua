--            *  *  *
-- GUI API (OpenComputers) (1.0)
-- 05/04/2015 (c) computercraft.ru
-- Created by Totoro, LeshaInc, Xom and some magic
--            *  *  *
 
-- Создаем таблицу
local API = {}
local param= {}
 
-- Подключаем системные API
local event = require('event')
local term = require("term") 
local component = require("component")
local gpu = component.gpu
 
-- Константы
-- Получаем разрешение монитора
local WIDTH, HEIGHT = gpu.getResolution()  -- понятные названия - наше все =)
-- Цвета
local color = {}
color.green = 0x00AA00
color.red   = 0xAA0000
color.black = 0x000000
color.white = 0xFFFFFF
-- Символы из Юникода
local LOWER_HALF_BLOCK = "-"
local UPPER_HALF_BLOCK = "-"
local LEFT_HALF_BLOCK = "¦"
local RIGHT_HALF_BLOCK = "¦"
-- Восстановители рассудка.
local FLOWERS = "? ? ? ? ? ? ?"
 
-- Функция очистки экрана
function API.clear(color)
    gpu.setBackground(color)
    gpu.fill(1, 1, WIDTH, HEIGHT,  " ")
end
 
-- ========================== Кнопочки =) ========================== --
-- интерактивные кнопки от Totoro
-- создаем кнопку
Button = {}
Button.__index = Button
function Button.new(func, x, y, text, fore, back, width, nu)
  self = setmetatable({}, Button)
 
  self.form = '[ '
  if width == nil then width = 0
    else width = (width - unicode.len(text))-4 end
  for i=1, math.floor(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..text
  for i=1, math.ceil(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..' ]'
 
  self.func = func
 
  self.x = math.floor(x); self.y = math.floor(y)
  self.fore = fore
  self.back = back
  self.visible = true
 
  self.notupdate = nu or false
 
  return self
end
 
-- рисуем кнопку
function Button:draw(fore, back)
  if self.visible then
    local fore = fore or self.fore
    local back = back or self.back
    gpu.setForeground(fore)
    gpu.setBackground(back)
    gpu.set(self.x, self.y, self.form)
  end
end
 
-- обрабатываем клик по кнопке
function Button:click(x, y)
  if self.visible then
    if y == self.y then
      if x >= self.x and x < self.x+unicode.len(self.form) then
        self:draw(self.back, self.fore)
        local data = self.func()
        if not self.notupdate then self:draw() end
        return true, data
      end
    end
  end
  return false
end
 
-- набор вспомогательных функций для работы с группами кнопок
-- добавляем кнопку в группу
function buttonNew(buttons, func, x, y, text, fore, back, width, notupdate)
  button = Button.new(func, x, y, text, fore, back, width, notupdate)
  table.insert(buttons, button)
  return button
end
-- рисуем группу кнопок
function buttonsDraw(buttons)
  for i=1, #buttons do
    buttons[i]:draw()
  end
end
-- обработка клика на группе кнопок
function buttonsClick(buttons, x, y)
  for i=1, #buttons do
    ok, data = buttons[i]:click(x, y)
    if ok then return data end
  end
  return nil
end
 
 
-- ========================= Псевдографика ========================= --
-- Функция рисования пикселя
function API.pixel(x,y,color)
    gpu.setBackground(color)
    gpu.set(x,y," ")
end
 
-- Линия от А до Б (by Xom)
-- (Запасной вариант) LeshaInc опять ничего не понял.
-- Осторожно: неоттестировано!
function API.xline(x1, y1, x2, y2, color, symbol)
    local deltax,deltay,stat,errors,temp,nextstep= 0,0,1,0,0,0
    deltax= x1-x2
    deltay= y1-y2
    errors= deltax/deltay
    if (x1 < x2) then
       stat= -1
    end
    for i=x1,x2,stat do
       temp= x1+errors
       c,d= math.fmod(temp)
       while true do
          temp= x1+errors
          c,d= math.fmod(temp)
          if (d > 5) then
             y1= y1-1
             API.pixel(x1,y1)
          else
             break
          end
       end
    end
end
 
-- Функция создания заполненной коробки
function API.box(x,y,WIDTH,HEIGHT,color,symbol) --Поставте symbol " " и будет чистый пиксель
    gpu.setBackground(color)
    gpu.fill(x,y,WIDTH,HEIGHT,symbol)
end
 
-- Функция выдачи позиции курсора
function API.getClick()
    local name, x, y, button, playerName = event.pull()
    return x, y, button, playerName
end
 
-- Функция написания текста, центрированного относительно X
function API.centerTextX(y,text,color)
    gpu.setForeground(color)
    gpu.set(w/2 - #text/2, y, text)
end
 
-- Функция написания текста, центрированного относительно Y
function API.centerTextY(x,text,color)
    gpu.setForeground(color)
    gpu.set(x,h/2-#text/2,text)
end
 
-- Функция написания текста, центрированного относительно XY
function API.centerTextXY(text,color)
    gpu.setForeground(color)
    gpu.set(x-#text/2,y-#text/2,text)
    
-- Функция отображения 'пустой' коробки  
-- Поставте symbol " " и будет чистый пиксель
function API.emptyBox(x,y,WIDTH,HEIGHT,color_inside,color_side,strip_thickness,symbol_side,symbol_inside)
    gpu.setBackground(color_side)
    gpu.fill(x,y,WIDTH,HEIGHT, symbol_side)
    gpu.setBackground(color_inside)
    gpu.fill(x+strip_thickness,y+strip_thickness,WIDTH-strip_thickness,HEIGHT-strip_thickness, symbol_inside)
end
 
-- Линия от А до Б
-- Ported from CC paintutils lib
-- LeshaInc говорит:"Это за грани моего понимания."
function API.line(startX, startY, endX, endY, nColor)
    if type(startX) ~= "number" or type(startX) ~= "number" or
       type(endX) ~= "number" or type(endY) ~= "number" or
       (nColor ~= nil and type(nColor) ~= "number") then
        error("Expected startX, startY, endX, endY, color", 2)
    end
    
    startX = math.floor(startX)
    startY = math.floor(startY)
    endX = math.floor(endX)
    endY = math.floor(endY)
 
    if startX == endX and startY == endY then
        API.pixel(startX, startY, nColor)
        return
    end
    
    local minX = math.min(startX, endX)
    if minX == startX then
        minY = startY
        maxX = endX
        maxY = endY
    else
        minY = endY
        maxX = startX
        maxY = startY
    end
 
    -- TODO: clip to screen rectangle?
    
    local xDiff = maxX - minX
    local yDiff = maxY - minY
            
    if xDiff > math.abs(yDiff) then
        local y = minY
        local dy = yDiff / xDiff
        for x=minX,maxX do
            API.pixel(x, math.floor(y + 0.5), nColor)
            y = y + dy
        end
    else
        local x = minX
        local dx = xDiff / yDiff
        if maxY >= minY then
            for y=minY,maxY do
                API.pixel(math.floor(x + 0.5), y, nColor)
                x = x + dx
            end
        else
            for y=minY,maxY,-1 do
                API.pixel(math.floor(x + 0.5 ), y, nColor)
                x = x - dx
            end
        end
    end
end
 
return API