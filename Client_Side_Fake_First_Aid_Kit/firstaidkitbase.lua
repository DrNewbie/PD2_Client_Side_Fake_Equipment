local ThisModPath = ModPath

local __Name = function(__id)
	return "RRR_"..Idstring(tostring(__id).."::"..ThisModPath):key()
end

ThisFakeFirstAidKitBase = ThisFakeFirstAidKitBase or class(FirstAidKitBase)

local IDS_UNIT = Idstring("unit")

local IDS_FAK = Idstring("units/pd2_dlc_old_hoxton/equipment/gen_equipment_first_aid_kit/gen_equipment_first_aid_kit_dummy")

local IDS_INTERACT_KEY = Idstring("units/world/props/apartment/apartment_key_dummy/apartment_key_dummy")

pcall(function()
	DelayedCalls:Add(__Name(0), 1, function()
		managers.dyn_resource:load(IDS_UNIT, IDS_FAK, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
		managers.dyn_resource:load(IDS_UNIT, IDS_INTERACT_KEY, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
	end)
end)

ThisFakeFirstAidKitBase.all_key_units = ThisFakeFirstAidKitBase.all_key_units or {}

local remove_unit = function(this_unit)	
	if this_unit and alive(this_unit) then
		World:delete_unit(this_unit)
	end
	if this_unit and alive(this_unit) then
		this_unit:set_slot(0)
	end
end

function ThisFakeFirstAidKitBase.spawn(pos, rot, bits, duration)
	pcall(function()
		if type(bits) ~= "number" then
			bits = 0
		end
		if type(duration) ~= "number" then
			duration = nil --infinity
		end
		
		local __key_unit = safe_spawn_unit(IDS_INTERACT_KEY, pos, rot)
		local __this_bag = safe_spawn_unit(IDS_FAK, pos, rot)
		
		__key_unit:interaction().__this_bag = __this_bag
		__key_unit:interaction()._tweak_data.text_id = "debug_equipment_first_aid_kit"
		__key_unit:interaction()._tweak_data.equipment_text_id = "debug_equipment_first_aid_kit"
		__key_unit:interaction()._tweak_data.special_equipment = nil
		__key_unit:interaction()._tweak_data.timer = 1
		__key_unit:interaction().interact = function(them, ...)
			if managers.player and managers.player:local_player() then
				managers.player:local_player():character_damage():band_aid_health()
				if them.__damage_reduction_upgrade then
					managers.player:activate_temporary_upgrade("temporary", "first_aid_damage_reduction")
				end
			end
			them:set_active(false)
			DelayedCalls:Add(__Name(them._unit), 0.1, function()
				remove_unit(them.__this_bag)
				remove_unit(them._unit)
			end)
		end
		
		local upgrade_lvl, auto_recovery = Bitwise:rshift(bits, FirstAidKitBase.auto_recovery_shift), Bitwise:rshift(bits, FirstAidKitBase.upgrade_lvl_shift) % 2^FirstAidKitBase.upgrade_lvl_shift
		
		__key_unit:interaction().__damage_reduction_upgrade = upgrade_lvl == 1
		
		ThisFakeFirstAidKitBase.all_key_units[__key_unit:key()] = {
			__key_unit = __key_unit,
			__this_bag = __this_bag,
			__time = duration
		}
		
		return ThisFakeFirstAidKitBase.all_key_units[__key_unit:key()]
	end)
end

Hooks:Add("GameSetupUpdate", __Name(1), function(__t, __dt)
	local all_key_units = ThisFakeFirstAidKitBase.all_key_units
	if type(all_key_units) == "table" then		
		for __key, __data in pairs(all_key_units) do
			if type(__key) == "userdata" and type(__data) == "table" and type(__data.__time) == "number" then
				if __data.__time > 0 then
					ThisFakeFirstAidKitBase.all_key_units[__key].__time = all_key_units[__key].__time - __dt
				end
				if __data.__time <= 0 then
					remove_unit(__data.__this_bag)
					remove_unit(__data.__key_unit)
					ThisFakeFirstAidKitBase.all_key_units[__key] = nil
				end
			end
		end
	end
end)