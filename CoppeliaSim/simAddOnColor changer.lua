function sysCall_info()
    return {autoStart=false}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This tool allows you to change the color of shapes, when those colors are named. Simply select individual shapes or models.")
    previousSelectedObjects={}
    colorNameIndex=-1
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    selectedObjects=sim.getObjectSelection()
    if not selectedObjects then selectedObjects={} end
    selectedObjects=getAlsoModelObjectsAndOnlyShapes(selectedObjects)
    if not areObjectsSame(selectedObjects,previousSelectedObjects) then
        hideDlg2()
        hideDlg1()
        previousSelectedObjects={}
        for i=1,#selectedObjects,1 do
            previousSelectedObjects[i]=selectedObjects[i]
        end
        if #selectedObjects>0 then
            colorNames={}
            for i=1,#selectedObjects,1 do
                local s=sim.getObjectStringParam(selectedObjects[i],sim.shapestringparam_color_name)
                if s and s~='' then
                    for token in string.gmatch(s,"[^%s]+") do
                        colorNames[token]=token
                    end
                end
            end
            colorNameTable={}
            for k, v in pairs(colorNames) do
                colorNameTable[#colorNameTable+1]=k
            end
            showDlg1(colorNameTable)
        end
    end
end

function sysCall_cleanup()
    hideDlg2()
    hideDlg1()
end

function sysCall_beforeSimulation()
    hideDlg2()
    hideDlg1()
    previousSelectedObjects={}
end

function sysCall_beforeInstanceSwitch()
    hideDlg2()
    hideDlg1()
    previousSelectedObjects={}
end

function showDlg1()
    if not ui and #colorNameTable>0 then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Color names" activate="false" closeable="true" on-close="close_callback" layout="vbox" '..pos..'>'
        for i=1,#colorNameTable,1 do
            xml=xml..'<button text="'..colorNameTable[i]..'" on-click="colorClick_callback" id="'..i..'" />'
        end
        xml=xml..'</ui>'
        ui=simUI.create(xml)
    end
end

function hideDlg1()
    if ui then
        uiPos={}
        uiPos[1],uiPos[2]=simUI.getPosition(ui)
        simUI.destroy(ui)
        ui=nil
    end
end

function close_callback()
    leaveNow=true
end

function colorClick_callback(ui,id,v)
    hideDlg1()
    colorNameIndex=id
    showDlg2()
end

function showDlg2()
    local pos='position="-50,50" placement="relative"'
    if ui2Pos then
        pos='position="'..ui2Pos[1]..','..ui2Pos[2]..'" placement="absolute"'
    end
    local xml ='<ui title="Color ['..colorNameTable[colorNameIndex]..']" activate="false" closeable="true" on-close="close2_callback" layout="vbox" '..pos..'>'
    xml=xml..[[
        <label text="Ambient+diffuse" style="* {font-weight: bold;}"/>
            <group layout="form" flat="true">
                <label text="red"/>
                <hslider id="1" on-change="sliderMoved" minimum="0" maximum="100"/>
                <label text="green"/>
                <hslider id="2" on-change="sliderMoved" minimum="0" maximum="100"/>
                <label text="blue"/>
                <hslider id="3" on-change="sliderMoved" minimum="0" maximum="100"/>
            </group>
    
        <label text="Specular" style="* {font-weight: bold;}"/>
            <group layout="form" flat="true">
                <label text="red"/>
                <hslider id="4" on-change="sliderMoved" minimum="0" maximum="100"/>
                <label text="green"/>
                <hslider id="5" on-change="sliderMoved" minimum="0" maximum="100"/>
                <label text="blue"/>
                <hslider id="6" on-change="sliderMoved" minimum="0" maximum="100"/>
            </group>

        <label text="Emission" style="* {font-weight: bold;}"/>
            <group layout="form" flat="true">
                <label text="red"/>
                <hslider id="7" on-change="sliderMoved" minimum="0" maximum="100"/>
                <label text="green"/>
                <hslider id="8" on-change="sliderMoved" minimum="0" maximum="100"/>
                <label text="blue"/>
                <hslider id="9" on-change="sliderMoved" minimum="0" maximum="100"/>
            </group>
    </ui>]]
    ui2=simUI.create(xml)
    ambientDiffuse,specular,emission=getColorValuesForColorName(colorNameTable[colorNameIndex],selectedObjects)
    for i=1,3,1 do
        simUI.setSliderValue(ui2,i+0,ambientDiffuse[i]*100)
        simUI.setSliderValue(ui2,i+3,specular[i]*100)
        simUI.setSliderValue(ui2,i+6,emission[i]*100)
    end
end

function hideDlg2()
    if ui2 then
        ui2Pos={}
        ui2Pos[1],ui2Pos[2]=simUI.getPosition(ui2)
        simUI.destroy(ui2)
        ui2=nil
        colorNameIndex=-1
        previousSelectedObjects={}
    end
end

function sliderMoved(ui,id,v)
    local s=v/100
    if id<=3 then
        ambientDiffuse[id]=s
    end
    if id>3 and id<=6 then
        id=id-3
        specular[id]=s
    end
    if id>6 then
        id=id-6
        emission[id]=s
    end
    local colName=colorNameTable[colorNameIndex]
    for i=1,#selectedObjects,1 do
        sim.setShapeColor(selectedObjects[i],colName,sim.colorcomponent_ambient_diffuse,ambientDiffuse)
        sim.setShapeColor(selectedObjects[i],colName,sim.colorcomponent_specular,specular)
        sim.setShapeColor(selectedObjects[i],colName,sim.colorcomponent_emission,emission)
    end
end

function close2_callback()
    hideDlg2()
end

getAlsoModelObjectsAndOnlyShapes=function(sel)
    local retSel={}
    for i=1,#sel,1 do
        local p=sim.getModelProperty(sel[i])
        if (p&sim.modelproperty_not_model)==0 then
            -- We have a model
            local modObjs=sim.getObjectsInTree(sel[i],sim.object_shape_type)
            for k=1,#modObjs,1 do
                local addIt=true
                for j=1,#retSel,1 do
                    if retSel[j]==modObjs[k] then
                        addIt=false
                        break
                    end
                end
                if addIt then
                    retSel[#retSel+1]=modObjs[k]
                end
            end
        else
            -- We do not have a model
            if sim.getObjectType(sel[i])==sim.object_shape_type then
                -- We have a shape
                local addIt=true
                for j=1,#retSel,1 do
                    if retSel[j]==sel[i] then
                        addIt=false
                        break
                    end
                end
                if addIt then
                    retSel[#retSel+1]=sel[i]
                end
            end
        end
    end
    return retSel
end

areObjectsSame=function(sel1,sel2)
    if #sel1~=#sel2 then
        return false
    else
        for i=1,#sel1,1 do
            if sel1[i]~=sel2[i] then
                return false
            end
        end
        return true
    end
end

getColorValuesForColorName=function(colName,selObjects)
    for i=1,#selObjects,1 do
        local r,v0=sim.getShapeColor(selObjects[i],colName,sim.colorcomponent_ambient_diffuse)
        if r>0 then
            local r,v1=sim.getShapeColor(selObjects[i],colName,sim.colorcomponent_specular)
            local r,v2=sim.getShapeColor(selObjects[i],colName,sim.colorcomponent_emission)
            return v0,v1,v2
        end
    end
    return nil,nil,nil
end

