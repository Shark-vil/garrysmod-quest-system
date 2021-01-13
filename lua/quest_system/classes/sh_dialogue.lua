-- Global table for working with dialogs
QuestDialogue = {}

-------------------------------------
-- Checks for the correctness of the entity class and model, as well as the condition for issuing a dialog.
-------------------------------------
-- @param npc entity - any entity, not necessarily an NPC
-- @param ply entity - player entity
-- @param data table - dialogue data
-------------------------------------
-- @return bool - true if the entity matches validation, else false
-------------------------------------
function QuestDialogue:IsValidParentNPCDialogue(npc, ply, data)
    local nice = true

    if data.class ~= nil then
        if isstring(data.class) then
            if data.class:lower() ~= npc:GetClass():lower() then nice = false end
        end

        if istable(data.class) then
            for _, v in pairs(data.class) do
                if v:lower() == npc:GetClass():lower() then
                    nice = true
                    break
                else
                    nice = false
                    break
                end
            end
        end
    end

    if data.model ~= nil then
        if isstring(data.model) then
            if data.model:lower() ~= npc:GetModel():lower() then
                nice = false
            else
                nice = true
            end
        end

        if istable(data.model) then
            for _, v in pairs(data.model) do
                if v:lower() == npc:GetModel():lower() then
                    nice = true
                    break
                else
                    nice = false
                    break
                end
            end
        end
    end

    if data.condition ~= nil then
        local result = data.condition(ply, npc)
        if result ~= nil and result == false then nice = false end
    end

    return nice
end

-------------------------------------
-- Get dialog data from the global list using an identifier.
-------------------------------------
-- @param id string - dialogue id
-------------------------------------
-- @return table - dialog data table or nil if dialog doesn't exist
-------------------------------------
function QuestDialogue:GetDialogue(id)
    return list.Get('QuestSystemDialogue')[id]
end

-------------------------------------
-- Get a list of all registered dialogs.
-------------------------------------
-- @return table - list of all dialogs with IDs as keys
-------------------------------------
function QuestDialogue:GetAllDialogues()
    return list.Get('QuestSystemDialogue')
end

-------------------------------------
-- Get a list of all registered dialogs of type "isRandomNpc".
-------------------------------------
-- @return table - list of all dialogs with IDs as keys
-------------------------------------
function QuestDialogue:GetAllRandom()
    local data = {}
    for key, value in pairs(list.Get('QuestSystemDialogue')) do
        if value.isRandomNpc then
            data[key] = value
        end
    end
    return data
end

-------------------------------------
-- Get a list of all registered dialogs of type "isBackground".
-------------------------------------
-- @return table - list of all dialogs with IDs as keys
-------------------------------------
function QuestDialogue:GetAllBackground()
    local data = {}
    for key, value in pairs(list.Get('QuestSystemDialogue')) do
        if value.isBackground then
            data[key] = value
        end
    end
    return data
end

-------------------------------------
-- Automatic assignment of a dialogue ID for NPCs. Will not assign anything if checks fail.
-------------------------------------
-- @param npc entity - any entity, not necessarily an NPC
-- @param ply entity - player entity
-------------------------------------
function QuestDialogue:AutoParentToNPC(npc, ply)
    local dialogues = QuestDialogue:GetAllDialogues()

    for key, data in pairs(dialogues) do
        if self:IsValidParentNPCDialogue(npc, ply, data) then
            local is_done = true

            if data.randomNumber ~= nil and data.randomNumber > 0 then
                if math.random(1, data.randomNumber) ~= 1 then is_done = false end
            end

            if is_done then
                npc.npc_dialogue_id = data.id
                break
            end
        end
    end
end

-------------------------------------
-- Assigning a specific dialogue ID for the NPC. Will not assign anything if checks fail.
-------------------------------------
-- @param id string - dialogue id
-- @param npc entity - any entity, not necessarily an NPC
-- @param ply entity - player entity
-- @param ignore_valid bool - pass true, if you want to ignore the validation check
-- @param ignore_random bool - pass true, if you want to ignore the randomness of the dialog assignment
-------------------------------------
function QuestDialogue:ParentToNPC(id, npc, ply, ignore_valid, ignore_random)
    local dialogue = QuestDialogue:GetDialogue(id)

    if dialogue ~= nil then
        if not self:IsValidParentNPCDialogue(npc, ply, dialogue) and not ignore_valid then
            return
        end

        if not ignore_random and data.randomNumber ~= nil and data.randomNumber > 0 then
            if math.random(1, data.randomNumber) ~= 1 then 
                return
            end
        end

        npc.npc_dialogue_id = id
    end
end

-------------------------------------
-- Starts a dialogue with the NPC.
-------------------------------------
-- @param id string - dialogue id
-- @param ply entity - player entity
-- @param npc entity - any entity, not necessarily an NPC
-------------------------------------
function QuestDialogue:SetPlayerDialogue(id, ply, npc)
    if QuestDialogue:GetDialogue(id) ~= nil then
        local dialogue_ent = ents.Create('quest_dialogue')
        dialogue_ent:Spawn()
        dialogue_ent:SetDialogueID(id)
        dialogue_ent:SetStep('start')
        dialogue_ent:SetPlayer(ply)
        dialogue_ent:SetNPC(npc)

        timer.Simple(1.5, function()
            dialogue_ent:StartDialogue()
        end)

        return dialogue_ent
    end

    return NULL
end

-------------------------------------
-- Start a single NPC replic without any functionality.
-------------------------------------
-- @param ply entity - player entity
-- @param npc entity - any entity, not necessarily an NPC
-- @param name string - interlocutor name
-- @param text string - dialogue text
-- @param delay number - window activity time
-------------------------------------
function QuestDialogue:SingleReplic(ply, npc, name, text, delay, is_background)
    is_background = is_background or false

    local dialogue_ent = ents.Create('quest_dialogue')
    dialogue_ent:Spawn()
    dialogue_ent:SingleReplic(name, text, delay, is_background)
    dialogue_ent:SetStep('start')
    dialogue_ent:SetPlayer(ply)
    dialogue_ent:SetNPC(npc)

    timer.Simple(1.5, function()
        dialogue_ent:StartDialogue()
    end)

    return dialogue_ent
end