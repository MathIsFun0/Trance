function HEX(hex)
    if #hex <= 6 then hex = hex.."FF" end
    local _,_,r,g,b,a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
    local color = {tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,tonumber(a,16)/255 or 255}
    return color
  end

local nativefs = require("nativefs")
local lovely = require("lovely")
Trance_config = {palette = "Base Game"}
if nativefs.read(lovely.mod_dir .. "/Trance/config.lua") then
    Trance_config = load(nativefs.read(lovely.mod_dir .. "/Trance/config.lua"))()
end
function is_color(v)
    return type(v) == 'table' and #v == 4 and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" and type(v[4]) == "number"
end
Trance = assert(load(nativefs.read(lovely.mod_dir .. "/Trance/colors/Base Game.lua")))()
Trance_theme = assert(load(nativefs.read(lovely.mod_dir .. "/Trance/colors/"..Trance_config.palette..".lua")))()
for k, v in pairs(Trance_theme) do
    if is_color(v) then 
        Trance[k] = v
    elseif type(v) == 'table' then
        for _k, _v in pairs(Trance_theme[k]) do
            if is_color(_v) then 
                Trance[k][_k] = _v
            end
        end
    end
end

local files = nativefs.getDirectoryItems(lovely.mod_dir .. "/Trance/colors")
Trance_palettes = {}
for _, v in pairs(files) do
    if v:match("%.lua$") then
        Trance_palettes[#Trance_palettes+1] = v:gsub("%.lua$", "")
    end
end

--color injection
function Trance_set_globals(G, dt)
    for k, v in pairs(Trance) do
        if is_color(v) then 
            if is_color(G.C[k]) then ease_colour(G.C[k],v,dt) else G.C[k] = v end
        elseif type(v) == 'table' then
            if not G.C[k] then G.C[k] = {} end
            for _k, _v in pairs(Trance[k]) do
                if is_color(_v) then 
                    if is_color(G.C[k][_k]) then ease_colour(G.C[k][_k],_v,dt) else G.C[k][_k] = _v end
                end
            end
        end
    end
    if Trance.MULT then ease_colour(G.C.UI_MULT,Trance.MULT,dt) end
    if Trance.CHIPS then ease_colour(G.C.UI_CHIPS,Trance.CHIPS,dt) end
    if G.P_BLINDS then
        for k, v in pairs(Trance.BOSSES) do
            if G.P_BLINDS[k] and G.P_BLINDS[k].boss_colour then G.P_BLINDS[k].boss_colour = v end
        end
    end
end

local iip = Game.init_item_prototypes
function Game:init_item_prototypes()
    iip(self)
    for k, v in pairs(Trance.BOSSES) do
        if G.P_BLINDS[k] and G.P_BLINDS[k].boss_colour then G.P_BLINDS[k].boss_colour = v end
    end
end

G_FUNCS_options_ref = G.FUNCS.options
G.FUNCS.options = function(e)
    G_FUNCS_options_ref(e)
    nativefs.write(lovely.mod_dir .. "/Trance/config.lua", STR_PACK(Trance_config))
end
local ct = create_tabs
function create_tabs(args)
    if args and args.tab_h == 7.05 then
        local palette_idx = 0
        for i = 1, #Trance_palettes do
            if Trance_palettes[i] == Trance_config.palette then
                palette_idx = i
                break
            end
        end
        args.tabs[#args.tabs + 1] = {
            label = 'Trance',
            tab_definition_function = (function()
                return {
                    n = G.UIT.ROOT,
                    config = {
                        align = "cm",
                        padding = 0.05,
                        colour = G.C.CLEAR
                    },
                    nodes = {
                        create_option_cycle({
                            label = "Selected Palette",
                            scale = 0.8,
                            w = 4,
                            options = Trance_palettes,
                            opt_callback = 'set_Trance_palette',
                            current_option = palette_idx,
                        }),
                    },
                }
            end),
            tab_definition_function_args = 'Trance'
        }
    end
    return ct(args)
end
G.FUNCS.set_Trance_palette = function(x)
    Trance_config.palette = x.to_val
    
    Trance = assert(load(nativefs.read(lovely.mod_dir .. "/Trance/colors/Base Game.lua")))()
    Trance_theme = assert(load(nativefs.read(lovely.mod_dir .. "/Trance/colors/"..Trance_config.palette..".lua")))()
    for k, v in pairs(Trance_theme) do
        if is_color(v) then 
            Trance[k] = v
        elseif type(v) == 'table' then
            for _k, _v in pairs(Trance_theme[k]) do
                if is_color(_v) then 
                    Trance[k][_k] = _v
                end
            end
        end
    end
    Trance_set_globals(G, 1)
end