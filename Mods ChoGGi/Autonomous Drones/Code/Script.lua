-- See LICENSE for terms

-- updating medium/high hubs, list of idle drones, list of all drones from low load hubs, list of all drones from medium load hubs, filtered list of mod option hubs, non-filtered hubs to clear out
local threshold, idle_drones, low_drones, med_drones, filtered_hubs, useless_hubs

local mod_AddHeavy
local mod_AddMedium
local mod_UsePrefabs
local mod_HidePackButtons
local mod_RandomiseHubList
local mod_SortHubListLoad
local mod_EnableMod
local mod_AddEmpty
local mod_UpdateDelay
local mod_UseDroneHubs
local mod_UseCommanders
local mod_UseRockets
local mod_EarlyGame
local mod_IgnoreUnusedHubs
local mod_DroneWorkDelay

-- fired when settings are changed/init
local function ModOptions()
	local options = CurrentModOptions
	mod_AddHeavy = options:GetProperty("AddHeavy")
	mod_AddMedium = options:GetProperty("AddMedium")
	mod_AddEmpty = options:GetProperty("AddEmpty")
	mod_UsePrefabs = options:GetProperty("UsePrefabs")
	mod_HidePackButtons = options:GetProperty("HidePackButtons")
	mod_RandomiseHubList = options:GetProperty("RandomiseHubList")
	mod_SortHubListLoad = options:GetProperty("SortHubListLoad")
	mod_EnableMod = options:GetProperty("EnableMod")
	mod_UpdateDelay = options:GetProperty("UpdateDelay")
	mod_UseDroneHubs = options:GetProperty("UseDroneHubs")
	mod_UseCommanders = options:GetProperty("UseCommanders")
	mod_UseRockets = options:GetProperty("UseRockets")
	mod_EarlyGame = options:GetProperty("EarlyGame")
	mod_IgnoreUnusedHubs = options:GetProperty("IgnoreUnusedHubs")
	mod_DroneWorkDelay = options:GetProperty("DroneWorkDelay")

	if not med_drones then
		med_drones = {}
	end
	if not low_drones then
		low_drones = {}
	end
	if not filtered_hubs then
		filtered_hubs = {}
	end
end

-- load default/saved settings
OnMsg.ModsReloaded = ModOptions

-- fired when option is changed
function OnMsg.ApplyModOptions(id)
	if id ~= CurrentModId then
		return
	end

	ModOptions()
end

local table = table
local table_ifilter = table.ifilter
local table_iclear = table.iclear
local table_rand = table.rand
local table_insert = table.insert
local table_remove = table.remove
local CreateGameTimeThread = CreateGameTimeThread
local Sleep = Sleep
local Max = Max
local GameTime = GameTime
local IsKindOf = IsKindOf
local floatfloor = floatfloor
local AsyncRand = AsyncRand

local DroneLoadLowThreshold = const.DroneLoadLowThreshold
local DroneLoadMediumThreshold = const.DroneLoadMediumThreshold
local idle_drone_cmds = {
	Idle = true,
	GoHome = true,
	WaitingCommand = true,
	Start = true,
}

local GetIdleDrones = ChoGGi.ComFuncs.GetIdleDrones
local FisherYates_Shuffle = ChoGGi.ComFuncs.FisherYates_Shuffle
local SendDroneToCC = ChoGGi.ComFuncs.SendDroneToCC

local function Template__condition(_, context)
	return not mod_HidePackButtons and IsKindOf(context, "DroneControl")
end

-- unhardcode these someday...
function OnMsg.ClassesPostprocess()
	local template = XTemplates.customDroneHub
	template[1].__condition = Template__condition
	template[2].__condition = Template__condition

	template = XTemplates.ipRover[1]
	template[3].__condition = Template__condition
	template[4].__condition = Template__condition
end

local function AssignDronePrefabs(hub)
	for _ = 1, (threshold == "red" and mod_AddHeavy or mod_AddMedium) do
		if hub.city.drone_prefabs > 0 then
			hub:UseDronePrefab()
		end
	end
end

