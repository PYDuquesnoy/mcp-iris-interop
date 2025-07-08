/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template.<br>
/// The XML Schema Wizard reads an XML schema and creates a set of corresponding classes.
Class %ZEN.Template.AddInWizard.XMLSchemaWizard Extends %ZEN.Template.AddInWizard.Template [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "XML Schema Wizard";

Parameter TEMPLATETITLE = "XML Schema Wizard";

Parameter TEMPLATETYPE = "cls";

Parameter TEMPLATEDESCRIPTION = "Creates class definitions from an XML Schema file.";

/// Display title of this page <title></title>
Parameter PAGETITLE = "XML Schema Wizard";

Parameter HELPID = "GXML_schema_wizard_ui";

/// Only display a preview of imports under 2Mb to prevent crashes
Parameter MAXPREVIEW = 2097152;

Property Multiple As %ZEN.Datatype.boolean;

/// Number of total Namespaces which is the same as total packages
Property TotalPackages As %ZEN.Datatype.integer;

/// String that contains package names delimited by comma.
Property Packages As %ZEN.Datatype.string;

Property lblSchemaFile As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Enter or select the path and name of a Schema File:")} ];

Property lblURL As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Enter a URL:")} ];

XData CSS3Style
{
<style type="text/css">
/* style for Namespace/Packages table */
table.NSTable		{ border: black solid 1px; font-size: 1.0em; }			 
table.NSTable td.Name { font-size: 0.8em; padding: 4px;}
tr.Header th	{ border-bottom: black solid 1px;
				text-align: left;
				color: white;
				background: rgb(91,164,220); 
				padding: 4px;
		  }
tr.DarkRow { background: #FFFFFF; }
tr.LightRow { background: #DDEEEE; }

/* style for Classes table */
span.filename { font-size: 0.8em; font-weight: bold; }
span.PropName { font-weight: bold; padding-left: 4px;}
span.PropType { font-weight: bold; color: #3b84bc; }
span.Description { font-size: 0.8em; color: green; }		 
span.IndexLabel { font-size: 0.7em; color: #3b84bc; }		 

div.Feedback { font-size: 0.8em; color: black; }

table.SchemaTable		{ border: black solid 1px; font-size: 1.0em; }

table.PropTable		{ font-size: 1.0em; }

th.Row	{ border-bottom: black solid 1px;
				text-align: left;
				background: rgb(91,164,220); color: white;
				padding: 4px;
		  }
table.SchemaTable th.Data	{ border-left: gray solid 1px; 
				border-bottom: black solid 1px;
				text-align: left;
				background: rgb(91,164,220); 
				color: white;
				padding: 4px;
		  }

td.Row 	{ border-bottom: black solid 1px; padding-right: 3px;}
table.SchemaTable td.Data 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding: 4px;
				font-size: 0.8em;
			}

td.Type 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding: 4px; font-size: 0.8em;
			}

td.Desc 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding: 4px;
				font-size: 0.8em;
			}

td.Prop 	{ border-left: gray solid 1px; border-bottom: black solid 1px;
			padding-left: 4px;
			}

td.PropCell1	{  
				padding: 4px;
				font-size: 0.8em;
			}

td.PropCell	{ border-top: gray solid 1px; 
				padding: 4px;
				font-size: 0.8em;
			}

td.PropCell1Error	{  
				background: red;
				padding: 4px;
				font-size: 0.8em;
			}

td.PropCellError	{ border-top: gray solid 1px; 
				background: red;
				padding: 4px;
				font-size: 0.8em;
			}

tr.DarkRowP { background: #DDFFFF; }
tr.LightRowP { background: #CCDDDD; }
tr.Preview { background: #FFFFFF; }

/* style for Out page */			 
div.CLASSMSG { font-size: 0.8em; border-top: black solid 1px; }
span.CLASSNAME { color: rgb(91,164,220); font-weight: bold; }
span.ERROR { color: #da4848; }
.sourceLabel {
	padding-right: 10px;
}
#iframePreview {
	background-color: white;
}
</style>
}

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for Namespace/Packages table */
table.NSTable		{ border: black solid 1px; font-size: 1.0em; }			 
table.NSTable td.Name { font-size: 0.8em; padding: 4px;}
tr.Header th	{ border-bottom: black solid 1px;
				text-align: left;
				color: white;
				background: rgb(91,164,220); 
				padding: 4px;
		  }
tr.DarkRow { background: #FFFFFF; }
tr.LightRow { background: #DDEEEE; }

/* style for Classes table */
span.filename { font-size: 0.8em; font-weight: bold; }
span.PropName { font-weight: bold; padding-left: 4px;}
span.PropType { font-weight: bold; color: #3b84bc; }
span.Description { font-size: 0.8em; color: green; }		 
span.IndexLabel { font-size: 0.7em; color: #3b84bc; }		 

div.Feedback { font-size: 0.8em; color: black; }

table.SchemaTable		{ border: black solid 1px; font-size: 1.0em; }

table.PropTable		{ font-size: 1.0em; }

th.Row	{ border-bottom: black solid 1px;
				text-align: left;
				background: rgb(91,164,220); color: white;
				padding: 4px;
		  }
table.SchemaTable th.Data	{ border-left: gray solid 1px; 
				border-bottom: black solid 1px;
				text-align: left;
				background: rgb(91,164,220); 
				color: white;
				padding: 4px;
		  }

td.Row 	{ border-bottom: black solid 1px; padding-right: 3px;}
table.SchemaTable td.Data 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding: 4px;
				font-size: 0.8em;
			}

td.Type 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding: 4px; font-size: 0.8em;
			}

td.Desc 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding: 4px;
				font-size: 0.8em;
			}

td.Prop 	{ border-left: gray solid 1px; border-bottom: black solid 1px;
			padding-left: 4px;
			}

td.PropCell1	{  
				padding: 4px;
				font-size: 0.8em;
			}

td.PropCell	{ border-top: gray solid 1px; 
				padding: 4px;
				font-size: 0.8em;
			}

td.PropCell1Error	{  
				background: red;
				padding: 4px;
				font-size: 0.8em;
			}

td.PropCellError	{ border-top: gray solid 1px; 
				background: red;
				padding: 4px;
				font-size: 0.8em;
			}

tr.DarkRowP { background: #DDFFFF; }
tr.LightRowP { background: #CCDDDD; }
tr.Preview { background: #FFFFFF; }

/* style for Out page */
div.CLASSMSG { font-size: 0.8em; border-top: black solid 1px; }
span.CLASSNAME { color: rgb(91,164,220); font-weight: bold; }
span.ERROR { color: #da4848; }
.sourceLabel {
	padding-right: 10px;
}
#iframePreview {
	background-color: white;
}
</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" cellStyle="padding-left:10px;">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<tabGroup id="tabGroup">

<!-- First Page -->
<tab id="tab1" enclosingStyle="padding:20px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="1"/>
 <radioSet id="FileType" label="Select a schema file or enter a URL:" labelClass="zenRequired" valueList="FILE,URL" displayList="Schema File,URL" value="FILE" captionClass="normal"
containerStyle="padding-bottom:4px;"
 onchange="zenPage.changedFileType(zenThis);"/>
 <group id="idFileName" label="Enter the path and name of a Schema File:" labelClass="zenRequired" cellVAlign="top" >
   <hgroup id="idSchema" cellVAlign="top">
  <text id="txtSchema" showLabel="false" size="80"
 value="" hint="Required." hintClass="helpText"/>
 <button id="btnBrowse" caption="Browse" onclick="zenPage.doBrowse();"/>
 </hgroup>
 <vgroup id="urlGroup" hidden="true">
  <text id="txtURL" showLabel="false" size="80" value="" hint="Required." hintClass="helpText"/>
  <select id="sslConfig" value="" valueList="" showEmpty="true" hint="SSL Configuration to use." hintClass="helpText" />
  </vgroup>
</group>
 <group containerStyle="padding-top:10px;" labelPosition="left">
<select id="lstRecentList" label="Recently Used URLs:" hidden="true" showEmpty="false"
onchange="zenPage.updateURL(zenThis.getValue());"/>
<select id="lstRecentListFile" label="Recently Used Files:" hidden="true" showEmpty="false"
onchange="zenPage.updateFile(zenThis.getValue());"/>
</group>
</tab>

<!-- Second Page -->
<tab id="tab2" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="2"/>
 <vgroup labelPosition="left">
 <label id="lblSchema" label="XML Schema:" labelClass="caption sourceLabel"/>
 </vgroup>
<vgroup containerStyle="padding:10px;" labelPosition="left">
<text id="SSLConfiguration" label="SSL Configuration name" hidden="true"/>
<checkbox id="KEEPEMPTY" caption="Keep Empty Classes" captionClass="normal" showLabel="false"/>
<checkbox id="NOARRAY" caption="Create No Array Properties" captionClass="normal" showLabel="false"/>
<checkbox id="XMLNIL" caption="Generate XMLNIL property parameter for nillable elements" captionClass="normal" showLabel="false"/>
<checkbox id="XMLNILNOOBJECT" caption="Generate XMLNILNOOBJECT property parameter for nillable elements" captionClass="normal" showLabel="false"/>
<iframe id="iframePreview" showLabel="false"/>
</vgroup>
</tab>

<!-- Third Page -->
<tab id="tab3" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="3"/>
<vgroup label="Options to control class generation and compilation:" labelClass="caption" labelPosition="left">
<checkbox id="COMPILE" caption="Compile generated classes" captionClass="normal" showLabel="false"
containerStyle="padding-top:10px;padding-bottom:10px;"/>
<checkbox id="NAMESPACE" caption="Add NAMESPACE Class Parameter" captionClass="normal" showLabel="false" value="0"/>
<checkbox id="PERSISTENT" caption="Create Persistent Classes" captionClass="normal" value="1" onclick="zenPage.changePersistent(zenThis.getValue());"/>
<vgroup id="idPersistent">
<checkbox id="RELATIONSHIPS" caption="Use Relationships for Collection Properties in Persistent Classes" captionClass="normal" value="1"
containerStyle="padding-left:20px;"/>
<checkbox id="INDEXRELATIONSHIPS" caption="Add index to many-one relationship" captionClass="normal" value="0" containerStyle="padding-left:40px;"/>
<checkbox id="PARENTCHILDRELATIONSHIPS" caption="Use parent-child relationship" captionClass="normal" value="0" containerStyle="padding-left:40px;"/>
<checkbox id="CASCADEDELETES" caption="Add delete trigger to classes in order to cascade deletes" captionClass="normal" value="0" containerStyle="padding-left:40px;"/>
<radioSet id="IDENTITY" label="Identity Property:" labelStyle="width:200px;" valueList="none,id,oid,guid" displayList="None,Use Id,Use Oid,UseGUID" value="none"
containerStyle="padding-left:20px;"/>
</vgroup>
</vgroup>
<html id="htmlNS" OnDrawContent="DrawNS" seed="" onrefresh="zenPage.drawDone(3);"/>
<label id="idProgress3" label="Finding Namespaces..." labelClass="progress" hidden="true"/>
</tab>

<!-- Fouth Page -->
<tab id="tab4" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;" layout="none">
 <html OnDrawContent="DrawPageTitle" seed="4"/>
 <vgroup labelPosition="left">
 <label id="lblSchema4" label="XML Schema: " labelClass="caption"/>
 </vgroup>
<hgroup labelPosition="left" cellStyle="padding-right:2px;">
<checkbox id="JAVA" label="Features:" labelClass="caption" caption="Java Enabled" captionClass="normal"
 containerStyle="padding-top:10px;padding-bottom:10px;"/>
<checkbox id="POPULATE" caption="Data Population" captionClass="normal"/>
<checkbox id="SQLCOLUMNS" caption="SQL Column Order" captionClass="normal"/>
<checkbox id="NOSEQUENCE" caption="No Sequence Check" captionClass="normal"/>
<checkbox id="IGNORENULL" caption="XML Ignore Null" captionClass="normal"/>
<checkbox id="BINARYASSTREAM" caption="Use Streams for Binary" captionClass="normal"/>
</hgroup>
<html id="htmlClasses" OnDrawContent="DrawClasses" seed="" onrefresh="zenPage.drawDone(4);"/>
<label id="idProgress4" label="Processing Schema..." labelClass="progress" hidden="true"/>
</tab>

<!-- Fifth Page -->
<tab id="tab5" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="5"/>
<vgroup labelPosition="top" containerStyle="padding:20px;" label="" labelClass="caption">
<html id="htmlSaving" OnDrawContent="DrawSaving" seed=""/>
</vgroup>
</tab>
</tabGroup>
</pane>
}

/// User changed file type. Change label. Show local FILENAME if it is a local server. OW show filename and browse button.
ClientMethod changedFileType(thisObj) [ Language = javascript ]
{
	var type = thisObj.getValue();
	var hasText = 0;
	if (type == "FILE") {
		var idName = this.lblSchemaFile;
		zen("urlGroup").setHidden(true);
		zen("idSchema").setHidden(false);
		zen("txtSchema").focus();
		zen("lstRecentList").setHidden(true);
		var recent = zen("lstRecentListFile");		
	} else {
		var idName = this.lblURL;
		zen("idSchema").setHidden(true);
		zen("urlGroup").setHidden(false);
		zen("txtURL").focus();
		zen("lstRecentListFile").setHidden(true);
		var recent = zen("lstRecentList");
	}
	if (recent.getProperty("valueList") != "") recent.setHidden(false);
	zen("idFileName").setProperty("label",idName);
}

/// Launching a file selector window. 
ClientMethod doBrowse() [ Language = javascript ]
{
	var Dir = zen("txtSchema").getValue();
	var wildcard = "*.xsd";
	var url = "%ZEN.Dialog.fileSelect.cls?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=0&CSPCHD=" + this.CSPSessionCookie + "&CSPSHARE=1"
	zenLaunchPopupWindow(url,'FileSelection','status,scrollbars,resizable,width=800,height=800');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen("txtSchema").setValue(value);
		zenPage.updateState();	
	}
}

ClientMethod changePersistent(flag) [ Language = javascript ]
{
	zen("idPersistent").setHidden(!flag);
}

/// Load the recently used url into textbox
ClientMethod updateURL(url) [ Language = javascript ]
{
	zen("txtURL").setValue(url);
}

/// Load the recently used file into textbox
ClientMethod updateFile(file) [ Language = javascript ]
{
	zen("txtSchema").setValue(file);
}

/// Load the recent list. Set last file type so that onstartHandler can hide/show fields appropriately.
Method %OnAfterCreatePage() As %Status
{
	Set ..%GetComponentById("sslConfig").valueList = $$ListSSLConfigs^%SYS.SECURITY("Client")
	For filetype = "URL","FILE" {
		Set valueList = ..GetRecentList(filetype)
		If valueList '= "" {
			Set tComboId = $select(filetype = "URL": "lstRecentList", 1: "lstRecentListFile")
			Set tCombo = ..%GetComponentById(tComboId)
			Set tCombo.valueList = valueList
			Set tLastURI = $G(^ISC.XMLSchemaWizard($Username,"Last",filetype))
			Set tCombo.value = tLastURI
			If (filetype = "URL") {
				Do ..%SetValueById("txtURL",tLastURI)
				Set tLastSSL = $get(^ISC.XMLSchemaWizard($Username,"Recent",filetype,tLastURI,"SSLConfig"))
				Do ..%SetValueById("sslConfig",tLastSSL)
			}
			ElseIf (filetype = "FILE") {
				Do ..%SetValueById("txtSchema",tLastURI)
			}
		}		
	}
	#; Default file type: The last one selected. If none, then FILE.
	Set LastFileType = $G(^ISC.XMLSchemaWizard($Username,"Last"),"FILE")
	Set ..%GetComponentById("FileType").value = LastFileType
	
	Quit $$$OK
}

/// Get recent list for URLs or Files. filetype = "FILE" or "URL".
ClassMethod GetRecentList(filetype) As %String [ ZenMethod ]
{
	Set valueList = ""
	Set tRecent = $order(^ISC.XMLSchemaWizard($Username,"Recent",filetype,""))
	While (tRecent '= "") {
		Set valueList = valueList_$S(valueList'="":",",1:"")_tRecent
		Set tRecent = $order(^ISC.XMLSchemaWizard($Username,"Recent",filetype,tRecent))
	}
	Quit valueList
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = false;
	switch(tabNo) {
	case 1:
		flag = true;
		break;
	case 2:
		flag = true;
		break;
	case 3:
		flag = true;
		break;
	case 4:
		flag = true;
		break;
	case 5:
		//flag = true;
		break;

	}
	return flag;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		flag = false;
		break;
	case 2:
		break;
	case 3:
		break;
	case 4:
		break;
	case 5:
		flag = false;
		break;

	}	
	return flag
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
ClientMethod canFinish() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = false;
	switch(tabNo) {
	case 1:
		break;
	case 2:
		break;
	case 3:
		break;
	case 4:
		break;
	case 5:
		var flag = true;
		break;
	}	
	zen("btnCancel").setDisabled(false);	
	
	return flag;
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	this.changedFileType(zen("FileType"));
	this.onresizeHandler();
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var isfile = zen("FileType").getValue();
	var fileName = zen("txtSchema").getValue();
	var url = zen("txtURL").getValue();
	var proxy = new zenProxy();
	var sslConfig = zen("sslConfig").getValue();
	var isHTTPS = false;
	switch(tabNo) {
	case 1:
		if (isfile == "FILE") {
			fileName = zenTrim(fileName);
			zen("txtSchema").setValue(fileName);
			if (fileName == '') {
				this.showMsg($$$Text("Please select an XML Schema file."));
				zen("txtSchema").focus();
				return false;
			} else {
				if (!this.FileExists(fileName)) {
					this.showMsg($$$Text("Unable to find this file: ") + fileName);
					zen("txtSchema").focus();
 					return false;
				}	
			}
		} else {
			fileName = url;
			fileName = zenTrim(fileName);
			zen("txtURL").setValue(fileName);
			if (fileName == '') {
				this.showMsg($$$Text("Please enter the URL of an XML Schema."));
				zen("txtURL").focus();
				return false;
			}
			if (url.toLowerCase().substring(0,8) == "https://") {
				isHTTPS = true;
				if (sslConfig == '') {
					this.showMsg($$$Text("Please enter an SSL Configuration for the current HTTPS URL."));
					zen("sslConfig").focus();
					return false;
				}
			}
		}
		this.resetMsg();
		zen("lblSchema").setValue(fileName);

		if (isHTTPS) {
			zen("SSLConfiguration").setValue(sslConfig);
			zen("SSLConfiguration").setHidden(false);
		}
		else {
			zen("SSLConfiguration").setHidden(true);
		}
		var isrc = this.GetSRC(isfile,fileName,sslConfig);
		var iframe = zen("iframePreview");
		iframe.setHidden(false);
		iframe.setProperty("src",isrc);
		tabGroup.showNextTab();
		break;
	case 2:
		var ssl = (isfile == "URL") ? zen("SSLConfiguration").getValue() : "";
		var keepempty = (zen("KEEPEMPTY").getValue() == true) ? 1 : 0;
		var noarray = (zen("NOARRAY").getValue() == true) ? 1 : 0;
		var xmlnil = (zen("XMLNIL").getValue() == true) ? 1 : 0;
		var xmlnilnoobject = (zen("XMLNILNOOBJECT").getValue() == true) ? 1 : 0;
		if (isfile == "FILE") url = "";
		else fileName = "";
		proxy.filename = fileName;
		proxy.url = url;
		proxy.ssl = ssl;
		proxy.keepempty = keepempty;
		proxy.noarray = noarray;
		proxy.xmlnil = xmlnil;
		proxy.xmlnilnoobject = xmlnilnoobject;
		var multiple = this.PreProcess(proxy);
		if (multiple == 1) {
			// if it is multiple, set NAMESPACE to be checked and disable the checkbox so user cannot modify
			zen("NAMESPACE").setValue(1);
			zen("NAMESPACE").setDisabled(true);
		} else {
			// if error then show error and quit
			if (multiple.length > 1) {
				this.showMsg(multiple);
				break;
			}		
		}
		tabGroup.showNextTab();
		var html = zen("htmlNS");
		// use setProperty('seed') here so that if seed is identical to the previous one it won't reload.
		html.setProperty('seed',proxy);
		zen("idProgress3").setHidden(false);
		break;
	case 3:
		this.resetMsg();
		var packages = this.getPackages();
		if (packages == 0) return;
		this.Packages = packages;
		proxy.ssl = (isfile == "URL") ? zen("SSLConfiguration").getValue() : "";
		proxy.keepempty = (zen("KEEPEMPTY").getValue() == true) ? 1 : 0;
		proxy.noarray = (zen("NOARRAY").getValue() == true) ? 1 : 0;
		proxy.xmlnil = (zen("XMLNIL").getValue() == true) ? 1 : 0;
		proxy.xmlnilnoobject = (zen("XMLNILNOOBJECT").getValue() == true) ? 1 : 0;
		if (isfile == "FILE") url = "";
		else fileName = "";
		proxy.url = url;
		proxy.filename = fileName;
		proxy.defpkg = "";
		if (document.getElementById("DEFAULTPKG")) proxy.defpkg = document.getElementById("DEFAULTPKG").value;
		proxy.relationships = (zen("RELATIONSHIPS").getValue()) ? 1 : 0;
		proxy.parentchildrelationships = (zen("PARENTCHILDRELATIONSHIPS").getValue()) ? 1 : 0;
		proxy.indexrelationships = (zen("INDEXRELATIONSHIPS").getValue()) ? 1 : 0;
		proxy.CascadeDeletes = (zen("CASCADEDELETES").getValue()) ? 1 : 0;
		proxy.persistent = (zen("PERSISTENT").getValue()) ? 1 : 0;
		proxy.identity = zen("IDENTITY").getValue();
		if (proxy.identity == "none") proxy.identify = "";
		proxy.namespace = (zen("NAMESPACE").getValue()) ? 1 : 0;
		proxy.compile = (zen("COMPILE").getValue()) ? 1 : 0;
		zen("idProgress4").setHidden(false);
		tabGroup.showNextTab();
		var html = zen("htmlClasses");
		// use setProperty('seed') here so that if seed is identical to the previous one it won't reload.
		html.setProperty('seed',proxy);
		if (isfile == "URL") fileName = url;
		zen("lblSchema4").setValue(fileName);
		break;
	case 4:
		proxy.defpkg = "";
		if (document.getElementById("DEFAULTPKG")) proxy.defpkg = document.getElementById("DEFAULTPKG").value;
		proxy.CascadeDeletes = (zen("CASCADEDELETES").getValue()) ? 1 : 0;
		proxy.identity = zen("IDENTITY").getValue();
		if (proxy.identity == "none") proxy.identify = "";
		proxy.java = (zen("JAVA").getValue()) ? 1 : 0;
		proxy.populate = (zen("POPULATE").getValue()) ? 1 : 0;
		proxy.sqlcolumns = (zen("SQLCOLUMNS").getValue()) ? 1 : 0;
		proxy.nosequence = (zen("NOSEQUENCE").getValue()) ? 1 : 0;
		proxy.ignorenull = (zen("IGNORENULL").getValue()) ? 1 : 0;
		proxy.binaryasstream = (zen("BINARYASSTREAM").getValue()) ? 1 : 0;	
		proxy.compile = (zen("COMPILE").getValue()) ? 1 : 0;
		// Get values from radio buttons and checkboxes
		proxy.TypeValues = this.getTypeValues();
		tabGroup.showNextTab();	
		var html = zen("htmlSaving");
		// use setProperty('seed') here so that if seed is identical to the previous one it won't reload.see YSD2132
		html.setProperty('seed',proxy);
		//html.seed = proxy;
		//html.refreshContents();
		break;
	}
	zenPage.updateState();
}

/// Validate and return packages string. If a package name is empty, display message and return 0.
ClientMethod getPackages() [ Language = javascript ]
{
	if (document.getElementById("DEFAULTPKG")) {
		var defpkg = zenTrim(document.getElementById("DEFAULTPKG").value);
		if (defpkg == "" ) {
			alert($$$Text("Please provide a default package name."));
			return 0;
		}
	}
	var len = this.TotalPackages;
	var packages = "";
	var rowid;
	var item;
	for (var i=1; i<len; i++) {
		rowid = "row" + i;
		item = document.getElementById(rowid).value;

		/// strip off surrounding write spaces
		if (document.getElementById(rowid).type != "hidden") {
			item = zenTrim(item);
			if (item == "") {
				this.showMsg($$$Text("Please provide a package name for every namespace."));
				packages = 0;
				break;
			}
		}
		packages = packages + item + ",";
	}
	return packages;
}

/// Go through the Type values (radio buttons) for all classes
ClientMethod getTypeValues() [ Language = javascript ]
{
	var idrow;
	var typeName;
	var typeValue;
	var IndexValues;
	var TypeValues = "";
	var TotalClasses = document.getElementById("TotalClasses").value;
	for (var n=1; n<=TotalClasses; n++) {
		typeName = "";
		typeValue = "";
		for (var m=1; m<4; m++) {
			idrow = "radio_" + n + "_" + m;
			if (document.getElementById(idrow)) {
				if (document.getElementById(idrow).checked) {
					typeName = document.getElementById(idrow).name;
					typeValue = document.getElementById(idrow).value;
				}
			}
		}
		IndexValues = this.getIndexValues(n);
		TypeValues = TypeValues + typeName + "#" + typeValue + "#" + IndexValues + "^";
	}
	return TypeValues;
}

/// Go through the Index values (checkboxes) for each class. Return index names that are checked.
ClientMethod getIndexValues(n) [ Language = javascript ]
{
	var indexName;
	var IndexValues = "";
	var m = 1;
	var idi = "check_"+n+"_"+m;
	while (document.getElementById(idi)) {
		if (document.getElementById(idi).checked) {
			indexName = document.getElementById(idi).name;
			IndexValues = IndexValues + indexName + ",";
		}
		m++;
		idi = "check_"+n+"_"+m;
	}
	return IndexValues;
}

/// Go to the previous page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
	this.resetMsg();	
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	switch(tabNo) {
	case 1:
		break;
	case 2:
		tabGroup.showPreviousTab();
		break;
	case 3:
		tabGroup.showPreviousTab();
		break;
	case 4:
		tabGroup.showPreviousTab();
		break;
	case 5:
		tabGroup.showPreviousTab();
		break;
	}
	zenPage.updateState();
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = ""
	If pSeed = 1 {
		Set tPageTitle = $$$Text("The XML Schema Wizard reads an XML schema and creates a set of corresponding classes.")_"<br><br>"_
		$$$Text("To start, select an XML Schema from either a file (using the <span class='guibutton'>Browse</span> button) or via a URL and then press <span class='guibutton'>Next</span>.")
	} ElseIf pSeed = 2 {
		Set tPageTitle = $$$Text("The source for your schema is displayed below. If it is correct press <span class='guibutton'>Next</span>.")
	} ElseIf pSeed = 3 {
		Set tPageTitle = $$$Text("The XML Schema Wizard has determined that that your schema uses the following XML namespaces.")_"<br><br>"_
		$$$Text("The Wizard will generate all the classes for an XML namespace within the same class package. You can specify the package name used for each XML namespace using the fields below.")_
		"&nbsp;"_$$$Text("Afterwards, press <span class='guibutton'>Next</span>.")
	} ElseIf pSeed = 4 {
		Set tPageTitle = $$$Text("The XML Schema Wizard has determined that that the following classes should be created from your schema.")_"<br><br>"_ 
		$$$Text("If you wish to generate these classes press <span class='guibutton'>Next</span>.")
	} ElseIf pSeed = 5 {
		Set tPageTitle = $$$Text("The XML Schema Wizard is saving the new class definitions to the database")_"<br>"_
		$$$Text("Press the <span class='guibutton'>Finish</span> button when saving is complete.")
	}
	Set tStep = ""
	Set:pSeed>1 tStep = $$$FormatText($$$Text("Step %1"),pSeed)_" - "
	&html<<div class="Description">#(tStep)##(tPageTitle)#
	</div><hr>>
	Quit $$$OK
}

/// This method is fired up after onDrawContent is finished. Hide progress message and display error if exists.
ClientMethod drawDone(tab) [ Language = javascript ]
{
	var result = this.GetStatus(tab);
	if (result.Status == "Done") {
		if (result.Error != "") {
			this.showMsg(result.Error);
		}
		var id = "idProgress"+tab;
		zen(id).setHidden(true);
	} 
	else {
		var error = $$$Text("Unexpected error occurred. Loading did not finish as expected.");
		this.showMsg(error);
	}
}

/// Given the source and filename, load the file.
/// Save the source and filename to %session.Data.
ClassMethod GetSRC(filetype As %String, filename As %String, sslConfig As %String = "") As %String [ ZenMethod ]
{
	If ($Get(%session.Data("schemaid")) '= "") {
		Do ##class(%XML.Utils.SchemaReader).Delete(%session.Data("schemaid"))
	}

	Do ..SaveLast(filetype, filename, sslConfig)

 	// Use schema server for all URLs
 	Set isrc = "_XML.Utils.SchemaServer.cls?"
 	If (filetype = "FILE") {
	 	Set isrc = isrc _ "FILE=" _ ..Encrypt($zcvt(filename,"O","UTF8"))
 	} Else {
	 	Set isrc = isrc _ "URL=" _ ..Encrypt($zcvt(filename,"O","UTF8"))
	 	If (sslConfig '= "") Set isrc = isrc _ "&SSLCONFIG=" _ ..Encrypt($zconvert(sslConfig,"O","UTF8"))
 	}
 	Set isrc = isrc _ "&MAXPREVIEW=" _ ..Encrypt(..#MAXPREVIEW)
	Quit isrc
}

/// FileType is either "FILE" or "URL".
ClassMethod SaveLast(filetype, url, sslConfig = "") As %Boolean [ ZenMethod ]
{
	// remember settings 
	Set ^ISC.XMLSchemaWizard($Username,"Last") = filetype
	Set ^ISC.XMLSchemaWizard($Username,"Last",filetype) = url
	Set ^ISC.XMLSchemaWizard($Username,"Recent",filetype,url) = $zdt($h,3)
	If (filetype = "URL") && (sslConfig '= "") Set ^ISC.XMLSchemaWizard($Username,"Recent",filetype,url,"SSLConfig") = sslConfig
 
	// clean up recent URL list
	// sort list by time, delete oldest...
	Set tCount = 0
	Set tRecent = $order(^ISC.XMLSchemaWizard($Username,"Recent",filetype,""))
	While (tRecent '= "") {
		Set tCount = tCount + 1
		Set tSort(^ISC.XMLSchemaWizard($Username,"Recent",filetype,tRecent)) = tRecent
		Set tRecent = $order(^ISC.XMLSchemaWizard($Username,"Recent",filetype,tRecent))
	}
	
	// remove oldest items (there are up to 10)
	While (tCount > 10) {
		Set tOld = $order(tSort(""))
		Kill ^ISC.XMLSchemaWizard($Username,"Recent",filetype,tSort(tOld))
		Set tCount = tCount - 1
	}
}

/// Check if file exists
ClassMethod FileExists(filename) As %Boolean [ ZenMethod ]
{
	Quit ##class(%File).Exists(filename)
}

/// For page 3, do preprocess to find out whether it is multiple
ClassMethod PreProcess(proxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set filename = proxy.filename
	Set url = proxy.url
	Set ssl = proxy.ssl
	Set keepempty = proxy.keepempty
	Set noarray = proxy.noarray
	Set xmlnil = proxy.xmlnil
	Set xmlnilnoobject = proxy.xmlnilnoobject
	Set schemaid = ""
	Set error = ""
	If ($get(%session.Data("schemaid")) '= "") {
		Do ##class(%XML.Utils.SchemaReader).Delete(%session.Data("schemaid"))
		Set schemaid = ""
 	}
 	
 	Set multiple = 0
 	If (url = "") {
		If ('##class(%File).Exists(filename)) {
			Set multiple = $$$Text("Unable to find Schema File.")
 		}
 		Else {
	 		Set reader = ##class(%XML.Utils.SchemaReader).%New()
			Set reader.KeepEmptyClasses = keepempty
			Set reader.NoArrayProperties = noarray
			Set reader.GenerateXMLNIL = xmlnil
			Set reader.GenerateXMLNILNOOBJECT = xmlnilnoobject

 			// we should use a Mime post but built-in server does not work!
	 		Set sc=reader.PreParseSchema(filename,,.multiple,.noSchema)
			If $$$ISERR(sc) {
				Do $System.Status.DecomposeStatus(sc,.err)
				Set multiple = err(1)
			} ElseIf noSchema {
				Set multiple = "No schema definition was found in specified file."
			}
 		}
 	}
 	Else {
	 	// use URL
 		Set reader = ##class(%XML.Utils.SchemaReader).%New()
 		Set reader.SSLConfiguration = ssl
		Set reader.KeepEmptyClasses = keepempty
		Set reader.NoArrayProperties = noarray
		Set reader.GenerateXMLNIL = xmlnil
		Set reader.GenerateXMLNILNOOBJECT = xmlnilnoobject

 		Set sc=reader.PreParseSchema(filename,url,.multiple,.noSchema)
		If $$$ISERR(sc) {
			Do $System.Status.DecomposeStatus(sc,.err)
			Set multiple = err(1)
		} ElseIf noSchema {
			Set multiple = "No schema definition was found in specified file."
		}
 	}
	Kill reader
	Quit multiple
}

/// Draw page 3, namespaces
ClassMethod DrawNS(proxy As %ZEN.proxyObject) As %Status
{
 
	Set tSC = $$$OK
	Quit:proxy="" tSC
	Set ^ISC.XMLSchemaWizard($Username,"Status") = ""
	Set ^ISC.XMLSchemaWizard($Username,"Error") = ""
	Set filename = proxy.filename
	Set url = proxy.url
	Set ssl = proxy.ssl
	Set keepempty = proxy.keepempty
	Set noarray = proxy.noarray
	Set xmlnil = proxy.xmlnil
	Set xmlnilnoobject = proxy.xmlnilnoobject
	Set schemaid = ""
	Set error = ""
	If ($get(%session.Data("schemaid")) '= "") {
		Do ##class(%XML.Utils.SchemaReader).Delete(%session.Data("schemaid"))
		Set schemaid = ""
 	}
 	
 	Set multiple = 0
 	
 	If (url = "") {
		If ('##class(%File).Exists(filename)) {
			Set error = $$$Text("Unable to find Schema File.")
 		}
 		Else {
	 		Set reader = ##class(%XML.Utils.SchemaReader).%New()
			Set reader.KeepEmptyClasses = keepempty
			Set reader.NoArrayProperties = noarray
			Set reader.GenerateXMLNIL = xmlnil
			Set reader.GenerateXMLNILNOOBJECT = xmlnilnoobject

 			// we should use a Mime post but built-in server does not work!
	 		Set sc=reader.PreParseSchema(filename,,.multiple,.noSchema)
			If $$$ISERR(sc) {
				Do $System.Status.DecomposeStatus(sc,.err)
				Set error = err(1)
			} ElseIf noSchema {
				Set error = "No schema definition was found in specified file."
			}

		 	// Save the schema info for later use
	 		Set schemaid = $select(error="":reader.Save(),1:"")
 		}
 	}
 	Else {
	 	// use URL
 		Set reader = ##class(%XML.Utils.SchemaReader).%New()
 		Set reader.SSLConfiguration = ssl
		Set reader.KeepEmptyClasses = keepempty
		Set reader.NoArrayProperties = noarray
		Set reader.GenerateXMLNIL = xmlnil
		Set reader.GenerateXMLNILNOOBJECT = xmlnilnoobject

 		Set sc=reader.PreParseSchema(filename,url,.multiple,.noSchema)
		If $$$ISERR(sc) {
			Do $System.Status.DecomposeStatus(sc,.err)
			Set error = err(1)
		} ElseIf noSchema {
			Set error = "No schema definition was found in specified file."
		}

	 	// Save the schema info for later use
 		Set schemaid = $select(error="":reader.Save(),1:"")
 	}
	Set %session.Data("schemaid") = schemaid
	Set ^ISC.XMLSchemaWizard($Username,"schemaid")=schemaid
	
	Set th1 = $$$Text("XML Namespace")
	Set th2 = $$$Text("Package Name")

	&html<<table class="NSTable" cellspacing="2" cellpadding="5">
		<tr class="Header">
		<th>#(th1)#</th>
		<th>#(th2)#</th>
		</tr>>
	
	// find out if we need to get a Default Package name...
	// this is only if there is no explicit default namespace
	Set hasDefault = 0
	Set n = $order(reader.NSInfo(""))
	While (n '= "") {
		Set pkg = $get(reader.NSInfo(n,"Package"))
		If (pkg = "$defaultNS") {
			Set hasDefault = 1
			Quit
		}
		
		Set n = $order(reader.NSInfo(n))
	}
	
	// list the namespaces found by the reader
	Set n = $order(reader.NSInfo(""))
	Set row = 1
	While (n '= "") {
		Set uri = $get(reader.NSInfo(n,"uri"))
		Set pkg = $get(reader.NSInfo(n,"Package"))
		Set label = uri
		Set ctrl = "NSINFO"
		
		If (uri = "$defaultNS") {
			If ('hasDefault) {
				// special case for default NS
				Set label = $$$Text("Default Namespace")
				Set ctrl = "DEFNS"
			}
		}
		
		If (pkg = "$defaultNS") {
			// use default name
			Set pkg = $get(^JSchema.LastPackage)
		}
		
		// special check for WSDL namespace
		If ((uri [ "schemas.xmlsoap.org/wsdl/") && (pkg = "")) {
			Set pkg = "wsdl"
		}

		Set rowid = "row"_row
		
		If (##class(%XML.Utils.SchemaReader).IsXMLSchemaNS(uri)) {
			// skip the XML schema namespace... (place holder)
			&html<<tr><td><input type="hidden" id="#(rowid)#" name="NSINFO" value=""></td><td></td></tr>>
		}
		Else {
			If (hasDefault && (ctrl = "DEFNS")) {
				// skip this
			}
			Else {
				&html<<tr class="#($select((row#2=0):"DarkRow",1:"LightRow"))#">
				<td class="Name">#(label)#</td>
				<td class="Name"><input type="text" name="#(ctrl)#" id="#(rowid)#" value="#(pkg)#">
				</td>
				</tr>>
			}
		}
		Set n = $order(reader.NSInfo(n))
		Set row = row + 1
	}
		If (reader.TargetNS = "") {
			// there is no namespace info: show a dummy one
			&html<<tr class="#($select((row#2=0):"DarkRow",1:"LightRow"))#">
			<td class="Name"><i>#($$$Text("This schema has no targetNamespace"))#.</i></td>
			<td class="Name"><input type="text" id="DEFAULTPKG" name="DEFAULTPKG" value="MyPackage">
			</td>
			</tr>>
		}
	&html<</table>>
	Set %page.TotalPackages = row
	Set ^ISC.XMLSchemaWizard($Username,"Error") = error
	Set ^ISC.XMLSchemaWizard($Username,"Status") = "Done"
	Quit tSC
}

/// tab = 3: NS - when DrawNS is finished, Status is "Done".
/// tab = 4: Classes - when DrawClasses is finished, Status is "Done".
ClassMethod GetStatus(tab) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.Status = $G(^ISC.XMLSchemaWizard($Username,"Status"))
	Set proxy.Error = $G(^ISC.XMLSchemaWizard($Username,"Error"))
	Quit proxy
}

/// Draw page 4, Classes
ClassMethod DrawClasses(proxy As %ZEN.proxyObject) As %Status
{
 
	Set tSC = $$$OK
	Quit:proxy="" tSC
	
	Set ^ISC.XMLSchemaWizard($Username,"Status") = ""
	Set ^ISC.XMLSchemaWizard($Username,"Error") = ""
	Set error = ""
	Set filename = proxy.filename
	Set url = proxy.url
	Set ssl = proxy.ssl
	Set keepempty = proxy.keepempty
	Set noarray = proxy.noarray
	Set xmlnil = proxy.xmlnil
	Set xmlnilnoobject = proxy.xmlnilnoobject
	Set defpkg = proxy.defpkg
	Set relationships = proxy.relationships
	Set parentchildrelationships = proxy.parentchildrelationships
	Set indexrelationships = proxy.indexrelationships
	Set CascadeDeletes = proxy.CascadeDeletes
	Set persistent = proxy.persistent
	Set identity = proxy.identity
	Set namespace = proxy.namespace
	Set compile = proxy.compile

	Set schemaid = $G(%session.Data("schemaid"))
	Set TotalPackages = %page.TotalPackages
	Set Packages = %page.Packages
	If (schemaid '= "") {
		// open existing schema
		Set reader = ##class(%XML.Utils.SchemaReader).Open(schemaid)
 		Set reader.SSLConfiguration = ssl
		
		// test if we have to update package/ns info
		For n = 1:1:TotalPackages {
			Set item = $P(Packages,",",n)
			If item '= "" {
				If ($get(reader.NSInfo(n,"Package")) '=	item) {
					Set reader.NSInfo(n,"Package") = item
				}
			}
		}
			
		// reparse schema using new NSInfo
		Do reader.Reset()
			
		// get package for targetNS
		Set reader.DefaultPackage = defpkg
		Set reader.MakePersistent = persistent
		Set reader.MakeRelationships = relationships
		Set reader.ParentChildRelationship = parentchildrelationships
		Set reader.IndexRelationship = indexrelationships
		Set reader.CascadeDeletes = CascadeDeletes
		Set reader.AddIdentity = identity
		Set reader.MakeNamespace = namespace
		Set reader.KeepEmptyClasses = keepempty
		Set reader.NoArrayProperties = noarray
		Set reader.GenerateXMLNIL = xmlnil
		Set reader.GenerateXMLNILNOOBJECT = xmlnilnoobject
		Set tSC = reader.ParseSchema(filename,url)
		If $$$ISERR(tSC) {
			Do $System.Status.DecomposeStatus(tSC,.err)
			Set error = err(1)
		}
		Set schemaid = reader.Save()
	}
	Else {
		If ((url="") && ('##class(%File).Exists(filename))) {
			Set error = "Unable to find Schema File."
		}
		Else {
	 		Set reader = ##class(%XML.Utils.SchemaReader).%New()
	 		Set reader.SSLConfiguration = ssl
			Set reader.MakePersistent = persistent
			Set reader.MakeRelationships = relationships
			Set reader.ParentChildRelationship = parentchildrelationships
			Set reader.IndexRelationship = indexrelationships
			Set reader.CascadeDeletes = CascadeDeletes
			Set reader.AddIdentity = identity
			Set reader.MakeNamespace = namespace
			Set reader.KeepEmptyClasses = keepempty
			Set reader.NoArrayProperties = noarray
			Set reader.GenerateXMLNIL = xmlnil
			Set reader.GenerateXMLNILNOOBJECT = xmlnilnoobject
	
			// we should use a Mime post but built-in server does not work!
			Set tSC = reader.ParseSchema(filename,url)	 		
			If $$$ISERR(tSC) {
				Do $System.Status.DecomposeStatus(tSC,.err)
				Set error = err(1)
			}
		}
	
		// Save the schema info for later use
		Set schemaid = reader.Save()
	}

	Set %session.Data("schemaid") = schemaid
	Set ^ISC.XMLSchemaWizard($Username,"schemaid") = schemaid
	If (error '= "") {
		 &html<<div>#(error)#</div>>
	}
	Else {
		// display Class info
	
		// Create a results object and use it for display
		Set tSC = $$$OK
		Do {
			Set tResult = ##class(%XML.Utils.SchemaResult).CreateResult(reader,defpkg)
			If '$IsObject(tResult) {
				Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("Unable to create Schema Result."))
				Quit
			}
	
			Set tSC = tResult.DisplayClassesHTML()
			If $$$ISERR(tSC) Quit

		} While (0)
	
		If ($$$ISERR(tSC)) {
		 &html<<pre>>
		 Do $System.Status.DisplayError(tSC)
		 &html<</pre>>
		}
	 }
	Set ^ISC.XMLSchemaWizard($Username,"Error") = error
	Set ^ISC.XMLSchemaWizard($Username,"Status") = "Done"	 
	Quit tSC
}

/// Draw page 5, Saving Classes
ClassMethod DrawSaving(proxy As %ZEN.proxyObject) As %Status
{
	Set tSC = $$$OK	
	Quit:proxy="" tSC
	Try {
		Set error = ""
		//Set filename = proxy.filename
		//Set url = proxy.url
		//Set ssl = proxy.ssl
		Set identity = proxy.identity
		Set defpkg = proxy.defpkg
		Set java = proxy.java
		Set populate = proxy.populate
		Set sqlcolumns = proxy.sqlcolumns
		Set nosequence = proxy.nosequence
		Set ignorenull = proxy.ignorenull
		Set binaryasstream = proxy.binaryasstream
		Set compile = proxy.compile
		Set TypeValues = proxy.TypeValues
		Set CascadeDeletes = proxy.CascadeDeletes
		
		Set schemaid = $G(%session.Data("schemaid"))
		If schemaid = "" Set schemaid = $G(^ISC.XMLSchemaWizard($Username,"schemaid"))
		Set reader = ##class(%XML.Utils.SchemaReader).Open(schemaid)
		If ($IsObject(reader)) {
	 		
			 Set reader.AddIdentity = identity
			 Set reader.CascadeDeletes=CascadeDeletes
			 
			 // update class types from checkboxes...
			 // also look for indexed fields
			 Set row = 1
			 Set key = $piece(TypeValues,"^",row)
			 While (key '= "") {
				Set typeName = $piece(key,"#",1)
 				Set cls = $piece(typeName,"_",2)
 				Set type = $piece(key,"#",2)
				If ((cls '= "") && (type '= "")) {
					Do reader.WizardSetClassType(cls,type)
				}
				Set indexValues = $piece(key,"#",3)
				For n = 1:1:$L(indexValues,",") {
					Set indexkey = $piece(indexValues,",",n)
					If ($piece(indexkey,"_",1) = "INDEX") {
						Set cls = $piece(indexkey,"_",2)
						Set pname = $piece(indexkey,"_",3)
						If ((cls '= "") && (pname '= "")) {
							Do reader.WizardAddIndex(cls,pname)
			 			}
					}
				}		 
				Set row = row + 1
			 	Set key = $P(TypeValues,"^",row)
			 }
	 
			 Set tSC = $$$OK
			 Do {
				Set:java=1 features("JAVA")=""
				Set:populate=1 features("POPULATE") = ""
				Set:sqlcolumns=1 features("SQLCOLUMNS") = ""
				Set:nosequence=1 features("NOSEQUENCE")=""
				Set:ignorenull=1 features("IGNORENULL")=1
				Set:binaryasstream=1 features("BINARYASSTREAM")=1
			 	Set tResult = ##class(%XML.Utils.SchemaResult).CreateResult(reader,defpkg,.features)
				If '$IsObject(tResult) {
					Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("Unable to create Schema Result."))
					Quit
				}
		 	 
				Set tSC = tResult.SaveClasses(1)
				If $$$ISERR(tSC) Quit
		
				Write "<hr><br>",!

				If compile {
					Write "<div class=""body"">"_$$$Text("Compilation Output")_":</div>",!
					Write "<div class=""OUTPUT"">",!
					Write "<pre>",!
					Set tSC = tResult.CompileClasses(0,"dk")
					Write "</pre>",!
					Write "</div>",!
				} Else {
					Write "<div class=""body"">"_$$$Text("Classes not compiled.")_"</div>",!
				}
		 
				// put classes into session data
				Kill %session.Data("ClassList")
		
				Set tCls = $order(tResult.Classes(""))
				While (tCls '= "") {
					Set %session.Data("ClassList",tCls) = ""
					Set tCls = $order(tResult.Classes(tCls))
				}
			 } While (0)
	 
			 If $$$ISERR(tSC) {
				 Write $$$Text("Error")_": "
				 Do $System.Status.DisplayError(tSC)
			 }
		  }
		  Do ##class(%XML.Utils.SchemaReader).Delete(schemaid)
		  Set msgComplete = $$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
		  Write "<br/>",msgComplete,"<br/>"

		}
		Catch (ex) {
			Set $ztrap=""
			Write $$$Text("Error")_": ",..EscapeHTML($ze),!
			Do ##class(%XML.Utils.SchemaReader).Delete(schemaid)
		}
	
	Quit tSC
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("iframePreview");
	var wd = (document.documentElement.clientWidth ? document.documentElement.clientWidth : document.body.clientWidth) - 50;
	var ht = (document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight) - 300;
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

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.<br/>
/// (1) adding classes to the project;
/// (2) classes may be opened if Studio's option "Open file to added project" is checked.
Method %OnTemplateAction() As %Status
{
	Set cls = $order(%session.Data("ClassList",""))
	While (cls '= "") {
		Do ..%AddToProject(cls _ ".cls")
		Do ..%AddToSourceControl(cls _ ".cls")
		Set cls = $order(%session.Data("ClassList",cls))
	}
	If ($get(%session.Data("schemaid")) '= "") {
		Do ##class(%XML.Utils.SchemaReader).Delete(%session.Data("schemaid"))
	}
	Kill %session.Data("ClassList")
	Kill %session.Data("schemaid")
	// delete temp data
	Set schemaid = $G(^ISC.XMLSchemaWizard($Username,"schemaid"))
	Do ##class(%XML.Utils.SchemaReader).Delete(schemaid)
	
	Quit 1
}

}
