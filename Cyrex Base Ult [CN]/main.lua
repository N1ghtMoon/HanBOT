local common = module.load("CyrexBaseUlt", "common")
local orb = module.internal("orb")

local left_side = vec3(396,182,462)
local right_side = vec3(14340,172,14384)

-- Set player team side --
local side = right_side
if player.team == 200 then
	side = left_side
end

-------------------
-- Menu creation --
-------------------

local menu = menu("BaseUlt", "Base Ultimate");
menu:menu("r", "Ultimate Settings");
	menu.r:boolean("baseult", "Use Base Ultimate", true);
	menu.r:boolean("sb", "Only Combo Key Down", false)
	menu.r:boolean("ds", "Draw State", true)

local recalls = {}

recalls.timers =  {
    recall = 8.0;
    odinrecall = 4.5;
   	odinrecallimproved = 4.0;
    recallimproved = 7.0;
    superrecall = 4.0;
}

local function damage_reduction(unit)
  	local armor = ((unit.bonusArmor * player.percentBonusArmorPenetration) + (unit.armor - unit.bonusArmor)) * player.percentArmorPenetration
  	local lethality = (player.physicalLethality * .4) + ((player.physicalLethality * .6) * (player.levelRef / 18))
  	return armor >= 0 and (100 / (100 + (armor - lethality))) or (2 - (100 / (100 - (armor - lethality))))
end

local jDmg = {250,350,450};
local jPct = {0.25, 0.30, 0.35}
local ezDmg = {350, 500, 650}
local drDmg = {175, 275, 375}
local asDmg = {200, 400, 600}
local function ezDamage(unit)
	if player.charName == 'Jinx' then
		local dmg = jDmg[player:spellSlot(3).level]
		local pct_dmg = jPct[player:spellSlot(3).level]
		local mod = (((player.baseAttackDamage + player.flatPhysicalDamageMod) * player.percentPhysicalDamageMod) - player.baseAttackDamage) * 1.5
		local missing_hp = unit.maxHealth - unit.health
		local hp_mod = missing_hp * pct_dmg;
		return (dmg + mod + hp_mod) * damage_reduction(unit);
	elseif player.charName == "Ezreal" then
		local dmg = ezDmg[player:spellSlot(3).level]
		local ad = (common.GetBonusAD(player) * .78)
		local ap = (common.GetTotalAP(player) * .9)
		return (dmg + common.CalculatePhysicalDamage(target, ad) + common.CalculateMagicDamage(target, ap))
	elseif player.charName == 'Draven' then
		local dmg = drDmg[player:spellSlot(3).level]
		local mod = (((player.baseAttackDamage + player.flatPhysicalDamageMod) * player.percentPhysicalDamageMod) - player.baseAttackDamage) * 1
		return (dmg + mod) * damage_reduction(unit);
	elseif player.charName == "Ashe" then
		local dmg = asDmg[player:spellSlot(3).level]
		local mod = (common.GetTotalAP(player) * 0.8)
		return (dmg + common.CalculateMagicDamage(target, mod))
	end
end

local function calc_ult_speed(dist)
	if player.charName == 'Jinx' then
		return (dist > 1350 and (1350*1700+((dist-1350)*2200))/dist or 1700)
	elseif player.charName == "Ezreal" then
		return 2000
	elseif player.charName == "Draven" then
		return 2000
	elseif player.charName == "Ashe" then
		return 1600
	end
end

local function calc_hit_time()
    local dist = player.pos:dist(side);
    local speed = calc_ult_speed(dist);
    if player.charName == 'Jinx' then
    	return (dist / speed) + 0.65 + network.latency
    elseif player.charName == 'Draven' then
    	return (dist / speed) + 0.25 + network.latency
    elseif player.charName == 'Ezreal' then
    	return (dist / speed) + 1 + network.latency
    elseif player.charName == 'Ashe' then
    	return (dist / speed) + 0.25 + network.latency
    end
end

local function track_recall()
	if not menu.r.baseult:get() then return end
	for i = 0, objManager.enemies_n - 1 do
    	local x = objManager.enemies[i]
    	if not x then return end
    	if not recalls[x.networkID] then recalls[x.networkID] = {} end
    	local data = recalls[x.networkID];
    	if x.isRecalling then 
    		local recall_time = recalls.timers[x.recallName];
    		if not recall_time then return end
    		if data.recall then data.time = recall_time - (os.clock() - data.start) return end
			data.recall = true;
			data.time = recall_time;
			data.start = os.clock();
   		else
   			if data and data.recall then
   				data.recall = false;
   			end
   		end
   	end
end

local function base_ult()
	if not menu.r.baseult:get() then return end
	if player:spellSlot(3).state ~= 0 then return end
	
	for i = 0, objManager.enemies_n - 1 do
    	local x = objManager.enemies[i]
    	local data = recalls[x.networkID];

    	local path = mathf.closest_vec_line(x.pos, player.pos, side)
        if path and path:dist(x.pos) <= (120 + x.boundingRadius) then return end

        local health = (x.health + x.physicalShield) + (x.maxHealth * 0.021);
        if not x.isVisible then
        	health = health + ((x.healthRegenRate / 5) * calc_hit_time())
        end

    	if data.recall and data.time <= calc_hit_time() and not x.isDead and ezDamage(x) > health then
    		if data.time < calc_hit_time() - 0.1 then return end
    		player:castSpell("pos", 3, side); 
    	end
    end
end


local function ontick()
	if player.isDead or chat.isOpened then 
		return 
	end
	
	track_recall()
	if menu.r.sb:get() then
		if orb.combat.is_active() then
			base_ult()
		end
	else
		base_ult();
	end
end

local function ondraw()
	if player.isDead or chat.isOpened then 
		return
	end
	local pos = graphics.world_to_screen(player.pos)
	if menu.r.ds:get() and player:spellSlot(3).state == 0 and player.isOnScreen then 
		graphics.draw_text_2D("Base Ultimate: On", 14, pos.x-40, pos.y+49, graphics.argb(255,255,255,255))
	end
end

cb.add(cb.tick, ontick)
cb.add(cb.draw, ondraw)