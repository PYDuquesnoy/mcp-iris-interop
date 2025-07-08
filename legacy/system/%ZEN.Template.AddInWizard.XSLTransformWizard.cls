/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template.<br>
/// The XSL Transform Wizard transforms an XML file using the specified XSL stylesheet.<br>
Class %ZEN.Template.AddInWizard.XSLTransformWizard Extends %ZEN.Template.AddInWizard.Template [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "XSL Transform Wizard";

Parameter TEMPLATETITLE = "XSL Transform Wizard";

Parameter TEMPLATEDESCRIPTION = "transforms an XML file using the specified XSL stylesheet";

/// Display title of this page <title></title>
Parameter PAGETITLE = "XSL Transform Wizard";

Parameter HELPID = "GXML_xslt_wizard";

Property Multiple As %ZEN.Datatype.boolean;

/// Number of total Namespaces which is the same as total packages
Property TotalPackages As %ZEN.Datatype.integer;

/// String that contains package names delimited by comma.
Property Packages As %ZEN.Datatype.string;

/// Text field name that user last clicked Browse on.
Property BrowseField As %String;

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" cellStyle="padding-left:10px;">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<tabGroup id="tabGroup">

<!-- First Page -->
<tab id="tab1" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="1"/>
  <hgroup labelPosition="left" cellVAlign="top"  >   
  <text id="FILENAME" label="XML File:" labelClass="zenRequired" size="80"
 value="" /> 
 <button caption="Browse" onclick="zenPage.doBrowse('FILENAME');"/>
 </hgroup>
<hgroup labelPosition="left" cellVAlign="top" >   
  <text id="XSLTFILENAME" label="XSL File:" labelClass="zenRequired" size="80"
 value="" />
 <button caption="Browse" onclick="zenPage.doBrowse('XSLTFILENAME');"/>
 </hgroup>
 <hgroup labelPosition="left" cellVAlign="top" >
 <select id="XSLTNSPACE" label="XSLT Helper Class:" showEmpty="false" onchange="zenPage.changeHelper(zenThis);"/>
 <select id="XSLTHELPERCLASS" />
 </hgroup>
 <hgroup labelPosition="left" cellVAlign="top" >
 <select id="XSLTRENDERAS" label="Render As:" valueList="Text,XML" showEmpty="false"/>
 </hgroup>
 <html><hr size="1"/></html>
 <!-- this iframe will hold the display of both XML and Text output -->
 <iframe id="iframePreview" showLabel="false" hidden="true"/>
</tab>

</tabGroup>
</pane>
}

/// Reload HelperClass valueList when user changed namespace
ClientMethod changeHelper(ctl) [ Language = javascript ]
{
	var ns = ctl.getValue();
	var valueList = this.LoadHelperClassList(ns);
	zen("XSLTHELPERCLASS").setProperty("valueList",valueList);
}

/// Launching a file selector window. 
ClientMethod doBrowse(fieldName) [ Language = javascript ]
{
	this.BrowseField = fieldName;
	var Dir = zen(fieldName).getValue();
	var wildcard = "*.xml";
	if (fieldName == "XSLTFILENAME") wildcard = "*.xsl";
	var url = "%ZEN.Dialog.fileSelect.cls?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=0&CSPCHD=" + this.CSPSessionCookie + "&CSPSHARE=1";
	zenLaunchPopupWindow(url,'FileSelection','status,scrollbars,resizable,width=600,height=700');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen(this.BrowseField).setValue(value);
		zenPage.updateState();	
	}
}

