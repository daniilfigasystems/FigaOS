-- Данный код частично сгенерирован программой FormsMaker
-- http://computercraft.ru/topic/1044-sistema-vizualnogo-programmirovaniia-formsmaker/
local gpu=require("component").gpu
local term = require('term')
local eventPull=require("event").pull
local forms=require("forms")
local serialize=require("serialization").serialize
local keys = require("keyboard").keys

local padRight=require("text").padRight
local len=require("unicode").len
local sub=require("unicode").sub

local scr  -- Хранит содержимое экрана
local fnCode --функция, содержащая код программы
local ENV  -- Окружение, под которым работает программа
local args={...}

local function saveScreen() -- Сохраняем текущий экран в таблицу scr
  scr={fc=gpu.getForeground(),bc=gpu.getBackground(),blink=term.getCursorBlink()}
  scr.W,scr.H = gpu.getResolution()
  scr.posX, scr.posY = term.getCursor()
  for i=1,scr.H do
    scr[i]={}
	local FC,BC
	for j=1,scr.W do
	  local c,fc,bc=gpu.get(j,i)
	  if fc==FC then fc=nil end
	  if bc==BC then bc=nil end
	  if fc or bc then
        table.insert(scr[i],{fc=fc,bc=bc,c=""})
		FC,BC=fc or FC, bc or BC
	  end
	  scr[i][#scr[i]].c=scr[i][#scr[i]].c .. c
	end
  end
  gpu.setResolution(80,25) os.sleep(0)
end

local function loadScreen()  -- Восстанавливаем содержимое экрана
  gpu.setResolution(scr.W,scr.H) os.sleep(0)
  term.setCursorBlink(false)
  for i=1,scr.H do
    local curX=1
    for j=1,#scr[i] do
	  if scr[i][j].fc then gpu.setForeground(scr[i][j].fc) end
	  if scr[i][j].bc then gpu.setBackground(scr[i][j].bc) end
      gpu.set(curX,i,scr[i][j].c) curX=curX+len(scr[i][j].c)
	end
  end
  gpu.setForeground(scr.fc)
  gpu.setBackground(scr.bc)
  term.setCursor(scr.posX,scr.posY)
  term.setCursorBlink(scr.blink)
end
saveScreen()

local function review()  -- Пересчитываем окно просмотра
  local res,ok
  for i=1,#lstVars.items do
    res=load("return "..lstVars.items[i],nil,nil,ENV)
	if res then
	  ok,res=pcall(res)
	  if ok then res=serialize(res,true):gsub("\n","")
	  else res=res:match("]:1:(.*)") end
	else res="Ошибка" end
    lstVars.lines[i]=" "..lstVars.items[i].." = "..res
  end
end

local function Main() Form1:setActive() end

local thread     -- Поток, в котором выполняется программа
local linePtr=0  -- Указатель на исполняемую строку
local ok,param  -- Параметры обмена между потоками

local function runDebug(condStep,condCur)
  if not fnCode then return end
  loadScreen()
  if condCur then
    while lstText.items[lstText.index]==nil and lstText.index<#lstText.lines do lstText.index=lstText.index+1 end
  end
  repeat
    if not thread then thread=coroutine.create(fnCode) param="debug" end  -- Первый запуск
	if param=="debug" then ok,param,linePtr=coroutine.resume(thread,table.unpack(args,2))
    else  ok,param,linePtr=coroutine.resume(thread,coroutine.yield(param)) end   -- Возобновление работы
    if not ok or coroutine.status( thread ) == "dead" then thread=nil end
  until not thread or (param=="debug" and (condStep or (condCur and lstText.index==linePtr) or lstText.items[linePtr]))
  saveScreen()
  review()
  if ok then
    if thread then
      if linePtr<lstText.shift+1 then lstText.shift=linePtr-1 end
      if linePtr>lstText.shift+lstText.H-2 then lstText.shift=linePtr-lstText.H+2 end
	end
    Form1:redraw()
  else lbError2.caption=param FormError:setActive() end
end

forms.ignoreAll()

Form1=forms.addForm()
Form1.H=1
Form1.color=65535

btStop=Form1:addButton(1,1,"Стоп(F2)",
  function()
    thread=nil
	lstText:redraw()
  end
)
btStop.fontColor=0
btStop.color=Form1.color

btBrkPt=Form1:addButton(11,1,"ТочОст(F4)",
  function()
    if lstText.items[lstText.index]~=nil then
      lstText.items[lstText.index] = not lstText.items[lstText.index]
	end
  end
)
btBrkPt.color=Form1.color
btBrkPt.fontColor=0

btScreen=Form1:addButton(22,1,"Экран(F5)",
  function ()
    local ev
    loadScreen()
	repeat ev=eventPull() until ev=="key_down" or ev=="touch"
	gpu.setResolution(80,25)
	Form1:redraw() 
  end
)
btScreen.color=Form1.color
btScreen.W=9
btScreen.fontColor=0

btView=Form1:addButton(32,1,"Просм(F6)",function() edView.text="" FormView:setActive() edView:touch(_,_,0) end)
btView.color=Form1.color
btView.fontColor=0
btView.W=9

btCur=Form1:addButton(42,1,"ДоКур(F7)",function() runDebug(false,true) end)
btCur.color=Form1.color
btCur.fontColor=0
btCur.W=9

btStep=Form1:addButton(52,1,"Шаг(F8)", function() runDebug(true,false) end )
btStep.color=Form1.color
btStep.fontColor=0
btStep.W=8

btRun=Form1:addButton(60,1,"Пуск(F9)",function() runDebug(false,false) end )
btRun.color=Form1.color
btRun.fontColor=0
btRun.W=9

btExit=Form1:addButton(69,1,"Выход(F10)",forms.stop)
btExit.fontColor=0
btExit.color=Form1.color

btAbout=Form1:addButton(80,1,"?",function() FormAbout:setActive() end)
btAbout.fontColor=0
btAbout.W=1
btAbout.color=Form1.color

local eventKey={
  [keys.f2]=btStop.onClick,
  [keys.f4]=btBrkPt.onClick,
  [keys.f5]=btScreen.onClick,
  [keys.f6]=btView.onClick,
  [keys.f7]=btCur.onClick,
  [keys.f8]=btStep.onClick,
  [keys.f9]=btRun.onClick,
  [keys.f10]=btExit.onClick,
}
eventKey[keys.up]=function()
  if lstText.index>1 then
    lstText.index=lstText.index-1
	if lstText.index<lstText.shift+1 then lstText.shift=lstText.index-1 end
	lstText:redraw()
  end
end

eventKey[keys.down]=function()
  if lstText.index<#lstText.lines then
    lstText.index=lstText.index+1
	if lstText.index>lstText.shift+lstText.H-2 then lstText.shift=lstText.index-lstText.H+2 end
	lstText:redraw() 
  end
end

eventKey[keys.delete]=function()
  if lstVars.index>0 then
    table.remove(lstVars.lines,lstVars.index)
    table.remove(lstVars.items,lstVars.index)
	if lstVars.index>#lstVars.lines then lstVars.index=#lstVars.lines end
	lstVars:redraw()
  end
end

eventKey[keys.enter]=function()
  if Form1:isActive() then
    edExec.text=""
    Execute:setActive()
    edExec:touch(_,_,0)
  end
end

function evKeyDownonEvent(self, _, _, code)
  if eventKey[code] then eventKey[code]() end
end

evKeyDown=Form1:addEvent("key_down",evKeyDownonEvent)

function lstTextPaint(self)
  local n
  for i=1,self.H-2 do
    n=i+self.shift
	if thread and n==linePtr then gpu.setForeground(0x000000) gpu.setBackground(0x00ff00) -- текущая строка
	elseif n==self.index then gpu.setForeground(self.sfColor) gpu.setBackground(self.selColor) -- курсор
	elseif self.items[n] then gpu.setForeground(0xffffff) gpu.setBackground(0xff0000) -- точка останова
	else gpu.setForeground(self.fontColor) gpu.setBackground(self.color)
	end
    gpu.set(self.X+1,self.Y+i, padRight(sub(self.lines[i+self.shift] or "",1,self.W-2),self.W-2))
  end
  lbCur.caption="["..self.index.."]"
  lbCur.left=self.W-#lbCur.caption-1
  if thread then lbMode.caption="RUN:"..linePtr else lbMode.caption="STOP" end
  lbMode.W=#lbMode.caption
end

function lstTextInsert(self,line,item)
  self.lines[#self.lines+1]=line
  self.items[#self.lines]=item
  if self.index<1 then self.index=1 end
  if #self.lines<self.shift+self.H-1 then self:redraw() end
end

lstText=Form1:addList(1,2)
lstText.H=18
lstText.W=80
lstText.color=128
lstText.paint=lstTextPaint
lstText.insert=lstTextInsert

lbFileName=lstText:addLabel(33,1," Код не загружен ")
lbFileName.W=17
lbFileName.color=lstText.color

lbCur=lstText:addLabel(72,18,"[0]")
lbCur.color=lstText.color

lbMode=lstText:addLabel(3,18,"STOP")
lbMode.color=lstText.color

lstVars=Form1:addList(1,20)
lstVars.H=6
lstVars.W=80
lstVars.color=32768

Label1=lstVars:addLabel(35,1," Просмотр ")
Label1.color=lstVars.color

FormError=forms.addForm()
FormError.top=7
FormError.H=12
FormError.border=1
FormError.W=53
FormError.left=15
FormError.color=8388608

lbError1=FormError:addLabel(24,3,"Ошибка")
lbError1.W=6
lbError1.color=FormError.color

lbError2=FormError:addLabel(4,5,"lbError2")
lbError2.autoSize=false
lbError2.H=4
lbError2.W=47
lbError2.centered=true
lbError2.color=FormError.color

btOk=FormError:addButton(22,10,"Ok",Main)

FormAbout=forms.addForm()
FormAbout.H=8
FormAbout.border=1
FormAbout.W=24
FormAbout.color=0x008000
FormAbout.left=math.floor((80-FormAbout.W)/2)
FormAbout.top =math.floor((25-FormAbout.H)/2)

lbAbout=FormAbout:addLabel(2,3,"Отладчик луа-кода\nВерсия 1.2\n от Zer0Galaxy")
lbAbout.W=FormAbout.W-2
lbAbout.H=3
lbAbout.color=FormAbout.color
lbAbout.centered=true
lbAbout.autoSize=false
lbError2.color=FormError.color

btAboutOk=FormAbout:addButton(8,7,"Ok",Main)

FormView=forms.addForm()
FormView.W=49
FormView.left=17
FormView.H=10
FormView.top=7
FormView.color=32768
FormView.border=1

edView=FormView:addEdit(4,4)
edView.color=FormView.color
edView.W=43

btViewOk=FormView:addButton(11,8,"Ok",
  function ()
  if edView.text~="" then
    lstVars:insert("",edView.text)
	review()
	Main()
  end
end)

btViewCancel=FormView:addButton(30,8,"Отмена",Main)

lbView=FormView:addLabel(5,3,"Выражение для просмотра:")
lbView.W=41
lbView.centered=true
lbView.autoSize=false
lbView.color=FormView.color

Execute=forms.addForm()
Execute.H=10
Execute.left=12
Execute.W=59
Execute.border=1
Execute.top=8
Execute.color=0x787878

lbExec=Execute:addLabel(5,3,"Выполнить:")
lbExec.W=10
lbExec.color=Execute.color

edExec=Execute:addEdit(4,4)
edExec.W=53
edExec.color=Execute.color

function btExeOkClick()
  if edExec.text~="" then
    local f,err,ok=load(edExec.text,nil,nil,ENV)
	if f then
      loadScreen()
      ok,err=pcall(f)
      saveScreen()
	  if ok then err=nil end
      review()
	end
    if err then lbError2.caption=err FormError:setActive() return
	end
  end
  Main()
end

btExeOk=Execute:addButton(17,8,"OK",btExeOkClick)

btExeCans=Execute:addButton(33,8,"Отмена",Main)


fileName=args[1]
if fileName then codeFile=io.open(fileName) end
local linesLoad,bug
local err="Код не загружен"

function readline()
  linesLoad=linesLoad+1
  if linesLoad<=#lstText.lines then
    if lstText.items[linesLoad]~=nil then
	  return "coroutine.yield('debug'," .. linesLoad .. ") " ..lstText.lines[linesLoad].."\r"
    end
    return lstText.lines[linesLoad].."\r"
  else
    bug=false
    local line=codeFile:read()
    if line then
      if line:sub(-1) == "\r" then line = line:sub(1, -2) end
	  if line:match("^%s*%a") then  --если строка начинается с буквы
        lstText:insert(" "..line,false)  -- добавляем возможность точки останова
	    return "coroutine.yield('debug'," .. #lstText.lines .. ") " ..line.."\r"
	  end
      lstText:insert(" "..line)
	  return line.."\r"
    end
  end
end
ENV={}
for k,v in pairs(_G) do ENV[k]=v end

if codeFile then
  lbFileName.caption=" "..fileName.." "
  lbFileName.W=#lbFileName.caption
  lbFileName.left=(lstText.W-lbFileName.W)/2
  repeat
    linesLoad = 0 bug=true
    fnCode,err=load(readline,fileName,nil,ENV)
	if not fnCode then lstText.items[linesLoad]=nil end
  until fnCode or bug
  codeFile:close()
end

if fnCode then forms.run(Form1)
else lbError2.caption=err forms.run(FormError) end

loadScreen()