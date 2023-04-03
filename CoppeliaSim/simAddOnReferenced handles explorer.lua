function sysCall_info()
    return {autoStart=false}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This tool will display the referenced handles stored in the selected object. Referenced handles can be written and read with simSetReferencedHandles and simGetReferencedHandles.")
    object=-1
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeSimulation()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function onCloseClicked()
    leaveNow=true
end

function showDlg()
    if not ui then
        local pos='position="-30,160" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        if not ui then
            xml='<ui title="Referenced Handles Explorer" closeable="true" on-close="onCloseClicked" resizable="false" '..pos..'>'
            xml=xml..'<group flat="true"><label text="Referenced handles in object &quot;<b>'..sim.getObjectAlias(object,1)..'</b>&quot;:" /></group>'
            xml=xml..'<table id="600" selection-mode="row" editable="false" on-selection-change="onSelectionChange">'
            xml=xml..'<header><item>Handle</item><item>Name</item></header>'
            for i,handle in ipairs(content) do
                local name=''
                if handle~=-1 then name=sim.getObjectAlias(handle,1) end
                xml=xml..'<row><item>'..handle..'</item><item>'..name..'</item></row>'
            end
            xml=xml..'</table>'
            xml=xml..'</ui>'
            ui=simUI.create(xml)
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

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    local previousObject,previousContent=object,content
    content=nil
    object=-1
    if s then
        if #s>=1 then
            if s[#s]>=0 then
                object=s[#s]
                content=sim.getReferencedHandles(object)
            end
        end
    end
    if previousObject~=object then
        hideDlg()
    end
    if content and #content>0 then
        local _=function(x) return x~=nil and sim.packTable(x) or nil end
        if _(content)~=_(previousContent) then
            hideDlg()
        end
        showDlg()
    else
        hideDlg()
    end
end
