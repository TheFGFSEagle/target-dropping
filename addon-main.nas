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
	
	io.read_properties(addon.basePath ~ "/data/pod-config/" ~ getprop("/sim/aircraft"), targetDropping.addonNode);
	
	targetDropping.checkTime = func {
		hours = getprop("/sim/time/real/hour");
		#if (hours < 20 or hours > 21) {
		#	return 0;
		#}
		return 1;
	};
	
	targetDropping.pod = targetDropping.Pod.new(targetDropping.addonNode);
	targetDropping.pod.place();
	
	var sceneryLoadedNode = props.globals.getNode("/sim/sceneryloaded");
	
	targetDropping.createTargetsTimer = maketimer(15, func {
		targetDropping.removeTargets();
		targetDropping.createTargets(addon.basePath ~ "/data/targets.xml");
	});
	targetDropping.createTargetsTimer.singleShot = 1;
	targetDropping.createTargetsTimer.simulatedTime = 0;
	
	if (sceneryLoadedNode.getBoolValue()) {
		targetDropping.createTargetsTimer.start();
	} 
	setlistener(sceneryLoadedNode, func {
		if (sceneryLoadedNode.getBoolValue() and !targetDropping.createTargetsTimer.isRunning) {
			targetDropping.createTargetsTimer.start();
		} 
	});
	
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
	
	targetDropping.createTargetsTimer.stop();
	
	call(targetDropping.removeTargets, nil, targetDropping);
	call(targetDropping.pod.del, nil, targetDropping.pod);
	
	delete(globals, "targetDropping");
}
