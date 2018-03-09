-- Created by Maxim Kartashev, Maja Kartasheva, 2017
--
-- This is free and unencumbered software released into the public domain.

map_data = {} -- a buffer for VoxelManip


local blocks = {
	dirt = { name = "default:dirt" },
	sand = { name = "default:sand" },
	stone = { name = "default:stone" },
	water = { name = "default:water_source" },
	air = { name = "default:air" },
	snow = { name = "default:snowblock" },
	grass = { name = "default:dirt_with_grass" },
	dirt_with_dry_grass = { name = "default:dirt_with_dry_grass" },
    }
    
local function get_lum(px)
    return math.sqrt(px.R*px.R + px.G*px.G + px.B*px.B)
end

----------------- By Maja ---------------------------------
local function is_grass(px)
    return px.G >= 200 and px.R < px.G and px.B < px.G
end

local function is_water(px)
    return px.G < px.B and px.R < px.B and px.B >= 100
end

local function get_height(px)
    if is_water(px) then
       return 3
    end

    local b = get_lum(px)
    return math.floor((255-b)/10) + 3
end

local function near_water(img, z, x)
    if z > 1 then
    	local p = img:getPixel(z-1, x)
    	if is_water(p) then
            return true
    	end
    end
    
    if z < img.width then
    	local p = img:getPixel(z+1, x)
    	if is_water(p) then
            return true
    	end
    end
    
    if x > 1 then
    	local p = img:getPixel(z, x-1)
    	if is_water(p) then
            return true
    	end
    end
    
    if x < img.height  then
    	local p = img:getPixel(z, x+1)
    	if is_water(p) then
            return true
    	end
    end
       
    return false         
end

local function is_inside_image(z, x)
    if imagemap.img then
	return ( x >= 1 and x <= imagemap.img.height and z >= 1 and z <= imagemap.img.width )
    end

    return false
end

local function pixel_to_block(x, y, z)
    p = imagemap.img:getPixel(z, x)
    h = get_height(p)
    
    if y > h then -- слишком высоко - ставим воздух
        b = blocks.air.name
    elseif is_water(p) then -- 
        b = blocks.water.name
    elseif is_grass(p) then
        if h == y then
            if near_water(imagemap.img, z, x) then
                b = blocks.sand.name
            else
                b = blocks.grass.name
            end
        else
            b = blocks.dirt.name
        end
    else 
        b = blocks.stone.name
    end
    return b
end

local function generate_blocks_for_area(area, emin, emax)
    local x0 = emin.x
    local y0 = emin.y
    local z0 = emin.z

    local x1 = emax.x
    local y1 = emax.y
    local z1 = emax.z

    print("------------------------------------")
    print("generate blocks for min ", x0, y0, z0)
    print("generate blocks for max ", x1, y1, z1)

    for x = x0, x1 do
        for z = z0, z1 do
            for y = y0, y1 do
                local vi = area:index(x, y, z) -- voxelmanip index
                if y <= 1 then 
                    map_data[vi] = minetest.get_content_id(blocks.stone.name)
                elseif is_inside_image(z, x) then
                    local b = pixel_to_block(x, y, z)
                    map_data[vi] = minetest.get_content_id(b)
                end
            end -- y
        end
    end

end

-----------------------------------------------------------

function imagemap.generate_landscape(area, minp, maxp)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

    vm:get_data(map_data)

    generate_blocks_for_area(area, emin, emax)

    vm:set_data(map_data)
    minetest.generate_ores(vm, emin, emax)
    vm:update_liquids()
    vm:write_to_map(true)
end


imagemap.img = nil

local function cleanup()
    math.randomseed(os.time())

    local pmin = {x = 0, y = 0, z = 0}
    local pmax = {x = imagemap.img.height, y = 1, z = imagemap.img.width}

    minetest.delete_area(pmin, pmax)
    minetest.emerge_area(pmin, pmax)
end

local function create_map_from_image(mapname)
    imagemap.img = pngImage(mapname)
    if imagemap.img == nil then
	return
    end

    cleanup()

    return true
end

function imagemap.create_map(name, param)
    local player = minetest.get_player_by_name(name)

    local mapname = imagemap.modpath.."/"..param

    local f = io.open(mapname, "r")
    if f == nil then 
	return false, "The file "..mapname.." does not exist"
    end
    io.close(f)

    create_map_from_image(mapname)

    return true, "Map was created from "..mapname
end

