
plain = SILE.baseClass { id = "plain" }

plain.options.direction = function (g)
  if g then plain.pageTemplate.frames["content"].direction = g end
end

plain:declareFrame("content",     {left = "5%",  right = "95%",  top = "5%",  bottom = "90%" });
plain:declareFrame("folio", {left = "5%",  right = "95%",  top = "92%", bottom = "97%" });

plain.pageTemplate.firstContentFrame = plain.pageTemplate.frames["content"];
plain:loadPackage("folio");

plain.endPage = function(self)
  plain:outputFolio()
  return SILE.baseClass.endPage(self)
end

local options = {}
plain.declareOption = function (self, name, default)
  options[name] = default
  self.options[name] = function (g)
    if g then options[name] = g end
    return options[name]
  end
end

SILE.registerCommand("noindent", function ( options, content )
  SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
  SILE.process(content)
end, "Do not add an indent to the start of this paragraph")

SILE.registerCommand("indent", function ( options, content )
  SILE.settings.set("current.parindent", SILE.settings.get("document.parindent"))
  SILE.process(content)
end, "Do add an indent to the start of this paragraph, even if previously told otherwise")

local skips = { small= "3pt plus 1pt minus 1pt",
      med = "6pt plus 2pt minus 2pt",
      big = "12pt plus 4pt minus 4pt"}

for k,v in pairs(skips) do
  SILE.settings.declare({
    name = "plain."..k.."skipamount", type="VGlue", default = SILE.nodefactory.newVglue(v),
    help = "The amount of a \\"..k.."skip"})
  SILE.registerCommand(k.."skip", function ( options, content )
    SILE.typesetter:leaveHmode();
    SILE.typesetter:pushExplicitVglue(SILE.settings.get("plain."..k.."skipamount"))
  end, "Skip vertically by a "..k.." amount")
end

SILE.registerCommand("hfill", function(o,c) SILE.typesetter:pushGlue(SILE.nodefactory.hfillGlue) end, "Add a huge horizontal glue")
SILE.registerCommand("vfill", function(o,c)
  SILE.typesetter:leaveHmode()
  SILE.typesetter:pushExplicitVglue(SILE.nodefactory.vfillGlue) end, "Add huge vertical glue")
SILE.registerCommand("hss", function(o,c)
  SILE.typesetter:initline()
  SILE.typesetter:pushGlue(SILE.nodefactory.hssGlue)
  table.insert(SILE.typesetter.state.nodes, SILE.nodefactory.zeroHbox)
end, "Add glue which stretches and shrinks horizontally (good for centering)")
SILE.registerCommand("vss", function(o,c) SILE.typesetter:pushVglue(SILE.nodefactory.vssGlue) end, "Add glue which stretches and shrinks vertically")

plain.registerCommands = function()
  SILE.baseClass.registerCommands()
  SILE.doTexlike([[\define[command=thinspace]{\glue[width=0.16667em]}%
\define[command=negthinspace]{\glue[width=-0.16667em]}%
\define[command=enspace]{\glue[width=0.5em]}%
\define[command=relax]{}%
\define[command=enskip]{\enspace}%
\define[command=quad]{\glue[width=1em]}%
\define[command=qquad]{\glue[width=2em]}%
\define[command=slash]{/\penalty[penalty=50]}%
\define[command=break]{\penalty[penalty=-10000]}%
\define[command=framebreak]{\break}%
\define[command=pagebreak]{\penalty[penalty=-20000]}%
\define[command=nobreak]{\penalty[penalty=10000]}%
\define[command=novbreak]{\penalty[penalty=10000,vertical=1]}%
\define[command=allowbreak]{\penalty[penalty=0]}%
\define[command=filbreak]{\vfill\penalty[penalty=-200]}%
\define[command=goodbreak]{\penalty[penalty=-500]}%
\define[command=eject]{\par\break}%
\define[command=supereject]{\par\penalty[penalty=-20000]}%
\define[command=justified]{\set[parameter=document.rskip]\set[parameter=document.spaceskip]}%
\define[command=rightalign]{\raggedleft{\process\par}}%
\define[command=em]{\font[style=italic]{\process}}%
\define[command=nohyphenation]{\font[language=xx]{\process}}%
\define[command=raggedright]{\ragged[right=true]{\process}}%
\define[command=raggedleft]{\ragged[left=true]{\process}}%
\define[command=center]{\ragged[left=true,right=true]{\process}}%
\define[command=quote]{\smallskip\par\set[parameter=document.lskip,value=2.5em]\set[parameter=document.rskip,value=2.5em]\font[size=0.8em]{\noindent\process}\par\set[parameter=document.lskip]\set[parameter="document.rskip"]\smallskip}%
\define[command=listitem]{\medskip{}• \process\medskip}%
]])
end

