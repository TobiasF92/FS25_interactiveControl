------------------------------------------------------------------------------------------------------------------------
-- InteractiveFunctions_externalMods
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Storage for shared functionalities for external mods
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---Extension of "src/misc/InteractiveFunctions.lua" for external mods
---@tablelib InteractiveFunctions for external mods

---Returns modClass in modEnvironment if existing, nil otherwise.
---If no modClassName is passed, the modEnvironment will be returned.
---@param modEnvironmentName string name of the mod environment (modName)
---@param modClassName? string|nil name of the mod class
---@return Class|nil modClass
---@return nil|boolean isEnvironment
local function getExternalModClass(modEnvironmentName, modClassName)
    if not g_modIsLoaded[modEnvironmentName] then
        return nil, nil
    end

    local modEnvironment = _G[modEnvironmentName]
    if modEnvironment == nil then
        return nil, nil
    end

    if modClassName == nil then
        return modEnvironment, true
    end

    return modEnvironment[modClassName], false
end
