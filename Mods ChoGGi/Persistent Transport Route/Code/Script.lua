-- See LICENSE for terms

local CreateRealTimeThread = CreateRealTimeThread
local WaitMsg = WaitMsg

local temp_route_obj
local temp_route_from
local temp_route_res

-- store resource name
local orig_ResourceItems_Close = ResourceItems.Close
function ResourceItems:Close(...)
	local c = self.context
	if c and c.object and c.object:IsKindOf("RCTransport") then
		temp_route_res = c.object.temp_route_transport_resource
	end
	return orig_ResourceItems_Close(self, ...)
end

-- store the unit/from point
local orig_SetTransportRoutePoint = UnitDirectionModeDialog.SetTransportRoutePoint
function UnitDirectionModeDialog:SetTransportRoutePoint(dir, pt, ...)
	-- make sure it's proper before we store it
	if dir == "from" and self.created_route then
		temp_route_obj = self.unit
		temp_route_from = pt
	end
	return orig_SetTransportRoutePoint(self, dir, pt, ...)
end

-- make sure it doesn't try to redo the route
local orig_OnTransportRouteCreated = UnitDirectionModeDialog.OnTransportRouteCreated
function UnitDirectionModeDialog.OnTransportRouteCreated(...)
	temp_route_obj = nil
	return orig_OnTransportRouteCreated(...)
end

-- restore it
local orig_Init = UnitDirectionModeDialog.Init or XWindow.Init
function UnitDirectionModeDialog:Init(...)
	CreateRealTimeThread(function()
		WaitMsg("OnRender")
		-- check that it's the right stuff
		if self.MouseCursor == "UI/Cursors/RoverTarget.tga"
			and self.unit == temp_route_obj and not Dialogs.OverviewModeDialog
		then
			self.unit:ToggleCreateRouteMode()
			self.unit.temp_route_transport_resource = temp_route_res
			self:SetCreateRouteMode(true)
			orig_SetTransportRoutePoint(self, "from", temp_route_from)
		end
	end)
	return orig_Init(self, ...)
end
