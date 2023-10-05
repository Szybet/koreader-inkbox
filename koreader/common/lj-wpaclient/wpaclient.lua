local cur_path = (...):match("(.-)[^%(.|/)]+$")
local wpa_ctrl = require(cur_path .. "wpa_ctrl")


local function str_split(str, sep)
    local fields = {}
    sep = sep or ":"
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local function str_strip(str)
    return str:match("(.-)\n$")
end


local WpaClient = {__index = {}}

function WpaClient.new(s)
    local instance = {
        wc_hdl = nil,
        attached = false,
    }

    local hdl, err_msg = wpa_ctrl.open(s)
    if not hdl then
        return nil, err_msg
    end

    instance.wc_hdl = hdl
    return setmetatable(instance, WpaClient)
end

function WpaClient.__index:sendCmd(cmd, block)
    return wpa_ctrl.command(self.wc_hdl, cmd, block)
end

function WpaClient.__index:sendCtrlCmd(cmd)
    return wpa_ctrl.control_command(self.wc_hdl, cmd)
end

function WpaClient.__index:getInterfaces()
    local reply, err = self:sendCmd("INTERFACES", true)
    if reply == nil then
        return nil, err
    end

    return str_split(reply, "\n")
end

function WpaClient.__index:listNetworks()
    local reply, err = self:sendCmd("LIST_NETWORKS", true)
    if reply == nil then
        return nil, err
    end

    local results = {}
    local lst = str_split(reply, "\n")
    table.remove(lst, 1)  -- remove output table header
    for _, v in ipairs(lst) do
        local splits = str_split(v, "\t")
        table.insert(results, {
            id = splits[1],
            ssid = splits[2],
            bssid = splits[3],
            flags = splits[4],
        })
    end
    return results
end

function WpaClient.__index:getCurrentNetwork()
    local networks, err = self:listNetworks()
    if networks == nil then
        return nil, err
    end

    for _, nw in ipairs(networks) do
        if nw.flags and string.find(nw.flags, "%[CURRENT%]") then
            return nw
        end
    end
end

function WpaClient.__index:doScan()
    local reply, err = self:sendCtrlCmd("SCAN")
    if reply == nil then
        return nil, err
    end

    return str_strip(reply), err
end

local network_mt = {__index = {}}

function network_mt.__index:getSignalQuality()
    -- Based on NetworkManager's nm_wifi_utils_level_to_quality
    -- c.f., https://github.com/NetworkManager/NetworkManager/blob/2fa8ef9fb9c7fe0cc2d9523eed6c5a3749b05175/src/nm-core-utils.c#L5083-L5100
    -- With a minor tweak: we assume a best-case at -20dBm (instead of -40dBm),
    -- because we've seen Kobos report slightly wonky values (as low as -15dBm)...
    -- https://github.com/koreader/lj-wpaclient/pull/6 & https://github.com/koreader/koreader/issues/7008
    -- There's no real silver bullet here, as the RSSI is in arbitrary units,
    -- which means every driver kinda does what it wants with it...

    local function clamp(val, min, max)
        return math.max(min, math.min(max, val))
    end

    local function dbm_to_qual(val)
        val = math.abs(clamp(val, -100, -20) + 20)    -- Normalize to 0
        val = 100 - math.floor((100.0 * val) / 80.0)  -- Rescale to [0, 100] range
        return val
    end

    local val = self.signal_level
    if val < 0 then
        -- Assume dBm already; rough conversion: best = -20, worst = -100
        val = dbm_to_qual(val)
    elseif val > 110 and val < 256 then
        -- Assume old-style WEXT 8-bit unsigned signal level
        val = val - 256                               -- Subtract 256 to convert to dBm
        val = dbm_to_qual(val)
    --[[
    else
        -- Assume signal is already a "quality" percentage
    --]]
    end

    return clamp(val, 0, 100)
end

function WpaClient.__index:getScanResults()
    local reply, err = self:sendCmd("SCAN_RESULTS", true)
    if reply == nil then
        return nil, err
    end

    local results = {}
    local lst = str_split(reply, "\n")
    for _, v in ipairs(lst) do
        local splits = str_split(v, "\t")

        if splits[5] then  -- ignore lines which don't split into 5 parts
            local network = {
                bssid = splits[1],
                frequency = tonumber(splits[2]),
                signal_level = tonumber(splits[3]),
                flags = splits[4],
                ssid = splits[5],
            }
            setmetatable(network, network_mt)
            table.insert(results, network)
        end
    end
    return results
end

