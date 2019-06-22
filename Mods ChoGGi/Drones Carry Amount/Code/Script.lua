-- See LICENSE for terms

local FuckingDrones = ChoGGi.ComFuncs.FuckingDrones

function OnMsg.ClassesPostprocess()

	local orig_SingleResourceProducer_Produce = SingleResourceProducer.Produce
	function SingleResourceProducer:Produce(...)
		-- get them lazy drones working
		if self:GetStoredAmount() > 1000 then
			FuckingDrones(self,"single")
		end
		-- be on your way
		return orig_SingleResourceProducer_Produce(self, ...)
	end

end

function OnMsg.NewHour()
	local labels = UICity.labels

	-- Hey. Do I preach at you when you're lying stoned in the gutter? No!
	local prods = labels.ResourceProducer or ""
	for i = 1, #prods do
		local prod = prods[i]
		-- most are fine with GetProducerObj, but some like water extractor don't have one
		local obj = prod:GetProducerObj() or prod
		local func = obj.GetStoredAmount and "GetStoredAmount" or obj.GetAmountStored and "GetAmountStored"
		if obj[func](obj) > 1000 then
			FuckingDrones(obj)
		end
		obj = prod.wasterock_producer
		if obj and obj:GetStoredAmount() > 1000 then
			FuckingDrones(obj, "single")
		end
	end

	prods = labels.BlackCubeStockpiles or ""
	for i = 1, #prods do
		local obj = prods[i]
		if obj:GetStoredAmount() > 1000 then
			FuckingDrones(obj)
		end
	end
end


-- update carry amount
local options
local default_drone_amount

-- load default/saved settings
function OnMsg.ModsReloaded()
	options = CurrentModOptions
--~ 	ModOptions()
end

local function UpdateAmount(amount)
	ChoGGi.ComFuncs.SetConstsG("DroneResourceCarryAmount", amount)
	UpdateDroneResourceUnits()
end

-- fired when option is changed
function OnMsg.ApplyModOptions(id)
	if id ~= "ChoGGi_DronesCarryAmountFix" then
		return
	end

	-- if enabled then apply option
	if options.UseCarryAmount then
		if g_Consts.DroneResourceCarryAmount ~= options.CarryAmount then
			UpdateAmount(options.CarryAmount)
		end
	elseif default_drone_amount and g_Consts.DroneResourceCarryAmount ~= default_drone_amount then
		UpdateAmount(default_drone_amount)
	end
end

local function StartupCode()
	-- get default
	default_drone_amount = ChoGGi.ComFuncs.GetResearchedTechValue("DroneResourceCarryAmount")

	if options.UseCarryAmount then
		UpdateAmount(options.CarryAmount)
	end
end

OnMsg.CityStart = StartupCode
OnMsg.LoadGame = StartupCode
