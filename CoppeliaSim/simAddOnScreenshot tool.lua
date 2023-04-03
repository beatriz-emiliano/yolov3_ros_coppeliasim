function sysCall_info()
    return {autoStart=false}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"Select the camera or vision sensor you wish to generate a high resolution screenshot for. This model is courtesy of Ulrich Schwesinger.")
    config={}
    config.res={4096,2304}
    config.viewAngle=60*math.pi/180
    config.viewSize=4
    config.perspective=true
    config.transparent=false
    config.fileDlg=true
    config.renderMode='opengl'
    config.povray={}
    config.povray.available=false
    config.povray.focalBlur=false
    config.povray.focalDistance=2
    config.povray.aperture=0.05
    config.povray.blurSamples=10
    config.nearClipping=0.01
    config.farClipping=250
    
    local moduleName=0
    local index=0
    while moduleName do
        moduleName=sim.getModuleName(index)
        if moduleName=='PovRay' then
            config.povray.available=true
            break
        end
        index=index+1
    end
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    showOrHideDlg()
end

function sysCall_sensing()
    if leaveNow then
        return {cmd='cleanup'}
    end
    showOrHideDlg()
end

function showOrHideDlg()
    local s=sim.getObjectSelection()
    local show=false
    if s and #s==1 and ( (sim.getObjectType(s[1])==sim.object_camera_type) or (sim.getObjectType(s[1])==sim.object_visionsensor_type) ) then
        cam=s[1]
        showDlg()
    else
        cam=nil
        hideDlg()
    end
end

function showImage()
    local xml =[[<ui title="Screenshot" closeable="true" on-close="imClose_callback" placement="center" modal="true">
        <image id="1" keep-aspect-ratio="true" scaled-contents="true" style="* {background-color: #555555}" />
        <button text="save screenshot" on-click="save_callback"/>
    </ui>]]
    imUi=simUI.create(xml)
end

function imClose_callback()
    simUI.destroy(imUi)
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Screenshot tool" activate="false" closeable="true" on-close="close_callback" '..pos..[[>

            <group layout="form" flat="true">
            <checkbox text="empty areas are transparent" on-change="transparent_callback" id="4" />
            <label text=""/>
            <checkbox text="show file dialog" on-change="dlg_callback" id="5" />
            <label text=""/>
            <checkbox text="perspective mode" on-change="perspective_callback" id="6" />
            <label text=""/>
            <label text="resolution X"/>
            <edit on-editing-finished="res_callback" id="1" />
            <label text="resolution Y"/>
            <edit on-editing-finished="res_callback" id="2" />
            <label text="view angle"/>
            <edit on-editing-finished="viewAngle_callback" id="7" />
            <label text="view size"/>
            <edit on-editing-finished="viewSize_callback" id="8" />
            
            <radiobutton text="OpenGL rendering" on-click="rendering_callback" id="21" />
            <label text=""/>
            <radiobutton text="OpenGL3 rendering" on-click="rendering_callback" id="22" />
            <label text=""/>
            <radiobutton text="POV-Ray rendering" on-click="rendering_callback" id="23" />
            <label text=""/>
            </group>
            
            <group layout="form" flat="true" id="30">
            <label text="POV-Ray rendering:"/>
            <label text=""/>
            <checkbox text="focal blur (slow)" on-change="povItems_callback" id="31" />
            <label text=""/>
            <label text="focal distance"/>
            <edit on-editing-finished="povItems_callback" id="32" />
            <label text="aperture"/>
            <edit on-editing-finished="povItems_callback" id="33" />
            <label text="blur samples"/>
            <edit on-editing-finished="povItems_callback" id="34" />
            </group>
            
            <button text="render screenshot" on-click="render_callback"/>
        </ui>]]
        ui=simUI.create(xml)
        updateDlg()
    end
end

