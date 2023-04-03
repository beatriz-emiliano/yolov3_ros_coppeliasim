simBWF=require('simBWF')
local isCustomizationScript=sim.getScriptAttribute(sim.getScriptAttribute(sim.handle_self,sim.scriptattribute_scripthandle),sim.scriptattribute_scripttype)==sim.scripttype_customizationscript

if false then -- if not sim.isPluginLoaded('Bwf') then
    function sysCall_init()
    end
else
    function sysCall_init()
        -- sim.writeCustomDataBlock(sim.getObject('.'),'',nil) -- remove all tags and data
        -- sim.writeCustomDataBlock(sim.getObject('.'),simBWF.modelTags.VISIONBOX,sim.packTable({version=1})) -- append the tag with data that just contains the version number
        model={}
        simBWF.appendCommonModelData(model,simBWF.modelTags.VISIONBOX)
        if isCustomizationScript then
            -- Customization script
            if model.modelVersion==1 then
                require("/bwf/scripts/visionBox/common")
                require("/bwf/scripts/visionBox/customization_main")
                require("/bwf/scripts/visionBox/customization_data")
                require("/bwf/scripts/visionBox/customization_ext")
                require("/bwf/scripts/visionBox/customization_dlg")
            end
        end
        sysCall_init() -- one of above's 'require' redefined that function
    end
end
