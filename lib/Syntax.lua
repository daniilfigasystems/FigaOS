local gpu = require("component").gpu
local unicode = require("unicode")
local syntax = {}

----------------------------------------------------------------------------------------------------------------

--����������� �������� �����
local colorSchemes = {
	["midnight"] = {
		["recommendedBackground"] = 0x262626,
		["text"] = 0xffffff,
		["strings"] = 0xff2024,
		["loops"] = 0xffff98,
		["comments"] = 0xa2ffb7,
		["boolean"] = 0xffcc66,
		["logic"] = 0xffcc66,
		["numbers"] = 0x24c0ff,
		["functions"] = 0xffcc66,
		["compares"] = 0xffff98,
	},
	["sunrise"] = {
		["recommendedBackground"] = 0xffffff,
		["text"] = 0x262626,
		["strings"] = 0x880000,
		["loops"] = 0x24c0ff,
		["comments"] = 0xa2ffb7,
		["boolean"] = 0x19c0cc,
		["logic"] = 0x880000,
		["numbers"] = 0x24c0ff,
		["functions"] = 0x24c0ff,
		["compares"] = 0x880000,
	},
}

--������� �������� �����
local currentColorScheme = {}
--������� ������
local patterns
--������ ������� �������� ������
local sPatterns

----------------------------------------------------------------------------------------------------------------