function updateDlg()
    local sel=simUI.getCurrentEditWidget(ui)
    simUI.setEditValue(ui,1,tostring(math.floor(config.res[1])))
    simUI.setEditValue(ui,2,tostring(math.floor(config.res[2])))
    simUI.setEditValue(ui,7,tostring(math.floor(0.5+config.viewAngle*180/math.pi)))
    simUI.setEditValue(ui,8,string.format('%.2f',config.viewSize))
    simUI.setEnabled(ui,7,config.perspective)
    simUI.setEnabled(ui,8,not config.perspective)
    simUI.setCheckboxValue(ui,4,config.transparent and 2 or 0)
    simUI.setCheckboxValue(ui,5,config.fileDlg and 2 or 0)
    simUI.setCheckboxValue(ui,6,config.perspective and 2 or 0)
    simUI.setRadiobuttonValue(ui,21,config.renderMode=='opengl' and 1 or 0)
    simUI.setRadiobuttonValue(ui,22,config.renderMode=='opengl3' and 1 or 0)
    simUI.setRadiobuttonValue(ui,23,config.renderMode=='povray' and 1 or 0)
    simUI.setEnabled(ui,23,config.povray.available)
    simUI.setEnabled(ui,30,config.povray.available and config.renderMode=='povray')
    simUI.setCheckboxValue(ui,31,config.povray.focalBlur and 2 or 0)
    simUI.setEditValue(ui,32,string.format('%.2f',config.povray.focalDistance))
    simUI.setEnabled(ui,32,config.povray.available and config.renderMode=='povray' and config.povray.focalBlur)
    simUI.setEditValue(ui,33,string.format('%.2f',config.povray.aperture))
    simUI.setEnabled(ui,33,config.povray.available and config.renderMode=='povray' and config.povray.focalBlur)
    simUI.setEditValue(ui,34,tostring(math.floor(config.povray.blurSamples+0.5)))
    simUI.setEnabled(ui,34,config.povray.available and config.renderMode=='povray' and config.povray.focalBlur)
    simUI.setCurrentEditWidget(ui,sel)
end

function hideDlg()
    if ui then
        uiPos={}
        uiPos[1],uiPos[2]=simUI.getPosition(ui)
        simUI.destroy(ui)
        ui=nil
    end
end

function transparent_callback(ui,id,v)
    config.transparent=not config.transparent
    updateDlg()
end

function dlg_callback(ui,id,v)
    config.fileDlg=not config.fileDlg
    updateDlg()
end

function perspective_callback(ui,id,v)
    config.perspective=not config.perspective
    updateDlg()
end

function res_callback(ui,id,v)
    v=tonumber(v)
    if v then
        v=math.floor(math.abs(v)+0.5)
        if v>4096 then v=4096 end
        if v<2 then v=2 end
        config.res[id]=v
    end
    updateDlg()
end

function viewAngle_callback(ui,id,v)
    v=tonumber(v)
    if v then
        if v>90 then v=90 end
        if v<5 then v=5 end
        v=v+0.5
        config.viewAngle=v*math.pi/180
    end
    updateDlg()
end

function viewSize_callback(ui,id,v)
    v=tonumber(v)
    if v then
        if v>100 then v=100 end
        if v<0.05 then v=0.05 end
        config.viewSize=v
    end
    updateDlg()
end

function rendering_callback(ui,id,v)
    if id==21 then
        config.renderMode='opengl'
    end
    if id==22 then
        config.renderMode='opengl3'
    end
    if id==23 then
        config.renderMode='povray'
    end
    updateDlg()
end

function povItems_callback(ui,id,v)
    if id==31 then
        config.povray.focalBlur=not config.povray.focalBlur
    else
        v=tonumber(v)
        if v then
            if id==32 then
                if v>100 then v=100 end
                if v<0.01 then v=0.01 end
                config.povray.focalDistance=v
            end
            if id==33 then
                if v>1 then v=1 end
                if v<0.01 then v=0.01 end
                config.povray.aperture=v
            end
            if id==34 then
                if v>50 then v=50 end
                if v<1 then v=1 end
                config.povray.blurSamples=math.floor(v+0.5)
            end
        end
    end
    updateDlg()
end

function render_callback(ui,id,v)
    local pose=sim.getObjectPose(cam,-1)
    local opt=1
    local a=config.viewSize
    if config.perspective then
        opt=opt|2
        a=config.viewAngle
    end
    local visSens=sim.createVisionSensor(opt,{config.res[1],config.res[2],0,0},{config.nearClipping,config.farClipping,a,0.1,0.1,0.1,0,0,0,0,0})
    sim.setObjectPose(visSens,-1,pose)
