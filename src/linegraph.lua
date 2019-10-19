local Series, LineChart, getMin, getMax, map, range

--credits: https://snipplr.com/view/13086/number-to-hex/
--modified by me
local hexstr = '0123456789abcdef'
function num2hex(num)
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    return string.upper(s == '' and '0' or s)
end

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end


--[====[
    @type func
    @name getMin(tbl)
    @param tbl:number[] Input table
    @return number Minimum value
    @brief Returns the minimum value of the passed table
--]====]

function getMin(tbl)
	local min = tbl[1]
	for v = 1, #tbl do
		v = tbl[v]
		if v < min then
			min = v
		end
	end
	return min
end

--[====[
    @type func
    @name getMax(tbl)
    @param tbl:number[] Input table
    @return number Maximum value
    @brief Returns the maximum value of the passed table
--]====]
function getMax(tbl)
	local max = tbl[1]
	for v = 1, #tbl do
		v = tbl[v]
		if v > max then
			max = v
		end
	end
	return max
end

function map(tbl, f)
	local res = {}
	for k, v in next, tbl do
		res[k] = f(v)
	end
	return res
end

function range(from, to, step)
    local insert = table.insert
	local res = { }
	for i = from, to, step do
		insert(res, i)
	end
	return res
end


local function invertY(y)
	return 400 - y
end


--class Series
--[====[
    @type class
    @name Series
    @brief A data series
    @description [
        Data series can be used to store X and Y data of something. This can be also used inside a #LineChart instance to output the data as a chart
    ]
--]====]
Series = {}
Series.__index = Series

