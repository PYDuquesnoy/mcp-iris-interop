/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized type of group that can be placed within a desktop group.
/// A drag group displays a header (which can include various buttons).
/// The user can drag the group around within its containing desktop group.
Class %ZEN.Component.dragGroup Extends group [ Deprecated, LegacyInstanceContext, System = 3 ]
{

/// Subclasses can set this to change default layout for a group.
Parameter DEFAULTLAYOUT As STRING = "none";

/// Subclasses can set this to change default css class for a group.
Parameter DEFAULTENCLOSINGCLASS = "dragGroup";

/// Default image for close group button.
Parameter DEFAULTCLOSEIMAGE = "images/grayDragClose.png";

/// Default image for maximize group button.
Parameter DEFAULTMAXIMAGE = "images/grayDragMax.png";

/// Default image for minimize group button.
Parameter DEFAULTMINIMAGE = "images/grayDragMin.png";

/// Default image for contract group button.
Parameter DEFAULTCONTRACTIMAGE = "images/grayDragContract.png";

/// Default image for expand group button.
Parameter DEFAULTEXPANDIMAGE = "images/grayDragExpand.png";

/// Default image for maximize group button.
Parameter DEFAULTRESIZEIMAGE = "images/grayDragResize.png";

/// Default resize icon size in pixels
Parameter DEFAULTRESIZEICONSIZE = 16;

/// Default header layout pattern
Parameter DEFAULTHEADERLAYOUT = "ITFC";

/// onresize event handler:
/// This event is fired when this drag group is resized.
Property onresize As %ZEN.Datatype.eventHandler;

/// onclosepending event handler:
/// This event is fired when the close button of this drag group is pressed.
/// Unlike native browser windows, it is possible to prevent the window
/// closure by calling abortClose() in response to this event.
Property onclosepending As %ZEN.Datatype.eventHandler;

/// onwindowgrab event handler:
/// This event is fired when this drag group is grabbed by the titlebar for relocation.
Property onwindowgrab As %ZEN.Datatype.eventHandler;

/// onwindowdrop event handler:
/// This event is fired when this drag group's title bar is released after a reloaction gesture
Property onwindowdrop As %ZEN.Datatype.eventHandler;

/// Title to display in header section for this group.
Property header As %ZEN.Datatype.caption [ InitialExpression = "Untitled Group" ];

/// URI of image to display for the close group button.
Property imageAppLogo As %ZEN.Datatype.uri;

/// Width (in pixels) of image to display for the close group button.
Property imageAppLogoWidth As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// URI of image to display for the close group button.
Property imageClose As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTCLOSEIMAGE} ];

/// URI of image to display for the close group button when mouse is present.
Property imageCloseHover As %ZEN.Datatype.uri;

/// Width (in pixels) of image to display for the close group button.
Property imageCloseWidth As %ZEN.Datatype.integer [ InitialExpression = 16 ];

/// URI of image to display for the minimize group button.
Property imageMinimize As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTMINIMAGE} ];

/// URI of image to display for the minimize group button when mouse is present
Property imageMinimizeHover As %ZEN.Datatype.uri;

/// Width (in pixels) of image to display for the minimize group button.
Property imageMinimizeWidth As %ZEN.Datatype.integer [ InitialExpression = 16 ];

/// URI of image to display for the maximize group button.
Property imageMaximize As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTMAXIMAGE} ];

/// URI of image to display for the maximize group button when mouse is present.
Property imageMaximizeHover As %ZEN.Datatype.uri;

/// Width (in pixels) of image to display for the maximize group button.
Property imageMaximizeWidth As %ZEN.Datatype.integer [ InitialExpression = 16 ];

/// URI of image to display for the expand group button.
Property imageExpand As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTEXPANDIMAGE} ];

/// URI of image to display for the expand group button when mouse is present.
Property imageExpandHover As %ZEN.Datatype.uri;

/// Width (in pixels) of image to display for the expand group button.
Property imageExpandWidth As %ZEN.Datatype.integer [ InitialExpression = 16 ];

/// URI of image to display for the contract group button.
Property imageContract As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTCONTRACTIMAGE} ];

/// URI of image to display for the contract group button when mouse is present.
Property imageContractHover As %ZEN.Datatype.uri;

/// Width (in pixels) of image to display for the contract group button.
Property imageContractWidth As %ZEN.Datatype.integer [ InitialExpression = 16 ];

/// URI of image to display for the minimize group button.
Property imageResize As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTRESIZEIMAGE} ];

/// Square area in pixels for the resize icon
Property imageResizeSize As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTRESIZEICONSIZE} ];

/// If set, this boolean flag indicates that the title section of the header
/// should be centered over the dragGroup 
Property centerHeader As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// The header layout pattern determines the order in which control windows are added
/// to the header section of the dragGroup window frame.  This is encoded as a five
/// character string consisting of the following tokens <br>
/// 'I' represents the Iconify button <br>
/// 'T' represents the Title section with both application logo and header caption<br>
/// 'F' represents the Full screen button <br>
/// 'C' represents the Close button <br>
/// 'U' represents the User content div (if desired) <br>
/// This string allows one to restructure the location of the controls with a single 
/// call and might be useful if the page designer is trying to match the look and feel 
/// of a given operating system.  For example, MS-Windows systems follow the pattern of
/// 'TIFC' whereas MacOS adopts the standard of CIFT with the title centered 
/// (cf. centerHeader) The Title section represent something of a breakpoint in the header
/// layout.  Everything prior to the header floats from the left end of the header;
/// Everything after the header, floats from the right end.
Property headerLayout As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTHEADERLAYOUT} ];

/// If set, the default, this boolean flag allows the drag group to be repositioned by
/// user action within the containing active group area.
Property moveEnabled As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If set, the default, this boolean flag allows the drag group to be resized by
/// user action 
Property resizeEnabled As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If used as a child of a snapGroup, this specifies the (initial static) width of the widget
/// in columns
Property colSpan As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// If used as a child of a snapGroup, this specifies the (initial static) height of the widget
/// in rows
Property rowSpan As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// If used as a child of a snapGroup, this specifies the (initial static) row hosting the 
/// top of the widget
Property homeRow As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// If used as a child of a snapGroup, this specifies the (initial static) row hosting the 
/// left edge of the widget
Property homeCol As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// This sets the minimum width (in pixels) for a dragGroup during resizing.  If used within a
/// snapGrid context, the actual minimum width is set to the next highest even multiple of
/// the snapGrid column width. 
Property minWidth As %ZEN.Datatype.integer [ InitialExpression = 96 ];

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for drag group." */
.dragGroup {
	position: absolute;
	border: 1px solid gray;
	background: white;
	overflow:hidden;
	width:250px;
}

