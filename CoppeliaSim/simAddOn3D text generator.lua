function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    textUtils=require('textUtils')
    sim.addLog(sim.verbosity_scriptinfos,"This tool allows to generate 3D text. Courtesy of 'Mechatronics Ninja'")
    prevObj=-1
    showDlg()
    config={}
    config.color={1,1,1}
    config.text="Hello\nWorld"
    config.height=0.1
    config.centered=false
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    if s and #s==1 then
        initDlg(s[1])
    else
        prevObj=-1
    end
end

function sysCall_beforeSimulation()
    hideDlg()
end

function sysCall_afterSimulation()
    showDlg()
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function sysCall_afterInstanceSwitch()
    showDlg()
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="3D text generator" activate="false" closeable="true" on-close="close_callback" '..pos..[[>
            <label text="Text:"/>
            <edit value="Hello\nWorld" on-change="text_callback" id="1" />
            <label text="Height:"/>
            <edit value="0.1" on-change="height_callback" id="2" />
            <checkbox checked="false" text="Centered" on-change="centered_callback" id="3" />
            <button text="Edit color" on-click="color_callback" id="4"/>
            <button text="Generate new" on-click="generate_callback" id="5"/>
        </ui>]]
        ui=simUI.create(xml)
    end
end

function initDlg(obj)
    if obj>=0 and obj~=prevObj and ui then
        local data=sim.readCustomTableData(obj,'__info__')
        if data.type=='3dText' then
            prevObj=obj
            config=sim.readCustomTableData(obj,'__config__')
            local txt=config.text:gsub("\n","\\n")
            simUI.setEditValue(ui,1,txt)
            simUI.setEditValue(ui,2,string.format("%2f",config.height))
            simUI.setCheckboxValue(ui,3,not config.centered and 0 or 2) 
        end
    end
end

function hideDlg()
    if ui then
        uiPos={}
        uiPos[1],uiPos[2]=simUI.getPosition(ui)
        simUI.destroy(ui)
        ui=nil
    end
end

function height_callback(ui,id,v)
    local nb=tonumber(v)
    if nb then
        if nb<0.01 then
            nb=0.01
        end
        if nb>1 then
            nb=1
        end
        config.height=nb
        update()
    end
end

function centered_callback(ui,id,v)
    config.centered=(v~=0)
    update()
end

function text_callback(ui,id,v)
    v=v:gsub("\\n","\n")
    config.text=v
    update()
end

function color_callback()
    local c=simUI.colorDialog(config.color,"Text color",false,true)
    if c then
        config.color=c
        update()
    end
end

function generate_callback()
    update(true)
end

function close_callback()
    leaveNow=true
end

function update(generateNew)
    local s=sim.getObjectSelection()
    local parentDummy
    if s and (#s==1) then
        local data=sim.readCustomTableData(s[1],'__info__')
        if data.type=='3dText' then
            parentDummy=s[1]
        end
    end
    local doNothing
    if generateNew then
        parentDummy=nil
    else
        doNothing=(parentDummy==nil)
    end
    if not doNothing then
        local h=textUtils.generateTextShape(config.text,config.color,config.height,config.centered,nil,parentDummy)
        sim.writeCustomTableData(h,'__info__',{type='3dText'})
        sim.writeCustomTableData(h,'__config__',config)
    end
end