--����������� ����� ��������
--��������� ������ �������� ��������� ������ ����
local function definePatterns()
	patterns = {
		--�����������
		{ ["pattern"] = "%-%-.*", ["color"] = currentColorScheme.comments, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		
		--������
		{ ["pattern"] = "\"[^\"\"]*\"", ["color"] = currentColorScheme.strings, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		
		--�����, �������, ����������
		{ ["pattern"] = "while ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "do$", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "do ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "end$", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "end ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "for ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = " in ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "repeat ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "if ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "then", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "until ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "return", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "local ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "function ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "else$", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "else ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "elseif ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },

		--��������� ����������
		{ ["pattern"] = "true", ["color"] = currentColorScheme.boolean, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "false", ["color"] = currentColorScheme.boolean, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "nil", ["color"] = currentColorScheme.boolean, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
				
		--�������
		{ ["pattern"] = "%s([%a%d%_%-%.]*)%(", ["color"] = currentColorScheme.functions, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		
		--And, or, not, break
		{ ["pattern"] = " and ", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = " or ", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = " not ", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = " break$", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "^break", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = " break ", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },

		--�����
		{ ["pattern"] = "%s(0x)(%w*)", ["color"] = currentColorScheme.numbers, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "(%s)([%d%.]*)", ["color"] = currentColorScheme.numbers, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		
		--��������� � ���. ��������
		{ ["pattern"] = "<=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = ">=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "<", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = ">", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "==", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "~=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%+", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%-", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%*", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%/", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%.%.", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%#", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "#^", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
	}

	--��, � ������ ������� �������� ����
	sPatterns = #patterns
end

--���������� ������ �������� string.find()
--�������� ���������, �� ���� �� ������������ ������
function unicode.find(str, pattern, init, plain)
	-- checkArg(1, str, "string")
	-- checkArg(2, pattern, "string")
	-- checkArg(3, init, "number", "nil")
	if init then
		if init < 0 then
			init = -#unicode.sub(str,init)
		elseif init > 0 then
			init = #unicode.sub(str,1,init-1)+1
		end
	end
	
	a, b = string.find(str, pattern, init, plain)
	
	if a then
		local ap,bp = str:sub(1,a-1), str:sub(a,b)
		a = unicode.len(ap)+1
		b = a + unicode.len(bp)-1
		return a,b
	else
		return a
	end
end

--���������������� ������ � ������� �� �� ������ �������� �����
function syntax.highlight(text)
	--������ �������� � �� ������
	local massiv = {}
	--����� ������
	local sText = unicode.len(text)
	--������� ���� ������
	local currentColor = currentColorScheme.text
	--������ ����� ������ ���������� ��������
	local searchFrom = 1
	--���������� ��������� ������
	local sucessfullyFound = false
	--���������� ��� ������ ����������� � ����������� ������� ������� ���� ����
	local symbol = 1
	while symbol <= sText do
		--�������� ����� ������, ��� ��� �����, ������ �� ��� ���-��
		sucessfullyFound = false
		--���������� ��� �������
		for i = 1, sPatterns do
			--���� ����������
			local starting, ending = unicode.find(text, patterns[i].pattern, searchFrom)
			--���� ����� ���������� ��������� � ������� �������, ��
			if starting and starting == symbol then
				--������ ���� ��� �������� � ����������� ��������
				currentColor = patterns[i].color
				--��������� ���� ��������, ��������������� �������, �� ����
				for j = (starting + patterns[i].cutFromLeft), (ending - patterns[i].cutFromRight) do
					massiv[j] = { ["symbol"] = unicode.sub(text, j, j), ["color"] = currentColor }
				end
				--��������� ����� ������� ������
				searchFrom = ending + 1 - patterns[i].cutFromRight
				--� ����� ������� �������
				symbol = searchFrom
				--������ true, ��� ������� ��� ������
				sucessfullyFound = true
				--��������� ����, ��� ����� ������ ������
				break
			end
			--�������� ����������, ��� � ��� �����
			starting, ending = nil, nil
		end

		--���� �� ���� �� �����, ��
		if not sucessfullyFound then
			--������ ������� ���� ������
			currentColor = currentColorScheme.text
			--�������� ������� ������
			massiv[symbol] = { ["symbol"] = unicode.sub(text, symbol, symbol), ["color"] = currentColor }
			--�� �����
			symbol = symbol + 1
		end
	end

	--� ��� ����
	sText, currentColor, searchFrom = nil, nil, nil

	--���������� ���������� ������
	return massiv
end

--�������� ����� �������� �����
function syntax.setColorScheme(colorScheme)
	--��������� �������� �����
	currentColorScheme = colorScheme
	--������������� �������
	definePatterns()
end

--���������� ��������� ������ �� ��������� ����������� � �������� ������ �� ��������� �����.
function syntax.highlightAndDraw(x, y, limit, text)
	--����� ����� ������ ����������, �.�. ���� ���������� � 1
	x = x - 1
	--�������� ������������ ������
	local massiv = syntax.highlight(text)
	--������ ��������� ����
	local currentColor = currentColorScheme.text
	gpu.setForeground(currentColor)
	--��������� �������. ����� ��� ���������� ���� ��������?
	if limit >= #massiv then limit = #massiv end
	--���������� ��� �������� ����������� �������
	local symbol = 1
	while symbol <= limit do
		--������ �����������. ������ ���� ������ ������ � ������ �������������� �������� ����� � ����� �� �������
		if currentColor ~= massiv[symbol].color then currentColor = massiv[symbol].color; gpu.setForeground(massiv[symbol].color) end
		--������ �����������. ����������� ��������� ����� ������� ���� ������ �� ����� �������� ������ ������ �������
		local stro4ka = massiv[symbol].symbol
		--������� ���-�� ����������� �������� � ����� �� ������, ��� � � �����
		local counter = 1
		--���������� ��� ������� � ������������ � �� �����
		for nextSymbol = (symbol + 1), limit do
			--���� ���� ������������ ����� ��������
			if massiv[nextSymbol].color == massiv[symbol].color then
				--�� ��������� � ������� ��������� ������
				stro4ka = stro4ka .. massiv[nextSymbol].symbol
				--�������� � counter, ��� ������� �������, ������, +1 � ����
				counter = counter + 1
			else
				break
			end
		end
		--������������ ����� ������ ����� ����� ������
		gpu.set(x + symbol, y, stro4ka)
		--���������� � ������� �������, ������� ������� ����� ���������
		symbol = symbol + counter
		--������� ������
		stro4ka, counter = nil, nil
	end
end

--������� ���� ��� ������ � ���������� ������ ������ �� ����, ����� �������, ��� �������� ���������
function syntax.highlightFileForDebug(pathToFile, colorSchemeName)
	--������������� �������� �����
	syntax.setColorScheme(colorSchemes[colorSchemeName] or colorSchemes.midnight)
	--������� ����� ������������� ������
	ecs.prepareToExit(currentColorScheme.recommendedBackground, currentColorScheme.text)
	--�������� ������ ������
	local xSize, ySize = gpu.getResolution()
	--��������� ������
	local file = io.open(pathToFile, "r")
	--������� �����
	local lineCounter = 1
	--������ ������
	for line in file:lines() do
		--������������ ������ � ������
		syntax.highlightAndDraw(2, lineCounter, xSize - 2, line)
		--������� � ����
		lineCounter = lineCounter + 1
		--��������� ����, ���� ���-�� ����� ��������� ������ ������
		if lineCounter > ySize then break end 
	end
	--��������� ����
	file:close()
end

----------------------------------------------------------------------------------------------------------------

--��������� ���������� �������� ����� ��� �������� ����������
syntax.setColorScheme(colorSchemes.midnight)

--syntax.highlightFileForDebug("highlightText", "midnight")
syntax.highlightAndDraw(5, 10, 8, "while true do test print() zebal end")

return syntax