/* @doc="div for drag group header." */
.dragHeader {
	border-bottom: 1px solid #808080;
	background: #23242C;
	background-image: url(images/grayDragHeader.png);
	background-repeat: repeat-x;
	cursor: move;
    font-family: sans-serif;
    font-weight:bold;
    font-size:14px;
	color: #000066;	
	white-space:nowrap;
	text-align:left;
	height:22px;
	position:relative;
}

/* @doc="div for drag group header." */
.dragHeaderText {
 	white-space: nowrap;
	position:relative;
	top:-35%;
	display:block;
}

/* @doc="div for drag user defined part of group header." */
.dragHeaderUserSpan {
	white-space: nowrap;
	height:100%;
	width:48px;
	position:absolute;
	top:0px;	
}

/* @doc="div for drag group header." */
.dragChildren {
	width:100%;
	height:100%;
	overflow:auto; 
}

.dragCoverplate {
	position:absolute;
	top:0px;
	bottom:0px;
	left:0px;
	right:0px;
	background-color:#ffffff;
	opacity:0.01;
	display:none;
}

.draglogoDiv {
	display:inline;
	height:22px;
	width:16px;
	margin-left:2px;
	margin-right:2px;
	background-position: center center;
	background-repeat:no-repeat;
	float:left;
}

.dragIconifyDiv {
	cursor:pointer;
	height:100%;
	width:16px;
	background-image:url(images/grayDragContract.png);
	background-position: center center;
	background-repeat:no-repeat;
	position:absolute;
	top:0px;
}

.dragExpandDiv {
	cursor:pointer;
	height:100%;
	width:16px;
	background-image:url(images/grayDragExpand.png);
	background-position: center center;
	background-repeat:no-repeat;
	position:absolute;
	top:0px;
	display:none;
}

.dragFullScreenDiv {
	cursor:pointer;
	height:100%;
	width:16px;
	background-image:url(images/grayDragMax.png);
	background-position: center center;
	background-repeat:no-repeat;
	position:absolute;
	top:0px;
}

.dragShareScreenDiv {
	cursor:pointer;
	height:100%;
	width:16px;
	background-image:url(images/grayDragMin.png);
	background-position: center center;
	background-repeat:no-repeat;
	position:absolute;
	top:0px;
	display:none;
}

.dragCloseDiv {
	cursor:pointer;
	height:100%;
	width:16px;
	background-image:url(images/grayDragClose.png);
	background-position: center center;
	background-repeat:no-repeat;
	position:absolute;
	top:0px;
}

.dragHeaderLeft {
	display:inline-block;
	white-space:nowrap;
	height:22px;
	width:16px;
	position:absolute;
	top:0px;
	left:5px;
}

.dragHeaderMiddle {
	position:absolute;
	top:0px;
	white-space:nowrap;
	height:100%;
}

.dragHeaderRight {
	white-space:nowrap;
	height:100%;
	margin-right:5px;
	position:absolute;
	top:0;
	right:0px;
}

</style>
}

Method %DrawHTML()
{
	#; header
	&html<<div class="dragHeader" id="#(..%MakeId("header"))#"></div>>

	#; children
	&html<<div class="dragChildren" id="#(..%MakeId("children"))#" style="position:absolute" >>
	
	Do ..%LayoutChildren(..tuple)
	&html<<div class="dragCoverplate" id="#(..%MakeId("coverplate"))#" ></div></div>>

	#; Modify renderFlag to be force client-side call to renderContents
	Set ..renderFlag = ..renderFlag + 1
}

/// Client-side method to ensure that the controller has an accurate model
/// to work with even if the DOM has been modified externally
ClientMethod onRefreshContents() [ Language = javascript ]
{
	this.renderContents();
}

/// Client-side method to render control.
ClientMethod renderContents() [ Language = javascript ]
{
	var header = this.getHeaderDiv();
	if (!header) return;
	if (header.textCell) return;
//this.renderCoverplate();
	this.coverplate = this.getCoverplateDiv();
	this.renderResize();
	this.renderHeader();
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return;
	thisDiv.compressed = 0;
	thisDiv.maximized = 0;
	if (!thisDiv.prefWidth) thisDiv.prefWidth = thisDiv.offsetWidth;
	if (!thisDiv.prefHeight) thisDiv.prefHeight = thisDiv.offsetHeight;
	if (!thisDiv.minWidth) thisDiv.minWidth = parseInt(this.minWidth,10);
	if (!thisDiv.minHeight) thisDiv.minHeight = thisDiv.iconHeight+thisDiv.resize.size+1;
	thisDiv.oldTop = 0;
	thisDiv.oldLeft = 0;
	thisDiv.oldWidth = 0;
	thisDiv.oldHeight = 0;
	thisDiv.oldPrefHeight = 0;
	this.adjustChildArea();
}

ClientMethod verifyHeaderGeometry() [ Language = javascript ]
{
	var ofsX=0;	
	if (this.headerLeft.hasChildNodes()==false) this.headerLeft.style.display='none';
	else {
		this.headerLeft.style.display='block';
		var k = this.headerLeft.childNodes;
		for (var i=0;i<k.length;i++) {
			if (k[i]==this.iconify) {
				k[i].style.left=ofsX+"px";
				this.expander.style.left=ofsX+"px";
				ofsX+=k[i].nativeWidth+2;
			}
			else if (k[i]==this.maxxer) {
				k[i].style.left=ofsX+"px";
				this.minner.style.left=ofsX+"px";
				ofsX+=k[i].nativeWidth+2;
			}
			else if (k[i]==this.closer) {
				k[i].style.left=ofsX+"px";
				ofsX+=k[i].nativeWidth+2;
			}
			else if (k[i]==this.userDiv) {
				k[i].style.left=ofsX+"px";
				ofsX+=k[i].offsetWidth+2;
			}
		}
		this.headerLeft.style.width=ofsX+"px";
	}

	if (this.centerLayout) {
		var cOfsX = (this.headerDiv.offsetWidth-this.appLogo.nativeWidth-this.titleDiv.offsetWidth)/2;
		if (cOfsX<ofsX)cOfsX=ofsX;
		this.headerMiddle.style.left=cOfsX+"px";
	}
	else this.headerMiddle.style.left=(ofsX+4)+"px";

	var k = this.headerRight.childNodes;
	var ofsX=0;
	for (var i=0;i<k.length;i++) {
		if (k[i]==this.iconify) {
			k[i].style.left=ofsX+"px";
			this.expander.style.left=ofsX+"px";
			ofsX+=k[i].nativeWidth+2;
		}
		else if (k[i]==this.maxxer) {
			k[i].style.left=ofsX+"px";
			this.minner.style.left=ofsX+"px";
			ofsX+=k[i].nativeWidth+2;
		}
		else if (k[i]==this.closer) {
			k[i].style.left=ofsX+"px";
			ofsX+=k[i].nativeWidth+2;
		}
		else if (k[i]==this.userDiv) {
			k[i].style.left=ofsX+"px";
			ofsX+=k[i].offsetWidth+2;
		}			
	}
	this.headerRight.style.width=ofsX+"px";
}

