-- resolution.lua

local loveVersion = love.getVersion() == 11
local getDPIScale = loveVersion and love.window.getDPIScale or love.window.getPixelScale
local updateWindowMode = loveVersion and love.window.updateMode or function(width, height, settings)
  local _, _, flags = love.window.getMode()
  for k, v in pairs(settings) do flags[k] = v end
  love.window.setMode(width, height, flags)
end

local resolution = {
  
  defaultSettings = {
    fullscreen = false,
    resizable = false,
    pixelPerfect = false,
    -- highDPI = true,
    useCanvas = true, 
    useStencil = true
  }
  
}
setmetatable(resolution, resolution)

function resolution:applySettings(settings)
  for k, v in pairs(settings) do
    self["_" .. k] = v
  end
end

function resolution:resetSettings() return self:applySettings(self.defaultSettings) end

function resolution:setupScreen(gameWidth, gameHeight, renderWidth, renderHeight, settings)

  settings = settings or {}

  self._gameWidth, self._gameHeight = gameWidth, gameHeight
  self._renderWidth, self._renderHeight = renderWidth, renderHeight

  self:applySettings(self.defaultSettings) -- set defaults first
  self:applySettings(settings) -- then fill with custom settings
  
  updateWindowMode(self._renderWidth, self._renderHeight, {
    fullscreen = self._fullscreen,
    resizable = self._resizable,
    highDPI = self._highDPI
  })

  self:initValues()

  if self._useCanvas then
    self:setupCanvas({ "default" }) -- setup canvas
  end

  self._borderColor = {0, 0, 0}

  self._drawFuncs = {
    ["start"] = self.start,
    ["end"] = self.finish
  }

  return self
end

function resolution:setupCanvas(canvases)
  table.insert(canvases, { name = "_render", private = true }) -- final render

  self._useCanvas = true
  self.canvases = {}

  for i = 1, #canvases do
    resolution:addCanvas(canvases[i])
  end

  return self
end

function resolution:addCanvas(params)
  table.insert(self.canvases, {
    name = params.name,
    private = params.private,
    shader = params.shader,
    canvas = love.graphics.newCanvas(self._gameWidth, self._gameHeight),
    stencil = params.stencil or self._useStencil
  })
end

function resolution:setCanvas(name)
  if not self._useCanvas then return true end
  local canvasTable = resolution:getCanvasTable(name)
  return love.graphics.setCanvas({ canvasTable.canvas, stencil = canvasTable.stencil })
end

function resolution:getCanvasTable(name)
  for i = 1, #self.canvases do
    if self.canvases[i].name == name then
      return self.canvases[i]
    end
  end
end

function resolution:setShader(name, shader)
  if not shader then
    self:getCanvasTable("_render").shader = name
  else
    self:getCanvasTable(name).shader = shader
  end
end

function resolution:initValues()
  self._pixelScale = (not loveVersion and self._highDPI) and getDPIScale() or 1
  
  self._scale = {
    x = self._renderWidth / self._gameWidth * self._pixelScale,
    y = self._renderHeight / self._gameHeight * self._pixelScale
  }
  
  if self._stretched then -- if stretched, no need to apply offset
    self._offset = {x = 0, y = 0}
  else
    local scale = math.min(self._scale.x, self._scale.y)
    if self._pixelPerfect then scale = math.floor(scale) end
    
    self._offset = {x = (self._scale.x - scale) * (self._gameWidth / 2), y = (self._scale.y - scale) * (self._gameHeight / 2)}
    self._scale.x, self._scale.y = scale, scale -- apply same scale to X and Y
  end
  
  self._gameWidthScaled = self._renderWidth * self._pixelScale - self._offset.x * 2
  self._gameHeightScaled = self._renderHeight * self._pixelScale - self._offset.y * 2
end

function resolution:apply(operation, shader)
  self._drawFuncs[operation](self, shader)
end

function resolution:start()
  if self._useCanvas then
    love.graphics.push()
    love.graphics.setCanvas({ self.canvases[1].canvas, stencil = self.canvases[1].stencil })

  else
    love.graphics.translate(self._offset.x, self._offset.y)
    love.graphics.setScissor(self._offset.x, self._offset.y, self._gameWidth * self._scale.x, self._gameHeight * self._scale.y)
    love.graphics.push()
    love.graphics.scale(self._scale.x, self._scale.y)
  end
end

