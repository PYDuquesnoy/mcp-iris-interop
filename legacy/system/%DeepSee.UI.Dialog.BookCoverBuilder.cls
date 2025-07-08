/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This dialog lets the user create or edit a DeepSee Book Cover filter definition.<br/>
Class %DeepSee.UI.Dialog.BookCoverBuilder Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cover spec. This is the string that describes the book cover.
Property coverSpec As %ZEN.Datatype.string(ZENURL = "SPEC");

/// Which element is selected.
Property selectedElement As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

#dsCovers {
	width: 200px;
	height: 300px;
}

.ztb-menuBar {
	background: rgb(53,107,141);
	filter: none;
}

.ztb-caption-1 {
	height: 14px;
	font-size: 12px;
	padding-left: 10px;
	padding-right: 10px;
}

.ztb-menuItemSelected-1 {
	background: white;
	border-top: 1px solid #404040;
	border-left: 1px solid #404040;
	border-right: 1px solid #404040;
	border-bottom: 1px solid #F0F0F0;
	border-top-left-radius: 10px;
	border-top-right-radius: 10px;
}

td.ztb-choiceSelected {
	background: white;
	color: black;
	opacity: 1.0;
	font-size:12px;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">

<jsonProvider id="imageList" OnGetArray="GetImageList"/>
<jsonProvider id="json" OnGetArray="GetCoverList"/>


<hgroup id="mainGroup" cellVAlign="top">
<navigator id="navigator" 
headerHeight="40"
 showDisclosure="true"
 onexpand="zenPage.onlayoutHandler(false);"
onchange="zenPage.dataChange(key,value,final);"
onselect="zenPage.selectItem(key,value);"
onbuttonclick="zenPage.headerButtonClick(key);"
onclosebuttonclick="zenPage.closeButtonClick(key);"
ongetcontent="return zenPage.getContentForLevel(level,key,value);"/>

<vgroup>
<toolbar id="toolbar" ongetdata="return zenPage.getToolbarData();" onselect="zenPage.toolbarSelect(key);" onchange="zenPage.toolbarChange(key,value);" selectedIndex="1"/>
<deepsee:coverView id="dsCovers" designMode="true" controllerId="json" onselectelement="return zenPage.selectElement(which);"/>
</vgroup>

</hgroup>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Book Cover Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create or modify book covers")
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		// reveal
		var main = zen('mainGroup');
		if (main) {
			var div = main.getEnclosingDiv();
			div.style.opacity = 1.0;
		}

		var covers = zen('dsCovers');
		covers.selectCover(0,true);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Add cover spec to undo buffer.
ClientMethod addUndo(spec) [ Language = javascript ]
{
	if (!this._undoStack) {
		this._undoStack = [];
	}

	this._undoStack[this._undoStack.length] = spec;
}

/// Undo the last change.
ClientMethod undo() [ Language = javascript ]
{
	if (this._undoStack && this._undoStack.length>0) {
		var spec = this._undoStack[this._undoStack.length-1];
		this._undoStack.length--;
		var cover = zen('dsCovers');
		var book = cover.getCoverObject(cover.selectedIndex);
		book.spec = spec;
		cover.setCoverObject(cover.selectedIndex,book);
		this.coverSpec = spec;
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	return true;
}

/// Get return value for dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.coverSpec;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// add buttons to dialog buttons
		Set tGroup = ..%GetComponentById("buttonHolder")
		Set tCancel = ..%GetComponentById("btnCancel")
		If ($IsObject(tGroup)&&$IsObject(tCancel)) {
			Set tButton = ##class(%ZEN.Component.button).%New()
			Set tButton.caption = $$$Text("Undo","%DeepSee")
			Set tButton.title = $$$Text("Undo last change","%DeepSee")
			Set tButton.controlClass="commandButton"
			Set tButton.onclick="zenPage.undo();"
			Do tGroup.%AddChildBefore(tButton,tCancel)

			Set tSpacer = ##class(%ZEN.Component.spacer).%New()
			Set tSpacer.width = 20
			Do tGroup.%AddChildBefore(tSpacer,tCancel)

			Set tButton = ##class(%ZEN.Component.button).%New()
			Set tButton.caption = $$$Text("Upload Image","%DeepSee")
			Set tButton.title = $$$Text("Upload a new image","%DeepSee")
			Set tButton.controlClass="commandButton"
			Set tButton.onclick="zenPage.uploadImage();"
			Do tGroup.%AddChildBefore(tButton,tCancel)

			Set tSpacer = ##class(%ZEN.Component.spacer).%New()
			Set tSpacer.width = 20
			Do tGroup.%AddChildBefore(tSpacer,tCancel)

			Set tButton = ##class(%ZEN.Component.button).%New()
			Set tButton.caption = $$$Text("Clear","%DeepSee")
			Set tButton.title = $$$Text("Clear the bookcover","%DeepSee")
			Set tButton.controlClass="commandButton"
			Set tButton.onclick="zenPage.clearCover();"
			Do tGroup.%AddChildBefore(tButton,tCancel)

			Set tSpacer = ##class(%ZEN.Component.spacer).%New()
			Set tSpacer.width = 20
			Do tGroup.%AddChildBefore(tSpacer,tCancel)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Adjust sizes components on the page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);
	var body = zen('body');
	var divBody = body.getEnclosingDiv();

	var width = divBody.offsetWidth;
	var height = divBody.offsetHeight;

	var navigator = zen('navigator');
	navigator.setHeight(height - 25);

	var toolbar = zen('toolbar');
	toolbar.setWidth(width - navigator.getWidth() - 25);
	var toolbarH = toolbar.getEnclosingDiv().offsetHeight;

	var coverView = zen('dsCovers');
	var divCover = coverView.getEnclosingDiv();
	divCover.style.height = (height-25 - (toolbarH)-2) + 'px';
	divCover.style.width = (width - navigator.getWidth() - 25-2) + 'px';
}

/// Get list of book covers for JSON provider.
Method GetCoverList(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		// return 1 object based on the current spec.
		Set pMetaData = $LB("category","title","spec","tooltip")

		Set tCoverSpec = ..coverSpec
		If (tCoverSpec="") {
			// default cover
			Set tCoverSpec = "{background: {style:'background:white;'},header: {text:'<Header>'},footer: {text:'<Footer>'},title: {text:'<Title>'},image: {src:'covers/book_128.gif'}}"
		}
		Set pData($I(n)) = $LB("Covers","DeepSee",tCoverSpec)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get list of available images.
ClientMethod getCoverImages() [ Language = javascript ]
{
	var list = [];
	var data = zen('imageList').getContentObject();
	if (data && data.children) {
		list = data.children;
	}
	return list;
}

/// Get list of images in the covers directory for JSON provider.
ClassMethod GetImageList(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMetaData = $LB("path","name")
		
		Set tFileTypes("jpg") = 1
		Set tFileTypes("png") = 1
		Set tFileTypes("gif") = 1

		// Get all files in covers directory (csp/broker/covers)
		Set tRS = ##class(%ResultSet).%New("%File:FileSet")
		Set tSC = tRS.Execute(..%GetImageDirectory(),"*.*")
		If $$$ISERR(tSC) Quit
		Set n = 0
		While(tRS.Next()) {
			// PFS016 - ItemName needs to be case sensitive for filesystems where this matters
			Set tName = tRS.Data("ItemName")
			Set tExt = $P(tName,".",$L(tName,"."))
			If $D(tFileTypes(tExt)) {
				Set pData($I(n)) = $LB("covers/"_tName,$P(tName,".",1))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// User click on element button.
ClientMethod selectElement(which, notify) [ Language = javascript ]
{
	notify = zenGet(notify,false);
	this.selectedElement = which;
	if (notify) {
		zen('dsCovers').selectElement(which);
	}

	// select tab
	if (which == '') {
		zen('toolbar').selectTab('');
	}
	else {
		zen('toolbar').selectTab('tab-' + which);
	}

	// update navigator
	var navigator = zen('navigator');
	navigator.refreshTopSheet();
	return true;
}

/// Return the physical directory in which cover images files are stored.
ClassMethod %GetImageDirectory() As %String [ CodeMode = expression ]
{
$SYSTEM.CSP.GetFileName("/csp/broker/covers/")
}

/// Get contents of toolbar.
ClientMethod getToolbarData() [ Language = javascript ]
{
	var cover = zen('dsCovers');
	var zoom = cover.zoomLevel + 'x';
	// contents of main menu
	var data = {
		children:[
			{ type:"tab", caption:$$$Text("Background"), key:"tab-background"},
			{ type:"tab", caption:$$$Text("Header"), key:"tab-header"},
			{ type:"tab", caption:$$$Text("Title"), key:"tab-title"},
			{ type:"tab", caption:$$$Text("Image"), key:"tab-image"},
			{ type:"tab", caption:$$$Text("Subtitle"), key:"tab-subtitle"},
			{ type:"tab", caption:$$$Text("Footer"), key:"tab-footer"},
			{ type:"spacer", style:"width:15px;"},
			{ type:"choice", key:"zoom", valueList:"1x,2x,3x", displayList:$$$Text("1x,2x,3x"), value:zoom, style:"width:100px;"}
		]
	};
	return data;
}

/// Click on toolbar item.
ClientMethod toolbarSelect(key) [ Language = javascript ]
{
	var t = key.toString().split('-');
	var k2 = t[0];
	switch(k2) {
	case 'tab':
		// tab-which
		zenPage.selectElement(t[1],true);
		break;
	case 'clear':
		zenPage.clearCover();
		break;

	case 'upload':
		zenPage.uploadImage();
		break;
	}
}

/// Change of toolbar value.
ClientMethod toolbarChange(key, value) [ Language = javascript ]
{
	switch(key) {
	case 'zoom':
		var cover = zen('dsCovers');
		var divCover = cover.getEnclosingDiv();
		var width = divCover.offsetWidth;
		var height = divCover.offsetHeight;
		var zoom = parseInt(value);
		cover.setProperty('zoomLevel',zoom);

		divCover.style.height = height + 'px';
		divCover.style.width = width + 'px';

		break;
	}
}

/// Show the upload image dialog.
ClientMethod uploadImage() [ Language = javascript ]
{
	var parms = {};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ImageUpload.zen','Upload','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Clear the cover spec.
ClientMethod clearCover() [ Language = javascript ]
{
	this.addUndo(this.coverSpec);
	this.coverSpec = '';

	// get current spec
	var specObj = null;
	var cover = zen('dsCovers');
	var book = cover.getCoverObject(cover.selectedIndex);
	if (book) {
		book.spec = this.coverSpec;
		cover.setCoverObject(cover.selectedIndex,book);
	}
}

/// Return an object describing what to display for this level.
ClientMethod getContentForLevel(level, key, value) [ Language = javascript ]
{
	var title = '';
	var content = { title: title, items:[] };
	var navigator = zen('navigator');

	if (this.selectedElement=='') {
		content.html = '<div style="padding:10px;font-size:20px;">' + $$$Text('Please select an element within the book cover.') + '</div>';
		return content;
	}

	// get details on selected item
	var cover = zen('dsCovers');
	var book = cover.getCoverObject(cover.selectedIndex);
	var spec = '';
	if (book) {
		spec = book.spec ? book.spec : '';
	}
	var specObject = cover.evalSpec(spec);
	if (!specObject[this.selectedElement]) {
		specObject[this.selectedElement] = {};
	}
	var text = zenGet(specObject[this.selectedElement].text);
	var style = zenGet(specObject[this.selectedElement].style);
	var image = zenGet(specObject[this.selectedElement].src);
	var which = this.selectedElement;

	// check for attributes
	var hasImage = false;
	var hasText = true;

	switch (which) {
	case 'background':
		hasImage = true;
		hasText = false;
		break;
	case 'image':
		hasImage = true;
		break;
	}

	switch (key) {
	case '':
		// root
		title = $$$Text('Settings','%DeepSee');

		// pull apart style from incoming value
		var info = navigator.parseStyle(style);
		var color = info.color;
		var background = info.backgroundColor;
		var fontFamily = info.fontFamily;
		var fontSize = info.fontSize;
		var align = zenGet(info.textAlign);
		var opacity = zenGet(info.opacity);
		opacity = opacity === '' ? 1.0 : opacity;

		var fs = [];
		if (info.bold) { fs[fs.length] = 'bold'; }
		if (info.underline) { fs[fs.length] = 'underline'; }
		if (info.italic) { fs[fs.length] = 'italic'; }
		//if (info.shadow) { fs[fs.length] = 'shadow'; }
		if (info.smallCaps) { fs[fs.length] = 'smallCaps'; }
		var fontStyle = fs.join(',');

		var radius = zenGet(info.radius);
		var displayed = zenGet(info.displayed,true);

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Visible','%DeepSee'), value:displayed,	edit:'switch', key:which+'-displayed'};
		if (hasText) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text','%DeepSee'), value:text,	edit:'string', action:'drill', key:which+'-text'};
		}
		if (hasImage) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image','%DeepSee'), value:image, edit:'string',	action:'drill', key:'image'};
		}

		if (hasText) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%DeepSee'), action:'drill', value:'',	key:which+'-color', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+color+';'};
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', value:'',	key:which+'-background', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'};
		if (hasText) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill', value:fontFamily,	key:which+'-font-family', valueStyle:'font-size:13px;font-family:'+fontFamily+';'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size','%DeepSee'), edit:'slider-toggle', value:fontSize,	key:which+'-font-size', minValue:2, maxValue:75, stepSize:1};

			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%DeepSee'), edit:'choice-multi', value:fontStyle,	key:which+'-style', valueList:'bold,italic,smallCaps,shadow', displayList:'B,I,Cc,S', valueStyle:'font-size:12px;font-family:times new roman;',  choiceStyles:'font-weight:900;^font-style:italic;^font-variant:small-caps;^text-shadow:1px 1px 2px #F0F0F0;'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Align','%DeepSee'), edit:'choice', value:align,	key:which+'-text-align', valueList:'left,center,right', displayList:'&#9664;,&#9632;,&#9654;'};
		}

		if (which=='background') {
			content.items[content.items.length] = {display:'caption', caption:$$$Text('Make Image Full Size','%DeepSee'), action:'select',	key:which+'-fullSize', style:'color:darkblue;'};
		}

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Top','%DeepSee'), edit:'slider-toggle', value:zenGet(info.top),	key:which+'-top', minValue:-50, maxValue:200};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Left','%DeepSee'), edit:'slider-toggle', value:zenGet(info.left),	key:which+'-left', minValue:-50, maxValue:200};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Height','%DeepSee'), edit:'slider-toggle', value:zenGet(info.height),	key:which+'-height', minValue:0, maxValue:200};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width','%DeepSee'), edit:'slider-toggle', value:zenGet(info.width),	key:which+'-width', minValue:0, maxValue:200};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Margin','%DeepSee'), edit:'slider', value:zenGet(info.margin),	key:which+'-margin', minValue:0, maxValue:25};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Padding','%DeepSee'), edit:'slider', value:zenGet(info.padding),	key:which+'-padding', minValue:0, maxValue:25};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:opacity,	key:which+'-opacity', minValue:0, maxValue:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Radius','%DeepSee'), edit:'slider', value:radius,	key:which+'-border-radius', minValue:0, maxValue:50};
		break;

	case 'image':
		title = $$$Text('Images','%DeepSee');
		var images = this.getCoverImages();
		var list = [];
		list[list.length] = { image:'', value:'' };
		for (var n = 0; n < images.length; n++) {
			list[list.length] = { image:images[n].path, value:images[n].path };
		}
		content.html = navigator.getIconListHTML(list,key,image);
		break;

	case 'background-color':
	case 'image-color':
	case 'title-color':
	case 'subtitle-color':
	case 'header-color':
	case 'footer-color':
		// choose a color
		title = $$$Text('Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'background-background':
	case 'image-background':
	case 'title-background':
	case 'subtitle-background':
	case 'header-background':
	case 'footer-background':
		// choose a color
		title = $$$Text('Background','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'background-font-family':
	case 'image-font-family':
	case 'title-font-family':
	case 'subtitle-font-family':
	case 'header-font-family':
	case 'footer-font-family':
		title = $$$Text('Font','%DeepSee');
		content.html = navigator.getFontChooserHTML(key,value);
		break;

	case 'background-text':
	case 'image-text':
	case 'title-text':
	case 'subtitle-text':
	case 'header-text':
	case 'footer-text':
		title = $$$Text('Text','%DeepSee');

		// list of $vars
		var list = [
			{ caption:$$$Text('Title','%DeepSee'), value:'$title', hint:$$$Text('Use the item title','%DeepSee')},
			{ caption:$$$Text('Category','%DeepSee'), value:'$category', hint:$$$Text('Use the item category','%DeepSee')},
			{ caption:$$$Text('Type','%DeepSee'), value:'$type', hint:$$$Text('Use the item type','%DeepSee')},
		];

		content.html = navigator.getChooserListHTML(list,key,zenGet(''),$$$Text('Text Tags','%DeepSee'),$$$Text('These special tags are replaced with actual values.','%DeepSee'));
		break;
	}
	content.title = title;
	return content;
}

