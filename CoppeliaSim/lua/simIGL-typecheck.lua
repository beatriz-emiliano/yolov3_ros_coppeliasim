-- simIGL lua type-checking wrapper
-- (this file is automatically generated: do not edit)
require 'checkargs'

local simIGL=require('simIGL')

function simIGL.__addTypeCheck()
    local function wrapFunc(funcName,wrapperGenerator)
        _G['simIGL'][funcName]=wrapperGenerator(_G['simIGL'][funcName])
    end

end

sim.registerScriptFuncHook('sysCall_init','simIGL.__addTypeCheck',true)

return simIGL