ClientMethod setAppLogo(iconURL, width) [ Language = javascript ]
{
	var w=parseInt(width,10);
	if (iconURL && iconURL.length>0) {
		this.appLogo.style.display = 'inline';
		this.appLogo.style.backgroundImage = "url("+iconURL+")";
		this.appLogo.style.width = w+"px";
		this.appLogo.nativeWidth = w;
	}
	else this.appLogo.style.display="none";
	this.imageAppLogo = iconURL;
	this.imageAppLogoWidth = w;
	if (this.centerLayout) this.setCenterLayout(true);
}

ClientMethod setContractIcon(iconURL, width) [ Language = javascript ]
{
	this.imageContractWidth=this.setIcon(this.iconify,iconURL,width);
	this.imageContract=iconURL;
}

ClientMethod setExpandIcon(iconURL, width) [ Language = javascript ]
{
	this.imageExpandWidth=this.setIcon(this.expander,iconURL,width);
	this.imageExpand=iconURL;
}

ClientMethod setMaximizeIcon(iconURL, width) [ Language = javascript ]
{
	this.imageMaximizeWidth=this.setIcon(this.maxxer,iconURL,width);
	this.imageMaximize=iconURL;
}

ClientMethod setMinimizeIcon(iconURL, width) [ Language = javascript ]
{
	this.imageMinimizeWidth=this.setIcon(this.minner,iconURL,width);
	this.imageMinimize=iconURL;
}

ClientMethod setCloseIcon(iconURL, width) [ Language = javascript ]
{
	this.imageCloseWidth=this.setIcon(this.closer,iconURL,width);
	this.imageClose=iconURL;
}

ClientMethod setIcon(iconDiv, iconURL, width) [ Language = javascript ]
{
	if (!width) var w=16;
	else var w=parseInt(width,10);
	if (iconURL && iconURL.length>0) {
		iconDiv.style.backgroundImage = "url("+iconURL+")";
		iconDiv.style.width = w+"px";
		iconDiv.nativeWidth = w;
	}
	this.verifyHeaderGeometry();
	return(w);
}

ClientMethod setCenterLayout(flag) [ Language = javascript ]
{
	var m=this.headerMiddle.style;
	var v=this.headerMiddleVDiv.style;
	v.position = "absolute";
	v.left = (this.imageAppLogoWidth+4)+"px";
	this.centerLayout=flag;
	this.verifyHeaderGeometry();
}

ClientMethod setHeaderLayout(layout) [ Language = javascript ]
{
	if (this.iconify.parentNode) this.iconify.parentNode.removeChild(this.iconify);
	if (this.expander.parentNode) this.expander.parentNode.removeChild(this.expander);
	if (this.maxxer.parentNode) this.maxxer.parentNode.removeChild(this.maxxer);
	if (this.minner.parentNode) this.minner.parentNode.removeChild(this.minner);
	if (this.closer.parentNode) this.closer.parentNode.removeChild(this.closer);
	
	var section = this.headerLeft;
	for (var i=0;i<layout.length;i++) {
		var c=layout.charAt(i).toUpperCase();
		if (c=='I') {
			section.appendChild(this.iconify);
			section.appendChild(this.expander);
		}
		else if (c=='F') {
			section.appendChild(this.maxxer);
			section.appendChild(this.minner);
		}
		else if (c=='C') {
			section.appendChild(this.closer);
		}
		else if (c=='U') {
			section.appendChild(this.userDiv);
		}
		else if (c=='T') {
			section=this.headerRight;
		}
	}
	this.headerLayout=layout;
	this.verifyHeaderGeometry();
}

/// If the object has been moved or resized inside a snapGrid, sync the server-side
/// visible geometry properties with the actual location and extents
ClientMethod syncObject() [ Language = javascript ]
{
	var div = this.getEnclosingDiv();
	if (!div) return;

	var mgr = div.layoutMgr;
	if (!mgr || !mgr.managerName || mgr.managerName!="snapGridGroup") return;
	var ref = div.oRefL;  // or oRefP in portrait mode
	if (div.layoutEngine.orientation=="portrait") ref = div.oRefP;
	if (ref) {
		this.setProperty("homeRow",ref.top);
		this.setProperty("homeCol",ref.left);
		this.setProperty("rowSpan",ref.height);
		this.setProperty("colSpan",ref.width);	
	}
}

