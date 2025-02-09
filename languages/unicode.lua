require("char-def")
local chardata  = characters.data

SILE.nodeMakers.base = std.object {
  makeToken = function(self)
    if #self.contents>0 then
      coroutine.yield(SILE.shaper:formNnode(self.contents, self.token, self.options))
      self.contents = {} ; self.token = "" ; self.lastnode = "nnode"
    end
  end,
  addToken = function (self, char, item)
    self.token = self.token .. char
    self.contents[#self.contents+1] = item
  end,
  makeGlue = function(self)
    if self.lastnode ~= "glue" then
      coroutine.yield(SILE.shaper:makeSpaceNode(self.options))
    end
    self.lastnode = "glue"
  end,
  makePenalty = function (self,p)
    coroutine.yield( SILE.nodefactory.newPenalty({ penalty = p or 0 }) )
    self.lastnode = "penalty"
  end,
  init = function (self)
    self.contents = {}
    self.token = ""
    self.lastnode = ""
  end,
  iterator = function (self,items)
    SU.error("Abstract function nodemaker:iterator called",1)
  end
}

SILE.nodeMakers.unicode = SILE.nodeMakers.base {
  iterator = function (self, items)
    self:init()
    return coroutine.wrap(function()
      for i = 1,#items do item = items[i]
        local char = items[i].text
        local cp = SU.codepoint(char)
        local thistype = chardata[cp] and chardata[cp].linebreak
        if chardata[cp] and thistype == "sp" then
          self:makeToken()
          self:makeGlue()
        elseif chardata[cp] and (thistype == "ba" or  thistype == "zw") then
          self:addToken(char,item)
          self:makeToken()
          self:makePenalty(0)
        elseif lasttype and (thistype ~= lasttype and thistype ~= "cm") then
          self:makeToken()
          self:addToken(char,item)
        else
          self:addToken(char,item)
        end
        if thistype ~= "cm" then lasttype = chardata[cp] and chardata[cp].linebreak end
      end
      self:makeToken()
    end)
  end
}

pcall( function () icu = require("justenoughicu") end)
if icu then
  SILE.tokenizers.unicode = function(text)
    local chunks = {icu.breakpoints(text)}
    return coroutine.wrap(function()
      for i = 2,(#chunks) do local chunk = chunks[i]
        if chunk.token:match("^%s+$") then
          coroutine.yield({ separator = chunk.token })
        elseif chunk.type == "line" then
          if #(chunk.token) > 0 then coroutine.yield({ string = chunk.token }) end
          coroutine.yield({ node = SILE.nodefactory.newPenalty({
            penalty = (chunk.subtype == "soft" and 0 or -1000) })
          })
        else
          coroutine.yield({ string = chunk.token })
        end
      end
    end)
  end
else
end