local function AssignWorkingDrones(drones, count, hub, not_rand)
	local drones_c = #drones
	for _ = 1, count do

		local drone, idx
		if not_rand then
			drone, idx = drones[drones_c], drones_c
		else
			drone, idx = table_rand(drones)
		end

		if drone and idx then
			-- need to remove entry right away (before table idx changes)
			table_remove(drones, idx)
			-- no need to move to same hub
			if not drone.ChoGGi_WaitingForIdleDrone and drone.command_center ~= hub then
				drone.ChoGGi_WaitingForIdleDrone = CreateGameTimeThread(function()
					-- wait till drone is idle then send it off
					local count = 0
					while not idle_drone_cmds[drone.command] do
						-- stop waiting after so long
						if mod_DroneWorkDelay > 0 and count > mod_DroneWorkDelay then
							break
						end
						Sleep(1000)
						count = count + 1
					end
					drone.ChoGGi_WaitingForIdleDrone = nil
					SendDroneToCC(drone, hub)
				end)
				drones_c = drones_c - 1
				if drones_c == 0 then
					break
				end
			end
		end
	end
end

local function AssignDrones(hub)
	local count = threshold == "red" and mod_AddHeavy or mod_AddMedium

	-- reassign idle drones
	local idle_drones_c = #idle_drones
	if idle_drones_c > 0 then
		for _ = 1, count do
			local drone, idx = table_rand(idle_drones)
			if drone and idx then
				table_remove(idle_drones, idx)
				CreateGameTimeThread(SendDroneToCC, drone, hub)
			end
			-- no sense in looping for naught
			idle_drones_c = idle_drones_c - 1
			if idle_drones_c == 0 then
				break
			end
		end
	end
	-- reassign low load drones
	if #low_drones > 0 then
		AssignWorkingDrones(low_drones, count, hub)
	end
	-- reassign medium load drones
	AssignWorkingDrones(med_drones, count, hub)
end

local DisablingCommands = {
	Malfunction = true,
	NoBattery = true,
	Freeze = true,
	Dead = true,
	DespawnAtHub = true,
	DieNow = true,
}
local function FilterDrones(_, drone)
	return not (DisablingCommands[drone.command] or false)
end

