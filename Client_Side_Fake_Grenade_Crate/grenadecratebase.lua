local ThisModPath = ModPath

local __Name = function(__id)
	return "RRR_"..Idstring(tostring(__id).."::"..ThisModPath):key()
end

ThisFakeGrenadeCrateBase = ThisFakeGrenadeCrateBase or class(GrenadeCrateBase)

local IDS_UNIT = Idstring("unit")

local IDS_BAG = Idstring("units/pd2_dlc_mxm/equipment/gen_equipment_grenade_crate/gen_equipment_grenade_crate_dummy")

local IDS_INTERACT_KEY = Idstring("units/world/props/apartment/apartment_key_dummy/apartment_key_dummy")

pcall(function()
	DelayedCalls:Add(__Name(0), 1, function()
		managers.dyn_resource:load(IDS_UNIT, IDS_BAG, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
		managers.dyn_resource:load(IDS_UNIT, IDS_INTERACT_KEY, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
	end)
end)

ThisFakeGrenadeCrateBase.all_key_units = ThisFakeGrenadeCrateBase.all_key_units or {}

local remove_unit = function(this_unit)	
	if this_unit and alive(this_unit) then
		World:delete_unit(this_unit)
	end
	if this_unit and alive(this_unit) then
		this_unit:set_slot(0)
	end
end

function ThisFakeGrenadeCrateBase.spawn(pos, rot, duration)
	pcall(function()
		if type(duration) ~= "number" then
			duration = nil --infinity
		end
		
		local __key_unit = safe_spawn_unit(IDS_INTERACT_KEY, pos, rot)
		local __this_bag = safe_spawn_unit(IDS_BAG, pos, rot)
		
		__key_unit:interaction().__this_bag = __this_bag
		__key_unit:interaction()._tweak_data.text_id = "debug_equipment_grenade_crate"
		__key_unit:interaction()._tweak_data.equipment_text_id = "debug_equipment_grenade_crate"
		__key_unit:interaction()._tweak_data.special_equipment = nil
		__key_unit:interaction()._tweak_data.timer = 1
		__key_unit:interaction().interact = function(them, ...)
			if them and managers.player and managers.player:local_player() and not managers.player:got_max_grenades() then
				if type(them.__grenade_amount) == "number" and them.__grenade_amount > 0 then
					them.__grenade_amount = them.__grenade_amount - 1
					
					managers.player:local_player():sound():play("pickup_ammo")
					local grenade_id = managers.blackmarket:equipped_grenade()
					local grenade_tweak = tweak_data.blackmarket.projectiles[grenade_id]
					local pickup_amount = 1
					managers.player:add_grenade_amount(pickup_amount)
					managers.player:register_grenade(managers.network:get_local_peer_safe():id())
				end
				if type(them.__grenade_amount) ~= "number" or them.__grenade_amount <= 0 then
					them:set_active(false)
					DelayedCalls:Add(__Name(them._unit), 0.1, function()
						remove_unit(them.__this_bag)
						remove_unit(them._unit)
					end)
				end
			end
		end
		
		ThisFakeGrenadeCrateBase.all_key_units[__key_unit:key()] = {
			__key_unit = __key_unit,
			__this_bag = __this_bag,
			__time = duration
		}
		__key_unit:interaction().__grenade_amount = tweak_data.upgrades.grenade_crate_base
		
		return ThisFakeGrenadeCrateBase.all_key_units[__key_unit:key()]
	end)
end

Hooks:Add("GameSetupUpdate", __Name(1), function(__t, __dt)
	local all_key_units = ThisFakeGrenadeCrateBase.all_key_units
	if type(all_key_units) == "table" then		
		for __key, __data in pairs(all_key_units) do
			if type(__key) == "userdata" and type(__data) == "table" and type(__data.__time) == "number" then
				if __data.__time > 0 then
					ThisFakeGrenadeCrateBase.all_key_units[__key].__time = all_key_units[__key].__time - __dt
				end
				if __data.__time <= 0 then
					remove_unit(__data.__this_bag)
					remove_unit(__data.__key_unit)
					ThisFakeGrenadeCrateBase.all_key_units[__key] = nil
				end
			end
		end
	end
end)