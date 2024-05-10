---@type boolean
local nuked = false
local stuck = false

local fossil = {}
local time = {}
World = {}

local farmIndex = 1
Start = 1
local totalFarm = 1

local messageId
local curVer = '0.1'

function MessageAllert(text)
    local message = MessageBox.new()
    message.title = '[' .. (Client and Client.index or 0) .. '] ' .. (Client and Client.name or 'Error Message')
    message.description = tostring(text)
    message:send()
end

function ReturnStatus()
    for i, v in pairs(BotStatus) do
        if v == Client.status then
            return i:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
                return first:upper() .. rest:lower()
            end)
        end
    end
    return 'Unknown'
end

function GetEmoji()
    if Client.status == BotStatus.online then
        return '<a:online:1160758807790624859>'
    else
        return '<a:offline:1160758900279234670>'
    end
end

function WebhookOffline()
    if WebhookStatus ~= '' then
        local webhook = Webhook.new(WebhookStatus)
        webhook.avatar_url =
        'https://cdn.discordapp.com/attachments/985689423796666419/1215737210242990160/Screenshot_2024-03-09_020520.png?ex=66104b82&is=65fdd682&hm=49e59eb32ca0020df9b21ce146a9a0ffee26b247c3e2dab0ad1293b5673eb32b&'
        webhook.username = 'Neuroman'
        webhook.content = GetEmoji() .. ' ' .. Client.name .. ' status is ' ..
            ReturnStatus() .. ' @everyone'
        webhook:send()
    end
end

local function formatTime(second)
    local days = math.floor(second / (24 * 3600))
    local remainingSeconds = second % (24 * 3600)
    local hours = math.floor(remainingSeconds / 3600)
    remainingSeconds = remainingSeconds % 3600
    local minutes = math.floor(remainingSeconds / 60)
    local seconds = remainingSeconds % 60

    return string.format("%d:%02d:%02d:%02d", days, hours, minutes, seconds)
end

