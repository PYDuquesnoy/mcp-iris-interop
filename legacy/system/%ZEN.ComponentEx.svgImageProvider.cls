/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// SVGImageProvider
/// These utilities are built upon the java .jar libraries in the FOP distribution included
/// with modern releases of InterSystems IRIS
Class %ZEN.ComponentEx.svgImageProvider Extends %ZEN.Component.component [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js";

/// This class does not project HTML into its containing document
Method %DrawHTML()
{
}

/// Return the temp directory for this system.
ClassMethod GetSystemTempDir() As %String
{
	Quit ##class(%SYS.System).TempDirectory()
}

/// Return a random and unique name in the given directory with an 'svg' extention for
/// the creation of temp files during processing
ClassMethod GenerateRootName(dir As %String) As %String [ ZenMethod ]
{
	Set name = ##class(%FileCharacterStream).NewFileName("svg",dir)
	Quit ##class(%File).NormalizeFilename(name,dir)
}

/// Given a user specified file name clip it to ensure that it only refers to 
/// files in the mgr/temp space
ClassMethod ScopeFileName(rawName As %String) As %String [ ZenMethod ]
{
	// Get the list of temp files we've touched (or create one if this is the first)
	If $D(^IRIS.Temp.zenData(%session.SessionId,"svgImageProvider","tempFiles")) {
 		Set activeNames = {}.%FromJSON(^IRIS.Temp.zenData(%session.SessionId,"svgImageProvider","tempFiles"))
	} 
	Else {
		Set activeNames = {}
	} 
	
	Set dir = ..GetSystemTempDir()
	Set name = ##class(%File).GetFilename(rawName)
	
	Set name=$Translate(name,"$<>:""/\|?*","")		// DTB317 - Sanitize the filename for cross-platform use
	
	Set csName = ##class(%File).NormalizeFilename(name,dir)

	// Add the new name to the list of temp files we've created
	// for the purposes of deleting them later.
	Do activeNames.%Set(csName,1)
	Set ^IRIS.Temp.zenData(%session.SessionId,"svgImageProvider","tempFiles") = activeNames.%ToJSON()

	Quit csName
}

ClassMethod ConvertXSLToPDF(pInFile As %String, pOutFile As %String) [ ZenMethod ]
{
	// DTB408 - Use protected callout to the OS for XSL-to-PDF conversion
	Do convertXslToPdf^%SYS.cspServer2(pInFile,pOutFile)
}

/// Mechanism for receiving fragmants of large data streams headed upstream from client 
/// to server.  This work in conjunction with the saveToServer() method.
ClassMethod ReceiveFragment(outputFile As %String, src As %ZEN.proxyObject) As %Status [ ZenMethod ]
{
	Set outputFile = ..ScopeFileName(outputFile)
	Set tSC = $$$OK
	Set $ZTrap = "SaveFileError"
	If (src.part=1) {
		Open outputFile:("NW")
	}
	Else {
		Open outputFile:("AW")
	}
	Use outputFile
	$$$SETIO("UTF8")
	Write src.code
	Close outputFile
	
	Quit tSC
	
SaveFileError
	Set $ZTrap=""
	Set tSC=$$$ERROR($$$GeneralError,$ZE)
	quit tSC
}

/// Remove a file from the mgr/Temp directory
ClassMethod RemoveFile(pFileName) As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		// Get the list of temp files we've touched
		If $D(^IRIS.Temp.zenData(%session.SessionId,"svgImageProvider","tempFiles")) {
 			Set activeNames = {}.%FromJSON(^IRIS.Temp.zenData(%session.SessionId,"svgImageProvider","tempFiles"))
			If (activeNames.%Get(pFileName)=1) {
				Set tFileName = ..ScopeFileName(pFileName)
				If ##class(%Library.File).Exists(tFileName) {
					Set tSC = ##class(%Library.File).Delete(tFileName)
				}
				// Remove the item from our list of touched files
				Do activeNames.%Remove(tFileName)
				Set ^IRIS.Temp.zenData(%session.SessionId,"svgImageProvider","tempFiles") = activeNames.%ToJSON()
			}
		} 
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Client-side utility to send large data streams up to the server for external file storage
/// Normally small data streams can simply be sent up to the host using simple POST requests
/// but we have encountered issues with data loss using very large packets.  To avoid
/// this issue, this method breaks large data streams into universally 'safe' packet lengths
/// and streams the parts up to the server where they are reassembled in the external file 
/// with the given fileName
ClientMethod saveToServer(src, fileName) [ Language = javascript ]
{
	//description originally referred to data loss on IE
	var obj = new zenProxy();
	var part = 1;
	var s=""
	var bufferSize = 32000;		// Set the upstream buffer size. This can be tuned to specific browser limitations.
	for (var i=0;i<src.length;i++) {
		if (s.length+src[i].length < bufferSize) {
			s+=src[i]+"\r\n";
		}
		else {
			obj.part = part++;
			obj.code = s;
			var well = this.ReceiveFragment(fileName,obj);
			s=src[i];
		}
	}
	obj.part = part++;
	obj.code = s;
	var well = this.ReceiveFragment(fileName,obj);
}

