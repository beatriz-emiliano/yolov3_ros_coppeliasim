function sysCall_info()
    return {autoStart=false}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"With this tool you are able to easily scale objects and models in an isometric fashion. Simply select a single object/model for the scaling dialog to appear.")
    factor=1
    currentFactor=1
    obj=-1
    xyCoordScale=false
    zCoordScale=true
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Isometric scaling" activate="false" closeable="true" on-close="close_callback" layout="vbox" '..pos..[[>
                <checkbox text="Scale also item's x/y position" on-change="xy_callback" id="3" />
                <checkbox text="Scale also item's z position" on-change="z_callback" id="4" />
                <edit value="xx" id="1" on-editing-finished="fact_callback"/>
                <hslider id="2" on-change="sliderMoved" minimum="0" maximum="100"/>
        </ui>]]
        ui=simUI.create(xml)
        simUI.setEditValue(ui,1,string.format("%.2f",factor))
        local l=math.log10(10*factor)/2
        simUI.setSliderValue(ui,2,l*100)
        simUI.setCheckboxValue(ui,3,xyCoordScale and 2 or 0)
        simUI.setCheckboxValue(ui,4,zCoordScale and 2 or 0)
    end
end

function hideDlg()
    if ui then
        uiPos={}
        uiPos[1],uiPos[2]=simUI.getPosition(ui)
        simUI.destroy(ui)
        ui=nil
    end
    factor=1
    currentFactor=1
    obj=-1
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    local show=(s and #s==1)
    if show then
        if obj~=s[1] then
            hideDlg()
            obj=s[1]
        end
        showDlg()
    else
        obj=-1
        hideDlg()
    end
end

function sysCall_beforeSimulation()
    hideDlg()
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function fact_callback(ui,id,newVal)
    local l=tonumber(newVal)
    if l then
        if l<0.1 then l=0.1 end
        if l>10 then l=10 end
        l=tonumber(string.format("%.2f",l))
        if l~=factor then
            factor=l
            simUI.setEditValue(ui,1,string.format("%.2f",l))
            l=math.log10(10*l)/2
            simUI.setSliderValue(ui,2,l*100)
        end
    end
    scale()
end

function sliderMoved(ui,id,v)
    local s=v/100
    local ds=10*0.1^((1-s)*2)
    factor=tonumber(string.format("%.2f",ds))
    simUI.setEditValue(ui,1,string.format("%.2f",factor))
    scale()
end

function xy_callback(ui,id,newVal)
    xyCoordScale=not xyCoordScale
end

function z_callback(ui,id,newVal)
    zCoordScale=not zCoordScale
end

function close_callback()
    leaveNow=true
end

function scale()
    local scaleFact=factor/currentFactor
    currentFactor=factor
    sim.scaleObjects({obj},scaleFact,false)
    local p=sim.getObjectPosition(obj,sim.handle_parent)
    if (xyCoordScale) then
        p[1]=p[1]*scaleFact
        p[2]=p[2]*scaleFact
    end
    if (zCoordScale) then
        p[3]=p[3]*scaleFact
    end
    sim.setObjectPosition(obj,sim.handle_parent,p)
end