/// Item selected in navigator.
ClientMethod selectItem(key, value) [ Language = javascript ]
{
	var navigator = zen('navigator');

	switch(key) {
	case 'background-fullSize':
		// get current spec
		var specObj = null;
		var cover = zen('dsCovers');
		var book = cover.getCoverObject(cover.selectedIndex);
		if (book) {
			specObj = cover.evalSpec(book.spec);
		}
		if (!specObj) return;

		var element = specObj.background;
		if (!element) {
			element = {};
			specObj.background = element;
		}

		element.imageStyle = navigator.setStyleIntoCSS(zenGet(element.imageStyle),'width','134px');
		element.imageStyle = navigator.setStyleIntoCSS(zenGet(element.imageStyle),'height','190px');

		// update cover
		this.addUndo(this.coverSpec);

		var bookSpec = cover.specToString(specObj);
		book.spec = bookSpec;
		cover.setCoverObject(cover.selectedIndex,book);
		this.coverSpec = bookSpec;
		break;
	}
}

/// Button clicked in navigator header.
ClientMethod headerButtonClick(key) [ Language = javascript ]
{
}

/// Button clicked in navigator close button.
ClientMethod closeButtonClick(key) [ Language = javascript ]
{
}

/// This is called when a data value within the navigator is changed.
/// <var>key</var> is the key for the item and <var>value</var> is the new value.
/// <var>final</var> is true if this is the final value (controls such as a slider
/// may provide intermediate values as well while the user is actively dragging it).
ClientMethod dataChange(key, value, final) [ Language = javascript ]
{
	var navigator = zen('navigator');

	var which = this.selectedElement;

	// key is which-element
	// use selectedElement in case user has clicked on a new item.
	var t = key.toString().split('-');
	if (t.length>1) {
		t.splice(0,1);
	}
	var k2 = t.join('-');

	// get current spec
	var specObj = null;
	var cover = zen('dsCovers');
	var book = cover.getCoverObject(cover.selectedIndex);
	if (book) {
		specObj = cover.evalSpec(book.spec);
	}
	if (!specObj) return;

	var element = specObj[which];
	if (!element) {
		element = {};
		specObj[which] = element;
	}

	switch (k2) {
	case 'text':
		element.text = value;
		break;

	case 'image':
		element.src = value;
		break;

	case 'color':
	case 'background':
	case 'font-family':
	case 'opacity':
	case 'displayed':
	case 'text-align':
		element.style = navigator.setStyleIntoCSS(zenGet(element.style),k2,value);
		break;

	case 'style':
		var styleValues = {};
		var cv = value.toString().split(',');
		for (var n = 0; n < cv.length; n++) {
			styleValues[cv[n]] = true;
		}
		var list = ['bold','underline','italic','shadow','smallCaps'];
		for (var n = 0; n < list.length; n++) {
			element.style = navigator.setStyleIntoCSS(zenGet(element.style),list[n],styleValues[list[n]]?true:false);
		}
		break;

	case 'border-radius':
	case 'font-size':
	case 'padding':
	case 'margin':
	case 'top':
	case 'left':
	case 'height':
	case 'width':
		value = value!=='' ? value+'px' : value;
		element.style = navigator.setStyleIntoCSS(zenGet(element.style),k2,value);
		if (which=='image' || which=='background') {
			if (k2=='width' || k2=='height' || k2=='border-radius') {
				element.imageStyle = navigator.setStyleIntoCSS(zenGet(element.imageStyle),k2,value);
			}
		}
		break;
	}

	// update cover
	if (final) {
		this.addUndo(this.coverSpec);
	}
	var bookSpec = cover.specToString(specObj);
	book.spec = bookSpec;
	cover.setCoverObject(cover.selectedIndex,book);
	if (final) {
		this.coverSpec = bookSpec;
	}
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'Upload':
		zen('imageList').reloadContents();
		break;
	}
}

}