/// Given an SVG DOM and (optional) introduction and coda strings containing SVG 
/// code snippets, walk the DOM extracting relavent rendering information and 
/// store the result in an array of strings
ClientMethod extractSVGSource(svg, intro, coda) [ Language = javascript ]
{
	if (svg) {
		var src=[];
		src.push('<?xml version="1.0"?>');
		src.push('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN"');
		src.push('"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">');
		var e=svg;
		for (var p=e.firstChild; p!=null; p=p.nextSibling) {
			if (p.nodeName=='svg') {
				this.rootSVG=true;
				this.dumpSVGNode(p,svg,src,intro,coda,"");
			}
			else this.dumpSVGNode(p,null,src,intro,coda,"");
		}
	}
	return(src);
}

/// Given an SVG DOM and (optional) introduction and coda strings containing SVG 
/// code snippets, walk the DOM extracting relavent rendering information and 
/// store the result in an array of strings
ClientMethod extractXSLFOSource(svg, intro, coda, maxWidth, maxHeight) [ Language = javascript ]
{
	if (svg) {
		var src=[];
		src.push('<fo:block font-size="0pt" >');
		src.push('<fo:instream-foreign-object >');
		var e=svg;
		for (var p=e.firstChild; p!=null; p=p.nextSibling) {
			if (p.nodeName=='svg') {
				this.rootSVG=true;
				this.dumpSVGNode(p,svg,src,intro,coda,"svg:",maxWidth,maxHeight);		// DTB561
			}
			else this.dumpSVGNode(p,null,src,intro,coda,"svg:");
		}
		src.push('</fo:instream-foreign-object>');
		src.push('</fo:block>');
	}
	return(src);
}

/// Given an SVG DOM and (optional) introduction and coda strings containing SVG 
/// code snippets, walk the DOM extracting relavent rendering information and 
/// return the result in one big string.
ClientMethod saveDOMToSVGStream(svg, intro, coda) [ Language = javascript ]
{
	if (svg) {
		var src = this.extractSVGSource(svg,intro,coda);;
		return(src.join('\n'));
	}
	return("");
}

/// Given an SVG DOM and (optional) introduction and coda strings containing SVG 
/// code snippets, walk the DOM extracting FO rendering information and 
/// return the result in one big string.
ClientMethod saveDOMToXSLFOStream(svg, intro, coda) [ Language = javascript ]
{
	if (svg) {
		var src = this.extractXSLFOSource(svg,intro,coda);
		return(src.join('\n'));
	}
	return("");
}

/// Given an SVG DOM, the name of a server side file to create/overwrite, and (optional)
/// introduction and coda strings containing SVG code snippets, walk the DOM extracting 
/// relavent rendering information and store the result in a stand-alone file on the server.
ClientMethod saveDOMToSVGFile(svg, fileName, intro, coda) [ Language = javascript ]
{
	if (svg) {
		var src= this.extractSVGSource(svg,intro,coda);
		this.saveToServer(src,fileName);
	}
}

/// Given an SVG DOM, the name of a server side file to create/overwrite, and (optional)
/// introduction and coda strings containing SVG code snippets, walk the DOM extracting 
/// XSLFO rendering information and store the result in a stand-alone file on the server.
ClientMethod saveDOMToXSLFOFile(svg, fileName, intro, coda) [ Language = javascript ]
{
	if (svg) {
		var src= this.extractXSLFOSource(svg,intro,coda);
		this.saveToServer(src,fileName);
	}
}

