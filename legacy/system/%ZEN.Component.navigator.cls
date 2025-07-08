/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The navigator component creates a combination navigation and simple settings
/// interface similar to that found on mobile devices.<br/>
/// This is an HTML5 component; it will only work correctly on HTML5 compliant browsers.
/// 
Class %ZEN.Component.navigator Extends %ZEN.Component.group [ Deprecated, System = 3 ]
{

/// Localization domain
Parameter DOMAIN = "%ZEN";

Parameter DEFAULTENCLOSINGCLASS = "navWrapper";

/// ongetcontent event handler:
/// This defines the client-side code that defines
/// the content of a "sheet" within this component.<br/>
/// This is passed <var>level</level>, <var>key</var>, and <var>value</var> as arguments.
/// This code should return an object with any of the following properties:<br/>
/// <var>title</var>-the title to display for the sheet.<br/>
/// <var>url</var>-if defined, the url to display as an iframe within the sheet (in the same domain).<br/>
/// <var>html</var>-custom html to display within the sheet.<br/>
/// <var>childIndex</var>-index number (0-based) of child of this component to display.<br/>
/// <var>items</var>-array of javascript objects used to define the contents.<br/>
Property ongetcontent As %ZEN.Datatype.eventHandler;

/// onchange event handler:
/// Notification that a control within the property sheet has changed value.
/// This event is passed 3 arguments: <var>key</var>, <var>value</var>, and <var>final</var>.
/// <var>final</var> is true when a value is finished changing (such as when the user stops
/// pressing a stepper button).
Property onchange As %ZEN.Datatype.eventHandler;

/// onarrange event handler:
/// Notification that the order of items in the current sheet has changed.
/// This event is passed 3 arguments: <var>key</var>, <var>swap</var>, and <var>final</var>.
/// <var>final</var> is true when a value is finished changing.
/// <var>swap</var> is an object with the property index and newIndex, containg the index of the 
/// item to move and its new location.
Property onarrange As %ZEN.Datatype.eventHandler;

/// onindent event handler:
/// Notification that the indentation level of an item in the current sheet has changed.
/// This event is passed 3 arguments: <var>key</var>, <var>list</var>, and <var>final</var>.
/// <var>final</var> is true when a value is finished changing.
/// <var>list is a an array containing the new ordinal positions of the items.
Property onindent As %ZEN.Datatype.eventHandler;

/// onselect event handler:
/// Notification that a new choice has been selected within the property sheet.
/// This is also called when a "drill" item is selected.
/// This event is passed 3 arguments: <var>key</var>, <var>value</var>, and <var>which</var>.
/// <var>which</var> is "select" or "drill".
Property onselect As %ZEN.Datatype.eventHandler;

/// onexpand event handler:
/// Notification that the user has expanded or contracted this component.
Property onexpand As %ZEN.Datatype.eventHandler;

/// onbuttonclick event handler:
/// Notification that the user has clicked on a "header" or "footer" button.
Property onbuttonclick As %ZEN.Datatype.eventHandler;

/// onclosebuttonclick event handler:
/// Notification that the user has clicked on an "close" button for an item.
Property onclosebuttonclick As %ZEN.Datatype.eventHandler;

/// onpopupaction event handler:
/// Notification that the user has invoked and applied a popup for an item. 
Property onpopupaction As %ZEN.Datatype.eventHandler;

/// Indicates how many levels deep the navigator is scrolled.
Property currLevel As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

/// Width of columns (in pixels).
/// Keep at 320 for best results.
Property columnWidth As %ZEN.Datatype.integer [ InitialExpression = 320 ];

/// Height of header (in pixels).
/// Keep at 40 for best results.
Property headerHeight As %ZEN.Datatype.integer [ InitialExpression = 40 ];

/// Height of footer (in pixels). Set to 0 for no footer.
/// Set to 40 to show footer with best results.
Property footerHeight As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// If true, show the disclosure bar on the left.
Property showDisclosure As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Width of the disclosure bar on the left.
Property disclosureWidth As %ZEN.Datatype.integer [ InitialExpression = 24 ];

/// If true, show slider values next to the control 
Property showSliderValue As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, then show the navigator; otherwise it is contracted.
Property expanded As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Current color set.
Property currColorSet As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = "deepsee" ];

/// Logical names of color sets.
Property colorSetNames As list Of %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

/// Captions of color sets.
Property colorSetCaptions As list Of %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

/// List of ;-delimited color set values for drop down.
Property colorSets As list Of %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

/// Style to apply to navigator background.
Property backgroundStyle As %ZEN.Datatype.style;

/// Pass current language to client.
Property language As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Warning tooltip message for delete options
Property deleteThisItemMsg As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete this item","%ZEN")} ];

