function sysCall_info()
    return {autoStart=false,menu='Importers\nFloor plan importer'}
end

function optimize(grid)
    local function findLargestRectFrom(grid,i,j)
        local function maxHeightWithFixedW(grid,i,j,w)
            local jj=-1
            if grid[j][i]~=0 then
                jj=j
                while jj<=#grid and grid[jj][i]~=0 do
                    local ii=i
                    while ii-i<w do
                        if grid[jj][ii]==0 then
                            return jj-j
                        end
                        ii=ii+1
                    end
                    jj=jj+1
                end
            end
            return jj-j
        end
        local max_w,max_h,max_a=0,0,0
        local ei,ej=-1,-1
        local max_w=0
        while max_w<=#grid[1]-i and grid[j][i+max_w]~=0 do
            local max_hh=maxHeightWithFixedW(grid,i,j,max_w+1)
            if max_hh>max_h then
                max_h=max_hh
            end
            local max_aa=max_hh*(max_w+1)
            if max_aa>max_a then
                max_a=max_aa
                ei=i+max_w
                ej=j+max_hh-1
            end
            max_w=max_w+1
        end
        return ei,ej
    end
    local rects={}
    for j=1,#grid do
        for i=1,#grid[1] do
            if grid[j][i]==1 then
                local ii,jj=findLargestRectFrom(grid,i,j)
                table.insert(rects,{i,j,ii,jj})
                for iii=i,ii do for jjj=j,jj do grid[jjj][iii]=2 end end
            end
        end
    end
    return rects
end