Method %OnAfterCreatePage() As %Status
{
	#; Load namespaces into drop-down
	Set tCombo = ..%GetComponentById("XSLTNSPACE")
	Do List^%SYS.NAMESPACE(.NspList,5,0,1)
	Set LastNamespace = $G(^ISC.XSLTWizard($Username,"LastNamespace"))
	Set valueList = ""
	Set tNamespace = $O(NspList(""))
	While tNamespace '= "" {
		Set tEnabled = $lg(NspList(tNamespace),1)
		If tEnabled = 1 {
			Set valueList = valueList _ $S(valueList'="":",",1:"") _ tNamespace
		} 
		Set tNamespace = $O(NspList(tNamespace))
	}
	Set tCombo.valueList = valueList
	Set tCombo.value = LastNamespace
	
	#; Load helper classes into drop-down
	If LastNamespace '= "" {
		Set ..%GetComponentById("XSLTHELPERCLASS").valueList = ..LoadHelperClassList(LastNamespace)
	}
	#; Load the rest of defaults
	Set ..%GetComponentById("FILENAME").value = $G(^ISC.XSLTWizard($Username,"LastXMLFile"))
	Set ..%GetComponentById("XSLTFILENAME").value = $G(^ISC.XSLTWizard($Username,"LastXSLTFile"))
	Set ..%GetComponentById("XSLTHELPERCLASS").value = $G(^ISC.XSLTWizard($Username,"LastHelper"))
	Set ..%GetComponentById("XSLTRENDERAS").value = $G(^ISC.XSLTWizard($Username,"LastRenderAs"))
	Set %page.Namespace = $namespace
	Quit $$$OK
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
ClientMethod canFinish() [ Language = javascript ]
{
	return true;
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	zen('FILENAME').focus();
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("iframePreview");
	var wd = (document.documentElement.clientWidth ? document.documentElement.clientWidth : document.body.clientWidth) - 20;
	var ht = (document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight) - 450;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// Zen page notification of an HTTP request. This method can be overwritten
/// by subclasses.<br/>
/// This is called <em>before</em> the standard Zen pre-HTTP processing occurs.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	// Allow one hour for compiles.
	Set %response.Timeout = 3600
	Quit 1
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return false;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	zenPage.updateState();
}

ClientMethod showMsg(msg) [ Language = javascript ]
{
	zen("idRespond").setValue(msg);
 	zen("idRespond").setHidden(false);
}

ClientMethod resetMsg() [ Language = javascript ]
{
	zen("idRespond").setValue('');
 	zen("idRespond").setHidden(true);
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = ""
	If pSeed = 1 {
		Set tPageTitle = $$$Text("The XSL Wizard transforms an XML file using the specified XSL stylesheet.")_"<br><br>"_
		$$$Text("Enter a source XML file and a stylesheet by selecting a file (using the <span class='guibutton'>Browse</span> button) or by entering a URL and then press <span class='guibutton'>Finish</span> to transform.")_"<br><br>"
	}
	Set tStep = ""
	Set:pSeed>1 tStep = $$$FormatText($$$Text("Step %1"),pSeed)_" - "
	&html<<div class="Description">#(tStep)##(tPageTitle)#
	</div><hr>>
	Quit $$$OK
}

ClientMethod validate(xmlfile, xslfile) [ Language = javascript ]
{
	try {
		var ok = this.ValidateFile(xmlfile,"XML");
		if (ok != 1) {
			this.showMsg(ok);
			zen("FILENAME").focus();
			return false;					
		}
		var ok = this.ValidateFile(xslfile,"XSLT");
		if (ok != 1) {
			this.showMsg(ok);
			zen("XSLTFILENAME").focus();
			return false;					
		}
	} catch (ex) {
		alert("Error in validate: " + ex);
	}
	return true;
}

/// Validate; call Transform and show result; save user input.
ClientMethod onfinishHandler() [ Language = javascript ]
{
	try {
		var xmlfile = zen("FILENAME").getValue();
		var xslfile = zen("XSLTFILENAME").getValue();
		var ok = this.validate(xmlfile,xslfile);
		if (!ok) return false;
		this.resetMsg();
		var namespace = zen("XSLTNSPACE").getValue();
		var helperclass = zen("XSLTHELPERCLASS").getValue();
		var renderas = zen("XSLTRENDERAS").getValue();
		var proxy = this.DoTransform(xmlfile,xslfile,namespace,helperclass,renderas);
		if (proxy) {
			if (proxy.Message != "") {
				this.showMsg(proxy.Message);
				return false;
			}
			if (renderas == "Text") {
				var isrc = "_ZEN.Template.AddInWizard.XSLTransformWizardOutput.cls?$NAMESPACE=" + encodeURIComponent(this.Namespace);
			} else {
				var isrc = proxy.resultfile;		
			}
			var iframe = zen("iframePreview");
			this.onresizeHandler();
			iframe.setHidden(false);
			iframe.setProperty("src",isrc);
		}
	} catch (ex) {
		alert("Error in onfinishHandler: " + ex);
	}
	return false;
}