local function UpdateHubs(hub_count, build_list, drone_prefabs, last_go)
	for i = 1, hub_count do
		local hub = filtered_hubs[i]
		local drones = hub.drones

		if (threshold == "empty" or threshold == "all") and (#drones == 0 or #table_ifilter(drones, FilterDrones) < 1) then
			-- no drones
			if drone_prefabs then
				AssignDronePrefabs(hub)
			else
				AssignDrones(hub)
			end
		else
			-- function DroneControl:CalcLapTime(), wanted the funcs local since we call this a lot
			local lap_time = Max(hub.lap_time, GameTime() - hub.lap_start)
--~ 			local lap_time = #drones == 0 and 0 or Max(hub.lap_time, GameTime() - hub.lap_start)

			if lap_time < DroneLoadLowThreshold then
				-- low load
				if build_list == "low" then
					local c = #low_drones
					for j = 1, #drones do
						c = c + 1
						low_drones[c] = drones[j]
					end
				end
				-- all other hubs have filled up on drones and these are the left over prefabs
				if last_go and drone_prefabs then
					AssignDronePrefabs(hub)
				end
			elseif (threshold == "red" or threshold == "all") and lap_time >= DroneLoadMediumThreshold then
				-- high load
				if drone_prefabs then
					AssignDronePrefabs(hub)
				else
					AssignDrones(hub)
				end
			elseif (threshold == "orange" or threshold == "all") and lap_time < DroneLoadMediumThreshold then
--~ 			elseif threshold == "orange" or threshold == "all" then
				-- medium load
				if build_list == "medium" then
					local c = #med_drones
					for j = 1, #drones do
						c = c + 1
						med_drones[c] = drones[j]
					end
				else
					if drone_prefabs then
						AssignDronePrefabs(hub)
					else
						AssignDrones(hub)
					end
				end
			end
		end

	end
end

local function UsePrefabs(drone_prefabs, hub_count)
	if drone_prefabs > 0 then
		threshold = "all"
		UpdateHubs(hub_count, nil, drone_prefabs)
	end
end

local function UpdateDrones()
	if not mod_EnableMod then
		return
	end

	local UICity = UICity
	local hubs = UICity.labels.DroneControl or ""

--~ 	ex(filtered_hubs)

	-- build list of filtered hubs
	table_iclear(filtered_hubs)
	local hub_count = 0
	table_iclear(useless_hubs)
	local use_hubs_c = 0
	for i = 1, #hubs do
		local hub = hubs[i]
		-- build list of hubs to use
		if hub.working and
			(mod_UseCommanders and hub:IsKindOf("RCRover")
			or mod_UseDroneHubs and hub:IsKindOf("DroneHub")
			or mod_UseRockets and hub:IsKindOf("SupplyRocket"))
		then
			hub_count = hub_count + 1
			filtered_hubs[hub_count] = hub
		elseif mod_UsePrefabs then
			-- we only clear these hubs if mod option (and only after checking hub_count)
			if hub.working then
				use_hubs_c = use_hubs_c + 1
				useless_hubs[use_hubs_c] = hub
			else
				-- always clear out borked hubs
				for _ = 1, #(hub.drones or "") do
					hub:ConvertDroneToPrefab()
				end
			end
		end
	end

	-- not much point if there's only one hub
	if hub_count < 2 then
		-- there could be some?
		if mod_UsePrefabs then
			UsePrefabs(UICity.drone_prefabs, hub_count)
		end
		return
	end

	-- remove any drones from hubs we don't use
	if not mod_IgnoreUnusedHubs then
		for i = 1, use_hubs_c do
			local hub = useless_hubs[i]
			for _ = 1, #(hub.drones or "") do
				hub:ConvertDroneToPrefab()
			end
		end
	end

	-- sort hubs by drone load (empty, heavy, med, low)
	if mod_SortHubListLoad then
		local DroneHubLoad = ChoGGi.ComFuncs.DroneHubLoad
		table.sort(filtered_hubs, function(a, b)
			return DroneHubLoad(a, true) > DroneHubLoad(b, true)
		end)
	-- randomise hub list (firsters get more drones)
	elseif mod_RandomiseHubList then
		FisherYates_Shuffle(filtered_hubs)
		-- stick all empty hubs at start (otherwise they may stay empty for too long)
		for i = 1, hub_count do
			if #filtered_hubs[i].drones == 0 then
				table_insert(filtered_hubs, 1, table_remove(filtered_hubs, i))
			end
		end
	end

	-- assign any prefabs to hubs
	if mod_UsePrefabs then
		UsePrefabs(UICity.drone_prefabs, hub_count)
	end

	-- if there's less drones then the threshold set in mod options we evenly split drones across hubs
	-- copied so we can table.remove from it (maybe filter out the not working drones?)
	local drones = table_icopy(UICity.labels.Drone)
	if mod_EarlyGame == 0 or mod_EarlyGame > #drones then
		-- get numbers for amount of drones split between hubs (rounded down)
		local split_count = floatfloor(#drones / hub_count)
		local leftovers = #drones - (split_count * hub_count)

		-- if all hubs have the same/more than the "split" amount skip assigning drones
		local low_count = false
		for i = 1, hub_count do
			local hub = filtered_hubs[i]
			if #hub.drones < split_count then
				low_count = true
			end
		end
		if not low_count then
			return
		end

		-- assign drones to hubs
		for i = 1, hub_count do
			AssignWorkingDrones(drones, split_count, filtered_hubs[i], true)
		end

		-- random assign for leftover round down drones
		CreateGameTimeThread(function()
			Sleep(1000)
			for _ = 1, leftovers do
				AssignWorkingDrones(drones, 1, filtered_hubs[AsyncRand(hub_count)+1], true)
			end
		end)

		-- we don't want the load sorting to happen
		return
	end

	-- build list of idle drones (prefab-able)
	idle_drones = GetIdleDrones()

	-- update empty drone hubs first
	threshold = "empty"
	UpdateHubs(hub_count)

	-- build list of drones from medium load hubs
	table_iclear(med_drones)
	threshold = "orange"
	UpdateHubs(hub_count, "medium")

	-- and low
	table_iclear(low_drones)
	threshold = "green"
	UpdateHubs(hub_count, "low")

	-- update heavy load drone hubs (some may turn into medium after)
	threshold = "red"
	UpdateHubs(hub_count)

	-- update med load drone hubs
	threshold = "orange"
	UpdateHubs(hub_count)

	-- assign any extra prefabs to low load hubs
	if mod_UsePrefabs and UICity.drone_prefabs > 0 then
		threshold = "green"
		UpdateHubs(hub_count, nil, UICity.drone_prefabs, true)
	end
end

function OnMsg.NewDay()
	if mod_UpdateDelay then
		UpdateDrones()
	end
end

function OnMsg.NewHour()
	if not mod_UpdateDelay then
		UpdateDrones()
	end
end
