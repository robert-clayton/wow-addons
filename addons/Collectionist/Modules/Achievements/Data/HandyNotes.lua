local _, MC = ...

-- Visible current achievements referenced by installed HandyNotes data but absent
-- from Collectionist's expansion-category manifests. Generated from an exact
-- 215-row provider and DB2 audit.

MC.RegisterContent("vanilla", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 6585, name = "Kalimdor Safari", description = "Catch every battle pet in Kalimdor." },
        { achievementID = 6586, name = "Eastern Kingdoms Safari", description = "Catch every battle pet in Eastern Kingdoms." },
    } },
})

MC.RegisterContent("tbc", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 6587, name = "Outland Safari", description = "Catch every battle pet in Outland." },
    } },
    { category = "features", source = "professions", achievements = {
        { achievementID = 1257, name = "The Scavenger", description = "Successfully fish in each of the junk nodes listed below." },
    } },
})

MC.RegisterContent("wrath", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 6588, name = "Northrend Safari", description = "Catch every battle pet in Northrend." },
    } },
    { category = "features", source = "professions", achievements = {
        { achievementID = 2096, name = "The Coin Master", description = "Complete the coin fishing achievements listed below." },
    } },
})

MC.RegisterContent("cata", "achievements", {
    { category = "collections", source = "mounts", achievements = {
        { achievementID = 5767, name = "Scourer of the Eternal Sands", description = "Obtain the reins of the Grey Riding Camel from Dormus the Camel-Hoarder." },
    } },
})

MC.RegisterContent("mop", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 6589, name = "Pandaria Safari", description = "Catch every battle pet in Pandaria." },
        { achievementID = 8397, name = "Crazy for Cats", description = "Obtain 20 of the cats listed below." },
    } },
    { category = "exploration", source = "zone", achievements = {
        { achievementID = 6926, name = "Tranquil Master", description = "Purge Pandaria of Sha corruption, defeating each known manifestation of negative emotion." },
    } },
})

MC.RegisterContent("wod", "achievements", {
    { category = "collections", source = "mounts", achievements = {
        { achievementID = 9713, name = "Awake the Drakes", description = "Collect the following drake mounts." },
    } },
    { category = "collections", source = "pets", achievements = {
        { achievementID = 9724, name = "Taming Draenor", description = "Defeat all of the Pet Tamers in Draenor listed below." },
        { achievementID = 10052, name = "Tiny Terrors in Tanaan", description = "Defeat the following fel-corrupted pets in Tanaan Jungle." },
    } },
    { category = "collections", source = "toys", achievements = {
        { achievementID = 10353, name = "Iron Armada", description = "Collect all five toys that are part of the Crashin' Thrashin' \"Iron Armada\" set." },
    } },
    { category = "exploration", source = "zone", achievements = {
        { achievementID = 9838, name = "What A Strange, Interdimensional Trip It's Been", description = "Defeat the following Draenor bosses while being accompanied by Pepe." },
        { achievementID = 10334, name = "Predator", description = "Defeat Xemirkol in Tanaan Jungle." },
    } },
})

MC.RegisterContent("legion", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 11233, name = "Broken Isles Safari", description = "Catch every battle pet in the Broken Isles." },
        { achievementID = 12088, name = "Anomalous Animals of Argus", description = "Defeat the following corrupted pets on Argus." },
    } },
})

