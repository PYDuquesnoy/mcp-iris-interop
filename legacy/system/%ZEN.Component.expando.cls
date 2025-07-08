/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized group that provides the ability to show or hide
/// its children.<br/>
/// The <property>framed</property> property controls the appearance
/// of the group. If false, then a caption is displayed at the top
/// of the group with a expando icon. Clicking on the icon will expand
/// or contract the group. If <property>framed</property> is true,
/// then a border is drawn around the entire group and the caption is
/// displayed within a more formal title box.<br/>
/// This type of component is also known as a "disclosure" within some
/// user interface systems.
Class %ZEN.Component.expando Extends group [ Deprecated, System = 3 ]
{

Parameter DEFAULTLAYOUT = "vertical";

Parameter DEFAULTGROUPCLASS = "expandoTable";

/// Default url of image used for expanded expando node.
Parameter IMAGEEXPANDED = "images/disclosure-expanded.gif";

/// Default url of image used for contracted expando node.
Parameter IMAGECONTRACTED = "images/disclosure-contracted.gif";

/// Value to display for expando node.
/// This text is <em>not</em> automatically HTML escaped.
Property caption As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// If true (default is false), then display a solid
/// title area and frame around the contents of this group.
Property framed As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true (default is false), then animate the appearance
/// and disappearance of the group contents.
Property animate As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// onexpand event handler:
/// If defined, this event is fired just
/// before the children of this expando are made visible.
Property onexpand As %ZEN.Datatype.eventHandler;

/// oncontract event handler:
/// If defined, this event is fired just
/// before the children of this expando are hidden.
Property oncontract As %ZEN.Datatype.eventHandler;

/// Indicates whether this expando node is expanded (children visible)
/// or contracted (children not visible).
Property expanded As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specifies amount child nodes should be indented.
Property childIndent As %ZEN.Datatype.length;

/// url of image used for expanded expando node.
Property imageExpanded As %ZEN.Datatype.uri [ InitialExpression = {..#IMAGEEXPANDED} ];

/// url of image used for contracted expando node.
Property imageContracted As %ZEN.Datatype.uri [ InitialExpression = {..#IMAGECONTRACTED} ];

/// If true, remember most recent expanded state in a session cookie.
Property remember As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional.
/// Name of Server-side callback method that provides additional HTML content
/// for this component.<br>
/// If defined, this callback is invoked on the server when this 
/// component is drawn. It provides HTML content by using &html or
/// by using the WRITE command.<br>
/// This must be the name of a server-only method in the page
/// class that contains this view component.
Property OnDrawContent As %ZEN.Datatype.delegator(FORMALSPEC = "expando:%ZEN.Component.expando", RETURNTYPE = "%Status");

XData Style
{
<style type="text/css">
/* @doc="Layout for node caption." */
.expandoTable {
}

/* @doc="div element around node caption." */
.expandoNode {
}

/* @doc="a element around node image and caption." */
.expandoNode a {
	color: black;
	border: none;
	text-decoration: none;
}

/* @doc="Mouse over expando caption." */
.expandoNode a:hover {
	color: blue;
	background: #FFEEAA;
}

.expandoNode a.menuItem:link, .expandoNode a.menuItem:visited, .expandoNode a.menuItem:active {
}

/* @doc="a element around node image and caption." */
.expandoFramed a {
	color: black;
	border: none;
	text-decoration: none;
}

/* @doc="Mouse over expando caption, framed mode." */
.expandoFramed a:hover {
	color: blue;
	background: #FFEEAA;
}

.expandoFramed a.menuItem:link, .expandoFramed a.menuItem:visited, .expandoFramed a.menuItem:active {
}

/* @doc="Image for expando node." */
.expandoImg {
	border: none;
}

/* @doc="div wrapper around node children." */
.expandoChildren {
}

/* @doc="div element around title frame in framed mode." */
.expandoFramed {
	font-family: "lucida sans unicode";
	width: 100%;
	border: 1px solid black;
	padding: 1px;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="div wrapper around node children in framed mode." */
.expandoFramedChildren {
	width: 100%;
	border-right: 1px solid black;
	border-left: 1px solid black;
	border-bottom: 1px solid black;
	padding: 1px;
}

</style>
}

Method %DrawHTML()
{
	#; draw *this* node, then create a wrapper div
	#; around any children of this node

	#; see if we are a subexpando
	If ($IsObject(..parent) && ..parent.%IsA("%ZEN.Component.expando")) {
		#; default to parent childIndent
		Set:..childIndent="" ..childIndent = ..parent.childIndent
	}

	#; draw expando node
	Set src = $S(+..expanded:..imageExpanded,1:..imageContracted)

	If ..framed {
		&html<<div id="#(..%MakeId("expandoNode"))#" class="expandoFramed">
		<table border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td nowrap="1">
		<a href="#" onclick="zenPage.getComponent(#(..index)#).toggleExpanded(#(..tuple)#);return false;"><img class="expandoImg" src="#(src)#" id="#(..%MakeId("image"))#"/>
		<span id="#(..%MakeId("caption"))#" #(..%Attr("title",..title))#>#($$$ZENVALHTML(..caption))#</span></a></td>
		<td width="80%" align="right">&nbsp;>
		Do ..%OnDrawTitleOptions()
		&html<</td></tr></table>>
	}
	Else {
		&html<<div id="#(..%MakeId("expandoNode"))#" class="expandoNode">
		<a href="#" onclick="zenPage.getComponent(#(..index)#).toggleExpanded(#(..tuple)#);return false;"><img class="expandoImg" src="#(src)#" id="#(..%MakeId("image"))#"/>
		<span id="#(..%MakeId("caption"))#" #(..%Attr("title",..title))#>#($$$ZENVALHTML(..caption))#</span></a>>
	}

	#; test for user callback
	If (..OnDrawContent'="") {
		Set tSC = ..%DrawContent()
		If $$$ISERR(tSC) {
			Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
		}
	}

	Write "</div>",!

	#; wrap submenu in extra div
	Set style = $S(+..expanded:"",1:"display: none;")
	Set:..childIndent'="" style = style _ "margin-left:" _ ..childIndent _ ";"

	&html<<div id="#(..%MakeId("expandoChildren"))#" class="#($S(..framed:"expandoFramedChildren",1:"expandoChildren"))#" style="#(style)#">>

	#; dispatch to super class to layout children
	Do ##super()

	&html<</div>>
}

/// This callback, if defined, provides a way to add
/// content to the right side of the title bar when the
/// expando is in framed mode.<br/>
/// Any HTML written by this method will be injected into
/// the title bar.<br/>
/// This is expected to be implemented in a subclass.
Method %OnDrawTitleOptions()
{
}

/// Invoke user method to provide additional contents for this 
/// component.
Method %DrawContent() As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	#; if user callback is defined, use that
	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnDrawContent '= "")) {
		Set tSC = $zobjmethod(tHost,..OnDrawContent,$this)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Toggle the current expanded state of this expando node.<br>
/// <var>tuple</var>, if supplied, is the current tuple number
/// for cases when this expando is used within a repeating group.
ClientMethod toggleExpanded(tuple) [ Language = javascript ]
{
	if ('undefined' == typeof tuple) {
		this.setExpanded(!this.getExpanded());
	}
	else {
		this.setExpanded(!this.getExpanded(), tuple);
	}
}

/// Returns the current expanded state of this expando node.<br>
/// <var>tuple</var>, if supplied, is the current tuple number
/// for cases when this expando is used within a repeating group.
ClientMethod getExpanded(tuple) [ Language = javascript ]
{
	if ('undefined' != typeof tuple) {
		var div = this.window.document.getElementById('expandoChildren_' + this.index + '.' + tuple);
		return div ? (div.style.display=='none' ? false : true) : false;
	}
	return this.expanded;
}

/// Set the expanded state of this expando.<br>
/// <var>tuple</var>, if supplied, is the current tuple number
/// for cases when this expando is used within a repeating group.
ClientMethod setExpanded(flag, tuple) [ Language = javascript ]
{
	this.expanded = flag;
	var divid = '';
	var div = null;
	var img = null;
	if ('undefined' == typeof tuple) {
		divid = 'expandoChildren';
		div = this.findElement(divid);
		img = this.findElement('image');
	}
	else {
		divid = 'expandoChildren_' + this.index + '.' + tuple;
		div = this.window.document.getElementById(divid);
		img = this.window.document.getElementById('image_' + this.index + '.' + tuple);
	}
	zenASSERT(div,'Unable to find div element for children',arguments);

	// invoke callbacks, if present
	if (this.expanded) {
		zenInvokeCallbackMethod(this.onexpand,this,'onexpand','tuple',tuple);
	}
	else {
		zenInvokeCallbackMethod(this.oncontract,this,'oncontract','tuple',tuple);
	}

	if (this.animate) {
		// remember current style 
		if (this._cssHeight==undefined){
			this._cssHeight = div.style.height;	
		}
		if (this._cssOverflow==undefined){
			this._cssOverflow = div.style.overflow;
		}
		if (div.style.opacity != null) {
			if (this._cssOpacity==undefined) {
				this._cssOpacity = div.style.opacity;
			}
		}

		if (this.expanded) {
			// make appear
			var h = div.clientHeight;
			if (h > 0) {
				this._height = h;
			}
			else if (div.style.height!='') {
				this._height = div.style.height;
			}
			else if (null == this._height) {
				this._height = 100; // guess
			}
			if (div.style.opacity != null) {
				div.style.opacity = 0.0;
			}
			div.style.height = '1px';
			div.style.overflow = 'hidden';
			div.style.display = '';
		}
		else {
			// make disappear
			this._height = div.clientHeight;
			div.style.overflow = 'hidden';
			if (div.style.opacity != null) {
				div.style.opacity = 1.0;
			}
		}

		if (this._exTimerId) {
			window.clearTimeout(this._exTimerId);
		}
		// start timer
		this._progress = this.expanded ? 0 : 100;
		var delta = this.expanded ? 10 : -10;
		this._exTimerId = self.setTimeout("zenPage.getComponent("+this.index+").animateExpand("+delta+",'"+divid+"')",20);
	}
	else {
		div.style.display = this.expanded ? '' : 'none';
	}

	if (img) {
		img.src = this.expanded ? this.imageExpanded : this.imageContracted;
	}

	if (this.expanded) this.exposeComponent();
	
	if (this.remember && ('undefined' == typeof tuple)) {
		// stash current state away
		zenStoreCookie(this,'expando',this.expanded ? '2' : '1');
	}
}

/// Internal method that animates the expansion/contraction
/// of the group.
ClientMethod animateExpand(delta, divid) [ Internal, Language = javascript ]
{
	delta = parseInt(delta);
	delete this._exTimerId;
	this._progress = parseInt(this._progress) + parseInt(delta);
	div = this.findElement(divid);

	if (this._progress > 0 && this._progress < 100) {
		var h = parseInt(((this._progress / 100) * this._height));
		h = (h <= 1) ? 1 : h;
		div.style.height = h + 'px';

		if (div.style.opacity != null) {
			// supports CSS
			div.style.opacity = this._progress / 100;
		}
		else if (div.style.filter != null) {
			// MS filter
			div.style.filter = 'alpha(opacity=' + this._progress + ')';
		}
		div.scrollIntoView();

		// restart timer
		this._exTimerId = self.setTimeout("zenPage.getComponent("+this.index+").animateExpand("+(delta*1.3)+",'"+divid+"')",20);
	}
	else {
		// final style
		div.style.height = 	this._cssHeight;
		if (null != div.style.opacity) {
			div.style.opacity = this._cssOpacity;
		}
		else if (div.style.filter != null) {
			div.style.filter = '';
		}
		div.style.overflow = this._cssOverflow;
		div.style.display = this.expanded ? '' : 'none';
		div.scrollIntoView();
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (this.remember) {
		// restore save exapanded state
		var exp = parseInt(zenLoadCookie(this,'expando'),10);
		if (exp > 0) {
			this.setExpanded(exp == 2);
		}
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'animate':
		this.animate = value ? true : false;
		break;
	case 'expanded':
		value = value ? true : false;
		this.setExpanded(value);
		break;
	case 'childIndent':
		this[property] = value;
		this.refreshContents();
		break;

	case 'caption':
		this.caption = value;
		var span = this.findElement('caption');
		if (span) {
			span.innerHTML = this.caption;
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
		break;
	}
	return true;
}

}