/// Return a javascript object that contains the various default values
/// for page set-up and meta data rendering.  Users can get this object,
/// modify its values as desired and then pass it to the actual renderer
/// methods
ClientMethod getPageSetupDefaults() [ Language = javascript ]
{
	var o = {};
	o.pageWidth = "8.5in";	
	o.pageHeight = "11in";
	o.marginLeft = "72pt";
	o.marginRight = "72pt";
	o.marginTop = "36pt";
	o.marginBottom = "36pt";
	o.imageWidth = "468pt";
	o.imageHeight = "720pt";		// DTB561
	o.omitPageNumbers = false;
	o.svgIntro = "";
	o.svgCoda = "";
	o.foIntro = "";
	o.foCoda = "";
	o.fileName = "image";
	o.title = "SVG IMAGE";
	return(o);
}

/// Set up a default page setup object, incorporating user
/// overrides, if defined
ClientMethod reconcileDefaults(metaDataJS) [ Language = javascript ]
{
	var o = this.getPageSetupDefaults();
	if (metaDataJS) {
		for (p in metaDataJS) {
			o[p] = metaDataJS[p];
		}
	}
	return(o);
}

/// Given an SVG DOM, the name of a server side file to create/overwrite, and (optional)
/// introduction and coda strings containing SVG code snippets, walk the DOM extracting 
/// XSLFO rendering information and store the result as a full XSL-FO document on the server.
ClientMethod saveDOMToXSLFile(svg, metaDataJS) [ Language = javascript ]
{
	var ps=this.reconcileDefaults(metaDataJS);
	var font = "Arial";		// DTB577 - Font defaults to Arial
	if (svg) {
		var tmp = [];
		tmp.push('<?xml version="1.0" encoding="utf-8" ?>');
		tmp.push('<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
		tmp.push('<fo:layout-master-set>');
		
		tmp.push('<fo:simple-page-master master-name="all-pages" ');
		tmp.push(' page-width="'+ps.pageWidth+'" ');
		tmp.push(' page-height="'+ps.pageHeight+'" ');
		tmp.push(' margin-left="'+ps.marginLeft+'" ');
		tmp.push(' margin-right="'+ps.marginRight+'" ');
		tmp.push(' margin-top="'+ps.marginTop+'" ');
		tmp.push(' margin-bottom="'+ps.marginBottom+'">');
		
		tmp.push('<fo:region-body margin-top="0.5in" />');
		tmp.push('<fo:region-before extent="0.75in"/>');
		tmp.push('</fo:simple-page-master>');
		
		tmp.push('<fo:page-sequence-master master-name="default-sequence">');
		tmp.push('<fo:repeatable-page-master-reference master-reference="all-pages" />');
		tmp.push('</fo:page-sequence-master>');
				
		tmp.push('</fo:layout-master-set>');

		tmp.push('<fo:page-sequence master-reference="default-sequence" font-family="'+font+'">');

		tmp.push('<fo:static-content flow-name="xsl-region-before" border-bottom-style="solid" border-bottom-width="1pt" border-bottom-color="#D0D0D0" font-size="10pt" font-family="'+font+'">');
		tmp.push('<fo:block color="#000000" text-align-last="justify">');
		if (ps.title) tmp.push(zenEscapeXML(ps.title));			// DTB352 - Escape the raw title
		tmp.push('<fo:leader/>');
		tmp.push('<fo:inline font-size="10pt" font-weight="normal">');
		if (!ps.omitPageNumbers) tmp.push('Page <fo:page-number/> of <fo:page-number-citation ref-id="EOD"/>');
		tmp.push('</fo:inline>');
		tmp.push('</fo:block>');
		tmp.push('</fo:static-content>');

		tmp.push('<fo:flow flow-name="xsl-region-body" font-family="'+font+'" font-size="10pt">');
		// DTB252 - Add a master containing block to aid content extraction for pdf merge
		tmp.push('<fo:block id="pageContent">');
		if (ps.foIntro) tmp.push('\n'+ps.foIntro+'\n');
		tmp.push('<fo:block color="#000000" text-align="center" margin-bottom="10pt" font-size="18pt" font-family="'+font+'">');

		var src= this.extractXSLFOSource(svg,ps.svgIntro,ps.svgCoda,ps.imageWidth,ps.imageHeight);		// DTB561 - Add imageHeight
		for (var i=0;i<src.length;i++) tmp.push(src[i]);
		tmp.push('</fo:block>');
		if (ps.foCoda) tmpPush(ps.foCoda);
		tmp.push('</fo:block>');		// DTB252 Close the new block
		tmp.push('<fo:block id="EOD"/>');
		tmp.push('</fo:flow>');
		tmp.push('</fo:page-sequence>');			
		tmp.push('</fo:root>');
		this.saveToServer(tmp,ps.fileName);
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this._debug = false;
}

ClientMethod makeSVGFileName(name) [ Language = javascript ]
{
	if (!name || name=="") {
		this.fileName = "";
	}
	else {
		this.fileName = this.ScopeFileName(name);
	}
	return(this.fileName);
}

/// Given some form of zen SVGComponent, return a pointer to the root of 
/// the embedded SVG document model
ClientMethod getSVGDOMRoot(image) [ Language = javascript ]
{
	var svg = null;
	var item = zenPage.getComponentById(image);
	if (item) var svg = item.getSVGDocument();
	return(svg);
}

ClientMethod saveToSVGFile(image, name, intro, coda) [ Language = javascript ]
{
	var svg = this.getSVGDOMRoot(image);
	if (svg) this.saveDOMToSVGFile(svg, name, intro, coda);
}

ClientMethod saveToXSLFOSnippet(image, name, intro, coda) [ Language = javascript ]
{
	var svg = this.getSVGDOMRoot(image);
	if (svg) this.saveDOMToXSLFOFile(svg, name, intro, coda);
}

ClientMethod saveToXSLFile(image, metaDataJS) [ Language = javascript ]
{
	var svg = this.getSVGDOMRoot(image);
	if (svg) this.saveDOMToXSLFile(svg, metaDataJS);
}

/// Quick check to test for embedded whitespace and control characters
ClientMethod isWhiteSpace(str) [ Language = javascript ]
{
	for (var i=0;i<str.length;i++) {
		var c=str.charCodeAt(i);
		if (c>32) return(false);
	}
	return(true);
}

/// Given an element, an active SVG DOM, a syntax buffer, and optional introduction and coda 
/// strings, recursively extract all of the descendant node information from the DOM and copy 
/// it to the syntax buffer adding appropriate lexical and syntactic elements as needed.<br/>
/// If intro and coda values have been provided, inject the contents of these strings into the
/// syntax buffer immediately after the opening of the first encountered <svg> tag and immediately 
/// before the close of that same tag, respectively.
ClientMethod dumpSVGNode(e, svgDoc, src, intro, coda, NSPrefix, maxWidth, maxHeight) [ Language = javascript ]
{
	var echoBack = false;
	var addCoda = false;
	var escapeXML = true;		// DTB456 - Add switch for future customization
	if (e.nodeName=='#text') {
		if (!this.isWhiteSpace(e.nodeValue)) {
			if (echoBack) ZLM.cerr(e.nodeValue);
			if (escapeXML) {
				src.push(zenEscapeXML(e.nodeValue));		// DTB456 - Escape XML text for printing
			}
			else {
				src.push(e.nodeValue);
			}
		}
		return;
	}
	if (e.nodeName=='#comment') {
		if (e.nodeValue!='\n') {
			if (echoBack) ZLM.cerr('<!-- '+e.nodeValue+' -->');
			src.push('<!-- '+e.nodeValue+' -->');
		}
		return;
	}
	if (e.nodeName=="#cdata-section") {
		if (e.nodeValue!='\n') {
			if (echoBack) ZLM.cerr(e.nodeValue);
			src.push(e.nodeValue);
		}
		return;
	}
	var s="<"+NSPrefix+e.nodeName+" ";
	if (e.nodeName=="xml-stylesheet") return;
	if (e.nodeName=="script") return;
	if (e.nodeName=="style") return;
	if (e.nodeName.indexOf("html:")>=0) return; // firebug hook - skip it
	var hasWidth=false;
	var hasHeight=false;
	var hasViewBox=false;
	var attrHeight = "";
	var attrWidth = "";
	if (e.attributes) {
		for (var i=0;i<e.attributes.length;i++) {
			var a = {}
			if (zenIsIE) {
				a.name=e.attributes.item(i).name;
				a.value=e.attributes.item(i).value;
			}
			else {
				a.name = e.attributes[i].name;
				a.value = e.attributes[i].value;
			}
			if (a.value.indexOf('"')>=0) {
				var tmp = a.value.split('"');
				a.value = tmp.join("'");
			}
			// don't bother generating non-visible items
			if (a.name=='display' && a.value=='none') return;
			if (a.name=='viewBox') hasViewBox = true;
			if (a.name=='width') {
				attrWidth = a.value;
				hasWidth=true;
			}
			if (a.name=='height') { 
				attrHeight = a.value;
				hasHeight=true;
			}	
			if (a.value && a.name.indexOf('on')!=0) s+=a.name+'="'+a.value+'" ';
		}
	}
	if (!hasWidth || !hasHeight) {
		if (e.nodeName=='rect') return;
	}
	if (e.nodeName=='svg' && this.rootSVG) {
		if (hasWidth && hasHeight && !hasViewBox && maxWidth) {
			var newView = "0 0 "+parseInt(attrWidth)+" "+parseInt(attrHeight);
			var newHeight = (parseInt(maxWidth)*parseInt(attrHeight))/(parseInt(attrWidth));
			if ((parseInt(maxHeight))&&(newHeight>parseInt(maxHeight))) {
				// DTB561 - Max height may be supplied, make this the hard limit on avialable space.
				newHeight = parseInt(maxHeight);
			}
			var sa = s.split(" ");
			var sal = sa.length;
			for (var sIdx = 0; sIdx<sal; sIdx++) {
				var attr = sa[sIdx];
				if (attr.indexOf("width=")==0) sa[sIdx] = 'width="'+parseInt(maxWidth)+'"';
				if (attr.indexOf("height=")==0) sa[sIdx] = 'height="'+newHeight+'"';;
			}
			sa.push('viewBox="'+newView+'"');
			s = sa.join(" ");			
		}
	}
	
	if (!e.firstChild && !svgDoc) {
		s+=" />"
		if (echoBack) ZLM.cerr(s);
		src.push(s);
		return;
	}
	s+=">";
	if (e.nodeName!='_rootBody') {
		if (echoBack) ZLM.cerr(s);
		src.push(s);
	}
	
	if (svgDoc) this.dumpSVGStyle(svgDoc,src,NSPrefix);
	if (e.nodeName=='svg' && this.rootSVG && intro) {
		this.rootSVG = false;
		if (intro.join) src.push(intro.join("\n"));
		else src.push(intro);
		addCoda=true;
	}
	for (var p=e.firstChild;p!=null;p=p.nextSibling) {
			this.dumpSVGNode(p,null,src,intro,coda,NSPrefix);
	}
	if (addCoda && coda) {
		if (coda.join) src.push(coda.join("\n"));
		else src.push(coda);
	}
	
	if (e.nodeName!='_rootBody') { 
		if (echoBack) ZLM.cerr("</"+e.nodeName+">");
		src.push("</"+NSPrefix+e.nodeName+">");
	}
}

/// Given an active SVG DOM and a syntax buffer, extract all embedded stylesheets and
/// copy them to the buffer adding appropriate lexical and syntactic elements as needed
ClientMethod dumpSVGStyle(svgDoc, src, NSPrefix) [ Language = javascript ]
{
		var e=svgDoc;
		src.push('<'+NSPrefix+'defs><'+NSPrefix+'style type="text/css" ><![CDATA[');
		if (e.styleSheets) {			// DTB - check to make sure the style sheets exist!
			for(var si=0;si<e.styleSheets.length;si++) {
				var ss=e.styleSheets[si];
				for (var ri=0; ri<ss.cssRules.length;ri++) {
					var cssBody = ss.cssRules[ri].cssText;
					if (cssBody) {
						if (cssBody.indexOf("cursor")>=0) { // remove rules related to cursor rollover
							var tmp = cssBody.split("cursor:");
							var balance = tmp[1].slice(tmp[1].indexOf(';')+1)
							cssBody = tmp[0]+balance;
						}
						if (cssBody.indexOf("rgba(")>=0) { // Batik doesn't take RGBA values
							var tmp = cssBody.split("rgba(");
							for (var i=1;i<tmp.length;i++) {
								var balance = tmp[i];
								var tmp2 = balance.split(")");
								var args = tmp2[0].split(",");
								tmp2[0]=args[0]+","+args[1]+","+args[2];
								tmp[i] = tmp2.join(")");
							}
							cssBody = tmp.join("rgb("); 
						}
						src.push(cssBody);
					}
				}
			}
		}
		src.push(']]></'+NSPrefix+'style></'+NSPrefix+'defs>');
}

ClientMethod buildFOStyleString(jsDesc) [ Language = javascript ]
{
	 var s = [];
	 if (jsDesc) {		 
		 for (p in jsDesc) {
			 switch(p) {
				 case "backgroundAttachment":
				 	s.push('background-attachment="'+jsDesc[p]+'"');
				 	break;
				 case "backgroundColor":
					s.push('background-color="'+jsDesc[p]+'"');
				 	break;
				 case "backgroundImage":
					s.push('background-image="'+jsDesc[p]+'"');
				 	break;
				 case "backgroundPosition":
				 	var pos = jsDesc[p].split[" "];
					s.push('background-position-horizontal="'+pos[0]+'"');
					s.push('background-position-vertical="'+pos[1]+'"');
				 	break;
				 case "backgroundRepeat":
					s.push('background-repeat="'+jsDesc[p]+'"');
				 	break;
				 case "border":
				 	var pos = jsDesc[p].split[" "];
					s.push('border-bottom-width="'+pos[0]+'"');
					s.push('border-left-width="'+pos[0]+'"');
					s.push('border-right-width="'+pos[0]+'"');
					s.push('border-top-width="'+pos[0]+'"');
					s.push('border-bottom-style="'+pos[1]+'"');
					s.push('border-left-style="'+pos[1]+'"');
					s.push('border-right-style="'+pos[1]+'"');
					s.push('border-top-style="'+pos[1]+'"');
					s.push('border-bottom-color="'+pos[2]+'"');
					s.push('border-left-color="'+pos[2]+'"');
					s.push('border-right-color="'+pos[2]+'"');
					s.push('border-top-color="'+pos[2]+'"');
				 	break;
				 case "borderBottomColor":
					s.push('border-bottom-color="'+jsDesc[p]+'"');
				 	break;
				 case "borderBottomStyle":
					s.push('border-bottom-style="'+jsDesc[p]+'"');
				 	break;
				 case "borderBottomWidth":
					s.push('border-bottom-width="'+jsDesc[p]+'"');
				 	break;
				 case "borderBottom":
				 	var pos = jsDesc[p].split[" "];
					s.push('border-bottom-width="'+pos[0]+'"');
					s.push('border-bottom-style="'+pos[1]+'"');
					s.push('border-bottom-color="'+pos[2]+'"');
				 	break;
				 case "borderBottomColor":
					s.push('border-bottom-color="'+jsDesc[p]+'"');
				 	break;
				 case "borderBottomStyle":
					s.push('border-bottom-style="'+jsDesc[p]+'"');
				 	break;
				 case "borderBottomWidth":
					s.push('border-bottom-width="'+jsDesc[p]+'"');
				 	break;
				 case "borderLeft":
				 	var pos = jsDesc[p].split[" "];
					s.push('border-left-width="'+pos[0]+'"');
					s.push('border-left-style="'+pos[1]+'"');
					s.push('border-left-color="'+pos[2]+'"');
				 	break;
				 case "borderLeftColor":
					s.push('border-left-color="'+jsDesc[p]+'"');
				 	break;
				 case "borderLeftStyle":
					s.push('border-left-style="'+jsDesc[p]+'"');
				 	break;
				 case "borderLeftWidth":
					s.push('border-left-width="'+jsDesc[p]+'"');
				 	break;
				 case "borderRight":
				 	var pos = jsDesc[p].split[" "];
					s.push('border-right-width="'+pos[0]+'"');
					s.push('border-right-style="'+pos[1]+'"');
					s.push('border-right-color="'+pos[2]+'"');
				 	break;
				 case "borderRightColor":
					s.push('border-right-color="'+jsDesc[p]+'"');
				 	break;
				 case "borderRightStyle":
					s.push('border-right-style="'+jsDesc[p]+'"');
				 	break;
				 case "borderRightWidth":
					s.push('border-right-width="'+jsDesc[p]+'"');
				 	break;
				 case "borderTop":
				 	var pos = jsDesc[p].split[" "];
					s.push('border-top-width="'+pos[0]+'"');
					s.push('border-top-style="'+pos[1]+'"');
					s.push('border-top-color="'+pos[2]+'"');
				 	break;
				 case "borderTopColor":
					s.push('border-top-color="'+jsDesc[p]+'"');
				 	break;
				 case "borderTopStyle":
					s.push('border-top-style="'+jsDesc[p]+'"');
				 	break;
				 case "borderTopWidth":
					s.push('border-top-width="'+jsDesc[p]+'"');
				 	break;
				 case "bottom":
					s.push('bottom="'+jsDesc[p]+'"');
				 	break;
				 case "color":
					s.push('color="'+jsDesc[p]+'"');
				 	break;
				 case "endIndent":
					s.push('end-indent="'+jsDesc[p]+'"');
				 	break;
				 case "fontFamily":
					s.push('font-family="'+jsDesc[p]+'"');
				 	break;
				 case "fontSelectionStrategy":
					s.push('font-selection-strategy="'+jsDesc[p]+'"');
				 	break;
				 case "fontSize":
					s.push('font-size="'+jsDesc[p]+'"');
				 	break;
				 case "fontSizeAdjust":
					s.push('font-size-adjust="'+jsDesc[p]+'"');
				 	break;
				 case "fontStretch":
					s.push('font-stretch="'+jsDesc[p]+'"');
				 	break;
				 case "fontStyle":
					s.push('font-style="'+jsDesc[p]+'"');
				 	break;
				 case "fontVariant":
					s.push('font-variant="'+jsDesc[p]+'"');
				 	break;
				 case "fontWeight":
					s.push('font-weight="'+jsDesc[p]+'"');
				 	break;
				 case "height":
					s.push('height="'+jsDesc[p]+'"');
				 	break;
				 case "left":
					s.push('left="'+jsDesc[p]+'"');
				 	break;
				 case "linefeedTreatment":
					s.push('linefeed-treatment="'+jsDesc[p]+'"');
				 	break;
				 case "lineHeight":
					s.push('line-height="'+jsDesc[p]+'"');
				 	break;
				 case "lineHeightShiftAdjustment":
					s.push('line-height-shift-adjustment="'+jsDesc[p]+'"');
				 	break;
				 case "lineStackingStrategy":
					s.push('line-stacking-strategy="'+jsDesc[p]+'"');
				 	break;
				 case "margin":
				 	s.push('margin-bottom="'+jsDesc[p]+'"');
				 	s.push('margin-left="'+jsDesc[p]+'"');
				 	s.push('margin-right="'+jsDesc[p]+'"');
				 	s.push('margin-top="'+jsDesc[p]+'"');
				 	break;
				 case "marginBottom":
					s.push('margin-bottom="'+jsDesc[p]+'"');
				 	break;
				 case "marginLeft":
					s.push('margin-left="'+jsDesc[p]+'"');
				 	break;
				 case "marginRight":
					s.push('margin-right="'+jsDesc[p]+'"');
				 	break;
				 case "marginTop":
					s.push('margin-top="'+jsDesc[p]+'"');
				 	break;
				 case "padding":
					s.push('padding-bottom="'+jsDesc[p]+'"');
					s.push('padding-left="'+jsDesc[p]+'"');
					s.push('padding-right="'+jsDesc[p]+'"');
					s.push('padding-top="'+jsDesc[p]+'"');
				 	break;
				 case "paddingBottom":
					s.push('padding-bottom="'+jsDesc[p]+'"');
				 	break;
				 case "paddingLeft":
					s.push('padding-left="'+jsDesc[p]+'"');
				 	break;
				 case "paddingRight":
					s.push('padding-right="'+jsDesc[p]+'"');
				 	break;
				 case "paddingTop":
					s.push('padding-top="'+jsDesc[p]+'"');
				 	break;
				 case "position":
				 	if (jsDesc[p]=="relative") s.push('relative-position="'+jsDesc[p]+'"');
				 	break;
				 case "right":
					s.push('right="'+jsDesc[p]+'"');
				 	break;
				 case "startIndent":
					s.push('start-indent="'+jsDesc[p]+'"');
				 	break;
				 case "textAlign":
					s.push('text-align="'+jsDesc[p]+'"');
				 	break;
				 case "textAlignLast":
					s.push('text-align-last="'+jsDesc[p]+'"');
				 	break;
				 case "textAltitude":
					s.push('text-altitude="'+jsDesc[p]+'"');
				 	break;
				 case "textDepth":
					s.push('text-depth="'+jsDesc[p]+'"');
				 	break;
				 case "textIndent":
					s.push('text-indent="'+jsDesc[p]+'"');
				 	break;
				 case "top":
					s.push('top="'+jsDesc[p]+'"');
				 	break;

				 case "width":
					s.push('width="'+jsDesc[p]+'"');
				 	break;
			 }
		 }
	 }
	 

	 return(" "+s.join(" ")+" ");
}

ClientMethod buildFOBlock(jsDesc) [ Language = javascript ]
{
	 //Expects an object that looks like:
	 // {caption:"Hello world",style:{backgroundColor:#ff5555,color:#ffff00,fontWeight:"bold"}}
 	var s = [];
 	if (jsDesc) {
		var caption = zenEscapeXML(jsDesc.caption);		// DTB352 - Encode the caption for XML
		var style = jsDesc.style;
		var styleStr = this.buildFOStyleString(style);
		s.push('<fo:block '+styleStr+'>'+caption+'</fo:block>');
 	}
 	return (s.join("\n"));
}

ClientMethod buildFOTable(jsDesc) [ Language = javascript ]
{
 //{
 // header: [
 //   { caption:"Filter", width:"144pt", style:{fontWeight:"bold"} }
 //   { caption:"Setting", width:"144pt", style:{fontWeight:"bold"} }
 // ],
 // rows: [
 //  {
 //	    cells:[ 
 //			{caption:"Just a test",style:{backgroundColor:"#bbffff"}},
 //			{caption"whatever"}
 //		],
 //  },
 //  {
 //	    cells:[ 
 //			{caption:"More stuff",style:{backgroundColor:"#bbffff"}},
 //			{caption:"whatever"}
 //		],
 //  },
 //  ]

	 var s = []
	 if (jsDesc && jsDesc.header && jsDesc.rows) {
		var header = jsDesc.header;
		s.push("<fo:block>");
		s.push("<fo:table>");
		var hLen = header.length;
		for (var i=0;i<hLen;i++) {
			var w = header[i].width;
			if (w) s.push('<fo:table-column column-width="'+w+'"/>');
		}
		s.push('<fo:table-header>');
		s.push('<fo:table-row>');
		for (var i=0;i<hLen;i++) {
			var caption = header[i].caption;
			var style = header[i].style;
			var styleStr = this.buildFOStyleString(style);
			s.push('<fo:table-cell>');
			s.push('<fo:block '+styleStr+'>'+caption+'</fo:block>');
			s.push('</fo:table-cell>');		 
		}
		s.push('</fo:table-row>');
		s.push('</fo:table-header>');

		s.push('<fo:table-body>');
		var rows = jsDesc.rows;
		var nRows = rows.length;
		for (var l = 0; l<nRows; l++) {
			s.push('<fo:table-row>');
			var r = rows[l];
			var cells = r.cells;
			var nCells = cells.length;
			for (var i=0;i<nCells;i++) {
				s.push('<fo:table-cell>');
				var caption = cells[i].caption;
				var style = cells[i].style;
				var styleStr = this.buildFOStyleString(style);
				s.push('<fo:block '+styleStr+'>'+caption+'</fo:block>');
				s.push('</fo:table-cell>');
			}
			s.push('</fo:table-row>');
		}	 
		s.push('</fo:table-body>');
		s.push('</fo:table>');
		s.push('</fo:block>');
 	}
 //NTS: MIGHT WANT TO SUPPORT SOME OF THESE SETTINGS SOME DAY... 
 //block-progression-dimension
 //break-after
 //break-before
 //column-number
 //display-align
 //empty-cells
 //ends-row
 //number-columns-spanned
 //number-rows-spanned
 //starts-row
 	return (s.join("\n"));
}

}