/// Render the contents of the header section of this component.
ClientMethod renderHeader() [ Language = javascript ]
{
	var header = this.getHeaderDiv();
	var group = this.getEnclosingDiv();
	if (!group) return;

	// If we already have a header, clear it and start over
	var q = null;
	for (var p = header.firstChild; p!=null; p=q) {
		q = p.nextSibling;
		header.removeChild(p);
	}
	
	if (ZLM.isIE) {
		group.iFrame = ZLM.simulateTag("iframe src='' frameBorder='0' style='filter:alpha(opacity=0); z-index:0; position:absolute; top:0px; left:0px; width:100%; height:100%; border: 0px solid black; background:transparent;'");
		group.insertBefore(group.iFrame,group.firstChild);
		header.style.position='relative';
		header.style.zIndex="1";
	}

	if (header) {
		this.headerLeft = ZLM.makeElement('div',{'class':'dragHeaderLeft'});
		this.headerMiddle = ZLM.makeElement('div',{'class':'dragHeaderMiddle'});
		this.headerRight = ZLM.makeElement('div',{'class':'dragHeaderRight'});
		
		header.appendChild(this.headerLeft);
		header.appendChild(this.headerMiddle);
		header.appendChild(this.headerRight);
		
		this.iconify = ZLM.makeElement('div',{'class':'dragIconifyDiv',onmouseover:'this.pane.zenObj.animateIcon("contract","enter");',onmouseout:'this.pane.zenObj.animateIcon("contract","exit");',onmousedown:'this.pane.zenObj.compress(event);',ontouchstart:'this.pane.zenObj.compress(event);'});
		this.expander = ZLM.makeElement('div',{'class':'dragExpandDiv',onmouseover:'this.pane.zenObj.animateIcon("expand","enter");',onmouseout:'this.pane.zenObj.animateIcon("expand","exit");',onmousedown:'this.pane.zenObj.expand(event);',ontouchstart:'this.pane.zenObj.expand(event);'});
		this.maxxer = ZLM.makeElement('div',{'class':'dragFullScreenDiv',onmouseover:'this.pane.zenObj.animateIcon("max","enter");',onmouseout:'this.pane.zenObj.animateIcon("max","exit");', onmousedown:'this.pane.zenObj.maximize(event); zenPage.setModified(true);',ontouchstart:'this.pane.zenObj.maximize(event);',title:'Maximize this widget'});
		this.minner = ZLM.makeElement('div',{'class':'dragShareScreenDiv',onmouseover:'this.pane.zenObj.animateIcon("min","enter");',onmouseout:'this.pane.zenObj.animateIcon("min","exit");',onmousedown:'this.pane.zenObj.normalize(event); zenPage.setModified(true);',ontouchstart:'this.pane.zenObj.normalize(event);',title:'Minimize this widget'});
		this.closer = ZLM.makeElement('div',{'class':'dragCloseDiv',onmouseover:'this.pane.zenObj.animateIcon("close","enter");',onmouseout:'this.pane.zenObj.animateIcon("close","exit");',onclick:'this.pane.zenObj.close(event);',ontouchstart:'this.pane.zenObj.close(event);',onmousedown:'ZLM.killEvent(event);',title:'Hide this widget'});
		this.appLogo = ZLM.makeElement('div',{'class':'dragLogoDiv'});
		this.userDiv = ZLM.makeElement('div',{'class':'dragHeaderUserSpan'});
		
		this.headerMiddle.appendChild(this.appLogo);
		this.headerMiddleVDiv = ZLM.makeElement('div',{style:'position:relative; top:50%; height:100%;'});
		this.headerMiddle.appendChild(this.headerMiddleVDiv);
		
        this.titleDiv = ZLM.makeElement("div",null,this.header);
        this.titleDiv.className = "dragHeaderText";
		this.headerMiddleVDiv.appendChild(this.titleDiv);
		
		this.setAppLogo(this.imageAppLogo,this.imageAppLogoWidth);
		this.setCenterLayout(this.centerLayout);
		this.setContractIcon(this.imageContract,this.imageContractWidth);
		this.setExpandIcon(this.imageExpand,this.imageExpandWidth);
		this.setMaximizeIcon(this.imageMaximize,this.imageMaximizeWidth);
		this.setMinimizeIcon(this.imageMinimize,this.imageMinimizeWidth);
		this.setCloseIcon(this.imageClose,this.imageCloseWidth);
	
		this.setHeaderLayout(this.headerLayout);
		
		ZLM.setLocalAttribute(header,"onmousedown","ZLM.drag(this.parentNode,event);");
		ZLM.setLocalAttribute(header,"ontouchstart","ZLM.touch(this.parentNode,event);");
		
		header.maxxer = this.maxxer;
		header.minner = this.minner;
		header.closer = this.closer;
		header.iconifier = this.iconify;
		header.expander = this.expander;
		header.textCell=this.titleDiv;
        
		this.maxxer.pane = group;
		this.minner.pane = group;
		this.closer.pane = group;
		this.expander.pane = group;
		this.iconify.pane = group;

		group.dragHandle=header;
		group.dragItem=this.getChildDiv();
		group.zenObj=this;
		this.adjustHandleWidth();
		this.adjustResizeBox();
		this.headerDiv=header;
		if (!this.moveEnabled) this.disableDrag();
	}
}

ClientMethod animateIcon(who, which) [ Language = javascript ]
{
	if (who=="close") {
		if (!this.imageCloseHover) return;
		if (which=="exit") {
			this.setIcon(this.closer,this.imageClose,this.imageCloseWidth)
		}
		else {
			this.setIcon(this.closer,this.imageCloseHover,this.imageCloseWidth)
		}
	}
	else if (who=="contract") {
		if (!this.imageContractHover) return;
		if (which=="exit") {
			this.setIcon(this.iconify,this.imageContract,this.imageContractWidth)
		}
		else {
			this.setIcon(this.iconify,this.imageContractHover,this.imageContractWidth)
		}
	}
	else if (who=="expand") {
		if (!this.imageExpandHover) return;
		if (which=="exit") {
			this.setIcon(this.expander,this.imageExpand,this.imageExpandWidth)
		}
		else {
			this.setIcon(this.expander,this.imageExpandHover,this.imageExpandWidth)
		}
	}
	else if (who=="max") {
		if (!this.imageMaximizeHover) return;
		if (which=="exit") {
			this.setIcon(this.maxxer,this.imageMaximize,this.imageMaximizeWidth)
		}
		else {
			this.setIcon(this.maxxer,this.imageMaximizeHover,this.imageMaximizeWidth)
		}
	}
	else if (who=="min") {
		if (!this.imageMinimizeHover) return;
		if (which=="exit") {
			this.setIcon(this.minner,this.imageMinimize,this.imageMinimizeWidth)
		}
		else {
			this.setIcon(this.minner,this.imageMinimizeHover,this.imageMinimizeWidth)
		}
	}
}

