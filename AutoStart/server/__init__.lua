-- AutoStart
-- Automatically starts coop games when at least one player is present
-- Solves the issue where coop servers require 2+ players to start by default

local SetTimeout = require "common/timer".SetTimeout

local AutoStartPlugin = {
    HasStartedGame = false,
    HasBroadcastStartMessage = false
}

-- Attempt to start the game if there's at least one human player present
function AutoStartPlugin:TryStartGame()
    -- Don't try to start if we've already started this round
    if self.HasStartedGame then
        return
    end
    
    -- Count human players (exclude bots)
    local players = PlayerManager.GetPlayers()
    local humanPlayerCount = 0
    
    for _, player in ipairs(players) do
        if not player.isBot then
            humanPlayerCount = humanPlayerCount + 1
        end
    end
    
    -- Start the game if at least one human player is present
    if humanPlayerCount > 0 then
        Console.Execute("startgame")
        self.HasStartedGame = true
        print("[AutoStart] Starting game with " .. humanPlayerCount .. " player(s)")
    else
        print("[AutoStart] No players connected, game not started")
    end
end

-- Primary trigger: Start game when level loads
EventManager.Listen("Level:Loaded", function()
    -- Reset flags for the new level
    AutoStartPlugin.HasStartedGame = false
    AutoStartPlugin.HasBroadcastStartMessage = false

    print("[AutoStart] Level loaded, will attempt to start game in 30 seconds")
    
    -- Broadcast message after 5 seconds
    SetTimeout(function()
        if not AutoStartPlugin.HasBroadcastStartMessage then
            Console.Execute("Kyber.Broadcast [AutoStart] Game will start automatically in 25 seconds")
            AutoStartPlugin.HasBroadcastStartMessage = true
        end
    end, 5.0)  -- 5 seconds
    
    -- Start game after 30 seconds total
    SetTimeout(function()
        print("[AutoStart] Timer completed, attempting to start game now")
        AutoStartPlugin:TryStartGame()
    end, 30.0)  -- 30 seconds
end)

-- Backup trigger: Start game when a player joins (if game hasn't started yet)
-- This handles the case where the level loaded with no players present
EventManager.Listen("ServerPlayer:Joined", function(player)
    print("[AutoStart] Player joined: " .. player.name)
    
    -- Only attempt to start if we haven't already started
    if not AutoStartPlugin.HasStartedGame then
        -- Broadcast if we haven't already
        if not AutoStartPlugin.HasBroadcastStartMessage then
            SetTimeout(function()
                if not AutoStartPlugin.HasBroadcastStartMessage then
                    Console.Execute("Kyber.Broadcast [AutoStart] Game will start automatically in 25 seconds")
                    AutoStartPlugin.HasBroadcastStartMessage = true
                end
            end, 5.0)  -- 5 seconds
        end
        
        SetTimeout(function()
            AutoStartPlugin:TryStartGame()
        end, 30.0)  -- 30 seconds
    end
end)