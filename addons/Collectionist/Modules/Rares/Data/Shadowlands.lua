local addonName, MC = ...

-- Shadowlands zone rares. Exact 211 ordered criteria/NPC rows.
MC.RegisterContent("shadowlands", "rares", {
    { source = "bastion", achievementID = 14307, criteriaCount = 29,
      criteriaTreeIDs = { 86622, 86623, 86624, 86625, 86626, 86627, 86628, 86629, 86630, 86631, 86632, 86633, 86634, 86635, 86636, 86637, 86638, 86639, 86640, 86641, 86642, 86643, 86644, 86645, 86646, 89116, 89125, 89123, 89119 },
      criteriaNPCIDs = { 158659, 160721, 161527, 161530, 161529, 160629, 167078, 160882, 163460, 170548, 170659, 170623, 170932, 171009, 171008, 171013, 171040, 171041, 171014, 171011, 171189, 171211, 171255, 171010, 171327, 161528, 160985, 156340, 170899 }, name = "Adventurer of Bastion",
      zoneMapID = MC.MAP.Bastion, zone = "Bastion" },
    { source = "maldraxxus", achievementID = 14308, criteriaCount = 22,
      criteriaTreeIDs = { 86671, 86656, 86663, 86665, 86664, 86672, 86666, 86647, 86667, 86669, 86668, 86649, 86673, 86652, 86654, 87968, 86650, 86675, 86648, 86651, 86674, 87969 },
      criteriaNPCIDs = { 157058, 158406, 157125, 159105, 159753, 159886, 160059, 161105, 161857, 162180, 162528, 162586, 168147, 162588, 162669, 162690, 162711, 162727, 162767, 162797, 162819, 174108 }, name = "Adventurer of Maldraxxus",
      zoneMapID = MC.MAP.Maldraxxus, zone = "Maldraxxus" },
    { source = "ardenweald", achievementID = 14309, criteriaCount = 21,
      criteriaTreeIDs = { 86456, 86457, 86572, 86573, 86574, 86575, 86576, 86577, 86578, 86579, 86580, 86588, 86589, 86590, 86591, 86592, 86593, 86594, 86595, 86596, 86597 },
      criteriaNPCIDs = { 164477, 164547, 164093, 164107, 164112, 164147, 164238, 164391, 164415, 160448, 165053, 167724, 167851, 167726, 167721, 168135, 163229, 163370, 168647, 171451, 171688 }, name = "Adventurer of Ardenweald",
      zoneMapID = MC.MAP.Ardenweald, zone = "Ardenweald" },
    { source = "revendreth", achievementID = 14310, criteriaCount = 24,
      criteriaTreeIDs = { 86598, 86599, 86600, 86601, 86602, 86604, 86605, 86606, 86607, 86608, 86609, 86610, 86615, 86612, 86613, 86614, 86616, 86617, 86618, 86619, 86620, 86621, 88387, 88388 },
      criteriaNPCIDs = { 160392, 160675, 160640, 155779, 159503, 160821, 160857, 161310, 161891, 165152, 165206, 164388, 165253, 166393, 166521, 166576, 166679, 166292, 166710, 166993, 167464, 170048, 170434, 162481 }, name = "Adventurer of Revendreth",
      zoneMapID = MC.MAP.Revendreth, zone = "Revendreth" },
    { source = "maw", achievementID = 14660, criteriaCount = 19,
      criteriaTreeIDs = { 87625, 87626, 87627, 87628, 87629, 87630, 87632, 87633, 87634, 87635, 87636, 87637, 87638, 87639, 87640, 88935, 88936, 88937, 90044 },
      criteriaNPCIDs = { 158314, 162452, 162829, 162845, 162965, 165047, 168693, 169102, 170692, 170787, 171316, 172521, 172523, 172524, 173086, 172207, 156203, 162844, 175821 }, name = "It's About Sending a Message",
      zoneMapID = MC.MAP.Maw, zone = "The Maw" },
    { source = "maw", achievementID = 14744, criteriaCount = 21,
      criteriaTreeIDs = { 88130, 88131, 88132, 88133, 88134, 88135, 88136, 88137, 88138, 88139, 88140, 88141, 88142, 88143, 88144, 88145, 88146, 88147, 88148, 88149, 89258 },
      criteriaNPCIDs = { 157964, 170301, 157833, 171317, 160770, 158025, 170711, 170774, 169827, 154330, 170303, 162849, 158278, 164064, 172577, 170634, 166398, 170302, 170731, 172862, 175012 }, name = "Better to Be Lucky Than Dead",
      zoneMapID = MC.MAP.Maw, zone = "The Maw" },
    { source = "maw", achievementID = 15054, criteriaCount = 15,
      criteriaTreeIDs = { 91686, 91687, 91688, 91689, 91690, 91691, 91692, 91693, 91694, 91695, 91696, 91697, 91698, 91699, 91700 },
      criteriaNPCIDs = { 177981, 177979, 177330, 177331, 177980, 178886, 178002, 177427, 178897, 178883, 178882, 178004, 177972, 178899, 178898 }, name = "Minions of the Cold Dark",
      zoneMapID = MC.MAP.Maw, zone = "The Maw" },
    { source = "korthia", achievementID = 15107, criteriaCount = 28,
      criteriaTreeIDs = { 91955, 91948, 91942, 91931, 91943, 91933, 91956, 91950, 91957, 91951, 91935, 91960, 91940, 91952, 91949, 91980, 91929, 91930, 91932, 91941, 91934, 91947, 91981, 91958, 91954, 91953, 91944, 91959 },
      criteriaNPCIDs = { 179853, 180246, 180132, 179913, 179779, 177903, 180014, 179460, 180042, 179851, 179472, 179108, 179684, 179914, 179931, 180160, 179608, 179911, 179985, 179735, 179760, 179805, 180162, 180032, 179859, 179802, 177444, 177336 }, name = "Conquering Korthia",
      zoneMapID = MC.MAP.Korthia, zone = "Korthia" },
    { source = "zereth_mortis", achievementID = 15391, criteriaCount = 29,
      criteriaTreeIDs = { 94515, 94516, 94517, 94518, 94519, 94520, 94521, 94522, 94523, 94524, 94525, 94526, 94527, 94528, 94529, 94530, 94531, 94532, 94533, 94574, 94582, 94601, 94605, 94606, 94608, 94609, 94610, 94611, 94612 },
      criteriaNPCIDs = { 178778, 183746, 178229, 180917, 183927, 183737, 179006, 183596, 183925, 183722, 179043, 184409, 183747, 178563, 182318, 178963, 181249, 184413, 180746, 178508, 180924, 183646, 180978, 183764, 183814, 183953, 183748, 181360, 183516 }, name = "Adventurer of Zereth Mortis",
      zoneMapID = MC.MAP.ZerethMortis, zone = "Zereth Mortis" },
    { source = "zereth_mortis", achievementID = 15392, criteriaCount = 3,
      criteriaTreeIDs = { 94537, 94538, 94539 },
      criteriaNPCIDs = { 182114, 182155, 182158 }, name = "Dune Dominance",
      zoneMapID = MC.MAP.ZerethMortis, zone = "Zereth Mortis" },
})

local SOURCE_KEYS = {
    { "bastion", "Bastion" },
    { "maldraxxus", "Maldraxxus" },
    { "ardenweald", "Ardenweald" },
    { "revendreth", "Revendreth" },
    { "maw", "The Maw" },
    { "korthia", "Korthia" },
    { "zereth_mortis", "Zereth Mortis" },
}
local function merge()
    MC.RareSourceOrder = MC.RareSourceOrder or {}
    MC.RareSourceLabels = MC.RareSourceLabels or {}
    local have = {}
    for _, key in ipairs(MC.RareSourceOrder) do have[key] = true end
    -- The base file already declares every key it owns. Inserting a
    -- second copy put the zone in the order list twice, which draws
    -- its group twice and prints it twice in the /mc summary.
    local at = 0
    for _, pair in ipairs(SOURCE_KEYS) do
        MC.RareSourceLabels[pair[1]] = pair[2]
        if not have[pair[1]] then
            at = at + 1
            have[pair[1]] = true
            table.insert(MC.RareSourceOrder, at, pair[1])
        end
    end
end
if MC.RareSourceOrder then merge() else
    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)
end
