-- Class ChargeAttacker v0.24
-- By Hairy77 with thanks to Rob Graham for Help & Support
--
-- Usage:
--      CA = ChargeAttacker:New('MainAttack')  -- (Mainattack being its designated name)
--      CA.reinforceDistance = 10000                 -- Change reinforce distance to 10kms
--      CA.maxReinforcements = 5                     -- Maximum number of reinforcement groups
--      CA.flankDistance = 3000                      -- Distance for flanking
--      CA:Start()

ChargeAttacker = {
    ClassName = "ChargeAttacker",
    maxReinforcements = 3,
    reinforceDistance = 10000,
    recalculatedistance = 1500,
    flankDistance = 3000, -- Distance for flanking
    excludeNames = {"NOMOVE", "POW"},
    excludeReinfNames = {"NOREINF"},
    chargeRandom = true, -- Randomly decide whether to flank or charge directly
    retaliateGroupTypes = {
        "2S6 Tunguska",
        "BMP-1",
        "BMP-2",
        "BMP-3",
        "BRDM-2",
        "BTR-80",
        "BTR-D",
        "Challenger2",
        "Gepard",
        "HL_KORD",
        "Leopard1A3",
        "M-1 Abrams",
        "M-2 Bradley",
        "M1126 Stryker ICV",
        "M1126 Stryker ICV",
        "M163 Vulcan",
        "M6 Linebacker",
        "Marder",
        "MCV-80",
        "SA-8 Osa",
        "Strela-1 9P31",
        "Strela-10M3",
        "T-55",
        "T-72B",
        "T-72B3",
        "T-80UD",
        "T-90",
        "Ural-375 ZU-23",
        "Ural-375 ZU-23 Insurgent",
        "ZSU-23-4 Shilka",
        "tt_DSHK",
        "tt_DSHK",
        "tt_KORD"
    }, -- Specify group types that can retaliate (set in initialization)
    reinforceGroupTypes = {
        "2S6 Tunguska",
        "BMP-1",
        "BMP-2",
        "BMP-3",
        "BRDM-2",
        "BTR-80",
        "BTR-D",
        "Challenger2",
        "Gepard",
        "HL_KORD",
        "Leopard1A3",
        "M-1 Abrams",
        "M-2 Bradley",
        "M1126 Stryker ICV",
        "M1126 Stryker ICV",
        "M163 Vulcan",
        "M6 Linebacker",
        "Marder",
        "MCV-80",
        "SA-8 Osa",
        "Strela-1 9P31",
        "Strela-10M3",
        "T-55",
        "T-72B",
        "T-72B3",
        "T-80UD",
        "T-90",
        "Ural-375 ZU-23",
        "Ural-375 ZU-23 Insurgent",
        "ZSU-23-4 Shilka",
        "tt_DSHK",
        "tt_DSHK",
        "tt_KORD"
    },  -- Specify group types that can reinforce (set in initialization)
    lastHitTime = {}, -- Store the last hit time for each group to avoid multiple reinforcements
    lastAttackerPositions = {}, -- Store the last attacker positions to ensure distance check
}

function ChargeAttacker:New(name)
    local self = mist.utils.deepCopy(ChargeAttacker) -- Create a new self instance with default values
    self.name = name
    self.active = false
    return self
end

function ChargeAttacker:Start()
    self.evhhit_ChargeAttack = EVENTHANDLER:New()
    self.evhhit_ChargeAttack:HandleEvent(EVENTS.Hit)
    local selfref = self
    function self.evhhit_ChargeAttack:OnEventHit(EventData)
        selfref:HandleChargeAttack(EventData)
    end
    self.active = true
    env.info(self.name .. " started.")
end

function ChargeAttacker:Stop()
    self.active = false
    env.info(self.name .. " stopped.")
end