function WpaClient.__index:scanThenGetResults()
    local success, reply, err
    if not self.attached then
        success, err = self:attach()
        if not success then
            return nil, "Failed to ATTACH: " .. err
        end
    end
    -- May harmlessly fail with FAIL-BUSY
    reply, err = self:doScan()
    if reply == nil then
        return nil, err
    end

    local found_result = false
    local wait_cnt = 20
    while wait_cnt > 0 do
        for _, ev in ipairs(self:readAllEvents()) do
            -- NOTE: If we hit a network preferred by the system, we may get connected directly,
            --       but we'll handle that later in WpaSupplicant:getNetworkList...
            if ev.msg == "CTRL-EVENT-SCAN-RESULTS" then
                found_result = true
                break
            end
        end
        if found_result then
            break
        end

        wait_cnt = wait_cnt - 1
        -- Wait for new data from wpa_supplicant in steps of at most 1 second.
        -- NOTE: I'm wary of simply doing a 20s poll, because we *may* receive events unrelated to the scan,
        --       unlike in sendCmd...
        wpa_ctrl.waitForResponse(self.wc_hdl, 1 * 1000)
    end

    if self.attached then
        success, err = self:detach()
        if not success then
           return nil, "Failed to DETACH: " .. err
        end
    end
    return self:getScanResults()
end

function WpaClient.__index:getStatus()
    local reply, err = self:sendCmd("STATUS", true)
    if reply == nil then
        return nil, err
    end

    local results = {}
    local lst = str_split(reply, "\n")
    for _, v in ipairs(lst) do
        local eqs, eqe = v:find("=")
        if eqs and eqe then
            results[v:sub(1, eqs-1)] = v:sub(eqe+1)
        end
    end
    return results
end

function WpaClient.__index:addNetwork()
    local reply, err = self:sendCtrlCmd("ADD_NETWORK")
    if reply == nil then
        return nil, err
    end

    return str_strip(reply), err
end

function WpaClient.__index:removeNetwork(id)
    local reply, err = self:sendCtrlCmd("REMOVE_NETWORK " .. id)
    if reply == nil then
        return nil, err
    end

    return str_strip(reply), err
end

function WpaClient.__index:disableNetworkByID(id)
    local reply, err = self:sendCtrlCmd("DISABLE_NETWORK " .. id)
    if reply == nil then
        return nil, err
    end

    return reply, err
end

function WpaClient.__index:setNetwork(id, key, value)
    local reply, err = self:sendCtrlCmd(string.format("SET_NETWORK %d %s %s", id, key, value))
    if reply == nil then
        return nil, err
    end

    return str_strip(reply), err
end

function WpaClient.__index:enableNetworkByID(id)
    local reply, err = self:sendCtrlCmd("ENABLE_NETWORK " .. id)
    if reply == nil then
        return nil, err
    end

    return reply, err
end

function WpaClient.__index:getConnectedNetwork()
    local reply, err = self:getStatus()
    if reply == nil then
        return nil, err
    end

    if reply.wpa_state == "COMPLETED" then
        return {
            id = reply.id,
            ssid = reply.ssid,
            bssid = reply.bssid,
        }
    else
        return nil, reply.wpa_state
    end
end

function WpaClient.__index:attach()
    local reply, err = wpa_ctrl.attach(self.wc_hdl)
    if reply ~= nil and reply == "OK\n" then
        self.attached = true
        return true
    end

    if reply == nil then
        return false, err
    end

    return false, str_strip(reply) or "N/A"
end

function WpaClient.__index:reattach()
    local reply, err = wpa_ctrl.reattach(self.wc_hdl)
    if reply ~= nil and reply == "OK\n" then
        self.attached = true
        return true
    end

    if reply == nil then
        return false, err
    end

    return false, str_strip(reply) or "N/A"
end

function WpaClient.__index:detach()
    local reply, err = wpa_ctrl.detach(self.wc_hdl)
    if reply ~= nil and reply == "OK\n" then
        self.attached = false
        return true
    end

    if reply == nil then
        return false, err
    end

    return false, str_strip(reply) or "N/A"
end

function WpaClient.__index:waitForEvent(timeout)
    return wpa_ctrl.waitForResponse(self.wc_hdl, timeout)
end

function WpaClient.__index:readEvent()
    -- NOTE: This may read nothing...
    wpa_ctrl.readResponse(self.wc_hdl)
    ---      ... what we care about is actually simply draining the event queue ;).
    return wpa_ctrl.readEvent(self.wc_hdl)
end

function WpaClient.__index:readAllEvents()
    -- This will call Socket:recvAll, filling the event queue (or not)
    wpa_ctrl.readResponse(self.wc_hdl)

    -- Drain the replies pushed in the event queue by Socket:recvAll in FILO order.
    -- NOTE: This essentially reverses self.wc_hdl.event_queue...
    local evs = {}
    repeat
        local ev = wpa_ctrl.readEvent(self.wc_hdl)
        if ev ~= nil then
            table.insert(evs, ev)
        end
    until ev == nil
    return evs
end

function WpaClient.__index:disconnect()
    -- NOTE: Probably expects an actual response, and as such, should use sendCtrlCmd?
    --       We're currently not using it, though.
    return self:sendCmd("DISCONNECT")
end

function WpaClient.__index:close()
    if self.attached then
        self:detach()
    end
    wpa_ctrl.close(self.wc_hdl)
end

return WpaClient
