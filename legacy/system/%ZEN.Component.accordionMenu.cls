/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements a simple HTML5 accordion menu component.<br/>
/// This is an HTML5 component; it will only correctly run on HTML5 compliant browsers.
Class %ZEN.Component.accordionMenu Extends (component, dataView) [ Deprecated, System = 3 ]
{

/// Do not include in "form" module.
Parameter SYSMODULE;

Parameter DEFAULTENCLOSINGCLASS = "zam-menu";

/// onselect event handler:
/// If defined, this event is fired when
/// the user clicks on a item within the menu.
Property onselect As %ZEN.Datatype.eventHandler;

/// ongetdata event handler:
/// If defined, this event is returns an array of items to be displayed within the menu.
Property ongetdata As %ZEN.Datatype.eventHandler;

/// Additional style to apply to items in the menu.<br/>
Property style As %ZEN.Datatype.style;

/// Current selected item.<br/>
/// This is a string of the form 'index1,index2,...', where each index is the 0-based
/// ordinal position of a menu, its first level child, etc.
Property selectedIndex As %ZEN.Datatype.string;

/// defines style sheet used by this component.
XData Style
{
<style type="text/css">

.zam-menu {
	border: 1px solid #404040;
	overflow: hidden;
	overflow-y: auto;
}

.zam-menuItem,
.zam-menuItemSelected {
	margin: 0px;
	padding: 0px;
	min-width: 150px;
	height: auto;
	-moz-user-select: -moz-none;
	-khtml-user-select: none;
	-webkit-user-select: none;
	user-select: none;
}

.zam-menuItemInner {
	padding: 0px;
	width: 100%;
	text-shadow: 0px 1px 0px rgba(255,255,255,0.35);
}

.zam-caption-1,
.zam-caption-2,
.zam-caption-3 {
	display: block;
	width: 100%;
	color: #fdfdfd;
	padding: 4px;
	text-decoration: none;
	text-shadow: 0px 1px 0px rgba(0,0,0,0.35);
    background: #6c6e74;
	background: -moz-linear-gradient(top,  #6c6e74 0%, #4b4d51 100%);
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#6c6e74), color-stop(100%,#4b4d51));
	background: -webkit-linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	background: -o-linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	background: -ms-linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	background: linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	-webkit-box-shadow: inset 0px 1px 0px 0px rgba(255,255,255, .1), 0px 1px 0px 0px rgba(0,0,0, .1);
	-moz-box-shadow: inset 0px 1px 0px 0px rgba(255,255,255, .1), 0px 1px 0px 0px rgba(0,0,0, .1);
	box-shadow: inset 0px 1px 0px 0px rgba(255,255,255, .1), 0px 1px 0px 0px rgba(0,0,0, .1);

	opacity: 0.8;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.zam-caption-1 {
	border-top: 1px solid #404040;
	border-bottom: 1px solid #404040;
	font-size: 16px;
	font-weight: bold;
}
.zam-caption-2 {
	border-top: 1px solid #404040;
	border-bottom: 1px solid #404040;
	font-size: 13px;
	font-weight: bold;
	padding-left: 10px;
}
.zam-caption-3 {
	border-top: 1px solid #404040;
	border-bottom: 1px solid #404040;
	font-size: 13px;
	font-weight: bold;
	font-style: italic;
	padding-left: 20px;
}

.zam-caption-1:hover,
.zam-caption-2:hover,
.zam-caption-3:hover {
	opacity: 1.0;
	color: white;
}

.zam-caption-1:active,
.zam-caption-2:active,
.zam-caption-3:active {
	text-shadow: -1px 1px 8px #FFFFCC, 1px -1px 8px #FFFFFF;
}

.zam-menuChildren {
	overflow: hidden;
	-webkit-transition-property: height,opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: height,opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
}

</style>
}

/// Client-side method to render this component.
ClientMethod renderContents() [ Language = javascript ]
{
	try {
		var model = this.getModel();

		var encDiv = this.getEnclosingDiv();
		// test if we have not been rendered yet
		if (encDiv == null) return;

		// get meta data
		if (model) {
			var menuId = this.id=='' ? this.index : this.id;
			encDiv.innerHTML = this.getMenuHTML(model,menuId);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in renderContents.');
	}
}

/// Get the model used to drive the menu.
ClientMethod getModel() [ Language = javascript ]
{
	// See if there is user-supplied data to drive the control
	var model = null;
	if (this.ongetdata!='') {
		model = zenInvokeCallbackMethod(this.ongetdata,this,'ongetdata');
	}
	else {
		// if not see if there is a data controller
		var controller = this.getController();
		if (null == controller) {
			// try to connect to dataController
			this.connectToController();
			controller = this.getController();
		}
		if (controller) {
			if (controller.getContentObject) {
				// json provider-- use object directly
				model = controller.getContentObject();
			}
			else {
				// build model from controller data!!!
			}
		}
	}
	return model;
}

/// Get HTML for a dynamic menu based on the given content object graph.
/// Each node in the graph may define <var>key</var>, <var>caption</var>,<var>action</var>,
/// <var>targetId</var>, <var>image</var>, and <var>children</var>.
ClientMethod getMenuHTML(content, menuId) [ Language = javascript ]
{
	var html = [];

	// context info to be passed along
	var menuInfo = {menuId:menuId, itemId:0};

	// hidden div used for size testing
	html[html.length] = '<div style="height:0px;overflow:hidden;">';
	html[html.length] = '<div id="'+menuId+'_menuSizing">';
	html[html.length] = '</div>';
	html[html.length] = '</div>';

	if (content && content.children && content.children.length) {
		html[html.length] = this.getMenuHTMLForArray(menuInfo,content.children,1,'');
	}
	return html.join('');
}

/// Get HTML for one array of menu content.
ClientMethod getMenuHTMLForArray(menuInfo, array, level, parentId) [ Internal, Language = javascript ]
{
	if (level>3) {
		alert('Menus cannot have more than 3 levels');
		return '';
	}

	var html = [];
	for (var n = 0; n < array.length; n++) {
		var info = array[n];
		// itemId is "idx,idx,idx"
		var itemId = (parentId===''?'':parentId+',') + n;
		var id = menuInfo.menuId + ':' + itemId;
		var image = zenGet(info.image);
		var style = zenGet(info.style);
		var imageStyle = 'width:32px;' + zenGet(info.imageStyle);
		var cls = (itemId==this.selectedIndex) ? 'zam-menuItemSelected' : 'zam-menuItem';
		html[html.length] = '<div class="'+cls+'" id="menu_'+id+'">';
		html[html.length] = '<div class="zam-menuItemInner" id="inner_'+id+'" style="'+style+'">';
		html[html.length] = '<a class="zam-caption-'+level+'" id="caption_'+id+'" onclick="zenPage.getComponent('+this.index+').menuClickHandler(event,\''+id+'\',\''+zenGet(info.key)+'\',\''+zenGet(info.action)+'\',\''+zenGet(info.targetId)+'\');">';
		if (image!='') {
			html[html.length] = '<image src="'+image+'" style="'+imageStyle+'"/>&nbsp;';
		}
		html[html.length] = zenGet(info.caption);
		html[html.length] = '</a>'
		html[html.length] = '</div>';

		if (info.children && info.children.length) {
			var hgt = ((itemId==this.selectedIndex.split(',')[level-1])||level>1) ? 'auto' : '0px';
			var opa = ((itemId==this.selectedIndex.split(',')[level-1])||level>1) ? '1.0' : '0.0';
			html[html.length] = '<div class="zam-menuChildren" id="children_'+id+'" style="height:'+hgt+';opacity:'+opa+';">';
			html[html.length] = this.getMenuHTMLForArray(menuInfo,info.children,level+1,itemId);
			html[html.length] = '</div>';
		}
		html[html.length] = '</div>';
	}
	return html.join('');
}

/// User click on a menu item.
ClientMethod menuClickHandler(evt, id, key, action, targetId) [ Language = javascript ]
{
	if (evt.stopPropagation) {
		evt.stopPropagation();
	}

	// split id apart
	var t = id.toString().split(':');
	var menuId = t[0];
	var itemId = t[1];	// csv list of #s
	var level = itemId.toString().split(',');
	this.selectItem(itemId);
	
	// invoke action handler
	this.menuActionHandler(id,key,action,targetId);
}

/// Adjust the size of a menu item's parents.
ClientMethod adjustParentMenuSize(menuId, level, id) [ Language = javascript ]
{
	var sizingDiv = self.document.getElementById(menuId + '_menuSizing');

	var t2 = id.toString().split(',');
	while (t2.length>1) {
		t2.length--;
		var parentId = menuId+':'+t2.join(',');
		var parentDiv = self.document.getElementById('children_'+parentId);
		if (parentDiv) {
			sizingDiv.innerHTML = parentDiv.innerHTML;
			parentDiv.style.height = sizingDiv.offsetHeight + 'px';
		}
	}
}

/// Action handler for menu item.
ClientMethod menuActionHandler(itemId, key, action, targetId) [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.onselect,this,'onselect','key',key,'action',action,'targetId',targetId);
}

/// Notification that the dataController associated with this grid
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
		this.render();
		break;
	case 'seriesChange':
		break;
	case 'modelChange':
		this.render();
		break;
	}
}

/// Select a given menu item and expand it (if it has children).
/// <var>index</var> is the index number of the menu item (0-based).
ClientMethod selectItem(index) [ Language = javascript ]
{
	var menuId = this.id=='' ? this.index : this.id;
	var itemId = index;	// csv list of #s
	var level = itemId.toString().split(',');
	var id = menuId + ':' + itemId;

	// unselect current selected item
	if (this.selectedIndex) {
		var selDiv = self.document.getElementById('menu_'+menuId+':'+this.selectedIndex);
		if (selDiv) {
			selDiv.className = 'zam-menuItem';
		}
	}

	this.selectedIndex = itemId;
	
	// select new item
	if (this.selectedIndex) {
		var selDiv = self.document.getElementById('menu_'+menuId+':'+this.selectedIndex);
		if (selDiv) {
			selDiv.className = 'zam-menuItemSelected';
		}
	}

	var childDiv = self.document.getElementById('children_'+id);
	if (childDiv) {
		var sizingDiv = self.document.getElementById(menuId + '_menuSizing');

		// if we have parents, change them to 'auto' height
		var func = new Function('zenPage.getComponent('+this.index+').adjustParentMenuSize(\''+menuId+'\','+level+',\''+itemId+'\');');
		window.setTimeout(func,500);	// !!!!! (use transition notification)
		if (childDiv.offsetHeight) {
			// hide this menu
			// childDiv.style.height = childDiv.offsetHeight + 'px';
			childDiv.style.height = '0px';
			childDiv.style.opacity = 0.0;
		}
		else {
			// disclose this menu
			// set height to pixel to force transition
			sizingDiv.innerHTML = childDiv.innerHTML;
			childDiv.style.height = sizingDiv.offsetHeight + 'px';
			childDiv.style.opacity = 1.0;
		}
	}

	if (level < 2) {
		// hide all other items at this level
		var t2 = itemId.toString().split(',');
		var thisId = t2[t2.length-1];
		t2.length--;
		var baseId = t2.join(',');
		for (var ix = 0;;ix++) {
			if (ix!=thisId) {
				var testId = menuId+':'+(baseId===''?'':baseId+',') + ix;
				var iDiv = self.document.getElementById('menu_'+testId);
				if (!iDiv) {
					break;
				}
				var iChildDiv = self.document.getElementById('children_'+testId);
				if (iChildDiv) {
					iChildDiv.style.height = '0px';
				}
			}
		}
	}
}

}