function ChargeAttacker:HandleChargeAttack(EventData)
    local attackGroup = EventData.IniGroup
    local defendGroup = EventData.TgtGroup
    local currentTime = timer.getTime()

    if attackGroup and defendGroup and self.active then
     if attackGroup:IsHelicopter() then 
        env.info("Handling charge attack: Attacker: " .. attackGroup.GroupName .. " | Defender: " .. defendGroup.GroupName)

        -- Check if enough time has passed since the last hit
        if self.lastHitTime[defendGroup.GroupName] == nil or (currentTime - self.lastHitTime[defendGroup.GroupName]) > 5 then
            local attackerCurrentPosition = attackGroup:GetCoordinate()

            -- Check if the defend group has been attacked before and if the attacker is within 1500 meters of the previous position
            if self.lastAttackerPositions[defendGroup.GroupName] == nil or attackerCurrentPosition:Get2DDistance(self.lastAttackerPositions[defendGroup.GroupName]) > self.recalculatedistance then
                self.lastHitTime[defendGroup.GroupName] = currentTime
                self.lastAttackerPositions[defendGroup.GroupName] = attackerCurrentPosition

                if self:IsRetaliateGroup(defendGroup) then
                    env.info(defendGroup.GroupName .. " is a valid retaliate group.")
                    self:TaskGroupToAttack(defendGroup, attackGroup) -- Ensure the defend group attacks the attacker
                    self:CallReinforcements(attackGroup, defendGroup)
                else
                    env.info(defendGroup.GroupName .. " is NOT a valid retaliate group.")
                end
            else
                env.info(attackGroup.GroupName .. " has not moved more than 1500 meters from its previous position. No new path calculated.")
            end
        else
            env.info(defendGroup.GroupName .. " was attacked again too soon. Ignoring this hit.")
        end
     end
   end
end

function ChargeAttacker:CallReinforcements(attackGroup, defendGroup)
    local reinforceCount = 0
    local defendGroupName = defendGroup.GroupName
    local attackerCoord = attackGroup:GetCoordinate()

    if self:IsExcluded(defendGroupName) then
        env.info(defendGroupName .. " is excluded from calling reinforcements.")
        return
    end

    env.info(defendGroupName .. " is calling reinforcements.")
    if attackerCoord then
        local potentialReinforcements = SET_GROUP:New():FilterCoalitions("red"):FilterCategoryGround():FilterActive(true):FilterOnce()
        potentialReinforcements:ForEachGroup(function(group)
            -- Check if the group is not the defend group itself
            if group:GetName() ~= defendGroupName then
                -- Check if the group is a valid reinforce group
                if self:IsReinforceGroup(group) then
                    -- Check if the group is not excluded
                    if not self:IsExcluded(group:GetName()) then
                        local groupCoord = group:GetCoordinate()
                        local distance = groupCoord:Get2DDistance(attackerCoord) -- Compare distance between reinforcement group and attacker group

                        -- Check if the group is within reinforce distance
                        if distance <= self.reinforceDistance and reinforceCount <= self.maxReinforcements then
                            self:TaskGroupToAttack(group, attackGroup)
                            reinforceCount = reinforceCount + 1
                            env.info(group:GetName() .. " is reinforcing " .. defendGroupName .. ". Reinforce count: " .. reinforceCount)
                        else
                            env.info(group:GetName() .. " is out of reinforce distance.")
                        end
                    else
                        env.info(group:GetName() .. " is excluded from reinforcing.")
                    end
                else
                    env.info(group:GetName() .. " is not a valid reinforce group.")
                end
            else
                env.info(group:GetName() .. " is the defend group itself and won't reinforce.")
            end

            if reinforceCount >= self.maxReinforcements then
                return
            end
        end)
    end
end

