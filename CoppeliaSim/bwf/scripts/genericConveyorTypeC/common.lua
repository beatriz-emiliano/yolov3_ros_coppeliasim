-- Functions:
-------------------------------------------------------
function model.completeDataConveyorSpecific(data)
    if not data.conveyorSpecific then
        data.conveyorSpecific={}
    end
    if not data.conveyorSpecific.padHeight then
        data.conveyorSpecific.padHeight=0.04
    end
    if not data.conveyorSpecific.padSpacing then
        data.conveyorSpecific.padSpacing=0.2
    end
    if not data.conveyorSpecific.padThickness then
        data.conveyorSpecific.padThickness=0.01
    end
    if not data.conveyorSpecific.wallThickness then
        data.conveyorSpecific.wallThickness=0.005
    end
    if not data.conveyorSpecific.bitCoded then
        data.conveyorSpecific.bitCoded=1+2+4+8 -- 1=leftOpen, 2=rightOpen, 4=frontOpen, 8=backOpen, 16=roundEnds, 32=textured
    end
end

-- Additional handles:
-------------------------------------------------------
model.specHandles={}

model.specHandles.backSide=sim.getObject('./genericConveyorTypeC_backSide')
model.specHandles.frontSide=sim.getObject('./genericConveyorTypeC_frontSide')
model.specHandles.leftSide=sim.getObject('./genericConveyorTypeC_leftSide')
model.specHandles.rightSide=sim.getObject('./genericConveyorTypeC_rightSide')
model.specHandles.base=sim.getObject('./genericConveyorTypeC_base')
model.specHandles.baseBack=sim.getObject('./genericConveyorTypeC_baseBack')
model.specHandles.baseFront=sim.getObject('./genericConveyorTypeC_baseFront')
model.specHandles.padBase=sim.getObject('./genericConveyorTypeC_padBase')
model.specHandles.pad=sim.getObject('./genericConveyorTypeC_pad')
model.specHandles.path=sim.getObject('./genericConveyorTypeC_path')
