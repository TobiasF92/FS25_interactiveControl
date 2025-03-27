------------------------------------------------------------------------------------------------------------------------
-- XMLInjectionsManager
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Manager for XML injections into files
--
---@author John Deere 6930 @VertexDezign
---@version 1.0.0.0
------------------------------------------------------------------------------------------------------------------------

---@class XMLInjectionsManager
---@field public modName string
---@field public modDirectory string
---@field public xmlRootFilename string
---@field public injectionsByXMLFilename table<string, table>
XMLInjectionsManager = {}

local xmlInjectionsManager_mt = Class(XMLInjectionsManager)

---@type table<string, string> Type to XMLFile set-function mapping
local XML_SET_FUNCTION_BY_TYPE = {
    bool = "setBool",
    int = "setInt",
    float = "setFloat",
    string = "setString",
}

---@type table<string, string> Type to XMLFile get-function mapping
local XML_GET_FUNCTION_BY_TYPE = {
    bool = "getBool",
    int = "getInt",
    float = "getFloat",
    string = "getString",
}

---Create new instance of XMLInjectionsManager
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return XMLInjectionsManager
function XMLInjectionsManager.new(modName, modDirectory, customMt)
    local self = setmetatable({}, customMt or xmlInjectionsManager_mt)

    self.modName = modName
    self.modDirectory = modDirectory

    self.xmlRootFilename = ""
    self.injectionsByXMLFilename = {}

    return self
end

---Called on load
---@param xmlRootFilename string Filename to injection root file
function XMLInjectionsManager:load(xmlRootFilename)
    self.xmlRootFilename = xmlRootFilename

    self:loadInjectionXMLs(xmlRootFilename)
end

---Called on delete
function XMLInjectionsManager:delete()
    self.xmlRootFilename = ""
    self.injectionsByXMLFilename = nil
end

---Load XML injections recursively through XMLFile
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param injectionKey string XML injection key
---@param injections table Injection storage
function XMLInjectionsManager:loadXMLInjectionsRecursively(xmlFile, key, injectionKey, injections)
    xmlFile:iterate(key .. ".xml", function(_, xmlKey)
        local _injectionKey = injectionKey .. xmlFile:getString(xmlKey .. "#key", "")

        xmlFile:iterate(xmlKey .. ".entry", function(_, entryKey)
            local vType = xmlFile:getString(entryKey .. "#type", "string")
            local vKey = xmlFile:getString(entryKey .. "#key")
            local vValue = xmlFile[XML_GET_FUNCTION_BY_TYPE[vType]](xmlFile, entryKey .. "#value")

            if vKey == nil or vKey == "" or vValue == nil then
                return
            end

            table.addElement(injections,
                {
                    key = _injectionKey .. vKey,
                    value = vValue,
                    type = vType,
                }
            )
        end)

        self:loadXMLInjectionsRecursively(xmlFile, xmlKey, _injectionKey, injections)
    end)
end

---Load injections from xmlFile
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
function XMLInjectionsManager:loadXMLInjectionsFromXML(xmlFile, key)
    local injectionXmlFilename = xmlFile:getString(key .. "#xmlFilename")

    if injectionXmlFilename == nil or injectionXmlFilename == "" then
        return
    end

    -- support for modDir, mapDir, pdlcdir
    injectionXmlFilename = NetworkUtil.convertFromNetworkFilename(injectionXmlFilename)

    if self.injectionsByXMLFilename[injectionXmlFilename] ~= nil then
        Logging.xmlError(xmlFile, "Can't load injection, because injection for '%s' already exists!", injectionXmlFilename)
        return
    end

    local injections = {}
    self:loadXMLInjectionsRecursively(xmlFile, key, "", injections)

    self.injectionsByXMLFilename[injectionXmlFilename] = injections
end

---Load injection xml file
---@param xmlFilename string Filename to injection xmlFile
---@param rootName string Root name of xml type
function XMLInjectionsManager:loadInjectionsFromXML(xmlFilename, rootName)
    local xmlFile = XMLFile.load("injectionXMLFile", self.modDirectory .. xmlFilename)

    xmlFile:iterate("data." .. rootName, function(_, key)
        self:loadXMLInjectionsFromXML(xmlFile, key)
    end)

    xmlFile:delete()
end

---Load injection xml files from xmlRootFilename
---@param xmlRootFilename string Filename to injection root xmlFile
function XMLInjectionsManager:loadInjectionXMLs(xmlRootFilename)
    self.injectionsByXMLFilename = {}
    local xmlFile = XMLFile.load("XMLInjections", self.modDirectory .. (xmlRootFilename or self.xmlRootFilename))

    xmlFile:iterate("files.file", function(_, key)
        local path = xmlFile:getString(key .. "#path")

        if path == nil or path == "" then
            return
        end

        local rootName = xmlFile:getString(key .. "#rootName", "vehicle")
        self:loadInjectionsFromXML(path, rootName)
    end)

    xmlFile:delete()
end

---Prepended function of initInheritance, checks for parent xmlFilename
---@param xmlFile XMLFile Instance of XMLFile
function XMLInjectionsManager:checkParentXMLData(xmlFile)
    -- check for parent file
    local rootName = xmlFile:getRootName()
    local parentFilename = xmlFile:getString(rootName .. ".parentFile#xmlFilename")

    if parentFilename ~= nil then
        local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFile.filename)
        xmlFile.parentFilename = Utils.getFilename(parentFilename, baseDirectory)
    end
end

---Appended function of initInheritance, injects XML parts into XMLFile
---@param xmlFile XMLFile Instance of XMLFile
function XMLInjectionsManager:injectXMLData(xmlFile)
    if xmlFile.handle == nil then
        return
    end

    local injectionFilenames = { xmlFile.filename }
    if xmlFile.parentFilename ~= nil then
        injectionFilenames = { xmlFile.parentFilename, xmlFile.filename }
    end

    -- check for injections
    for _, filename in ipairs(injectionFilenames) do
        local injectionData = self.injectionsByXMLFilename[filename]

        if injectionData ~= nil then
            for _, entry in ipairs(injectionData) do
                xmlFile[XML_SET_FUNCTION_BY_TYPE[entry.type]](xmlFile, entry.key, entry.value)
            end
        end
    end
end
