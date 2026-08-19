local _, MC = ...

-- The original per-profession files are the Midnight catalog and assign
-- MC.<Profession>Recipes directly. Adopt those tables only after all nine
-- files have loaded so expansion filters and the per-module registry see
-- Midnight before older expansion categories are appended.
for skillLine in pairs(MC.RECIPE_DATA_KEYS) do
    MC.RegisterExistingRecipeContent("midnight", skillLine)
end