MC.RegisterContent("bfa", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 12930, name = "Battle Safari", description = "Catch every battle pet on Zandalar and Kul Tiras" },
        { achievementID = 12936, name = "Battle on Zandalar and Kul Tiras", description = "Complete 20 Pet Battle World Quests on Zandalar and Kul Tiras with a full team of level 25 pets." },
        { achievementID = 13270, name = "Beast Mode", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Beast pets." },
        { achievementID = 13271, name = "Critters With Huge Teeth", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Critter pets." },
        { achievementID = 13272, name = "Dragons Make Everything Better", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Dragonkin pets." },
        { achievementID = 13273, name = "Element of Success", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Elemental pets." },
        { achievementID = 13274, name = "Fun With Flying", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Flying pets." },
        { achievementID = 13275, name = "Magician's Secrets", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Magic pets." },
        { achievementID = 13277, name = "Machine Learning", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Mechanical pets." },
        { achievementID = 13278, name = "Not Quite Dead Yet", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Undead pets." },
        { achievementID = 13280, name = "Hobbyist Aquarist", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Aquatic pets." },
        { achievementID = 13281, name = "Human Resources", description = "Defeat 15 Master Tamers on Kul Tiras or Zandalar with a team of all level 25 Humanoid pets." },
        { achievementID = 13625, name = "Mighty Minions of Mechagon", description = "Defeat the following mechanized minions on Mechagon Island." },
        { achievementID = 13626, name = "Nautical Nuisances of Nazjatar", description = "Defeat the following deep sea terrors of Nazjatar." },
        { achievementID = 13693, name = "Mecha-Safari", description = "Catch every battle pet on Mechagon Island." },
        { achievementID = 13694, name = "Nazjatari Safari", description = "Catch every battle pet in Nazjatar." },
        { achievementID = 13715, name = "From The Belly Of The Jelly", description = "Obtain a slimy companion pet in Nazjatar." },
    } },
    { category = "collections", source = "toys", achievements = {
        { achievementID = 13708, name = "Most Minis Wins", description = "Collect all the figures from the Azeroth Mini: Mechagon set." },
    } },
    { category = "exploration", source = "zone", achievements = {
        { achievementID = 14730, name = "To All the Squirrels I Set Sail to See", description = "The critters of Kul Tiras and Zandalar are worthy of /love as well." },
    } },
    { category = "features", source = "professions", achievements = {
        { achievementID = 13489, name = "Secret Fish of Mechagon", description = "Catch and deliver each of these fish of Mechagon to Angler Danielle." },
    } },
    { category = "features", source = "war_effort", achievements = {
        { achievementID = 12572, name = "War Supplied", description = "Open a War Supply Crate from an air supply drop while within War Mode." },
        { achievementID = 13317, name = "Supplied and Ready", description = "Loot the Secret Supply Chests in Kul Tiras and Zandalar during an active Assault while in War Mode." },
        { achievementID = 13720, name = "Supplying the Assassins", description = "Loot 25 War Supply Chests in Nazjatar while an Assassin." },
    } },
})

MC.RegisterContent("shadowlands", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 14625, name = "Battle in the Shadowlands", description = "Complete 14 Pet Battle World Quests throughout the Shadowlands with a full team of level 25 pets." },
        { achievementID = 14867, name = "Shadowlands Safari", description = "Catch every battle pet in the Shadowlands." },
        { achievementID = 14868, name = "Aquatic Apparitions", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Aquatic pets." },
        { achievementID = 14869, name = "Beast Busters", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Beast pets." },
        { achievementID = 14870, name = "Creepy Critters", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Critter pets." },
        { achievementID = 14871, name = "Deathly Dragonkin", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Dragonkin pets." },
        { achievementID = 14872, name = "Eerie Elementals", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Elemental pets." },
        { achievementID = 14873, name = "Flickering Fliers", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Flying pets." },
        { achievementID = 14874, name = "Haunted Humanoids", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Humanoid pets." },
        { achievementID = 14875, name = "Mummified Magics", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Magic pets." },
        { achievementID = 14876, name = "Macabre Mechanicals", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Mechanical pets." },
        { achievementID = 14877, name = "Unholy Undead", description = "Defeat 9 Master Tamers in the Shadowlands with a team of all level 25 Undead pets." },
        { achievementID = 14881, name = "Abhorrent Adversaries of the Afterlife", description = "Defeat the following afterlife atrocities of the Shadowlands." },
        { achievementID = 15004, name = "A Sly Fox", description = "Find \"Sly\" each time he runs away." },
    } },
})

MC.RegisterContent("df", "achievements", {
    { category = "collections", source = "mounts", achievements = {
        { achievementID = 16736, name = "Grand Theft Mammoth", description = "Liberate a Qalashi magmammoth... permanently." },
    } },
    { category = "collections", source = "pets", achievements = {
        { achievementID = 16464, name = "Battle on the Dragon Isles", description = "Complete 8 Pet Battle World Quests on the Dragon Isles with a full team of level 25 pets." },
        { achievementID = 16501, name = "Aquatic Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Aquatic pets." },
        { achievementID = 16503, name = "Beast Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Beast pets." },
        { achievementID = 16504, name = "Critter Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Critter pets." },
        { achievementID = 16505, name = "Dragonkin Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Dragonkin pets." },
        { achievementID = 16506, name = "Elemental Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Elemental pets." },
        { achievementID = 16507, name = "Flying Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Flying pets." },
        { achievementID = 16508, name = "Humanoid Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Humanoid pets." },
        { achievementID = 16509, name = "Magic Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Magic pets." },
        { achievementID = 16510, name = "Mechanical Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Mechanical pets." },
        { achievementID = 16511, name = "Undead Battler of the Dragon Isles", description = "Defeat the elite pets and trainers of the Dragon Isles with a team of all level 25 Undead pets." },
        { achievementID = 16519, name = "Dragon Isles Safari", description = "In the Dragon Isles, catch all of the battle pets listed below." },
        { achievementID = 17406, name = "Battle on the Dragon Isles II", description = "Complete 8 Pet Battle World Quests on the Dragon Isles with a full team of level 25 pets." },
        { achievementID = 17541, name = "Global Swarming", description = "Defeat Vortex, Tremblor, Wildfire, and Flow in a Pet Battle." },
        { achievementID = 17880, name = "Battle in Zaralek Cavern", description = "Complete 4 Pet Battle World Quests in Zaralek Cavern with a full team of level 25 pets." },
        { achievementID = 17881, name = "Aquatic Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Aquatic pets." },
        { achievementID = 17882, name = "Beast Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Beast pets." },
        { achievementID = 17883, name = "Critter Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Critter pets." },
        { achievementID = 17890, name = "Dragonkin Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Dragonkin pets." },
        { achievementID = 17904, name = "Elemental Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Elemental pets." },
        { achievementID = 17905, name = "Flying Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Flying pets." },
        { achievementID = 17915, name = "Humanoid Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Humanoid pets." },
        { achievementID = 17916, name = "Magic Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Magic pets." },
        { achievementID = 17917, name = "Mechanical Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Mechanical pets." },
        { achievementID = 17918, name = "Undead Battler of Zaralek Cavern", description = "Defeat the pet trainers of Zaralek Cavern with a team of all level 25 Undead pets." },
        { achievementID = 18384, name = "Whelp, There It Is", description = "Help care for whelplings at Little Scales Daycare by completing the following quests." },
        { achievementID = 19401, name = "Emerald Dream Safari", description = "In the Emerald Dream, catch all of the battle pets listed below." },
    } },
    { category = "collections", source = "toys", achievements = {
        { achievementID = 17361, name = "Rumble Minis, All the Looks!", description = "Upgrade all seven Warcraft Rumble Minis twice." },
        { achievementID = 19724, name = "Hearthstone Card Collection", description = "Collect all these Hearthstone cards." },
    } },
    { category = "exploration", source = "zone", achievements = {
        { achievementID = 16502, name = "Storming the Runway", description = "Collect an armor set from the Primal Storms." },
        { achievementID = 17736, name = "The Gift of Cheese", description = "Share the Recipe Rat's greatest recipe with hungry rats across Azeroth." },
    } },
    { category = "features", source = "dragonriding", achievements = {
        { achievementID = 18928, name = "Storm Rider: Bronze", description = "Complete all Storm Gryphon races." },
        { achievementID = 18929, name = "Storm Rider: Silver", description = "Obtain silver in all the Storm Gryphon races." },
        { achievementID = 18931, name = "Storm Rider: Gold", description = "Obtain gold in all the Storm Gryphon races." },
    } },
    { category = "features", source = "war_effort", achievements = {
        { achievementID = 16613, name = "Finder's Keepers", description = "Open 10 War Supply Crates in the Dragon Isles while within War Mode." },
    } },
})

MC.RegisterContent("tww", "achievements", {
    { category = "collections", source = "pets", achievements = {
        { achievementID = 40153, name = "Battle on Khaz Algar", description = "Complete 8 Pet Battle World Quests on Khaz Algar with a full team of level 25 pets." },
        { achievementID = 40154, name = "Aquatic Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Aquatic pets." },
        { achievementID = 40155, name = "Beast Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Beast pets." },
        { achievementID = 40156, name = "Critter Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Critter pets." },
        { achievementID = 40157, name = "Dragonkin Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Dragonkin pets." },
        { achievementID = 40158, name = "Elemental Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Elemental pets." },
        { achievementID = 40161, name = "Flying Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Flying pets." },
        { achievementID = 40162, name = "Humanoid Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Humanoid pets." },
        { achievementID = 40163, name = "Magic Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Magic pets." },
        { achievementID = 40164, name = "Mechanical Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Mechanical pets." },
        { achievementID = 40165, name = "Undead Battler of Khaz Algar", description = "Defeat the pet trainers of Khaz Algar with a team of all level 25 Undead pets." },
    } },
    { category = "exploration", source = "glyphs", achievements = {
        { achievementID = 40166, name = "Isle of Dorn Glyph Hunter", description = "Discover the following Skyriding Glyphs in Isle of Dorn:" },
        { achievementID = 40703, name = "The Ringing Deeps Glyph Hunter", description = "Discover the following Skyriding Glyphs in The Ringing Deeps:" },
        { achievementID = 40704, name = "Hallowfall Glyph Hunter", description = "Discover the following Skyriding Glyphs in Hallowfall:" },
        { achievementID = 40705, name = "Azj-Kahet Glyph Hunter", description = "Discover the following Skyriding Glyphs in Azj-Kahet:" },
    } },
    { category = "exploration", source = "zone", achievements = {
        { achievementID = 40979, name = "No Crate Left Behind", description = "Find and return all Celebration Crates." },
    } },
    { category = "features", source = "dragonriding", achievements = {
        { achievementID = 40316, name = "Isle of Dorn: Bronze", description = "Complete all normal races in the Isle of Dorn." },
        { achievementID = 40317, name = "Isle of Dorn: Silver", description = "Obtain silver in all normal races in the Isle of Dorn." },
        { achievementID = 40318, name = "Isle of Dorn: Gold", description = "Obtain gold in all normal races in the Isle of Dorn." },
        { achievementID = 40319, name = "Isle of Dorn Advanced: Bronze", description = "Complete all advanced races in the Isle of Dorn." },
        { achievementID = 40320, name = "Isle of Dorn Advanced: Silver", description = "Obtain silver in all advanced races in the Isle of Dorn." },
        { achievementID = 40321, name = "Isle of Dorn Advanced: Gold", description = "Obtain gold in all advanced races in the Isle of Dorn." },
        { achievementID = 40322, name = "Isle of Dorn Reverse: Bronze", description = "Complete all reverse races in the Isle of Dorn." },
        { achievementID = 40323, name = "Isle of Dorn Reverse: Silver", description = "Obtain silver in all reverse races in the Isle of Dorn." },
        { achievementID = 40324, name = "Isle of Dorn Reverse: Gold", description = "Obtain gold in all reverse races in the Isle of Dorn." },
        { achievementID = 40325, name = "The Ringing Deeps: Bronze", description = "Complete all normal races in The Ringing Deeps." },
        { achievementID = 40326, name = "The Ringing Deeps: Silver", description = "Obtain silver in all normal races in The Ringing Deeps." },
        { achievementID = 40327, name = "The Ringing Deeps: Gold", description = "Obtain gold in all normal races in The Ringing Deeps." },
        { achievementID = 40328, name = "The Ringing Deeps Advanced: Bronze", description = "Complete all advanced races in The Ringing Deeps." },
        { achievementID = 40329, name = "The Ringing Deeps Advanced: Silver", description = "Obtain silver in all advanced races in The Ringing Deeps." },
        { achievementID = 40330, name = "The Ringing Deeps Advanced: Gold", description = "Obtain gold in all advanced races in The Ringing Deeps." },
        { achievementID = 40331, name = "The Ringing Deeps Reverse: Bronze", description = "Complete all reverse races in The Ringing Deeps." },
        { achievementID = 40332, name = "The Ringing Deeps Reverse: Silver", description = "Obtain silver in all reverse races in The Ringing Deeps." },
        { achievementID = 40333, name = "The Ringing Deeps Reverse: Gold", description = "Obtain gold in all reverse races in The Ringing Deeps." },
        { achievementID = 40334, name = "Hallowfall: Bronze", description = "Complete all normal races in Hallowfall." },
        { achievementID = 40335, name = "Hallowfall: Silver", description = "Obtain silver in all normal races in Hallowfall." },
        { achievementID = 40336, name = "Hallowfall: Gold", description = "Obtain gold in all normal races in Hallowfall." },
        { achievementID = 40337, name = "Hallowfall Advanced: Bronze", description = "Complete all advanced races in Hallowfall." },
        { achievementID = 40338, name = "Hallowfall Advanced: Silver", description = "Obtain silver in all advanced races in Hallowfall." },
        { achievementID = 40339, name = "Hallowfall Advanced: Gold", description = "Obtain gold in all advanced races in Hallowfall." },
        { achievementID = 40340, name = "Hallowfall Reverse: Bronze", description = "Complete all reverse races in Hallowfall." },
        { achievementID = 40341, name = "Hallowfall Reverse: Silver", description = "Obtain silver in all reverse races in Hallowfall." },
        { achievementID = 40342, name = "Hallowfall Reverse: Gold", description = "Obtain gold in all reverse races in Hallowfall." },
        { achievementID = 40343, name = "Azj-Kahet: Bronze", description = "Complete all normal races in Azj-Kahet." },
        { achievementID = 40344, name = "Azj-Kahet: Silver", description = "Obtain silver in all normal races in Azj-Kahet." },
        { achievementID = 40345, name = "Azj-Kahet: Gold", description = "Obtain gold in all normal races in Azj-Kahet." },
        { achievementID = 40346, name = "Azj-Kahet Advanced: Bronze", description = "Complete all advanced races in Azj-Kahet." },
        { achievementID = 40347, name = "Azj-Kahet Advanced: Silver", description = "Obtain silver in all advanced races in Azj-Kahet." },
        { achievementID = 40348, name = "Azj-Kahet Advanced: Gold", description = "Obtain gold in all advanced races in Azj-Kahet." },
        { achievementID = 40349, name = "Azj-Kahet Reverse: Bronze", description = "Complete all reverse races in Azj-Kahet." },
        { achievementID = 40350, name = "Azj-Kahet Reverse: Silver", description = "Obtain silver in all reverse races in Azj-Kahet." },
        { achievementID = 40351, name = "Azj-Kahet Reverse: Gold", description = "Obtain gold in all reverse races in Azj-Kahet." },
        { achievementID = 40936, name = "Undermine Skyrocketing: Bronze", description = "Complete all Skyrocketing races in Undermine." },
        { achievementID = 40937, name = "Undermine Skyrocketing: Silver", description = "Obtain silver in all Skyrocketing races in Undermine." },
        { achievementID = 40938, name = "Undermine Skyrocketing: Gold", description = "Obtain gold in all Skyrocketing races in Undermine." },
        { achievementID = 41081, name = "Undermine Breaknecking: Bronze", description = "Complete all normal Breakneck races in Undermine." },
        { achievementID = 41083, name = "Undermine Breaknecking: Silver", description = "Obtain silver in all Breakneck races in Undermine." },
        { achievementID = 41084, name = "Undermine Breaknecking: Gold", description = "Obtain gold in all Breakneck races in Undermine." },
    } },
})

MC.RegisterContent("midnight", "achievements", {
    { category = "features", source = "delves", achievements = {
        { achievementID = 61713, name = "Midnight Delver Damage Dealer III", description = "Complete every Midnight delve on Tier 11 with lives remaining as a damage dealer." },
        { achievementID = 61716, name = "Midnight Delver Healer III", description = "Complete every Midnight delve on Tier 11 with lives remaining as a healer." },
        { achievementID = 61719, name = "Midnight Delver Tank III", description = "Complete every Midnight delve on Tier 11 with lives remaining as a tank." },
        { achievementID = 61724, name = "The Grudge Pit Stories", description = "Complete each story variant of The Grudge Pit." },
        { achievementID = 61725, name = "Parhelion Plaza Stories", description = "Complete each story variant of Parhelion Plaza." },
        { achievementID = 61726, name = "Collegiate Calamity Stories", description = "Complete each story variant of Collegiate Calamity." },
        { achievementID = 61727, name = "The Shadow Enclave Stories", description = "Complete each story variant of The Shadow Enclave." },
        { achievementID = 61728, name = "The Darkway Stories", description = "Complete each story variant of The Darkway." },
        { achievementID = 61729, name = "Atal'Aman Stories", description = "Complete each story variant of Atal'Aman." },
        { achievementID = 61730, name = "Twilight Crypts Stories", description = "Complete each story variant of Twilight Crypts." },
        { achievementID = 61731, name = "The Gulf of Memory Stories", description = "Complete each story variant of The Gulf of Memory." },
        { achievementID = 61732, name = "Sunkiller Sanctum Stories", description = "Complete each story variant of Sunkiller Sanctum." },
        { achievementID = 61733, name = "Shadowguard Point Stories", description = "Complete each story variant of Shadowguard Point." },
        { achievementID = 61863, name = "Atal'Aman Discoveries", description = "Find and open all Sturdy Chests hidden in Atal'Aman." },
        { achievementID = 61892, name = "The Shadow Enclave Discoveries", description = "Find and open all Sturdy Chests hidden in The Shadow Enclave." },
        { achievementID = 61893, name = "Parhelion Plaza Discoveries", description = "Find and open all Sturdy Chests hidden in Parhelion Plaza." },
        { achievementID = 61894, name = "Collegiate Calamity Discoveries", description = "Find and open all Sturdy Chests hidden in Collegiate Calamity." },
        { achievementID = 61895, name = "The Darkway Discoveries", description = "Find and open all Sturdy Chests hidden in The Darkway." },
        { achievementID = 61896, name = "Twilight Crypts Discoveries", description = "Find and open all Sturdy Chests hidden in Twilight Crypts." },
        { achievementID = 61897, name = "The Grudge Pit Discoveries", description = "Find and open all Sturdy Chests hidden in The Grudge Pit." },
        { achievementID = 61898, name = "The Gulf of Memory Discoveries", description = "Find and open all Sturdy Chests hidden in The Gulf of Memory." },
        { achievementID = 61899, name = "Sunkiller Sanctum Discoveries", description = "Find and open all Sturdy Chests hidden in Sunkiller Sanctum." },
        { achievementID = 61900, name = "Shadowguard Point Discoveries", description = "Find and open all Sturdy Chests hidden in Shadowguard Point." },
    } },
    { category = "features", source = "events", achievements = {
        { achievementID = 61681, name = "Abundance: You Should See Him in a Crown", description = "Harvest a total lifetime amount of 1,000,000 Abundance." },
        { achievementID = 61937, name = "Abundance: Artisan of Mausoloa", description = "Earn 250,000 Abundance at the Watha'nan Crypts in Eversong Woods." },
        { achievementID = 61938, name = "Abundance: Artisan of Loaknit", description = "Earn 250,000 Abundance at the Loaknit Den in Zul'Aman." },
        { achievementID = 61939, name = "Abundance: Artisan of Floaret", description = "Earn 250,000 Abundance at the Floaret Grotto in Harandar." },
        { achievementID = 61940, name = "Abundance: Artisan of Loanite", description = "Earn 250,000 Abundance at the Abundant Voidburrow in Voidstorm." },
        { achievementID = 62266, name = "Abundance: An Acolyte no Longer", description = "Harvest a total lifetime amount of 10,000,000 Abundance." },
        { achievementID = 62324, name = "Abundance: Loa of all Trades", description = "Complete an Abundance event having earned points in every score catagory." },
        { achievementID = 62325, name = "Abundance: Treasures Aplenty", description = "Trigger the Treasure Dundun Bonus in each Abundance location." },
        { achievementID = 62326, name = "Abundance: Golden Opportunities", description = "Trigger the Golden Glow Bonus in each Abundance location." },
        { achievementID = 62329, name = "Abundance: Squash the Competition", description = "Trigger the Runaways Bonus in each Abundance location." },
        { achievementID = 62330, name = "Abundance: One Bite at a Time", description = "Trigger the Gigantic Harvest Bonus in each Abundance location." },
        { achievementID = 62331, name = "Abundance: Drops of Prosperity", description = "Trigger the Rain of Abundance Bonus in each Abundance location." },
        { achievementID = 62333, name = "Abundance: Harvester", description = "Complete an Abundance event having earned a score of at least 10,000 in the Materials Harvested catagory." },
        { achievementID = 62336, name = "Abundance: Contributor", description = "Complete an Abundance event having earned a score of at least 10,000 in the Materials Contributed catagory." },
        { achievementID = 62337, name = "Abundance: Professional", description = "Complete an Abundance event having earned a score of at least 10,000 in the Basic Nodes catagory." },
        { achievementID = 62338, name = "Abundance: Artisan", description = "Complete an Abundance event having earned a score of at least 10,000 in the Artisan Nodes catagory." },
        { achievementID = 62339, name = "Abundance: Gambler", description = "Complete an Abundance event having earned a score of at least 10,000 in the Bonus Events catagory." },
        { achievementID = 62340, name = "Abundance: Investor", description = "Complete an Abundance event having earned a score of at least 10,000 in the Large Orbs catagory." },
    } },
})