function resolution:applyShaders(canvas, shaders)
  local _shader = love.graphics.getShader()
  if #shaders <= 1 then
    love.graphics.setShader(shaders[1])
    love.graphics.draw(canvas)
  else
    local _canvas = love.graphics.getCanvas()

    local _tmp = resolution:getCanvasTable("_tmp")
    if not _tmp then -- create temp canvas only if needed
      self:addCanvas({ name = "_tmp", private = true, shader = nil })
      _tmp = resolution:getCanvasTable("_tmp")
    end

    love.graphics.push()
    love.graphics.origin()
    local outputCanvas
    for i = 1, #shaders do
      local inputCanvas = i % 2 == 1 and canvas or _tmp.canvas
      outputCanvas = i % 2 == 0 and canvas or _tmp.canvas
      love.graphics.setCanvas(outputCanvas)
      love.graphics.clear()
      love.graphics.setShader(shaders[i])
      love.graphics.draw(inputCanvas)
      love.graphics.setCanvas(inputCanvas)
    end
    love.graphics.pop()

    love.graphics.setCanvas(_canvas)
    love.graphics.draw(outputCanvas)
  end
  love.graphics.setShader(_shader)
end

function resolution:finish(shader)
  love.graphics.setBackgroundColor(unpack(self._borderColor))
  if self._useCanvas then
    local _render = resolution:getCanvasTable("_render")

    love.graphics.pop()

    local white = loveVersion and 1 or 255
    love.graphics.setColor(white, white, white)

    -- draw canvas
    love.graphics.setCanvas(_render.canvas)
    for i = 1, #self.canvases do -- do not draw _render yet
      local _table = self.canvases[i]
      if not _table.private then
        local _canvas = _table.canvas
        local _shader = _table.shader
        self:applyShaders(_canvas, type(_shader) == "table" and _shader or { _shader })
      end
    end
    love.graphics.setCanvas()
    
    -- draw render
    love.graphics.translate(self._offset.x, self._offset.y)
    local shader = shader or _render.shader
    love.graphics.push()
    love.graphics.scale(self._scale.x, self._scale.y)
    resolution:applyShaders(_render.canvas, type(shader) == "table" and shader or { shader })
    love.graphics.pop()

    -- clear canvas
    for i = 1, #self.canvases do
      love.graphics.setCanvas(self.canvases[i].canvas)
      love.graphics.clear()
    end

    love.graphics.setCanvas()
    love.graphics.setShader()
  else
    love.graphics.pop()
    love.graphics.setScissor()
  end
end

function resolution:setBorderColor(color, g, b)
  self._borderColor = g and {color, g, b} or color
end

function resolution:toGame(x, y)
  x, y = x - self._offset.x, y - self._offset.y
  local normalX, normalY = x / self._gameWidthScaled, y / self._gameHeightScaled
  
  x = (x >= 0 and x <= self._gameWidth * self._scale.x) and normalX * self._gameWidth or nil
  y = (y >= 0 and y <= self._gameHeight * self._scale.y) and normalY * self._gameHeight or nil
  
  return x, y
end

-- doesn't work - TODO
function resolution:toReal(x, y)
  return x + self._offset.x, y + self._offset.y
end

function resolution:toggleFullscreen(winWidth, winHeight)
  self._fullscreen = not self._fullscreen
  local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
  
  if self._fullscreen then -- save windowed dimensions for later
    self._windowedWidth, self._windowedHeight = self._renderWidth, self._renderHeight
  elseif not self._windowedWidth or not self._windowedHeight then
    self._windowedWidth, self._windowedHeight = desktopWidth * .5, desktopHeight * .5
  end
  
  self._renderWidth = self._fullscreen and desktopWidth or winWidth or self._windowedWidth
  self._renderHeight = self._fullscreen and desktopHeight or winHeight or self._windowedHeight
  
  self:initValues()
  
  love.window.setFullscreen(self._fullscreen, "desktop")
  if not self._fullscreen and (winWidth or winHeight) then
    updateWindowMode(self._renderWidth, self._renderHeight) -- set window dimensions
  end
end

function resolution:resize(width, height)
  if self._highDPI then width, height = width / self._pixelScale, height / self._pixelScale end
  self._renderWidth = width
  self._renderHeight = height
  self:initValues()
end

function resolution:getWidth() return self._gameWidth end
function resolution:getHeight() return self._gameHeight end
function resolution:getDimensions() return self._gameWidth, self._gameHeight end

return resolution
