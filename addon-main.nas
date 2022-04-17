var main = func(addon) {
	logprint(LOG_INFO, "Target-dropping addon initialized from ", addon.basePath);
	
	http.load("http://thefgfseagle.alwaysdata.net/flightgear/apps/target-dropping-competition.py?reset&callsign=" ~ getprop("/sim/multiplay/callsign"));
	
	globals["targetDropping"] = {};
	
	targetDropping.basePath = addon.basePath;
	targetDropping.resourcePath = addon.resourcePath;
	targetDropping.addonNode = addon.node.getNode("addon-devel");
	
	io.load_nasal(addon.basePath ~ "/Nasal/utils.nas", "targetDropping");
	io.load_nasal(addon.basePath ~ "/Nasal/pod.nas", "targetDropping");
	io.load_nasal(addon.basePath ~ "/Nasal/targets.nas", "targetDropping");
	io.load_nasal(addon.basePath ~ "/Nasal/item.nas", "targetDropping");
	
	var model = split(".xml", split("/", getprop("/sim/model/path"))[-1])[0];
	if (model == "") {
		logprint(LOG_WARN, "Target dropping: Your aircraft is not supported ! Falling back to Cessna P210N data.");
	}
	targetDropping.aircraft = model != "" ? model : "p210n";
	
	io.read_properties(addon.basePath ~ "/data/pod-config/" ~ targetDropping.aircraft, targetDropping.addonNode);
	
	targetDropping.pod = targetDropping.Pod.new(targetDropping.addonNode);
	targetDropping.pod.place();
	
	targetDropping.createTargets(addon.basePath ~ "/data/targets.xml");
	
#	setlistener("/sim/signals/click", func {
#		if (__kbd.shift.getBoolValue()) {
#			var click_pos = geo.click_position();
#			if (__kbd.ctrl.getBoolValue()) {
#				return;
#			} else {
#				var pos_lat = click_pos.lat();
#				var pos_lon = click_pos.lon();
#				var click_alt = geo.elevation(click_pos.lat(), click_pos.lon());
#				print(pos_lat, " ", pos_lon, " ", click_alt);
#			}
#		}
#	}, 0, 1);
}

var unload = func(addon) {
	logprint(LOG_DEBUG, "Unloading target-dropping addon");
	
	call(targetDropping.removeTargets, nil, targetDropping);
	call(targetDropping.pod.del, nil, targetDropping.pod);
	
	delete(globals, "targetDropping");
}
