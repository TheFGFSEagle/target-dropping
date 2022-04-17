var Item = {
	new: func (rootNode) {
		var obj = {
			parents: [Item],
			rootNode: rootNode,
		};
		
		obj.latNode = obj.rootNode.initNode("latitude-deg", targetDropping.pod.latNode.getValue());
		obj.lonNode = obj.rootNode.initNode("longitude-deg", targetDropping.pod.lonNode.getValue());
		obj.altNode = obj.rootNode.initNode("altitude-ft", targetDropping.pod.altNode.getValue());
		obj.headingNode = obj.rootNode.initNode("heading-deg", targetDropping.pod.headingNode.getValue());
		obj.pitchNode = obj.rootNode.initNode("pitch-deg", 0);
		obj.rollNode = obj.rootNode.initNode("roll-deg", 0);
		
		obj.removeTimer = maketimer(0, func { obj.del(); });
		obj.removeTimer.singleShot = 1;
		obj.removeTimer.simulatedTime = 0;
		
		obj.model = targetDropping.put_model(targetDropping.basePath ~ "/Models/item.xml", obj.latNode.getPath(), obj.lonNode.getPath(), obj.altNode.getPath(), obj.headingNode.getPath(), obj.pitchNode.getPath(), obj.rollNode.getPath());
		return obj;
	},
	
	drop: func {
		var alt = geo.elevation(me.latNode.getValue(), me.lonNode.getValue()) * M2FT;
		var fallTime = (me.altNode.getValue() - alt) * FT2M / 5;
		
		me.removeTimer.restart(fallTime);
		interpolate(me.altNode, alt, fallTime);
		interpolate(me.pitchNode, 0, fallTime);
		interpolate(me.rollNode, 0, fallTime)
	},
	
	del: func {
		me.model.removeChildren();
		me.model.remove();
		me.removeTimer.stop();
	}
};
