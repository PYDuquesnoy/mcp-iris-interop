/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized SVG component that displays the relationship
/// between a set of data items as a radial diagram.<br>
/// The data is displayed as a central circular hub surrounded by a set 
/// of evenly spaced nodes. The number and contents of the nodes is specified
/// by an array of <class>%ZEN.Auxiliary.radialNode</class> objects.
Class %ZEN.SVGComponent.radialNavigator Extends svgComponent [ Deprecated, System = 3 ]
{

/// Default viewBoxWidth of this component.
/// This is set to 100 to provide a fixed coordinate system.
Parameter DEFAULTVIEWBOXWIDTH As INTEGER = 100;

/// Default viewBoxHeight of this component.
/// This is set to 100 to provide a fixed coordinate system.
Parameter DEFAULTVIEWBOXHEIGHT As INTEGER = 100;

/// List of node information objects.
/// Each object specifies details about a node displayed by the Navigator.
Property nodes As list Of %ZEN.Auxiliary.radialNode(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE");

/// Title displayed by navigator.
Property title As %ZEN.Datatype.caption;

/// Label for central hub.
Property mainLabel As %ZEN.Datatype.caption;

/// Optional: style used for background panel.
Property backgroundStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for title text.
Property titleStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for main hub label text.
Property mainLabelStyle As %ZEN.Datatype.svgStyle;

/// Optional: style applied to central hub.
Property hubStyle As %ZEN.Datatype.svgStyle;

/// Optional: style applied to nodes.
Property nodeStyle As %ZEN.Datatype.svgStyle;

/// Optional: if true, then scale the size of the outer nodes proportionally to their value.
Property scaleNodes As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Index (0-based) of selected node.
/// -1 means that the central node is selected.
/// -2 means that no node is selected.
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -2 ];

/// onselectNode event handler:
/// This event is fired when the mouse is clicked on a Node.<br>
/// When this event is invoked, the <property>selectedIndex</property>
/// will contain the index (0-based) of the current node. If the user clicks on the central node then
/// <property>selectedIndex</property> will be -1;
Property onselectNode As %ZEN.Datatype.eventHandler;

XData SVGStyle
{
<style type="text/css">

.rnavBackground {
	fill: #CCDDFF;
	stroke: gray;
	stroke-width: 0.5px;
}

/* line from title to main node */
.rnavTitleConnector {
	fill: none;
	stroke: gray;
	stroke-width: 0.5px;
	stroke-dasharray: 0.4,0.4;
}

/* main title */
.rnavTitle {
	fill: #404040;
	stroke: none;
	font-size: 4pt;
	font-weight: bold;
}

/* label for node */
.rnavLabel {
	fill: #404040;
	fill-opacity: 0.8;
	stroke: none;
	font-size: 2.5pt;
}

.rnavLabelHilight {
	fill: red;
	stroke: none;
	font-size: 3pt;
	font-weight: bold;
}

.rnavConnector {
	fill: none;
	stroke: #404040;
	stroke-width: 0.25px;
}

.rnavHub {
	stroke: #404040;
	stroke-width: 0.25px;
	fill: green;
}

.rnavHubHilight {
	stroke: #404040;
	stroke-width: 1px;
	fill: red;
}

.rnavHubSelected {
	stroke: blue;
	stroke-width: 1px;
	fill: yellow;
}

.rnavNode {
	stroke: #404040;
	stroke-width: 0.25px;
	fill: blue;
}

.rnavNodeHilight {
	stroke: black;
	stroke-width: 0.8px;
	fill: red;
}

.rnavNodeSelected {
	stroke: blue;
	stroke-width: 0.8px;
	fill: yellow;
}

</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	if (this.svgGroup) {
		// remove old SVG
		this.unrender();

		// draw contents of Navigator
		var nodeCount = this.nodes.length;
		var wid = 100;
		var hgt = 100;
		// radius of outer ring
		this._ringRadius = 25;

		// in some cases, slide over line from label to center
		var adj = (nodeCount!=0 && nodeCount <20 && nodeCount%4==0) ? 15 : 0;	

		var rect = this.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('class','rnavBackground');
		rect.setAttribute('x',0);
		rect.setAttribute('y',0);
		rect.setAttribute('width',wid);
		rect.setAttribute('height',hgt);
		rect.setAttribute('style',this.backgroundStyle);
		this.svgGroup.appendChild(rect);

		if ('' != this.mainLabel) {
			// connector to main label
			var line = this.document.createElementNS(SVGNS,'line');
			line.setAttribute('class','rnavTitleConnector');
			line.setAttribute('x1',wid/2);
			line.setAttribute('y1',hgt/2);
			line.setAttribute('x2',wid/2-adj);
			line.setAttribute('y2',9);
			this.svgGroup.appendChild(line);
	
			// main label
			var text = this.document.createElementNS(SVGNS,'text');
			text.setAttribute('class','rnavTitle');
			text.setAttribute('x',wid/2-adj);
			text.setAttribute('y',7);
			text.setAttribute('style',this.mainLabelStyle);
			text.setAttribute('text-anchor','middle');
	
			var textNode = this.document.createTextNode(this.mainLabel);
			text.appendChild(textNode);

			this.svgGroup.appendChild(text);
		}

		// set up group for coord space
		var group = this.document.createElementNS(SVGNS,'g');
		group.setAttribute('transform','translate('+(wid/2)+','+(hgt/2)+')');
		this.svgGroup.appendChild(group);

		// draw nodes
		// first, draw connectors
		if (nodeCount > 0) {
			for (var n = 0; n < nodeCount; n++) {
				var angle = (n-1) * ((Math.PI*2)/nodeCount);
				this.drawConnector(group, angle);
			}
		}

		// find max of values
		var max = 0;
		if (this.scaleNodes && nodeCount > 0) {
			for (var n = 0; n < nodeCount; n++) {
				var node = this.nodes[n];
				var v = parseFloat(node.value);
				if (!isNaN(v) && v > max) {
					max = v;
				}
			}
		}

		// main node
		if ('' != this.title || nodeCount > 0) {
			this.drawNode(group,"main");
		}

		// draw nodes
		if (nodeCount > 0) {
			// compute max node size based on ring radius
			var circ = this._ringRadius * 2 * Math.PI;
			var nodeSize = (circ/(nodeCount*2))*0.9;
			nodeSize = (nodeSize>2.5) ? 2.5 : nodeSize;

			for (var n = 0; n < nodeCount; n++) {
				var node = this.nodes[n];
				var angle = (n-1) * ((Math.PI*2)/nodeCount);
				var size = nodeSize;
				if (node.value && max>0) {
					size = Math.sqrt(nodeSize*nodeSize*(node.value/max));
				}
				this.drawNode(group, "node", angle, node, n, size);
			}
		}
	}
}

/// Draw a connector.
ClientMethod drawConnector(group, angle) [ Language = javascript ]
{
	if (this.svgGroup) {
		var radius = this._ringRadius;
		var x = Math.cos(angle) * radius;
		var y = Math.sin(angle) * radius;

		var line = this.document.createElementNS(SVGNS,'line');
		line.setAttribute('class','rnavConnector');
		line.setAttribute('x1',0);
		line.setAttribute('y1',0);
		line.setAttribute('x2',x);
		line.setAttribute('y2',y);
		group.appendChild(line);
	}
}

/// Draw a node.
ClientMethod drawNode(group, type, angle, node, num, size) [ Language = javascript ]
{
	if (this.svgGroup) {

		var x,y,size;
		var radius = this._ringRadius;
		var cls,id,style;

		switch (type) {
		case 'main':
			x = 0;
			y = 0;
			size = 5;
			cls = (-1 == this.selectedIndex) ? 'rnavHubSelected' : 'rnavHub';
			style = this.hubStyle;
			id = this.makeId("main");
			num = -1;
			break;
		default:
			x = Math.cos(angle) * radius;
			y = Math.sin(angle) * radius;
			cls = (num == this.selectedIndex) ? 'rnavNodeSelected' : 'rnavNode';
			style = this.nodeStyle;
			id = this.makeId("node_"+num);
			lblid = this.makeId("label_"+num);
			break;
		}
		
		var item = this.document.createElementNS(SVGNS,'circle');
		item.setAttribute('class',cls);
		item.setAttribute('id',id);
		item.setAttribute('r',size);
		item.setAttribute('cx',x);
		item.setAttribute('cy',y);
		if (node) {
			item.setAttribute('style',style + node.style);
		}
		else {
			item.setAttribute('style',style);
		}

		item.addEventListener('click',new Function('evt','return zenPage.getComponent('+this.index+').nodeClickHandler(evt,"'+type+'",'+num+');'),false);
		item.addEventListener('mouseover',new Function('evt','return zenPage.getComponent('+this.index+').nodeMouseHandler(evt,"over",'+num+');'),false);
		item.addEventListener('mouseout',new Function('evt','return zenPage.getComponent('+this.index+').nodeMouseHandler(evt,"out",'+num+');'),false);
		group.appendChild(item);

		if ((type != "main") && (node.label != "")) {
			var tx = Math.cos(angle) * (radius+5);
			var ty = Math.sin(angle) * (radius+5);
			
			var anchor = ((tx<2)&&(tx>-2)) ? "middle" : ((tx>0) ? "start" :"end");
			var yadj = (ty>=0) ? 2 : -1;
			
			var text = this.document.createElementNS(SVGNS,'text');
			text.setAttribute('class','rnavLabel');			
			text.setAttribute('id',lblid);
			text.setAttribute('x',tx);
			text.setAttribute('y',ty + yadj);
			text.setAttribute('text-anchor',anchor);
			var textNode = this.document.createTextNode(node.caption);
			text.appendChild(textNode);
			group.appendChild(text);
		}
	}
}

/// Select the specified node.
ClientMethod selectNode(index) [ Language = javascript ]
{
	// unhighlight old node
	var el = null;

	switch (this.selectedIndex) {
	case -2:
		break;
	case -1:
		var el = this.findSVGElement('main');
		break;
	default:
		var el = this.findSVGElement('node_' + this.selectedIndex);
		break;
	}
	
	if (el) {
		el.setAttribute('class','rnavNode');
	}

	// highlight new node
	var el = null;
	this.selectedIndex = index;

	switch (this.selectedIndex) {
	case -2:
		break;
	case -1:
		var el = this.findSVGElement('main');
		if (el) {
			el.setAttribute('class','rnavHubSelected');
		}
		break;
	default:
		var el = this.findSVGElement('node_' + this.selectedIndex);
		if (el) {
			el.setAttribute('class','rnavNodeSelected');
		}
		break;
	}
}

/// Highlight/unhighlight node (called by mouseover, mouseout events).
ClientMethod nodeMouseHandler(evt, flag, nodeIndex) [ Language = javascript ]
{
	// find node
	var node = this.getNode(nodeIndex);
	if (null == node) {
		// central node
		evt.target.setAttribute("class",flag=="over" ? 'rnavHubHilight' : (this.selectedIndex==-1 ? 'rnavHubSelected' : 'rnavHub'));
	}
	else {
		var el = this.findSVGElement('node_' + nodeIndex);
		var label = this.findSVGElement('label_' + nodeIndex);
		if (el) {	
			el.setAttribute("class",flag=="over" ? 'rnavNodeHilight' : (this.selectedIndex==nodeIndex) ? 'rnavNodeSelected' : 'rnavNode');
		}
		if (label) {
			label.setAttribute("class",flag=="over" ? 'rnavLabelHilight' : 'rnavLabel');
		}
	}
}

/// Onclick handler for nodes.
ClientMethod nodeClickHandler(evt, type, nodeIndex) [ Language = javascript ]
{
	evt.stopPropagation();
	
	if (type == 'main') { nodeIndex = -1 }
	this.selectNode(nodeIndex);

	zenInvokeCallbackMethod(this.onselectNode,this,'onselectNode');
}

/// Remove the set of nodes associated with this Navigator.
ClientMethod clearNodes() [ Language = javascript ]
{
	this.selectedIndex = -2;
	this.nodes.length = 0;
	this.render();
}

/// Return the current selected node object associated with this Navigator.
ClientMethod getCurrNode() [ Language = javascript ]
{
	return this.getNode(this.selectedIndex);
}

/// Return a node object associated with this Navigator given its index
/// number (0-based).
ClientMethod getNode(index) [ Language = javascript ]
{
	if (index >= 0 && index < this.nodes.length) {
		return this.nodes[index];
	}
	return null;
}

/// Remove a node from this navigator.<br>
/// <var>index</var> is the index number (0-based) of the node.<br>
ClientMethod removeNode(index) [ Language = javascript ]
{
	this.nodes.splice(index,1);
	this.render();
}

/// Append a new node object to this navigator.<br>
/// The node object should be created by calling:
/// <example language="javascript">
/// node = zenPage.createComponent('radialNode');
/// </example>
ClientMethod appendNode(node) [ Language = javascript ]
{
	this.nodes[this.nodes.length] = node;
	this.render();
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'backgroundStyle':
	case 'titleStyle':
	case 'title':
	case 'mainLabelStyle':
	case 'mainLabel':
	case 'hubStyle':
	case 'nodeStyle':
	case 'scaleNodes':
		this[property] = value;
		this.render();
		break;
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