--    sim.setObjectInt32Param(visSens,sim.visionintparam_resolution_x,config.res[1])
--    sim.setObjectInt32Param(visSens,sim.visionintparam_resolution_y,config.res[2])
--    sim.setObjectFloatParam(visSens,sim.visionfloatparam_perspective_angle,config.viewAngle)
--    sim.setObjectFloatParam(visSens,sim.visionfloatparam_ortho_size,config.viewSize)
--    sim.setObjectInt32Param(visSens,sim.visionintparam_perspective_operation,config.perspective and 1 or 0)
    sim.setObjectInt32Param(visSens,sim.visionintparam_pov_focal_blur,config.povray.focalBlur and 1 or 0)
    sim.setObjectFloatParam(visSens,sim.visionfloatparam_pov_blur_distance,config.povray.focalDistance)
    sim.setObjectFloatParam(visSens,sim.visionfloatparam_pov_aperture,config.povray.aperture)
    sim.setObjectInt32Param(visSens,sim.visionintparam_pov_blur_sampled,config.povray.blurSamples)
    if config.renderMode=='opengl' then
        sim.setObjectInt32Param(visSens,sim.visionintparam_render_mode,0)
    end
    if config.renderMode=='opengl3' then
        sim.setObjectInt32Param(visSens,sim.visionintparam_render_mode,7)
    end
    if config.renderMode=='povray' then
        sim.setObjectInt32Param(visSens,sim.visionintparam_render_mode,3)
    end

    local savedVisibilityMask=0
    local savedVisibilityMask=sim.getObjectInt32Param(cam,sim.objintparam_visibility_layer)
    sim.setObjectInt32Param(cam,sim.objintparam_visibility_layer,0)
    local newAttr=sim.displayattribute_renderpass
    newAttr=newAttr+sim.displayattribute_forvisionsensor
    newAttr=newAttr+sim.displayattribute_ignorerenderableflag
    sim.setObjectInt32Param(visSens,sim.visionintparam_rendering_attributes,newAttr)
    sim.handleVisionSensor(visSens)
    sim.setObjectInt32Param(cam,sim.objintparam_visibility_layer,savedVisibilityMask)
    showImage()
    local img,x,y=sim.getVisionSensorCharImage(visSens)
    local rxy={}
    img,rxy=sim.getScaledImage(img,{x,y},{800,800},4)
    simUI.setImageData(imUi,1,img,rxy[1],rxy[2])
    local cutOff=0
    if config.transparent then
        cutOff=0.99
    end
    image,resX,resY=sim.getVisionSensorCharImage(visSens,0,0,0,0,cutOff)
    sim.removeObject(visSens)
end

function save_callback(ui,id,v)
    local options=0
    if config.transparent then
        options=1
    end
    local filenameAndPath
    if config.fileDlg then
        filenameAndPath=sim.fileDialog(sim.filedlg_type_save,'title','','screenshot.png','image file','*')
    else
        local theOs=sim.getInt32Param(sim.intparam_platform)
        if theOs==1 then
            -- MacOS, special: executable is inside of a bundle:
            filenameAndPath='../../../coppeliaSim_screenshot_'..os.date("%Y_%m_%d-%H_%M_%S",os.time())..'.png'
        else
            filenameAndPath='coppeliaSim_screenshot_'..os.date("%Y_%m_%d-%H_%M_%S",os.time())..'.png'
        end
    end
    if filenameAndPath then
        if sim.saveImage(image,{resX,resY},options,filenameAndPath,-1)~=-1 then
            sim.addLog(sim.verbosity_msgs,"Screenshot was saved to "..filenameAndPath)
            simUI.msgBox(simUI.msgbox_type.info,simUI.msgbox_buttons.ok,'Screenshot',"Screenshot was saved to "..filenameAndPath)
        else
            sim.addLog(sim.verbosity_scripterrors,"Failed saving the screenshot. Did you specify a supported image extension?")
            simUI.msgBox(simUI.msgbox_type.warning,simUI.msgbox_buttons.ok,'Screenshot',"Failed saving the screenshot. Did you specify a supported image extension?")
        end
    else
        sim.addLog(sim.verbosity_scripterrors,"Failed saving the screenshot. Bad filename or action canceled.")
        simUI.msgBox(simUI.msgbox_type.warning,simUI.msgbox_buttons.ok,'Screenshot',"Failed saving the screenshot. Bad filename or action canceled.")
    end
    simUI.destroy(imUi)
    imUi=nil
end

function close_callback()
    leaveNow=true
end
