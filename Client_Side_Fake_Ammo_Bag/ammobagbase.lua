local ThisModPath = ModPath

local __Name = function(__id)
	return "RRR_"..Idstring(tostring(__id).."::"..ThisModPath):key()
end

ThisFakeAmmoBagBase = ThisFakeAmmoBagBase or class(AmmoBagBase)

local IDS_UNIT = Idstring("unit")

local IDS_BAG = Idstring("units/payday2/equipment/gen_equipment_ammobag/gen_equipment_ammobag_dummy_unit")

local IDS_INTERACT_KEY = Idstring("units/world/props/apartment/apartment_key_dummy/apartment_key_dummy")

pcall(function()
	DelayedCalls:Add(__Name(0), 1, function()
		managers.dyn_resource:load(IDS_UNIT, IDS_BAG, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
		managers.dyn_resource:load(IDS_UNIT, IDS_INTERACT_KEY, DynamicResourceManager.DYN_RESOURCES_PACKAGE)
	end)
end)

ThisFakeAmmoBagBase.all_key_units = ThisFakeAmmoBagBase.all_key_units or {}

local remove_unit = function(this_unit)	
	if this_unit and alive(this_unit) then
		World:delete_unit(this_unit)
	end
	if this_unit and alive(this_unit) then
		this_unit:set_slot(0)
	end
end

local check_them_is_okay = function(them)
	if not them or not them._unit or not alive(them._unit) then
		return false
	end
	return true
end

local get_them_data = function(them)
	if not check_them_is_okay(them) then
		return nil
	end
	return ThisFakeAmmoBagBase.all_key_units[them._unit:key()]
end

local set_them_data = function(them, data)
	if not check_them_is_okay(them) then
		return
	end
	ThisFakeAmmoBagBase.all_key_units[them._unit:key()] = data
	return
end

function ThisFakeAmmoBagBase.spawn(pos, rot, ammo_upgrade_lvl, bullet_storm_level, duration)
	pcall(function()
		if type(ammo_upgrade_lvl) ~= "number" then
			ammo_upgrade_lvl = 0
		end
		if type(bullet_storm_level) ~= "number" then
			bullet_storm_level = 0
		end
		if type(duration) ~= "number" then
			duration = nil --infinity
		end
		
		local __key_unit = safe_spawn_unit(IDS_INTERACT_KEY, pos, rot)
		local __this_bag = safe_spawn_unit(IDS_BAG, pos, rot)
		
		__key_unit:interaction().__this_bag = __this_bag
		__key_unit:interaction()._tweak_data.text_id = "debug_ammo_bag"
		__key_unit:interaction()._tweak_data.equipment_text_id = "debug_ammo_bag"
		__key_unit:interaction()._tweak_data.special_equipment = nil
		__key_unit:interaction()._tweak_data.timer = 1
		__key_unit:interaction().interact = function(them, ...)
			local them_base = get_them_data(them)
			if managers.player and managers.player:local_player() then
				ThisFakeAmmoBagBase._take_ammo(them, managers.player:local_player())
			end
			if not check_them_is_okay(them) or not them_base or them_base._empty then
				them:set_active(false)
				DelayedCalls:Add(__Name(them._unit), 0.1, function()
					remove_unit(them.__this_bag)
					remove_unit(them._unit)
				end)
			end
		end
		
		ThisFakeAmmoBagBase.all_key_units[__key_unit:key()] = {
			__key_unit = __key_unit,
			__this_bag = __this_bag,
			__time = duration,
			bullet_storm_level = bullet_storm_level,
			ammo_amount = tweak_data.upgrades.ammo_bag_base + managers.player:upgrade_value_by_level("ammo_bag", "ammo_increase", ammo_upgrade_lvl)
		}
		
		if __this_bag.damage and __this_bag:damage() then
			local state = "state_6"
			if __this_bag:damage():has_sequence(state) then
				__this_bag:damage():run_sequence_simple(state)
			end
		end
		
		return ThisFakeAmmoBagBase.all_key_units[__key_unit:key()]
	end)
end

function ThisFakeAmmoBagBase._take_ammo(them, unit)
	if not check_them_is_okay(them) or not unit or not alive(unit) then
		return 0
	end
	
	local them_base = get_them_data(them)
	
	if not them_base then
		return 0
	end
	
	local round_value = function(val)
		return math.floor(val * 10000) / 10000
	end
	
	local taken = 0
	local inventory = unit:inventory()

	if inventory then
		for _, weapon in pairs(inventory:available_selections()) do
			local took = round_value(weapon.unit:base():add_ammo_from_bag(them_base.ammo_amount))
			taken = taken + took
			them_base.ammo_amount = round_value(them_base.ammo_amount - took)
			set_them_data(them, them_base)
			
			if them_base.ammo_amount <= 0 then
				taken = 2
				them_base.ammo_amount = 0
				them_base._empty = true
				set_them_data(them, them_base)
				return taken
			end
		end
	end
	return taken
end

Hooks:Add("GameSetupUpdate", __Name(1), function(__t, __dt)
	local all_key_units = ThisFakeAmmoBagBase.all_key_units
	if type(all_key_units) == "table" then		
		for __key, __data in pairs(all_key_units) do
			if type(__key) == "userdata" and type(__data) == "table" and type(__data.__time) == "number" then
				if __data.__time > 0 then
					ThisFakeAmmoBagBase.all_key_units[__key].__time = all_key_units[__key].__time - __dt
				end
				if __data.__time <= 0 then
					remove_unit(__data.__this_bag)
					remove_unit(__data.__key_unit)
					ThisFakeAmmoBagBase.all_key_units[__key] = nil
				end
			end
		end
	end
end)