/// Add resize box for this component.
ClientMethod renderResize() [ Language = javascript ]
{
	var group = this.getEnclosingDiv();
	var sz = parseInt(this.imageResizeSize);
	if (group) {
        var resize = ZLM.simulateTag("img src='"+this.imageResize+"' style='cursor:nw-resize; position:absolute; z-index:65535; width:"+sz+"; height:"+sz+";' onmousedown='ZLM.drag(this,event);' ontouchstart='ZLM.touch(this,event);'");
        resize.pane = group;
        resize.size = sz;
        group.appendChild(resize);
        group.resize=resize;
        ZLM.registerDragItem(resize,this);
  		if (!this.resizeEnabled) this.disableResize();
	}
}

/// Enable user resize events for this group
ClientMethod enableResize() [ Language = javascript ]
{
	var group = this.getEnclosingDiv();
	if (group && group.resize) {
		ZLM.setLocalAttribute(group.resize,"onmousedown","ZLM.drag(this,event);");
		group.resize.style.cursor = "nw-resize;"
		group.resize.style.display= "block";
	}
	this.noResize = false;
}

/// Disable user resize events for this group
ClientMethod disableResize() [ Language = javascript ]
{
	var group = this.getEnclosingDiv();
	if (group && group.resize) {
		ZLM.setLocalAttribute(group.resize,"onmousedown","");
		group.resize.style.cursor = "auto;"
		group.resize.style.display= "none";
	}
	this.noResize=true;
}

/// Enable user drag events for this group
ClientMethod enableDrag() [ Language = javascript ]
{
	var group = this.getEnclosingDiv();
	if (group && group.dragHandle) {
		ZLM.setLocalAttribute(group.dragHandle,"onmousedown","ZLM.drag(this.parentNode,event);");
		group.resize.style.cursor = "move;"
	}
}

/// Disable user drag events for this group
ClientMethod disableDrag() [ Language = javascript ]
{
	var group = this.getEnclosingDiv();
	if (group && group.dragHandle) {
		ZLM.setLocalAttribute(group.dragHandle,"onmousedown","");
		ZLM.setLocalAttribute(group.dragHandle,"ontouchstart","");
		group.dragHandle.style.cursor = "auto;"
	}
}

/// When rendering static windows, enable a click anywhere on the 
/// header handle to toggle full screen mode instead of allowing
/// drag operations
ClientMethod enableHeaderMaxToggle() [ Language = javascript ]
{
	var group = this.getEnclosingDiv();
	if (group && group.dragHandle) {
		group.dragHandle.zenObj = this;
		ZLM.setLocalAttribute(group.dragHandle,"onmousedown","this.zenObj.maximize(event);");
		ZLM.setLocalAttribute(group.dragHandle,"ontouchstart","this.zenObj.maximize(event);");
		group.dragHandle.style.cursor = "all-scroll";
		this.headerAsToggle=true;
	}
}

/// Reset the maximize toggle mode set up by enableHeaderMaxToggle
ClientMethod disableHeaderMaxToggle() [ Language = javascript ]
{
		this.enableDrag();
		this.headerAsToggle=false;
}

/// Remove the header entirely and disable resize
ClientMethod removeWindowChrome() [ Language = javascript ]
{
		this.headerRemoved = true;
		this.disableResize();
		var h = this.getHeaderDiv();
		h.style.height="0px";
		h.style.overflow="hidden";
		h.style.border="none";
		this.adjustChildArea();
		this.onresizeHandler();
}

/// Restore header and resize controls previously remove by removeWindowChrome
ClientMethod resetWindowChrome() [ Language = javascript ]
{
		this.headerRemoved = false;
		this.enableResize();
		var h = this.getHeaderDiv();
		if (h) {		// DTB558
			h.style.height="";
			h.style.overflow="";
			h.style.border="";
		}
		this.adjustChildArea();
		this.onresizeHandler();
}

ClientMethod renderCoverplate() [ Language = javascript ]
{
		var g = this.getChildDiv();
		try {  // if we already have one, recycle it
			if (this.coverplate) {
				g.removeChild(this.coverplate);
				g.appendChild(this.coverplate);
				return;
			}
		}
		catch (err) {
		}
		// otherwise make a fresh one, some clever programmer must of toasted us
		var plate=ZLM.makeElement('div',{'class':'dragCoverplate'});
 //ZLM.setLocalAttribute(plate,"onmousemove","ZLM.killEvent(event);");
		g.appendChild(plate);
		var div = this.getEnclosingDiv();
		if (div) div.coverplate=plate;
		this.coverplate=plate;
}

/// Return a string that captures the current state of the group's layout
ClientMethod getState() [ Language = javascript ]
{
   var r = this.getEnclosingDiv();
   if (!r) return(null);

   var str=r.id+":"+encodeURIComponent(this.header)+":";
   str=str+r.prefWidth+":"+r.prefHeight+":"+r.minWidth+":"+r.minHeight+":"+r.compressed+":"+r.maximized+":";
   str=str+r.oldTop+":"+r.oldLeft+":"+r.oldWidth+":"+r.oldHeight+":"+r.oldPrefHeight;
   return(str);
}

/// Given a previously encoded layout string, restore a group to its
/// previous state
ClientMethod restoreState(str) [ Language = javascript ]
{
	var n = this.getEnclosingDiv();
	if (!n) return;

	var d = str.split(':');
    n.prefWidth=parseInt(d[2]);
    n.prefHeight=parseInt(d[3]);
    n.minWidth=parseInt(d[4]);
    n.minHeight=parseInt(d[5]);
    n.oldTop=parseInt(d[8]);
    n.oldLeft=parseInt(d[9]);
    n.oldWidth=parseInt(d[10]);
    n.oldHeight=parseInt(d[11]);
    n.oldPrefHeight=parseInt(d[12]);
    if (d[7]=="1"){
	    if (d[6]==1) n.compressed=1;
	    else n.compressed=0;
        n.maximized = 1;
        n.dragHandle.expander.style.display="none";
        n.dragHandle.iconifier.style.display="none";
        n.dragHandle.maxxer.style.display="none";
        n.dragHandle.minner.style.display="block";
        n.dragItem.style.display="block";
        n.resize.style.display="none";
        this.resize(n.parentNode.clientWidth-2,n.parentNode.clientHeight-2);
        ZLM.setLocalAttribute(n.dragHandle,"onmousedown","");
        n.dragHandle.style.cursor="auto";
        n.parentNode.style.overflow="hidden";
        n.style.top="0px";
        n.style.left="0px";
        n.style.zIndex="100";
        ZLM.notifyResize(n);
        this.onresizeHandler();
    }
    else {
        n.maximized = 0;
        n.dragHandle.minner.style.display="none";
        n.dragHandle.maxxer.style.display="block";
        if (d[6]=="1") {
	        n.compressed=1;
            n.dragHandle.expander.style.display="block";
	        n.dragHandle.iconifier.style.display="none";
            n.dragItem.style.display="none";
	        n.resize.style.display="none";
        }
        else {
	        n.compressed=0;
            n.dragHandle.expander.style.display="none";
	        n.dragHandle.iconifier.style.display="block";
	        n.resize.style.display="block";
            n.dragItem.style.display="block";
        }
        ZLM.setLocalAttribute(n.dragHandle,"onmousedown","ZLM.drag(this.parentNode,event);");
        n.dragHandle.style.cursor="move";
        n.parentNode.style.overflow="auto";
        n.style.zIndex="0";
    }
}

