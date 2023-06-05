-- Class ChargeAttacker v 0.1  (2023-06-05)
-- By Hairy77
-- 
-- Usage:
--      CA = ChargeAttacker:New('MainAttack')  -- (Mainattack being it's designated name)
--      CA.reinforceDistance = 10000           --Change reinforcedistance out to 10kms)
--      CA:Start()

-- Optional Parameters:

-- Default values
-- ChargeAttacker.retaliateGroupTypes   = { "2S6 Tunguska", "BMP-1" }  -- Specify which group types should retaliate. (Has a default set if not assigned)
-- ChargeAttacker.reinforceGroupTypes   = { "2S6 Tunguska", "BMP-1" }  -- Specify which unit types are willing to respond to reinforcement calls. (Has a default set if not assigned)
-- ChargeAttacker.reinforceGroups       = { 'MYGROUP-1' }              -- Use to specify individual groups that can be used for reinforcement
-- ChargeAttacker.resetDistance         = 1000                         -- (Defaults 1km) - If the attacker has moved more than this from the original place, recalculate the attack
-- ChargeAttacker.directChargeDistance  = 3000                         -- (Defaults 3km) - If the attacked group is within this range, it will attack directly regardless of other parameters
-- ChargeAttacker.reinforceDistance     = 7000                         -- (Defaults 7kms) Specify the maximum distance from which reinforcements will be called in
-- ChargeAttacker.excludeNames          = {'NOMOVE', 'POW'}            -- Specify a substring of group names for excluding. This is a PARTIAL match. Defaults so groups with NOMOVE and POW will not respond
-- ChargeAttacker.excludeReinforcements = {'NOREINF'}                  -- Specify a substring of group names for excluding as part of reinforcements. This is a PARTIAL match. Defaults so groups with NOREINF in the name will not reinforce. (Handy if you want a group to retaliate directly but ignore requests for reinforcements)
-- ChargeAttacker.ChargeRandom          = true                         -- Specify if you want the attacked group to consider flanking or just charge directly
-- ChargeAttacker.callReinforcements    = true                         -- (Defaults true) Specify if you want the attacked group to call in reinforcements

--                      W A R N I N G 
--      -- DO NOT SET THE BELOW PARAMETERS - BROKEN AT THIS TIME
--    ChargeAttacker.returnHome   (Leave false) - Specifies if you want the groups to return back to original position when finished ** BROKEN **

ChargeAttacker = {
    ClassName = "ChargeAttacker",
}

function stringmatches(textline, subtext)
    result = false
    if (string.find(textline, subtext)) or (textline == subtext) then
       result = true
    end
    return result
 end

function ChargeAttacker:New(name)
    local self = routines.utils.deepCopy( self ) -- Create a new self instance
    self.name = name
    self.active = false
    self.returnHome = false
    self.retaliateGroupTypes = { "2S6 Tunguska", "BMP-1", "BMP-2", "BMP-3", "BRDM-2", "BTR-80", "BTR-D", "Challenger2", "Gepard", "HL_KORD", "Leopard1A3", "M-1 Abrams", "M-2 Bradley", "M1126 Stryker ICV", "M1126 Stryker ICV", "M163 Vulcan", "M6 Linebacker", "Marder", "MCV-80", "SA-8 Osa", "Strela-1 9P31", "Strela-10M3", "T-55", "T-72B", "T-72B3", "T-80UD", "T-90", "Ural-375 ZU-23", "Ural-375 ZU-23 Insurgent", "ZSU-23-4 Shilka", "tt_DSHK", "tt_DSHK", "tt_KORD" }
    self.reinforceGroupTypes = { "2S6 Tunguska", "BMP-1", "BMP-2", "BMP-3", "BRDM-2", "BTR-80", "BTR-D", "Challenger2", "Gepard", "HL_KORD", "Leopard1A3", "M-1 Abrams", "M-2 Bradley", "M1126 Stryker ICV", "M1126 Stryker ICV", "M163 Vulcan", "M6 Linebacker", "Marder", "MCV-80", "SA-8 Osa", "Strela-1 9P31", "Strela-10M3", "T-55", "T-72B", "T-72B3", "T-80UD", "T-90", "Ural-375 ZU-23", "Ural-375 ZU-23 Insurgent", "ZSU-23-4 Shilka", "tt_DSHK", "tt_DSHK", "tt_KORD" }
    self.reinforceGroups = {}  -- Can populate with individual names of Groups if preferred
    self.resetDistance = 1000 --Distance that a new counter-attack will be calculated if the current destination waypoint is more than x meters from the target
    self.directChargeDistance = 3000 --Distance that the units will charge directly at the attacker
    self.reinforceDistance = 7000
    self.excludeNames = {'NOMOVE', 'POW'}  -- Any group with this in it will be ignored regardless of it's group type.
    self.excludeReinforcements = {'NOREINF'}
    self.ChargeRandom = true
    self.callReinforcements = true
    self.ChargeCommands = {}  -- Private - do not change
    return self