setmetatable(Series, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

--[====[
    @type func
    @name Series.new(dx, dy, name, col)
    @param dx:number[] The <code>x</code> data
    @param dy:number[] The <code>y</code> data
    @param name:string The name of the series.
    @param col:number|nil The color of the series. If <code>nil</code> or nothing is provided assigns a random color.
    @return A new Series instance
    @brief Creates a new Series instance
    @description [
        Creates a new series instance. Note that you can also Series(dx, dy, name, col) for the same purpose.
    ]
--]====]
function Series.new(dx, dy, name, col)
  assert(#dx == #dy, "Expected same number of data for both axis")
  local self = setmetatable({ }, Series)
  self.name = name
  self:setData(dx, dy)
  self.col = col or math.random(0x000000, 0xFFFFFF)
  return self
end

--[====[
    @type func
    @name Series:getName()
    @return string The name of the series
    @brief Returns the name of the series
--]====]
function Series:getName() return self.name end

--[====[
    @type func
    @name Series:getDX()
    @return number[] The X data
    @brief Returns the data X
--]====]
function Series:getDX() return self.dx end

--[====[
    @type func
    @name Series:getDX()
    @return number[] The Y data
    @brief Returns the data Y
--]====]
function Series:getDY() return self.dy end

--[====[
    @type func
    @name Series:getColor()
    @return number the color of the series
    @brief Returns the color of the series
--]====]
function Series:getColor() return self.col end

function Series:getMinX() return self.minX end
function Series:getMinY() return self.minY end
function Series:getMaxX() return self.maxX end
function Series:getMaxY() return self.maxY end
function Series:getDataLength() return #self.dx end
function Series:getLineWidth() return self.lWidth or 3 end

function Series:setName(name)
  self.name = name
end

function Series:setData(dx, dy)
  self.dx = dx
  self.dy = dy
  self.minX = getMin(dx)
  self.minY = getMin(dy)
  self.maxX = getMax(dx)
  self.maxY = getMax(dy)
end

function Series:setColor(col)
  self.col = col
end

function Series:setLineWidth(w)
  self.lWidth = w
end

-- class LineChart
LineChart = {}
LineChart.__index = LineChart
LineChart._joints = 10000

setmetatable(LineChart, {
	__call = function (cls, ...)
		return cls.new(...)
	end
})

function LineChart.init()
    tfm.exec.addPhysicObject(-1, 0, 0, { type = 14, miceCollision = false, groundCollision = false })
end

function LineChart.handleClick(call, n, id)
    if call:sub(0, ("lchart:data:["):len()) == 'lchart:data:[' then
        local cdata = split(call:sub(("lchart:data:["):len() + 1, -2), ",")
        local cx, cy, cdx, cdy = split(cdata[1], ":")[2], split(cdata[2], ":")[2], split(cdata[3], ":")[2], split(cdata[4], ":")[2]
        ui.addTextArea(18000, "<a href='event:close'>X: " .. cdx .. "<br>Y: " ..cdy .. "</a>", n, cx, cy, 80, 30, nil, nil, 0.5, true)
    elseif call == "close" then
        ui.removeTextArea(id)
    end
end

function LineChart.new(id, x, y, w, h)
	local self = setmetatable({ }, LineChart)
	self.id = id
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.showing = false
	self.joints = LineChart._joints
	LineChart._joints = LineChart._joints + 10000
    self.series = { }
	return self
end

--getters
function LineChart:getId() return self.id end
function LineChart:getDimension() return { x = self.x, y = self.y, w = self.w, h = self.h } end
function LineChart:getMinX() return self.minX end
function LineChart:getMaxX() return self.maxX end
function LineChart:getMinY() return self.minY end
function LineChart:getMaxY() return self.maxY end
function LineChart:getXRange() return self.xRange end
function LineChart:getYRange() return self.yRange end
function LineChart:getGraphColor() return { bgColor = self.bg or 0x324650, borderColor = self.border or 0x212F36 } end
function LineChart:getAlpha() return self.alpha or 0.5 end
function LineChart:isShowing() return self.showing end
function LineChart:getDataLength()
  local count = 0
  for _, s in next, self.series do
    count = count + s:getDataLength()
  end
  return count
end

function LineChart:show()
    self:refresh()
    local floor, ceil = math.floor, math.ceil
	--the graph plot
	ui.addTextArea(10000 + self.id, "", nil, self.x, self.y, self.w, self.h, self.bg, self.border, self:getAlpha(), true)
	--label of the origin
	ui.addTextArea(11000 + self.id, "<b>[" .. floor(self.minX) .. ", "  .. floor(self.minY) .. "]</b>", nil, self.x - 15, self.y + self.h + 5, 50, 50, nil, nil, 0, true)
	--label of the x max
	ui.addTextArea(12000 + self.id, "<b>" .. ceil(self.maxX) .. "</b>", nil, self.x + self.w + 10, self.y + self.h + 5, 50, 50, nil, nil, 0, true)
	--label of the y max
	ui.addTextArea(13000 + self.id, "<b>" .. ceil(self.maxY) .. "</b>", nil, self.x - 15, self.y - 10, 50, 50, nil, nil, 0, true)
	--label x median
	ui.addTextArea(14000 + self.id, "<b>" .. ceil((self.maxX + self.minX) / 2) .. "</b>", nil, self.x + self.w / 2, self.y + self.h + 5, 50, 50, nil, nil, 0, true)
	--label y median
	ui.addTextArea(15000 + self.id, "<br><br><b>" .. ceil((self.maxY + self.minY) / 2) .. "</b>", nil, self.x - 15, self.y + (self.h - self.y) / 2, 50, 50, nil, nil, 0, true)

	local joints = self.joints
	local xRatio = self.w / self.xRange
	local yRatio = self.h / self.yRange
  for id, series in next, self.series do
    for d = 1, series:getDataLength(), 1 do
        local x1 = floor(series:getDX()[d] * xRatio  + self.x - (self.minX * xRatio))
        local y1 = floor(invertY(series:getDY()[d] * yRatio) + self.y - invertY(self.h) + (self.minY * yRatio))
        local x2 = floor((series:getDX()[d+1]  or series:getDX()[d]) * xRatio + self.x - (self.minX * xRatio))
        local y2 = floor(invertY((series:getDY()[d+1] or series:getDY()[d]) * yRatio) + self.y - invertY(self.h) + (self.minY * yRatio))
		tfm.exec.addJoint(self.id + 6 + joints ,-1,-1,{
			type=0,
			point1= x1 .. ",".. y1,
			point2=  x2 .. "," .. y2,
			damping=0.2,
			line=series:getLineWidth(),
			color=series:getColor(),
			alpha=1,
			foreground=true
        })
        if self.showDPoints then
            ui.addTextArea(16000 + self.id + joints, "<font color='#" .. num2hex(series:getColor()) .."'><a href='event:lchart:data:[x:" .. x1 .. ",y:" .. y1 .. ",dx:" .. series:getDX()[d] .. ",dy:" .. series:getDY()[d] .. "]'>█</a></font>", nil, x1, y1, 10, 10, nil, nil, 0, true)
        end
		joints = joints + 1
	  end
  end

	self.showing = true
end


function LineChart:setGraphColor(bg, border)
	self.bg = bg
	self.border = border
end

function LineChart:setShowDataPoints(show)
    self.showDPoints = show
end

function LineChart:setAlpha(alpha)
	self.alpha = alpha
end

function LineChart:addSeries(series)
  table.insert(self.series, series)
  self:refresh()
end

function LineChart:removeSeries(name)
  for i=1, #self.series do
    if self.series[i]:getName() == name then
      table.remove(self.series, i)
      break
    end
  end
  self:refresh()
end

function LineChart:refresh()
  self.minX, self.minY, self.maxX, self.maxY = nil
  for k, s in next, self.series do
    self.minX = math.min(s:getMinX(), self.minX or s:getMinX())
    self.minY = math.min(s:getMinY(), self.minY or s:getMinY())
    self.maxX = math.max(s:getMaxX(), self.maxX or s:getMaxX())
    self.maxY = math.max(s:getMaxY(), self.maxY or s:getMaxY())
  end
    self.xRange = self.maxX - self.minX
    self.yRange = self.maxY - self.minY
end

function LineChart:resize(w, h)
	self.w = w
	self.h = h
end

function LineChart:move(x, y)
	self.x = x
	self.y = y
end

function LineChart:hide()
	for id = 10000, 17000, 1000 do
		ui.removeTextArea(id + self.id)
    end
    for id = self.id + 16000, self.joints, 1 do
        ui.removeTextArea(id + self.id)
    end
	for d = self.joints, self.joints + self:getDataLength() + 5, 1 do
		tfm.exec.removeJoint(d)
	end
	self.showing = false
end

function LineChart:showLabels(show)
  if show or show == nil then
  local labels = ""
    for _, series in next, self.series do
      labels = labels .. "<font color='#" .. num2hex(series:getColor()) .. "'> ▉<b> " .. series:getName() .. "</b></font><br>"
    end
    ui.addTextArea(16000 + self.id, labels, nil, self.x + self.w + 15, self.y, 80, 18 * #self.series, self:getGraphColor().bgColor, self:getGraphColor().borderColor, self:getAlpha(), true )
  else
    ui.removeTextArea(16000 + self.id, nil)
  end
end

function LineChart:displayGrids(show)
    if show or show == nil then
        local interval = self.h / 5
        for id, y in next, range(self.y + interval, self.y + self.h - interval, interval) do
            --Adds joints in the mid 4 positions of the graph
            tfm.exec.addJoint(self.id + id ,-1,-1,{
			    type=0,
			    point1= self.x .. "," .. y,
			    point2=  self.x + self.w .. "," .. y,
			    damping=0.2,
			    line=1,
			    alpha=1,
                foreground=true,
                color=0xFFFFFF
		    })
        end
        --Adds a joint near the median x value of the graph
        tfm.exec.addJoint(self.id + 5 ,-1,-1,{
			    type=0,
			    point1= self.x + self.w / 2 .. "," .. self.y,
			    point2=  self.x + self.w / 2 .. "," .. self.y + self.h,
			    damping=0.2,
			    line=2,
			    alpha=1,
                foreground=true,
                color=0xFFFFFF
        })
        --Adds a joint near the median y value of the graph
        tfm.exec.addJoint(self.id + 6 ,-1,-1,{
			    type=0,
			    point1= self.x  .. "," .. self.y + self.h / 2,
			    point2=  self.x + self.w .. "," .. self.y + self.h / 2,
			    damping=0.2,
			    line=2,
			    alpha=1,
                foreground=true,
                color=0xFFFFFF
		})
    end
end
