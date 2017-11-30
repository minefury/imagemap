-- Created by Maxim Kartashev, Maja Kartasheva, 2017
--
-- This is free and unencumbered software released into the public domain.

function imagemap.generate_floor(minp, maxp)
    -- this will provide a stone floor at the level zero and below
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    local data = vm:get_data()

    local x0 = minp.x
    local y0 = minp.y
    local z0 = minp.z

    local x1 = maxp.x
    local y1 = maxp.y
    local z1 = maxp.z

    -- only interested in voxels that contain a plane with y == 0
    if y0 > 0 or y1 < 0 then
	return
    end

    for x=x0,x1 do
	for z=z0,z1 do
	    for y=-10,0 do
		local vi = area:index(x, y, z) -- voxelmanip index
		data[vi] = minetest.get_content_id("default:stone")
	    end
	end
    end

    vm:set_data(data)
    minetest.generate_ores(vm, minp, maxp)
    vm:calc_lighting()
    vm:write_to_map(data)
    vm:update_liquids()
end

local blocks = {
	dirt = { name = "default:dirt" },
	sand = { name = "default:sand" },
	stone = { name = "default:stone" },
	water = { name = "default:water_source" },
	air = { name = "default:air" },
	snow = { name = "default:snowblock" },
	grass = { name = "default:dirt_with_grass"},
	dirt_with_dry_grass = { name = "default:dirt_with_dry_grass"},
    }
    
local function get_lum(px)
    return math.sqrt(px.R*px.R + px.G*px.G + px.B*px.B)
end

----------------- By Maja ---------------------------------
local function clean()
    math.randomseed(os.time())

    for x = 0, 100 do
        for z = 0, 100 do
            for y = 0, 30 do
                local pos = {x=x, y=y, z=z}
                minetest.remove_node(pos)
            end
        end
    end
end

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

local function generate_blocks(img)
    clean()
    
    for x = 1, img.height do
        for z = 1, img.width do
            p = img:getPixel(z, x)
	    h = get_height(p)

	    for y = 1, h do
	        pos = {x = x, y = y, z = z}
                minetest.set_node(pos, blocks.dirt)   
	    end
	    
            if is_water(p) then
                b = blocks.water
            elseif is_grass(p) then
                b = blocks.grass
            else
                b = blocks.stone
            end
            
            if not is_water(p) and near_water(img, z, x) then
                b = blocks.sand
            end
            
            pos = {x = x, y = h+1, z = z}
            minetest.set_node(pos, b)
        end
    end
end
-----------------------------------------------------------

local function create_map_from_image(mapname)
    local img = pngImage(mapname)
    if img == nil then
	return
    end

    generate_blocks(img)

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