/// Warning tooltip message for open options
Property openThisItemMsg As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Open this item","%ZEN")} ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* wrapper around entire control */
.navWrapper {
	position: relative;
	background: #F0F0F0;
	padding: 0px;
	margin: 0px;
	width: 320px;
	height: 480px;
	overflow: hidden;
	border: none;
	opacity: 0.0;
	color: #404040;
	font-size: 8pt;
	font-family : HelveticaNeue,Helvetica, Arial;

	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	-ms-user-select: none;
	user-select: none;

	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;

	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	transition-property: opacity;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

/* background of navigator */
.navBackground {
	position: absolute;
	top: 0px;
	left: 0px;
	background-repeat: no-repeat;
}

/* disclosure bar */
.navDisclosureBar {
	position: absolute;
	top: 0px;
	width: 20px;
	overflow: hidden;
	background: rgb(220,231,241);

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;

	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	transition-property: background;
	transition-duration: 0.5s;
	transition-timing-function: ease;

	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-ms-user-select: none;
	-o-user-select: none;
	user-select: none;
}

.navDisclosureBar:hover {
	background: #F0F0F0;
}

/* disclosure icon */
.navDisclosureIcon {
	position: absolute;
	width: 16px;
	left: 2px;
}

/* wrapper for master panel: this displays the current panel */
.navMasterPanel {
	position: absolute;
	top: 0px;
	width: 320px;
	border: 1px solid #808080;
	overflow: hidden;

	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	-ms-user-select: none;
	user-select: none;
}

/* "Tray" within master panel containing all detail items. */
.navMasterTray {
	position: absolute;

	-webkit-transition-property: left;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;

	-moz-transition-property: left;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	transition-property: left;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

/* contents of a panel: header,body, and footer */
.navPanel {
	position: absolute;
	top: 0px;
	overflow-x: hidden;
	overflow-y: hidden;
}

.navHeader,
.navFooter {
	height: 40px;
	position: relative;
	border-bottom: 1px solid white;
	padding: 2px;
	font-size: 10pt;
	color: #F0F0F0;
	box-shadow: none;
	text-shadow: 1px 1px 2px #808080;
	overflow: hidden;

	background: rgb(53,107,141);
	background: -moz-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* FF3.6+ */
	background: -webkit-linear-gradient(top,  rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* IE10+ */
	background: linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* W3C */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#cedce7', endColorstr='#596a72',GradientType=0 ); /* IE6-9 */
}

/* body within a panel */
.navBody {
	position: relative;
	top: 0px;
	overflow-x: hidden;
	overflow-y: auto;
}

.navItem, .navItemSelected {
	position: relative;
	height: 40px;
	border-bottom: 1px solid white;
	padding: 2px;
	background: none;
	color: #404040;
	box-shadow: none;
	overflow: hidden;
	cursor: pointer;
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;

	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	transition-property: background;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

.navItemSelected {
	color: #F0F0F0;
	background: rgb(93,147,181);
}

.navItem:hover {
	background: #E8E8E8;
}
	
.navItemSelected:hover {
	color: white;
	background: rgb(53,107,161);
}

/* image in header bar */
.navHeaderIcon {
	width: 16px;
	height: 16px;
	opacity: 0.8;
}

.navHeaderIcon:hover {
	opacity: 1.0;
}


/* image in icon list */
.navIconList,
.navIconListSelected,
.navIconListDisabled {
	float: left;
	position: relative;
	width: 66px;
	height: 66px;
	border: 3px solid transparent;
	border-radius: 6px;
	padding: 3px;

	opacity: 0.75;
	-webkit-transition-property: opacity,background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity,background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
	transition-property: opacity,background;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

.navIconList img,
.navIconListSelected img,
.navIconListDisabled img {
	width: 64px;
	height: 64px;
}

.navIconList:hover {
	opacity: 1.0;
	background: #FFEEAA;
}

.navIconListSelected {
	background: white;
	border: 3px solid rgb(53,107,141);
	opacity: 1.0;
}

/* + WAL083 (4) -- if also a multiselect icon, color the background */
.navIconListSelected.navMultiSelectIconListSelected {
	background: #FFEEAA;
}
/* - WAL083 (4) */

.navIconListDisabled {
	opacity: 0.2;
}

/* image within cell */
.navItemImage {
	position: absolute;
	top: 4px;
	left: 4px;
}

.navItemImage img {
	height: 32px;
	width: 32px;
}

/* provide background for images in selected items */
.navItemSelected .navItemImage img {
	background: #D0D0D0;
	border-radius: 5px;
}

/* style for sections */
.navSection, .navSectionSelected {
	position: relative;
	height: 40px;
	border-bottom: 1px solid white;
	padding: 2px;
	background: #C0C0C0;
	color: #606060;
	overflow: hidden;
	text-align: center;
	text-shadow:#fff 0px 1px 0, #000 0 -1px 0;

	background: rgb(200,200,200);
	background: -moz-linear-gradient(top, rgb(180,180,180) 0%,rgb(200,200,200) 20%,rgb(200,200,200) 80%,rgb(180,180,180) 100%);
	background: -webkit-linear-gradient(top,  rgb(180,180,180) 0%,rgb(200,200,200) 20%,rgb(200,200,200) 80%,rgb(180,180,180) 100%);
	background: -o-linear-gradient(top,  rgb(180,180,180) 0%,rgb(200,200,200) 20%,rgb(200,200,200) 80%,rgb(180,180,180) 100%);
	background: -ms-linear-gradient(top,  rgb(180,180,180) 0%,rgb(200,200,200) 20%,rgb(200,200,200) 80%,rgb(180,180,180) 100%);
	background: linear-gradient(top,  rgb(180,180,180) 0%,rgb(200,200,200) 20%,rgb(200,200,200) 80%,rgb(180,180,180) 100%);
}

/* style for info boxes */
.navInfo {
	position: relative;
	height: 40px;
	border-bottom: 1px solid white;
	padding: 2px;
	background: rgb(255,255,255);/*fallback*/
	background: rgba(255,255,255,0.75);
	color: #606060;
	overflow: hidden;
}

/* base style for item captions; adjusted by specific items */
.navItemCaption, .navItemCaptionDisabled,
.navItemInfoCaption,
.navSectionCaption, .navSectionCaptionDisabled {
	position: absolute;
	font-size: 16px;
	font-weight: bold;
	padding-left: 5px;
	padding-top: 5px;
	overflow: hidden;
	white-space: nowrap;
	text-wrap: none;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

.navItem .navItemCaption:hover {
	color: #4040D0;
}

.navItem:active {
	background: #F8F8F8;
	box-shadow: 3px 3px 25px #FFF8F8,-3px -3px 25px #F8F8FF;
}

.navItemCaptionDisabled {
	color: #A0A0A0;
}

.navSectionCaption, .navSectionCaptionDisabled {
	color: #606060;
	font-weight: normal;
}

.navItemInfoCaption {
	color: rgb(53,107,141);
	font-style: italic;
	font-size: 14px;
}

/* base style for item values; adjusted by specific items */
.navItemValue, .navItemValueHz, 
.navItemInfoValue,
.navItemHint,.navItemHintSelected {
	position: absolute;
	font-size: 10px;
	font-weight: bold;
	padding-left: 5px;
	padding-top: 4px;
	overflow: hidden;
	white-space: nowrap;
	text-wrap: none;
}

.navItemValueHz {
	font-size: 18px;
}

.navItemHint {
	color: #606060;
	white-space: normal;
	text-wrap: normal;
}

.navItemHintSelected {
	color: #F0F0F0;
	white-space: normal;
	text-wrap: normal;
}

.navItemInfoValue {
	color: #606060;
	white-space: normal;
	text-wrap: normal;
	font-style: italic;
}

.navItemCheckMark {
	position: absolute;
	top: 12px;
	left: 0px;
	width: 16px;
}

.navItemDrillDown {
	position: absolute;
	top: 12px;
	right: 24px;
	width: 16px;
}

.navItemPopup {
	position: absolute;
	top: 12px;
	right: 24px;
	width: 16px;
	opacity: 0.8;
}

.navItemPopup:hover {
	position: absolute;
	top: 12px;
	right: 24px;
	width: 16px;
	opacity: 1.0;
}

.navItemPopup:active {
	background: white;
	box-shadow: 1px 1px 5px white,-1px -1px 5px white;
}

.navItemDragHandle {
	position: absolute;
	top: 8px;
	left: 0px;
	opacity: 0.6;
	text-align: center;
	border-radius: 4px;
	-webkit-transition-property: opacity,background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity,background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
	transition-property: opacity,background;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

.navItemDragHandle:hover{
	opacity: 1.0;
}

.navItemDragHandle:hover img{
	background: #F0F0FF;
	border: 1px solid #808080;
	border-radius: 4px;
}

.navItemCloseBtn {
	position: absolute;
	top: 10px;
	right: 46px;
	padding: 2px;
	opacity: 0.8;
}

.navItemCloseBtn:hover {
	background-color: #dd0000;
	opacity: 1.0;
}

.navItemCloseBtn:active {
	background: white;
	box-shadow: 1px 1px 5px white,-1px -1px 5px white;
}

.navItemOpenBtn {
	position: absolute;
	top: 12px;
	right: 20px;
	padding: 2px;
	opacity: 0.8;
}

.navItemOpenBtn:hover {
	background-color: #69b4ff;
	opacity: 1.0;
}

.navControlWrap {
	position: relative;
	height: 24px;
	border: 1px solid #D0D0D0;
	white-space: nowrap;
	text-overflow: ellipsis;
	overflow: hidden;
}

.navControlWrap:hover {
	border: 1px solid #808080;
}

.navControl {
	position: absolute;
	top: 0px;
	bottom: 0px;
	left: 0px;
	font-size: 10px;
	background: white;
	border: 1px solid #808080;
}

.navControlBtn {
	position: absolute;
	top: 4px;
	width: 16px;
	height: 16px;
	opacity: 0.75;
}

.navControlBtn:hover {
	opacity: 1.0;
}

.navTitle {
	font-size: 18px;
	font-weight: bold;
}

.navArrow {
	fill: white;
	stroke: #808080;
	opacity: 0.75;
}

.navArrow:hover {
	fill: #FFEEAA;
	stroke: #808080;
	opacity: 1.0;
}

.navSliderTxt {
	position: absolute;
	width: 30px;
	border-radius:5px;
	font-size:12px;
	font-weight:bold;
}

.navSwitch,
.navSliderThumb {
	position: absolute;
	background: #beccd7; /* Old browsers */
	background: -moz-radial-gradient(center, ellipse cover,  #beccd7 0%, #596a72 100%); /* FF3.6+ */
	background: -webkit-gradient(radial, center center, 0px, center center, 100%, color-stop(0%,#beccd7), color-stop(100%,#596a72)); /* Chrome,Safari4+ */
	background: -webkit-radial-gradient(center, ellipse cover,  #beccd7 0%,#596a72 100%); /* Chrome10+,Safari5.1+ */
	background: -o-radial-gradient(center, ellipse cover,  #beccd7 0%,#596a72 100%); /* Opera 12+ */
	background: -ms-radial-gradient(center, ellipse cover,  #beccd7 0%,#596a72 100%); /* IE10+ */
	background: radial-gradient(center, ellipse cover,  #beccd7 0%,#596a72 100%); /* W3C */
	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	-ms-user-select: none;
	user-select: none;
	width:20px;
	text-align:center;
	height:20px;
	border-radius:10px;
}

.navSwitch:hover,
.navSliderThumb:hover {
	background: #deecf7; /* Old browsers */
	background: -moz-radial-gradient(center, ellipse cover,  #deecf7 0%, #596a72 100%); /* FF3.6+ */
	background: -webkit-gradient(radial, center center, 0px, center center, 100%, color-stop(0%,#deecf7), color-stop(100%,#596a72)); /* Chrome,Safari4+ */
	background: -webkit-radial-gradient(center, ellipse cover,  #deecf7 0%,#596a72 100%); /* Chrome10+,Safari5.1+ */
	background: -o-radial-gradient(center, ellipse cover,  #deecf7 0%,#596a72 100%); /* Opera 12+ */
	background: -ms-radial-gradient(center, ellipse cover,  #deecf7 0%,#596a72 100%); /* IE10+ */
	background: radial-gradient(center, ellipse cover,  #deecf7 0%,#596a72 100%); /* W3C */
}

.navStepper {
	background: #f5f6f6; /* Old browsers */
	background: -moz-linear-gradient(top,  #f5f6f6 0%, #dbdce2 21%, #b8bac6 49%, #dddfe3 80%, #f5f6f6 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f5f6f6), color-stop(21%,#dbdce2), color-stop(49%,#b8bac6), color-stop(80%,#dddfe3), color-stop(100%,#f5f6f6)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* IE10+ */
	background: linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* W3C */
	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	user-select: none;
}

.navStepperBtn {
}

.navStepperBtn:hover {
	color: #DD9980;
}

/* choice button */
.navChoice,
.navChoiceSelected,
.navChoiceDisabled,
.navChoiceSelectedDisabled {
	white-space: nowrap;
	position: absolute;
	height: 16px;
	color: #808080;
	font-size: 10px;
	font-weight: bold;
	padding-top: 2px;
	text-align: center;
	overflow:hidden;
	
	background: #f5f6f6; /* Old browsers */
}

.navChoice,
.navChoiceSelected {
	color: #404040;
	background: #f5f6f6; /* Old browsers */
	background: -moz-linear-gradient(top,  #f5f6f6 0%, #dbdce2 21%, #b8bac6 49%, #dddfe3 80%, #f5f6f6 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f5f6f6), color-stop(21%,#dbdce2), color-stop(49%,#b8bac6), color-stop(80%,#dddfe3), color-stop(100%,#f5f6f6)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* IE10+ */
	background: linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* W3C */

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;

	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	transition-property: background;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

.navChoiceSelected,.navChoiceSelectedDisabled {
	background: rgb(53,107,141);
	color: white;
}

.navChoice:hover {
	background: #FFEEAA;
}

.navChoiceSelected:hover {
	background: rgb(73,127,161);
	color: white;
}

.navSlider {
	position: relative;
	border:1px solid #808080;
	height:20px;
	border: none;
}

.navSliderTrack {
	position:absolute;
	top:8px;
	border-radius:2px;
	border:1px solid #808080;
	height:2px;
	font-size:2px;
	background: #cedce7;
}

.navSliderTrackActive {
	position:absolute;
	top:8px;
	border-radius:2px;
	border:1px solid #808080;
	height:2px;
	font-size:2px;
	background: rgb(53,107,141);
}

.navPlotbar {
	position: relative;
	border:1px solid #808080;
	height:20px;
	border: none;
}

.navPlotbarBox {
	position:absolute;
	top:6px;
	border-radius:2px;
	border:1px solid #808080;
	height:10px;
	font-size:2px;
	background: #D0D0D0;
}

.navPlotbarValue {
	position:absolute;
	top:6px;
	border-radius:2px;
	border:1px solid #808080;
	height:10px;
	font-size:2px;
	background: rgb(53,107,141);
	background: -moz-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* FF3.6+ */
	background: -webkit-linear-gradient(top,  rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* IE10+ */
	background: linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* W3C */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#cedce7', endColorstr='#596a72',GradientType=0 ); /* IE6-9 */
}

/* overlay for messages, wait icon, etc. */
.navOverlay {
	position: absolute;
	z-index: 100;
	opacity: 0.0;
	visibility: hidden;

	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
	transition-property: opacity;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

/* iframe within sheet */
.navFrame {
	border: none;
	padding: 0px;
	opacity: 0.0;

	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;

	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	transition-property: opacity;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

.navColorBtn {
	width: 16px;
	height: 16px;
	opacity: 0.75;
}

.navColorBtn:hover {
	opacity: 1.0;
}

.navColorSet {
	color: #404040;
	font-size: 10px;
}

table.navColorTable td {
}

table.navColorTable td:hover {
	box-shadow: 1px 1px 1px #4040F0,-1px -1px 1px #4040F0;
}


/* ie version of back arrow */
.nav-arrow-left-ie {
    display : block;
    position: absolute;
    z-index : 0;
    left:20px;
    top:7px;
    height:20px;
    width: auto;
    padding: 7px 10px 0 6px;

    border-radius: 5px;
    border-top-left-radius: 18px;
    border-bottom-left-radius: 18px;
    border-bottom: 1px solid rgb(255,255,255);/*fallback*/
    border-bottom: 1px solid rgba(255,255,255,0.4);

    box-shadow :0 -1px 1px rgba(0,0,0,0.2) inset,
        0 1px 2px rgba(0,0,0,0.8) inset;

    color:#fff;
    text-shadow : 0px -1px 0px rgba(0,0,0,0.8);
    cursor: pointer;
    user-select: none;

	background: none;
}

.nav-arrow-left {
    display: block;
    position:absolute;
    z-index: 0;
    left:20px;
    top:7px;
    height:30px;
    width:auto;
    padding: 0 10px 0 6px;
    background-size: 30px 30px;

    background-repeat:repeat-x;
    background-position:0;
    background-image: -moz-linear-gradient(
        90deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 50%,
        rgba(255,255,255,0.1) 50%,
        rgba(255,255,255,0.3) 100%
        );
    background-image: -o-linear-gradient(
        90deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 50%,
        rgba(255,255,255,0.1) 50%,
        rgba(255,255,255,0.3) 100%
        );
    background-image: -webkit-linear-gradient(
        90deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 50%,
        rgba(255,255,255,0.1) 50%,
        rgba(255,255,255,0.3) 100%
        );

    border-radius: 5px;

    border-bottom: 1px solid rgb(255,255,255);/*fallback*/
    border-bottom: 1px solid rgba(255,255,255,0.4);

    box-shadow:0 -1px 1px rgba(0,0,0,0.2)inset,
        0 1px 2px rgba(0,0,0,0.8)inset;

    color:#fff;
    text-shadow: 0px -1px 0px rgba(0,0,0,0.8);
    cursor: pointer;
    -webkit-user-select: none;
    -moz-user-select: none;
    -o-user-select: none;
    user-select: none;
}

.nav-arrow-left:before{
    position:absolute;
    content: ' ';
    left:-8px;
    top:4px;
    height: 23px;
    width: 24px;
    z-index: 1;

    background-repeat:repeat-x;
    background-size: 30px 30px;
    background-position:-1px -1.5px;
    background-image: -moz-linear-gradient(
        45deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 52%,
        rgba(255,255,255,0.1) 52%,
        rgba(255,255,255,0.4) 100%
        );
    background-image: -o-linear-gradient(
        45deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 52%,
        rgba(255,255,255,0.1) 52%,
        rgba(255,255,255,0.4) 100%
        );
    background-image: -webkit-linear-gradient(
        45deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 52%,
        rgba(255,255,255,0.1) 52%,
        rgba(255,255,255,0.4) 100%
        );
    background-image: linear-gradient(
        45deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 52%,
        rgba(255,255,255,0.1) 52%,
        rgba(255,255,255,0.4) 100%
        );


    -moz-transform: rotateZ(-45deg) skewY(-10deg) skewX(-10deg);
    -o-transform: rotateZ(-45deg) skewY(-10deg) skewX(-10deg);
    -webkit-transform: rotateZ(-45deg) skewY(-10deg) skewX(-10deg);
    transform: rotateZ(-45deg) skewY(-10deg) skewX(-10deg);
    border-top-right-radius : 11px;
    border-top-left-radius :0px;
    border-bottom-right-radius : 0;
    border-bottom-left-radius : 10px;

    border-left: 1px solid rgb(255,255,255);/*fallback*/
    border-left: 1px solid rgba(255,255,255,0.4);

    box-shadow:  0px 1px 1px rgba(0,0,0,0.7) inset,
        2px -2px 2px -3px rgba(0,0,0,0.5) inset;
}

.nav-arrow-left:after {
    font-family: HelveticaNeue,Helvetica, Arial;
    font-weight: 400;
    font-size: 12px;
    line-height: 30px;
    text-align:center;    
    content: attr(title)"";
    z-index: 999;
    left:-2px;
    padding-left:3px;
    position:relative;
    height: 30px;
    line-height:30px;
    display:block;
    background-repeat:repeat-x;
    background-size: 30px 30px;
    background-position:-1px -0.5px;
    box-shadow: 0 -3px 1px -2px rgba(0,0,0,0.3)inset,
                0 4px 2px -3px rgba(0,0,0,0.8)inset;
    background-image: -webkit-linear-gradient(
        90deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 50%,
        rgba(255,255,255,0.1) 50%,
        rgba(255,255,255,0.3) 100%
        );
    background-image: -moz-linear-gradient(
        90deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 50%,
        rgba(255,255,255,0.1) 50%,
        rgba(255,255,255,0.3) 100%
        );
    background-image: -o-linear-gradient(
        90deg,
        rgba(0,0,0,0) 0%,
        rgba(0,0,0,0) 50%,
        rgba(255,255,255,0.1) 50%,
        rgba(255,255,255,0.3) 100%
        );
}

.nav-arrow-left,
.nav-arrow-left:after,
.nav-arrow-left:before {
    background: rgb(74,108,155);/*fallback*/
    background: rgba(74,108,155,1);

}

.nav-arrow-left:hover,
.nav-arrow-left:hover:after,
.nav-arrow-left:hover:before {
    background: rgb(54,88,135);/*fallback*/
    background: rgba(54,88,135,1);
}

.nav-arrow-left-ie:hover {
    background: rgb(54,88,135);/*fallback*/
    background: rgba(54,88,135,1);
}
</style>
}

Method %DrawHTML()
{
	// JMD1272
	Set ..language = %session.Language

	// Get list of color sets
	Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetColorSets(.tSets)
	Set k = $O(tSets(""))
	While (k'="") {
		Do ..colorSetNames.Insert($LG(tSets(k),1))
		Do ..colorSetCaptions.Insert($LG(tSets(k),2))
		Do ..colorSets.Insert($LG(tSets(k),3))
		Set k = $O(tSets(k))
	}

	Do ##super()
}

/// The default list of fonts available may be extended by editing the global
/// ^zenNavigator.UserFontListCSV.  This is a flat string holding the names of
/// desired fonts, separated by commas (i.e. "Palatino Linotype,Tahoma")  Names 
/// are case sentitive and subject to substitution if the named font is not found
/// on the run time system.  This function passes the value of the global to the 
/// client side renderer. 
ClassMethod GetUserFontList() As %ZEN.Datatype.string [ ZenMethod ]
{
 	Set tUFL = $Get(^zenNavigator.UserFontListCSV,"")
 	Quit tUFL
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// if we have any static groups; copy them;
	// !!!
	if (this.children && this.children.length) {
		this._stash = [];
		for (var n = 0; n < this.children.length; n++) {
			this._stash[n] = this.children[n].getEnclosingDiv();
		}
		this.children.length = 0;
	}

	// make first sheet appear
	this.pushSheet(null);
	this.render();

	// force layout
	this.setHeight(this.getEnclosingDiv().offsetHeight);
}

/// Slide a new item onto the stack and render it (with animation).
/// <var>item</var> is an object describing the new sheet to display.
ClientMethod slideInto(item) [ Language = javascript ]
{
	this.pushSheet(item);
}

/// Slide top item off of the stack and re-render (with animation).
ClientMethod slideOutOf() [ Language = javascript ]
{
	this.popSheet();
}

/// Push a new item onto the stack.
ClientMethod pushSheet(itemSpec) [ Language = javascript ]
{
	if (null==this._stack) {
		// create the stacks for divs and key values
		this.currLevel = 0;
		this._stack = [];			// stack of divs
		this._itemSpecStack = [];	// stack of current item spec for each level
		this._dataStack = [];		// stack of contentList for each level
		this._selectedStack = [];	// stack of selectedItem for each level
	}
	else {
		this.currLevel++;
	}

	// get the div to display for the new item
	var div = this.getLevelContent(this.currLevel,itemSpec);
	this._stack[this.currLevel] = div;
	this._itemSpecStack[this.currLevel] = itemSpec;
	this._dataStack[this.currLevel] = this._contentList;
	this._selectedStack[this.currLevel] = -1;
	this.updateMasterPanel(false);

	// slide tray over
	var columnWidth = parseInt(this.columnWidth,10);
	var tray = this.findElement('tray');
	if (tray) {
		tray.style.left = (-this.currLevel*columnWidth) + 'px';
	}
}

/// Pop the top sheet (html div) off of the stack and render it.
/// Return the current stack level.
ClientMethod popSheet() [ Language = javascript ]
{
	if (this._stack && this.currLevel>0) {
		this.currLevel--;
		this._editMode = false;

		// refresh div for new current item
		var div = this.getLevelContent(this.currLevel,this._itemSpecStack[this.currLevel]);
		this._stack[this.currLevel] = div;
		this._dataStack[this.currLevel] = this._contentList;

		this.updateMasterPanel(true);

		// slide tray over
		var columnWidth = parseInt(this.columnWidth,10);
		var tray = this.findElement('tray');
		if (tray) {
			tray.style.left = (-this.currLevel*columnWidth) + 'px';
		}

		// redraw without extra panel
		if (zenIsIE) {
			this.updateMasterPanel(false);
		}
		else {
			// attach to transition event per browser
			if (tray.addEventListener) {
				this._transEvent = new Function('zenPage.getComponent('+this.index+').updateMasterPanel(false);');
				tray.addEventListener('webkitTransitionEnd', this._transEvent,false);
				tray.addEventListener('transitionend', this._transEvent,false);
			}
		}
	}
	return this.currLevel;
}

/// Refresh the contents of the current top sheet.
ClientMethod refreshTopSheet() [ Language = javascript ]
{
	if (this._stack) {
		var itemSpec = this._itemSpecStack[this.currLevel];

		// get the div to display for the new item
		var div = this.getLevelContent(this.currLevel,itemSpec);
		this._stack[this.currLevel] = div;
		this._dataStack[this.currLevel] = this._contentList;
		this.updateMasterPanel(false);
	}
}

/// Return the HTML content for the given level.
/// <var>itemSpec</var> is the spec object for the parent of the current level.
/// It is null for the top-most level.
ClientMethod getLevelContent(level, itemSpec) [ Language = javascript ]
{
	var key = itemSpec ? zenGet(itemSpec.key) : '';

	var div = this.getEnclosingDiv();
	var bodyHeight = div.offsetHeight;

	// See if there are user-supplied contents for this level
	var content = null;
	if (this.ongetcontent!='') {
		// callback returns an object
		var value = itemSpec ? zenGet(itemSpec.value) : '';
		var content = zenInvokeCallbackMethod(this.ongetcontent,this,'ongetcontent','level',level,'key',key,'value',value);
	}

	// pick up any information for the title bar
	// set title for sheet
	if (!this._title) {
		this._title = [];
	}
	this._title[this.currLevel] = (content && content.title) ? content.title : '';

	if (!this._headerButtons) {
		this._headerButtons = [];
	}
	this._headerButtons[this.currLevel] = (content && content.headerButtons) ? content.headerButtons : null;

	if (!this._footerButtons) {
		this._footerButtons = [];
	}
	this._footerButtons[this.currLevel] = (content && content.footerButtons) ? content.footerButtons : null;

	var cwid = parseInt(this.columnWidth,10) - 12;
	cwid = cwid > 0 ? cwid : 1;

	var chgt = bodyHeight-parseInt(this.headerHeight,10)-parseInt(this.footerHeight,10)-20;
	chgt = chgt > 0 ? chgt : 1;

	var html = [];
	if (content) {
		if (content.url) {
			html[html.length] = '<iframe id="'+this.makeId('iframe_'+level)+'" onload="zenPage.getComponent('+this.index+').revealFrame(this);" class="navFrame" style="width:'+(cwid)+'px;height:'+(chgt)+'px;" src="'+content.url+'"/>';
			this.beginWait();
		}
		else if (content.html) {
			html[html.length] = content.html;
		}
		else if (content.childIndex !== null && this._stash && this._stash.length && this._stash[content.childIndex]) {
			// use html from stashed div
			html[html.length] = this._stash[content.childIndex].innerHTML;
		}
		else if (content.items && content.items.length) {
			this._contentList = content.items;
			// loop over items, build content
			for (var n = 0; n < content.items.length; n++) {
				var item = content.items[n];
				html[html.length] = this.getHTMLForItem(n,item,false);
			}
		}
	}

	if (html.length==0) {
		// no data: show panel number
		// html[html.length] = '<div style="height: 200px;background: white;font-size:80px; text-align:center; color:#808080;">' + level + '</div>';
	}
	return html.join('');
}

/// Refresh the contents of the property sheet.
/// If <var>reset</var> is true, unhighlight and unscroll the contents.
ClientMethod update(reset) [ Language = javascript ]
{
	if (reset) {
		var enc = this.getEnclosingDiv();
		enc.scrollTop = 0;
		enc.scrollLeft = 0;
		this.selectedItem = '';

		// reset the stack 
		this._stack = null;
		this.pushSheet(null);
	}
	this._validContent = false;
	this.render();
}

/// Refresh the contents of the master panel.
ClientMethod updateMasterPanel(showExtra) [ Language = javascript ]
{
	// update master panel
	var masterDiv = this.findElement('tray');
	if (masterDiv) {
		// remove transition handler
		if (!showExtra && this._transEvent && masterDiv.removeEventListener) {
			masterDiv.removeEventListener('webkitTransitionEnd', this._transEvent);
			masterDiv.removeEventListener('transitionend', this._transEvent);
			this._transEvent = null;
		}
		masterDiv.innerHTML = this.getMasterContent(showExtra);
	}
}

/// Draw contents of the property sheet.
ClientMethod renderContents() [ Language = javascript ]
{
	var div = this.getEnclosingDiv();
	if (!div) return;

	// already rendered
	if (this._validContent) {
		return;
	}

	var discWidth = this.showDisclosure ? parseInt(this.disclosureWidth,10) : 0;
	var bodyHeight = div.offsetHeight;

	// width of navigator is fixed
	div.style.width = discWidth + (this.expanded ?  parseInt(this.columnWidth,10)+2 : 0) + 'px';

	if (bodyHeight>0) {
		this._validContent = true;
	}

	var columnWidth = parseInt(this.columnWidth,10);

	// Content consists of a master area and an optional details area
	// There is an optional "disclosure" bar on the left (if enabled).
	// Within the master area, there is a wrapper, that clips the visible content
	// This contains a "tray" of items; The tray slides within the master area
	var html = [];

	if (this.showDisclosure) {
		html[html.length] = '<div id="'+this.makeId('disclosure')+'" title="'+this.title+'" class="navDisclosureBar" style="height:'+bodyHeight+'px;width:'+this.disclosureWidth+'px;left:0px;" onclick="zenPage.getComponent('+this.index+').toggleExpanded();">';

		// outer disclosure icon
		var icon = this.expanded ? 'images/black_left_arrow.png' : 'images/black_right_arrow.png';
		
		html[html.length] = '<image id="'+this.makeId('discIcon')+'" class="navDisclosureIcon" style="top:'+bodyHeight/2+'px;" src="'+icon+'" />';
		html[html.length] = '</div>';
		html[html.length] = '</div>';
	}

	// background
	html[html.length] = '<div id="'+this.makeId('background')+'" class="navBackground" style="left:'+discWidth+'px;height:'+bodyHeight+'px;width:'+columnWidth+'px;'+this.backgroundStyle+'"></div>';

	html[html.length] = '<div id="'+this.makeId('master')+'" class="navMasterPanel" style="left:'+discWidth+'px;height:'+bodyHeight+'px;width:'+columnWidth+'px;">';
	html[html.length] = '<div id="'+this.makeId('tray')+'" class="navMasterTray" style="height:'+bodyHeight+'px;">';
	html[html.length] = this.getMasterContent(false);
	html[html.length] = '</div>';
	html[html.length] = '</div>';

	// overlay
	html[html.length] = '<div id="'+this.makeId('overlay')+'" class="navOverlay"></div>';

	// show it
	div.innerHTML = html.join('');
	div.style.opacity = 1.0;

	// turn on transition
	div.style.transitionProperty = 'width';
	div.style.webkitTransitionProperty = 'width';
	div.style.MozTransitionProperty = 'width';

	var tray = this.findElement('tray');
	if (tray) {
		tray.style.left = (-this.currLevel*columnWidth) + 'px';
	}
}

/// Get the HTML contents of the master panel tray.
ClientMethod getMasterContent(showExtra) [ Language = javascript ]
{
	var div = this.getEnclosingDiv();
	if (!div) return;

	var columnWidth = parseInt(this.columnWidth,10);
	var bodyHeight = div.offsetHeight;

	var chgt = bodyHeight-parseInt(this.headerHeight,10)-parseInt(this.footerHeight,10)-20;
	chgt = chgt > 0 ? chgt : 1;

	var html = [];
	
	// if we are in a "pop", draw an extra panel
	var extra = showExtra ? 1 : 0;

	// draw all items within the stack
	if (null!=this._stack) {
		var left = 0;
		for (var n = 0; n <= this.currLevel + extra; n++) {
			html[html.length] = '<div id="'+this.makeId('panel_'+n)+'" class="navPanel" style="left:'+left+'px;width:'+columnWidth+'px;height:'+bodyHeight+'px;">';
			if (parseInt(this.headerHeight,10)>0) {
				html[html.length] = this.getNavHeaderHTML(n);
			}
			html[html.length] = '<div id="'+this.makeId('body_'+n)+'" class="navBody" style="height:'+(chgt)+'px;">';
			html[html.length] = this._stack[n] ? this._stack[n] : '';
			html[html.length] = '</div>';
			if (parseInt(this.footerHeight,10)>0) {
				html[html.length] = this.getNavFooterHTML(n);
			}
			html[html.length] = '</div>';
			left += columnWidth;
		}
	}
	return html.join('');
}

/// Get HTML for the navigator bar (header for master panel).
ClientMethod getNavHeaderHTML(level) [ Language = javascript ]
{
	var html = [];

	// JMD1272
	var backText = '';
	if (level>0) {
		if (this.language.toString().substr(0,2) == 'en') {
			var backText = 'Back';
		}
		else {
			var backText = '&nbsp;&nbsp;&#9664;&nbsp;&nbsp;';
		}
	}

	var titleText = this._title && this._title[this.currLevel] ? this._title[this.currLevel] : '';
	var headerButtons = this._headerButtons && this._headerButtons[this.currLevel] ? this._headerButtons[this.currLevel] : '';

	// header
	html[html.length] = '<div class="navHeader" style="height:'+this.headerHeight+'px;">';

	// arrow size
	var h = parseInt(this.headerHeight,10);
	var arrowWid = 80;
	var arrowHgt = h * 0.8;
	arrowHgt = arrowHgt > 24 ? 24 : arrowHgt;

	// back arrow
	if (backText != '') {
		if (zenIsIE) {
			html[html.length] = '<div class="nav-arrow-left-ie" onclick="zenPage.getComponent('+this.index+').slideOutOf();">'+backText+'</div>';
		}
		else {
			html[html.length] = '<div class="nav-arrow-left" onclick="zenPage.getComponent('+this.index+').slideOutOf();" title="'+backText+'"></div>';
		}
	}

	if (titleText != '') {
		var newCaption = {};
		var twid = parseInt(this.columnWidth,10) - 120;
		// parseInt(this.columnWidth,10)-(arrowWid+10)
		var tooltip = 'title="'+titleText+'" ';
		var nsz = this.findTextSize(titleText,"navTitle",'font-size:18px;',(twid),newCaption);
		if (newCaption.caption) {
			titleText = newCaption.caption;
		}
		var style = 'width:'+twid+'px;';
		if (nsz) {
			style = 'font-size:' + nsz + 'px;';
		}
		html[html.length] = '<div style="position:absolute;top:'+(h/4)+'px;left:'+(arrowWid+10)+'px;">';
		html[html.length] = '<div '+tooltip+' class="navTitle" style="'+style+'">' + zenEscapeXML(titleText) + '</div>';
		html[html.length] = '</div>';
	}

	// buttons?
	if (headerButtons && headerButtons.length) {
		var enc = this.getEnclosingDiv();
		var width = enc.offsetWidth;
		var bx = 0;
		for (var b = headerButtons.length-1; b>=0; b--) {
			var bInfo = headerButtons[b];
			if (bInfo) {
				var bKey = zenGet(bInfo.key);
				var bImage = zenGet(bInfo.image);
				var bCaption = zenGet(bInfo.caption);
				html[html.length] = '<div title="'+bCaption+'" style="position:absolute;top:'+(h/2-6)+'px;left:'+(width-50-bx)+'px;">';
				html[html.length] = '<image class="navHeaderIcon" src="'+bImage+'" onclick="zenPage.getComponent('+this.index+').headerButtonClickHandler(\''+bKey+'\','+level+');"/>';
				html[html.length] = '</div>';
				bx += 25;
			}
		}
	}

	html[html.length] = '</div>';
	return html.join('');
}

/// Get HTML for the footer bar.
ClientMethod getNavFooterHTML(level) [ Language = javascript ]
{
	var html = [];

	var footerButtons = this._footerButtons && this._footerButtons[this.currLevel] ? this._footerButtons[this.currLevel] : '';

	// header
	html[html.length] = '<div class="navFooter" style="height:'+this.footerHeight+'px;">';

	var h = parseInt(this.footerHeight,10);

	// buttons
	if (footerButtons && footerButtons.length) {
		var enc = this.getEnclosingDiv();
		var width = enc.offsetWidth;
		var bx = 15;
		for (var b = 0; b < footerButtons.length; b++) {
			var bInfo = footerButtons[b];
			if (bInfo) {
				var bKey = zenGet(bInfo.key);
				var bImage = zenGet(bInfo.image);
				var bCaption = zenGet(bInfo.caption);
				html[html.length] = '<div title="'+bCaption+'" style="position:absolute;top:'+(h/2-6)+'px;left:'+(bx)+'px;">';
				html[html.length] = '<image class="navHeaderIcon" src="'+bImage+'" onclick="zenPage.getComponent('+this.index+').headerButtonClickHandler(\''+bKey+'\','+level+');"/>';
				html[html.length] = '</div>';
				bx += 25;
			}
		}
	}

	html[html.length] = '</div>';
	return html.join('');
}

/// Return HTML for one item.
ClientMethod getHTMLForItem(index, item, active) [ Language = javascript ]
{
	var html = [];
	var itemStyle = zenGet(item.style);
	var display = zenGet(item.display,'caption');
	var selected = zenGet(item.selected,false);

	// special handling for some types
	switch (display) {
	case 'info':
		var cls = 'navInfo';
		html[html.length] = '<div id="'+this.makeId('item_'+(this.currLevel)+'_'+index)+'" class="'+cls+'" style="width:'+this.columnWidth+'px;'+itemStyle+'">';
		html[html.length] = this.getItemContent(index,item,active);
		html[html.length] = '</div>';
		break;
	case 'section':
		var cls = selected ? 'navSectionSelected' : 'navSection';
		html[html.length] = '<div id="'+this.makeId('item_'+(this.currLevel)+'_'+index)+'" class="'+cls+'" style="width:'+this.columnWidth+'px;'+itemStyle+'">';
		html[html.length] = this.getItemContent(index,item,active);
		html[html.length] = '</div>';
		break;
	default:
		var cls = selected ? 'navItemSelected' : 'navItem';
		html[html.length] = '<div id="'+this.makeId('item_'+(this.currLevel)+'_'+index)+'" class="'+cls+'" style="width:'+this.columnWidth+'px;'+itemStyle+'" onclick="zenPage.getComponent('+this.index+').clickHandler(event,'+index+');">';
		html[html.length] = this.getItemContent(index,item,active);
		html[html.length] = '</div>';
		break;
	}
	return html.join('');
}

/// Return HTML for the contents of an item.
/// This draw the various cells and controls within a sheet.
ClientMethod getItemContent(index, item, active) [ Language = javascript ]
{
	var html = [];
	var id = this.makeId('control_'+this.currLevel);
	var display = zenGet(item.display,'caption');
	var key = zenGet(item.key);
	var action = zenGet(item.action);
	var caption = zenGet(item.caption);
	var value = zenGet(item.value);
	var text = zenGet(item.text,value);
	var edit = zenGet(item.edit);
	var help = zenGet(item.help);
	var captionStyle = zenGet(item.captionStyle);
	var valueStyle = zenGet(item.valueStyle);
	var disabled = this.disabled || zenGet(item.disabled,false);
	var hasCheck = ('undefined' != typeof item.checked && item.checked);
	var hasClose = ('undefined' != typeof item.closeButton && item.closeButton);
	var hasDrag = ('undefined' != typeof item.canDrag && item.canDrag);
	var indent = parseInt(zenGet(item.indent,0),10);
	var indentWidth = 20;

	// tooltip
	var tooltip = help ? ('title="'+help+'" ') : '';

	// compute widths and offsets
	var width = parseInt(this.columnWidth,10);

	// for single values
	var itemWidth = 280 - (indent*indentWidth);		// only one value to show

	// for two values
	var item1Width = 120 - (indent*indentWidth);		// left
	var item2Width = width - (item1Width + 60);		// right

	var chwid = hasCheck ? 16 : 0;

	if (hasCheck) {
		var checked = zenGet(item.checked,false);
		caption = (checked ? '&#8226;':'&nbsp;')+caption;
	}
	// render based on the display property
	var style = '';
	
	if(!zenPage.getComponent(this.index).widgets){
		zenPage.getComponent(this.index).widgets = {};
	}

	switch(display) {
	case 'value':
		style = 'top: 5px;width:'+itemWidth+'px;';
		style += valueStyle;
		style += (edit!='') ? 'color:#404080;' : '';
		var captionText = text==='' ? '&nbsp;' : zenEscapeXML(text);
		html[html.length] = '<div class="navItemCaption'+(disabled?'Disabled':'')+'" style="'+style+'" title="'+captionText+'">';
		if (edit!='') {
			html[html.length] = this.getHTMLForEditor(index,item,active,disabled);
		}
		else {
	//		html[html.length] = text==='' ? '&nbsp;' : zenEscapeXML(text);
			html[html.length] = captionText;
		}
		html[html.length] = '</div>';
		break;

	case 'info':
		// show a caption and value as an info box
		// no drag or edit
		style = 'top: 0px; font-size:18px;left:40px;';
		style += captionStyle;
		html[html.length] = '<div '+tooltip+' class="navItemInfoCaption" style="'+style+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';

		html[html.length] = '<div class="navItemImage" style="'+istyle+'">';
		var src = zenGet(item.image,'deepsee/ds2_info_44.png');
		if (src && src!=='') {
			html[html.length] = '<image src="'+src+'" style="width:24px;height:24px;opacity:0.5;"/>';
		}
		html[html.length] = '</div>';

		style = 'top: 22px; font-weight:normal;left:40px;';
		style += valueStyle;
		html[html.length] = '<div class="navItemInfoValue" style="'+style+'">';
		html[html.length] = text==='' ? '&nbsp;' : zenEscapeXML(text);
		html[html.length] = '</div>';
		break;

	case 'html':
		// inject user HTML content into cell
		//html[html.length] = '<div class="navItemCaption">';
		html[html.length] = zenGet(item.content);
		//html[html.length] = '</div>';
		break;

	case 'section':
		style = 'top: 8px;width:'+itemWidth+'px;';
		style += captionStyle;
		html[html.length] = '<div class="navSectionCaption'+(disabled?'Disabled':'')+'" style="'+style+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';
		break;

	case 'value-cells':
		// loop over cells and plot each within a table cell
		var cellsPerRow = parseInt(zenGet(item.cellsPerRow,3),10);
		cellsPerRow = (isNaN(cellsPerRow)||cellsPerRow<=0) ? 1 : cellsPerRow;
		
		var cellCount = (item.cells&&item.cells.length) ? item.cells.length : 0;
		if (cellCount) {
			var cellNo = 0;
			var rows = Math.floor(cellCount/cellsPerRow);
			var style = '';
			var cwid = this.columnWidth / cellsPerRow;
			// do not apply style to table
			html[html.length] = '<table border="0" cellpadding="0" cellspacing="0">';
			for (var r = 0; r < rows; r++) {
				html[html.length] = '<tr>';

				// values
				for (var c = 0; c < cellsPerRow; c++) {
					var cell = item.cells[cellNo+c];
					if (cell) {
						html[html.length] = '<td style="width:'+cwid+'px;text-align:center;font-size:36px;color:#606060;font-weight:bold;">';
						html[html.length] = zenGet(cell.value);
						html[html.length] = '</td>';
					}
				}
				html[html.length] = '</tr>';

				// captions
				html[html.length] = '<tr>';
				for (var c = 0; c < cellsPerRow; c++) {
					var cell = item.cells[cellNo+c];
					if (cell) {
						html[html.length] = '<td style="width:'+cwid+'px;vertical-align:top;text-align:center;padding-bottom:10px;">';
						html[html.length] = zenGet(cell.caption);
						html[html.length] = '</td>';
					}
				}
				html[html.length] = '</tr>';
				cellNo += cellsPerRow;
			}

			html[html.length] = '</table>';
		}
		break;

	case 'caption':
	default:
		style = 'top: 5px;width:'+itemWidth+'px;';
		if (hasDrag) {
			style += 'left:'+((indent+1)*indentWidth)+'px;';
		}
		style += captionStyle;
		html[html.length] = '<div class="navItemCaption'+(disabled?'Disabled':'')+'" style="'+style+'" title="'+caption+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';
		break;

	case 'caption-value':
	case 'caption-value-vt':
		style = 'top: 0px; font-size:18px;';
		if (hasDrag) {
			style += 'left:'+((indent+1)*indentWidth)+'px;';
		}
		style += captionStyle;
		if (tooltip==='') tooltip = 'title="'+caption+'" ';
		html[html.length] = '<div '+tooltip+' class="navItemCaption'+(disabled?'Disabled':'')+'" style="'+style+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';

		style = 'top: 22px; font-weight:normal;';
		style += valueStyle;
		style += (edit!='') ? 'color:#404080;' : '';

		html[html.length] = '<div class="navItemValue" style="'+style+'">';
		if (edit!='') {
			html[html.length] = this.getHTMLForEditor(index,item,active,disabled);
		}
		else {
			html[html.length] = text==='' ? '&nbsp;' : zenEscapeXML(text);
		}
		html[html.length] = '</div>';
		break;

	case 'caption-value-hz':
		// test caption size
		var newCaption = {};
		if (caption && tooltip=='') tooltip = 'title="'+caption+'" ';
		var nsz = this.findTextSize(caption,"navItemCaption",captionStyle,item1Width,newCaption);
		if (newCaption.caption) {
			
			caption = newCaption.caption;
		}
		style = 'top:5px;width:'+item1Width+'px;';
		if (hasDrag) {
			style += 'left:'+((indent+1)*indentWidth)+'px;';
		}
		style += captionStyle;
		if (nsz) {
			style += 'font-size:' + nsz + 'px;';
		}
		html[html.length] = '<div '+tooltip+' class="navItemCaption'+(disabled?'Disabled':'')+'" style="'+style+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';
		style = 'top:5px;left:140px;font-weight:normal;width:'+item2Width+'px;';
		style += (edit!='') ? 'color:#404080;' : '';
		style += valueStyle;

		// shrink text to fit
		if (edit==''||disabled) {
			var newCaption = {};
			var nsz = this.findTextSize(text,"navItemValueHz",valueStyle,item2Width-((hasClose&&!disabled)?14:0));
			if (newCaption.caption) {
				text = newCaption.caption;
			}
			if (nsz) {
				style += 'font-size:' + nsz + 'px;';
			}
		}

		if (edit=='string') {
			// give more space to string edit
			style += 'width:'+(item2Width+40)+'px;';
		}
		html[html.length] = '<div class="navItemValueHz" style="'+style+'">';
		if (edit!='') {
			html[html.length] = this.getHTMLForEditor(index,item,active,disabled);
		}
		else {
			html[html.length] = text==='' ? '&nbsp;' : zenEscapeXML(text);
		}
		html[html.length] = '</div>';
		break;

	case 'image-caption':
	case 'image-caption-hz':
		var newCaption = {};
		if (caption && tooltip=='') tooltip = 'title="'+caption+'" ';
		var nsz = this.findTextSize(caption,"navItemCaption",captionStyle,(itemWidth-55-(hasDrag?30:0)),newCaption);
		if (newCaption.caption) {	
			caption = newCaption.caption;
		}

		var istyle = '';
		if (hasDrag) {
			istyle += 'left:'+(10+((indent+1)*indentWidth))+'px;';
		}
		html[html.length] = '<div class="navItemImage" style="'+istyle+'">';
		var src = zenGet(item.image,'portal/lamp_48.gif');
		if (src && src!=='') {
			src = ('none'==src)?'':src;
			html[html.length] = '<image src="'+src+'" style="width:36px;'+zenGet(item.imageStyle)+'"/>';
		}
		html[html.length] = '</div>';

		style = 'top: 5px;';
		if (hasDrag) {
			style += 'left:'+(50+((indent+1)*indentWidth))+'px;';
		}
		else {
			style += 'left:40px;';
		}
		style += captionStyle;
		if (nsz) {
			style += 'font-size:' + nsz + 'px;';
		}
		html[html.length] = '<div '+tooltip+'class="navItemCaption'+(disabled?'Disabled':'')+'" style="'+style+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';
		break;

	case 'image-caption-value':
	case 'image-caption-value-vt':
		html[html.length] = '<div class="navItemImage">';
		var src = zenGet(item.image,'portal/lamp_48.gif');
		if (src && src!=='') {
			src = ('none'==src)?'':src;
			html[html.length] = '<image src="'+src+'" style="width:36px;"/>';
		}
		html[html.length] = '</div>';

		style = 'top: 0px; left:40px;font-size:18px;';
		style += captionStyle;
		html[html.length] = '<div class="navItemCaption'+(disabled?'Disabled':'')+'" style="'+style+'" title="'+caption+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';

		style = 'top: 22px; left:40px;font-weight:normal;';
		style += valueStyle;
		html[html.length] = '<div class="navItemValue" style="'+style+'">';
		html[html.length] = text;
		html[html.length] = '</div>';
		break;

	case 'image-caption-value-hz':
		html[html.length] = '<div class="navItemImage">';
		var src = zenGet(item.image,'portal/lamp_48.gif');
		if (src && src!=='') {
			src = ('none'==src)?'':src;
			html[html.length] = '<image src="'+src+'" style="width:36px;"/>';
		}
		html[html.length] = '</div>';

		style = 'top:5px;left:40px;width:90px;font-size:18px;';
		style += captionStyle;
		html[html.length] = '<div class="navItemCaption'+(disabled?'Disabled':'')+'" style="'+style+'" title="'+caption+'">';
		html[html.length] = caption;
		html[html.length] = '</div>';
		style = 'top:5px;left:160px;font-weight:normal;font-size:18px;width:100px;';
		style += valueStyle;
		html[html.length] = '<div class="navItemValueHz" style="'+style+'">';
		html[html.length] = text;
		html[html.length] = '</div>';

		break;
	}

	// drag handle
	if (hasDrag && !disabled) {
		var hlp = $$$Text('Move this item to a new position');
		html[html.length] = '<div class="navItemDragHandle" title="'+hlp+'" onmousedown="return zenPage.getComponent('+this.index+').itemDragHandleMouseDown(event,'+this.currLevel+','+index+',\''+key+'\');">';
		var src = 'images/navthumb.png';
		var left = indent * indentWidth;
		html[html.length] = '<image style="left:'+left+'px;position:absolute;" src="'+src+'"/>';
		html[html.length] = '</div>';
	}

	// close button
	if (hasClose && !disabled) {
		html[html.length] = '<div class="navItemCloseBtn" onclick="zenPage.getComponent('+this.index+').closeButtonClickHandler(event,\''+key+'\');" title="'+this.deleteThisItemMsg+'">';
		var src = 'deepsee/delete_widget.png';
		html[html.length] = '<image src="'+src+'" style="width:18px;"/>';
		html[html.length] = '</div>';
	}

	if (action=='drill' && !disabled && !active) {
		// drill down button
		html[html.length] = '<div class="navItemDrillDown" onclick="zenPage.getComponent('+this.index+').clickHandler(event,'+index+',true);">';
		var src = 'images/black_right_arrow.png';
		html[html.length] = '<image src="'+src+'" style="width:16px;"/>';
		html[html.length] = '</div>';
	}
	else if(action=='openButton'){
		var widget = zenGet(item.widget);
		var wid = widget.id;
		zenPage.getComponent(this.index).widgets[wid] = widget;
		var src = 'deepsee/open_widget.png'
		html[html.length] = '<div class="navItemOpenBtn" onclick="zenPage.getComponent('+this.index+').widgets[\''+wid+'\'].openWidget();" title="'+this.openThisItemMsg+'">';
		html[html.length] = '<image src="'+src+'" style="width:18px;"/>';
		html[html.length] = '</div>';
	}
	else if (action=='popup' && !disabled && !active) {
		// popup button
		var url = zenGet(item.url);
		if (url) {
			html[html.length] = '<div class="navItemPopup" onclick="zenPage.getComponent('+this.index+').popupButtonClickHandler(event,\''+key+'\',\''+url+'\');">';
			var src = 'deepsee/ds2_magnify_44.png';
			html[html.length] = '<image src="'+src+'" style="width:16px;"/>';
			html[html.length] = '</div>';
		}
	}

	return html.join('');
}

/// Find a font-size so the given text will fit in the given space.
ClientMethod findTextSize(text, cls, style, width, newCaption) [ Internal, Language = javascript ]
{
	var newSize = 0;
	// if string is too long, create a shortened version
	if (newCaption && text.length > 25) {
		text = text.substr(0,25) + '...';
		newCaption.caption = text;
	}

	if (text!='' && text.length > 10) {
		var div = this.getEnclosingDiv();
		var element = document.createElement('div');
		if (cls) {
			element.className = cls;
		}
		if (style) {
			element.style.cssText = style;
		}	
		element.appendChild(document.createTextNode(text));
	    div.appendChild(element);

		// offsetWidth does not work without this!
		element.style.position = 'fixed';

		if (element.offsetWidth > width) {
			var newSize = 24;
			while (element.offsetWidth > width && newSize > 8) {
				newSize--;
				element.style.fontSize = newSize + 'px';
			}
		}
	   	div.removeChild(element);
	}
	return newSize;
}

/// Click handler for header (or footer) button.
ClientMethod headerButtonClickHandler(key, level) [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.onbuttonclick,this,'onbuttonclick','key',key,'level',level);
}

/// Click handler for close button.
ClientMethod closeButtonClickHandler(evt, key) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	zenInvokeCallbackMethod(this.onclosebuttonclick,this,'onclosebuttonclick','key',key);
}

/// Click handler for popup button.
ClientMethod popupButtonClickHandler(evt, key, url) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}

	var parms = {};
	zenPage.launchPopupWindow(url,key,'resizable,width=800,height=600',parms,this);
}

/// This client event, if present, is fired when a popup page has specified
/// this component as its parent and fires an action.<br>
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.onpopupaction,this,'onpopupaction','key',popupName,'value',value);
}

/// Start of item drag.
/// This can either be a "move" or a "indent" operation.
ClientMethod itemDragHandleMouseDown(evt, level, index, key) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	// JMD1286: ie
	evt.cancelBubble = true;
	evt.returnValue = false;

	// connect mouse handlers to window
	if (document.onmousemove != this.itemDragMouseMove) {
		this._oldMouseMove = document.onmousemove;
		document.onmousemove = this.itemDragMouseMove;
	}
	if (document.onmouseup != this.itemDragMouseUp) {
		this._oldMouseUp = document.onmouseup;
		document.onmouseup = this.itemDragMouseUp;
	}
	
	// drag state
	zenPage._dragState = {};
	var dragState = zenPage._dragState;

	dragState.componentIndex = this.index;
	dragState.itemLevel = level;
	dragState.itemIndex = index;
	dragState.itemNewIndex = index;
	dragState.itemKey = key;
	dragState.operation = null;
	dragState.moveCount = 0;

	// remember indent level
	var item = this.findItemByIndex(index);
	// if indent is not set, then "indent" operation is not used
	dragState.itemIndent = zenGet(item.indent);
	dragState.itemNewIndent = dragState.itemIndent;

	if (dragState.itemIndent==='') {
		dragState.firstIndex = 0;
		dragState.lastIndex = 100000;
		dragState.moveMap = null;
	}
	else {
		// find range of motion: we only allow movement within the
		// same "group": items with same indent or higher
		dragState.firstIndex = index;
		for (var j = index; j >=0; j--) {
			var test = this.findItemByIndex(j);
			if (!test || dragState.itemIndent > zenGet(test.indent,-1)) {
				break;
			}
			dragState.firstIndex = j;
		}

		dragState.lastIndex = index;
		for (var j = index;; j++) {
			var test = this.findItemByIndex(j);
			if (!test || dragState.itemIndent > zenGet(test.indent,-1)) {
				break;
			}
			dragState.lastIndex = j;
		}
		// map index # within sheet to index within local array of items
		dragState.moveMap = {};
		var jcount = 0;
		for (var j = dragState.firstIndex; j<=dragState.lastIndex; j++) {
			var test = this.findItemByIndex(j);
			if (test && dragState.itemIndent == zenGet(test.indent,-1)) {
				dragState.moveMap[j] = jcount++;
			}
		}
	}

	var itemId = 'item_'+level+'_'+index;
	var div = this.findElement(itemId);
	dragState.itemHeight = div.offsetHeight;

	// create ghost copy of pane
	var ghostDiv = document.createElement('div');
    div.parentNode.appendChild(ghostDiv);
	dragState.ghostDiv = ghostDiv;

	ghostDiv.style.position = 'absolute';
	ghostDiv.style.zIndex = 9;
	ghostDiv.style.top = '0px';

	// create copy of item to drag
	var dragDiv = document.createElement('div');
	dragDiv.className = div.className;
	dragDiv.style.cssText = div.style.cssText;
	dragDiv.style.position = 'absolute';
	dragDiv.style.zIndex = 10;
	dragDiv.innerHTML = div.innerHTML;
    div.parentNode.appendChild(dragDiv);
    dragState.dragDiv = dragDiv;
    dragDiv.style.opacity = 0.33;

	// !!! find actual top and left
	dragState.parentOffsetTop = div.parentNode.offsetTop;
	dragState.parentOffsetLeft = div.parentNode.offsetLeft;
	dragState.itemHeight = div.offsetHeight;
	var my = evt.clientY - dragState.parentOffsetTop;
	var mx = evt.clientX - dragState.parentOffsetLeft;

	dragState.startY = my;
	dragState.startX = mx;

	dragDiv.style.top = my - (dragState.itemHeight/2) + 'px';

	// build list of all items on the current page level
	var list = [];
	var orderList = [];
	for (var n = 0;;n++) {
		var itemId = 'item_'+level+'_'+n;
		var div = this.findElement(itemId);
		if (div) {
			list[n] = div;
			orderList[n] = n;
		}
		else {
			break;
		}
	}
	dragState.itemList = list;
	dragState.orderList = orderList;
	dragState.ghostDiv.innerHTML = this.getGhostHTML(dragState.itemList,dragState.orderList,index);
	return false;
}

/// Arrange the divs in the item list using the order list.
ClientMethod getGhostHTML(itemList, orderList, newIndex) [ Internal, Language = javascript ]
{
	var html = [];
	var wid = this.columnWidth;
	for (var n = 0; n < orderList.length; n++) {
		var bg = (n==newIndex) ? '#D0D0FF' : '#D0D0D0';
		html[html.length] = '<div class="navItem" style="background:'+bg+';width:'+wid+'px;">';
		html[html.length] = itemList[orderList[n]].innerHTML;
		html[html.length] = '</div>';
	}
	return html.join('');
}

/// Mouse up handler for item drag (connected to window).
ClientMethod itemDragMouseUp(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;

	var dragState = zenPage._dragState;
	var nav = (!dragState||dragState.componentIndex===null)?null:zenPage.getComponent(dragState.componentIndex);

	// invoke callback
	if (dragState && dragState.operation) {
		switch(dragState.operation) {
		case 'move':
			if (dragState.moveCount) {
				var oldPos = dragState.moveMap ? dragState.moveMap[dragState.itemIndex] : dragState.itemIndex;
				var newPos = dragState.moveMap ? dragState.moveMap[dragState.itemNewIndex] : dragState.itemNewIndex;
				// +DTB330 - Swap each single-step from oldPos to newPos to maintain order of other items
				if (oldPos < newPos) {
					for (var pos=oldPos ; pos<newPos ; pos++) {
						zenInvokeCallbackMethod(nav.onarrange,nav,'onarrange','swap',
							{index:dragState.itemIndex, oldPosition:pos, newPosition:pos+1},
							'key',dragState.itemKey,'final',true);
					}
				}
				else if (newPos < oldPos) {
					for (var pos=oldPos ; pos>newPos ; pos--) {
						zenInvokeCallbackMethod(nav.onarrange,nav,'onarrange','swap',
							{index:dragState.itemIndex, oldPosition:pos, newPosition:pos-1},
							'key',dragState.itemKey,'final',true);
					}
				}
 				// -DTB330
			}
			break;
		case 'indent':
			break;
		default:
			// select
				zenInvokeCallbackMethod(nav.onarrange,nav,'onarrange','swap',
					{index:dragState.itemIndex, oldPosition:dragState.itemIndex, newPosition:dragState.itemIndex},
					'key',dragState.itemKey,'final',true);
			break;
		}
	}

	// remove mouse handlers from window
	if (this._oldMouseMove) {
		document.onmousemove = this._oldMouseMove;
	}
	this._oldMouseMove = null;
	if (this._oldMouseUp) {
		document.onmouseup = this._oldMouseUp;
	}
	this._oldMouseUp = null;
	zenPage._dragState = null;

	if (nav) {
		nav.refreshTopSheet();
	}
}

/// Mouse move handler for item drag (connected to window).
ClientMethod itemDragMouseMove(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	// JMD1286: ie
	evt.cancelBubble = true;
	evt.returnValue = false;

	var dragState = zenPage._dragState;
	var nav = (!dragState||dragState.componentIndex===null)?null:zenPage.getComponent(dragState.componentIndex);
	if (nav) {
		var my = evt.clientY - dragState.parentOffsetTop;
		var mx = evt.clientX - dragState.parentOffsetLeft - dragState.startX;
		var dragDiv = dragState.dragDiv;

		// find index of new position
		var list = dragState.itemList;
		if (!list||!list.length) {
			return;
		}

		var newIndex = Math.floor(my / dragState.itemHeight);
		newIndex = (newIndex<0) ? 0 : newIndex;
		newIndex = (newIndex>=list.length) ? list.length-1 : newIndex;

		// find new indent
		var dragIndent = Math.floor(mx / 30);
		var newIcon = '';

		// determine what kind of operation this is:
		// vertical motion is a move
		// sideways motion is an indent
		if (!dragState.operation) {
			if (newIndex!=dragState.itemIndex) {
				dragState.operation = 'move';
			}
			else if (dragState.itemIndent!=='' && (Math.abs(mx)>10)) {
				dragState.operation = 'indent';
			}
		}

		switch (dragState.operation) {
		case 'move':
			newIcon = (newIndex>dragState.itemIndex)?'deepsee/ds2_arrow_south_44.png':'deepsee/ds2_arrow_north_44.png';
			dragDiv.style.top = my - (dragState.itemHeight/2) + 'px';

			// find new index of drag item
			var newIndex = Math.round(my / dragState.itemHeight);
			newIndex = (newIndex<0) ? 0 : newIndex;
			newIndex = (newIndex>=list.length) ? list.length-1 : newIndex;
			newIndex = (newIndex>=dragState.firstIndex) ? newIndex : dragState.firstIndex;
			newIndex = (newIndex<=dragState.lastIndex) ? newIndex : dragState.lastIndex;

			// test indent level
			var testItem = nav.findItemByIndex(newIndex);
			var testIndent = zenGet(testItem.indent,0);

			// items on different levels or out of range; do not move
			if ((dragState.itemNewIndex!=newIndex)&&(dragState.itemIndent==testIndent)) {
				dragState.itemNewIndex = newIndex;
				dragState.moveCount++;
				
				// make copy of orderList in new order
				var orderList = [];
				for (var n = 0;n < list.length;n++) {
					orderList[orderList.length] = n;
				}
				orderList.splice(dragState.itemIndex,1);
				orderList.splice(newIndex,0,dragState.itemIndex);
				dragState.ghostDiv.innerHTML = nav.getGhostHTML(dragState.itemList,orderList,newIndex);

				// invoke callback
				var oldPos = dragState.moveMap ? dragState.moveMap[dragState.itemIndex] : dragState.itemIndex;
				var newPos = dragState.moveMap ? dragState.moveMap[dragState.itemNewIndex] : dragState.itemNewIndex;
				zenInvokeCallbackMethod(nav.onarrange,nav,'onarrange','swap',
					{index:dragState.itemIndex, oldPosition:oldPos, newPosition:newPos},
					'key',dragState.itemKey,'final',false);
			}
			break;
		case 'indent':
			var indent = dragState.itemIndent;
			newIcon = (dragIndent < indent) ? 'deepsee/ds2_arrow_west_44.png' : 'deepsee/ds2_arrow_east_44.png';
			if (dragIndent < indent) {
				// slide out
				indent = indent <=1 ? 0 : indent-1;
			}
			else if (dragIndent > indent) {
				// slide in
				indent = indent+1;
			}
			var currItem = nav.findItemByIndex(dragState.itemIndex);
			if (indent != zenGet(currItem.indent)) {

				// invoke callback
				var oldPos = dragState.moveMap ? dragState.moveMap[dragState.itemIndex] : dragState.itemIndex;
				var newPos = dragState.moveMap ? dragState.moveMap[dragState.itemNewIndex] : dragState.itemNewIndex;
				zenInvokeCallbackMethod(nav.onindent,nav,'onindent','swap',
					{index:dragState.itemIndex, oldIndent:currItem.indent, newIndent:indent},
					'key',dragState.itemKey,'final',false);
			}
			break;
		}

		if (newIcon) {
			// replace drag icon
			if (dragDiv.childNodes && dragDiv.childNodes.length) {
				for (var n = 0; n < dragDiv.childNodes.length; n++) {
					if (dragDiv.childNodes[n].className=='navItemDragHandle') {
						var src = newIcon;
						var left = dragState.itemIndent * 24;
						dragDiv.childNodes[n].style.opacity = 1.0;
						dragDiv.childNodes[n].innerHTML = '<image style="opacity:1.0;height:24px;left:'+left+'px;position:absolute;" src="'+src+'"/>';
					}
				}
			}
		}

	}
}

/// Click handler for item in sheet.
ClientMethod clickHandler(evt, index, forceDrill) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	var item = this.findItemByIndex(index);
	if (item && item.disabled) {
		return;
	}
	this.selectItem(index,zenGet(forceDrill,false));
}

/// Return the item with the given index (and optional level).
ClientMethod findItemByIndex(index, level) [ Language = javascript ]
{
	level = zenGet(level,this.currLevel);
	var item = null;
	if (this._dataStack && this._dataStack[level]) {
		item = this._dataStack[level][index];
	}
	return item;
}

/// Start editing within the item with the given index.
ClientMethod startEdit(index) [ Language = javascript ]
{
	if (this._editMode&&(index!=this._editIndex)) {
		this.stopEdit(this._editIndex);
	}
	
	if (!this._editMode) {
		var item = this.findItemByIndex(index);
		if (item) {
			// turn on editor
			var div = this.getItemDiv(this.currLevel,index);
			if (div) {
				var content = this.getItemContent(index,item,true);
				div.innerHTML = content;
			}
		}
		// remember who is in edit mode
		this._editMode = true;
		this._editIndex = index;
		this.giveFocusToControl();
	}
}

/// Stop editing within the item with the given index.
ClientMethod stopEdit(index, cancel) [ Language = javascript ]
{
	cancel = zenGet(cancel,false);

	if (this._editMode) {
		var item = this.findItemByIndex(index);
		if (item) {
			var edit = zenGet(item.edit);
			var ctrl = this.findElement('control_'+this.currLevel);
			if (ctrl && !cancel) {
				// change value in local copy of model
				item.value = ctrl.value;
				
				// invoke callback
				var key = zenGet(item.key);
				zenInvokeCallbackMethod(this.onchange,this,'onchange','value',ctrl.value,'key',key,'final',true);
			}

			// turn off editor
			var div = this.getItemDiv(this.currLevel,index);
			if (div) {
				var content = this.getItemContent(index,item,false);
				div.innerHTML = content;
			}
		}
	}

	this._editMode = false;
	this._editIndex = -1;
}

/// Select the item with the given index.
ClientMethod selectItem(index, forceDrill) [ Language = javascript ]
{
	var item = this.findItemByIndex(index);
	forceDrill = zenGet(forceDrill,false);

	var oldIndex = -1;
	if (this._selectedStack) {
		oldIndex = this._selectedStack[this.currLevel];
		this._selectedStack[this.currLevel] = index;
	}

	if (item) {
		var action = zenGet(item.action);
		var key = zenGet(item.key);
		var edit = zenGet(item.edit);

		// cancel edit mode
		if (this._editMode && (this._editIndex!=index)) {
			this.stopEdit(this._editIndex);
		}

		// edit mode?
		if (edit!='' && !forceDrill) {
			if (!this.editMode) {
				this.startEdit(index);
			}
			return;
		}

		switch (action) {
		case 'drill':
			// drill down
			if (key!='') {
				// invoke onselect if present
				zenInvokeCallbackMethod(this.onselect,this,'onselect','value',zenGet(item.value),'key',key,'which','drill');

				var enc = this.getEnclosingDiv();
				enc.scrollTop = 0;
				enc.scrollLeft = 0;
				this.slideInto(item);
			}
			break;

		case 'select':
			// select the current value;
			// invoke callback
			var key = zenGet(item.key);
			zenInvokeCallbackMethod(this.onselect,this,'onselect','value',zenGet(item.value),'key',key,'which','select');
			break;

		case 'link':
			// navigate to link using value as url;
			// !!! what document to use !!!
			if (item.value) {
				try {  // Add defensive coding to avoid IE double unload bug
					self.document.location = item.value;
				}
				catch(ex) {
				}
			}
			break;

		case 'apply':
			// apply current value to our parent item
			// display&value !!!!
			this.applyValue(zenGet(item.value));
			break;
		}
	}
}

/// Apply the value <var>value</var> and display value <var>display</var> to the current item.
/// <var>display</var> is not passed to the callback. You can get it via the
/// <var>currDisplayValue</var> property of this component.<br/>
/// If <var>pop</var> is true, pop the current frame on the navigator.
ClientMethod applyValue(value, display, pop) [ Language = javascript ]
{
	pop = zenGet(pop,true);
	var parent = this._itemSpecStack[this.currLevel];
	if (parent) {
		parent.value = value;
	}
	// invoke callback
	var parentKey = parent ? zenGet(parent.key) : '';

	// make display value available
	this.currDisplayValue = display;
	zenInvokeCallbackMethod(this.onchange,this,'onchange','value',value,'key',parentKey,'final',pop);
	if (pop) {
		this.slideOutOf();
	}
}

ClientMethod collectValue(value, final) [ Language = javascript ]
{
	// + WAL083 (3) -- if this isn't the final submission, collect the value by storing it in the parent value
	var parent = this._itemSpecStack[this.currLevel];
	if (parent) {
		if (!final) {
			var add = true;
			// if this value is already in the list, remove it
			var valueArray = [];
			valueArray = parent.value.split(',');
			for (var i = 0; i < valueArray.length; i++) {
				if (valueArray[i] == value) {
					add = false;
					valueArray.splice(i,1);	
					parent.value = valueArray.join(',');
					break;
				}
			}
			if (add) {
				if (parent.value.length > 0) { 
					parent.value += ',' + value;
				}
				else {
					parent.value += value;	
				}
			}
			this.refreshTopSheet();  // WAL083 (4) -- redraw the list after making a selection
		}
		value = parent.value;
	}
	if (final) { 
		this.applyValue(value,'',true);
	}
	// - WAL083 (3)
}

ClientMethod clearValue() [ Language = javascript ]
{
	// + WAL083 (3)
	var parent = this._itemSpecStack[this.currLevel];
	if (parent) {
		// Unselect all values
		parent.value = '';
		this.refreshTopSheet();
	}
	// - WAL083 (3)
}

/// Do a trial application of the value <var>value</var> to the current item.
/// This is used by mouse-over on certain controls.
ClientMethod tryValue(value, tryLevel) [ Language = javascript ]
{
	// n.b. if tryLevel does not match, then this is being called 
	// *after* the current sheet has been popped
	if (tryLevel == this.currLevel) {
		// final is false for tryValue
		this.applyValue(value,'',false);
	}
}

/// Return the spec object for the current frame.
ClientMethod getCurrSpec() [ Language = javascript ]
{
	return this._itemSpecStack[this.currLevel];
}

/// Return the spec object for the parent of the current frame.
ClientMethod getParentSpec() [ Language = javascript ]
{
	return this.currLevel>0 ? this._itemSpecStack[this.currLevel-1]:null;
}

/// Find the div element for the given item level and index.
ClientMethod getItemDiv(level, index) [ Language = javascript ]
{
	return this.findElement('item_' + level + '_' + index);
}

/// Give focus to the current input control.
ClientMethod giveFocusToControl() [ Language = javascript ]
{
	var ctrl = this.findElement('control_'+this.currLevel);
	if (ctrl) {
		ctrl.select();
		ctrl.focus();
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'disabled':
		this[property] = value ? true : false;
		this.refreshTopSheet();
		break;

	case 'columnWidth':
		this.setWidth(value);
		break;

	case 'headerHeight':
	case 'footerHeight':
	case 'showDisclosure':
	case 'disclosureWidth':
	case 'expanded':
	case 'backgroundStyle':
		this[property] = value;
		this.render();
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Return HTML for a value editor.
/// This draws an edit control within an item.
ClientMethod getHTMLForEditor(index, item, active, disabled) [ Language = javascript ]
{
	var html = [];
	var display = zenGet(item.display,'caption');
	var edit = zenGet(item.edit,'string');
	var value = zenGet(item.value);
	var text = zenGet(item.text,value);
	var title = zenGet(item.title);

	var style = ''
	switch (display) {
	case 'caption-value':
	case 'caption-value-vt':
	case 'image-caption-value-vt':
		style = 'font-size:10px;'
		break;	

	default:
		style = 'font-size:12px;'
		break;	
	}

	// n.b. don't stop edit when control loses focus-- this causes timing issues!
	switch (edit) {
	case 'number':
	case 'integer':
	case 'string':
	default:
		var cstyle = '';
		var cwidth = 120;
		if (edit=='string') {
			var cwidth = parseInt(this.columnWidth,10) - 200;
			if (active && !disabled) {
				cwidth += 40;
			}
		}

		if (!active || disabled) {
			var newCaption = {};
			var nsz = this.findTextSize(text,"navControlWrap",'font-size:18px;',cwidth+20,newCaption);
			if (newCaption.caption) {
				text = newCaption.caption;
			}
			if (nsz) {
				cstyle += 'font-size:' + nsz + 'px;';
			}
		}

		html[html.length] = '<div class="navControlWrap" style=width:'+cwidth+'px;'+cstyle+'" onclick="zenPage.getComponent('+this.index+').editClick(event,'+index+');" title="'+zenEscapeXML(title)+'">';
		if (active && !disabled) {
			// input control
			html[html.length] = '<input id="'+this.makeId('control_'+this.currLevel)+'" "type="text" class="navControl" style="'+style+'width:'+(cwidth-44)+'px;height:22px;" value="'+zenEscapeXML(value)+'" onkeypress="zenPage.getComponent('+this.index+').editKeyPressHandler(event,'+index+');" onkeyup="return zenPage.getComponent('+this.index+').editKeyUpHandler(event,'+index+');"/>';

			// ok, cancel buttons
			html[html.length] = '<image class="navControlBtn" src="deepsee/ds2_check_44.png" style="left:'+(cwidth-40)+'px;" onclick="zenPage.getComponent('+this.index+').editControlApply(event,'+index+');"/>';
			html[html.length] = '<image class="navControlBtn" src="deepsee/ds2_x_44.png" style="left:'+(cwidth-20)+'px;" onclick="zenPage.getComponent('+this.index+').editControlCancel(event,'+index+');"/>';
		}
		else {
			// just show value
			html[html.length] = zenEscapeXML(text);
		}
		html[html.length] = '</div>';
		break;
	case 'plotbar':
	case 'plotbar-value':
		// show value as simple plot bar
		var width = (edit=='plotbar-value') ? 100 : 120;
		var leftAdj = 0;

		var left = 0; 
		var minValue = parseFloat(zenGet(item.minValue,0));
		var maxValue = parseFloat(zenGet(item.maxValue,1));
		var range = maxValue - minValue;
		var isNull = zenGet(item.value)==='';
		var val = parseFloat(zenGet(item.value));
		val = isNaN(val) ? 0 : val;
		if (range != 0 && !isNaN(range)) {
			left = 0 + ((val/range)*(width));
		}
		if (disabled) {
			html[html.length] = zenEscapeHTML(text);
		}
		else {
			html[html.length] = '<div class="navPlotbar" style="width:'+width+'px;">';
			if (edit=='plotbar-value') {
				// show value
				var text = zenGet(item.text,val);
				html[html.length] = '<div style="position:absolute;left:'+102+'px;">' + zenEscapeXML(text) + '</div>';
			}
		
			// box
			html[html.length] = '<div class="navPlotbarBox" style="z-index:3;left:'+(leftAdj)+'px;width:'+(width-4)+'px;">&nbsp;</div>';

			// value
			html[html.length] = '<div class="navPlotbarValue" style="z-index:3;width:'+(left)+'px;">&nbsp;</div>';

			html[html.length] = '</div>';
		}
		break;

	case 'choice':
	case 'choice-multi':
		// show small set of choices as buttons
		var valueList = zenGet(item.valueList);
		var displayList = zenGet(item.displayList);
		displayList = displayList=='' ? valueList : displayList;
		var isMulti = (edit=='choice-multi');

		var vlist = valueList.toString().split(',');
		var dlist = displayList.toString().split(',');
		var count = vlist.length;

		// if there is an imageList, use it
		if (item.imageList) {
			var imageList = item.imageList.toString().split(',');
			for (var xi = 0; xi < count; xi++) {
				if (imageList[xi]) {
					dlist[xi] = '<image src="'+imageList[xi]+'" style=""/>';
				}
			}
		}

		// list of styles to apply to choices
		var styleList = zenGet(item.choiceStyles).toString().split('^');
		if (isMulti) {
			var currValues = {};
			var cv = value.toString().split(',');
			for (var n = 0; n < cv.length; n++) {
				currValues[cv[n]] = true;
			}
		}

		html[html.length] = '<div style="position:relative;height:20px;">';

		if (count > 0) {
			var wid = (this.columnWidth - 190) / count;
			var x = 0;

			for (var n = 0; n<count; n++) {
				var st = zenGet(item.valueStyle);
				if (n==0) {
					st += 'border-top-left-radius:5px;border-bottom-left-radius:5px;';
				}
				if (n==(count-1)) {
					st += 'border-top-right-radius:5px;border-bottom-right-radius:5px;';
				}
				if (styleList[n]) {
					st += styleList[n];
				}

				var cls = 'navChoice';
				var test = zenGet(vlist[n]);
				if (isMulti) {
					if (test&&currValues[test]) {
						cls = 'navChoiceSelected';
					}
				}
				else {
					if (test==zenGet(item.value)) {
						cls = 'navChoiceSelected';
					}
				}
				cls = disabled ? (cls+'Disabled') : cls;

				html[html.length] = '<div id="'+this.makeId('choice_'+this.currLevel+'_'+index+'_'+n)+'" class="'+cls+'" style="left:'+x+'px;width:'+wid+'px;border:1px solid #808080;'+st+'" ';
				if (!disabled) {
					html[html.length] = 'onclick="zenPage.getComponent('+this.index+').choiceClick(event,'+(isMulti?'true':'false')+','+index+','+n+',\''+zenGet(vlist[n])+'\');';
				}
				html[html.length] = '">'+zenGet(dlist[n])+'</div>';
				x += wid;
			}
		}
		html[html.length] = '</div>';

		break;
	case 'slider':
	case 'slider-toggle':
		var totalWidth = 130;
		var width = totalWidth - 30;

		var leftAdj = 0;

		var left = 0; 
		var minValue = parseFloat(zenGet(item.minValue,0));
		var maxValue = parseFloat(zenGet(item.maxValue,1));
		var range = maxValue - minValue;
		
		if (this.showSliderValue) {
			var textWidth = 30;
			width = width - textWidth;
			item.renderWidth = width;
			item.range = range;
			var boxRight = 18;
		}

		var isNull = zenGet(item.value)==='';
		var val = parseFloat(zenGet(item.value));
		val = isNaN(val) ? 0 : val;
		if (range != 0 && !isNaN(range)) {
			left = 0 + ((val/range)*(width-20));
		}
		if (disabled) {
			html[html.length] = zenEscapeHTML(text);
		}
		else {
			html[html.length] = '<div class="navSlider" style="width:'+totalWidth+'px;">';
			if (edit=='slider-toggle') {
				// show toggle checkbox
				html[html.length] = '<input type="checkbox" id="'+this.makeId('toggle_'+this.currLevel+'_'+index)+'" '+(!isNull?'checked="1"':'')+' style="position:absolute;right:0px;" onclick="zenPage.getComponent('+this.index+').sliderToggleClick(event,'+index+');"/>';
			}
			if (this.showSliderValue) {
				html[html.length] = '<input type="text" value="'+val+'" class="navSliderTxt" id="'+this.makeId('sliderValue_'+this.currLevel+'_'+index)+'" style="position:absolute;right:'+boxRight+'px;" onchange="zenPage.getComponent('+this.index+').sliderValueChange(event,'+index+');"/>';
			}
		
			// track
			html[html.length] = '<div id="'+this.makeId('track_'+this.currLevel+'_'+index)+'" class="navSliderTrack" style="z-index:3;left:'+(leftAdj)+'px;width:'+(width-4)+'px;">&nbsp;</div>';

			// track (active)
			html[html.length] = '<div id="'+this.makeId('trackActive_'+this.currLevel+'_'+index)+'" class="navSliderTrackActive" style="z-index:3;width:'+(left)+'px;">&nbsp;</div>';

			// thumb
			html[html.length] = '<div id="'+this.makeId('thumb_'+this.currLevel+'_'+index)+'" class="navSliderThumb" style="z-index:4;left:'+left+'px;" onmousedown="zenPage.getComponent('+this.index+').sliderMouseDown(event,'+index+');" ontouchstart="zenPage.getComponent('+this.index+').sliderTouchStart(event,'+index+');">'+'&nbsp;'+'</div>';

			html[html.length] = '</div>';
		}
		break;
	case 'stepper':
	case 'stepper-value':
		var showValue = edit=='stepper-value';
		var width = showValue ? 80 : 40;
		var left2 = showValue ? 60 : 20;
		if (disabled) {
			html[html.length] = zenEscapeHTML(text);
		}
		else {
			html[html.length] = '<div class="navStepper" style="position:relative;border:1px solid #808080;width:'+width+'px;height:20px;border-radius:3px;font-size:20px;font-weight:bold;">';
			html[html.length] = '<div class="navStepperBtn" style="top:50%;margin-top:-14px;position:absolute;left:0px;width:18px;text-align:center;height:20px;" onmousedown="zenPage.getComponent('+this.index+').stepperMouseDown(\'down\','+index+');" onmouseup="zenPage.getComponent('+this.index+').stepperMouseUp(\'down\','+index+');">'+'-'+'</div>';

			if (showValue) {
				// round non-integer to 2 decimal places
				if (!isNaN(parseFloat(text)) && Math.floor(parseFloat(text))!=parseFloat(text)) {
					text = text.toFixed(2);
				}
				html[html.length] = '<div style="text-align:center;top:50%;margin-top:-8px;position:absolute;left:20px;width:40px;font-size:14px;text-align:center;height:20px;">';
				html[html.length] = zenEscapeHTML(text);
				html[html.length] = '</div>';
			}

			html[html.length] = '<div class="navStepperBtn" style="top:50%;margin-top:-12px;position:absolute;left:'+left2+'px;width:18px;text-align:center;height:20px;" onmousedown="zenPage.getComponent('+this.index+').stepperMouseDown(\'up\','+index+');" onmouseup="zenPage.getComponent('+this.index+').stepperMouseUp(\'up\','+index+');">'+'+'+'</div>';

			html[html.length] = '</div>';
		}
		break;

	case 'switch':
		var flag = text ? true : false;
		var bg = flag ? 'rgb(53,107,141)' : 'white';
		var color = flag ? '#F0F0F0' : '#404040;';

		// JMD1272
		if (this.language.toString().substr(0,2) == 'en') {
			var onText = 'ON';
			var offText = 'OFF';
		}
		else {
			var onText = 1;
			var offText = 0;
		}

		if (disabled) {
			html[html.length] = flag ? onText : offText;
		}
		else {
			html[html.length] = '<div style="position:relative;border:1px solid #808080;border-radius:10px;width:60px;height:20px;background:'+bg+';font-size:15px;font-weight:bold;color:'+color+';" onclick="zenPage.getComponent('+this.index+').toggleSwitch('+index+');">';
			if (flag) {
				html[html.length] = '<div style="padding-top:1px;position:absolute;left:0px;width:40px;text-align:center;height:20px;">'+onText+'</div>';
				html[html.length] = '<div class="navSwitch" style="position:absolute;left:40px;width:20px;text-align:center;height:20px;border-radius:10px;">'+'&nbsp;'+'</div>';
			}
			else {
				html[html.length] = '<div class="navSwitch" style="position:absolute;left:0px;width:20px;text-align:center;height:20px;border-radius:10px;">'+'&nbsp;'+'</div>';
				html[html.length] = '<div style="padding-top:1px;position:absolute;left:20px;width:40px;text-align:center;height:20px;">'+offText+'</div>';
			}
			html[html.length] = '</div>';
		}
		break;
	}
	return html.join('');
}

/// Toggle value of switch control.
ClientMethod toggleSwitch(index) [ Language = javascript ]
{
	var item = this.findItemByIndex(index);
	if (item) {
		// toggle value
		item.value = item.value ? false : true;

		// invoke callback
		var key = zenGet(item.key);
		zenInvokeCallbackMethod(this.onchange,this,'onchange','value',item.value,'key',key,'final',true);

		// update item
		var div = this.getItemDiv(this.currLevel,index);
		if (div) {
			var content = this.getItemContent(index,item,false);
			div.innerHTML = content;
		}
	}
}

/// Mouse down on stepper control.
ClientMethod stepperMouseDown(which, index) [ Language = javascript ]
{
	this.stepperAction(which,index,200);
}

/// Apply stepper action
ClientMethod stepperAction(which, index, delay) [ Language = javascript ]
{
	if (this._stepperTimer) {
		window.clearTimeout(this._stepperTimer);
	}

	var item = this.findItemByIndex(index);
	if (item) {
		var minValue = parseFloat(zenGet(item.minValue,0));
		var maxValue = parseFloat(zenGet(item.maxValue,100));
		var stepSize = parseFloat(zenGet(item.stepSize,1));

		var delta = which=='down'?-stepSize:stepSize;
		var oldValue = zenGet(item.value);
		var startValue = isNaN(parseFloat(oldValue)) ? 0 : parseFloat(oldValue);
		item.value = startValue + delta;
		
		item.value = item.value >= maxValue ? maxValue : item.value;
		item.value = item.value <= minValue ? minValue : item.value;

		// invoke callback
		if (oldValue != zenGet(item.value)) {
			var key = zenGet(item.key);
			zenInvokeCallbackMethod(this.onchange,this,'onchange','value',item.value,'key',key,'final',false);

			// update item
			var div = this.getItemDiv(this.currLevel,index);
			if (div) {
				var content = this.getItemContent(index,item,false);
				div.innerHTML = content;
			}
		}
		// set up timer for repeat action
		if ((which=='down' && item.value>minValue)||(which=='up' && item.value<maxValue)) {
			delay = (parseInt(delay,10) > 50) ? parseInt(delay,10) - 10 : 50;
			this._stepperTimer = window.setTimeout("zenPage.getComponent(" + this.index + ").stepperAction(\'"+which+"\',"+index+","+delay+")",delay);
		}
	}
}

/// Mouse up on stepper control.
ClientMethod stepperMouseUp(which, index) [ Language = javascript ]
{
	if (this._stepperTimer) {
		window.clearTimeout(this._stepperTimer);
		this._stepperTimer = null;
	}
	var item = this.findItemByIndex(index);
	if (item) {
		var key = zenGet(item.key);
		zenInvokeCallbackMethod(this.onchange,this,'onchange','value',item.value,'key',key,'final',true);
	}
}

/// Apply button for edit control.
ClientMethod editControlApply(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	this.stopEdit(index,false);
}

/// Cancel button for edit control.
ClientMethod editControlCancel(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	this.stopEdit(index,true);
}

/// Key press handler for edit control.
ClientMethod editKeyPressHandler(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	// trap keys
	switch(evt.keyCode) {
	case zenENTER:
		this.stopEdit(index);
		break;
	}
}

/// Key up handler for edit control.
ClientMethod editKeyUpHandler(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (this._editMode && this.onchange) {
		var item = this.findItemByIndex(index);
		if (item) {
			var edit = zenGet(item.edit);
			var ctrl = this.findElement('control_'+this.currLevel);
			if (ctrl) {
				// invoke callback (non-final)
				var key = zenGet(item.key);
				zenInvokeCallbackMethod(this.onchange,this,'onchange','value',ctrl.value,'key',key,'final',false);
			}
		}
	}

	return true;
}

/// Mouse click on edit control.
ClientMethod editClick(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (index!=this._editIndex) {
		if (evt && evt.stopPropagation) {
			evt.stopPropagation();
		}
		this.startEdit(index);
	}
	return true;
}

/// Mouse click handler for choice control.
/// <var>multi</var> is true for choice-multi.
ClientMethod choiceClick(evt, multi, index, choiceNo, newValue) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	// unselect
	if (!multi) {
		for (var n = 0; n < 99; n++) {
			var div = this.findElement('choice_'+this.currLevel+'_'+index+'_'+n);
			if (div) {
				div.className = 'navChoice';
			}
			else {
				break;
			}
		}
	}

	// select/toggle new item
	var div = this.findElement('choice_'+this.currLevel+'_'+index+'_'+choiceNo);
	if (div) {
		if (multi) {
			div.className = (div.className=='navChoiceSelected') ? 'navChoice' : 'navChoiceSelected';

			var valueList = [];
			var item = this.findItemByIndex(index);
			if (item) {
				valueList = item.valueList.toString().split(',');
			}

			// compute newValue
			var vals = [];
			for (var n = 0; n < valueList.length; n++) {
				var div = this.findElement('choice_'+this.currLevel+'_'+index+'_'+n);
				if (div) {
					if (div.className=='navChoiceSelected') {
						vals[vals.length] = valueList[n];
					}
				}
				else {
					break;
				}
			}
			newValue = vals.join(',');
		}
		else {
			div.className = 'navChoiceSelected';
		}
	}
	var item = this.findItemByIndex(index);
	if (item) {
		// invoke callback
		var key = zenGet(item.key);
		if (item.value != newValue) {
			item.value = newValue;
			zenInvokeCallbackMethod(this.onchange,this,'onchange','value',item.value,'key',key,'final',true);
		}
	}
}

/// Notification that the user has entered an explicit value in the value text box.
ClientMethod sliderValueChange(event, index) [ Language = javascript ]
{
	var item = this.findItemByIndex(index);
	var minValue = parseFloat(zenGet(item.minValue,0));
	var maxValue = parseFloat(zenGet(item.maxValue,1));
	var stepSize = parseFloat(zenGet(item.stepSize,''));
	var width = parseInt(zenGet(item.renderWidth,100));
	var range = parseFloat(zenGet(item.range,1));
	var defaultValue = parseFloat(zenGet(item.defaultValue,maxValue));
	var oldValue = parseFloat(zenGet(item.value,defaultValue));
	var intVal = (stepSize==Math.floor(stepSize)); // Integer values only?

	var txtBox = event.target;
	var value = txtBox.value; // At this point value is a string
	if (!value || isNaN(value)) {  // if parsing would fail revert to old value 
		value = oldValue ;
	}
	else {
		value = parseFloat(value);
	}
	// Sanitize the user input to match constraints
	if (value<minValue) value = minValue;
	if (value>maxValue) value = maxValue;

	if (!isNaN(stepSize) && stepSize!=0) {
		value = Math.floor(value/stepSize)*stepSize;
		value = intVal ? Math.round(value) : value;
	}
	
	value = parseFloat(value.toString().substring(0,5));

	txtBox.value = value;

	var track = this.findElement('track_'+this.currLevel+'_'+index);
	var activeTrack = this.findElement('trackActive_'+this.currLevel+'_'+index);
	var thumb = this.findElement('thumb_'+this.currLevel+'_'+index);

	if (range != 0 && !isNaN(range)) {
		if (oldValue != value) {
			var toggle = this.findElement('toggle_'+this.currLevel+'_'+index);
			if (toggle && !toggle.checked) {
				toggle.checked = true;
			}
			this.sliderChanged(index,value,true); 
			left = (value/range)*(width-20);
			thumb.style.left = left + 'px';
			activeTrack.style.width =  left + 'px';
		}
	}
	event.preventDefault();
}

/// Notification that a slider has moved.
/// <var>newValue</var> is the new value.
ClientMethod sliderChanged(index, newValue, final) [ Language = javascript ]
{
	var item = this.findItemByIndex(index);
	var txtBox = this.findElement('sliderValue_'+this.currLevel+'_'+index);
	if (txtBox && newValue!='') txtBox.value = newValue;
	if (item) {
		// invoke callback
		var key = zenGet(item.key);
		item.value = newValue;
		zenInvokeCallbackMethod(this.onchange,this,'onchange','value',item.value,'key',key,'final',final);
	}
}

/// Raise the onchange event for this navigator.
/// This is used by custom content.
ClientMethod raiseChange(key, value, final) [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.onchange,this,'onchange','value',value,'key',key,'final',final);
}

/// Click on slider toggle checkbox.
ClientMethod sliderToggleClick(evt, index) [ Language = javascript ]
{
	var toggle = this.findElement('toggle_'+this.currLevel+'_'+index);
	if (!toggle.checked) {
		this.sliderChanged(index,'',true);
	}
}

/// TouchStart down handler for slider control.
ClientMethod sliderTouchStart(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	var t=evt.touches;
	if (t.length==1) { // NOT the start of a multi-touch gesture...

		// connect touch handlers to window
		if (document.ontouchmove != this.sliderTouchMove) {
			this._oldTouchMove = document.ontouchmove;
			document.ontouchmove = this.sliderTouchMove;
		}
		if (document.ontouchend != this.sliderTouchEnd) {
			this._oldTouchEnd = document.ontouchend;
			document.ontouchend = this.sliderTouchEnd;
		}
	
		zenPage._componentIndex = this.index;
		zenPage._sliderIndex = index;
		evt.preventDefault();
	}
}

/// Touch end handler for slider control (connected to window).
ClientMethod sliderTouchEnd(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	// raise final changed event
	var slider = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);
	if (slider) {
		var index = zenPage._sliderIndex;
		var item = slider.findItemByIndex(index);
		if (item) {
			slider.sliderChanged(index,item.value,true);
		}
	}

	// remove mouse handlers from window
	document.ontouchend = this._oldTouchEnd;
	this._oldTouchEnd = null;
	document.ontouchend = this._oldTouchEnd;
	this._oldTouchEnd = null;
	evt.preventDefault();
	zenPage._componentIndex = null;
	zenPage._sliderIndex = null;
}

/// Touch move handler for slider control.
ClientMethod sliderTouchMove(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var t=evt.touches;
	var index = zenPage._sliderIndex;
	var slider = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);
	if (slider) {
		var track = slider.findElement('track_'+slider.currLevel+'_'+index);
		var activeTrack = slider.findElement('trackActive_'+slider.currLevel+'_'+index);
		var thumb = slider.findElement('thumb_'+slider.currLevel+'_'+index);
		
		var width = parseInt(track.offsetWidth,10) + 2; 	// border
		var tleft = zenGetLeft(track);

		var x = (t[0].clientX-12) - tleft;
		x = (x<=0) ? 0 : x;
		x = (x>=(width-20))?width-20:x;

		// compute new value
		var item = slider.findItemByIndex(index);
		var minValue = parseFloat(zenGet(item.minValue,0));
		var maxValue = parseFloat(zenGet(item.maxValue,1));
		var stepSize = parseFloat(zenGet(item.stepSize,''));
		var range = maxValue - minValue;
		
		// integer values?
		var intVal = (stepSize==Math.floor(stepSize));
	
		if (range != 0 && !isNaN(range)) {
			var newValue = minValue + ((x/(width-20)) * range);
			if (!isNaN(stepSize) && stepSize!=0) {
				newValue = Math.floor(newValue/stepSize)*stepSize;
				newValue = intVal ? Math.round(newValue) : newValue;
			}
			var value = zenGet(item.value);
			if (newValue != value) {
				var toggle = slider.findElement('toggle_'+slider.currLevel+'_'+index);
				if (toggle && !toggle.checked) {
					toggle.checked = true;
				}
				slider.sliderChanged(index,newValue,false);
				left = (newValue/range)*(width-20);
				thumb.style.left = x + 'px';
				activeTrack.style.width =  x + 'px';
			}
		}
	}
	evt.preventDefault();
}

/// Mouse down handler for slider control.
ClientMethod sliderMouseDown(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	// connect mouse handlers to window
	if (document.onmousemove != this.sliderMouseMove) {
		this._oldMouseMove = document.onmousemove;
		document.onmousemove = this.sliderMouseMove;
	}
	if (document.onmouseup != this.sliderMouseUp) {
		this._oldMouseUp = document.onmouseup;
		document.onmouseup = this.sliderMouseUp;
	}
	
	zenPage._componentIndex = this.index;
	zenPage._sliderIndex = index;
}

/// Mouse up handler for slider control (connected to window).
ClientMethod sliderMouseUp(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	// raise final changed event
	var slider = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);
	if (slider) {
		var index = zenPage._sliderIndex;
		var item = slider.findItemByIndex(index);
		if (item) {
			slider.sliderChanged(index,item.value,true);
		}
	}

	// remove mouse handlers from window
	if (this._oldMouseMove) {
		document.onmousemove = this._oldMouseMove;
	}
	this._oldMouseMove = null;
	if (this._oldMouseUp) {
		document.onmouseup = this._oldMouseUp;
	}
	this._oldMouseUp = null;
	zenPage._componentIndex = null;
	zenPage._sliderIndex = null;
}

/// Mouse move handler for slider control (connected to window).
ClientMethod sliderMouseMove(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var index = zenPage._sliderIndex;
	var slider = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);
	if (slider) {
		var track = slider.findElement('track_'+slider.currLevel+'_'+index);
		var activeTrack = slider.findElement('trackActive_'+slider.currLevel+'_'+index);
		var thumb = slider.findElement('thumb_'+slider.currLevel+'_'+index);
		
		var width = parseInt(track.offsetWidth,10) + 2; 	// border
		var tleft = zenGetLeft(track);

		var x = (evt.clientX-12) - tleft;
		x = (x<=0) ? 0 : x;
		x = (x>=(width-20))?width-20:x;

		// compute new value
		var item = slider.findItemByIndex(index);
		var minValue = parseFloat(zenGet(item.minValue,0));
		var maxValue = parseFloat(zenGet(item.maxValue,1));
		var stepSize = parseFloat(zenGet(item.stepSize,''));
		var range = maxValue - minValue;
		
		// integer values?
		var intVal = (stepSize==Math.floor(stepSize));
	
		if (range != 0 && !isNaN(range)) {
			var newValue = minValue + ((x/(width-20)) * range);
			if (!isNaN(stepSize) && stepSize!=0) {
				newValue = Math.floor(newValue/stepSize)*stepSize;
				newValue = intVal ? Math.round(newValue) : newValue;
			}
			var value = zenGet(item.value);
			if (newValue != value) {
				var toggle = slider.findElement('toggle_'+slider.currLevel+'_'+index);
				if (toggle && !toggle.checked) {
					toggle.checked = true;
				}
				slider.sliderChanged(index,newValue,false);
				left = (newValue/range)*(width-20);
				thumb.style.left = x + 'px';
				activeTrack.style.width =  x + 'px';
			}
		}
	}
}

/// Reveal the iframe component.
ClientMethod revealFrame(frame) [ Internal, Language = javascript ]
{
	frame.style.opacity = 1.0;
	this.endWait();
}

/// Display a message for this form.
ClientMethod showMessage(msg) [ Language = javascript ]
{
	this.showOverlay('<div class="bformMsg">'+msg+'</msg>');
}

/// Hide the message for this form.
ClientMethod hideMessage() [ Language = javascript ]
{
	this.hideOverlay();
}

/// Start "wait" state.
ClientMethod beginWait() [ Language = javascript ]
{
	this.showOverlay('<img src="images/wait.gif"/>');
}

/// End "wait" state .
ClientMethod endWait() [ Language = javascript ]
{
	this.hideOverlay();
}

/// Show the given content in the overlay.
ClientMethod showOverlay(content) [ Language = javascript ]
{
	var overlay = this.findElement('overlay');
	if (overlay) {
		overlay.innerHTML = content;

		var div = this.getEnclosingDiv();
		overlay.style.top = (div.offsetHeight - overlay.offsetHeight)/2 + 'px';
		overlay.style.left = (this.columnWidth - overlay.offsetWidth)/2 + 'px';

		overlay.style.visibility = 'visible';
		overlay.style.opacity = 1.0;
	}
}

/// Hide the overlay.
ClientMethod hideOverlay() [ Language = javascript ]
{
	var overlay = this.findElement('overlay');
	if (overlay) {
		overlay.innerHTML = '';
		overlay.style.opacity = 0.0;
		overlay.style.visibility = 'hidden';
	}
}

/// Expand or contract the display of this component.
ClientMethod toggleExpanded() [ Language = javascript ]
{
	this.setExpanded(!this.expanded);
}

/// Expand or contract the display of this component.
ClientMethod setExpanded(flag) [ Language = javascript ]
{
	if (this.expanded != flag) {
		this.expanded = flag;

		var div = this.getEnclosingDiv();
		var columnWidth = this.expanded ?  parseInt(this.columnWidth,10) : 0;
		var discWidth = this.showDisclosure?parseInt(this.disclosureWidth,10):0;
		div.style.width = discWidth + columnWidth + (this.expanded?2:0) + 'px';

		var icon = this.expanded ? 'images/black_left_arrow.png' : 'images/black_right_arrow.png';

		var image = this.findElement('discIcon');
		image.src = icon; 

		// notify
		if (this.onexpand!='') {
			if (zenIsIE) {
				this.expandHandler();
			}
			else {
				// attach to transition event per browser
				if (div.addEventListener) {
					this._transEvent = new Function('zenPage.getComponent('+this.index+').expandHandler();');
					div.addEventListener('webkitTransitionEnd', this._transEvent,false);
					div.addEventListener('transitionend', this._transEvent,false);
				}
			}
		}
	}
}

/// Fire the onexpand event handler.
ClientMethod expandHandler() [ Language = javascript ]
{
	var div = this.getEnclosingDiv();

	if (div.removeEventListener) {
		div.removeEventListener('webkitTransitionEnd', this._transEvent);
		div.removeEventListener('transitionend', this._transEvent);
	}
	zenInvokeCallbackMethod(this.onexpand,this,'onexpand');
}

/// Get the expected width of this component in pixels.
ClientMethod getWidth() [ Language = javascript ]
{
	// JMD1388: if we are hidden our width is 0
	if (this.hidden) {
		return 0;
	}
	var discWidth = this.showDisclosure?parseInt(this.disclosureWidth,10):0;
	var columnWidth = this.expanded ?  parseInt(this.columnWidth,10) : 0;
	return discWidth + columnWidth + (this.expanded?2:0);
}

/// Set the column width (pixels) of this component.
ClientMethod setWidth(width) [ Language = javascript ]
{
	if (this.columnWidth != parseInt(width,10)) {
		this.columnWidth = parseInt(width,10);
		this.render();
		this.refreshTopSheet();
	}
}

/// Set the height (pixels) of this component.
ClientMethod setHeight(height) [ Language = javascript ]
{
	height = height<0 ? 0 : height;
	var div = this.getEnclosingDiv();
	div.style.height = height + 'px';

	var disc = this.findElement('disclosure');
	if (disc) {
		disc.style.height = height + 'px';
	}

	var bg = this.findElement('background');
	if (bg) {
		bg.style.height = height + 'px';
	}

	var master = this.findElement('master');
	if (master && height>2) {
		master.style.height = height-2 + 'px';
	}

	var tray = this.findElement('tray');
	if (tray) {
		tray.style.height = height + 'px';
	}

	// adjust height of every panel & body
	var chgt = height-parseInt(this.headerHeight,10)-parseInt(this.footerHeight,10)-20;
	chgt = chgt > 0 ? chgt : 1;
	for (var n = 0;;n++) {
		var panel = this.findElement('panel_'+n);
		if (!panel) break;
		panel.style.height = height + 'px';

		var body = this.findElement('body_'+n);
		if (body) {
			body.style.height = chgt + 'px';
		}
	}

	var icon = this.findElement('discIcon');
	if (icon) {
		icon.style.top = height/2 + 'px';
		icon.style.left = (parseInt(this.disclosureWidth,10)-16)/2 + 'px';
	}

	var iframe = this.findElement('iframe_0');
	if (iframe && height>24) {
		iframe.style.height = height-24 + 'px';
	}
}

/// Utility method. Split a css value into individual style values.
/// Return an object containing these values.
/// In addition to normal css attributes, the special attributes:
/// "bold", "displayed","italic","underline", "smallCaps", and "shadow" are returned.
ClientMethod parseStyle(style) [ Language = javascript ]
{
	var result = {};
	var enc = this.getEnclosingDiv();
	var encStyle = enc.style.cssText;

	// use div to pull apart styles
	enc.style.cssText = style + 'visibility:hidden;';

	result.displayed = true;
	result.bold = false;
	result.italic = false;
	result.underline = false;
	result.shadow = false;
	result.smallCaps = false;
	
	// list of styles with default logic
	var list = ['color','backgroundColor','textAlign','fontFamily','fontSize','margin','padding','opacity','borderRadius','top','left','right','left','width','height','borderColor'];

	for (var n = 0; n < list.length; n++) {
		result[list[n]] = '';
		if (enc.style[list[n]]!=='') {
			result[list[n]] = enc.style[list[n]];
		}
	}

	result.borderTop = enc.style.borderTopWidth=='0px' ? false : true;
	result.borderBottom = enc.style.borderBottomWidth=='0px' ? false : true;;
	result.borderLeft = enc.style.borderLeftWidth=='0px' ? false : true;;
	result.borderRight = enc.style.borderRightWidth=='0px' ? false : true;;
	result.borderWidth = enc.style.borderWidth;
	if (result.borderTop && !isNaN(parseInt(enc.style.borderTopWidth,10))) {
		result.borderWidth = enc.style.borderTopWidth;
	}
	else if (result.borderBottom && !isNaN(parseInt(enc.style.borderBottomWidth,10))) {
		result.borderWidth = enc.style.borderBottomWidth;
	}
	else if (result.borderLeft && !isNaN(parseInt(enc.style.borderLeftWidth,10))) {
		result.borderWidth = enc.style.borderLeftWidth;
	}
	else if (result.borderRight && !isNaN(parseInt(enc.style.borderRightWidth,10))) {
		result.borderWidth = enc.style.borderRightWidth;
	}

	if (enc.style.display!='') {
		result.displayed = (enc.style.display != 'none');
	}
	if (enc.style.fontWeight!='') {
		result.bold = (enc.style.fontWeight == 'bold');
	}
	if (enc.style.fontStyle!='') {
		result.italic = (enc.style.fontStyle == 'italic');
	}
	if (enc.style.fontVariant!='') {
		result.smallCaps = (enc.style.fontVariant == 'small-caps');
	}
	if (enc.style.textDecoration!='') {
		result.underline = (enc.style.textDecoration == 'underline');
	}
	if (enc.style.textShadow!='') {
		result.shadow = (enc.style.textShadow != 'inherit') && (enc.style.textShadow != '');
	}

	// restore
	enc.style.cssText = encStyle;

	return result;
}

/// Utility method. Split an SVG css value into individual style values.
/// Return an object containing these values.
ClientMethod parseStyleSVG(style) [ Language = javascript ]
{
	var result = {};

	// for svg we have to parse
	var items = style.toString().toLowerCase().split(';');
	for (var i=0; i<items.length; i++) {
		if (items[i]) {
			var pair = items[i].split(':');
			if (pair && pair.length==2) {
				newAttr = zenTrim(pair[0]);
				if (newAttr && newAttr.length>0) {
					newVal = zenTrim(pair[1]);
					if (newVal !== '') {
						result[newAttr] = newVal;
					}
				}
			}
		}
	}
	return result;
}

/// Convert an object containing css values as name-values into a css string.
/// This is used for SVG styles.
ClientMethod convertCSSToText(result) [ Language = javascript ]
{
	var css = [];
	for (var p in result) {
		if (result[p]!=='') {
			css[css.length] = p + ':' + result[p] + ';';
		}
	}
	return css.join('');
}

/// Utility method. Set a specific css value into the given style string.
ClientMethod setStyleIntoCSS(cssText, style, value) [ Language = javascript ]
{
	var s = cssText;
	if (style!=='') {
		// list of styles with default logic
		// lists must match!
		var list = ['color','backgroundColor','fontFamily','fontSize','margin','padding','opacity','borderRadius','top','left','right','left','width','height'];
		var listCSS = ['color','background-color','font-family','font-size','margin','padding','opacity','border-radius','top','left','right','left','width','height'];

		var test = cssText;
		switch (style) {
		case 'align':
			test += 'text-align:' + (value==''?'inherit':value) + ';';
			break;
		case 'bold':
			test += 'font-weight:' + (value?'bold':'normal') + ';';
			break;
		case 'underline':
			test += 'text-decoration:' + (value?'underline':'none') + ';';
			break;
		case 'italic':
			test += 'font-style:' + (value?'italic':'normal') + ';';
			break;
		case 'smallCaps':
			test += 'font-variant:' + (value?'small-caps':'normal') + ';';
			break;
		case 'shadow':
			test += 'text-shadow:' + (value?'1px 1px 1px #808080':'inherit') + ';';
			break;
		case 'displayed':
			test += 'display:' + (value?'block':'none') + ';';
			break;

		case 'borderTop':
			if (!value) {
				test += 'border-top-width:0px;';
			}
			else {
				test += 'border-top-width:medium;';
			}
			break;
		case 'borderBottom':
			if (!value) {
				test += 'border-bottom-width:0px;';
			}
			else {
				test += 'border-bottom-width:medium;';
			}
			break;
		case 'borderLeft':
			if (!value) {
				test += 'border-left-width:0px;';
			}
			else {
				test += 'border-left-width:medium;';
			}
			break;
		case 'borderRight':
			if (!value) {
				test += 'border-right-width:0px;';
			}
			else {
				test += 'border-right-width:medium;';
			}
			break;

		default:
			test += style + ':' + (value!==''?value:'inherit') + ';';
			break;
		}

		var result = this.parseStyle(test);

		var s = '';
		if (result.textAlign && result.textAlign!='inherit') {
			s += 'text-align: ' + result.textAlign+';';
		}
		if (result.bold) {
			s += 'font-weight: bold;';
		}
		if (result.italic) {
			s += 'font-style: italic;';
		}
		if (result.smallCaps) {
			s += 'font-variant: small-caps;';
		}
		if (result.underline) {
			s += 'text-decoration: underline;';
		}
		if (result.shadow) {
			s += 'text-shadow: 1px 1px 1px #808080;';
		}
		if (!result.displayed) {
			s += 'display: none;';
		}

		if (result.borderWidth && result.borderWidth!='0px') {
			// fold in all border styles
			s += 'border-style:solid;';
			s += 'border-width:'+result.borderWidth+';';
			if (!result.borderTop) {
				s += 'border-top-width:0px;'
			}
			if (!result.borderBottom) {
				s += 'border-bottom-width:0px;'
			}
			if (!result.borderLeft) {
				s += 'border-left-width:0px;'
			}
			if (!result.borderRight) {
				s += 'border-right-width:0px;'
			}
		}
		if (result.borderColor && result.borderColor!='inherit') {
			s += 'border-color:' + result.borderColor + ';';
		}

		for (var n = 0; n < list.length; n++) {
			if (result[list[n]]!==null && result[list[n]]!=='' && result[list[n]]!='inherit') {
				s += listCSS[n] + ':'+result[list[n]]+ ';';
			}
		}
	}
	return s;
}

/// Utility method.
/// Display a set of choices as icons.
/// Given a list of objects, of the form:
/// [{image:url, caption:caption, value:value, style:style}]<br/>
/// <var>key</var> and <var>value</var> are the key and value for item within the navigator.
/// Return HTML to display a chooser list based on the given values.
ClientMethod getIconListHTML(list, key, value) [ Language = javascript ]
{
	var html = [];
	html[html.length] = '<div>';
	for (var n = 0; n < list.length; n++) {
		var info = list[n];
		if (info) {
			var style = info.style ? info.style : '';
			var ivalue = info.value ? info.value : '';
			var idisabled = info.disabled ? info.disabled : false;
			var caption = info.caption ? info.caption : ivalue;
			var title = info.title ? info.title : caption;
			var image = zenGet(info.image) ? info.image : '';
			var cls = (value==ivalue) ? 'navIconListSelected' : 'navIconList';
			if (idisabled) {
				cls = 'navIconListDisabled';
			}
			html[html.length] = '<div class="'+cls+'" title="'+title+'" style="'+style+';" onclick="zenPage.getComponent('+this.index+').applyValue(\''+ivalue+'\');"  onmouseover="zenPage.getComponent('+this.index+').tryValue(\''+ivalue+'\','+this.currLevel+');" onmouseout="zenPage.getComponent('+this.index+').tryValue(\''+value+'\','+this.currLevel+');">';
			if (image) {
				html[html.length] = '<image src="'+image+'"/>';
			}
			html[html.length] = '</div>';
		}
	}
	html[html.length] = '</div>';
	return html.join('');
}

/// Utility method.
/// Display a set of choices as icons.
/// Given a list of objects, of the form:
/// [{image:url, caption:caption, value:value, style:style}]<br/>
/// <var>key</var> and <var>value</var> are the key and value for item within the navigator.
/// Return HTML to display a multi-select supporting chooser
ClientMethod getMultiSelectIconListHTML(list, key, value) [ Language = javascript ]
{
	// + WAL083 (3) -- method added by WAL083
	if (value) {
		var valueArray = [];
		var isSelectedArray = [];
		valueArray = value.split(',');
		for (var i = 0; i < valueArray.length; i++) {
			isSelectedArray[valueArray[i]] = 'selected';
		}
	}
	
	var html = [];
	// Apply Selection button
	html[html.length] = '<div class="navItem" onclick="zenPage.getComponent('+this.index+').collectValue(\'\',true,\'\');"><div class="navItemCaption">Apply Selection</div></div>'
	// Clear Selection button
	html[html.length] = '<div class="navItem" onclick="zenPage.getComponent('+this.index+').clearValue();"><div class="navItemCaption">Clear Selection</div></div>'
	html[html.length] = '<div>';
	for (var n = 0; n < list.length; n++) {
		var info = list[n];
		if (info) {		
			var style = info.style ? info.style : '';
			var ivalue = info.value ? info.value : '';
			var idisabled = info.disabled ? info.disabled : false;
			var caption = info.caption ? info.caption : ivalue;
			var title = info.title ? info.title : caption;
			var image = zenGet(info.image) ? info.image : '';
			var cls = (value==ivalue) ? 'navIconListSelected' : 'navIconList';
			if (idisabled) {
				cls = 'navIconListDisabled';
			}
			// + WAL083 -- update styling if already selected
			var isSelected = (value && isSelectedArray[ivalue]=='selected') ? 1 : 0;
			var cls = isSelected ? 'navIconListSelected navMultiSelectIconListSelected' : 'navIconList';
			// - WAL083
			html[html.length] = '<div class="'+cls+'" title="'+title+'" style="'+style+';" onclick="zenPage.getComponent('+this.index+').collectValue(\''+ivalue+'\',false);">';
			if (image) {
				html[html.length] = '<image src="'+image+'"/>';
			}
			html[html.length] = '</div>';
		}
	}
	html[html.length] = '</div>';
	return html.join('');
	// - WAL083 (3)
}

/// Utility method.
/// Given a list of objects, of the form:
/// [{caption:caption, value:value, style:style}]<br/>
/// <var>key</var> and <var>value</var> are the key and value for item within the navigator.
/// Return HTML to display a chooser list based on the given values.
/// If <var>caption</var> and <var>help</var> are defined, display them at the top.
ClientMethod getChooserListHTML(list, key, value, caption, help) [ Language = javascript ]
{

	var columnWidth = parseInt(this.columnWidth,10);
	caption = zenGet(caption);
	help = zenGet(help);

	var html = [];

	if (caption || help) {
		// !!! why does mouse fire on this???
		html[html.length] = '<div style="font-style:italic;padding:5px;border-bottom:1px solid #808080;background:#FFFFFF;"><b>' 
			+ zenEscapeXML(caption) + 
			'</b><br/>' + 
			zenEscapeXML(help) + 
			'</div>';
	}

	html[html.length] = '<div>';
	for (var n = 0; n < list.length; n++) {
		var info = list[n];
		if (info) {
			var style = zenGet(info.style);
			var ivalue = zenGet(info.value);
			var idisabled = info.disabled ? true : false;
			var caption = info.caption ? info.caption : ivalue;
			var display = info.caption ? info.caption : '';
			var help = zenGet(info.help);
			if (!help) help = caption;
			var hint = zenGet(info.hint)
			var cls = (value==ivalue) ? 'navItemSelected' : 'navItem';
			if (hint) {
				style += 'height:50px;';
			}

			html[html.length] = '<div class="'+cls+'" title="'+zenEscapeXML(help)+'" style="'+style+';" onclick="zenPage.getComponent('+this.index+').applyValue(\''+zenEscapeJS(ivalue)+'\',\''+zenEscapeJS(display)+'\');" onmouseover="zenPage.getComponent('+this.index+').tryValue(\''+zenEscapeJS(ivalue)+'\','+this.currLevel+');" onmouseout="zenPage.getComponent('+this.index+').tryValue(\''+zenEscapeJS(value)+'\','+this.currLevel+');">';
			html[html.length] = '<div class="navItemCaption'+(idisabled?'Disabled':'')+'">';
			html[html.length] = zenEscapeXML(caption);
			html[html.length] = '</div>';
			if (hint && !idisabled) {
				var cls = (value==ivalue) ? 'navItemHintSelected' : 'navItemHint';
				html[html.length] = '<div class="'+cls+'" style="top:20px;left:5px;height:30px;width:'+(columnWidth-20)+'px;">';
				html[html.length] = zenEscapeXML(hint);
				html[html.length] = '</div>';
			}
			html[html.length] = '</div>';
		}
	}
	html[html.length] = '</div>';
	return html.join('');
}

/// Utility method.
/// Return the HTML for a font chooser panel.
/// <var>key</var> and <var>value</var> are the key and value for item within the navigator.
ClientMethod getFontChooserHTML(key, value) [ Language = javascript ]
{
	// + WAL100 (3) -- in order for the fonts to appear in the PDF export, the case matters
		var list = [
		{ caption: 'Default', value:''},
		{ value:'Arial', style:'font-family:arial;'},
		{ value:'Arial Narrow', style:'font-family:arial narrow;'},
		{ value:'Century Schoolbook', style:'font-family:century schoolbook;'},
		{ value:'Copperplate', style:'font-family:copperplate;'},
		{ value:'Courier New', style:'font-family:courier new;'},
		{ value:'Georgia', style:'font-family:georgia;'},
		{ value:'Helvetica', style:'font-family:helvetica;'},
		{ value:'Impact', style:'font-family:impact;'},
		{ value:'Lucida Sans Unicode', style:'font-family:lucida sans unicode;'},
		{ value:'Tahoma', style:'font-family:tahoma;'},
		{ value:'Times Roman', style:'font-family:times roman;'},
		{ value:'Verdana', style:'font-family:verdana;'},
		{ value:'Comic Sans MS', style:'font-family:comic sans ms;'}
	];
	// - WAL1000 (3)
	if (!this._userFontsIntialized) {
		this._userFontList=this.GetUserFontList();
		if (this._userFontList.split) {
			this._userFonts = this._userFontList.split(",");
		}
		this._userFontsIntialized = true;
	}
	if (this._userFonts) {
		var len = this._userFonts.length;
		var i =0;
		while (i<len && this._userFonts[i].length>0) {
			var name = this._userFonts[i];
			var o = {};
			o.value = name;
			o.style = 'font-family:'+name+';';
			list.push(o);
			i++;
		}
	}

	return this.getChooserListHTML(list,key+'-font-family',value);
}

/// Return the HTML for a color chooser panel.
/// <var>key</var> and <var>value</var> are the key and value for item within the navigator.
/// <var>mode</mode> is "html" or "svg".
ClientMethod getColorChooserHTML(key, value, mode) [ Language = javascript ]
{
	mode = zenGet(mode,"html");
	var defValue = (mode=='svg') ? '' : 'inherit';

	html = [];
	html[html.length] = '<div style="background:#F0F0F0;padding:1px;position:relative;">';

	html[html.length] = '<select class="navColorSet" id="'+this.makeId('colorSet_'+this.currLevel)+'" onchange="zenPage.getComponent('+this.index+').colorSetChange(\''+value+'\');">';
	for (var n = 0; n < this.colorSetNames.length; n++) {
		var ostyle = n%2 ? '' : 'background:#F8F8F8;';
		html[html.length] = '<option style="padding:4px;'+ostyle+'" '+(this.colorSetNames[n]==this.currColorSet?'selected="1"':'')+' value="'+this.colorSetNames[n]+'">' + this.colorSetCaptions[n] + '</option>';
	}
	html[html.length] = '</select>';

	// gradients
	if (mode == 'svg') {
		var gradList = ["deep-silver","shade-silver","glow-silver","glow-silverHz","glow-silverDiag","deep-red","shade-red","glow-red","glow-redHz","glow-redDiag","deep-green","shade-green","glow-green","glow-greenHz","glow-greenDiag","deep-blue","shade-blue","glow-blue","glow-blueHz","glow-blueDiag","deep-yellow","shade-yellow","glow-yellow","glow-yellowHz","glow-yellowDiag","deep-purple","shade-purple","glow-purple","glow-purpleHz","glow-purpleDiag","deep-teal","shade-teal","glow-teal","glow-tealHz","glow-tealDiag","deep-orange","shade-orange","glow-orange","glow-orangeHz","glow-orangeDiag"];
		html[html.length] = '<select class="navColorSet" id="'+this.makeId('gradList_'+this.currLevel)+'" onchange="zenPage.getComponent('+this.index+').applyValue(this.value);">';
		html[html.length] = '<option value=""></option>';
		for (var n = 0; n < gradList.length; n++) {
			var ostyle = n%2 ? '' : 'background:#F8F8F8;';
			html[html.length] = '<option style="padding:4px;'+ostyle+'" '+(('url(#'+gradList[n]+')')==value?'selected="yes"':'')+' value="'+'url(#'+gradList[n]+')'+'">' + gradList[n] + '</option>';
		}
		html[html.length] = '</select>';
	}
	
	// reset button
	html[html.length] = '<image class="navColorBtn" src="deepsee/ds2_x_44.png" style="margin-left:20px;bottom:2px;position:absolute;" onclick="zenPage.getComponent('+this.index+').applyValue(\''+defValue+'\');"/>';
	
	if (zenPage.launchColorChooser) {
		// color wheel button
		html[html.length] = '<image class="navColorBtn" src="deepsee/ds2_magnify_44.png" style="margin-left:45px;bottom:2px;position:absolute;" onclick="zenPage.launchColorChooser();"/>';
	}

	html[html.length] = '</div>';
	
	// reset color on mouse over background
	html[html.length] = '<div id="'+this.makeId('colorTable_'+this.currLevel)+'" onmouseover="zenPage.getComponent('+this.index+').tryValue(\''+value+'\','+this.currLevel+')">';
	html[html.length] = this.getColorTableHTML(mode,value);
	html[html.length] = '</div>';

	html[html.length] = '</table>';
	return html.join('');
}

/// Change the displayed color set.
ClientMethod colorSetChange(value) [ Language = javascript ]
{
	var cb = this.findElement('colorSet_'+this.currLevel);
	if (cb) {
		if (cb.value!=this.currColorSet) {
			this.currColorSet = cb.value;
			var div = this.findElement('colorTable_'+this.currLevel);
			if (div) {
				div.innerHTML = this.getColorTableHTML(value);
			}
		}
	}
}

/// Return a HTML for the table of color choices for the current color set.
ClientMethod getColorTableHTML(mode, value) [ Language = javascript ]
{
	var html = [];

	var stdColors = this.getColorSet(mode);

	html[html.length] = '<table class="navColorTable">';
	for (var r = 0; r < stdColors.length; r++) {
		html[html.length] = '<tr>';
		for (var c = 0; c < stdColors[r].length; c++) {
			var color = stdColors[r][c];
			var bdr = (color=='inherit')?'black':'#D0D0D0';
			// prevent propagation of mouse over
			html[html.length] = '<td title="'+color+'" style="border:1px solid '+bdr+';font-size:1px; width:28px;height:28px;background:'+color+';" onclick="zenPage.getComponent('+this.index+').applyValue(\''+color+'\');" onmouseover="zenPage.getComponent('+this.index+').tryValue(\''+color+'\','+this.currLevel+');(event.stopPropagation?event.stopPropagation():0);" onmouseout="zenPage.getComponent('+this.index+').tryValue(\''+value+'\','+this.currLevel+');">';
			html[html.length] = '&nbsp;';
			html[html.length] = '</td>';
		}
		html[html.length] = '</tr>';
	}
	html[html.length] = '</table>';
	return html.join('');
}

/// Return an array of (arrays of) the current color set.
ClientMethod getColorSet(mode) [ Language = javascript ]
{
	// find color set index
	var index = -1;
	if (this.currColorSet!='') {
		for (var n = 0; n < this.colorSetNames.length; n++) {
			if (this.colorSetNames[n]==this.currColorSet) {
				index = n;
				break;
			}
		}
	}

	if (index < 0) {
		// built-in colors
		var colors = [
			[ '#FFFFFF','#000000','#0000F0','#00F000','#F00000','#F000F0','#00F0F0','#F0F000'],
			[ '#C0C0C0','#404040','#4040D0','#40D040','#D04040','#D040D0','#40D0D0','#D0D040'],
			[ '#D0D0D0','#606060','#6060D0','#60D060','#D06060','#D060D0','#60D0D0','#D0D060'],
			[ '#E0E0E0','#808080','#8080FF','#80FF80','#FF8080','#FF80FF','#80F0F0','#FFFF80'],
			[ '#F0F0F0','#909090','#B0B0FF','#B0FFB0','#FFB0B0','#FFB0FF','#B0FFFF','#FFFFB0'],
			[ '#F4F4F4','#A0A0A0','#D0D0FF','#D0FFD0','#FFD0D0','#FFD0FF','#D0FFFF','#FFFFD0'],
			[ '#F8F8F8','#B0B0B0','#F0F0F8','#F0F8F0','#F8F0F0','#FFF0FF','#F0FFFF','#FFFFF0'],
			[ '#FFFFFF','#FEFEFE','#F0F0FF','#F0FFF0','#FFF0F0','#FFF8FF','#F8FFFF','#FFFFF8']
		];
	}
	else {
		var set = this.colorSets[index];
		var t = set.toString().split(';');

		// create a rows x cols grid of colors
		var rows = 8;
		var cols = 8;
		var colors = [];
		for (var r = 0; r < rows; r++) {
			var list = [];
			colors[r] = list;
			for (var c = 0; c < cols; c++) {
				var x = (c*rows)+r;
				list[c] = t[x] ? t[x] : '#FFFFFF';
			}
		}
	}
	return colors;
}

ClientMethod customColorChange(which) [ Language = javascript ]
{
	var ctrlRed = this.findElement('red');
	var ctrlGreen = this.findElement('green');
	var ctrlBlue = this.findElement('blue');
	var sample = this.findElement('sample');

	var red = parseInt(ctrlRed.value,10);
	if (ctrlRed.value==='') {
		red = 0;
	}
	else {
		red = isNaN(red) ? 0 : red;
		red = (red > 255) ? 255 : (red < 0) ? 0 : red;
		ctrlRed.value = red;
	}

	var green = parseInt(ctrlGreen.value,10);
	if (ctrlGreen.value==='') {
		green = 0;
	}
	else {
		green = isNaN(green) ? 0 : green;
		green = (green > 255) ? 255 : (green < 0) ? 0 : green;
		ctrlGreen.value = green;
	}

	var blue = parseInt(ctrlBlue.value,10);
	if (ctrlBlue.value==='') {
		blue = 0;
	}
	else {
		blue = isNaN(blue) ? 0 : blue;
		blue = (blue > 255) ? 255 : (blue < 0) ? 0 : blue;
		ctrlBlue.value = blue;
	}
	
	var color = 'rgb(' + red + ',' + green + ',' + blue + ')';
	sample.style.background = color;
	if (which=='color') {
		this._customColor = color;
	}
	else {
		this._customBackground = color;
	}
}

/// Some charts may have use SVG colors. This is a crude translator.
ClientMethod transformColor(color) [ Language = javascript ]
{
	// copied from chartLegend
	switch(color) {
	case 'url(#deep-silver)':
	case 'url(#shade-silver)':
	case 'url(#glow-silver)':
	case 'url(#glow-silverHz)':
	case 'url(#glow-silverDiag)':
		return 'silver';
	case 'url(#deep-red)':
	case 'url(#shade-red)':
	case 'url(#glow-red)':
	case 'url(#glow-redHz)':
	case 'url(#glow-redDiag)':
		return 'red';
	case 'url(#deep-green)':
	case 'url(#shade-green)':
	case 'url(#glow-green)':
	case 'url(#glow-greenHz)':
	case 'url(#glow-greenDiag)':
		return 'green';
	case 'url(#deep-yellow)':
	case 'url(#shade-yellow)':
	case 'url(#glow-yellow)':
	case 'url(#glow-yellowHz)':
	case 'url(#glow-yellowDiag)':
		return 'yellow';
	case 'url(#deep-blue)':
	case 'url(#shade-blue)':
	case 'url(#glow-blue)':
	case 'url(#glow-blueHz)':
	case 'url(#glow-blueDiag)':
		return 'blue';
	case 'url(#deep-teal)':
	case 'url(#shade-teal)':
	case 'url(#glow-teal)':
	case 'url(#glow-tealHz)':
	case 'url(#glow-tealDiag)':
		return 'teal';
	case 'url(#deep-purple)':
	case 'url(#shade-purple)':
	case 'url(#glow-purple)':
	case 'url(#glow-purpleHz)':
	case 'url(#glow-purpleDiag)':
		return 'purple';
	case 'url(#deep-orange)':
	case 'url(#shade-orange)':
	case 'url(#glow-orange)':
	case 'url(#glow-orangeHz)':
	case 'url(#glow-orangeDiag)':
		return 'orange';
	}
	return color;
}

}