end


function ChargeAttacker:Start()
    self.evhhit_ChargeAttack = EVENTHANDLER:New()
    self.evhhit_ChargeAttack:HandleEvent(EVENTS.Hit)
    local selfref = self
    function self.evhhit_ChargeAttack:OnEventHit(EventData)
        selfref:HandleChargeAttack(EventData)    -- Not working because this is 'outside' and thus doesn't have access to self?
    end    
    self.active = true    
end

function ChargeAttacker:Stop()
    self.active = false
end

function ChargeAttacker:HandleChargeAttack(EventData)
    local attackgroup = EventData.IniGroup
    local defendgroup = EventData.TgtGroup
    if attackgroup and defendgroup and self.active == true then
       self:DoChargeAttack(attackgroup, defendgroup, true, false)
    end
end

function ChargeAttacker:DoChargeAttack(attackgroup, defendgroup, callreinforcements, isreinforcement)
    local functioncall = "Charge: "
    if isreinforcement then
       functioncall = "Reinforcement Charge: "
    end
 

    if attackgroup ~= nil and defendgroup ~= nil then -- the attacker must still be alive -- there must still be some units alive
      local moveflag = true
      for i = 1, #self.excludeNames do       
       if stringmatches(string.upper(defendgroup.GroupName), string.upper(self.excludeNames[i]))  then 
         moveflag = false
       end
      end


      for i = 1, #self.excludeReinforcements do       
        if (stringmatches(string.upper(defendgroup.GroupName), string.upper(self.excludeReinforcements[i]))) and (isreinforcement == true)  then --Don't have POW Convoys Charge
         moveflag = false
        end    
      end
 
       if moveflag == true then
          if attackgroup:IsHelicopter() or attackgroup:IsGround() then -- if your attacking me from the helicopter or a ground unit
             local mooseAttackGroup = GROUP:FindByName(attackgroup.GroupName)
             local mooseDefendGroup = GROUP:FindByName(defendgroup.GroupName)
             if mooseAttackGroup and mooseDefendGroup then
                local attackerLocation = mooseAttackGroup:GetVec3()
                local defenderLocation = mooseDefendGroup:GetVec3()
                local attackedUnits = mooseDefendGroup:GetUnits()
                local _chargeflag = false
                local alreadyEnroute = false
 
                local closingDistance = mooseDefendGroup:GetCoordinate():Get2DDistance(mooseAttackGroup:GetCoordinate())
 
                for i = #self.ChargeCommands, 1, -1 do  
                   if self.ChargeCommands[i].group and mooseDefendGroup and self.ChargeCommands[i].group == mooseDefendGroup.GroupName then
                      local distanceDiff = self.ChargeCommands[i].coord:Get2DDistance(mooseAttackGroup:GetCoordinate())
 
                      if (distanceDiff > self.resetDistance) or (closingDistance < self.directChargeDistance) or (alreadyEnroute ~= true) then
                         table.remove(self.ChargeCommands, i)
                         env.info(functioncall .. mooseDefendGroup.GroupName .. " RETASKER - is being re-tasked due to coordinate changing")
                      else
                         alreadyEnroute = true
                      end
                   end
                end

                local checkTable = self.retaliateGroupTypes
                if isreinforcement then 
                    checkTable = self.reinforceGroupTypes
                end    
 
                if not alreadyEnroute then
                   for i = 1, #attackedUnits do
                      if attackedUnits[i] and attackedUnits[i]:GetDesc() then
                         for _, unitType in pairs(checkTable) do
                            if attackedUnits[i]:GetDesc().typeName == unitType then
                               _chargeflag = true
                            end
                         end
                         for _, groupName in pairs(self.reinforceGroups) do 
                            _chargeflag = _chargeflag or mooseDefendGroup:GetName() == groupName
                         end
                      end
                   end
                end
 
                if attackerLocation and _chargeflag and defenderLocation then
                   local Points = {}
                   local initcoord = COORDINATE:NewFromVec3(defenderLocation)
                   local initheading = initcoord:HeadingTo(attackerLocation)
                   initcoord:SetHeading(initheading)
                   local attackercoord = COORDINATE:NewFromVec3(mooseAttackGroup:GetCoord())
                   local randomPointNearTarget = mooseAttackGroup:GetVec3(500)
                   local distance = attackercoord:Get2DDistance(initcoord)
 
                   if self.ChargeRandom then
                      local randomPointNearTarget = mooseAttackGroup:GetRandomVec3(500)
                   end
 
                   local attacktype = math.random(3)
                   if (closingDistance < self.directChargeDistance) then
                      attacktype = 4 --Override for direct charge at this distaince!
                   end
 
                   if isreinforcement == true then
                      attacktype = 4
                   end
 
                   local offsetheading = 0
 
                   if attacktype > 2 then
                      local vec2Coord = {x = attackerLocation.x, y = attackerLocation.z}
                      local wp1 = COORDINATE:NewFromVec2(vec2Coord)
                      local wpA = initcoord:Translate(distance * 0.5, initheading)
                      local wpB = initcoord:Translate(0, 0)
 
                      local Points = {}
                      Points[#Points + 1] = initcoord:WaypointGround(120, "Vee")
                      Points[#Points + 1] = wp1:WaypointGround(120, "Vee")
                      if self.returnHome then
                        Points[#Points + 1] = wpA:WaypointGround(120, "Vee")
                        Points[#Points + 1] = wpB:WaypointGround(120, "Vee")  --Returning fully home causes issues. :(
                      end
 
                      local taskroute = mooseDefendGroup:TaskRoute(Points)
                      mooseDefendGroup:SetTask(taskroute)
                      env.info(functioncall ..mooseDefendGroup.GroupName .." is charging " .. mooseAttackGroup.GroupName .. " using method " .. attacktype)
 
                      table.insert(self.ChargeCommands, {group = mooseDefendGroup.GroupName, coord = attackercoord, lastattacktype = attacktype})
                   else
                      if attacktype == 1 then
                         offsetheading = initheading + 090
                         env.info("Counter-attack Initiated: " .. mooseDefendGroup.GroupName .. " is RIGHT-FLANKING " .. attackgroup.GroupName .. "!")
                      end
                      if attacktype == 2 then
                         offsetheading = initheading - 090
                         env.info("Counter-attack Initiated: " .. mooseDefendGroup.GroupName .. " is LEFT-FLANKING " .. attackgroup.GroupName .. "!")
                      end
 
                      if offsetheading > 360 then
                         offsetheading = offsetheading - 360
                      end
                      if offsetheading < 0 then
                         offsetheading = offsetheading + 360
                      end
 
                      local wp1 = initcoord:Translate(distance, offsetheading)
                      wp1:SetHeading(initheading)
                      local wp3 = COORDINATE:NewFromVec3(randomPointNearTarget)
                      local wp2 = wp3:Translate(distance, offsetheading)
                      local wpA = initcoord:Translate(distance * 0.5, initheading)
                      local wpB = initcoord:Translate(0, 0)
 
                      local Points = {}
                      Points[#Points + 1] = initcoord:WaypointGround(120, "Vee")
                      Points[#Points + 1] = wp1:WaypointGround(120, "Vee")
                      Points[#Points + 1] = wp2:WaypointGround(120, "Vee")
                      Points[#Points + 1] = wp3:WaypointGround(120, "Vee")
                      if self.returnHome then
                      Points[#Points + 1] = wpA:WaypointGround(120, "Vee")
                      Points[#Points + 1] = wpB:WaypointGround(120, "Vee")  --Returning home causes issues
                      end
 
                      local taskroute = mooseDefendGroup:TaskRoute(Points)
                      mooseDefendGroup:SetTask(taskroute)
                      table.insert(self.ChargeCommands, {group = mooseDefendGroup.GroupName, coord = wp3, lastattacktype = attacktype})
                   end
                   mooseDefendGroup:OptionAlarmStateRed()
                end
 
                if self.callReinforcements and not isreinforcement  then  -- Need not isreinforcement otherwise we get Stack Overflow!
                   local routeunits = SET_GROUP:New():FilterCoalitions("red"):FilterCategoryGround():FilterActive(true):FilterOnce()
                   if routeunits ~= nil then
                      routeunits:ForEach(function(g)
                         if g:IsAlive() == true and g:GetName() ~= mooseDefendGroup:GetName() then
                            local _reenforcegroup = GROUP:FindByName(g:GetName())
                            gc = _reenforcegroup:GetCoordinate()
                            if gc == nil then
                               BASE:E({"Could not get Coord for group:", g:GetName(), g:GetCoordinate(), gc})
                            else
                               local d = gc:Get2DDistance(mooseAttackGroup:GetCoordinate())
                               if d < self.reinforceDistance then
                                  env.info(mooseDefendGroup.GroupName.." is requesting Reenforcement assistance from " .. _reenforcegroup:GetName())
                                  self:DoChargeAttack(attackgroup, g, false, true)
                               else
                               end
                            end
                         end
                      end)
                   end
                end --Call reinforcements
 
             end
          end
       end
    end
 end