/// Resize the active group to the given geometry
ClientMethod resize(width, height) [ Language = javascript ]
{
	if (!width.indexOf) width=width+"px";
	if (!height.indexOf) height=height+"px";
	var thisDiv = this.getEnclosingDiv();
	if (thisDiv) {
    	thisDiv.style.width=width;
    	thisDiv.style.height=height;
/*
    var s = ZLM.getComputedNodeStyle(thisDiv,"marginTop");
    if (s) {
	    var m = parseInt(s);
	    var w = (thisDiv.offsetWidth-2*m)+"px";
	    var h = (thisDiv.offsetHeight-2*m)+"px";
	    thisDiv.style.width=w;
	    thisDiv.style.height=h;
    } 
*/
	}
    this.adjustHandleWidth();
    this.adjustChildArea();
    this.onresizeHandler();
}

/// Restore key layout information about group in after a radical presentation change
ClientMethod restoreGeometry() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return;

    thisDiv.style.top=this.oldTop + "px";
    thisDiv.style.left=this.oldLeft + "px";
    ZLM.setOffsetWidth(thisDiv,this.oldWidth);
    ZLM.setOffsetHeight(thisDiv,this.oldHeight);
    this.adjustHandleWidth();
    this.adjustChildArea();
}

/// Save key layout information about group in anticipation of a radical presentation change
ClientMethod saveGeometry() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return;
    this.oldTop = thisDiv.offsetTop;
    this.oldLeft = thisDiv.offsetLeft;
    this.oldWidth = thisDiv.offsetWidth;
    this.oldHeight = thisDiv.offsetHeight;
}

/// Utility to adjust the width of the drag header to correctly position
/// the header controls based on the current drag group width
ClientMethod adjustHandleWidth() [ Language = javascript ]
{
	if (this.centerLayout) this.verifyHeaderGeometry();
}

/// Utility to adjust the location of the resize box to correctly position
/// the control based on the current drag group width
ClientMethod adjustResizeBox() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return;

	var box = thisDiv.resize;
	box.style.bottom="0px";
	box.style.right="0px"
}

/// Utility to adjust the size of the dragChildren area in the
/// event of a resize action
ClientMethod adjustChildArea() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return;

	var headerDiv = this.getHeaderDiv();
	if (!headerDiv) return;
	
	var childDiv = this.getChildDiv();
	var box = thisDiv.resize;
	var hgt = ZLM.getClientHeight(thisDiv);
	if (!this.headerRemoved) hgt = hgt-ZLM.getOffsetHeight(headerDiv);
	hgt = (hgt <= 0) ? 0 : hgt;
	childDiv.style.height = hgt + 'px';
	if (!this.isResizeInProgress()) {
		box.style.top="";
		box.style.left="";
		this.adjustResizeBox();
	}
}

/// Public utility to abort the a window closure in progress
ClientMethod abortClose() [ Language = javascript ]
{
	this.closePending = false;
}

/// Callback to close the subwindow
ClientMethod close(event) [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return;

    ZLM.killEvent(event);
	this.closePending=true;
	if (this.onclosepending) {
		zenInvokeCallbackMethod(this.onclosepending,this,'onclosepending');
	}
    if (this.closePending) thisDiv.layoutMgr.closePane(thisDiv);
    ZLM.killEvent(event);
}

/// Callback to reduce subwindow to the height of its title bar 
ClientMethod compress(event) [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
    ZLM.killEvent(event);
    if (!thisDiv) return;

    thisDiv.oldPrefHeight = thisDiv.prefHeight;
    thisDiv.dragItem.style.display="none";
    thisDiv.resize.style.display="none";
    thisDiv.dragHandle.expander.style.display="block";
    thisDiv.dragHandle.iconifier.style.display="none";
    thisDiv.compressed=1;
    thisDiv.prefHeight=ZLM.getOffsetHeight(this.getHeaderDiv());
    thisDiv.layoutMgr.layoutBlock(thisDiv.layoutEngine);
}

/// Callback to restore a compressed pane to it miniture display mode 
ClientMethod expand(event) [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
    ZLM.killEvent(event);
    if (!thisDiv) return;

    thisDiv.compressed=0;
    thisDiv.prefHeight = thisDiv.oldPrefHeight;
    thisDiv.dragItem.style.display="block";
    thisDiv.resize.style.display="block";
    thisDiv.dragHandle.expander.style.display="none";
    thisDiv.dragHandle.iconifier.style.display="block";
    thisDiv.layoutMgr.layoutBlock(thisDiv.layoutEngine);
}

/// Callback to switch subwindow into full screen mode 
ClientMethod maximize(event) [ Language = javascript ]
{
	this.maximized = true;
	var thisDiv = this.getEnclosingDiv();
    ZLM.killEvent(event);
    if (!thisDiv) return;

    thisDiv.maximized = 1;
    thisDiv.style.display="block";
    thisDiv.dragHandle.expander.style.display="none";
    thisDiv.dragHandle.iconifier.style.display="none";
    thisDiv.dragHandle.maxxer.style.display="none";
    thisDiv.dragHandle.minner.style.display="block";
    thisDiv.dragItem.style.display="block";
    thisDiv.resize.style.display="none";
    this.saveGeometry();
    var dskW = thisDiv.parentNode.parentNode.clientWidth-2;
    var dskH = thisDiv.parentNode.parentNode.clientHeight-2;
    this.resize(dskW,dskH);
    ZLM.setLocalAttribute(thisDiv.dragHandle,"onmousedown","");
    ZLM.setLocalAttribute(thisDiv.dragHandle,"ontouchstart","");
    thisDiv.dragHandle.style.cursor="auto";
    thisDiv.parentNode.style.overflow="hidden";
    thisDiv.style.top="0px";
    thisDiv.style.left="0px";
    thisDiv.style.zIndex="100";    
    if (this.headerAsToggle) {
		ZLM.setLocalAttribute(thisDiv.dragHandle,"onmousedown","this.zenObj.normalize(event);");
		ZLM.setLocalAttribute(thisDiv.dragHandle,"ontouchstart","this.zenObj.normalize(event);");
	}
    ZLM.notifyResize(thisDiv);
    this.onresizeHandler();
}

