-- CoopTeamFix
-- Ensures all players stay on the correct team in Co-op.
-- Prevents the engine from balancing players onto the AI bot teams.

local SetTimeout = require "common/timer".SetTimeout

local CoopTeamFix = {
    prefix = "[CoopTeamFix] ",
    currentLevel = nil,
    currentMode = nil,

    -- Configuration
    settings = {
        initialMoveDelay = 15.0, -- Time to wait for level initialization
        joinMidMatchDelay = 5.0, -- Time to wait for mid-match joiners
    },

    -- Co-op game modes
    MODES = {
        ATTACK = "Mode9",
        DEFEND = "ModeDefend"
    },

    TEAMS = {
        LIGHTSIDE = 1,
        DARKSIDE  = 2
    },

    -- List of Co-op maps and which side is the ATTACKER.
    -- The script automatically calculates the defender for "ModeDefend".
    CoopAttackerTeams = {
        -- Prequel Era
        ["Levels/MP/Kamino_01/Kamino_01"]                      = 2, -- DARKSIDE
        ["S5_1/Levels/MP/Geonosis_01/Geonosis_01"]             = 1, -- LIGHTSIDE
        ["S7_2/Levels/Naboo_03/Naboo_03"]                      = 2, -- DARKSIDE
        ["S7/Levels/Kashyyyk_02/Kashyyyk_02"]                  = 2, -- DARKSIDE
        ["S7_1/Levels/Kamino_03/Kamino_03"]                    = 2, -- DARKSIDE
        ["S6_2/Geonosis_02/Levels/Geonosis_02/Geonosis_02"]    = 1, -- LIGHTSIDE
        ["S8/Felucia/Levels/MP/Felucia_01/Felucia_01"]         = 1, -- LIGHTSIDE

        -- Original Trilogy
        ["S3/Levels/Kessel_01/Kessel_01"]                      = 1, -- LIGHTSIDE
        ["Levels/MP/Tatooine_01/Tatooine_01"]                  = 2, -- DARKSIDE
        ["Levels/MP/Yavin_01/Yavin_01"]                        = 2, -- DARKSIDE
        ["Levels/MP/Hoth_01/Hoth_01"]                          = 2, -- DARKSIDE
        ["S2_2/Levels/JabbasPalace_01/JabbasPalace_01"]        = 1, -- LIGHTSIDE
        ["Levels/MP/Endor_01/Endor_01"]                        = 1, -- LIGHTSIDE
        ["Levels/MP/DeathStar02_01/DeathStar02_01"]            = 1, -- LIGHTSIDE
        ["S9_3/Scarif/Levels/MP/Scarif_02/Scarif_02"]          = 1, -- LIGHTSIDE

        -- Sequel Era
        ["S9/Jakku_02/Jakku_02"]                               = 2, -- DARKSIDE
        ["S9/Takodana_02/Takodana_02"]                         = 2, -- DARKSIDE
        ["S9/StarKiller_02/StarKiller_02"]                     = 1, -- LIGHTSIDE
        ["S9/Paintball/Levels/MP/Paintball_01/Paintball_01"]   = 2, -- DARKSIDE
        ["S9_3/COOP_NT_MC85/COOP_NT_MC85"]                     = 2, -- DARKSIDE
        ["S9_3/COOP_NT_FOSD/COOP_NT_FOSD"]                     = 1, -- LIGHTSIDE
    }
}

--- LOGIC HELPERS ---

function CoopTeamFix:GetOppositeTeam(teamId)
    return (teamId == self.TEAMS.LIGHTSIDE) and self.TEAMS.DARKSIDE or self.TEAMS.LIGHTSIDE
end

function CoopTeamFix:GetPlayerTeam(levelName, gameModeId)
    local attackerTeam = self.CoopAttackerTeams[levelName]

    if not attackerTeam then return nil end

    if gameModeId == self.MODES.ATTACK then
        return attackerTeam
    elseif gameModeId == self.MODES.DEFEND then
        return self:GetOppositeTeam(attackerTeam)
    end

    return nil
end

--- PLAYER SWAPPING ---

function CoopTeamFix:MovePlayerToCorrectTeam(player, targetTeam)
    if player.isBot or not player.team then return end

    if player.team ~= targetTeam then
        local teamName = (targetTeam == self.TEAMS.LIGHTSIDE) and "LIGHTSIDE" or "DARKSIDE"
        print(self.prefix .. "Moving " .. player.name .. " to " .. teamName)
        player:SetTeam(targetTeam)
    end
end

function CoopTeamFix:MoveAllPlayersToCorrectTeam(targetTeam)
    local players = PlayerManager.GetPlayers()
    for _, player in ipairs(players) do
        self:MovePlayerToCorrectTeam(player, targetTeam)
    end
end

function CoopTeamFix:DisableTeamBalancing()
    Console.Execute("Kyber.DisableTeamBalancing true")
    Console.Execute("Whiteshark.AutoBalanceTeamsOnNeutral false")
end

--- EVENT LISTENERS ---

EventManager.Listen("Level:Loaded", function(levelName, gameModeId)
    CoopTeamFix.currentLevel = levelName
    CoopTeamFix.currentMode = gameModeId

    local targetTeam = CoopTeamFix:GetPlayerTeam(levelName, gameModeId)

    if targetTeam then
        print(CoopTeamFix.prefix .. "Co-op match detected.")
        CoopTeamFix:DisableTeamBalancing()

        SetTimeout(function()
            CoopTeamFix:MoveAllPlayersToCorrectTeam(targetTeam)
        end, CoopTeamFix.settings.initialMoveDelay)
    end
end)

EventManager.Listen("ServerPlayer:Joined", function(player)
    if CoopTeamFix.currentLevel and CoopTeamFix.currentMode then
        local targetTeam = CoopTeamFix:GetPlayerTeam(CoopTeamFix.currentLevel, CoopTeamFix.currentMode)

        if targetTeam then
            SetTimeout(function()
                CoopTeamFix:MovePlayerToCorrectTeam(player, targetTeam)
            end, CoopTeamFix.settings.joinMidMatchDelay)
        end
    end
end)

EventManager.Listen("ServerPlayer:Spawned", function(player)
    if player.isBot or not CoopTeamFix.currentLevel or not CoopTeamFix.currentMode then
        return
    end

    local targetTeam = CoopTeamFix:GetPlayerTeam(CoopTeamFix.currentLevel, CoopTeamFix.currentMode)
    if targetTeam and player.team ~= targetTeam then
        CoopTeamFix:MovePlayerToCorrectTeam(player, targetTeam)
    end
end)