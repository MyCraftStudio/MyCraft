--Minetest
--Copyright (C) 2014 sapier
--
--This program is free software; you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation; either version 3.0 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License along
--with this program; if not, write to the Free Software Foundation, Inc.,
--51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

local function create_world_formspec(dialogdata)

	--mm_texture.clear("header")
    --mm_texture.clear("footer")
    --minetest.set_clouds(false)
    --minetest.set_background("background",minetest.formspec_escape(mm_texture.basetexturedir)..'background.jpg')
    --minetest.set_background("header",minetest.formspec_escape(mm_texture.basetexturedir)..'header.png')


	local mapgens = core.get_mapgen_names()

	local current_seed = core.setting_get("fixed_map_seed") or ""
	local current_mg   = core.setting_get("mg_name")

	local mglist = ""
	local selindex = 1
	local i = 1
	for k,v in pairs(mapgens) do
		if current_mg == v then
			selindex = i
		end
		i = i + 1
		mglist = mglist .. v .. ","
	end
	mglist = mglist:sub(1, -2)
	
	local gameid = core.setting_get("menu_last_game")
	
	local game, gameidx = nil , 0
	if gameid ~= nil then
		game, gameidx = gamemgr.find_by_gameid(gameid)
		
		if gameidx == nil then
			gameidx = 0
		end
	end

	current_seed = core.formspec_escape(current_seed)
	local retval =
		"size[12,3]" ..
		"label[2,0;" .. fgettext("World name") .. "]"..
		"field[4.5,0.4;6,0.5;te_world_name;;]" ..

		"label[2,1;" .. fgettext("Seed") .. "]"..
		"field[4.5,1.4;6,0.5;te_seed;;".. current_seed .. "]" ..

		--"label[2,2;" .. fgettext("Mapgen") .. "]"..
		--"dropdown[4.2,2;6.3;dd_mapgen;" .. mglist .. ";" .. selindex .. "]" ..

		--"label[2,3;" .. fgettext("Game") .. "]"..
		"dropdown[6000.2,6;6.3;games;" .. gamemgr.gamelist() ..
                ";1]" ..

		"button[5,2.6;2.6,0.5;world_create_confirm;" .. fgettext("Create") .. "]" ..
		"button[7.5,2.6;2.8,0.5;world_create_cancel;" .. fgettext("Cancel") .. "]"
		
	if #gamemgr.games == 0 then
		retval = retval .. "box[2,4;8,1;#ff8800]label[2.25,4;" ..
				fgettext("You have no subgames installed.") .. "]label[2.25,4.4;" ..
				fgettext("Download one from minetest.net") .. "]"
	elseif #gamemgr.games == 1 and gamemgr.games[1].id == "minimal" then
		retval = retval .. "box[1.75,4;8.7,1;#ff8800]label[2,4;" ..
				fgettext("Warning: The minimal development test is meant for developers.") .. "]label[2,4.4;" ..
				fgettext("Download a subgame, such as minetest_game, from minetest.net") .. "]"
	end

	return retval

end

local function create_world_buttonhandler(this, fields)

	if fields["world_create_cancel"] then
                this:delete()
                return true
        end

	if fields["world_create_confirm"] or
		fields["key_enter"] then

		local worldname = fields["te_world_name"]
		local gameindex
                for i,item in ipairs(gamemgr.games) do
                    if item.name == fields["games"] then
                       gameindex = i
                    end
                end

		if gameindex ~= nil and
			worldname ~= "" then

			local message = nil

			core.setting_set("fixed_map_seed", fields["te_seed"])

			if not menudata.worldlist:uid_exists_raw(worldname) then
				core.setting_set("mg_name","valleys")
				message = core.create_world(worldname,gameindex)
			else
				message = fgettext("A world named \"$1\" already exists", worldname)
			end

			if message ~= nil then
				gamedata.errormessage = message
			else
				core.setting_set("menu_last_game",gamemgr.games[gameindex].id)
				if this.data.update_worldlist_filter then
					menudata.worldlist:set_filtercriteria(gamemgr.games[gameindex].id)
					--mm_texture.update("singleplayer", gamemgr.games[gameindex].id)
				end
				menudata.worldlist:refresh()
				core.setting_set("mainmenu_last_selected_world",
									menudata.worldlist:raw_index_by_uid(worldname))
			end
		else
			gamedata.errormessage =
				fgettext("No worldname given or no game selected")
		end
		this:delete()
		return true
	end

	if fields["games"] then
		return true
	end


	return false
end


function create_create_world_dlg(update_worldlistfilter)
	local retval = dialog_create("sp_create_world",
					create_world_formspec,
					create_world_buttonhandler,
					nil)
	retval.update_worldlist_filter = update_worldlistfilter
	
	return retval
end