/// Callback to switch a full screen window back down to it previous
/// (iconified or mini-window) mode
ClientMethod normalize(event) [ Language = javascript ]
{
	this.maximized = false;
	var thisDiv = this.getEnclosingDiv();
    ZLM.killEvent(event);
    if (!thisDiv) return;
  
    thisDiv.maximized = 0;
    thisDiv.dragHandle.minner.style.display="none";
    thisDiv.dragHandle.maxxer.style.display="block";
    if (thisDiv.compressed==1) {
      thisDiv.dragHandle.expander.style.display="block";
      thisDiv.dragItem.style.display="none";
    }
    else {
	  thisDiv.dragHandle.iconifier.style.display="block";
	  if (!this.noResize) thisDiv.resize.style.display="block";
    }
    this.restoreGeometry(); 
    if (this.moveEnabled) {
    	ZLM.setLocalAttribute(thisDiv.dragHandle,"onmousedown","ZLM.drag(this.parentNode,event);");
    	ZLM.setLocalAttribute(thisDiv.dragHandle,"ontouchstart","ZLM.drag(this.parentNode,event);");
    }
    thisDiv.dragHandle.style.cursor="move";
    thisDiv.parentNode.style.overflow="auto";
    thisDiv.style.zIndex="0";
    thisDiv.layoutMgr.layoutBlock(thisDiv.layoutEngine);
    if (this.headerAsToggle) {
		ZLM.setLocalAttribute(thisDiv.dragHandle,"onmousedown","this.zenObj.maximize(event);");
		ZLM.setLocalAttribute(thisDiv.dragHandle,"ontouchstart","this.zenObj.maximize(event);");
	}
	if (thisDiv.layoutMgr.broadcast) thisDiv.layoutMgr.broadcast("resize");
	else this.onresizeHandler();
}

/// Launches a callback (if defined) when the drag group is grabbed by 
/// the title bar for the purpose of relocation 
ClientMethod onGrabHandler() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	var mgr = thisDiv.layoutMgr;
	if (mgr && mgr.broadcast) {
		mgr.broadcast("enableCoverplate");
	}
	if (this.onwindowgrab) {
		zenInvokeCallbackMethod(this.onwindowgrab,this,'onwindowgrab');
	}
}

/// Launches a callback (if defined) when the drag group's title bar is released 
/// after relocation gesture
ClientMethod onReleaseHandler() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (thisDiv.layoutMgr && thisDiv.layoutMgr.broadcast) {
		thisDiv.layoutMgr.broadcast("disableCoverplate");
	}
	if (this.onwindowdrop) {
		zenInvokeCallbackMethod(this.onwindowdrop,this,'onwindowdrop');
	}
}

/// Returns true if the drag window is currently rendered in 
/// maximized mode
ClientMethod isMaximized() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return(false);

    if (thisDiv.maximized == 1) return(true);
    return(false);
}

/// Returns true if the drag window is currently rendered in 
/// header only mode
ClientMethod isCompressed() [ Language = javascript ]
{
	var thisDiv = this.getEnclosingDiv();
	if (!thisDiv) return(false);

    if (thisDiv.compressed == 1) return(true);
    return(false);
}

/// Checks to see if the user is actively in the process of resizing the
/// window 
ClientMethod isResizeInProgress() [ Language = javascript ]
{
	if (this.resizeDragActive==true) return(true);
	return(false);
}

ClientMethod enableCoverplate() [ Language = javascript ]
{
	if (this.coverplate) this.coverplate.style.display="block";
}

ClientMethod disableCoverplate() [ Language = javascript ]
{
	if (this.coverplate) this.coverplate.style.display="none";
}

/// Callback to initiate window resize event
ClientMethod startDrag(engine, wrapper) [ Language = javascript ]
{
	var mgr = zen(this.parent.id);
	if (mgr && mgr.bringToFront) {
		mgr.bringToFront(this);
	}

	var thisDiv=this.getEnclosingDiv();	
	if (this.coverplate) this.coverplate.style.display="block";
	if (thisDiv.layoutMgr.maskPeers) thisDiv.layoutMgr.maskPeers(thisDiv.layoutEngine,true,this);
	this.resizeDragActive=true;
}

/// Callback to wrap up window resize event 
ClientMethod endDrag(engine, wrapper) [ Language = javascript ]
{
	var thisDiv=this.getEnclosingDiv();
	if (this.coverplate) this.coverplate.style.display="none";
	if (thisDiv.layoutMgr.maskPeers) thisDiv.layoutMgr.maskPeers(thisDiv.layoutEngine,false);
	this.resizeDragActive=false;
    thisDiv.layoutMgr.layoutBlock(thisDiv.layoutEngine);
    this.syncObject();
    ZLM.notifyResize(thisDiv);
	this.onresizeHandler();
}

/// Callback to limit horizontal resizing
ClientMethod constrainDragX(engine, wrapper, intendedX) [ Language = javascript ]
{
	var thisDiv=this.getEnclosingDiv();
	var pad = parseInt(this.imageResizeSize)+1;
	var x = parseInt(intendedX)+ pad;
	if (x<thisDiv.minWidth) x = thisDiv.minWidth;
	thisDiv.prefWidth=x;
    return(x-pad);
}

/// Callback to limit vertical resizing
ClientMethod constrainDragY(engine, wrapper, intendedY) [ Language = javascript ]
{
	var thisDiv=this.getEnclosingDiv();
	var pad = parseInt(this.imageResizeSize)+1;
	var y = parseInt(intendedY)+pad;
	if (y<thisDiv.minHeight) y = thisDiv.minHeight;
	thisDiv.prefHeight=y;
	this.resize(thisDiv.prefWidth,thisDiv.prefHeight);
	thisDiv.layoutMgr.layoutBlock(thisDiv.layoutEngine);
	return(y-pad);
}

