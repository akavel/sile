SILE.settings = {
  state = {},
  declarations = {},
  stateQueue = {},
  defaults = {},
  pushState = function()
    table.insert(SILE.settings.stateQueue, SILE.settings.state)
    SILE.settings.state = pl.tablex.copy(SILE.settings.state)
  end,
  popState = function()
    SILE.settings.state = table.remove(SILE.settings.stateQueue)
  end,
  declare = function(spec)
    if spec.name then
      SU.deprecated("'name' argument of SILE.settings.declare", "'parameter' argument of SILE.settings.declare", "0.10.10", "0.11.0")
      spec.parameter = spec.name
      spec.name = nil
    end
    SILE.settings.declarations[spec.parameter] = spec
    SILE.settings.defaults[spec.parameter] = spec.default
    SILE.settings.set(spec.parameter)
  end,
  reset = function()
    for k,_ in pairs(SILE.settings.state) do
      SILE.settings.set(k, SILE.settings.defaults[k])
    end
  end,
  get = function(parameter)
    if not SILE.settings.declarations[parameter] then
      SU.error("Undefined setting '"..parameter.."'")
    end
    if type(SILE.settings.state[parameter]) ~= "nil" then
      return SILE.settings.state[parameter]
    else
      return SILE.settings.defaults[parameter]
    end
  end,
  set = function(parameter, value)
    if not SILE.settings.declarations[parameter] then
      SU.error("Undefined setting '"..parameter.."'")
    end
    if type(value) == "nil" then
      SILE.settings.state[parameter] = nil
    else
      SILE.settings.state[parameter] = SU.cast(SILE.settings.declarations[parameter].type, value)
    end
  end,
  temporarily = function(func)
    SILE.settings.pushState()
    func()
    SILE.settings.popState()
  end,
  wrap = function() -- Returns a closure which applies the current state, later
    local clSettings = pl.tablex.copy(SILE.settings.state)
    return function(func)
      table.insert(SILE.settings.stateQueue, SILE.settings.state)
      SILE.settings.state = clSettings
      SILE.process(func)
      SILE.settings.popState()
    end
  end,
}

SILE.settings.declare({
  parameter = "document.parindent",
  type = "glue",
  default = SILE.nodefactory.glue("20pt"),
  help = "Glue at start of paragraph"
})

SILE.settings.declare({
  parameter = "document.baselineskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("1.2em plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  parameter = "document.lineskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("1pt"),
  help = "Leading"
})

SILE.settings.declare({
  parameter = "document.parskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("0pt plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  parameter = "document.spaceskip",
  type = "length or nil",
  default = nil,
  help = "The length of a space (if nil, then measured from the font)"
})

SILE.settings.declare({
  parameter = "document.rskip",
  type = "glue or nil",
  default = nil,
  help = "Skip to be added to right side of line"
})

SILE.settings.declare({
  parameter = "document.lskip",
  type = "glue or nil",
  default = nil,
  help = "Skip to be added to left side of line"
})

SILE.registerCommand("set", function(options, content)
  local parameter = SU.required(options, "parameter", "\\set command")
  local makedefault = SU.boolean(options.makedefault, false)
  local value = options.value
  if content and (type(content) == "function" or content[1]) then
    SILE.settings.temporarily(function()
      SILE.settings.set(parameter, value)
      SILE.process(content)
    end)
  else
    SILE.settings.set(parameter, value)
  end
  if makedefault then
    SILE.settings.declarations[parameter].default = value
    SILE.settings.defaults[parameter] = value
  end
end, "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)")