function ChargeAttacker:TaskGroupToAttack(group, targetGroup)
    local targetCoord = targetGroup:GetCoordinate()
    local Points = {}
    local groupCoord = group:GetCoordinate()
    local distance = groupCoord:Get2DDistance(targetCoord)
    local initheading = groupCoord:HeadingTo(targetCoord)
    local flankDirection = 90

    if self.chargeRandom and math.random() > 0.5 then
        -- Flanking movement logic
        if math.random() > 0.5 then
            flankDirection = initheading + 90
        else
            flankDirection = initheading - 90
        end

        if flankDirection > 360 then flankDirection = flankDirection - 360 end
        if flankDirection < 0 then flankDirection = flankDirection + 360 end

        local wp0 = groupCoord:Translate(0, 0)
        local wp1 = groupCoord:Translate(self.flankDistance, flankDirection)
        local wp2 = targetCoord:Translate(self.flankDistance, flankDirection)
        local wp3 = targetCoord:Translate(1000, initheading)
        local wp0type = wp0:GetSurfaceType()
        local wp1type = wp1:GetSurfaceType()
        local wp2type = wp2:GetSurfaceType()
        local wp3type = wp3:GetSurfaceType()

        if wp0type == land.SurfaceType.LAND or wp0type == land.SurfaceType.ROAD then 
        Points[#Points + 1] = wp0:WaypointGround(50, "Vee")
        else
         env.info('Skipping WP0 - Type is not LAND or ROAD')   
        end

        if wp1type == land.SurfaceType.LAND or wp1type == land.SurfaceType.ROAD then 
        Points[#Points + 1] = wp1:WaypointGround(50, "Vee")
    else
        env.info('Skipping WP1 - Type is not LAND or ROAD')   
       end

       if wp2type == land.SurfaceType.LAND or wp2type == land.SurfaceType.ROAD then 
        Points[#Points + 1] = wp2:WaypointGround(50, "Vee")
    else
        env.info('Skipping WP2 - Type is not LAND or ROAD')   
       end

       if wp3type == land.SurfaceType.LAND or wp3type == land.SurfaceType.ROAD then        
        Points[#Points + 1] = wp3:WaypointGround(50, "Vee")
    else
        env.info('Skipping WP3 - Type is not LAND or ROAD')   
       end
    else
        -- Direct charge
        local wp1 = groupCoord:Translate(distance * 0.5, initheading) -- Intermediate point halfway to the target
        local wp2 = targetCoord:Translate(1000, initheading) -- Final point 1000 meters from the target
        local wp1type = wp1:GetSurfaceType()
        local wp2type = wp2:GetSurfaceType()

        if wp1type == land.SurfaceType.LAND or wp1type == land.SurfaceType.ROAD then 
        Points[#Points + 1] = wp1:WaypointGround(50, "Vee")
    else
        env.info('Skipping WP1 - Type is not LAND or ROAD')   
       end

       if wp2type == land.SurfaceType.LAND or wp2type == land.SurfaceType.ROAD then 
        Points[#Points + 1] = wp2:WaypointGround(50, "Vee")
    else
        env.info('Skipping WP2 - Type is not LAND or ROAD')   
       end

    end

    local taskRoute = group:TaskRoute(Points)
    group:SetTask(taskRoute)
end

function ChargeAttacker:IsRetaliateGroup(group)
    for _, unit in ipairs(group:GetUnits()) do
        if #self.retaliateGroupTypes == 0 or self:IsInList(unit:GetTypeName(), self.retaliateGroupTypes) then
            return true
        end
    end
    return false
end

function ChargeAttacker:IsReinforceGroup(group)
    local groupName = group:GetName()
    for _, excludeName in ipairs(self.excludeReinfNames) do
        if string.find(groupName, excludeName) then
            return false
        end
    end

    for _, unit in ipairs(group:GetUnits()) do
        if #self.reinforceGroupTypes == 0 or self:IsInList(unit:GetTypeName(), self.reinforceGroupTypes) then
            return true
        end
    end
    return false
end

function ChargeAttacker:IsExcluded(groupName)
    for _, excludeName in ipairs(self.excludeNames) do
        if string.find(groupName, excludeName) then
            return true
        end
    end
    return false
end

function ChargeAttacker:IsInList(value, list)
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end
    return false
end