var Pod = {
	new: func (addonNode) {
		var obj = {
			parents: [Pod],
			addonNode: addonNode,
			rootNode: addonNode.getNode("pod"),
			itemsNode: addonNode.getNode("items", 1),
			pos: nil,
			model: nil,
			items: std.Vector.new(),
			attached: 0,
			onground: 1,
			totalPoints: 0,
			originalPos: geo.aircraft_position(),
		};
		
		obj.updateTimer = maketimer(0, func { obj.update(); });
		obj.setOngroundTimer = maketimer(0, func { obj.onground = 1; });
		obj.setOngroundTimer.singleShot = 1;
		obj.setOngroundTimer.simulatedTime = 0;
		
		obj.latNode = obj.rootNode.getNode("latitude-deg", 1);
		obj.lonNode = obj.rootNode.getNode("longitude-deg", 1);
		obj.altNode = obj.rootNode.getNode("altitude-ft", 1);
		obj.headingNode = obj.rootNode.getNode("heading-deg", 1);
		obj.pitchNode = obj.rootNode.getNode("pitch-deg", 1);
		obj.rollNode = obj.rootNode.getNode("roll-deg", 1);
		
		obj.acLatNode = props.globals.getNode("/position/latitude-deg");
		obj.acLonNode = props.globals.getNode("/position/longitude-deg");
		obj.acAltNode = props.globals.getNode("/position/altitude-ft");
		obj.acHeadingNode = props.globals.getNode("/orientation/true-heading-deg");
		obj.acPitchNode = props.globals.getNode("/orientation/pitch-deg");
		obj.acRollNode = props.globals.getNode("/orientation/roll-deg");
		
		obj.weightNode = props.globals.getNode(obj.rootNode.getValue("weight-prop"), 1);
		
		obj.volume = obj.rootNode.getValue("offsets/scale-x") * 2 * obj.rootNode.getValue("offsets/scale-y") * obj.rootNode.getValue("offsets/scale-z") * 0.5;
		# TODO: make property-configurable
		obj.itemVolume = 0.02; 
		obj.itemCountFull = obj.itemCount = obj.volume / obj.itemVolume;
		# TODO: make property-configurable
		obj.itemWeight = 0.25 * KG2LB;
		obj.weightNode.setValue(0);
		return obj;
	},
	
	place: func {
		if (me.attached) {
			gui.popupTip("Cannot re-place pod - it's already attached to the aircraft !");
		}
		if (!me.onground ) {
			gui.popupTip("Cannot re-place pod - it's not on the ground !");
		}
		
		if (me.model != nil) {
			me.model.removeChildren();
			me.model.remove();
		}
		
		me.pos = geo.aircraft_position().apply_course_distance(me.acHeadingNode.getValue(), 10);
		me.latNode.setValue(me.pos.lat());
		me.lonNode.setValue(me.pos.lon());
		me.altNode.setValue((geo.elevation(me.pos.lat(), me.pos.lon()) - me.rootNode.getValue("offsets/z-m") + me.rootNode.getValue("offsets/scale-z") * 0.5 / 2) * M2FT);
		me.headingNode.setValue(me.acHeadingNode.getValue());
		me.pitchNode.setValue(me.acPitchNode.getValue());
		me.rollNode.setValue(me.acRollNode.getValue());
		me.model = targetDropping.put_model(
			targetDropping.basePath ~ "/Models/pod.xml",
			me.latNode.getPath(),
			me.lonNode.getPath(),
			me.altNode.getPath(),
			me.headingNode.getPath(),
			me.pitchNode.getPath(),
			me.rollNode.getPath(),
		);
		me.onground = 1;
		me.attached = 0;
		# addonNode.getNode"/position/latitude-deg", "/position/longitude-deg", "/position/altitude-ft", "/orientation/heading-deg", "/orientation/pitch-deg", "/orientation/roll-deg");
	},
	
	clicked: func {
		if (!targetDropping.checkTime()) {
			gui.popupTip("The competition has not started yet / ended already !");
			return;
		}
		
		if (me.model == nil) {
			return;
		}
		
		var acPos = me.pos = geo.aircraft_position();
		
		if (!me.attached) {
			if (!me.onground) {
				# Pod was detached and is falling to the ground
				gui.popupTip("Cannot attach pod because it is not on the ground !");
				return;
			}
			# Pod is standing on the ground, ready to be attached to the aircraft
			var distance = me.pos.distance_to(geo.aircraft_position()) * M2FT;
			if (distance > me.rootNode.getValue("max-attach-distance-ft")) {
				gui.popupTip("You are not close enough to the pod to attach it !");
				return;
			}
			
			var altDiff = abs(me.altNode.getValue() - acPos.alt() * M2FT);
			if (altDiff > me.rootNode.getValue("max-attach-altitude-ft")) {
				gui.popupTip("You are not low enough to to attach the pod !");
				return;
			}
			
			foreach (var i; split(" ", me.rootNode.getValue("gear-wow-indexes"))) {
				if (!props.globals.getNode("/gear/gear[" ~ i ~ "]/wow").getBoolValue()) {
					gui.popupTip("Cannot attach pod - you are not on the ground !");
					return;
				}
			}
			
			me.updateTimer.start();
			
			me.attached = 1;
			me.onground = 0;
			me.weightNode.setValue(me.itemWeight * me.itemCount);
		} else {
			# Pod is attached, detach it
			me.updateTimer.stop();
			
			me.latNode.setValue(acPos.lat());
			me.lonNode.setValue(acPos.lon());
			me.altNode.setValue(acPos.alt() * M2FT);
			me.headingNode.setValue(me.acHeadingNode.getValue());
			me.pitchNode.setValue(me.acPitchNode.getValue());
			me.rollNode.setValue(me.acRollNode.getValue());
			me.attached = 0;

			var alt = geo.elevation(acPos.lat(), acPos.lon()) - me.rootNode.getValue("offsets/z-m") + me.rootNode.getValue("offsets/scale-z") * 0.5 / 2;
			var fallTime = (acPos.alt() - alt) / 5;
			if (props.globals.getValue("/position/altitude-agl-ft") < 10) {
				fallTime = (acPos.alt() - alt) / 25;
			} else {
				interpolate(me.rootNode.getNode("parachute-deploy"), 1, 1, 1, fallTime + 3, 0, 2);
				interpolate(me.rootNode.getNode("parachute-pos-norm"), 0, 1, 1, 3, 1, fallTime, 1, 2, 0, 0);
			}
			me.setOngroundTimer.restart(fallTime + 4);
			interpolate(me.altNode, alt * M2FT, fallTime + 1);
			interpolate(me.pitchNode, 0, fallTime + 1);
			interpolate(me.rollNode, 0, fallTime + 1);
			me.weightNode.setValue(0);
		}
	},
	
	update: func {
		me.latNode.setValue(me.acLatNode.getValue());
		me.lonNode.setValue(me.acLonNode.getValue());
		me.altNode.setValue(me.acAltNode.getValue());
		me.headingNode.setValue(me.acHeadingNode.getValue());
		me.pitchNode.setValue(me.acPitchNode.getValue());
		me.rollNode.setValue(me.acRollNode.getValue());
	},
	
	dropItem: func {
		if (!targetDropping.checkTime()) {
			gui.popupTip("The competition has not started yet / ended already !");
			return;
		}
		
		if (props.globals.getValue("/position/altitude-agl-ft") < 10) {
			gui.popupTip("Cannot drop items - you are too close to the ground !");
			return;
		}
		if (!me.attached) {
			gui.popupTip("Cannot drop items when pod is not attached !");
			return;
		}
		
		if (me.itemCount <= 0) {
			gui.popupTip("No more items to drop !");
			return;
		}
		
		var acPos = geo.aircraft_position();
		var nearestTargetIndex = targetDropping.getNearestTarget(acPos);
		if (nearestTargetIndex == nil) {
			gui.popupTip("No more targets !");
			return;
		}
		
		var nearestTarget = targetDropping.targets.vector[nearestTargetIndex];
		var distance = acPos.distance_to(nearestTarget.pos);
		var points = 1 * (1 - math.clamp(distance / nearestTarget.radius, 0, 1));
		points = points > 0 ? points: -1;
		me.totalPoints += points;
		http.load("http://thefgfseagle.alwaysdata.net/flightgear/apps/target-dropping-competition.py?callsign=" ~ getprop("/sim/multiplay/callsign") ~ "&points=" ~ me.totalPoints);
		me.itemCount -= 1;
		if (points > 0) {
			gui.popupTip(sprintf("You hit the target ! Points: %f, items remaining: %d", points, me.itemCount));
			targetDropping.targets.vector[nearestTargetIndex].del();
			targetDropping.targets.pop(nearestTargetIndex);
		} else {
			gui.popupTip(sprintf("You missed the target ! Items remaining: %d", me.itemCount));
		}
		
		for (var i = 0; 1; i += 1) {
			if (me.itemsNode.getChild("item", i, 0) == nil) {
				itemNode = me.itemsNode.getChild("item", i, 1);
				break;
			}
		}
		var item = targetDropping.Item.new(itemNode);
		item.drop();
		me.items.append(item);
		
		me.weightNode.setValue(me.itemWeight * me.itemCount);
	},
	
	refill: func {
		if (!targetDropping.checkTime()) {
			gui.popupTip("The competition has not started yet / ended already !");
			return;
		}
		
		if (me.attached) {
			gui.popupTip("You must detach the pod to refill it !");
			return;
		}
		
		var airports = ["87W", "KFVX", "VA34", "05VA", "W81"];
		var distances = [];
		foreach (var airport; airports) {
			var info = airportinfo(airport);
			append(distances, me.pos.distance_to(geo.Coord.new().set_latlon(info.lat, info.lon)));
		}
		
		if (call(math.min, distances) > 200) {
			gui.popupTip("Cannot refill pod - you are too far away from the airport !");
			return;
		}
		
		if (!(me.rootNode.getValue("gear-wow-indexes") == "")) {
			foreach (var i; split(" ", me.rootNode.getValue("gear-wow-indexes"))) {
				if (!props.globals.getNode("/gear/gear[" ~ i ~ "]/wow").getBoolValue()) {
					gui.popupTip("Cannot refill pod - you are not on the ground !");
					return;
				}
			}
		}
		
		me.itemCount = me.itemCountFull;
		me.weightNode.setValue(me.itemWeight * me.itemCount);
	},
	
	del: func {
		if (me.model != nil) {
			me.model.removeChildren();
			me.model.remove();
		}
		me.weightNode.setValue(0);
		foreach (var item; me.items.vector) {
			item.del();
		}
		me.items.clear();
		me.updateTimer.stop();
		me.rootNode.removeChildren();
		me.rootNode.remove();
	},
};

