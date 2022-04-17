var put_model = func (path, latProp, lonProp, elevProp, headingProp, pitchProp, rollProp) {
	var n = props.globals.getNode("/models", 1);
	for (var i = 0; 1; i += 1) {
		if (n.getChild("model", i, 0) == nil) {
			break;
		}
	}
	
	m = n.getChild("model", i, 1);
	m.getNode("path", 1).setValue(path);
	m.getNode("latitude-deg-prop", 1).setValue(latProp);
	m.getNode("longitude-deg-prop", 1).setValue(lonProp);
	m.getNode("elevation-ft-prop", 1).setValue(elevProp);
	m.getNode("heading-deg-prop", 1).setValue(headingProp);
	m.getNode("pitch-deg-prop", 1).setValue(pitchProp);
	m.getNode("roll-deg-prop", 1).setValue(rollProp);
	m.getNode("load", 1).remove();
	
	return m;
}

