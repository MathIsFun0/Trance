function HEX(hex)
    if #hex <= 6 then hex = hex.."FF" end
    local _,_,r,g,b,a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
    local color = {tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,tonumber(a,16)/255 or 255}
    return color
  end

local nativefs = require("nativefs")
local lovely = require("lovely")
Trance_config = {palette = "Base Game", font = "m6x11"}
baladir = lovely.mod_dir:sub(1, #lovely.mod_dir-5)
if nativefs.read(baladir .. "/config/Trance.lua") then
    Trance_config = load(nativefs.read(baladir .. "/config/Trance.lua"))()
end
function is_color(v)
    return type(v) == 'table' and #v == 4 and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" and type(v[4]) == "number"
end
function load_file_with_fallback(primary_path, fallback_path, reset_config)
    local success, result = pcall(function() return assert(load(nativefs.read(primary_path)))() end)
    if success then
        return result
    end
    reset_config()
    local fallback_success, fallback_result = pcall(function() return assert(load(nativefs.read(fallback_path)))() end)
    if fallback_success then
        return fallback_result
    end
end
Trance = assert(load(nativefs.read(lovely.mod_dir .. "/Trance/colors/Base Game.lua")))()
Trance_theme = load_file_with_fallback(
    lovely.mod_dir .. "/Trance/colors/" .. (Trance_config.palette or "Base Game") .. ".lua",
    lovely.mod_dir .. "/Trance/colors/Base Game.lua",
    function() Trance_config.palette = "Base Game" end
)
Trance_font = load_file_with_fallback(
    lovely.mod_dir .. "/Trance/fonts/" .. (Trance_config.font or "m6x11") .. ".lua",
    lovely.mod_dir .. "/Trance/fonts/m6x11.lua",
    function() Trance_config.font = "m6x11" end
)
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
local file = nativefs.read(lovely.mod_dir .. "/Trance/fonts/"..(Trance_config.font or "m6x11")..".ttf")
local gsl = Game.set_language
function Game:set_language()
    gsl(self)
    local file = nativefs.read(lovely.mod_dir .. "/Trance/fonts/"..(Trance_config.font or "m6x11")..".ttf")
    love.filesystem.write("temp-font.ttf", file)
    G.LANG.font.FONT = love.graphics.newFont("temp-font.ttf", G.TILESIZE * Trance_font.render_scale)
    for k, v in pairs(Trance_font) do
        G.LANG.font[k] = v
    end
    love.filesystem.remove("temp-font.ttf")
end


local files = nativefs.getDirectoryItems(lovely.mod_dir .. "/Trance/colors")
Trance_palettes = {}
for _, v in pairs(files) do
    if v:match("%.lua$") then
        Trance_palettes[#Trance_palettes+1] = v:gsub("%.lua$", "")
    end
end
files = nativefs.getDirectoryItems(lovely.mod_dir .. "/Trance/fonts")
Trance_fonts = {}
for _, v in pairs(files) do
    if v:match("%.lua$") then
        Trance_fonts[#Trance_fonts+1] = v:gsub("%.lua$", "")
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
    if love.filesystem.getInfo(baladir .. "/config", "directory") == nil then love.filesystem.createDirectory(baladir .. "/config") end
    nativefs.write(baladir .. "/config/Trance.lua", STR_PACK(Trance_config))
end
G.FUNCS.set_Trance_font = function(x)
    Trance_config.font = x.to_val
    
    Trance_font = assert(load(nativefs.read(lovely.mod_dir .. "/Trance/fonts/"..(Trance_config.font or "m6x11")..".lua")))()
    
    local file = nativefs.read(lovely.mod_dir .. "/Trance/fonts/"..Trance_config.font..".ttf")
    love.filesystem.write("temp-font.ttf", file)
    G.LANG.font.FONT = love.graphics.newFont("temp-font.ttf", G.TILESIZE * Trance_font.render_scale)
    for k, v in pairs(Trance_font) do
        G.LANG.font[k] = v
    end
    for k, v in pairs(G.I.UIBOX) do
        if v.recalculate and type(v.recalculate) == "function" then
            v:recalculate()
        end
    end
    love.filesystem.remove("temp-font.ttf")
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
local createOptionsRef = create_UIBox_options
  function create_UIBox_options()
  contents = createOptionsRef()
  local m = UIBox_button({
  minw = 5,
  button = "tranceMenu",
  label = {
  "Trance"
  },
  colour = G.C.BLUE
  })
  table.insert(contents.nodes[1].nodes[1].nodes[1].nodes, #contents.nodes[1].nodes[1].nodes[1].nodes + 1, m)
  return contents
end
G.FUNCS.tranceMenu = function(e)
    local tabs = create_tabs({
        snap_to_nav = true,
        tabs = {
            {
                label = "Trance",
                chosen = true,
                tab_definition_function = function()
                    local palette_idx = 0
                    for i = 1, #Trance_palettes do
                        if Trance_palettes[i] == Trance_config.palette then
                            palette_idx = i
                            break
                        end
                    end
                    local font_idx = 0
                    for i = 1, #Trance_fonts do
                        if Trance_fonts[i] == Trance_config.font then
                            font_idx = i
                            break
                        end
                    end
                    return {
                        n = G.UIT.ROOT,
                        config = {
                            emboss = 0.05,
                            minh = 6,
                            r = 0.1,
                            minw = 10,
                            align = "cm",
                            padding = 0.2,
                            colour = G.C.BLACK
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
                            create_option_cycle({
                                label = "Selected Font",
                                scale = 0.8,
                                w = 4,
                                options = Trance_fonts,
                                opt_callback = 'set_Trance_font',
                                current_option = font_idx,
                            }),
                        },
                    }
                end
            },
        }})
    G.FUNCS.overlay_menu{
            definition = create_UIBox_generic_options({
                back_func = "options",
                contents = {tabs}
            }),
        config = {offset = {x=0,y=10}}
    }
end