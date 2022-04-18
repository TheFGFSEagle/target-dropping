targetDropping.targets = std.Vector.new();

var Target = {
	new: func (lat, lon, radius=100) {
		var obj = {
			parents: [Target],
			pos: geo.Coord.new().set_latlon(lat, lon, geo.elevation(lat, lon)),
			radius: radius,
		};
		
		obj.model = call(geo.put_model, [targetDropping.basePath ~ "/Models/target.ac", lat, lon]);
		
		return obj;
	},
	
	del: func {
		me.model.removeChildren();
		me.model.remove();
	}
};

var getNearestTarget = func (pos) {
	if (targetDropping.targets.size() < 1) {
		return nil;
	}
	
	var nearestDistance = pos.distance_to(targetDropping.targets.vector[0].pos);
	var nearestIndex = 0;
	forindex (var i; targetDropping.targets.vector) {
		target = targetDropping.targets.vector[i];
		distance = pos.distance_to(target.pos);
		if (distance < nearestDistance) {
			nearestDistance = distance;
			nearestIndex = i;
		}
	}
	return nearestIndex;
};

var createTargets = func (file) {
	var contents = io.read_properties(file);
	var targetCount = 0;
	foreach (var targetNode; contents.getChildren("target")) {
		var radius = targetNode.getNode("radius-ft") != nil ? targetNode.getValue("radius-ft") * FT2M : targetNode.getValue("radius-m");
		var target = Target.new(targetNode.getValue("latitude-deg"), targetNode.getValue("longitude-deg"), radius);
		targetDropping.targets.append(target);
		targetCount += 1;
	}
	
	return targetCount;
};

var removeTargets = func {
	foreach (var target; targetDropping.targets.vector) {
		target.del();
	}
	targetDropping.targets.clear();
};
