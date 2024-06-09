function HEX(hex)
    if #hex <= 6 then hex = hex.."FF" end
    local _,_,r,g,b,a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
    local color = {tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,tonumber(a,16)/255 or 255}
    return color
  end

local nativefs = require("nativefs")
local lovely = require("lovely")
Trance = assert(load(nativefs.read(lovely.mod_dir .. "/Trance/colors.lua")))()

--color injection
function Trance.set_globals(G)
    for k, v in pairs(Trance) do
        G.C[k] = v
    end
    G.C.UI_MULT = Trance.MULT
    G.C.UI_CHIPS = Trance.CHIPS
end

local iip = Game.init_item_prototypes
function Game:init_item_prototypes()
    iip(self)
    for k, v in pairs(Trance.BOSSES) do
        if G.P_BLINDS[k] and G.P_BLINDS[k].boss_colour then G.P_BLINDS[k].boss_colour = v end
    end
end