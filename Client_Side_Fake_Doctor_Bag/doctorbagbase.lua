local ThisModPath = ModPath

local __Name = function(__id)
	return "RRR_"..Idstring(tostring(__id).."::"..ThisModPath):key()
end

ThisFakeDoctorBagBase = ThisFakeDoctorBagBase or class(DoctorBagBase)

local IDS_UNIT = Idstring("unit")

local IDS_BAG = Idstring("units/payday2/equipment/gen_equipment_medicbag/gen_equipment_medicbag_dummy_unit")

local IDS_INTERACT_KEY = Idstring("units/world/props/apartment/apartment_key_dummy/apartment_key_dummy")

pcall(function()
	DelayedCalls:Add(__Name(0), 1, function()
		managers.dyn_resource:load(IDS_UNIT, IDS_BAG, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
		managers.dyn_resource:load(IDS_UNIT, IDS_INTERACT_KEY, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
	end)
end)

ThisFakeDoctorBagBase.all_key_units = ThisFakeDoctorBagBase.all_key_units or {}

local remove_unit = function(this_unit)	
	if this_unit and alive(this_unit) then
		World:delete_unit(this_unit)
	end
	if this_unit and alive(this_unit) then
		this_unit:set_slot(0)
	end
end

function ThisFakeDoctorBagBase.spawn(pos, rot, bits, duration)
	pcall(function()
		if type(bits) ~= "number" then
			bits = 0
		end
		if type(duration) ~= "number" then
			duration = nil --infinity
		end
		
		local __key_unit = safe_spawn_unit(IDS_INTERACT_KEY, pos, rot)
		local __this_bag = safe_spawn_unit(IDS_BAG, pos, rot)
		
		__key_unit:interaction().__this_bag = __this_bag
		__key_unit:interaction()._tweak_data.text_id = "debug_doctor_bag"
		__key_unit:interaction()._tweak_data.equipment_text_id = "debug_doctor_bag"
		__key_unit:interaction()._tweak_data.special_equipment = nil
		__key_unit:interaction()._tweak_data.timer = 1
		__key_unit:interaction().interact = function(them, ...)
			if managers.player and managers.player:local_player() then
				if type(them.__medic_amount) == "number" and them.__medic_amount > 0 then
					them.__medic_amount = them.__medic_amount - 1					
					managers.player:local_player():character_damage():recover_health()
				end
				if them.__damage_reduction_upgrade then
					managers.player:activate_temporary_upgrade("temporary", "first_aid_damage_reduction")
				end
			end
			if type(them.__medic_amount) ~= "number" or them.__medic_amount <= 0 then
				them:set_active(false)
				DelayedCalls:Add(__Name(them._unit), 0.1, function()
					remove_unit(them.__this_bag)
					remove_unit(them._unit)
				end)
			end
		end
		
		local dmg_reduction_lvl = Bitwise:rshift(bits, DoctorBagBase.damage_reduce_lvl_shift)
		local amount_upgrade_lvl = Bitwise:rshift(bits, DoctorBagBase.amount_upgrade_lvl_shift) % 2^DoctorBagBase.amount_upgrade_lvl_shift
		
		__key_unit:interaction().__medic_amount = tweak_data.upgrades.doctor_bag_base + managers.player:upgrade_value_by_level("doctor_bag", "amount_increase", 1)
		__key_unit:interaction().__damage_reduction_upgrade = dmg_reduction_lvl ~= 0
		
		ThisFakeDoctorBagBase.all_key_units[__key_unit:key()] = {
			__key_unit = __key_unit,
			__this_bag = __this_bag,
			__time = duration
		}
		
		return ThisFakeDoctorBagBase.all_key_units[__key_unit:key()]
	end)
end

Hooks:Add("GameSetupUpdate", __Name(1), function(__t, __dt)
	local all_key_units = ThisFakeDoctorBagBase.all_key_units
	if type(all_key_units) == "table" then		
		for __key, __data in pairs(all_key_units) do
			if type(__key) == "userdata" and type(__data) == "table" and type(__data.__time) == "number" then
				if __data.__time > 0 then
					ThisFakeDoctorBagBase.all_key_units[__key].__time = all_key_units[__key].__time - __dt
				end
				if __data.__time <= 0 then
					remove_unit(__data.__this_bag)
					remove_unit(__data.__key_unit)
					ThisFakeDoctorBagBase.all_key_units[__key] = nil
				end
			end
		end
	end
end)