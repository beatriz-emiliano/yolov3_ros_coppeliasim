function sysCall_info()
    return {autoStart=false}
end

function sysCall_init()
    h=sim.auxiliaryConsoleOpen('CoppeliaSim Plugins',100,4,{100,100},{800,300})
    sim.auxiliaryConsolePrint(h,'Following CoppeliaSim plugins are loaded and operational:'..'\n\n')
    i=0
    while (true) do
        name,version=sim.getModuleName(i)
        if (name) then
            str='-'..name..' (version: '..version
            if sim.getInt32Param(sim.intparam_program_version)>=30500 then
                local extVer=sim.getModuleInfo(name,0)
                if #extVer>0 then
                    str=str..', extended version string: '..extVer
                end
                local buildDate=sim.getModuleInfo(name,1)
                if #buildDate>0 then
                    str=str..', build date: '..buildDate
                end
            end
            str=str..')\n'
            sim.auxiliaryConsolePrint(h,str)
        else
            break
        end
        i=i+1
    end
    return {cmd='cleanup'}
end
