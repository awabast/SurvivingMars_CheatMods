-- See LICENSE for terms

local table_find = table.find
local table_clear = table.clear
local table_iclear = table.iclear
local table_sort = table.sort
local type, pairs, next, print = type, pairs, next, print
local tostring, tonumber, rawget = tostring, tonumber, rawget
local AveragePoint2D = AveragePoint2D
local IsValid = IsValid
local IsKindOf = IsKindOf
local IsValidEntity = IsValidEntity
local Sleep = Sleep
local WaitMsg = WaitMsg
local table_remove = table.remove
local IsPoint = IsPoint
local IsBox = IsBox
local DoneObject = DoneObject

local debug_getinfo, debug_getlocal, debug_getupvalue, debug_gethook

local MsgPopup = ChoGGi.ComFuncs.MsgPopup
local RetName = ChoGGi.ComFuncs.RetName
local Translate = ChoGGi.ComFuncs.Translate
local TableConcat = ChoGGi.ComFuncs.TableConcat
local RandomColourLimited = ChoGGi.ComFuncs.RandomColourLimited
local SaveOrigFunc = ChoGGi.ComFuncs.SaveOrigFunc
local IsValidXWin = ChoGGi.ComFuncs.IsValidXWin
local PlacePolyline = ChoGGi.ComFuncs.PlacePolyline
local InvalidPos = ChoGGi.Consts.InvalidPos
local Strings = ChoGGi.Strings
local blacklist = ChoGGi.blacklist
local testing = ChoGGi.testing

local debug = blacklist and false or debug
if debug then
	debug_getinfo = debug.getinfo
	debug_getlocal = debug.getlocal
	debug_getupvalue = debug.getupvalue
	debug_gethook = debug.gethook
end

-- Ease of access to _G for my lib mod (when HelperMod is installed for ECM)
function ChoGGi.ComFuncs.RetUnrestricedG()
	return _G
end

local function SetCheatsMenuPos(pos)
	pos = pos or ChoGGi.UserSettings.KeepCheatsMenuPosition
	if pos then
		XShortcutsTarget:SetPos(pos)
	else
		XShortcutsTarget:SetPos(GetSafeMargins():min())
	end
end
ChoGGi.ComFuncs.SetCheatsMenuPos = SetCheatsMenuPos

function ChoGGi.ComFuncs.DraggableCheatsMenu(enable)
	local XShortcutsTarget = XShortcutsTarget

	-- always add the move control so we can re-pos for xbox
	if not XShortcutsTarget.idMoveControl then
		-- add move control to menu
		XShortcutsTarget.idMoveControl = g_Classes.XMoveControl:new({
			Id = "idMoveControl",
			MinHeight = 6,
			VAlign = "top",
		}, XShortcutsTarget)
	end

	if enable then
		-- add a bit of spacing above menu
		XShortcutsTarget.idMenuBar:SetPadding(box(0, 6, 0, 0))

		-- move the move control to the padding space we created above
		CreateRealTimeThread(function()
			WaitMsg("OnRender")
			-- needs a delay (cause we added the control?)
			local height = XShortcutsTarget.idToolbar.box:maxy() * -1
			XShortcutsTarget.idMoveControl:SetMargins(box(0, height, 0, 0))
		end)
	else
		-- remove my padding
		XShortcutsTarget.idMenuBar:SetPadding(box(0, 0, 0, 0))
		-- restore to original pos
		SetCheatsMenuPos()
	end

end

function ChoGGi.ComFuncs.SetCommanderBonuses(name)
	local comm = GetCommanderProfile(g_CurrentMissionParams.idCommanderProfile)
	if not comm then
		return
	end
	local c = #comm

	local comms = ChoGGi.Tables.Commanders[name] or ""
	for i = 1, #comms do
		c = c + 1
		comm[c] = comms[i]
	end
end

function ChoGGi.ComFuncs.SetSponsorBonuses(name)
	local CompareAmounts = ChoGGi.ComFuncs.CompareAmounts

	local sponsor = GetMissionSponsor(g_CurrentMissionParams.idMissionSponsor)
	if not sponsor then
		return
	end
	local c = #sponsor

	local bonus = ChoGGi.Tables.Sponsors[name]

	-- bonuses multiple sponsors have (CompareAmounts returns equal or larger amount)
	if sponsor.cargo then
		sponsor.cargo = CompareAmounts(sponsor.cargo, bonus.cargo)
	end
	if sponsor.additional_research_points then
		sponsor.additional_research_points = CompareAmounts(sponsor.additional_research_points, bonus.additional_research_points)
	end

	-- add extra bonuses to current sponsor
	for i = 1, #bonus do
		c = c + 1
		sponsor[c] = bonus[i]
	end

	-- figure out how to add this as a loop?
	if name == "BlueSun" then
		sponsor.rocket_price = CompareAmounts(sponsor.rocket_price, bonus.rocket_price)
		sponsor.applicants_price = CompareAmounts(sponsor.applicants_price, bonus.applicants_price)
	elseif name == "ESA" then
		sponsor.funding_per_tech = CompareAmounts(sponsor.funding_per_tech, bonus.funding_per_tech)
		sponsor.funding_per_breakthrough = CompareAmounts(sponsor.funding_per_breakthrough, bonus.funding_per_breakthrough)
	elseif name == "SpaceY" then
		sponsor.modifier_name1 = CompareAmounts(sponsor.modifier_name1, bonus.modifier_name1)
		sponsor.modifier_value1 = CompareAmounts(sponsor.modifier_value1, bonus.modifier_value1)
		sponsor.modifier_name2 = CompareAmounts(sponsor.modifier_name2, bonus.bonusmodifier_name2)
		sponsor.modifier_value2 = CompareAmounts(sponsor.modifier_value2, bonus.modifier_value2)
		sponsor.modifier_name3 = CompareAmounts(sponsor.modifier_name3, bonus.modifier_name3)
		sponsor.modifier_value3 = CompareAmounts(sponsor.modifier_value3, bonus.modifier_value3)
	elseif name == "Roscosmos" then
		sponsor.modifier_name1 = CompareAmounts(sponsor.modifier_name1, bonus.modifier_name1)
		sponsor.modifier_value1 = CompareAmounts(sponsor.modifier_value1, bonus.modifier_value1)
	elseif name == "Paradox" then
		sponsor.applicants_per_breakthrough = CompareAmounts(sponsor.applicants_per_breakthrough, bonus.applicants_per_breakthrough)
		sponsor.anomaly_bonus_breakthrough = CompareAmounts(sponsor.anomaly_bonus_breakthrough, bonus.anomaly_bonus_breakthrough)
	end
end

function ChoGGi.ComFuncs.GenerateScreenshotFilename(prefix, folder, ext, just_name, ...)
	if blacklist then
		return GenerateScreenshotFilename(prefix, folder, ext, just_name, ...)
	end
	local match = string.match
	local Max = Max

	prefix = prefix or ""
	ext = ext or "png"
	folder = folder or "AppData/"
	if not match(folder, "/$") and #folder > 0 then
		folder = folder .. "/"
	end
	local existing_files = io.listfiles(folder, prefix .. "*." .. ext)
	local index = 0
	for i = 1, #existing_files do
		index = Max(index, tonumber(match(existing_files[i], prefix .. "(%d+)" or 0)))
	end
	if just_name then
		return string.format("%s%04d", prefix, index + 1)
	end
	return string.format("%s%s%04d.%s", folder, prefix, index + 1, ext)
end
local GenerateScreenshotFilename = ChoGGi.ComFuncs.GenerateScreenshotFilename

function ChoGGi.ComFuncs.Dump(obj, overwrite, file, ext, skip_msg, gen_name)
	if blacklist then
		ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.Dump")
		return
	end

	-- If overwrite is nil then we append, if anything else we overwrite
	if overwrite then
		overwrite = nil
	else
		overwrite = "-1"
	end

	local filename
	if gen_name then
		filename = GenerateScreenshotFilename(file or "DumpedText", "AppData/logs/", ext or "txt")
	else
		filename = "AppData/logs/" .. (file or "DumpedText") .. "." .. (ext or "txt")
	end

	ThreadLockKey(filename)
	AsyncStringToFile(filename, obj, overwrite)
	ThreadUnlockKey(filename)

	-- let user know
	if not skip_msg then
		local msg = Strings[302535920000039--[[Dumped]]] .. ": " .. RetName(obj)
		print(filename,"\n",msg:sub(1,msg:find("\n")))
		MsgPopup(
			msg,
			filename
		)
	end
end

function ChoGGi.ComFuncs.DumpLua(obj)
	ChoGGi.ComFuncs.Dump(ChoGGi.newline .. ValueToLuaCode(obj), nil, "DumpedLua", "lua")
end

