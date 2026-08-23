local _, MC = ...

-- The Burning Crusade player-facing achievements. Exact 99-row manifest;
-- stable criteria tasks are attached only for 2-30-row progress lists.
MC.RegisterContent("tbc", "achievements", {
    { category = "features", source = "eye_of_storm", achievements = {
        { achievementID = 212, name = "Storm Capper", description = "Personally carry and capture the flag in Eye of the Storm.", zone = "Eye of the Storm",
          taskList = { intro = "Progress from live achievement criteria.", tasks = {
              { achievementID = 212, criteriaID = 438, label = "Capture the flag" },
              { achievementID = 212, criteriaID = 33092, label = "Capture the flag" },
          } } },
        { achievementID = 213, name = "Stormtrooper", description = "Kill 5 flag carriers in a single Eye of the Storm battle.", zone = "Eye of the Storm",
          taskList = { intro = "Progress from live achievement criteria.", tasks = {
              { achievementID = 213, criteriaID = 3685, label = "5 Flag Carriers" },
              { achievementID = 213, criteriaID = 28767, label = "5 Flag Carriers" },
          } } },
        { achievementID = 1171, name = "Master of Eye of the Storm", description = "Complete the Eye of the Storm achievements listed below.", zone = "Eye of the Storm",
          taskList = { intro = "Progress from live achievement criteria.", tasks = {
              { achievementID = 1171, criteriaID = 3446, label = "Eye of the Storm Veteran" },
              { achievementID = 1171, criteriaID = 3447, label = "The Perfect Storm" },
              { achievementID = 1171, criteriaID = 3448, label = "Eye of the Storm Domination" },
              { achievementID = 1171, criteriaID = 3449, label = "Flurry" },
              { achievementID = 1171, criteriaID = 3450, label = "Stormtrooper" },
              { achievementID = 1171, criteriaID = 3451, label = "Storm Capper" },
              { achievementID = 1171, criteriaID = 3452, label = "Bound for Glory" },
              { achievementID = 1171, criteriaID = 3453, label = "Bloodthirsty Berserker" },
          } } },
    } },
})
