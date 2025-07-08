/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple image control.<br>
/// This can be used to display an image within a page or it can
/// serve as a button by specifying an onclick event.<br>
/// There is no submitted value associated with this control.<br>
/// There are several different ways to specify the image to display:
/// <ol>
/// <li>If provided, <property>src</property> is the URI of the image to display.</li>
/// <li>If provided, <property>streamId</property> is the OID value for a binary stream object containing the image. 
/// This OID value will be encrypted and the image will be served via the CSP stream server.</li>
/// <li>If provided, <property>value</property> is an encrypted stream OID value for a binary stream object containing the image. 
/// The image will be served via the CSP stream server. This is used when the
/// image is bound to a property within a dataController that contains binary stream data.</li>
/// </ol>
/// Note that the <property>controlClass</property> does not apply to the image component.
Class %ZEN.Component.image Extends control [ Deprecated, System = 3 ]
{

/// URI of image to display.
Property src As %ZEN.Datatype.uri;

/// Alternate text for this image; This is used for the alt attribute
/// of the HTML img element used for this component.
Property alt As %ZEN.Datatype.caption;

/// If defined, URI of image to display when this image is disabled.
Property srcDisabled As %ZEN.Datatype.uri;

/// If defined, URI of image to display when a value for this image is missing;
/// This is used when this image is bound to a property of a dataController and
/// there is no value for the bound property.
Property srcMissing As %ZEN.Datatype.uri;

/// If defined, this is the stream id of a binary stream object on the server
/// that will provide data for this image. This supercedes <property>src</property>
/// if present.
Property streamId As %ZEN.Datatype.string(ZENENCRYPT = 1);

/// If defined, this is an optional text value associated with this image.
/// By default, this is used as a value when this image is the source of
/// a drag and drop operation.
Property text As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

/* @doc="Style used for images with links." */
.imageLink {
	cursor: pointer;
}

</style>
}

Method %DrawHTML()
{
	#; handle onclick directly
	Set tIgnore("onclick")=""
	Set tIgnore("onchange")=""

	Set ..onclick = $$$ZENVALJS(..onclick)

	#; select image to display
	Set tSrc = ##class(%CSP.Page).Link(..src)
	If (..streamId '= "") {
		#; we are passed a stream id, we have to encode it
		Set tSrc = ##class(%CSP.Page).Link("%25CSP.StreamServer.cls?STREAMOID="_##class(%CSP.Page).Encrypt(..streamId))
	}
	ElseIf (..value '= "") {
		#; assume value is an encoded stream id
		Set tSrc = ##class(%CSP.Page).Link("%25CSP.StreamServer.cls?STREAMOID="_$ZCVT(..value,"O","URL"))
	}

	#; disabled/missing logic
	If (..disabled) {
		Set tSrc = $S(..srcDisabled="":tSrc,1:..srcDisabled)
	}
	ElseIf (tSrc = "") {
		If (..srcMissing = "") {
 			Set tSrc = "images/spacer.gif"
 		}
		Else {
			Set tSrc = ..srcMissing
		}
	}

	#; if we support drag & drop we need additional mouse event handling
	Set tMouseEvents = ""
	If (%page.dragAndDrop) {
		Set tMouseEvents = " onmousedown=""zenPage.getComponent("_..index_").itemMouseDown(event);""" _
						" onmouseup=""zenPage.getComponent("_..index_").itemMouseUp(event);"""
	}
	#; use Write instead of &html so that whitespace does not mess up IE!
	Write "<img id=""",..%MakeId("image"),""" ",$S(..onclick="":"",1:"class=""imageLink""")," ",..%Attr("src",tSrc)," ",..%Attr("title",..title)," ",..%Attr("width",..width)," ",..%Attr("height",..height)," ",..%Attr("alt",..alt)," ",..%Attr("style",..controlStyle)," ",..%GetEventHandlers(.tIgnore)," onclick=""zenPage.getComponent(",..index,").imageClick(event);"" ",tMouseEvents,"/>"
}

Method %SetDefaultValues()
{
	Set ..src = "images/folder.gif"
	Set ..srcDisabled = "images/spacer.gif"
}

/// User click on image; Invoke callback if button is enabled.
ClientMethod imageClick(evt) [ Language = javascript ]
{
	if (!this.disabled) {
		zenFireEvent(this.index, this.onclick, 'onclick', evt);
	}
}

/// Mouse down handler.
ClientMethod itemMouseDown(evt) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		return false;
	}
	return true;
}

/// Mouse up handler.
ClientMethod itemMouseUp(evt) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		return false;
	}
	return true;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('image');

	switch(property) {
	case 'src':
		this.src = value;
		if (!this.disabled || '' == this.srcDisabled) {
			el.src = value;
		}
		break;
	case 'srcDisabled':
		this.srcDisabled = value;
		if (this.disabled) {
			el.src = value;
		}
		break;
	case 'disabled':
		value = value ? true : false;
		this.disabled = value;
		if (!this.disabled || '' == this.srcDisabled) {
			if ('' != this.value) {
				this.setProperty('value',this.value);
			}
			else {
				try {
					el.src = this.src;
					// JMD834-if no disabled image, dim out
					el.style.opacity = (this.disabled ? 0.5 : 1.0);
					if (zenIsIE) {
						el.style.filter = (this.disabled ? 'alpha(opacity=50)' : 'alpha(opacity=100)');
					}
				}
				catch(ex) { } // ignore browser errors (HCR311)
			}
		}
		else {
			el.src = this.srcDisabled;
		}
		break;
	case 'value':
	
		// don't update src if value is unchanged
		if (this.value===value) {
			break;
		}
		
		// assume this is an encrypted stream id
		this.value = value;
		if (!this.disabled || '' == this.srcDisabled) {
			if ('' == this.value) {
				el.src = this.srcMissing;
			}
			else {
				el.src = '%25CSP.StreamServer.cls?STREAMOID=' + escape(this.value);
			}
		}
		break;
	case 'width':
	case 'height':
		this[property] = value;
		if (el) {
			el[property] = value;
		}
		break;
	case 'controlStyle':
		this.controlStyle = value;
		if (el) { el.style.cssText = value;	}
		break;

	case 'title':
		this.title = value;
		if (el) { el.title = value;	}
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
		break;
	}
	return true;
}

/// Override default drag behavior.
ClientMethod getDragData(dragData) [ Language = javascript ]
{
	dragData.value = this.text;
	dragData.text = this.text;
	return true;
}

}
