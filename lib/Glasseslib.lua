--WorkGlasses - виртуальный рабочий стол
--(c) SergOmarov, 2015
local shell=require("shell")
local event=require("event")
local term=require("term")
local c=require("component")
local computer=require("computer")

local chat=c.chat_box
local textFieldsList={}

local textFields={}

local glasses=c.glasses
local gpu=c.gpu

local w,h=gpu.getResolution()

local textNull=""
--[[while #text~=w
i=i+1
if(#text<w)then
text=text..text
elseif(#text<w)then
text=string.sub(text,1,#text-1)
end
end
print(i)]]
for i=1,w do
textNull=textNull.." "
end

local function reset()
for i=1,h do
textFields[i]=glasses.addTextLabel()
textFields[i].setText(textNull)
textFields[i].setPosition(1,i*7)

end
end
reset()
local function get(x,y)
return textFields[y].getText():sub(x,x)
end

local function setSimbol(x,y,simbol)
simbol=simbol:sub(1,1)
local textField=textFields[y]
local text0=textField.getText()
local text1=text0:sub(1,x)
local text2=text0:sub(x+1,math.huge)
text0=text1..simbol..text2
textField.setText(text0)

end

local function set(x,y,text)
local textField=textFields[y]
local text0=textField.getText()
local text1=text0:sub(1,x)
local ltext=#text
local text2=text0:sub(x+#text,math.huge)
text=text1..text..text2
textField.setText(text)
end

local function copy(x,y,w,h,x1,y1)
local len=h+y
for i=y,len do
set(x+x1,i+y1,textFields[i].getText():sub(x,x+w))
end
end

term.setCursorBlink(false)
term.setCursorBlink=function()end

local gpu_set=gpu_set or gpu.set
local gpu_setBackground=gpu_setBackground or gpu.setBackground
local gpu_setForeground=gpu_setForeground or gpu.setForeground
local gpu_copy=gpu_copy or gpu.copy

gpu.set=function(x,y,text)
gpu_set(x,y,text)
set(x,y,text)

end
gpu.copy=function(x,y,w,h,x1,y1)
gpu_copy(x,y,w,h,x1,y1)
copy(x,y,w,h,x1,y1)

end
local glasses_removeAll=glasses.removeAll
glasses.removeAll=function()
glasses_removeAll()
reset()

end

local term_clearLine=term.clearLine
term.clearLine=function(line)
textFields[line].setText(textNull)
term_clearLine()
end

local term_clear=term.clear
term.clear=function()
glasses.removeAll()
term_clear()
end

function Set(list)
  local set = {}
  for l=1,#list do set[list[l]] = true end
  return set
end

local pullSignal = pullSignal or computer.pullSignal

computer.pullSignal = function (...)
local eventObject={pullSignal(...)}
if eventObject[1]=='chat_message' then
local users=Set({computer.users()})
if(users[eventObject[3]])then
local stringS=eventObject[4]
if(stringS:find("--")==1)then
if(stringS:find("/")==3)then
stringS=string.sub(stringS,4,#stringS)
shell.execute(stringS)
else
print(string.sub(stringS,3,#stringS))

end

end

end
end
return table.unpack(eventObject)
end