/// Return the HTML div element reserver for user content in the header of this group.
ClientMethod getHeaderUserDiv() [ Language = javascript ]
{
	return this.userDiv;
}

/// Return the HTML div element needed as a cover plate for event management under
/// certain versions of IE
ClientMethod getCoverplateDiv() [ Language = javascript ]
{
	return this.findElement('coverplate');
}

/// Return the HTML div element that wraps the header of this group.
ClientMethod getHeaderDiv() [ Language = javascript ]
{
	return this.findElement('header');
}

/// Return the HTML div element that wraps the children of this group.
ClientMethod getChildDiv() [ Language = javascript ]
{
	return this.findElement('children');
}

/// Return the internal width of the drag window in pixles
ClientMethod getWindowWidth() [ Language = javascript ]
{
	var div =this.getEnclosingDiv();
	if (!div) return(0);

	return(div.clientWidth);
}

/// Return the internal height of the drag window in pixles
ClientMethod getWindowHeight() [ Language = javascript ]
{
	var e = this.getEnclosingDiv();
	if (!e) return(0);
	var d = this.findElement('header');
	if (!d) return(0);
	var h = ZLM.getClientHeight(e);
	if (!this.headerRemoved) h = h - ZLM.getOffsetHeight(d);
	return(h);
}

/// Generic method to receive client "broadcast" messages.  Subclasses
/// can override this to extend the broadcast functionality.
ClientMethod processAppMessage(value) [ Language = javascript ]
{
}

ClientMethod applyCSSSettings(div, value) [ Language = javascript ]
{
	if (!div) return;
	var nodeStyle = div.style;
	if (!nodeStyle) return;
	var v = value;
	if (typeof(value)=="string") {
		if (value.indexOf("{")==0) { // assume JSON 
				v = ZLM.jsonParse(value);
				if (!v) return;
		}
		else { // assume a CSS snippet, need to nornalize to JavaScript conventions
			v = {};
			var nvp = value.split(";");
			for (var i=nvp.length-1;i>=0;i--) {
				var item = nvp[i];
				if (item && item.indexOf && item.indexOf(":")>0) {
					var nvpA = item.split(":");
					var attrValue = nvpA[1];
					var attrCSS = nvpA[0];
					if (attrCSS && attrCSS.indexOf("-")>0) {
						var attrA = attrCSS.split("-");
						attrCSS = attrA[0]+attrA[1].charAt(0).toUpperCase()+attrA[1].substring(1);
					}
					if (attrCSS) v[attrCSS]=attrValue;
				}
			}
		}
	}
	for (var p in v) {
		nodeStyle[p] = v[p];
	}
	this.adjustChildArea();
	this.onresizeHandler();
}

/// Set the CSS styles of the header section of the element.  
/// The value passed may take one of three forms: 
/// It can be a CSS Snippet in a string "background-color:#0000ff;font-weight:bold;"
/// It can be a JSON string abiding by JavaScript's CSS conventions "{'backgroundColor':'#0000ff', 'fontWeight':'bold' }"
/// Or it can be an actual javascript object {backgroundColor:'#0000ff', fontWeight:'bold'}
ClientMethod setHeaderStyle(value) [ Language = javascript ]
{
	this.applyCSSSettings(this.getHeaderDiv(),value);
}

/// Set the CSS styles of the header section of the element
/// The value passed may take one of three forms: 
/// It can be a CSS Snippet in a string "background-color:#0000ff;font-weight:bold;"
/// It can be a JSON string abiding by JavaScript's CSS conventions "{'backgroundColor':'#0000ff', 'fontWeight':'bold' }"
/// Or it can be an actual javascript object {backgroundColor:'#0000ff', fontWeight:'bold'}
ClientMethod setBodyStyle(value) [ Language = javascript ]
{
	this.applyCSSSettings(this.getEnclosingDiv(),value);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'header':
		this.header = value;
		this.renderHeader();
		break;
	case 'appLogo': 
		this.setAppLogo(value,value2);
		break;
	case 'imageClose':
		this.setCloseIcon(value,value2);
		break;
	case 'imageCloseHover':
		this.imageCloseHover = value;
		break;
	case 'imageMinimize':
		this.setMinimizeIcon(value,value2);
		break;
	case 'imageMinimizeHover':
		this.imageMinimizeHover = value;
		break;
	case 'imageMaximize':
		this.setMaximizeIcon(value,value2);
		break;
	case 'imageMaximizeHover':
		this.imageMaximizeHover = value;
		break;
	case 'imageExpand':
		this.setExpandIcon(value,value2);
		break;
	case 'imageExpandHover':
		this.imageExpandHover = value;
		break;
	case 'imageContract':
		this.setContractIcon(value,value2);
		break;
	case 'imageContractHover':
		this.imageContractHover = value;
		break;
	case 'colSpan':
		this.colSpan = value;
//Update controller
		break;
	case 'rowSpan':
		this.rowSpan = value;
//Update controller
		break;
	case 'homeRow':
		this.homeRow = value;
//Update controller
		break;
	case 'homeCol':
		this.homeCol = value;
//Update controller
		break;
	case 'centerLayout':
		this.setCenterLayout(value);
		break;
	case 'headerLayout':
		this.setHeaderLayout(value);
		break;
	case 'onresize':
		this.onresize = value;
		break;
	case 'onclosepending':
		this.onclosepending = value;
		break;
	case 'onwindowgrab':
		this.onwindowgrab = value;
		break;
	case 'onwindowdrop':
		this.onwindowdrop = value;
		break;
	case 'resizeEnabled':
		this.resizeEnabled = value;
		if (value) this.enableResize();
		else this.disableResize();
		break;
	case 'moveEnabled':
		this.moveEnabled = value;
		if (value) this.enableDrag();
		else this.disableDrag();
		break;
	case 'minWidth':
		this.minWidth = value;
		var d = this.getEnclosingDiv();
		if (d) d.minWidth = parseInt(this.minWidth,10);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

ClientMethod onresizeHandler() [ Language = javascript ]
{
	if (this.onresize) zenInvokeCallbackMethod(this.onresize,this,'onresize');
}

}