local function generateInfoWorld()
    local info = {}
    local start = math.max(Start, #World - 8 + 1)
    for i = start, #World do
        local world, id = '', ''
        if World[i] and World[i]:find(':') then
            world, id = World[i]:match("(.+):(.+)")
        end
        local fossilCount = fossil[world] or 0
        local timeInfo = (time[world] and type(time[world]) == 'number') and ('<a:offf:1219704068868542465>' .. formatTime(os.difftime(os.time(), time[world]))) or '<a:onn:1219704070999248966> ' .. (time[world] or 'N/A')
        table.insert(info, string.format('%d.<:Globe:1208401533163671553>||%s|| (%d<:fossilrock:1228297533449830441> | %s)', i, world, fossilCount, timeInfo))
    end
    return table.concat(info, '\n')
end

local function createMessageID(url, content)
    url = url .. '?wait=1'
    local http = HttpClient.new()
    http.url = url
    http.headers['Content-Type'] = 'application/json'
    http:setMethod(Method.post)
    http.content = [[
    {
        "username":"Neuroman",
        "avatar_url":"https://raw.githubusercontent.com/maysens/Neurotation/main/images/logo.png",
        "embeds": [
            {
                "title":"]] .. content .. [[",
                "color": ]] .. math.random(111111, 999999) .. [[
            }
        ]
    }
]]
    local result = http:request()
    if result.error == 0 then
        local resultData = result.body:match('{"id":"(%d+)",')
        if resultData then
            return resultData
        end
    else
        print("Request Error: " .. result:getError())
    end
    return nil
end

function FoundFossil()
    local count = 0
    for _, m in pairs(fossil) do
        count = count + m
    end
    return count
end

---@param task  string
function WebhookInfo(task)
    if WebhookURL ~= '' then
        local fields = {
            {
                name = '<:pickaxe:1226659803162611815>Bot Task',
                value = task,
                inline = true
            },
            {
                name = '<:growbot:1133362502667866132>Bot Name',
                value = Client and (Client.name or 'Unknown') .. '(' .. (Client and Client.level or 0) .. ')',
                inline = true
            },
            {
                name = GetEmoji() .. 'Bot Status',
                value = ReturnStatus() .. '(' .. (Client and Client:getPing() or 0) .. ')',
                inline = true
            },
            {
                name = '<:Globe:1208401533163671553> Current World',
                value = '||' .. Client:getWorld().name .. '||',
                inline = true
            },
            {
                name = '<:fossilrock:1228297533449830441>Fossil Found',
                inline = true,
                value = FoundFossil() .. 'x'
            },
            {
                name = 'Inventory Statistic',
                value = '<:fossilbrush:1232230116872949842>Fossil Brush: ' ..
                    getInventory():findItem(4132) ..
                    'x\n<:polishedfossil:1224583845144432711>Polished Fossil: ' ..
                    getInventory():findItem(4134) ..
                    'x\n<:fossil:1228284575193628692>Fossil: ' .. getInventory():findItem(3936),
                inline = true
            },
            {
                name = 'World Statistic',
                value = generateInfoWorld() or 'nil',
                inline = true
            }
        }
        local webhook = Webhook.new(WebhookURL)
        webhook.embed1.use = true
        webhook.embed1.title = 'NeuroFossil'
        webhook.embed1.color = math.random(111111, 999999)
        for _, m in pairs(fields) do
            webhook.embed1:addField(m.name, m.value, m.inline)
        end
        webhook.embed1.footer.text = '[Lucifer]: NeuroFossil developed by Shiro\nLast Updated • ' ..
            (os.date("!%a %b %d, %Y at %I:%M %p", os.time() + 7 * 60 * 60))
        webhook.embed1.footer.icon_url =
        'https://raw.githubusercontent.com/maysens/Neurotation/main/images/logo.png'
        webhook.embed1.thumbnail = 'https://raw.githubusercontent.com/maysens/Neurotation/main/images/logo.png'
        if messageId then
            webhook:edit(messageId)
        else
            webhook:send()
        end
    end
end

local function Reconnect()
    if Client.status ~= BotStatus.online then
        WebhookOffline()
        WebhookInfo('Reconnecting...')
        local k, p, T, y, o = 8, 5, 0, 6, 5
        while Client.status ~= BotStatus.online do
            if T ~= 0 and T % (y * k) == 0 then
                for i = 1, (p * 60) do
                    sleep(1000)
                    if Client.status == BotStatus.online then
                        break
                    end
                end
            end
            if T == 0 or T % y == 0 then
                Client:connect()
            end
            T = T + 1
            for i = 1, o do
                sleep(1000)
                if Client.status == BotStatus.online then
                    break
                end
            end
            if Client.status == BotStatus.online then
                WebhookOffline()
                WebhookInfo('Reconnected')
                break
            elseif Client.status == BotStatus.account_banned then
                WebhookOffline()
                WebhookInfo('Account Banned')
                removeBot()
                sleep(1000)
                error('Terimnate script,account has been banned', 0)
            end
        end
    end
end

---@param world string
---@param id? string
function Warp(world, id)
    local function isInWhiteDoor()
        return getTile(Client.x, Client.y).fg == 6
    end
    world = world:upper()
    id = id or ''
    nuked, stuck = false, false
    local afterTries = 6
    local limitTries = 6
    local warpTries = 2
    local restTime = 5
    if not Client:isInWorld(world) then
        --- Event function
        ---@param var Variant
        ---@param netid? number
        addEvent(Event.variantlist, function(var, netid)
            if var:get(0):getString() == 'OnConsoleMessage' then
                local text = var:get(1):getString()
                if text == 'That world is inaccessible.' or text:find('created too many worlds') or text:find('Players lower than level') then
                    nuked = true
                end
            end
        end)

        local tries = 0
        local attempt = 5

        while not Client:isInWorld(world) and not nuked do
            Reconnect()
            if tries ~= 0 and tries % (afterTries * limitTries) == 0 then
                for i = 1, restTime * 60 do
                    sleep(1000)
                    listenEvents(1)
                    if Client:isInWorld(world) then
                        break
                    end
                end
            end
            tries = tries + 1
            if tries % warpTries == 0 then
                Client:warp(id == '' and world or world .. ('|' .. id))
            end
            for i = 1, attempt do
                listenEvents(1)
                sleep(1000)
                if Client:isInWorld(world) then
                    break
                end
            end
        end
    end
    if Client:isInWorld(world) and id ~= '' and isInWhiteDoor() then
        local tries = 0
        local delay = 5
        limitTries = 2
        warpTries = 4
        while isInWhiteDoor() and not stuck do
            if tries ~= 0 and tries % (afterTries * limitTries) == 0 then
                stuck = true
            end
            tries = tries + 1
            if tries % warpTries == 0 then
                Client:warp(id == '' and world or world .. ('|' .. id))
            end
            for i = 1, delay do
                sleep(1000)
                if not isInWhiteDoor() then
                    break
                end
            end
        end
    end
end

function CountFossil()
    local count = 0
    for _, tile in pairs(getTiles()) do
        if tile.fg == 3918 and hasAccess(tile.x, tile.y) and tile.flags < 4096 then
            count = count + 1
        end
    end
    return count
end

function Reposition(world, id, x, y)
    if Client.status ~= BotStatus.online then
        Reconnect()
        sleep(1000)
    end
    if Client.status == BotStatus.online then
        if world then
            Warp(world, id or '')
        end
        if x and y then
            while not Client:isInTile(x, y) do
                Client:findPath(x, y)
                if #Client:getPath(x, y) == 0 then
                    break
                end
            end
        end
    end
end

function GetTools()
    if #StorageTools == 0 then
        return error('There is currently no storage available for taking tools.')
    end
    local itemTools = { 3932, 3934 }
    for _, itm in pairs(itemTools) do
        while getInventory():findItem(itm) == 0 do
            for i, data in pairs(StorageTools) do
                local world, id = data, ''
                if world:find(':') then world, id = data:match('(.+):(.+)') end
                Warp(world, id)
                if not nuked then
                    if not stuck then
                        for _, object in pairs(getObjects()) do
                            if object.id == itm then
                                local object_x, object_y = math.floor((object.x + 10) * (1 / 32)),
                                    math.floor((object.y + 10) * (1 / 32))
                                while not Client:isInTile(object_x, object_y) do
                                    Client:findPath(object_x, object_y)
                                    Reposition(world, id, object_x, object_y)
                                end
                                if Client:isInTile(object_x, object_y) then
                                    Client:collectObject(object.oid, 3)
                                    sleep(500)
                                end
                                if getInventory():findItem(itm) > 1 then
                                    while getInventory():findItem(itm) > 1 do
                                        Client:moveTo(-1, 0)
                                        sleep(100)
                                        Client:setDirection(false)
                                        sleep(500)
                                        Client:drop(itm, getInventory():findItem(itm) - 1)
                                        sleep(500)
                                        Reposition(world, id, object_x - 1, object_y)
                                    end
                                end
                            end
                            if getInventory():findItem(itm) > 0 then
                                print('[' .. Client.index .. '] Success taking tools ' .. getInfo(itm).name)
                                break
                            end
                        end
                    else
                        table.remove(StorageTools, i)
                    end
                else
                    table.remove(StorageTools, i)
                end
            end
        end
    end
end

function GetBrushNRock(World, Id)
    if #StorageTools == 0 then
        return error('There is currently no storage available for taking tools.')
    end
    local itemTools = { 4132 }
    if ReplaceRock then
        table.insert(itemTools, 10)
    end
    for _, itm in pairs(itemTools) do
        if getInventory():findItem(itm) == 0 then
            WebhookInfo('Taking ' .. getInfo(itm).name)
            while getInventory():findItem(itm) == 0 do
                for i, data in pairs(StorageTools) do
                    local world, id = data, ''
                    if world:find(':') then world, id = data:match('(.+):(.+)') end
                    Warp(world, id)
                    if not nuked then
                        if not stuck then
                            for _, object in pairs(getObjects()) do
                                if object.id == itm then
                                    local object_x, object_y = math.floor((object.x + 10) * (1 / 32)),
                                        math.floor((object.y + 10) * (1 / 32))
                                    while not Client:isInTile(object_x, object_y) do
                                        Client:findPath(object_x, object_y)
                                        Reposition(world, id, object_x, object_y)
                                    end
                                    if Client:isInTile(object_x, object_y) then
                                        Client:collectObject(object.oid, 3)
                                        sleep(500)
                                    end
                                end
                                if getInventory():findItem(itm) > 0 then
                                    print('[' .. Client.index .. '] Success taking tools ' .. getInfo(itm).name)
                                    break
                                end
                            end
                        else
                            table.remove(StorageTools, i)
                        end
                    else
                        table.remove(StorageTools, i)
                    end
                end
            end
            Warp(World, Id)
        end
    end
end

function GetTileFossil()
    local tiles = {}
    for _, tile in pairs(getTiles()) do
        if tile.fg == 3918 and hasAccess(tile.x, tile.y) > 0 and tile.flags < 4096 then
            table.insert(tiles, tile)
        end
    end
    return tiles
end

function GetRange(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function IsCanFindPath(x, y)
    return (#Client:getPath(x, y) > 0 and not Client:isInTile(x, y)) or
        (#Client:getPath(x, y) == 0 and Client:isInTile(x, y))
end

function ClossestPath(x, y)
    local clossestTile
    local distances = math.huge
    local rangeY = y - Client.y
    local rangeX = x - Client.x
    for ye = Client.y, rangeY >= 0 and 53 or 0, rangeY >= 0 and 1 or -1 do
        for ex = Client.x, rangeX >= 0 and 99 or 0, rangeX >= 0 and 1 or -1 do
            if IsCanFindPath(ex, ye) then
                local distance = GetRange(ex, ye, x, y)

                if distance < distances then
                    clossestTile = { x = ex, y = ye }
                    distances = distance
                end
            end
        end
    end
    if clossestTile then
        return clossestTile.x, clossestTile.y
    end
    return nil, nil
end

local function isPunchable(x, y)
    local tile = getTile(x, y)
    if not tile.fg then return false end
    return tile.fg % 2 == 0 and tile.fg ~= 0 and tile.fg ~= 8 and tile.fg ~= 3918 and hasAccess(x, y) > 0 and
        tile.flags < 4096
end

function CheckFossil(x, y)
    for _, object in pairs(getObjects()) do
        local object_x, object_y = math.floor((object.x + 10) * (1 / 32)), math.floor((object.y + 10) * (1 / 32))
        if x == object_x and y == object_y then
            if object.id == 3936 then
                return true
            end
        end
    end
    return false
end

function ClossestPunch(x, y)
    local distances = math.huge
    local relation = {
        { 0,  1 }, { -1, 0 }, { 1, 0 }, { -1, -1 },
        { -1, 1 }, { 0, -1 }, { 1, -1 }, { 1, 1 }
    }
    local clossestPunch
    local bot_x, bot_y = Client.x, Client.y
    for _, data in pairs(relation) do
        local tile_x, tile_y = bot_x + data[1], bot_y + data[2]
        if isPunchable(tile_x, tile_y) then
            local distance = GetRange(tile_x, tile_y, x, y)
            if distance < distances then
                clossestPunch = { x = tile_x, y = tile_y }
                distances = distance
            end
        end
    end
    if clossestPunch then
        return clossestPunch.x, clossestPunch.y
    end
    return nil, nil
end

function Wear(id)
    if getInventory():findItem(id) > 0 then
        while not getInventory():getItem(id).isActive do
            Client:wear(id)
            sleep(500)
        end
    end
end

function Unwear(id)
    if getInventory():findItem(id) > 0 then
        while getInventory():getItem(id).isActive do
            Client:unwear(id)
            sleep(500)
        end
    end
end

---@param x number
---@param y number
---@param num number
function TileDrop(x, y, num)
    local count = 0
    local stack = 0
    for _, obj in pairs(getObjects()) do
        if ((obj.x + 10) // 32) == x and ((obj.y + 10) // 32) == y then
            count = count + obj.count
            stack = stack + 1
        end
    end
    return stack < 20 and count <= (4000 - num)
end

function StoringItems(world, id)
    local tools = { 4134, 3936 }
    if #StorageSave == 0 then
        return error('There is currently no storage available for storing fossil.')
    end
    for _, itm in pairs(tools) do
        if getInventory():findItem(itm) >= MinimumStore then
            while getInventory():findItem(itm) >= MinimumStore do
                for i, data in pairs(StorageSave) do
                    local World, Id = data, ''
                    if data:find(':') then World, Id = data:match('(.+):(.+)') end
                    Warp(World, Id)
                    if not nuked then
                        if not stuck then
                            for y = 53, 0, -1 do
                                for x = 0, 99 do
                                    if IsCanFindPath(x, y) and TileDrop(x, y, getInventory():findItem(itm)) and IsCanFindPath(x - 1, y) then
                                        while not Client:isInTile(x - 1, y) do
                                            Client:findPath(x - 1, y)
                                            Reposition(World, Id, x - 1, y)
                                        end
                                        if Client:isInTile(x - 1, y) then
                                            while TileDrop(x, y, getInventory():findItem(itm)) and getInventory():findItem(itm) > 0 do
                                                Client:setDirection(false)
                                                sleep(500)
                                                Client:drop(itm, getInventory():findItem(itm))
                                                sleep(500)
                                                Reposition(World, Id, x - 1, y)
                                            end
                                        end
                                    end
                                    if getInventory():findItem(itm) == 0 then
                                        break
                                    end
                                end
                            end
                        else
                            table.remove(StorageSave, i)
                        end
                    else
                        table.remove(StorageSave, i)
                    end
                end
            end
            Warp(world, id)
        end
    end
end

function RunScript()
    if not Client then
        return error('No bots available to run the script.', 0)
    end
    GetTools()
    if not messageId then
        messageId = createMessageID(WebhookURL, 'NeuroFossil')
    end
    local split = WorldEachBot == 0 and math.floor(#WorldList / #getBots()) or WorldEachBot
    local start = ((Client.index - 1) * split) + 1
    local stop = Client.index * split
    Client.move_interval = 100
    Client.move_range = 8
    totalFarm = stop
    farmIndex = start
    Start = start
    for idx = start, stop do
        farmIndex = idx
        local world, id = WorldList[idx], ''
        if WorldList[idx]:find(':') then world, id = WorldList[idx]:match('(.+):(.+)') end
        table.insert(World,WorldList[idx])
        Warp(world, id)
        time[world] = os.time()
        if not nuked then
            if not stuck then
                fossil[world] = CountFossil()
                WebhookInfo('Found ' .. fossil[world] .. ' Fossil rock')
                if fossil[world] > 0 then
                    local tiles = GetTileFossil()
                    for _, tile in pairs(tiles) do
                        GetBrushNRock(world, id)
                        Wear(98)
                        local ex, ye = ClossestPath(tile.x, tile.y)
                        if ex and ye then
                            if not Client:isInTile(ex, ye) then
                                while not Client:isInTile(ex, ye) do
                                    Client:findPath(ex, ye)
                                    Reposition(world, id, ex, ye)
                                end
                            end
                            local rangeX, rangeY = tile.x - ex, tile.y - ye
                            if math.abs(rangeX) >= 2 or math.abs(rangeY) >= 2 then
                                WebhookInfo('Getting Path ' .. ex .. ':' .. ye)
                                rangeX, rangeY = tile.x - ex, tile.y - ye
                                while math.abs(rangeX) >= 2 or math.abs(rangeY) >= 2 do
                                    if math.abs(rangeX) >= 2 or math.abs(rangeY) >= 2 then
                                        local punch_x, punch_y = ClossestPunch(tile.x, tile.y)
                                        if punch_x and punch_y then
                                            while isPunchable(punch_x, punch_y) do
                                                Client:hit(punch_x, punch_y)
                                                sleep(180)
                                                Reposition(world, id, ex, ye)
                                            end
                                        else
                                            break
                                        end
                                    end
                                    ex, ye = ClossestPath(tile.x, tile.y)
                                    if ex and ye then
                                        while not Client:isInTile(ex, ye) do
                                            Client:findPath(ex, ye)
                                            Reposition(world, id, ex, ye)
                                        end
                                    end
                                    rangeX, rangeY = tile.x - ex, tile.y - ye
                                end
                            end
                            if math.abs(rangeX) >= 2 or math.abs(rangeY) >= 2 then
                                print('[' .. Client.name .. '] Failed to get path ' .. tile.x .. ':' .. tile.y)
                            else
                                if getTile(tile.x, tile.y).fg == 3918 then
                                    if getTile(tile.x, tile.y).flags == 0 then
                                        Wear(3932)
                                        while getTile(tile.x, tile.y).flags == 0 do
                                            for i = 1, 20 do
                                                if getTile(tile.x, tile.y).flags == 0 then
                                                    Client:hit(tile.x, tile.y)
                                                    sleep(DelayPunch)
                                                    Reposition(world, id, ex, ye)
                                                else
                                                    break
                                                end
                                            end
                                            if getTile(tile.x, tile.y).flags == 0 then
                                                sleep((math.random(7, 8) * 1000))
                                            else
                                                break
                                            end
                                        end
                                    end
                                    if getTile(tile.x, tile.y).flags ~= 0 and getTile(tile.x, tile.y).fg == 3918 then
                                        Wear(3934)
                                        while getTile(tile.x, tile.y).fg ~= 0 do
                                            Client:hit(tile.x, tile.y)
                                            sleep(180)
                                            Reposition(world, id, ex, ye)
                                        end
                                    end
                                    Unwear(3934)
                                    for i = 1, 10 do
                                        if CheckFossil(tile.x, tile.y) then
                                            Client:place(tile.x, tile.y, 4132)
                                            sleep(180)
                                        else
                                            break
                                        end
                                    end
                                    if not IsCanFindPath(tile.x, tile.y) then
                                        local punch_x, punch_y = ClossestPunch(tile.x, tile.y)
                                        if punch_x and punch_y then
                                            while isPunchable(punch_x, punch_y) do
                                                Client:hit(punch_x, punch_y)
                                                sleep(180)
                                                Reposition(world, id, ex, ye)
                                            end
                                        else
                                            print('['..Client.name..'] Failed to collect polished fossil at path '..tile.x..':'..tile.y)
                                        end
                                    end
                                    Client.auto_collect = true
                                    sleep(500)
                                    if ReplaceRock then
                                        while getTile(tile.x, tile.y).fg ~= 10 and getTile(tile.x,tile.y).fg == 0 do
                                            Client:place(tile.x, tile.y, 10)
                                            sleep(180)
                                            Reposition(world,id,ex,ye)
                                        end
                                    end
                                    Client.auto_collect = false
                                    StoringItems(world, id)
                                end
                            end
                        end
                    end
                end
                time[world] = formatTime(os.difftime(os.time(), time[world]))
            else
                time[world] = 'STUCK'
            end
        else
            time[world] = 'NUKED'
        end
    end
    WebhookInfo('All world has been harvested!')
    if RemoveBots then
        removeBot()
    end
end

return RunScript