SILE.registerCommand("{", function (o,c) SILE.typesetter:typeset("{") end)
SILE.registerCommand("}", function (o,c) SILE.typesetter:typeset("}") end)
SILE.registerCommand("%", function (o,c) SILE.typesetter:typeset("%") end)
SILE.registerCommand("\\", function (o,c) SILE.typesetter:typeset("\\") end)

SILE.registerCommand("ragged", function(options,c)
  SILE.settings.temporarily(function()
    if options.left then SILE.settings.set("document.lskip", SILE.nodefactory.hfillGlue) end
    if options.right then SILE.settings.set("document.rskip", SILE.nodefactory.hfillGlue) end
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
    SILE.settings.set("document.spaceskip", SILE.length.new({ length = SILE.shaper:measureDim(" ") }))
    SILE.process(c)
    SILE.call("par")
  end)
end)
SILE.registerCommand("hbox", function (o,c)
  local index = #(SILE.typesetter.state.nodes)+1
  local recentContribution = {}
  SILE.process(c)
  local l = SILE.length.new()
  local h,d = 0,0
  for i = index, #(SILE.typesetter.state.nodes) do
    local node = SILE.typesetter.state.nodes[i]
    if node:isUnshaped() then
      local s = node:shape()
      for i = 1, #s do
        recentContribution[#recentContribution+1] = s[i]
        l = l + s[i]:lineContribution()
      end
    else
      recentContribution[#recentContribution+1] = node
      l = l + node:lineContribution()
    end
    h = node.height > h and node.height or h
    d = node.depth > d and node.depth or d
    SILE.typesetter.state.nodes[i] = nil
  end
  local hbox = SILE.nodefactory.newHbox({
    height = h,
    width = l,
    depth = d,
    value = recentContribution,
    outputYourself = function (self, typesetter, line)
      -- Yuck!
      if typesetter.frame:writingDirection() == "RTL" then
        typesetter.frame:advanceWritingDirection(self:scaledWidth(line))
      end
      local X = typesetter.frame.state.cursorX
      SILE.outputter.moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
      for i = 1, #(self.value) do local node = self.value[i]
        node:outputYourself(typesetter, line)
      end
      typesetter.frame.state.cursorX = X
      if typesetter.frame:writingDirection() ~= "RTL" then
        typesetter.frame:advanceWritingDirection(self:scaledWidth(line))
      end
    end
  })
  table.insert(SILE.typesetter.state.nodes, hbox)
  return hbox
end, "Compiles all the enclosed horizontal-mode material into a single hbox")

SILE.registerCommand("vbox", function (options,c)
  local vbox
  SILE.settings.temporarily(function()
    if (options.width) then SILE.settings.set("typesetter.breakwidth", options.width) end
    SILE.typesetter:pushState()
    SILE.process(c)
    SILE.typesetter:leaveHmode(1)
    vbox = SILE.pagebuilder.collateVboxes(SILE.typesetter.state.outputQueue)
    SILE.typesetter:popState()
  end)
  return vbox
end, "Compiles all the enclosed horizontal-mode material into a single hbox")

SILE.require("packages/bidi")
return plain;