function sysCall_init()
    color={0.95,0.95,0.95}
    colorCSS=function(c) return string.format('rgb(%d,%d,%d)',math.floor(255*c[1]),math.floor(255*c[2]),math.floor(255*c[3])) end
    path=sim.getStringParam(sim.stringparam_scene_path)
    fmts,fmtss=simUI.supportedImageFormats(';')
    imageFile=sim.fileDialog(sim.filedlg_type_load,'Open image...',path,'','Image files',fmtss)
    addCuboid=function(classTbl,x1,y1,x2,y2)
        local handles={}
        for j,classTbl1 in ipairs(classTbl.zSet) do
            local h=sim.createPureShape(0,1+(respondable and 8 or 0)+16,{x2-x1,y2-y1,classTbl1.zMax-classTbl1.zMin},0)
            sim.setObjectPosition(h,-1,{(x1+x2)/2,(y1+y2)/2,(classTbl1.zMax+classTbl1.zMin)/2})
            sim.setShapeColor(h,nil,sim.colorcomponent_ambient_diffuse,color)
            table.insert(handles,h)
        end
        if #handles>1 then
            local h=sim.groupShapes(handles)
            return h
        else
            return handles[1]
        end
    end
    addCuboidI=function(classTbl,i1,j1,i2,j2)
        i2,j2=i2 or i1,j2 or j1
        return addCuboid(classTbl,(i1-0.5)*pixelSize,(j1-0.5)*pixelSize,(i2+0.5)*pixelSize,(j2+0.5)*pixelSize)
    end
    go=function()
        pixelSize=simUI.getSpinboxValue(ui,101)
        classes={}
        classes.wall={}
        classes.wall.height=simUI.getSpinboxValue(ui,111)
        classes.wall.valueMin=simUI.getSpinboxValue(ui,201)
        classes.wall.valueMax=simUI.getSpinboxValue(ui,202)
        classes.wall.zMin=0
        classes.wall.zMax=classes.wall.height
        classes.wall.zSet={classes.wall}
        classes.door={}
        classes.door.height=simUI.getSpinboxValue(ui,112)
        classes.door.valueMin=simUI.getSpinboxValue(ui,211)
        classes.door.valueMax=simUI.getSpinboxValue(ui,212)
        classes.door.zMin=classes.door.height
        classes.door.zMax=classes.wall.zMax
        classes.door.zSet={classes.door}
        classes.window={}
        classes.window.height=simUI.getSpinboxValue(ui,113)
        classes.window.valueMin=simUI.getSpinboxValue(ui,221)
        classes.window.valueMax=simUI.getSpinboxValue(ui,222)
        classes.window.zMin=0
        classes.window.zMax=classes.door.zMin-classes.window.height
        classes.window.zSet={classes.window,classes.door}
        optimizationEnabled=simUI.getCheckboxValue(ui,901)>0
        invertImageValues=simUI.getCheckboxValue(ui,902)>0
        respondable=simUI.getCheckboxValue(ui,911)>0
        im,res=sim.loadImage(0,imageFile)
        c={res[1]/2,res[2]/2}
        im=sim.transformBuffer(im,sim.buffer_uint8rgb,1,0,sim.buffer_uint8)
        im=sim.unpackUInt8Table(im)
        handles={}
        for className,classTbl in pairs(classes) do
            classTbl.grid={}
            for j=1,res[2] do
                classTbl.grid[j]=classTbl.grid[j] or {}
                for i=1,res[1] do
                    local v=im[(j-1)*res[1]+i]
                    if invertImageValues then v=255-v end
                    classTbl.grid[j][i]=(v>=classTbl.valueMin and v<=classTbl.valueMax) and 1 or 0
                end
            end
            if optimizationEnabled then
                classTbl.rects=optimize(classTbl.grid)
                for i,rect in ipairs(classTbl.rects) do
                    table.insert(handles,addCuboidI(classTbl,rect[1]-c[1],rect[2]-c[2],rect[3]-c[1],rect[4]-c[2]))
                end
            else
                for j=1,#classTbl.grid do
                    for i=1,#classTbl.grid[1] do
                        if classTbl.grid[j][i]==1 then
                            table.insert(handles,addCuboidI(classTbl,i-c[1],j-c[2]))
                        end
                    end
                end
            end
        end
        handle=sim.groupShapes(handles,false)
        sim.setObjectAlias(handle,'FloorPlan')
        sim.setObjectInt32Param(handle,sim.shapeintparam_respondable,respondable and 1 or 0)
        sim.reorientShapeBoundingBox(handle,-1)
        sim.setObjectSpecialProperty(handle,sim.objectspecialproperty_collidable|sim.objectspecialproperty_measurable|sim.objectspecialproperty_detectable_all|sim.objectspecialproperty_renderable)
        sim.setObjectSelection({handle})
        closeUi()
    end
    chooseColor=function()
        newColor=simUI.colorDialog(color)
        if newColor then
            color=newColor
            simUI.setStyleSheet(ui,800,'background-color: '..colorCSS(color))
        end
    end
    closeUi=function()
        simUI.destroy(ui)
        ui=nil
        done=true
    end
    if imageFile then
        ui=simUI.create([[<ui title="Import floorplan..." closeable="true" on-close="closeUi" resizable="true" modal="true" layout="vbox">
            <group layout="form">
                <label text="Pixel size:" />
                <spinbox id="101" float="true" minimum="0.001" maximum="10.000" step="0.001" value="0.200" decimals="6" suffix=" [m]" />

                <label text="Walls:" />
                <group layout="form">
                    <label text="Height:" />
                    <spinbox id="111" float="true" minimum="0.001" maximum="20.000" step="0.001" value="3.000" decimals="3" suffix=" [m]" />
                    <label text="Range:" />
                    <group flat="true" layout="hbox">
                        <spinbox id="201" minimum="0" maximum="255" value="0" />
                        <spinbox id="202" minimum="0" maximum="255" value="63" />
                    </group>
                </group>

                <label text="Doors:" />
                <group layout="form">
                    <label text="Height:" />
                    <spinbox id="112" float="true" minimum="0.001" maximum="20.000" step="0.001" value="2.000" decimals="3" suffix=" [m]" />
                    <label text="Range:" />
                    <group flat="true" layout="hbox">
                        <spinbox id="211" minimum="0" maximum="255" value="128" />
                        <spinbox id="212" minimum="0" maximum="255" value="191" />
                    </group>
                </group>

                <label text="Windows:" />
                <group layout="form">
                    <label text="Height:" />
                    <spinbox id="113" float="true" minimum="0.001" maximum="20.000" step="0.001" value="1.200" decimals="3" suffix=" [m]" />
                    <label text="Range:" />
                    <group flat="true" layout="hbox">
                        <spinbox id="221" minimum="0" maximum="255" value="64" />
                        <spinbox id="222" minimum="0" maximum="255" value="127" />
                    </group>
                </group>

                <label text="Color:" />
                <button on-click="chooseColor" text=" " style="background-color: ]]..colorCSS(color)..[[" id="800" />

                <label />
                <checkbox id="911" text="Respondable shape" checked="true" />

                <label />
                <checkbox id="901" text="Optimize" checked="true" />

                <label />
                <checkbox id="902" text="Invert image values" checked="false" />
            </group>
            <group flat="true" layout="hbox">
                <button id="998" text="Cancel" on-click="closeUi" />
                <button id="999" text="Import" on-click="go" />
            </group>
        </ui>]])
    else
        return {cmd='cleanup'}
    end
end

function sysCall_nonSimulation()
    if done then
        return {cmd='cleanup'}
    end
end

function sysCall_cleanup()
end