do -- DumpTableFunc
	local CmpLower = CmpLower

	local output_list = {}
	local c
	local level_limit

	local function SortTableFunc(a, b)
		if a.key and b.key then
			return CmpLower(
				RetName(a.key),
				RetName(b.key)
			)
		end
		return a.key and true or b.key and true
	end

	local function DumpTableFunc(obj, level, parent_name)
		if level == level_limit then
			return 0
		end

		if type(obj) == "table" then

			local obj_name = RetName(obj)

			c = c + 1
			output_list[c] = "\n\n------------------------- "
			if parent_name then
				c = c + 1
				output_list[c] = parent_name
				c = c + 1
				output_list[c] = " "
			end
			c = c + 1
			output_list[c] = obj_name
			c = c + 1
			output_list[c] = ":"
			c = c + 1
			output_list[c] = "\n"

			-- get all the key/values then sort the table
			local temp_list = {}
			local t_c = 0

			-- get all key/value pairs in the table
			for key, value in pairs(obj) do
				t_c = t_c + 1
				temp_list[t_c] = {
					key = key,
					value = value,
				}
			end
			table_sort(temp_list, SortTableFunc)

			-- now we can return an ordered list
			for i = 1, t_c do
				local item = temp_list[i]
				c = c + 1
				output_list[c] = "\n"
				c = c + 1
				output_list[c] = RetName(item.key)
				c = c + 1
				output_list[c] = ": "
				c = c + 1
				output_list[c] = RetName(item.value)
			end

			c = c + 1
			output_list[c] = "\n"

			-- go through once and dump any tables in the table
			for i = 1, t_c do
				local item = temp_list[i]
				if type(item.key) == "table" then
					DumpTableFunc(item.key, level+1, RetName(item.value))
				end
				if type(item.value) == "table" then
					DumpTableFunc(item.value, level+1, RetName(item.key))
				end
			end

		end
	end

	--[[
	mode = -1 to append or nil to overwrite (default: append)
	limit = how far down the rabbit hole (default 3)
	]]
	function ChoGGi.ComFuncs.DumpTable(obj, mode, limit)
		if blacklist then
			ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.DumpTable")
			return
		end
		if type(obj) ~= "table" then
			MsgPopup(
				Strings[302535920000003--[[Can't dump nothing]]],
				Strings[302535920000004--[[Dump]]]
			)
			return
		end
		local name = RetName(obj)

		level_limit = limit or 3

		-- make sure it's empty
		table_iclear(output_list)
		c = 0
		DumpTableFunc(obj, 0)

		if output_list[1] then
			local filename = "AppData/logs/DumpedTable.txt"
			AsyncStringToFile(filename, TableConcat(output_list), mode or "-1")

			local msg = Strings[302535920000039--[[Dumped]]] .. ": " .. name
			-- print msg to first newline
			print(filename,"\n",msg:sub(1,msg:find("\n")))
			MsgPopup(
				msg,
				filename,
				{objects = obj}
			)
			return
		end

		local msg = Strings[302535920000003--[[Can't dump nothing]]] .. ": " .. name .. "\n" .. ValueToLuaCode(obj)
		print(msg)
		MsgPopup(
			msg,
			Strings[302535920000004--[[Dump]]]
		)

	end
end --do

-- write logs funcs
do -- WriteLogs_Toggle
	local Dump = ChoGGi.ComFuncs.Dump
	local newline = ChoGGi.newline
	local func_names = {
		"DebugPrintNL",
--~ 		"DebugPrint", -- causes an error and stops games from loading
		"OutputDebugString",
		"AddConsoleLog", -- also does print()
--~ 		"printf",
		"assert",
		"error",
	}

	for i = 1, #func_names do
		SaveOrigFunc(func_names[i])
	end
	local ChoGGi_OrigFuncs = ChoGGi.OrigFuncs

	-- every 5s check buffer and print if anything
	local timer = testing and 2500 or 5000
	-- we always start off with a newline so the first line or so isn't merged
	local buffer_table = {newline}
	local buffer_cnt = 1

	if rawget(_G, "ChoGGi_thread_print_buffer") then
		DeleteThread(ChoGGi_thread_print_buffer)
	end
	ChoGGi_thread_print_buffer = CreateRealTimeThread(function()
		while true do
			Sleep(timer)
			if buffer_cnt > 1 then
				Dump(TableConcat(buffer_table, newline), nil, "Console", "log", true)
				table_iclear(buffer_table)
				buffer_table[1] = newline
				buffer_cnt = 1
			end
		end
	end)

	local function ReplaceFunc(funcname)
		local mask = funcname == "error" and 1
		_G[funcname] = function(...)

			-- table.concat don't work with non strings/numbers
			local args = {...}
			for i = 1, #args do
				local arg = args[i]
				local arg_type = type(arg)
				if arg_type ~= "string" and arg_type ~= "number" then
					args[i] = tostring(arg)
				end
			end
			args = TableConcat(args, " ")

			if buffer_table[buffer_cnt] ~= args then
				buffer_cnt = buffer_cnt + 1
				buffer_table[buffer_cnt] = funcname .. ": " .. args
			end

			-- I have no idea why the devs consider this an error?
			if mask == 1 and ... == "Attempt to use an undefined global '" then
				return
			end
			-- fire off orig func...
			ChoGGi_OrigFuncs[funcname](...)
		end

	end

	local function ResetFunc(funcname)
		if ChoGGi_OrigFuncs[funcname] then
			_G[funcname] = ChoGGi_OrigFuncs[funcname]
		end
	end

	function ChoGGi.ComFuncs.WriteLogs_Toggle(which)
		if blacklist then
			ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.WriteLogs_Toggle")
			return
		end

		if which then
			-- move old log to previous and add a blank log
			AsyncCopyFile("AppData/logs/Console.log", "AppData/logs/Console.previous.log", "raw")
			AsyncStringToFile("AppData/logs/Console.log", " ")

			-- redirect functions
			for i = 1, #func_names do
				ReplaceFunc(func_names[i])
			end
		else
			for i = 1, #func_names do
				ResetFunc(func_names[i])
			end
		end
	end
end -- do

-- returns table with list of files without path or ext and path, or exclude ext to return all files
function ChoGGi.ComFuncs.RetFilesInFolder(folder, ext)
	local err, files = AsyncListFiles(folder, ext and "*" .. ext or "*")
	if not err and #files > 0 then
		local table_path = {}
		local path = folder:sub(-1) == "/" and folder or folder .. "/"
		for i = 1, #files do
			local file = files[i]
			local name
			if ext then
				name = file:gsub(path, ""):gsub(ext, "")
			else
				name = file:gsub(path, "")
			end
			table_path[i] = {
				path = file,
				name = name,
			}
		end
		return table_path
	end
end

function ChoGGi.ComFuncs.RetFoldersInFolder(folder)
	local err, folders = AsyncListFiles(folder, "*", "folders")
	if not err and #folders > 0 then
		local table_path = {}
		local path = folder .. "/"
		for i = 1, #folders do
			table_path[i] = {
				path = folders[i],
				name = folders[i]:gsub(path, ""),
			}
		end
		return table_path
	end
end

do -- OpenInExamineDlg
	local IsPoint = IsPoint
	local red = red
	local function FlashTitlebar(title)
		title:SetBackground(red)
		Sleep(500)
		title:SetBackground(g_Classes.ChoGGi_XMoveControl.Background)
	end

	function ChoGGi.ComFuncs.OpenInExamineDlg(obj, parent, title, ...)
		local params, p_type
		-- check if parent is an opened examine dialog, or other
		if parent then
			p_type = type(parent)
			-- we only (somewhat) care about parent being a string, point, dialog
			if p_type == "table" and parent.ex_params then
				params = parent
				parent = nil
			elseif p_type ~= "string" and p_type ~= "table" and p_type ~= "userdata" then
				parent = nil
			end
		end
		params = params or {}
		params.varargs = params.varargs or ...

		-- preserve the orig params
		params.obj = obj
		if parent then
			params.parent = parent
		end
		if title then
			params.title = title
		end

		-- check if the parent has an id and use it
		if params.parent and p_type == "table" and params.parent.parent_id then
			params.parent_id = params.parent.parent_id
		end

		-- workaround for ChoGGi_dlgs_examine
		if type(params.obj) == "nil" then
			params.obj = "nil"
		end

		-- already examining? if so focus and return ( :new() doesn't return the opened dialog).
		local opened = ChoGGi_dlgs_examine[params.obj]

		if opened then
			-- dialog was closed, but ref remains
			if not IsValidXWin(opened) then
				ChoGGi_dlgs_examine[params.obj] = nil
			-- examine gets confused with children (first examined one that is)
			elseif not params.parent
				or params.parent and not (params.parent.child_lock and params.parent.child_lock_dlg)
			then
				-- hit refresh, cause i'm that kinda guy
				opened:RefreshExamine()
				-- and flash the titlebar
				CreateRealTimeThread(FlashTitlebar, opened.idMoveControl)
				return opened
			end
		end

		if params.parent ~= "str" and not (IsKindOf(params.parent, "XWindow") or IsPoint(params.parent)) then
			params.parent = nil
		end
		if type(params.title) ~= "string" then
			params.title = nil
		end

		-- are we using child lock?
		local new_child_lock_dlg
		if not params.skip_child then
			parent = params.parent
			if parent and IsKindOf(parent, "ChoGGi_DlgExamine") and parent.child_lock then
				local child = parent.child_lock_dlg
				if child then
					if not IsValidXWin(child) then
						parent.child_lock_dlg = false
					else
						-- It's valid so update with new obj
						child.obj = params.obj
						child:SetObj()
						-- no need for a new window
						return
					end
				end

				-- child_lock_dlg is invalid or not opened yet
				new_child_lock_dlg = true
			end
		end

		local dlg = ChoGGi_DlgExamine:new({}, terminal.desktop, params)

		-- update parent examine with new child
		if new_child_lock_dlg then
			parent.child_lock_dlg = dlg
		end

		return dlg
	end
end -- do

function ChoGGi.ComFuncs.OpenInMonitorInfoDlg(list, parent)
	if type(list) ~= "table" then
		return
	end

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_DlgMonitorInfo:new({}, terminal.desktop, {
		obj = list,
		parent = parent,
		tables = list.tables,
		values = list.values,
	})
end

function ChoGGi.ComFuncs.OpenInObjectEditorDlg(obj, parent, title)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = ChoGGi.ComFuncs.SelObject()
		parent = nil
	else
		obj = obj or ChoGGi.ComFuncs.SelObject()
	end

	if not obj then
		return
	end

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_DlgObjectEditor:new({}, terminal.desktop, {
		obj = obj,
		parent = parent,
		title = title,
	})
end

function ChoGGi.ComFuncs.OpenIn3DManipulatorDlg(obj, parent)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = ChoGGi.ComFuncs.SelObject()
		parent = nil
	else
		obj = obj or ChoGGi.ComFuncs.SelObject()
	end

	if not obj then
		return
	end

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_Dlg3DManipulator:new({}, terminal.desktop, {
		obj = obj,
		parent = parent,
	})
end

function ChoGGi.ComFuncs.OpenInExecCodeDlg(context, parent)
	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_DlgExecCode:new({}, terminal.desktop, {
		obj = context,
		parent = parent,
	})
end

function ChoGGi.ComFuncs.OpenInFindValueDlg(context, parent)
	if not context then
		return
	end

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_DlgFindValue:new({}, terminal.desktop, {
		obj = context,
		parent = parent,
	})
end

function ChoGGi.ComFuncs.OpenInImageViewerDlg(obj, parent)
	if not obj then
		return
	end

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_DlgImageViewer:new({}, terminal.desktop, {
		obj = obj,
		parent = parent,
	})
end

function ChoGGi.ComFuncs.OpenInDTMSlotsDlg(parent)
	-- If fired from action menu
	if parent and (IsKindOf(parent, "XAction") or not IsKindOf(parent, "XWindow")) then
		parent = nil
	end

	return ChoGGi_DlgDTMSlots:new({}, terminal.desktop, {
		parent = parent,
	})
end

function ChoGGi.ComFuncs.EntitySpawner(obj, params)

	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		params = {}
		if obj.setting_planning then
			params.planning = true
		else
			params.planning = nil
		end
		obj = nil
	else
		params = params or {}
	end

	local const = const

	local title = params.planning and Strings[302535920000862--[[Object Planner]]] or Strings[302535920000475--[[Entity Spawner]]]
	local hint = params.planning and Strings[302535920000863--[[Places fake construction site objects at mouse cursor (collision disabled).]]] or Strings[302535920000476--[["Shows list of objects, and spawns at mouse cursor."]]]

	local default
	local item_list = {}
	local c = 0

	if IsValid(obj) and IsValidEntity(obj.ChoGGi_orig_entity) then
		default = Translate(1000121--[[Default]])
		item_list[1] = {
			text = " " .. default,
			value = default,
		}
		c = #item_list
	end

	if params.planning then
		local BuildingTemplates = BuildingTemplates
		for key, value in pairs(BuildingTemplates) do
			c = c + 1
			item_list[c] = {
				text = key,
				value = value.entity,
			}
		end
	else
		local EntityData = EntityData
		for key in pairs(EntityData) do
			c = c + 1
			item_list[c] = {
				text = key,
				value = key,
			}
		end
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]
		local value = choice.value

		if not obj then
			local cls = ChoGGi_OBuildingEntityClass
			if choice.check1 then
				cls = ChoGGi_OBuildingEntityClassAttach
			end

			obj = cls:new()
			obj:SetPos(ChoGGi.ComFuncs.CursorNearestHex())

			if params.planning then
				obj.planning = true
				obj:SetGameFlags(const.gofUnderConstruction)
			end
		end

		-- backup orig entity
		if not IsValidEntity(obj.ChoGGi_orig_entity) then
			obj.ChoGGi_orig_entity = obj:GetEntity()
		end

		-- crash prevention
		obj:SetState("idle")

		if value == default and IsValidEntity(obj.ChoGGi_orig_entity) then
			obj:ChangeEntity(obj.ChoGGi_orig_entity)
			obj.entity = obj.ChoGGi_orig_entity
		else
			obj:ChangeEntity(value)
			obj.entity = value
		end

		if SelectedObj == obj then
			ObjModified(obj)
		end

		-- needs to fire whenever entity changes
		obj:ClearEnumFlags(const.efCollision + const.efApplyToGrids)

		if not params.skip_msg then
			MsgPopup(
				choice.text .. ": " .. Strings[302535920000014--[[Spawned]]],
				title
			)
		end
	end

	local checkboxes
	if params.list_type ~= 7 then
		checkboxes = {
			{
				title = Strings[302535920001578--[[Auto-Attach]]],
				hint = Strings[302535920001579--[[Activate any auto-attach spots this entity has.]]],
			},
		}
	end

	if params.title_postfix then
		title = title .. ": " .. params.title_postfix
	end

	ChoGGi.ComFuncs.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = title,
		hint = hint,
		custom_type = params.list_type or 0,
		checkboxes = checkboxes,
	}
end

function ChoGGi.ComFuncs.SetAnimState(obj)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = ChoGGi.ComFuncs.SelObject()
	else
		obj = obj or ChoGGi.ComFuncs.SelObject()
	end

	if not IsValid(obj) then
		return
	end

	local item_list = {}
	local states_str = obj:GetStates()
	local states_num = EnumValidStates(obj)

	if testing and #states_str ~= #states_num then
		print("SetAnimState: Different state amounts")
	end

	for i = 1, #states_str do
		local state = states_str[i]
		local idx = states_num[i]
		item_list[i] = {
			text = Translate(1000037--[[Name]]) .. ": " .. state .. ", " .. Strings[302535920000858--[[Index]]] .. ": " .. idx,
			value = state,
		}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		local value = choice.value
		-- If user wants to play it again we'll need to have it set to another state and everything has idle
		obj:SetState("idle")

		if value ~= "idle" then
			obj:SetState(value)
			MsgPopup(
				ChoGGi.ComFuncs.SettingState(choice.text),
				Strings[302535920000859--[[Anim State]]]
			)
		end
	end

	ChoGGi.ComFuncs.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = Strings[302535920000860--[[Set Anim State]]],
		hint = Strings[302535920000861--[[Current State: %s]]]:format(obj:GetState()),
		custom_type = 7,
	}
end

function ChoGGi.ComFuncs.MonitorThreads()
	local table_list = {}
	local dlg = ChoGGi.ComFuncs.OpenInExamineDlg(table_list, {
		ex_params = true,
		auto_refresh = true,
		title = Strings[302535920000853--[[Monitor]]] .. ": ThreadsRegister",
	})

	local RetThreadInfo = ChoGGi.ComFuncs.RetThreadInfo

	CreateRealTimeThread(function()
		-- stop when dialog is closed
		local ThreadsRegister = ThreadsRegister
		while IsValidXWin(dlg) do
			-- only update when it's our dlg sending the msg
			local _,msg_dlg = WaitMsg("ChoGGi_dlgs_examine_autorefresh")
			if msg_dlg == dlg then
				-- we use a "tags" tag to store a unique number (examine uses tags off for text, so we need to use on
				local c = 0
				table_clear(table_list)
				for thread in pairs(ThreadsRegister) do
					if blacklist then
						-- first func is always a C func (WaitMsg or Sleep), and we want a file name
						local info = RetThreadInfo(thread)[2]
						if info then
							c = c + 1
							table_list[info.func .. "<tags on " .. c .. ">"] = thread
						end
					else
						local info = debug_getinfo(thread, 1, "S")
						if info then
							c = c + 1
							table_list[info.source .. "(" .. info.linedefined .. ")<tags on " .. c .. ">"] = thread
						end
					end
				end
			end

		end
	end)
end

-- sortby: nil = table length, 1 = table names
-- skip_under: don't show any tables under this length (default 25)
--~ 	ChoGGi.ComFuncs.MonitorTableLength(_G)
function ChoGGi.ComFuncs.MonitorTableLength(obj, skip_under, sortby, title)
	obj = obj or _G
	title = title or RetName(obj)
	skip_under = skip_under or 25
	local table_list = {}
	local dlg = ChoGGi.ComFuncs.OpenInExamineDlg(table_list, {
		ex_params = true,
		auto_refresh = true,
		title = title,
	})

	local PadNumWithZeros = ChoGGi.ComFuncs.PadNumWithZeros

	CreateRealTimeThread(function()
		-- stop when dialog is closed
		while IsValidXWin(dlg) do
			-- only update when it's our dlg sending the msg
			local _,msg_dlg = WaitMsg("ChoGGi_dlgs_examine_autorefresh")
			if msg_dlg == dlg then
				table_clear(table_list)

				for key, value in pairs(obj) do
					if type(value) == "table" then
						-- tables can be index or associative or a mix
						local length = 0
						for _ in pairs(value) do
							length = length + 1
						end
						-- skip the tiny tables
						if length > skip_under then
							if not sortby then
								table_list[PadNumWithZeros(length) .. " " .. key] = value
							elseif sortby == 1 then
								table_list[key .. " " .. length] = value
							end
						end

					end
				end
			end

		end
	end)
end

function ChoGGi.ComFuncs.SetParticles(obj)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = ChoGGi.ComFuncs.SelObject()
	else
		obj = obj or ChoGGi.ComFuncs.SelObject()
	end

	local name = Strings[302535920000129--[[Set]]] .. " " .. Strings[302535920001184--[[Particles]]]
	if not obj or obj and not obj:IsKindOf("FXObject") then
		MsgPopup(
			Strings[302535920000027--[[Nothing selected]]] .. ": " .. "FXObject",
			name
		)
		return
	end

	local PlayFX = PlayFX
	-- make a list of spot names for the obj, so we skip particles that need that spot
	local spots = {}
	local id_start, id_end = obj:GetAllSpots(obj:GetState())
	for i = id_start, id_end do
		spots[obj:GetSpotName(i)] = true
	end

	local default = Translate(1000121--[[Default]])

	local item_list = {
		{text = " " .. default, value = default},
	}
	local c = #item_list

	local dupes = {}

	local particles = FXLists.ActionFXParticles
	for i = 1, #particles do
		local p = particles[i]
		local name = p.Actor .. ", " .. p.Action .. ", " .. p.Moment
		if not dupes[name] then
			dupes[name] = true
			if spots[p.Spot] or p.Spot == "" then
				c = c + 1
				item_list[c] = {
					text = name,
					value = p.Actor,
					action = p.Action,
					moment = p.Moment,
					handle = p.handle,
					index = i,
					hint = "Actor: " .. p.Actor .. ", Action: " .. p.Action .. ", Moment: " .. p.Moment,
				}
			end
		end
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]
		local actor = choice.value
		local action = choice.action
		local moment = choice.moment

		-- If there's one playing then stop it
		if obj.ChoGGi_playing_fx then
			PlayFX(obj.ChoGGi_playing_fx, "end", obj)
			if obj.DestroyFX then
				obj:DestroyFX(obj, obj.ChoGGi_playing_fx)
			end
			obj.ChoGGi_playing_fx = nil
		end
		-- save fx id so we can stop it
		obj.ChoGGi_playing_fx = action

		if obj.fx_actor_class_ChoGGi_Orig == nil then
			obj.fx_actor_class_ChoGGi_Orig = obj.fx_actor_class
		end

		obj.fx_actor_class = actor

		particles[choice.index].Actor = "any"

		if actor == default then
			if obj.fx_actor_class_ChoGGi_Orig then
				obj.fx_actor_class = obj.fx_actor_class_ChoGGi_Orig
				obj.fx_actor_class_ChoGGi_Orig = nil
			end
			obj.ChoGGi_playing_fx = nil
		else
			PlayFX(action, moment, obj)
		end

		MsgPopup(action,name)
	end

	ChoGGi.ComFuncs.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = name,
		hint = Strings[302535920001421--[[Shows list of particles to quickly test out on objects.]]],
		custom_type = 7,
		skip_icons = true,
	}
end

-- toggles console when it has focus (otherwise focuses on the console)
function ChoGGi.ComFuncs.ToggleConsole(show)
	local dlg = dlgConsole
	local visible = dlg and dlg:GetVisible()

	if IsKindOf(show, "XAction") then
		show = not visible
		if dlg and visible then
			return dlg.idEdit:SetFocus()
		end
	end
	ShowConsole(show or not visible)
	-- ShowConsole can reset the dlgConsole ref
	dlgConsole.idEdit:SetFocus()

-- maybe see about overriding focus from construct dlg
end

-- toggle visiblity of console log
function ChoGGi.ComFuncs.ToggleConsoleLog()
	local log = dlgConsoleLog
	if log then
		if log:GetVisible() then
			log:SetVisible(false)
		else
			log:SetVisible(true)
		end
	else
		dlgConsoleLog = ConsoleLog:new({}, terminal.desktop)
	end
end

function ChoGGi.ComFuncs.ShowConsoleLogWin(visible)
	if visible and not dlgChoGGi_DlgConsoleLogWin then
		dlgChoGGi_DlgConsoleLogWin = ChoGGi_DlgConsoleLogWin:new({}, terminal.desktop, {})
		dlgChoGGi_DlgConsoleLogWin:UpdateText(LoadLogfile())
	end

	local dlg = dlgChoGGi_DlgConsoleLogWin
	if dlg then
		dlg:SetVisible(visible)

		-- size n position
		local size = ChoGGi.UserSettings.ConsoleLogWin_Size
		local pos = ChoGGi.UserSettings.ConsoleLogWin_Pos
		-- make sure dlg is within screensize
		if size then
			dlg:SetSize(size)
		end
		if pos then
			dlg:SetPos(pos)
		else
			dlg:SetPos(point(100, 100))
		end

	end
end

-- Any png files in AppData/Logos folder will be added to mod as converted logo files.
-- They have to be min of 8bit, and will be resized to power of 2.
-- This doesn't add anything to metadata/items, it only converts files.
--~ 	ChoGGi.ComFuncs.ConvertImagesToLogoFiles("MOD_ID")
--~ 	ChoGGi.ComFuncs.ConvertImagesToLogoFiles(Mods.MOD_ID, ".tga")
--~ ChoGGi.ComFuncs.ConvertImagesToLogoFiles(Mods.ChoGGi_)
function ChoGGi.ComFuncs.ConvertImagesToLogoFiles(mod, ext)
	if blacklist then
		ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.ConvertImagesToLogoFiles")
		return
	end
	mod = mod or Mods.ChoGGi_
	if type(mod) == "string" then
		mod = Mods[mod]
	end
	local images = ChoGGi.ComFuncs.RetFilesInFolder("AppData/Logos", ext or ".png")
	if images then
		-- returns error msgs and prints in console
		local TGetID = TGetID
		local fake_ged_socket = {
			ShowMessage = function(title, msg)
				if TGetID(title) == 12061 then
					print("ShowMessage", Translate(title), Translate(msg))
				end
			end,
		}

		local ModItemDecalEntity = ModItemDecalEntity
		local Import = ModItemDecalEntity.Import
		local ConvertToOSPath = ConvertToOSPath
		for i = 1, #images do
			local filename = ConvertToOSPath(images[i].path)
			Import(nil,
				ModItemDecalEntity:new{
					entity_name = images[i].name,
					name = images[i].name,
					filename = filename:gsub("\\", "/"),
					mod = mod,
				},
				nil,
				fake_ged_socket
			)
			print(filename)
		end
	end
end

do -- ConvertImagesToResEntities
	-- converts png images (512x512) to an entity you can use to replace deposit signs.
	local ConvertToOSPath = ConvertToOSPath
	local RetFilesInFolder = ChoGGi.ComFuncs.RetFilesInFolder
--~ 	ModItemDecalEntity:Import
	local function ModItemDecalEntityImport(name, filename, mod)
		local output_dir = ConvertToOSPath(mod.content_path)

		local ent_dir = output_dir .. "Entities/"
		local ent_file = name .. ".ent"
		local ent_output = ent_dir .. ent_file

		local mtl_dir = output_dir .. "Entities/Materials/"
		local mtl_file = name .. "_mesh.mtl"
		local mtl_output = mtl_dir .. mtl_file

		local texture_dir = output_dir .. "Entities/Textures/"
		local texture_output = texture_dir .. name .. ".dds"

		local fallback_dir = texture_dir .. "Fallbacks/"
		local fallback_output = fallback_dir .. name .. ".dds"

		local err = AsyncCreatePath(ent_dir)
		if err then
			return err
		end
		err = AsyncCreatePath(mtl_dir)
		if err then
			return err
		end
		err = AsyncCreatePath(texture_dir)
		if err then
			return err
		end
		err = AsyncCreatePath(fallback_dir)
		if err then
			return err
		end

		err = AsyncStringToFile(ent_output, [[<?xml version="1.0" encoding="UTF-8"?>
<entity path="">
	<state id="idle">
		<mesh_ref ref="mesh"/>
	</state>
	<mesh_description id="mesh">
		<src file=""/>
		<mesh file="SignConcreteDeposit_mesh.hgm"/>
		<material file="]] .. mtl_file .. [["/>
		<bsphere value="0, 0, 50, 1301"/>
		<box min="-920, -920, 50" max="920, 920, 50"/>
	</mesh_description>
</entity>
]])

		if err then
			return
		end

		local cmdline = [["]] .. ConvertToOSPath(g_HgnvCompressPath) .. [[" -dds10 -24 bc1 -32 bc3 -srgb "]] .. filename .. [[" "]] .. texture_output .. [["]]
		err = AsyncExec(cmdline, "", true, false)
		if err then
			return err
		end
		cmdline = [["]] .. ConvertToOSPath(g_DdsTruncPath) .. [[" "]] .. texture_output .. [[" "]] .. fallback_output .. [[" "]] .. const.FallbackSize .. [["]]
		err = AsyncExec(cmdline, "", true, false)
		if err then
			return err
		end
--~ 			cmdline = [["]] .. ConvertToOSPath(g_HgimgcvtPath) .. [[" "]] .. texture_output .. [[" "]] .. ui_output .. [["]]
--~ 			err = AsyncExec(cmdline, "", true, false)
--~ 			if err then
--~ 				return err
--~ 			end

		err = AsyncStringToFile(mtl_output, [[<?xml version="1.0" encoding="UTF-8"?>
<Materials>
<Material>
	<BaseColorMap Name="]] .. name .. [[.dds" mc="0"/>
	<SIMap Name="BackLight.dds" mc="0"/>
	<Property Special="None"/>
	<Property AlphaBlend="Blend"/>
</Material>
</Materials>]])

		if err then
			return err
		end
	end

--~ 	ChoGGi.ComFuncs.ConvertImagesToResEntities("ChoGGi_ExampleNewResIcon")
--~ 	ChoGGi.ComFuncs.ConvertImagesToResEntities("MOD_ID")
--~ 	ChoGGi.ComFuncs.ConvertImagesToResEntities(Mods.MOD_ID, ".tga")
	function ChoGGi.ComFuncs.ConvertImagesToResEntities(mod, ext)
		if blacklist then
			ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.ConvertImagesToResEntities")
			return
		end
		mod = mod or Mods.ChoGGi_
		if type(mod) == "string" then
			mod = Mods[mod]
		end
		local images = RetFilesInFolder("AppData/Logos", ext or ".png")
		if images then
			for i = 1, #images do
				local filename = ConvertToOSPath(images[i].path)
				ModItemDecalEntityImport(
					images[i].name,
					filename:gsub("\\", "/"),
					mod
				)
				print(filename)
			end
		end

	end
end -- do

do -- ExamineEntSpots (Object>Entity Spots)
	local spots_str = [[		<attach name="%s" spot_note="%s" bone="%s" spot_pos="%s, %s, %s" spot_scale="%s" spot_rot="%s, %s, %s, %s"/>]]

	local RetOriginSurfaces
	local pts_c
	local pts_tmp = {}
	local suffix = [["/>]]
	local function BuildSurf(c, list, obj, name, surf)
		local prefix = [[		<surf type="]] .. name .. [[" points="]]

		local surfs = RetOriginSurfaces(obj, surf)
		for i = 1, #surfs do
			local pts = surfs[i]
			table_iclear(pts_tmp)
			pts_c = 0

			local count = #pts
			for j = 1, count do
				local x, y, z = pts[j]:xyz()
				pts_c = pts_c + 1
				pts_tmp[pts_c] = x
				pts_c = pts_c + 1
				pts_tmp[pts_c] = ", "
				pts_c = pts_c + 1
				pts_tmp[pts_c] = y
				pts_c = pts_c + 1
				pts_tmp[pts_c] = ", "
				pts_c = pts_c + 1
				pts_tmp[pts_c] = z
				if j ~= count then
					pts_c = pts_c + 1
					pts_tmp[pts_c] = ";"
				end
			end
			c = c + 1
			list[c] = prefix .. TableConcat(pts_tmp) .. suffix
		end
		return c
	end

--~ local list = ChoGGi.ComFuncs.ExamineEntSpots(s, true)
--~ list = ChoGGi.ComFuncs.TableConcat(list, "\n")
--~ ChoGGi.ComFuncs.Dump(list, nil, nil, "ent")
	function ChoGGi.ComFuncs.ExamineEntSpots(obj, parent_or_ret)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi.ComFuncs.SelObject()
			parent_or_ret = nil
		else
			obj = obj or ChoGGi.ComFuncs.SelObject()
		end

		local entity = obj and obj.GetEntity and obj:GetEntity()
		if not IsValidEntity(entity) then
			return
		end

		local origin = obj:GetSpotBeginIndex("Origin")
		local origin_pos_x, origin_pos_y, origin_pos_z = obj:GetSpotLocPosXYZ(origin)
		local id_start, id_end = obj:GetAllSpots(EntityStates.idle)
		if not id_end then
			return
		end

		CreateGameTimeThread(function()

		local list = {}
		local c = #list

		-- loop through each state and add sections for them
		local states_str = obj:GetStates()
		local states_num = EnumValidStates(obj)
		for i = 1, #states_str do
			local state_str = states_str[i]
			local state_num = states_num[i]
			obj:SetState(state_str)
			-- till i find something where the channel isn't 1
			while obj:GetAnim(1) ~= state_num do
				WaitMsg("OnRender")
			end

			-- this is our bonus eh
			local bbox = obj:GetEntityBBox()
			local x1, y1, z1 = bbox:minxyz()
			local x2, y2, z2 = bbox:maxxyz()
			local pos_x, pos_y, pos_z, radius = obj:GetBSphere(state_str, true)
			local anim_dur = obj:GetAnimDuration(state_str)
			local step_len = obj:GetStepLength(state_str)
--~ 			local step_vec = obj:GetStepVector(state_str, obj:GetAngle(), 0, obj:GetAnimPhase())
			local step_vec = obj:GetStepVector(state_str, obj:GetAngle(), 0, anim_dur)
			local sv1, sv2, sv3 = step_vec:xyz()
--~ Basketball_idle.hga
			c = c + 1
			list[c] = [[		<state id="]] .. state_str .. [[">
			<mesh_ref ref="mesh"/>
			<anim file="]] .. entity .. "_" .. state_str .. [[.hga" duration="]] .. anim_dur .. [["/>
			<bsphere value="]] .. (pos_x - origin_pos_x) .. ", "
				.. (pos_y - origin_pos_y) .. ", " .. (pos_z - origin_pos_z) .. ", "
				.. radius .. [["/>
			<box min="]] .. x1 .. ", " .. y1 .. ", " .. z1
				.. [[" max="]] .. x2 .. ", " .. y2 .. ", " .. z2 .. [["/>
			<step length="]] .. step_len .. [[" vector="]] .. sv1 .. ", " .. sv2 .. ", " .. sv3 ..  [["/>]]
			.. [[</state>]]
		-- ADD ME
		-- compensate="CME"

		end -- for states

		local mat = GetStateMaterial(entity, 0, 0)
		-- add the rest of the entity info
		c = c + 1
		list[c] = [[	<mesh_description id="mesh">
		<mesh file="]] .. mat:sub(1, -3) .. [[.hgm"/>
		<material file="]] .. mat .. [["/>]]
		-- eh, close enough

		-- stick with idle i guess?
		obj:SetState("idle")
		while obj:GetAnim(1) ~= 0 do
			WaitMsg("OnRender")
		end

		for i = id_start, id_end do
			local name = obj:GetSpotName(i)
			-- It isn't needed
			if name ~= "Origin" then
				-- make a copy to edit
				local spots_str_t = spots_str

				-- we don't want to fill the list with stuff we don't use
				local annot = obj:GetSpotAnnotation(i)
				if not annot then
					annot = ""
					spots_str_t = spots_str_t:gsub([[ spot_note="%%s"]], "%%s")
				end

				local bone = obj:GetSpotBone(i)
				if bone == "" then
					spots_str_t = spots_str_t:gsub([[ bone="%%s"]], "%%s")
				end

				-- axis, scale
				local _, _, _, _, axis_x, axis_y, axis_z = obj:GetSpotLocXYZ(i)

				-- 100 is default
				local scale = obj:GetSpotVisualScale(i)
				if scale == 100 then
					spots_str_t = spots_str_t:gsub([[ spot_scale="%%s"]], "%%s")
					scale = ""
				end

				local angle = obj:GetSpotVisualRotation(i)
				-- means nadda for spot_rot
				if angle == 0 and axis_x == 0 and axis_y == 0 and axis_z == 4096 then
					spots_str_t = spots_str_t:gsub([[ spot_rot="%%s, %%s, %%s, %%s"]], "%%s%%s%%s%%s")
					angle, axis_x, axis_y, axis_z = "", "", "", ""
				else
					axis_x = (axis_x + 0.0) / 100
					axis_y = (axis_y + 0.0) / 100
					axis_z = (axis_z + 0.0) / 100
					angle = (angle) / 60
--~ 					if angle > 360 then
--~ 						printC("ExamineEntSpots: angle > 360: ", angle)
--~ 						-- just gotta figure out how to turn 18000 or 3600 into 60 (21600)
--~ 						angle = 360 - angle
--~ 					end
				end

				local pos_x, pos_y, pos_z = obj:GetSpotPosXYZ(i)

				c = c + 1
				list[c] = spots_str_t:format(
					name, annot, bone,
					pos_x - origin_pos_x, pos_y - origin_pos_y, pos_z - origin_pos_z,
					scale, axis_x, axis_y, axis_z, angle
				)
			end

		end -- for spots

		-- add surfs
		RetOriginSurfaces = RetOriginSurfaces or ChoGGi.ComFuncs.RetOriginSurfaces
		-- hex_shape
		c = BuildSurf(c, list, obj, "hex_shape", 5)
		-- selection
		c = BuildSurf(c, list, obj, "selection", 7)
		-- collision
		c = BuildSurf(c, list, obj, "collision", 0)

		-- opener
		table.insert(list, 1, Strings[302535920001068--[["The func I use for spot_rot rounds to two decimal points... (let me know if you find a better one).
Attachment bspheres are off (x and y are; z and rotate aren't).
Some of the file names are guesses. <anim> is a guess, try removing it."]]]
			.. [[


<?xml version="1.0" encoding="UTF-8"?>
<entity path="">]])

		-- and the closer
		list[#list+1] = [[	</mesh_description>
</entity>]]

		if parent_or_ret == true then
			return TableConcat(list, "\n")
		else
			ChoGGi.ComFuncs.OpenInMultiLineTextDlg{
				parent = parent_or_ret,
				text = TableConcat(list, "\n"),
				title = Strings[302535920000235--[[Entity Spots]]] .. ": " .. RetName(obj),
			}
		end

		end)
	end
end -- do

do -- RetHexSurfaces
	local GetStates = GetStates
	local GetStateIdx = GetStateIdx
	local GetSurfaceHexShapes = GetSurfaceHexShapes
	local EntitySurfaces = EntitySurfaces

	local function AddToList(filter, list, c, shape, name, key, value, state, hash)
		if shape and (not filter or filter and #shape > 0) then
			c = c + 1
			list[c] = {
				name = name,
				shape = shape,
				id = key,
				mask = value,
				state = state,
				hash = hash,
			}
		end
		return c
	end

	function ChoGGi.ComFuncs.RetHexSurfaces(entity, filter, parent_or_ret)
		local list = {}
		local c = 0

		local all_states = GetStates(entity)
		for i = 1, #all_states do
			local state = GetStateIdx(all_states[i])
			for key, value in pairs(EntitySurfaces) do
				local outline, interior, hash = GetSurfaceHexShapes(entity, state, value)
				c = AddToList(filter, list, c, outline, "outline", key, value, state, hash)
				c = AddToList(filter, list, c, interior, "interior", key, value, state, hash)
			end
		end

		if parent_or_ret == true then
			return list
		else
			ChoGGi.ComFuncs.OpenInExamineDlg(list, nil, "RetHexSurfaces")
		end
	end
end -- do

do -- ObjFlagsList
--~ 		local IsFlagSet = IsFlagSet
	local const = const

	-- get list of const.rf* flags
	local rf_flags = {}
	local int_flags = {}
	for flag, value in pairs(const) do
		if flag:sub(1, 2) == "rf" and type(value) == "number" then
			rf_flags[flag] = value
		elseif flag:sub(1, 3) == "int" and type(value) == "number" then
			int_flags[flag] = value
		end
	end

	local flags_table
	local function CheckFlags(flags, obj, func_name)
		local get = "Get" .. func_name
		local set = "Set" .. func_name
		local clear = "Clear" .. func_name
		local us = ChoGGi.UserSettings

		for _, f in pairs(flags) do
			local mask = const[f]
			-- grumble efAlive grumble
			if mask then
				local flagged = obj[get](obj, mask) == mask
				if func_name == "ClassFlags" then
					flags_table[f .. " (" .. mask .. ")"] = flagged
				else
					flags_table[f .. " (" .. mask .. ")"] = {
						ChoGGi_AddHyperLink = true,
						hint = Strings[302535920001069--[[Toggle Boolean]]],
						name = tostring(flagged),
						colour = flagged and us.ExamineColourBool or us.ExamineColourBoolFalse,
						func = function(ex_dlg, _, list_obj)
							-- If flag is true
							if obj[get](obj, mask) == mask then
								obj[clear](obj, mask)
								list_obj.name = "false"
								list_obj.colour = us.ExamineColourBoolFalse
							else
								obj[set](obj, mask)
								list_obj.name = "true"
								list_obj.colour = us.ExamineColourBool
							end
							ex_dlg:RefreshExamine()
						end,
					}
				end
			end
		end
	end

	function ChoGGi.ComFuncs.ObjFlagsList_TR(obj, parent_or_ret)
		if not obj or obj.__name ~= "HGE.TaskRequest" then
			return
		end
		flags_table = {}

		for flag, value in pairs(rf_flags) do
			flags_table[flag .. " (" .. value .. ")"] = obj:IsAnyFlagSet(value)
		end

		if parent_or_ret == true then
			return flags_table
		else
			ChoGGi.ComFuncs.OpenInExamineDlg(flags_table, parent_or_ret, RetName(obj))
		end
	end

	function ChoGGi.ComFuncs.ObjFlagsList(obj, parent_or_ret)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi.ComFuncs.SelObject()
			parent_or_ret = nil
		else
			obj = obj or ChoGGi.ComFuncs.SelObject()
		end

		if not IsValid(obj) then
			return
		end

		flags_table = {}

		local FlagsByBits = FlagsByBits
		CheckFlags(FlagsByBits.Enum, obj, "EnumFlags")
		CheckFlags(FlagsByBits.Game, obj, "GameFlags")
		CheckFlags(FlagsByBits.Class, obj, "ClassFlags")
--~ 			CheckFlags(FlagsByBits.Component, obj, "ClassFlags")

		if parent_or_ret == true then
			return flags_table
		else
			ChoGGi.ComFuncs.OpenInExamineDlg(flags_table, parent_or_ret, RetName(obj))
		end

	end
end -- do

do -- GetMaterialProperties
	local GetMaterialProperties = GetMaterialProperties
	local GetStateMaterial = GetStateMaterial
	local GetStateIdx = GetStateIdx
	local GetStateLODCount = GetStateLODCount
	local GetStates = GetStates

	local channel_list = {
		RM = true,
		BaseColor = true,
		Dust = true,
		AO = true,
		Normal = true,
		Colorization = true,
		SI = true,
		RoughnessMetallic = true,
		Emissive = true,
	}
	local mtl_lookup = {
		AO = [[		<AmbientOcclusionMap Name="%s" mc="%s"/>]],
		BaseColor = [[		<BaseColorMap Name="%s" mc="%s"/>]],
		Colorization = [[		<ColorizationMap Name="%s" mc="%s"/>]],
		Dust = [[		<DustMap Name="%s" mc="%s"/>]],
		Emissive = [[		<EmissiveMap Name="%s" mc="%s"/>]],
		Normal = [[		<NormalMap Name="%s" mc="%s"/>]],
		RM = [[		<RMMap Name="%s" mc="%s"/>]],
		RoughnessMetallic = [[		<RoughnessMetallicMap Name="%s" mc="%s"/>]],
		SI = [[		<SIMap Name="%s" mc="%s"/>]],

		alphatest = [[		<Property AlphaTest="%s"/>]],
		animation_frames_x = [[		<Property AnimationFramesX="%s"/>]],
		animation_frames_y = [[		<Property AnimationFramesY="%s"/>]],
		animation_time = [[		<Property AnimationTime="%s"/>]],
		blend = [[		<Property AlphaBlend="%s"/>]],
		castshadow = [[		<Property CastShadow="%s"/>]],
		deposition = [[		<Property Deposition="%s"/>]],
		depthsmooth = [[		<Property DepthSmooth="%s"/>]],
		depthwrite = [[		<Property DepthWrite="%s"/>]],
		distortion = [[		<Property Distortion="%s"/>]],
		opacity = [[		<Property Opacity="%s"/>]],
		special = [[		<Property Special="%s"/>]],
		terraindistorted = [[		<Property TerrainDistortedMesh="%s"/>]],
		transparentdecal = [[		<Property TransparentDecal="%s"/>]],
		transparent = [[		<Property Transparent="%s"/>]],
		twosidedshading = [[		<Property TwoSidedShading="%s"/>]],
		wind = [[		<Property Wind="%s"/>]],
		flags = [[		<Property Flags="%s"/>]],
		emflags = [[		<Property EMFlags="%s"/>]],
		shader = [[		<Property shader="%s"/>]],

--~ 			XX = [[		<Property Anisotropic="%s"/>]],
--~ 			XX = [[		<Property DtmDisable="%s"/>]],
--~ 			XX = [[		<Property EnvMapped="%s"/>]],
--~ 			XX = [[		<Property GlossColor="%s"/>]],
--~ 			XX = [[		<Property MarkVolume="%s"/>]],
--~ 			XX = [[		<Property MaskedCM="%s"/>]],
--~ 			XX = [[		<Property NoDiffuse="%s"/>]],
--~ 			XX = [[		<Property NumInstances="%s"/>]],
--~ 			XX = [[		<Property SelfIllum="%s"/>]],
--~ 			XX = [[		<Property ShadowBlob="%s"/>]],
--~ 			XX = [[		<Property SpecularPower="%s"/>]],
--~ 			XX = [[		<Property SpecularPowerRGB="%s"/>]],
--~ 			XX = [[		<Property StretchFactor1="%s"/>]],
--~ 			XX = [[		<Property StretchFactor2="%s"/>]],
--~ 			XX = [[		<Property SunFacingShading="%s"/>]],
--~ 			XX = [[		<Property TexScrollTime="%s"/>]],
--~ 			XX = [[		<Property Translucency="%s"/>]],
--~ 			XX = [[		<Property TwoSided="%s"/>]],
--~ 			XX = [[		<Property UnitLighting="%s"/>]],
--~ 			XX = [[		<Property UOffset="%s"/>]],
--~ 			XX = [[		<Property USize="%s"/>]],
--~ 			XX = [[		<Property ViewDependentOpacity="%s"/>]],
--~ 			XX = [[		<Property VOffset="%s"/>]],
--~ 			XX = [[		<Property VSize="%s"/>]],
	}

	local function CleanupMTL(mat, list, c)
		list = list or {}
		c = c or #list

		for key, value in pairs(mat) do
			if value == true then
				value = 1
			elseif value == false then
				value = 0
			end

			local mtl = mtl_lookup[key]
			if mtl then
				if channel_list[key] then
					if value ~= "" then
						c = c + 1
						list[c] = mtl:format(value, mat[key .. "Channel"])
					end
				else
					c = c + 1
					list[c] = mtl:format(value)
				end
			end

		end
		return list, c
	end

	local function RetEntityMTLFile(mat)
		local list = {[[<?xml version="1.0" encoding="UTF-8"?>
<Materials>
	<Material>]]}
		local c = #list

		-- build main first
		list, c = CleanupMTL(mat, list, c)
		c = c + 1
		list[c] = [[	</Material>]]

		-- add any sub materials
		for key, sub_mat in pairs(mat) do
			if type(key) == "string" and key:sub(1, 19) == "_sub_material_index" then
				c = c + 1
				list[c] = [[	<Material>]]
				list, c = CleanupMTL(sub_mat, list, c)
				c = c + 1
				list[c] = [[	</Material>]]
			end
		end

		c = c + 1
		list[c] = [[</Materials>]]

		return TableConcat(list, "\n")
	end
	ChoGGi.ComFuncs.RetEntityMTLFile = RetEntityMTLFile

	local function ExamineExportMat(ex_dlg, mat)
		ChoGGi.ComFuncs.OpenInMultiLineTextDlg{
			parent = ex_dlg,
			text = RetEntityMTLFile(mat),
			title = Strings[302535920001458--[[Material Properties]]] .. ": " .. mat.__mtl,
		}
	end

	local function RetEntityMats(entity, skip)
		-- some of these funcs can crash sm, so lets make sure it's valid
		if not skip and not IsValidEntity(entity) then
			return
		end

		local mats = {}
		local states = GetStates(entity) or ""
		for si = 1, #states do
			local state_str = states[si]
			local state = GetStateIdx(state_str)
			local num_lods = GetStateLODCount(entity, state) or 0
			for li = 1, num_lods do
				local mat_name = GetStateMaterial(entity, state, li - 1)
				local mat = GetMaterialProperties(mat_name, 0)

				-- add any sub materials
				local c = 1
				while true do
					local extra = GetMaterialProperties(mat_name, c)
					if not extra then
						break
					end
					mat["_sub_material_index" .. c] = extra
					c = c + 1
				end

				mat.__mtl = mat_name
				mat.__lod = li
				mat[1] = {
					ChoGGi_AddHyperLink = true,
					hint = Strings[302535920001174--[[Show an example .mtl file for this material (not complete).]]],
					name = Strings[302535920001177--[[Generate .mtl]]],
					func = function(ex_dlg)
						ExamineExportMat(ex_dlg, mat)
					end,
				}

				mats[mat_name .. ", LOD: " .. li .. ", State: " .. state_str .. " (" .. state .. ")"] = mat
			end
		end

		return mats
	end
	ChoGGi.ComFuncs.RetEntityMats = RetEntityMats

	function ChoGGi.ComFuncs.GetMaterialProperties(obj, parent_or_ret)
		if not UICity then
			return
		end

		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi.ComFuncs.SelObject()
			parent_or_ret = nil
		else
			obj = obj or ChoGGi.ComFuncs.SelObject()
		end

		local materials

		if IsValidEntity(obj) then
			materials = RetEntityMats(obj, true)
		else
			local entity = obj and obj.GetEntity and obj:GetEntity()
			if IsValidEntity(entity) then
				materials = RetEntityMats(entity, true)
			else
				materials = {}
				local EntityData = EntityData
				for entity in pairs(EntityData) do
					materials[entity] = RetEntityMats(entity, true)
				end
			end
		end


		if parent_or_ret == true then
			return materials
		else
			ChoGGi.ComFuncs.OpenInExamineDlg(materials, parent_or_ret, Strings[302535920001458--[[Material Properties]]])
		end

	end
end -- do

do -- DisplayObjectImages
	local CmpLower = CmpLower
	local getmetatable = getmetatable
	local images_table
	local ImageExts = ChoGGi.ComFuncs.ImageExts

	-- grab any strings with the correct ext
	local function AddToList(c, key, value)
		if type(value) == "string" and ImageExts()[value:sub(-3):lower()] then
			local dupe_test = key .. value

			if not images_table.dupes[dupe_test] then
				c = c + 1
				images_table[c] = {
					name = key,
					path = value,
				}
				images_table.dupes[dupe_test] = true
			end
		end
		return c
	end

	function ChoGGi.ComFuncs.DisplayObjectImages(obj, parent, images)
		images_table = images or {
			dupes = {},
		}
		if type(obj) ~= "table" then
			return #images_table > 0
		end
		local c = #images_table

		-- and images
		for key, value in pairs(obj) do
			c = AddToList(c, key, value)
		end
		-- any meta images
		local meta = getmetatable(obj)
		while meta do
			for key, value in pairs(meta) do
				c = AddToList(c, key, obj[key] or value)
			end
			meta = getmetatable(meta)
		end

		-- and sort
		if images_table[1] then
			ChoGGi.ComFuncs.TableCleanDupes(images_table)
			table_sort(images_table, function(a, b)
				return CmpLower(a.name, b.name)
			end)
			ChoGGi.ComFuncs.OpenInImageViewerDlg(images_table, parent)
			return true
		end
		return false

	end
end -- do

do -- BBoxLines_Toggle
	local point = point
	local objlist = objlist
	local IsBox = IsBox

	-- stores objlist of line objects
	local bbox_lines

	local function SpawnBoxLine(bbox, list, depth_test, colour)
		local line = PlacePolyline(list, colour)
		if depth_test then
			line:SetDepthTest(true)
		end
		line:SetPos(bbox:Center())
		bbox_lines[#bbox_lines+1] = line
	end
	local pillar_table = objlist:new()
	local function SpawnPillarLine(pt, z, obj_height, depth_test, colour)
		pillar_table:Destroy()
		pillar_table[1] = pt:SetZ(z)
		pillar_table[2] = pt:SetZ(z + obj_height)
		local line = PlacePolyline(pillar_table, colour)
		if depth_test then
			line:SetDepthTest(true)
		end
		line:SetPos(AveragePoint2D(line.vertices):SetZ(z))
		bbox_lines[#bbox_lines+1] = line
	end

	local function PlaceTerrainBox(bbox, pos, depth_test, colour)
		local obj_height = bbox:sizez() or 1500
		local z = pos:z()
		-- stores all line objs for deletion later
		bbox_lines = objlist:new()

		local edges = {bbox:ToPoints2D()}
		-- needed to complete the square (else there's a short blank space of a chunk of a line)
		edges[5] = edges[1]
		edges[6] = edges[2]

		-- we need a list of top/bottom box points
		local points_top, points_bot = {}, {}
		for i = 1, #edges - 1 do
			local edge = edges[i]
			if i < 5 then
				-- the four "pillars"
				SpawnPillarLine(edge, z, obj_height, depth_test, colour)
			end
			local x, y = edge:xy()
			points_top[#points_top + 1] = point(x, y, z + obj_height)
			points_bot[#points_bot + 1] = point(x, y, z)
		end
		SpawnBoxLine(bbox, points_top, depth_test, colour)
		SpawnBoxLine(bbox, points_bot, depth_test, colour)

		--[[
		-- make bbox follow ground height
		for i = 1, #edges - 1 do

			local pt1 = edges[i]
			local pt2 = edges[i + 1]
			local diff = pt2 - pt1
			local steps = Max(2, 1 + diff:Len2D() / step)

			for j = 1, steps do
				local pos = pt1 + MulDivRound(diff, j - 1, steps - 1)
				points_top[#points_top + 1] = pos:SetTerrainZ(offset + obj_height)
				points_bot[#points_bot + 1] = pos:SetTerrainZ(offset)
			end

			-- ... extra lines?
			-- this is what i get for not commenting it the first time.
			points_bot[#points_bot] = nil
			points_top[#points_top] = nil
		end

		SpawnBoxLine(bbox_lines, bbox, points_top, colour)
		SpawnBoxLine(bbox_lines, bbox, points_bot, colour)
		]]

		return bbox_lines
	end
	local function BBoxLines_Clear(obj, is_box)
		SuspendPassEdits("ChoGGi.ComFuncs.BBoxLines_Clear")
		if not is_box and obj.ChoGGi_bboxobj then
			obj.ChoGGi_bboxobj:Destroy()
			obj.ChoGGi_bboxobj = nil
			return true
		end
		ResumePassEdits("ChoGGi.ComFuncs.BBoxLines_Clear")
	end
	ChoGGi.ComFuncs.BBoxLines_Clear = BBoxLines_Clear

	function ChoGGi.ComFuncs.BBoxLines_Toggle(obj, params)
		params = params or {}
		obj = obj or ChoGGi.ComFuncs.SelObject()
		local is_box = IsBox(obj)

		if not (IsValid(obj) or is_box) or (BBoxLines_Clear(obj, is_box) and not params.skip_return) then
			return
		end

		local bbox = is_box and obj or params.bbox

		-- fallback to sel obj
		if not IsBox(bbox) then
			bbox = obj:GetObjectBBox()
		end

		if IsBox(bbox) then
			SuspendPassEdits("ChoGGi.ComFuncs.BBoxLines_Toggle")
			local box = PlaceTerrainBox(
				bbox,
				bbox:Center():SetTerrainZ(),
				params.depth_test,
				params.colour or RandomColourLimited()
			)
			ResumePassEdits("ChoGGi.ComFuncs.BBoxLines_Toggle")
			if not is_box then
				obj.ChoGGi_bboxobj = box
			end
			return box
		end
	end
end -- do

do -- SurfaceLines_Toggle
	local GetRelativeSurfaces = GetRelativeSurfaces

	local function BuildLines(obj, params)
		local surfs = params.surfs or GetRelativeSurfaces(obj, params.surface_mask or 0)
		local c = #obj.ChoGGi_surfacelinesobj

		for i = 1, #surfs do
			local group = surfs[i]
			-- connect the lines
			group[#group+1] = group[1]

			local line = PlacePolyline(group, params.colour)
			if params.depth_test then
				line:SetDepthTest(true)
			end
			line:SetPos(AveragePoint2D(line.vertices):SetZ(group[1]:z()+params.offset))
			c = c + 1
			obj.ChoGGi_surfacelinesobj[c] = line
		end

		return obj.ChoGGi_surfacelinesobj
	end

	local function SurfaceLines_Clear(obj)
		if type(obj) ~= "table" then
			return
		end
		SuspendPassEdits("ChoGGi.ComFuncs.SurfaceLines_Clear")
		if obj.ChoGGi_surfacelinesobj then
			obj.ChoGGi_surfacelinesobj:Destroy()
			obj.ChoGGi_surfacelinesobj = nil
			return true
		end
		ResumePassEdits("ChoGGi.ComFuncs.SurfaceLines_Clear")
	end
	ChoGGi.ComFuncs.SurfaceLines_Clear = SurfaceLines_Clear

	function ChoGGi.ComFuncs.SurfaceLines_Toggle(obj, params)

		params = params or {}
		local is_valid = IsValid(obj)
		if not is_valid or is_valid and not IsValidEntity(obj:GetEntity()) or not params.skip_return then
			return
		end
		if not params.skip_clear then
			if (SurfaceLines_Clear(obj) and not params.skip_return) then
				return
			end
		end

		obj.ChoGGi_surfacelinesobj = obj.ChoGGi_surfacelinesobj or objlist:new()

		params.colour = params.colour or RandomColourLimited()
		params.offset = params.offset or 1

		SuspendPassEdits("ChoGGi.ComFuncs.SurfaceLines_Toggle")
		BuildLines(obj, params)
		ResumePassEdits("ChoGGi.ComFuncs.SurfaceLines_Toggle")

		if not params.skip_clear then
			ChoGGi.ComFuncs.CleanInfoAttachDupes(obj.ChoGGi_surfacelinesobj)
		end
		return obj.ChoGGi_surfacelinesobj
	end
end -- do

function ChoGGi.ComFuncs.RetOriginSurfaces(obj, surf)
	-- collision (see also 5, 7)
	surf = surf or 0

	local surfs = GetRelativeSurfaces(obj, surf)
	local origin = obj:GetPos()
	for i = 1, #surfs do
		local pts = surfs[i]
		for j = 1, #pts do
			pts[j] = pts[j] - origin
		end
	end
	return surfs
end

function ChoGGi.ComFuncs.MoveObjToGround(obj)
	obj:SetZ(obj:GetPos():SetTerrainZ())
end

function ChoGGi.ComFuncs.GetDesktopWindow(class)
	local desktop = terminal.desktop
	return desktop[table_find(desktop, "class", class)]
end

do -- RetThreadInfo/FindThreadFunc
	local GedInspectorFormatObject = GedInspectorFormatObject
	local GedInspectedObjects_l

	local function DbgGetlocal(thread, level)
		local list = {}
		local idx = 1
		while true do
			local name, value = debug_getlocal(thread, level, idx)
			if name == nil then
				break
			end
			list[idx] = {
				name = name ~= "" and name or Strings[302535920000723--[[Lua]]],
				value = value,
				level = level,
			}
			idx = idx + 1
		end
		if next(list) then
			return list
		end
	end
	local function DbgGetupvalue(info)
		local list = {}
		local idx = 1
		while true do
			local name, value = debug_getupvalue(info.func, idx)
			if name == nil then
				break
			end
			list[idx] = {
				name = name ~= "" and name or Strings[302535920000723--[[Lua]]],
				value = value,
			}
			idx = idx + 1
		end
		if next(list) then
			return list
		end
	end

	-- returns some info if blacklist enabled
	function ChoGGi.ComFuncs.RetThreadInfo(thread)
		if type(thread) ~= "thread" then
			return empty_table
		end
		local funcs = {}

		if blacklist then
			GedInspectedObjects_l = GedInspectedObjects_l or GedInspectedObjects
			-- func expects a table
			if GedInspectedObjects_l[thread] then
				table_clear(GedInspectedObjects_l[thread])
			else
				GedInspectedObjects_l[thread] = {}
			end
			-- returns a table of the funcs in the thread
			local threads = GedInspectorFormatObject(thread).members
			-- build a list of func name / level
			for i = 1, #threads do
				-- why'd i add the "= false"?
				local temp = {level = false, func = false, name = false}

				local t = threads[i]
				for key, value in pairs(t) do
					if key == "key" then
						temp.level = value
					elseif key == "value" then
						-- split "func(line num) name" into two
						local space = value:find(") ", 1, true)
						temp.func = value:sub(2, space)
						-- change unknown to Lua
						local n = value:sub(space + 2, -2)
						temp.name = n ~= "unknown name" and n or Strings[302535920000723--[[Lua]]]
					end
				end

				funcs[i] = temp
			end

		else
			funcs.gethook = debug_gethook(thread)

			local info = debug_getinfo(thread, 0, "Slfunt")
			if info then
				local nups = info.nups
				if nups > 0 then
					-- we start info at 0, nups starts at 1
					nups = nups + 1

					for i = 0, nups do
						local info_got = debug_getinfo(thread, i)
						if info_got then
							local name = info_got.name or info_got.what or Strings[302535920000723--[[Lua]]]
							funcs[i] = {
								name = name,
								func = info_got.func,
								level = i,
								getlocal = DbgGetlocal(thread, i),
								getupvalue = DbgGetupvalue(info_got),
							}
						end
					end
				end
			end
		end

		return funcs
	end

	-- find/return func if str in func name
	function ChoGGi.ComFuncs.FindThreadFunc(thread, str)
		-- needs an empty table to work it's magic
		GedInspectedObjects[thread] = {}
		-- returns a table of the funcs in the thread
		local threads = GedInspectorFormatObject(thread).members
		for i = 1, #threads do
			for key, value in pairs(threads[i]) do
				if key == "value" and value:find_lower(str, 1, true) then
					return value
				end
			end
		end
	end

end -- do

do -- DebugGetInfo
	local format_value = format_value

	-- this replaces the func added in my library mod (which is just a straight format_value)
	function ChoGGi.ComFuncs.DebugGetInfo(obj)
		if blacklist then
			return format_value(obj)
		else
			local info = debug_getinfo(obj)
			-- sub(2): removes @, Mars is ingame files, mods is mods...
			local src = info.source ~= "" and info.source or info.short_src
			return src:sub(2):gsub("Mars/", ""):gsub("AppData/Mods/", "")
				.. "(" .. info.linedefined .. ")"
		end
	end
end -- do

do -- RetSourceFile
	local FileExists = ChoGGi.ComFuncs.FileExists
	local AsyncFileToString = AsyncFileToString
	local source_path = "AppData/Source/"

	function ChoGGi.ComFuncs.RetSourceFile(path)
		if blacklist then
			ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.RetSourceFile")
			return
		end
--[[
source: '@CommonLua/PropertyObject.lua'
~PropertyObject.Clone
source: '@Mars/Lua/LifeSupportGrid.lua'
~WaterGrid.RemoveElement
source: '@Mars/Dlc/gagarin/Code/RCConstructor.lua'
~RCConstructor.CanInteractWithObject

~ChoGGi.ComFuncs.RetSourceFile
]]
		-- remove @
		local at = path:sub(1, 1)
		if at == "@" then
			path = path:sub(2)
		end

		local err, code
		-- mods (we need to skip CommonLua else it'll open the luac file)
		local comlua = path:sub(1, 10)
		if comlua ~= "CommonLua/" and FileExists(path) then
			err, code = AsyncFileToString(path)
			if not err then
				return code, path
			end
		end

		-- might as well return commonlua/dlc files...
		if path:sub(1, 5) == "Mars/" then
			path = source_path .. path:sub(6)
			err, code = AsyncFileToString(path)
			if not err then
				return code, path
			end
		elseif comlua == "CommonLua/" then
			path = source_path .. path
			err, code = AsyncFileToString(path)
			if not err then
				return code, path
			end
		end

		return nil, (err and err .. "\n" or "") .. path

	end
end -- do

function ChoGGi.ComFuncs.RetSurfaceMasks(obj)

	if not IsValid(obj) then
		return
	end

	local list = {}

	local entity = obj:GetEntity()
	if not IsValidEntity(entity) then
		return list
	end

	local GetEntityNumSurfaces = GetEntityNumSurfaces

	local EntitySurfaces = EntitySurfaces
	for key, value in pairs(EntitySurfaces) do
		local surfs = GetEntityNumSurfaces(entity, value)
		local surf_bool = obj:HasAnySurfaces(value)

		if surfs > 0 then
			list[key .. " (mask: " .. value .. ", surfaces count: " .. surfs .. ")"] = surf_bool
		else
			list[key .. " (mask: " .. value .. ")"] = surf_bool
		end
	end
	return list
end

do -- ReturnTechAmount/GetResearchedTechValue
	local floatfloor = floatfloor
	--[[
	ReturnTechAmount(tech, prop)
	returns number from Object (so you know how much it changes)
	see: Data/Object.lua, or ex(Object)

	ReturnTechAmount("GeneralTraining", "NonSpecialistPerformancePenalty")
	^returns 10
	ReturnTechAmount("SupportiveCommunity", "LowSanityNegativeTraitChance")
	^ returns 0.7

	it returns percentages in decimal for ease of mathing (SM has no math. funcs)
	ie: SupportiveCommunity is -70 this returns it as 0.7
	it also returns negative amounts as positive (I prefer num - Amt, not num + NegAmt)
	]]
	local function ReturnTechAmount(tech, prop)
		local techdef = TechDef[tech]
		local idx = table_find(techdef, "Prop", prop)
		if idx then
			tech = techdef[idx]
			local number

			-- With enemies you know where they stand but with Neutrals, who knows?
			-- defaults for the objects have both percent/amount, so whoever isn't 0 means something
			if tech.Percent == 0 then
				if tech.Amount < 0 then
					number = tech.Amount * -1 -- always gotta be positive
				else
					number = tech.Amount
				end
			-- probably just have an else here instead...
			elseif tech.Amount == 0 then
				if tech.Percent < 0 then
					tech.Percent = tech.Percent * -1 -- -50 > 50
				end
				number = (tech.Percent + 0.0) / 100 -- (50 > 50.0) > 0.50
			end

			return number
		end
	end
	ChoGGi.ComFuncs.ReturnTechAmount = ReturnTechAmount

	function ChoGGi.ComFuncs.GetResearchedTechValue(name, cls)
		local ChoGGi_Consts = ChoGGi.Consts
		local UICity = UICity

		-- cls
		if name == "RCTransportStorageCapacity" then
			local amount = cls == "RCConstructor" and ChoGGi_Consts.RCConstructorStorageCapacity or ChoGGi_Consts.RCTransportStorageCapacity

			if UICity:IsTechResearched("TransportOptimization") then
				local a = ReturnTechAmount("TransportOptimization", "max_shared_storage")
				return amount + (a * const.ResourceScale)
			end
			return amount
		end

		--
		if name == "DroneBatteryMax" then
			if UICity:IsTechResearched("BatteryOptimization") then
				local p = ReturnTechAmount("BatteryOptimization", "battery_max")
				return floatfloor(ChoGGi_Consts.DroneBatteryMax + (ChoGGi_Consts.DroneBatteryMax * p))
			end
			return ChoGGi_Consts.DroneBatteryMax
		end
		--
		if name == "SpeedDrone" then
			local move_speed = ChoGGi_Consts.SpeedDrone

			if UICity:IsTechResearched("LowGDrive") then
				local p = ReturnTechAmount("LowGDrive", "move_speed")
				move_speed = move_speed + (move_speed * p)
			end
			if UICity:IsTechResearched("AdvancedDroneDrive") then
				local p = ReturnTechAmount("AdvancedDroneDrive", "move_speed")
				move_speed = move_speed + (move_speed * p)
			end
			return floatfloor(move_speed)
		end
		--
		if name == "MaxColonistsPerRocket" then
			local per_rocket = ChoGGi_Consts.MaxColonistsPerRocket
			if UICity:IsTechResearched("CompactPassengerModule") then
				local a = ReturnTechAmount("CompactPassengerModule", "MaxColonistsPerRocket")
				per_rocket = per_rocket + a
			end
			if UICity:IsTechResearched("CryoSleep") then
				local a = ReturnTechAmount("CryoSleep", "MaxColonistsPerRocket")
				per_rocket = per_rocket + a
			end
			return per_rocket
		end
		--
		if name == "FuelRocket" then
			if UICity:IsTechResearched("AdvancedMartianEngines") then
				local a = ReturnTechAmount("AdvancedMartianEngines", "launch_fuel")
				return ChoGGi_Consts.LaunchFuelPerRocket - (a * const.ResourceScale)
			end
			return ChoGGi_Consts.LaunchFuelPerRocket
		end
		--
		if name == "SpeedRC" then
			if UICity:IsTechResearched("LowGDrive") then
				local p = ReturnTechAmount("LowGDrive", "move_speed")
				return floatfloor(ChoGGi_Consts.SpeedRC + (ChoGGi_Consts.SpeedRC * p))
			end
			return ChoGGi_Consts.SpeedRC
		end
		--
		if name == "CargoCapacity" then
			if UICity:IsTechResearched("FuelCompression") then
				local a = ReturnTechAmount("FuelCompression", "CargoCapacity")
				return ChoGGi_Consts.CargoCapacity + a
			end
			return ChoGGi_Consts.CargoCapacity
		end
		--
		if name == "CommandCenterMaxDrones" then
			if UICity:IsTechResearched("DroneSwarm") then
				local a = ReturnTechAmount("DroneSwarm", "CommandCenterMaxDrones")
				return ChoGGi_Consts.CommandCenterMaxDrones + a
			end
			return ChoGGi_Consts.CommandCenterMaxDrones
		end
		--
		if name == "DroneResourceCarryAmount" then
			if UICity:IsTechResearched("ArtificialMuscles") then
				local a = ReturnTechAmount("ArtificialMuscles", "DroneResourceCarryAmount")
				return ChoGGi_Consts.DroneResourceCarryAmount + a
			end
			return ChoGGi_Consts.DroneResourceCarryAmount
		end
		--
		if name == "LowSanityNegativeTraitChance" then
			if UICity:IsTechResearched("SupportiveCommunity") then
				local p = ReturnTechAmount("SupportiveCommunity", "LowSanityNegativeTraitChance")
				--[[
				LowSanityNegativeTraitChance = 30%
				SupportiveCommunity = -70%
				]]
				local LowSan = ChoGGi_Consts.LowSanityNegativeTraitChance + 0.0 --SM has no math.funcs so + 0.0
				return floatfloor((p * LowSan) / (100 * 100))
			end
			return ChoGGi_Consts.LowSanityNegativeTraitChance
		end
		--
		if name == "NonSpecialistPerformancePenalty" then
			if UICity:IsTechResearched("GeneralTraining") then
				local a = ReturnTechAmount("GeneralTraining", "NonSpecialistPerformancePenalty")
				return ChoGGi_Consts.NonSpecialistPerformancePenalty - a
			end
			return ChoGGi_Consts.NonSpecialistPerformancePenalty
		end
		--
		if name == "RCRoverMaxDrones" then
			if UICity:IsTechResearched("RoverCommandAI") then
				local a = ReturnTechAmount("RoverCommandAI", "RCRoverMaxDrones")
				return ChoGGi_Consts.RCRoverMaxDrones + a
			end
			return ChoGGi_Consts.RCRoverMaxDrones
		end
		--
		if name == "RCTransportGatherResourceWorkTime" then
			if UICity:IsTechResearched("TransportOptimization") then
				local p = ReturnTechAmount("TransportOptimization", "RCTransportGatherResourceWorkTime")
				return floatfloor(ChoGGi_Consts.RCTransportGatherResourceWorkTime * p)
			end
			return ChoGGi_Consts.RCTransportGatherResourceWorkTime
		end
		--
		if name == "TravelTimeEarthMars" then
			if UICity:IsTechResearched("PlasmaRocket") then
				local p = ReturnTechAmount("PlasmaRocket", "TravelTimeEarthMars")
				return floatfloor(ChoGGi_Consts.TravelTimeEarthMars * p)
			end
			return ChoGGi_Consts.TravelTimeEarthMars
		end
		--
		if name == "TravelTimeMarsEarth" then
			if UICity:IsTechResearched("PlasmaRocket") then
				local p = ReturnTechAmount("PlasmaRocket", "TravelTimeMarsEarth")
				return floatfloor(ChoGGi_Consts.TravelTimeMarsEarth * p)
			end
			return ChoGGi_Consts.TravelTimeMarsEarth
		end

	end
end -- do

function ChoGGi.ComFuncs.RetBuildingPermissions(traits, settings)
	settings.restricttraits = settings.restricttraits or {}
	settings.blocktraits = settings.blocktraits or {}
	traits = traits or {}
	local block, restrict

	local rtotal = 0
	for _ in pairs(settings.restricttraits) do
		rtotal = rtotal + 1
	end

	local rcount = 0
	for trait in pairs(traits) do
		if settings.restricttraits[trait] then
			rcount = rcount + 1
		end
		if settings.blocktraits[trait] then
			block = true
		end
	end

	-- restrict is empty so allow all or since we're restricting then they need to be the same
	if not next(settings.restricttraits) or rcount == rtotal then
		restrict = true
	end

	return block, restrict
end

do -- EntitySpots_Toggle
	local GetSpotNameByType = GetSpotNameByType
	local old_remove_table = {"ChoGGi_OText", "ChoGGi_OOrientation"}
	local OText, OPolyline

	local function EntitySpots_Clear(obj)
		if type(obj) ~= "table" then
			return
		end
		SuspendPassEdits("ChoGGi.ComFuncs.EntitySpots_Clear")
		-- just in case (old way of doing it)
		if obj.ChoGGi_ShowAttachSpots == true then
			local DoneObject = DoneObject
			obj:DestroyAttaches(old_remove_table, function(a)
				if a.ChoGGi_ShowAttachSpots then
					DoneObject(a)
				end
			end)
			obj.ChoGGi_ShowAttachSpots = nil
			return true
		elseif obj.ChoGGi_ShowAttachSpots then
			obj.ChoGGi_ShowAttachSpots:Destroy()
			obj.ChoGGi_ShowAttachSpots = nil
			return true
		end
		ResumePassEdits("ChoGGi.ComFuncs.EntitySpots_Clear")
	end
	ChoGGi.ComFuncs.EntitySpots_Clear = EntitySpots_Clear

	local function EntitySpots_Add(obj, spot_type, annot, depth_test, show_pos, colour)
		local c = #obj.ChoGGi_ShowAttachSpots
		local obj_pos = obj:GetVisualPos()
		local start_id, id_end = obj:GetAllSpots(obj:GetState())
		for i = start_id, id_end do
			local spot_name = GetSpotNameByType(obj:GetSpotsType(i)) or ""
			if not spot_type or spot_name == spot_type then
				local spot_annot = obj:GetSpotAnnotation(i) or ""
				-- If it's a chain then we need to check for "annot, " so chain=2 doesn't include chain=20
				local chain = annot and annot:find("chain")
--~ printC(spot_type, "|", spot_annot, "|", annot, "|", chain, "|", spot_annot:sub(1, #annot+1) == annot .. ", ")
				if not annot or annot and (chain and spot_annot:sub(1, #annot+1) == annot .. ","
						or not chain and spot_annot:sub(1, #annot) == annot) then

					local text_str = obj:GetSpotName(i)
					text_str = i .. "." .. text_str
					if spot_annot ~= "" then
						text_str = text_str .. ";" .. spot_annot
					end
					if show_pos then
						text_str = text_str .. " " .. tostring(obj:GetSpotPos(i) - obj_pos)
					end

					local text_obj = OText:new()
					if depth_test then
						text_obj:SetDepthTest(true)
					end
					text_obj:SetText(text_str)
					text_obj:SetColor1(colour)
					obj:Attach(text_obj, i)
					c = c + 1
					obj.ChoGGi_ShowAttachSpots[c] = text_obj

					-- append waypoint num for chains later on
					-- need to reverse string so it finds the last =, since find looks ltr
					local equal = spot_annot:reverse():find("=")
					if equal then
						-- we need a neg number for sub + 1 to remove the slash
						text_obj.order = tonumber(spot_annot:sub((equal * -1) + 1))
					end

				end
			end
		end -- for
	end

	local function EntitySpots_Add_Annot(obj, depth_test, colour)
		local chain_c = 0
		local points = {}
		for i = 1, #obj.ChoGGi_ShowAttachSpots do
			local text = obj.ChoGGi_ShowAttachSpots[i]
			-- use order from above to sort by waypoint number
			if text.order then
				chain_c = chain_c + 1
				points[text.order] = text:GetPos()
			end
		end
		-- some stuff has order nums in another spotname?, (the door path for the diner)
		for i = 1, chain_c do
			if not points[i] then
				if points[i+1] then
					points[i] = points[i+1]
				elseif points[i-1] then
					points[i] = points[i-1]
				end
			end
		end

		if chain_c > 0 then
			local line_obj = OPolyline:new()
			if depth_test then
				line_obj:SetDepthTest(true)
			end
			line_obj.max_vertices = #points
			line_obj:SetMesh(points, colour)
			line_obj:SetPos(AveragePoint2D(points))

			obj.ChoGGi_ShowAttachSpots[#obj.ChoGGi_ShowAttachSpots + 1] = line_obj
		end

	end

	function ChoGGi.ComFuncs.EntitySpots_Toggle(obj, params)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi.ComFuncs.SelObject()
			params = {}
		else
			obj = obj or ChoGGi.ComFuncs.SelObject()
		end

		params = params or {}
		local is_valid = IsValid(obj)
		local entity = obj and obj.GetEntity and obj:GetEntity()
		if not (is_valid or IsValidEntity(entity) or params.skip_return) then
			return
		end
		if not params.skip_clear then
			if EntitySpots_Clear(obj) and not params.skip_return then
				return
			end
		end

		obj.ChoGGi_ShowAttachSpots = obj.ChoGGi_ShowAttachSpots or objlist:new()

		params.colour = params.colour or RandomColourLimited()

		if not OPolyline then
			OPolyline = ChoGGi_OPolyline
		end
		if not OText then
			OText = ChoGGi_OText
		end
		SuspendPassEdits("ChoGGi.ComFuncs.EntitySpots_Add")
		EntitySpots_Add(obj,
			params.spot_type,
			params.annotation,
			params.depth_test,
			params.show_pos,
			params.colour
		)
		ResumePassEdits("ChoGGi.ComFuncs.EntitySpots_Add")

		if not params.skip_clear then
			ChoGGi.ComFuncs.CleanInfoAttachDupes(obj.ChoGGi_ShowAttachSpots, "ChoGGi_OText")
		end

		-- play connect the dots if there's chains
		if obj.ChoGGi_ShowAttachSpots[2] and params.annotation and params.annotation:find("chain") then
			SuspendPassEdits("ChoGGi.ComFuncs.EntitySpots_Add_Annot")
			EntitySpots_Add_Annot(obj, params.depth_test, RandomColourLimited())
			ResumePassEdits("ChoGGi.ComFuncs.EntitySpots_Add_Annot")
		end

		if not params.skip_clear then
			ChoGGi.ComFuncs.CleanInfoAttachDupes(obj.ChoGGi_ShowAttachSpots, "ChoGGi_OPolyline")
		end

		return obj.ChoGGi_ShowAttachSpots

	end
end -- do

do -- ShowAnimDebug_Toggle
	local OText

	local function AnimDebug_Show(obj, colour)
		local text = OText:new()
		text:SetColor1(colour)

		-- so we can delete them easy
		text.ChoGGi_AnimDebug = true
		obj:Attach(text, 0)

		local obj_bbox = obj:GetObjectBBox():sizez()

		text:SetAttachOffset(point(0, 0, obj_bbox + 100))
		CreateGameTimeThread(function()
			while IsValid(text) do
				text:SetText(obj:GetAnimDebug())
				WaitNextFrame()
			end
		end)
	end

	local function AnimDebug_Hide(obj)
		obj:ForEachAttach("ChoGGi_OText", function(a)
			if a.ChoGGi_AnimDebug then
				DoneObject(a)
			end
		end)
	end

	local function AnimDebug_ShowAll(cls, colour)
		local objs = ChoGGi.ComFuncs.MapGet(cls)
		for i = 1, #objs do
			AnimDebug_Show(objs[i], colour)
		end
	end

	local function AnimDebug_HideAll(cls)
		local objs = ChoGGi.ComFuncs.MapGet(cls)
		for i = 1, #objs do
			AnimDebug_Hide(objs[i])
		end
	end

	function ChoGGi.ComFuncs.ShowAnimDebug_Toggle(obj, params)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi.ComFuncs.SelObject()
		else
			obj = obj or ChoGGi.ComFuncs.SelObject()
		end
		if not OText then
			OText = ChoGGi_OText
		end
		params = params or {}
		params.colour = params.colour or RandomColourLimited()

		SuspendPassEdits("ChoGGi.ComFuncs.ShowAnimDebug_Toggle")
		if IsValid(obj) then
			if not obj:GetAnimDebug() then
				return
			end

			if obj.ChoGGi_ShowAnimDebug then
				obj.ChoGGi_ShowAnimDebug = nil
				AnimDebug_Hide(obj)
			else
				obj.ChoGGi_ShowAnimDebug = true
				AnimDebug_Show(obj, params.colour)
			end
		else
			ChoGGi.Temp.ShowAnimDebug = not ChoGGi.Temp.ShowAnimDebug
			if ChoGGi.Temp.ShowAnimDebug then
				AnimDebug_ShowAll("Building", params.colour)
				AnimDebug_ShowAll("Unit", params.colour)
				AnimDebug_ShowAll("CargoShuttle", params.colour)
			else
				AnimDebug_HideAll("Building")
				AnimDebug_HideAll("Unit")
				AnimDebug_HideAll("CargoShuttle")
			end
		end
		ResumePassEdits("ChoGGi.ComFuncs.ShowAnimDebug_Toggle")
	end
end -- do

do -- ChangeSurfaceSignsToMaterials
	local function ChangeEntity(cls, entity, random)
		MapForEach("map", cls, function(o)
			if random then
				o:ChangeEntity(entity .. Random(1, random))
			else
				o:ChangeEntity(entity)
			end
		end)
	end
	local function ResetEntity(cls)
		local entity = g_Classes[cls]:GetDefaultPropertyValue("entity")
		MapForEach("map", cls, function(o)
			o:ChangeEntity(entity)
		end)
	end

	function ChoGGi.ComFuncs.ChangeSurfaceSignsToMaterials()

		local item_list = {
			{text = Translate(754117323318--[[Enable]]), value = true, hint = Strings[302535920001081--[[Changes signs to materials.]]]},
			{text = Translate(251103844022--[[Disable]]), value = false, hint = Strings[302535920001082--[[Changes materials to signs.]]]},
		}

		local function CallBackFunc(choice)
			if choice.nothing_selected then
				return
			end
			SuspendPassEdits("ChoGGi.ComFuncs.ChangeSurfaceSignsToMaterials")
			if choice[1].value then
				ChangeEntity("SubsurfaceDepositWater", "DecSpider_01")
				ChangeEntity("SubsurfaceDepositMetals", "DecDebris_01")
				ChangeEntity("SubsurfaceDepositPreciousMetals", "DecSurfaceDepositConcrete_01")
				ChangeEntity("TerrainDepositConcrete", "DecDustDevils_0", 5)
				ChangeEntity("SubsurfaceAnomaly", "DebrisConcrete")
				ChangeEntity("SubsurfaceAnomaly_unlock", "DebrisMetal")
				ChangeEntity("SubsurfaceAnomaly_breakthrough", "DebrisPolymer")
			else
				ResetEntity("SubsurfaceDepositWater")
				ResetEntity("SubsurfaceDepositMetals")
				ResetEntity("SubsurfaceDepositPreciousMetals")
				ResetEntity("TerrainDepositConcrete")
				ResetEntity("SubsurfaceAnomaly")
				ResetEntity("SubsurfaceAnomaly_unlock")
				ResetEntity("SubsurfaceAnomaly_breakthrough")
				ResetEntity("SubsurfaceAnomaly_aliens")
				ResetEntity("SubsurfaceAnomaly_complete")
			end
			ResumePassEdits("ChoGGi.ComFuncs.ChangeSurfaceSignsToMaterials")
		end

		ChoGGi.ComFuncs.OpenInListChoice{
			callback = CallBackFunc,
			items = item_list,
			title = Strings[302535920001083--[[Change Surface Signs]]],
		}
	end
end -- do

function ChoGGi.ComFuncs.UpdateServiceComfortBld(obj, service_stats)
	if not obj or not service_stats then
		return
	end

	-- check for type as some are boolean
	if type(service_stats.health_change) ~= "nil" then
		obj:SetBase("health_change", service_stats.health_change)
	end
	if type(service_stats.sanity_change) ~= "nil" then
		obj:SetBase("sanity_change", service_stats.sanity_change)
	end
	if type(service_stats.service_comfort) ~= "nil" then
		obj:SetBase("service_comfort", service_stats.service_comfort)
	end
	if type(service_stats.comfort_increase) ~= "nil" then
		obj:SetBase("comfort_increase", service_stats.comfort_increase)
	end

	if obj:IsKindOf("Service") then
		if type(service_stats.visit_duration) ~= "nil" then
			obj:SetBase("visit_duration", service_stats.visit_duration)
		end
		if type(service_stats.usable_by_children) ~= "nil" then
			obj.usable_by_children = service_stats.usable_by_children
		end
		if type(service_stats.children_only) ~= "nil" then
			obj.children_only = service_stats.children_only
		end
		for i = 1, 11 do
			local name = "interest" .. i
			if service_stats[name] ~= "" and type(service_stats[name]) ~= "nil" then
				obj[name] = service_stats[name]
			end
		end
	end

end

function ChoGGi.ComFuncs.BlacklistMsg(msg)
	msg = Strings[302535920000242--[[%s is blocked by SM function blacklist; use ECM HelperMod to bypass or tell the devs that ECM is awesome and it should have �ber access.]]]:format(msg)
	MsgPopup(msg,Strings[302535920000000--[[Expanded Cheat Menu]]])
	print(msg)
end

do -- ToggleFuncHook
	-- counts funcs calls, and keeps a table of func|line num
	local func_table = {}
	function ChoGGi.ComFuncs.ToggleFuncHook(path, line, mask, count)
		if blacklist then
			ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.ToggleFuncHook")
			return
		end

		if not ChoGGi.Temp.FunctionsHooked then
			ChoGGi.Temp.FunctionsHooked = true
			-- always start fresh
			table_clear(func_table)
			-- setup path
			path = path or "@AppData/Mods/"
			local str_len = #path

			print(Strings[302535920000497--[[Hook Started]]], path, line, mask, count)
			MsgPopup(Strings[302535920000497--[[Hook Started]]], T(1000113, "Debug"))

			collectgarbage()
			local function hook_func(event)

				local i
				if event == "call" then
					i = debug_getinfo(2, "Sf")
				else
					i = debug_getinfo(2, "S")
				end

				if i.source:sub(1, str_len) == path and (not line or line and i.linedefined == line) then

					local lua_obj
					if event == "call" then
						lua_obj = i.func
					else
						lua_obj = i.source .. "|" .. i.linedefined
					end

					local c = func_table[lua_obj] or 1
					func_table[lua_obj] = c + 1
				end
			end
			-- start capture (c = func call, r = func ret, l = enters new line of code)
			debug.sethook(hook_func, mask or "c", count)
		else
			print(Strings[302535920000498--[[Hook Stopped]]], path, line, mask, count)
			MsgPopup(Strings[302535920000498--[[Hook Stopped]]], T(1000113, "Debug"))
			ChoGGi.Temp.FunctionsHooked = false

			-- stop capture
			debug.sethook()
			-- view the results
			ChoGGi.ComFuncs.OpenInExamineDlg(func_table, nil, "Func call count (" .. #func_table .. ")")
		end
	end
end -- do

do -- PrintToFunc_Add/PrintToFunc_Remove
	local ValueToLuaCode = ValueToLuaCode
	local rawset = rawset

	function ChoGGi.ComFuncs.PrintToFunc_Remove(name, parent)
		name = tostring(name)
		local saved_name = name .. "_ChoGGi_savedfunc"

		local saved = parent[saved_name]
		if saved then
			parent[name] = parent[saved_name]
			parent[saved_name] = nil
		end

	end

	function ChoGGi.ComFuncs.PrintToFunc_Add(func, name, parent, func_name, params)
		name = tostring(name)
		local saved_name = name .. "_ChoGGi_savedfunc"

		-- move orig to saved name (if it hasn't already been)
		local saved
		if parent == _G then
			-- SM error spams console if you have the affront to try _G.NonExistingKey... (thanks autorun.lua)
			-- It works prefectly fine of course, but i like a clean log.
			-- In other words a workaround for "Attempt to use an undefined global '"
			saved = rawget(parent, saved_name)
			if not saved then
				rawset(parent, saved_name, func)
				saved = func
			end
		else
			saved = parent[saved_name]
			if not saved then
				parent[saved_name] = func
				saved = func
			end
		end

		local text_table = {}
		local cls_obj = g_Classes[parent.class]

		-- and replace the func reference
		parent[name] = function(...)
			if params then
				table_iclear(text_table)
				local c = 0

				local varargs = {...}
				for i = 1, #varargs do
					local arg = varargs[i]
					c = c + 1
					text_table[c] = "arg "
					c = c + 1
					text_table[c] = i
					c = c + 1
					text_table[c] = ": "

					-- If it's a cls obj the first arg is always the cls obj
					if i == 1 and cls_obj then
						c = c + 1
						text_table[c] = tostring(arg)
						c = c + 1
						text_table[c] = " ("
						c = c + 1
						text_table[c] = RetName(arg)
						c = c + 1
						text_table[c] = ")"
					else
						c = c + 1
						text_table[c] = ValueToLuaCode(arg)
					end

					c = c + 1
					text_table[c] = "\n "
				end
				print(func_name, "\n", TableConcat(text_table))
			else
				-- no params
				print(func_name)
			end
			return saved(...)
		end

	end

end -- do

do -- TestLocaleFile
--~ ChoGGi.ComFuncs.TestLocaleFile(Mods["bMPAkJP"].env.CurrentModPath .. "Locale/TraduzioneItaliano.csv", true)
	local my_locale = ChoGGi.library_path .. "Locales/English.csv"
	local csv_load_fields = {
		"id",
		"text",
		"translated",
		"translated_new",
		"gender"
	}

	local strings_failed, csv_failed
	local strings_count, csv_count

	local function ProcessLoadedTables(loaded_csv, language, out_table, out_gendertable)
		local order
		if language == "English" then
			order = {"translated_new", "text", "translated"}
		else
			order = {"translated_new", "translated", "text"}
		end

		local prev_str = Translate(1000231--[[Previous]])
		local next_str = Translate(1000232--[[Next]])
		local cur_str = Strings[302535920000106--[[Current]]]

		for i = 1, #loaded_csv do
			local entry = loaded_csv[i]

			local translation
			local ord1, ord2 = entry[order[1]], entry[order[2]]
			if ord1 and ord1 ~= "" then
				translation = ord1
			elseif ord2 and ord2 ~= "" then
				translation = ord2
			else
				translation = entry[order[3]]
			end

			local id = tonumber(entry.id)

			if id and translation then
				out_table[id] = translation
				if out_gendertable then
					out_gendertable[id] = entry.gender
				end
			else
				strings_count = strings_count + 1
				strings_failed[strings_count] = {
					name = "index: " .. i,
					[cur_str .. " id"] = entry.id,
					[cur_str .. " text"] = entry.text,
					[cur_str .. " translated_new"] = entry.translated_new,
					[cur_str .. " translated"] = entry.translated,
				}
				-- add some context
				local eprev = loaded_csv[i-1]
				local enext = loaded_csv[i+1]
				local str = strings_failed[strings_count]
				if eprev then
					str[prev_str .. " id"] = eprev.id
					str[prev_str .. " text"] = eprev.text
					str[prev_str .. " translated_new"] = eprev.translated_new
					str[prev_str .. " translated"] = eprev.translated
				end
				if enext then
					str[next_str .. " id"] = enext.id
					str[next_str .. " text"] = enext.text
					str[next_str .. " translated_new"] = enext.translated_new
					str[next_str .. " translated"] = enext.translated
				end

			end
		end
	end

	local function TestCSV(filepath, column_limit)
		column_limit = filepath == my_locale and 4 or column_limit
		if not column_limit or column_limit == true or type(column_limit) ~= "number" then
			column_limit = 5
		end

		-- this is the LoadCSV func from CommonLua/Core/ParseCSV.lua with some DebugPrint added
		local omit_captions = "omit_captions"
		local err, str = AsyncFileToString(filepath)
		if err then
			print(Strings[302535920001125--[[Test Locale File]]], "ERROR:", err, "FILEPATH:", filepath)
			return
		end

		local rows, pos = {}, 1
		local rows_c = 0
		local Q = lpeg.P("\"")
		local quoted_value = Q * lpeg.Cs((1 - Q + Q * Q / "\"") ^ 0) * Q
		local raw_value = lpeg.C((1 - lpeg.S(", \t\r\n\"")) ^ 0)
		local field = (lpeg.P(" ") ^ 0 * quoted_value * lpeg.P(" ") ^ 0 + raw_value) * lpeg.Cp()
		local RemoveTrailingSpaces = RemoveTrailingSpaces

		-- remove any carr returns
		str = str:gsub("\r\n", "\n")
		local str_len = #str

		-- mostly LoadCSV()
		while pos < str_len do
			local row, col = {}, 1
			local lf = str:sub(pos, pos) == "\n"
--~ 				local crlf = str:sub(pos, pos + 1) == "\r\n"

--~ 				while pos < str_len and not lf and not crlf do
			while pos < str_len and not lf do

				local value, nextv = field:match(str, pos)
				value = RemoveTrailingSpaces(value)
				local f_remap_col = csv_load_fields[col]
				if f_remap_col then
					row[f_remap_col] = value
				end
				col = col + 1
				lf = str:sub(nextv, nextv) == "\n"
--~ 					crlf = str:sub(nextv, nextv + 1) == "\r\n"
				pos = nextv + 1

				-- only seems to happen on bad things
				if col > column_limit then
					csv_count = csv_count + 1
					csv_failed[csv_count] = {
						name = "ERROR row: " .. row.id,
						value = value,
						string_pos = pos,
						column = col,
						general_area = str:sub(pos-50, pos+50),
						row_gender = row.gender,
						row_text = row.text,
						row_id = row.id,
						row_translated = row.translated,
						row_translated_new = row.translated_new,
					}
				end

				-- stop inf loop from malformed csv
				if pos >= str_len then
					break
				end
			end -- while inner

--~ 				if crlf then
			if lf then
				pos = pos + 1
			end

			if not omit_captions then
				rows_c = rows_c + 1
				rows[rows_c] = row
			end
			omit_captions = false

			-- stop inf loop from malformed csv
			if pos >= str_len and not lf then
--~ 				if pos >= str_len and not crlf then
				break
			end
		end -- while outer

		return csv_failed, rows
	end

	function ChoGGi.ComFuncs.TestLocaleFile(filepath, test_csv, language)
		if not filepath then
			if testing then
				local locale_path = ChoGGi.library_path .. "Locales/" .. ChoGGi.lang .. ".csv"
				if ChoGGi.ComFuncs.FileExists(locale_path) then
					filepath = locale_path
				else
					filepath = my_locale
				end
			else
				print(Strings[302535920001125--[[Test Locale File]]], "FILEPATH ERROR:", filepath)
				return
			end
		end

		-- always reset to 0 for reporting (csv_count > 0)
		csv_count = 0
		csv_failed = {}
		local loaded_csv
		if test_csv then
			if blacklist then
				ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.TestLocaleFile(test_csv)")
			else
				test_csv, loaded_csv = TestCSV(filepath, test_csv)
			end
		end

		-- my TestCSV is the same as LoadCSV, but without an inf loop if it's a malformed csv file
		-- so we skip it for test_csv
		if not loaded_csv then
			loaded_csv = {}
			LoadCSV(
				filepath,
				loaded_csv,
				csv_load_fields,
				"omit_captions"
			)
		end

		strings_failed = {}

		if test_csv then
			strings_failed[-1] = Strings[302535920001571--[["The way I test the CSV file means there might be some ""non-error"" errors added here.
It's a tradeoff between erroneous errors and the game locking up."]]]
		end

		strings_count = 0
		-- this can fail, so we pcall it (some results are better than none)
		local final_strings, final_gendertable = {}, {}
		pcall(function()
			ProcessLoadedTables(
				loaded_csv,
				language,
				final_strings,
				final_gendertable
			)
		end)

		local title
		if strings_count > 0 or csv_count > 0 then
			title = Strings[302535920001125--[[Test Locale File]]] .. ": " .. Translate(951--[[Failed to complete operation.]])
		else
			title = Strings[302535920001125--[[Test Locale File]]] .. ": " .. Translate(1000015--[[Success]])
		end
		local results = {
			loaded_csv = loaded_csv,
			strings_failed = strings_failed,
			final_strings = final_strings,
			final_gendertable = final_gendertable,
		}
		if test_csv and #csv_failed > 0 then
			results.csv_failed = test_csv
		end

		ChoGGi.ComFuncs.OpenInExamineDlg(results, nil, title)
	end
end -- do

do -- ValueToStr
	local getmetatable = getmetatable
	local IsPoint, IsBox, IsT = IsPoint, IsBox, IsT
	local missing_text = ChoGGi.Temp.missing_text

	function ChoGGi.ComFuncs.ValueToStr(obj, obj_type)
		obj_type = obj_type or type(obj)

		if obj_type == "string" then
			-- strings with (object) don't work well with Translate
			if obj:find("%(") then
				return obj, obj_type
			-- If there's any <image, <color, etc tags
			elseif obj:find("[<>]") then
				return Translate(obj), obj_type
			else
				return obj, obj_type
			end
		end
		--
		if obj_type == "number" then
			-- faster than tostring()
			return obj .. "", obj_type
		end
		--
		if obj_type == "boolean" then
			return tostring(obj), obj_type
		end
		--
		if obj_type == "table" then
			return RetName(obj), obj_type
		end
		--
		if obj_type == "userdata" then
			if IsPoint(obj) then
				return "point" .. tostring(obj), obj_type
			elseif IsBox(obj) then
				return "box" .. tostring(obj), obj_type
			end
			-- show translated text if possible, otherwise check for metatable name
			if IsT(obj) then
				local trans_str = Translate(obj)
				if trans_str == missing_text then
					local meta = getmetatable(obj).__name
					return tostring(obj) .. (meta and " " .. meta or ""), obj_type
				end
				return trans_str, obj_type
			end
			--
			local meta = getmetatable(obj).__name
			return tostring(obj) .. (meta and " " .. meta or ""), obj_type
		end
		--
		if obj_type == "function" then
			return RetName(obj), obj_type
		end
		--
		if obj_type == "thread" then
			return tostring(obj), obj_type
		end
		--
		if obj_type == "nil" then
			return "nil", obj_type
		end

		-- just in case
		return tostring(obj), obj_type
	end
end -- do

do -- ToggleObjLines
	local function ObjListLines_Clear(obj)
		if type(obj) ~= "table" then
			return
		end
		if IsValid(obj.ChoGGi_ObjListLine) then
			DoneObject(obj.ChoGGi_ObjListLine)
		end
		rawset(obj, "ChoGGi_ObjListLine", nil)
	end
	ChoGGi.ComFuncs.ObjListLines_Clear = ObjListLines_Clear

	local function ObjListLines_Add(list, obj, colour)
		local vertices = {}
		local c = 0

		-- add any obj pos points of box centres
		for i = 1, #list do
			local o = list[i]
			if IsPoint(o) then
				if o:z() then
					c = c + 1
					vertices[c] = o
				else
					c = c + 1
					vertices[c] = o:SetTerrainZ()
				end
			elseif IsValid(o) then
				c = c + 1
				vertices[c] = o:GetVisualPos()
			elseif IsBox(o) then
				c = c + 1
				vertices[c] = o:Center()
			end
		end
		-- remove any invalid pos
		for i = #vertices, 1, -1 do
			if vertices[i] == InvalidPos then
				table_remove(vertices, i)
			end
		end

		local line = PlacePolyline(vertices, colour)
		line:SetPos(AveragePoint2D(line.vertices))

		obj.ChoGGi_ObjListLine = line
	end

	function ChoGGi.ComFuncs.ObjListLines_Toggle(objs_list, params)
		params = params or {}
		params.obj = params.obj or objs_list

		if ObjListLines_Clear(params.obj) and not params.skip_return then
			return
		end

		SuspendPassEdits("ChoGGi.ComFuncs.ObjListLines_Toggle")
		ObjListLines_Add(objs_list,
			params.obj,
			params.colour or RandomColourLimited()
		)
		ResumePassEdits("ChoGGi.ComFuncs.ObjListLines_Toggle")
	end
end

function ChoGGi.ComFuncs.UsedTerrainTextures(ret)
	if not UICity then
		return
	end

	-- If fired from action menu
	if IsKindOf(ret, "XAction") then
		ret = nil
	end

	local MulDivRound = MulDivRound
	local TerrainTextures = TerrainTextures

	local tm = terrain.GetTypeGrid()
	local _, levels_info = tm:levels(true, 1)
	local size = tm:size()
	local textures = {}
	for level, count in pairs(levels_info) do
		local texture = TerrainTextures[level]
		if texture then
			local perc = MulDivRound(100, count, size * size)
			if perc > 0 then
				textures[texture.name] = perc
			end
		end
	end

	if ret then
		return textures
	end
	ChoGGi.ComFuncs.OpenInExamineDlg(textures, nil, Strings[302535920001181--[[Used Terrain Textures]]])
end

do -- RetObjectCapAndGrid
	local IsFlagSet = IsFlagSet
	local visitors = {"Service", "TrainingBuilding"}

	-- mask is a combination of numbers. IsFlagSet(15, num) will match 1 2 4 8
	function ChoGGi.ComFuncs.RetObjectCapAndGrid(obj, mask)
		if not IsValid(obj) then
			return
		end

		if IsFlagSet(mask, 1) and obj:IsKindOf("ElectricityStorage") then
			return "electricity", obj:GetClassValue("capacity"), obj.electricity

		elseif IsFlagSet(mask, 2) and obj:IsKindOf("AirStorage") then
			return "air", obj:GetClassValue("air_capacity"), obj.air

		elseif IsFlagSet(mask, 4) and obj:IsKindOf("WaterStorage") then
			return "water", obj:GetClassValue("water_capacity"), obj.water

		elseif IsFlagSet(mask, 8) and obj:IsKindOf("Residence") then
			return "colonist", obj:GetClassValue("capacity")

		elseif IsFlagSet(mask, 16) and obj:IsKindOf("Workplace") then
			return "workplace", obj:GetClassValue("max_workers")

		elseif IsFlagSet(mask, 32) and obj:IsKindOfClasses(visitors) then
			return "visitors", obj:GetClassValue("max_visitors")

		end
	end
end -- do

do -- SetLibraryToolTips
	local dlgs = {
		"ChoGGi_XText",
		"ChoGGi_XTextList",
		"ChoGGi_XMultiLineEdit",
		"ChoGGi_XMoveControl",
		"ChoGGi_XButtons",
		"ChoGGi_XImage",
		"ChoGGi_XComboButton",
		"ChoGGi_XCheckButton",
		"ChoGGi_XTextInput",
		"ChoGGi_XList",
		"ChoGGi_XListItem",
		"ChoGGi_XDialog",
		"ChoGGi_XDialogSection",
		"ChoGGi_XWindow",
	}
	function ChoGGi.ComFuncs.SetLibraryToolTips()
		local g = _G

		local tip = ChoGGi.UserSettings.EnableToolTips and "Rollover" or ""
		for i = 1, #dlgs do
			g[dlgs[i]] = tip
		end
	end
end -- do

function ChoGGi.ComFuncs.SetLoadingScreenLog()
	SaveOrigFunc("WaitLoadingScreenClose")

	-- screws up speed buttons (and maybe other stuff)
	-- LoadingScreenOpen = empty_func
	-- LoadingScreenClose = empty_func
	if ChoGGi.UserSettings.LoadingScreenLog then
		WaitLoadingScreenClose = empty_func

		local cls = BaseLoadingScreen
		cls.HandleMouse = false
		cls.transparent = true
		cls.ZOrder = 0
	else
		WaitLoadingScreenClose = ChoGGi.OrigFuncs.WaitLoadingScreenClose

		local cls = BaseLoadingScreen
		cls.HandleMouse = true
		cls.transparent = false
		cls.ZOrder = 1000000000

		cls = BaseSavingScreen
		cls.HandleMouse = true
		cls.transparent = true
		cls.ZOrder = 1000000000
	end
end

-- MonitorFunc (shortcut name in AddedFunctions)
function ChoGGi.ComFuncs.MonitorFunctionResults(func, ...)
	local varargs = ...

	local results_list = {}
	local dlg = ChoGGi.ComFuncs.OpenInExamineDlg(results_list, {
		ex_params = true,
		auto_refresh = true,
		title = Strings[302535920000853--[[Monitor]]] .. " " .. Strings[302535920000110--[[Function Results]]],
	})

	CreateRealTimeThread(function()
		-- stop when dialog is closed
		while IsValidXWin(dlg) do
			-- only update when it's our dlg sending the msg
			local _,msg_dlg = WaitMsg("ChoGGi_dlgs_examine_autorefresh")
			if msg_dlg == dlg then
				table_iclear(results_list)
				local results = {func(varargs)}
				for i = 1, #results do
					results_list[i] = results[i]
				end
			end
		end
	end)
end

-- set UI transparency
function ChoGGi.ComFuncs.SetDlgTrans(dlg, ...)
	if not dlg or dlg and not dlg.class then
		return dlg, ...
	end
	local t = ChoGGi.UserSettings.Transparency[dlg.class]
	if t then
		dlg:SetTransparency(t)
	end
	return dlg, ...
end

-- close any examine dlgs opened from "parent" examine dlg
function ChoGGi.ComFuncs.CloseChildExamineDlgs(self)
	local ChoGGi_dlgs_examine = ChoGGi_dlgs_examine or empty_table
	for _, dlg in pairs(ChoGGi_dlgs_examine) do
		if dlg ~= self and dlg.parent_id == self.parent_id then
			dlg:Close()
		end
	end
end

function ChoGGi.ComFuncs.CheckForBorkedTransportPath(obj, list)
	CreateRealTimeThread(function()
		-- let it sleep for awhile
		Sleep(100)
		-- 0 means it's stopped, so anything above that and without a path means it's borked (probably)
		if obj:GetAnim() > 0 and obj:GetPathLen() == 0 then
			list[obj] = true
			obj:InterruptCommand()
			MsgPopup(
				Strings[302535920001267--[[%s at position: %s was stopped.]]]:format(RetName(obj), obj:GetVisualPos()),
				Strings[302535920001266--[[Borked Transport Pathing]]],
				{objects = obj, image = "UI/Icons/IPButtons/transport_route.tga"}
			)
		end
	end)
end

do -- DisplayMonitorList
	local function AddGrid(city, name, info)
		local c = #info.tables
		for i = 1, #city[name] do
			c = c + 1
			info.tables[c] = city[name][i]
		end
	end

	function ChoGGi.ComFuncs.DisplayMonitorList(value, parent)
		if value == "New" then
			ChoGGi.ComFuncs.MsgWait(
				Strings[302535920000033--[[Post a request on Nexus or Github or send an email to: %s]]]:format(ChoGGi.email),
				Strings[302535920000034--[[Request]]]
			)
			return
		end

		local UICity = UICity
		local info
		--0=value, 1=#table, 2=list table values
		local info_grid = {
			tables = {},
			values = {
				{name="connectors", kind=1},
				{name="consumers", kind=1},
				{name="producers", kind=1},
				{name="storages", kind=1},
				{name="all_consumers_supplied", kind=0},
				{name="charge", kind=0},
				{name="discharge", kind=0},
				{name="current_consumption", kind=0},
				{name="current_production", kind=0},
				{name="current_reserve", kind=0},
				{name="current_storage", kind=0},
				{name="current_storage_change", kind=0},
				{name="current_throttled_production", kind=0},
				{name="current_waste", kind=0},
			}
		}
		if value == "Grids" then
			info = info_grid
			info_grid.title = Strings[302535920000035--[[Grids]]]
			AddGrid(UICity, "air", info)
			AddGrid(UICity, "electricity", info)
			AddGrid(UICity, "water", info)
		elseif value == "Air" then
			info = info_grid
			info_grid.title = Translate(891--[[Air]])
			AddGrid(UICity, "air", info)
		elseif value == "Power" then
			info = info_grid
			info_grid.title = Translate(79--[[Power]])
			AddGrid(UICity, "electricity", info)
		elseif value == "Water" then
			info = info_grid
			info_grid.title = Translate(681--[[Water]])
			AddGrid(UICity, "water", info)
		elseif value == "Research" then
			info = {
				title = Translate(311--[[Research]]),
				listtype = "all",
				tables = {UICity.tech_status},
				values = {
					researched = true
				}
			}
		elseif value == "Colonists" then
			info = {
				title = Translate(547--[[Colonists]]),
				tables = UICity.labels.Colonist or "",
				values = {
					{name="handle", kind=0},
					{name="command", kind=0},
					{name="goto_target", kind=0},
					{name="age", kind=0},
					{name="age_trait", kind=0},
					{name="death_age", kind=0},
					{name="race", kind=0},
					{name="gender", kind=0},
					{name="birthplace", kind=0},
					{name="specialist", kind=0},
					{name="sols", kind=0},
					--{name="workplace", kind=0},
					{name="workplace_shift", kind=0},
					--{name="residence", kind=0},
					--{name="current_dome", kind=0},
					{name="daily_interest", kind=0},
					{name="daily_interest_fail", kind=0},
					{name="dome_enter_fails", kind=0},
					{name="traits", kind=2},
				}
			}
		elseif value == "Rockets" then
			info = {
				title = Translate(5238--[[Rockets]]),
				tables = UICity.labels.AllRockets,
				values = {
					{name="name", kind=0},
					{name="handle", kind=0},
					{name="command", kind=0},
					{name="status", kind=0},
					{name="priority", kind=0},
					{name="working", kind=0},
					{name="charging_progress", kind=0},
					{name="charging_time_left", kind=0},
					{name="landed", kind=0},
					{name="drones", kind=1},
					--{name="units", kind=1},
					{name="unreachable_buildings", kind=0},
				}
			}
		elseif value == "City" then
			info = {
				title = Strings[302535920000042--[[City]]],
				tables = {UICity},
				values = {
					{name="rand_state", kind=0},
					{name="day", kind=0},
					{name="hour", kind=0},
					{name="minute", kind=0},
					{name="total_export", kind=0},
					{name="total_export_funding", kind=0},
					{name="funding", kind=0},
					{name="research_queue", kind=1},
					{name="consumption_resources_consumed_today", kind=2},
					{name="maintenance_resources_consumed_today", kind=2},
					{name="gathered_resources_today", kind=2},
					{name="consumption_resources_consumed_yesterday", kind=2},
					{name="maintenance_resources_consumed_yesterday", kind=2},
					{name="gathered_resources_yesterday", kind=2},
					 --{name="unlocked_upgrades", kind=2},
				}
			}
		end
		if info then
			if not IsKindOf(parent, "XWindow") then
				parent = nil
			end
			ChoGGi.ComFuncs.OpenInMonitorInfoDlg(info, parent)
		end
	end
end -- do

function ChoGGi.ComFuncs.RetLastLineFromStr(str, text)
	if not str then
		return
	end
	-- no text than return last line
	text = (text or "\n"):reverse()

	-- need to reverse string so it finds the last one, since find looks ltr
	local last = str:reverse():find(text, 1, true)
	if last then
		-- we need a neg number for sub + 1 to remove the slash
		return str:sub((last * -1) + 1)
	end
	return ""
end

do -- RetLangTable
	local LoadCSV = LoadCSV
	local ProcessLoadedTables = ProcessLoadedTables

	local loaded = {}
	local translate_gen = {}
	local csv_load_fields = {
		[1] = "id",
		[2] = "text",
		[5] = "translated",
		[3] = "translated_new",
		[7] = "gender"
	}

	function ChoGGi.ComFuncs.RetLangTable(filepath)
		table_iclear(loaded)
		table_iclear(translate_gen)
		LoadCSV(filepath, loaded, csv_load_fields, "omit_captions")
		local translate = {}
		ProcessLoadedTables(loaded, nil, translate, translate_gen)
		return translate, translate_gen
	end
end -- do

function ChoGGi.ComFuncs.AttachSpireFrame(obj)
	local frame = SpireFrame:new()
	obj:Attach(frame)
	frame:ChangeEntity("TempleSpireFrame")
	-- copy from regular frame
	frame:SetAttachOffset(point(0, 0, 4280))
	return frame
end

function ChoGGi.ComFuncs.AttachSpireFrameOffset(obj)
	if obj[1] then
		obj = obj[1]
	end
	local offset = obj:GetAttachOffset()
	obj:SetAttachOffset(point(0, 0, offset:z()))
end

do -- ExpandModOptions
	local function UpdateProp(xtemplate)
		local idx = table_find(xtemplate, "MaxWidth", 400)
		if idx then
			xtemplate[idx].MaxWidth = 1000000
		end
	end

	local function AdjustNumber(self, direction)
		local slider = self.parent.idSlider
		if direction then
			slider:ScrollTo(slider.Scroll + slider.StepSize)
		else
			slider:ScrollTo(slider.Scroll - slider.StepSize)
		end
	end

	local function AddSliderButtons(xtemplate)
		local idx = table_find(xtemplate, "Id", "idSlider")
		if idx then
			local template_left = PlaceObj("XTemplateWindow", {
					"Id", "idButtonLower_ChoGGi",
					"__class", "XTextButton",
					"Text", T("[-]"),
					"FXMouseIn", "ActionButtonHover",
					"FXPress", "ActionButtonClick",
					"FXPressDisabled", "UIDisabledButtonPressed",
					"HAlign", "center",
					"RolloverZoom", 1100,
					"Background", 0,
					"FocusedBackground", 0,
					"RolloverBackground", 0,
					"PressedBackground", 0,
					"TextStyle", "MessageTitle",
					"MouseCursor", "UI/Cursors/Rollover.tga",
					"OnPress", function(self)
						AdjustNumber(self, false)
					end,
					"RolloverTemplate", "Rollover",
				})
			local template_right = PlaceObj("XTemplateWindow", {
					"__template", "PropName",
					"__class", "XTextButton",
					"Id", "idButtonHigher_ChoGGi",
					"Text", T("[+]"),
					"FXMouseIn", "ActionButtonHover",
					"FXPress", "ActionButtonClick",
					"FXPressDisabled", "UIDisabledButtonPressed",
					"HAlign", "center",
					"RolloverZoom", 1100,
					"Background", 0,
					"FocusedBackground", 0,
					"RolloverBackground", 0,
					"PressedBackground", 0,
					"TextStyle", "MessageTitle",
					"MouseCursor", "UI/Cursors/Rollover.tga",
					"OnPress", function(self)
						AdjustNumber(self, true)
					end,
					"RolloverTemplate", "Rollover",
				})
			table.insert(xtemplate, idx, template_left)
			table.insert(xtemplate, idx+2, template_right)
		end
	end

	function ChoGGi.ComFuncs.ExpandModOptions(XTemplates)
		local xtemplate = XTemplates.PropBool[1]
		if xtemplate.ChoGGi_ModOptionsExpanded then
			return
		end
		xtemplate.ChoGGi_ModOptionsExpanded = true

		UpdateProp(xtemplate)
		UpdateProp(XTemplates.PropChoiceOptions[1])
		xtemplate = XTemplates.PropNumber[1]
		UpdateProp(xtemplate)
		-- add buttons to number
		AddSliderButtons(xtemplate)

	end
end -- do


do -- UnpublishParadoxMod
	local function PDX_GetModDetails(mod_title, os_type)
		local query = {
			Query = mod_title,
			Author = "",
			RequiredVersion = "",
			Tags = {},
			Page = 0,
			PageSize = 20,
			SortBy = "displayName",
			OrderBy = "asc",
			OSType = os_type
		}
		local err, results = AsyncOpWait(PopsAsyncOpTimeout, nil, "AsyncPopsModsSearch", query)
		if err then
			return err
		end
		-- to unpublish a mod we have to parse search results, instead of using the guid to look it up?
		for i = 1, #results do
			local entry = results[i]
			if entry.DisplayName == mod_title then
				return entry
			end
		end
		return "mod not found"
	end

	-- platform = "any" for pc/xbox, "windows" for only pc
	-- mod_title = name of mod on paradox platform
--~ ChoGGi.ComFuncs.UnpublishParadoxMod("Lakes Toggle Visibility")
	function ChoGGi.ComFuncs.UnpublishParadoxMod(mod_title, platform)
		if blacklist then
			ChoGGi.ComFuncs.BlacklistMsg("ChoGGi.ComFuncs.UnpublishParadoxMod")
			return
		end
		if not mod_title then
			return
		end

		local function CallBackFunc(answer)
			if answer then

				if not platform then
					platform = "any"
				end
				local result = PDX_GetModDetails(mod_title, platform)

				if type(result) == "table" then
					result = AsyncOpWait(PopsAsyncOpTimeout, nil, "AsyncPopsModsDeleteMod", result.ModID)
				end

				if type(result) == "string" then
					print("UnpublishParadoxMod<color ChoGGi_red> ERROR", result, "</color>")
				else
					print("UnpublishParadoxMod<color ChoGGi_green>", Translate(1000015--[[Success]]), "</color>")
				end
			end
		end
		ChoGGi.ComFuncs.QuestionBox(
			Translate(6779--[[Warning]]) .. "!\n" .. Translate(672683736395--[[Unpublish from Paradox]]),
			CallBackFunc,
			mod_title
		)
	end
end -- do
