local minidoc = require("mini.doc")

if _G.MiniDoc == nil then
  minidoc.setup()
end

MiniDoc.generate({ "lua/textobject-hud/init.lua", "lua/textobject-hud/config.lua" }, "doc/textobject-hud.txt")
