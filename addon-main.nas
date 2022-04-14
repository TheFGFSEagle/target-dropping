var namespace = "targetDropping";

var main = func(addon) {
	logprint(LOG_ALERT, "Target-dropping addon initialized from ", addon.basePath);
	
	# initialization
	setlistener("/sim/signals/fdm-initialized", func {
		foreach(var script; ['cargooperations.nas', 'longlineanimation-uc.nas', 'js.nas']) {
			var fname = addon.basePath ~ "/" ~ script;
			logprint("info", "Load ", fname, " module");
			#io.load_nasal(fname, "CGTOW");
		}
	}, 0, 1);
	
	setlistener("/sim/signals/click", func {
		if (__kbd.shift.getBoolValue()) {
			var click_pos = geo.click_position();
			if (__kbd.ctrl.getBoolValue()) {
				return;
			} else {
				var pos_lat = click_pos.lat();
				var pos_lon = click_pos.lon();
				var click_alt = geo.elevation(click_pos.lat(), click_pos.lon());
				print(pos_lat, " ", pos_lon, " ", click_alt);
			}
		}
	}, 0, 1);
}

var unload = func(addon) {
	logprint(LOG_ALERT, "Unloading target-dropping addon");
	delete(globals, namespace);
}