/// Taken user's input and process transform.
ClassMethod DoTransform(xmlfile, xslfile, namespace, helper, renderas) As %ZEN.proxyObject [ ZenMethod ]
{
 Try {
	
	Do ..SaveLast(xmlfile, xslfile, namespace, helper, renderas)

	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.xmlout = ""
	
	Set file = xmlfile
	// Workaround bug in $zcvt(s,"I","URL")
	Do {
		set pos=$find(file,"%3F")
		if pos'=0 set $extract(file,pos-3,pos-1)="?"
	} while pos'=0

	Set XSLTfile = xslfile
	// Workaround bug in $zcvt(s,"I","URL")
	Do {
		set pos=$find(XSLTfile,"%3F")
		if pos'=0 set $extract(XSLTfile,pos-3,pos-1)="?"
	} while pos'=0
	
	Set XSLTHelper = helper
	Set XSLTHelper = $ZCVT(XSLTHelper,"I","URL")
	
	Set nspace = namespace
	Set nspace = $ZCVT(nspace,"I","URL")

	Set renderas = $ZCVT(renderas,"I","URL")

	// Need schema server for file
	// file should never be null coming here.
	if file="" {
		Set tProxy.resultfile = ""
		Set tProxy.Message = "File is null!"
	} else {
		Set status = ..Transform(file,XSLTfile,XSLTHelper,nspace,.xmlout)
		If $$$ISOK(status) {
			Set tProxy.xmlout = xmlout
			Set tProxy.resultfile = "_XML.Utils.SchemaServer.cls?FILE=" _ ..Encrypt($zcvt(xmlout,"O","UTF8"))
			Set tProxy.Message = ""
			If renderas="Text" Set ^ISC.XSLTWizard($Username,"xmlout") = xmlout
		} Else {
			Set tProxy.resultfile = ""
			Set tProxy.Message = ..EscapeHTML(status)
			Set ^ISC.XSLTWizard($Username,"Message") = tProxy.Message
		}
	}
   } Catch {
		Set tProxy.Message = $$$Text("Unexpected error occurred in DoTransform: ") _ $ZE
   }
   Quit tProxy
}

/// Save user input.
ClassMethod SaveLast(xmlfile, xslfile, namespace, helper, renderas) [ ZenMethod ]
{
	// remember settings 
	Set ^ISC.XSLTWizard($Username,"LastXMLFile") = xmlfile
	Set ^ISC.XSLTWizard($Username,"LastXSLTFile") = xslfile
	Set ^ISC.XSLTWizard($Username,"LastNamespace") = namespace
	Set ^ISC.XSLTWizard($Username,"LastHelper") = helper
	Set ^ISC.XSLTWizard($Username,"LastRenderAs") = renderas
}

/// Actual code to call transform code on server
ClassMethod Transform(xmlfile, xslfile, helperclass, namespace, results) As %String
{
	Try {
		Set sc = $$$OK
		Set oldns = $namespace
		If oldns '= namespace Set $Namespace = namespace
		Set helper = $S(helperclass'="":$classmethod(helperclass,"%New"),1:$$$NULLOREF)
		set tempdir = ##class(%File).NormalizeDirectory($system.Util.ManagerDirectory())
		set tempdir = ##class(%File).NormalizeDirectory(tempdir_"Temp")
		set results = tempdir_##class(%FileCharacterStream).NewFileName(,tempdir)
		Set sc = ##class(%XML.XSLT.Transformer).TransformFile(xmlfile,xslfile,results,,,helper)
		If $$$ISERR(sc) Set sc = $System.Status.GetErrorText(sc)
		If oldns '= namespace Set $Namespace = oldns
    } Catch {
		Set sc = $$$Text("Unexpected error occrurred in Transform: ") _ $ZE
    }
	Quit sc
}

/// Load helper class list per namespace selected.
Method LoadHelperClassList(Namespace) As %String [ ZenMethod ]
{
	Set oldns = $namespace
	If oldns '= Namespace Set $Namespace = Namespace
	Set valueList = ""
	Set clslist = ##class(%ResultSet).%New("%ClassDefinition:SubclassOf")
	Set sc = clslist.Execute("%XML.XSLT.CallbackHandler")
	While (clslist.Next()) {
		Set cls = clslist.Get("Name")
		Set:cls'="" valueList = valueList _ $S(valueList'="":",",1:"") _ cls
	}
	If oldns '= Namespace Set $Namespace = oldns
	Quit valueList
}

/// Validate file name: cannot be null, and must exists.
ClassMethod ValidateFile(FILE, FILETYPE) As %String [ ZenMethod ]
{
	If $ZStrip(FILE,"<>W") = "" Quit $$$FormatText($$$Text("Please enter a %1 file name."),FILETYPE)
	#; XML or XSLT File does not exist!"
	If '##class(%File).Exists(FILE) Quit $$$FormatText($$$Text("%1 file does not exist."),FILETYPE)
	Quit 1
}

}
