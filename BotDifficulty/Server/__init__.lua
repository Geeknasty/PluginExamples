-- BotDifficulty
-- Sets bot difficulty automatically when a level loads
-- Use /botdiff <value> to change difficulty in-game (or/botdifficulty or /bd for short)

local SetTimeout = require "common/timer".SetTimeout
local SetInterval = require "common/timer".SetInterval

-- Helper function to split strings
local function split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter or "%s")
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end

-- Difficulty scale reference:
-- 0 = Master, 3 = Knight, 6 = Hard, 9 = Medium, 12 = Easy
local BotDifficulty = {
    current = 6,  -- Default: Hard difficulty
    prefix = "[BotDifficulty] "
}

-- Difficulty presets for easy reference
local DifficultyPresets = {
    master = 0,
    knight = 3,
    hard = 6,
    medium = 9,
    easy = 12
}

function BotDifficulty:SetDifficulty(value, shouldBroadcast)
    -- Default to broadcasting if not specified
    if shouldBroadcast == nil then
        shouldBroadcast = true
    end
    
    -- Clamp value between 0 and 12
    value = math.max(0, math.min(12, value))
    
    local settings = Console.GetSettings("AutoPlayers")
    if settings then
        settings.AimNoiseScale = value
        self.current = value
        
        local presetName = self:GetPresetName(value)
        local message = string.format("%sBot difficulty set to: %d (%s)", 
            self.prefix, value, presetName)
        
        print(message)
        
        if shouldBroadcast then
            Console.Execute("Kyber.Broadcast " .. message)
        end
    else
        print(self.prefix .. "Error: Could not get AutoPlayers settings")
    end
end

function BotDifficulty:GetPresetName(value)
    for name, presetValue in pairs(DifficultyPresets) do
        if presetValue == value then
            return name:sub(1,1):upper() .. name:sub(2)
        end
    end
    return "Custom"
end

-- Broadcast helpful reminder every 10 minutes
SetInterval(function()
    Console.Execute("Kyber.Broadcast [BotDifficulty] Change difficulty with /bd <easy/medium/hard/knight/master>")
end, 600.0)  -- 600 seconds = 10 minutes

SetInterval(function()
    -- Silently enforce difficulty every 5 seconds
    BotDifficulty:SetDifficulty(BotDifficulty.current, false)
end, 5.0)

-- Set difficulty when level loads (silently, no broadcast)
EventManager.Listen("Level:Loaded", function(levelName, gameModeId)
    print("[BotDifficulty] Level loaded, will set difficulty in 30 seconds")

    SetTimeout(function()
        BotDifficulty:SetDifficulty(BotDifficulty.current, false)  -- false = don't broadcast
    end, 30.0)  -- 30 seconds
end)

-- Listen for chat commands
EventManager.Listen("ServerPlayer:SendMessage", function(player, message)
    if message:len() < 2 then return end
    local messageSplit = split(message)

    if #messageSplit <= 0 then return end
    if messageSplit[1]:len() < 2 then return end
    if messageSplit[1]:sub(1, 1) ~= '/' and messageSplit[1]:sub(1, 1) ~= '!' then return end

    local command = messageSplit[1]:lower():sub(2)

    -- Check if it's a botdiff command
    if command == "botdiff" or command == "botdifficulty" or command == "bd" then
        -- Cancel the message so it doesn't broadcast
        EventManager.SetCancelled(true)

        if #messageSplit < 2 then
            -- No argument provided, show current difficulty
            local currentPreset = BotDifficulty:GetPresetName(BotDifficulty.current)
            Console.Execute(string.format("Kyber.Broadcast %sCurrent difficulty: %d (%s)", 
                BotDifficulty.prefix, BotDifficulty.current, currentPreset))
            Console.Execute("Kyber.Broadcast Usage: /bd <value> or /bd <preset>")
            Console.Execute("Kyber.Broadcast Presets: master(0), knight(3), hard(6), medium(9), easy(12)")
            return
        end

        local arg = messageSplit[2]:lower()
        local newDifficulty = nil

        -- Check if it's a preset name
        if DifficultyPresets[arg] then
            newDifficulty = DifficultyPresets[arg]
        else
            -- Try to parse as number
            newDifficulty = tonumber(arg)
        end

        if newDifficulty == nil then
            Console.Execute("Kyber.Broadcast " .. BotDifficulty.prefix .. "Invalid difficulty value!")
            Console.Execute("Kyber.Broadcast Use a number (0-12) or preset: master, knight, hard, medium, easy")
            return
        end

        BotDifficulty:SetDifficulty(newDifficulty)  -- Defaults to true = broadcast
    end
end)