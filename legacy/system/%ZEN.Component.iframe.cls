/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a simple wrapper for the HTML IFRAME component.
Class %ZEN.Component.iframe Extends component [ Deprecated, System = 3 ]
{

/// URI of frame content.
Property src As %ZEN.Datatype.uri;

/// Link to the long description of the iframe.
Property longdesc As %ZEN.Datatype.uri;

/// The align value used for the iframe.
Property frameAlign As %ZEN.Datatype.align;

/// The frameborder value used for the iframe.
Property frameBorder As %ZEN.Datatype.boolean;

/// The scrolling value used for the iframe.
Property scrolling As %ZEN.Datatype.string(VALUELIST = ",auto,yes,no");

Method %DrawHTML()
{
	Set tSrc = ##class(%CSP.Page).Link(..src)
	&html<<iframe id="#(..%MakeId("iframe"))#" #(..%Attr("src",tSrc))# #(..%Attr("name",..name))# #(..%Attr("frameBorder",..frameBorder))# #(..%Attr("align",..frameAlign))# #(..%Attr("longdesc",..longdesc))# #(..%Attr("height",..height))# #(..%Attr("width",..width))# #(..%Attr("scrolling",..scrolling))#></iframe>>
}

/// Get the zenPage object for the document within the iframe
/// (if there is one).
ClientMethod getPage() [ Language = javascript ]
{
	var page = null;
	var iframe = this.findElement('iframe');
	if (iframe && iframe.contentWindow && iframe.contentWindow.zenPage) {
		page = iframe.contentWindow.zenPage;
	}
	return page;
}

/// Get the html document object within the iframe
/// (if there is one).
ClientMethod getDocument() [ Language = javascript ]
{
	var doc = null;
	var iframe = this.findElement('iframe');
	if (iframe && iframe.contentWindow && iframe.contentWindow.document) {
		doc = iframe.contentWindow.document;
	}
	return doc;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var iframe = this.findElement('iframe');

	switch(property) {
	case 'src':
	case 'longdesc':
	case 'height':
	case 'width':
	case 'scrolling':
		this[property] = value;
		if (iframe) {
			iframe[property] = value;
		}
		break;
	case 'frameBorder':
		this.frameBorder = value ? true : false;
		if (iframe) {
			iframe.frameBorder = value ? 1 : 0;
		}
		break;
	case 'frameAlign':
		this.frameAlign = value;
		if (iframe) {
			iframe.align = value;
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
