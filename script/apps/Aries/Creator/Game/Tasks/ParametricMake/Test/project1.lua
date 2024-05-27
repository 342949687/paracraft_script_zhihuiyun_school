project("Gear", {
    icon = "",
    label = "",
    desc = "",
})

include("./Preset.lua");
defineBounds("TEETH_BOUNDS",{
    unitless =  { 4, 25, 1000 }
})
defineBounds("POSITIVE_REAL_BOUNDS",{
    unitless =  { 0, 1, 1e5 }
})


defineEnum("GearInputType",{
    { label = "Module", key = "module", value = "module", },
    { label = "Diametral pitch", key = "diametralPitch", value = "diametralPitch", },
    { label = "Circular pitch", key = "circularPitch", value = "circularPitch", },
})

addProperty({
    label = "Number of teeth", 
    name = "numTeeth",
    type = "number",
    value = 4,
    bounds = "TEETH_BOUNDS"
})

addProperty({
    label = "Number of teeth 2", 
    name = "numTeeth2",
    type = "number",
    value = 10,
    bounds = "TEETH_BOUNDS"
})

addProperty({
    label = "Input type", 
    name = "GearInputType",
    type = "GearInputType",
    value = getEnumValue("GearInputType.module"),
})
if(self.props.GearInputType and (self.props.GearInputType ==  getEnumValue("GearInputType.module")))then
    addProperty({
        label = "Module", 
        name = "module",
        type = "number",
        bounds = "POSITIVE_REAL_BOUNDS" ,
		dynamic = true ,
    })
end
if(self.props.GearInputType and (self.props.GearInputType ==  getEnumValue("GearInputType.diametralPitch")))then
    addProperty({
        label = "Diametral pitch", 
        name = "diametralPitch",
        type = "number",
        bounds = "POSITIVE_REAL_BOUNDS" ,
		dynamic = true,
    })
end

setAction(function()
    local numTeeth = self.props.numTeeth;
    local GearInputType = self.props.GearInputType;
    local diametralPitch = self.props.diametralPitch;
	commonlib.echo("===============v");
	commonlib.echo({ numTeeth, GearInputType, diametralPitch, });
end)




