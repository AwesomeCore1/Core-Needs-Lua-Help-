-- by: minipunch
-- for: Initially made for USA Realism RP (https://usarrp.net)
-- purpose: Provide public servants with blips for all other active emergency personnel

local ACTIVE_STAFF_PERSONNEL = {}

--[[
person = {
 src = 123,
 color = 3,
 name = "Taylor Weitman"
}
]]
-- Below is the roles allowed to use the command /blip 
--[[
	1 = Red
	2 = Green
	3 = Blue
	5 = Yellow
	17 = Orange
	Color Info obtained from: https://wiki.gtanet.work/index.php?title=Blips
]]
-- CONFIG --
roleList = {
    ['🛑 T.Mod | '] = {768211954745475103, 1, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['🛑 Mod | '] = {741760820085522475, 1, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['🛑 Sr.Mod | '] = {741763655112196147, 1, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['⛔️ Admin | '] = {741763827200425985, 1, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['⛔️ Sr.Admin | '] = {752892190379737240, 1, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['⛔️ Head Admin'] = {741763936503726110, 1, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['🕵 Network Manager | '] = {754397905720180909, 2, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['👑 Owner |'] = {741524699888091218, 3, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
	['💎 Founder |'] = {741764244642726020, 3, 'https://staff.lucaasflightsim.xyz/API/reciever.php'},
}

-- CODE --
Citizen.CreateThread(function()
	while true do 
		-- We wait a second and add it to their timeTracker 
		Wait(1000); -- Wait a second
		for k, v in pairs(timeTracker) do 
			timeTracker[k] = timeTracker[k] + 1;
		end 
	end 
end)
timeTracker = {}
hasPerms = {}
permTracker = {}
activeBlip = {}
onDuty = {}
prefix = '^9[^4Staff-Blips^9] ^3';
AddEventHandler("playerDropped", function()
	if onDuty[source] ~= nil then 
		local tag = activeBlip[source];
		local webHook = roleList[activeBlip[source]][3];
		if webHook ~= nil then 
			local time = timeTracker[source];
			local now = os.time();
			local startPlusNow = now + time;
			local minutesActive = os.difftime(now, startPlusNow) / 60;
			minutesActive = math.floor(math.abs(minutesActive))
			sendToDisc(identifierDiscord, identifierDiscord, 
			minutesActive,
				webHook, 16711680)
		end 
	end
	timeTracker[source] = nil;
	onDuty[source] = nil;
	permTracker[source] = nil;
	hasPerms[source] = nil;
	activeBlip[source] = nil;
	-- Remove them from Blips:
	TriggerEvent('sblips:remove', source)
end)
function sendToDisc(title, message, footer, webhookURL, color)
	local embed = {}
	embed = {
		{
			["color"] = color, -- GREEN = 65280 --- RED = 16711680
			["title"] = title,
			["description"] = message,
			["footer"] = {
				["text"] = footer,
			},
		}
	}
	-- Start
	-- TODO Input Webhook
	PerformHttpRequest(webhookURL, 
	function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
  -- END
end

AddEventHandler('playerConnecting', function()
  local src = source
  for _, v in ipairs(GetPlayerIdentifiers(src)) do
    if(string.sub(v, 1, string.len("discord:")) == "discord:" then)
      identifierDiscord = v
      break
    end
  end
  if identifierDiscord then
		local roleIDs = exports.staffdiscord_perms:GetRoles(src)
		if not (roleIDs == false) then
			for k, v in pairs(roleList) do 
				for j = 1, #roleIDs do
					if (tostring(v[1]) == tostring(roleIDs[j])) then
						-- They have a proper role to use it 
						table.insert(perms, k);
						activeBlip[src] = k;
						hasPerms[src] = true;
					end
				end
			end
			-- Set up what roles they have access to: 
            permTracker[src] = perms;
            if hasPerms[source] ~= nil then  
                local colorr = roleList[activeBlip[source]][2];
                local tag = activeBlip[source];
                local webHook = roleList[activeBlip[source]][3];
                if webHook ~= nil then
                    sendToDisc(identifierDiscord, 'Player ' .. GetPlayerName(source) .. ' has gone on duty as ' .. tag, '',
                        webHook, 65280)
                end
                TriggerEvent('sblips:add', {name = tag .. GetPlayerName(source), src = source, color = colorr}); 
                sendMsg(source, 'You have toggled your Staff Blip ^2ON ^3and your Blip-Tag is: ' .. tag)
                onDuty[source] = true;
                timeTracker[source] = 0;
                TriggerClientEvent('StaffActivity:GiveWeapons', source);
            else 
                -- You are not a cop, you must be a cop in our discord to use it 
            end
        end)
			print("[StaffActivity] " .. GetPlayerName(src) .. " has gotten their permissions")
			print("[StaffActivity] " .. GetPlayerName(src) .. " has the permission " .. hasPerms[src])
		else
			-- They don't have any perms 
			print("[StaffActivity] " .. GetPlayerName(src) .. " has not gotten their permissions cause roleIDs == false")
		end
	else
		print("[StaffActivity] " .. GetPlayerName(src) .. " has not gotten their permissions cause discord was not detected...")
	end
	permTracker[src] = perms; 
end)
RegisterCommand('staff', function(source, args, rawCommand) 
	-- Prints the active cops online with a /blip that is on 
	sendMsg(source, 'The active cops on are:')
	for id, _ in pairs(onDuty) do 
		TriggerClientEvent('chatMessage', source, '^9[^4' .. id .. '^9] ^0' .. GetPlayerName(id));
	end
end)
function sendMsg(src, msg) 
	TriggerClientEvent('chatMessage', src, prefix .. msg);
end
RegisterCommand('staffbliptag', function(source, args, rawCommand)
	-- The /blipTag command to toggle on and off the cop blip 
	if hasPerms[source] ~= nil then 
		if #args == 0 then 
			-- List out which ones they have access to 
			sendMsg(source, 'You have access to the following Staff Blip-Tags:');
			for i = 1, #permTracker[source] do 
				-- List 
				TriggerClientEvent('chatMessage', source, '^9[^4' .. i .. '^9] ^0' .. permTracker[source][i]);
			end
		else 
			-- Choose their bliptag 
			local selection = args[1];
			if tonumber(selection) ~= nil then 
				local sel = tonumber(selection);
				local theirBlips = permTracker[source];
				if sel <= #theirBlips then
					-- Set up their tag
					local tag = activeBlip[source];
					local webHook = roleList[activeBlip[source]][3];
					if onDuty[source] ~= nil then 
						local time = timeTracker[source];
						local now = os.time();
						local startPlusNow = now + time;
						local minutesActive = os.difftime(now, startPlusNow) / (60);
						minutesActive = math.floor(math.abs(minutesActive))
						sendToDisc(identifierDiscord, identifierDiscord 
							, minutesActive,
							webHook, 16711680)
						timeTracker[source] = 0;
					end
					activeBlip[source] = permTracker[source][sel];
					sendMsg(source, 'You have set your Blip-Tag to ^1' .. permTracker[source][sel]);
					if onDuty[source] ~= nil then 
						tag = activeBlip[source];
						webHook = roleList[activeBlip[source]][3];
						sendToDisc(identifierDiscord, identifierDiscord, '',
							webHook, 65280) 
						local colorr = roleList[activeBlip[source]][2]
						TriggerEvent('sblips:remove', source)
						TriggerEvent('sblips:add', {name = tag .. GetPlayerName(source), src = source, color = colorr});
					end
				else 
					-- That is not a valid selection 
					sendMsg(source, '^1ERROR: That is not a valid selection...')
				end
			else 
				-- Not a number 
				sendMsg(source, '^1ERROR: That is not a number...')
			end
		end
	else 
		-- You are not a cop, you must be a cop in our discord to use this 
		sendMsg(source, '^1ERROR: You must be a Staff Member to do this...')
	end 
end)

RegisterServerEvent("sblips:add")
AddEventHandler("sblips:add", function(person)
	ACTIVE_STAFF_PERSONNEL[person.src] = person
	for k, v in pairs(ACTIVE_STAFF_PERSONNEL) do
		TriggerClientEvent("sblips:updateAll", k, ACTIVE_STAFF_PERSONNEL)
	end
	TriggerClientEvent("sblips:toggle", person.src, true)
end)

RegisterServerEvent("sblips:remove")
AddEventHandler("sblips:remove", function(src)
	-- remove from list --
	ACTIVE_STAFF_PERSONNEL[src] = nil
	-- update client blips --
	for k, v in pairs(ACTIVE_STAFF_PERSONNEL) do
		TriggerClientEvent("sblips:remove", tonumber(k), src)
	end
	-- deactive blips when off duty --
	TriggerClientEvent("sblips:toggle", src, false)
end)

-- Clean up blip entry for on duty player who leaves --
AddEventHandler("playerDropped", function()
	if ACTIVE_STAFF_PERSONNEL[source] then
		ACTIVE_STAFF_PERSONNEL[source] = nil
	end
end)
