/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog window displays a finder-style file selection window.
/// This is intended for use within server portal pages.<br/>
/// To launch the finder use the zenLaunchPopupWindow function:<br/>
/// <example language="javascript">
/// zenLaunchPopupWindow('%ZEN.Dialog.finderDialog.cls?MODE=classes',
/// 	'DataSource',
/// 	'status,scrollbars,resizable=yes,width=800,height=600');
/// </example>
/// <br/>
/// Set URL parameter <var>MODE</var> to the type of thing you wish to display. 
/// Refer to the <property>mode</property> for a list of possible values.
/// <br/>
/// Set URL parameter <var>SUPER</var> to limit the finder to showing classes that inherit
/// from a specified class. In this case, <var>MODE</var> is ignored.
/// <br/>
/// The return value of this dialog is of the form "name.type", where type is "cls" or "int" etc.
/// To process the return value:<br/>
/// <example language="cls!member">
/// ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
/// {
/// 	switch(popupName) {
/// 	case 'DataSource':
/// 			if (value != '') {
/// 				// value is name plus extension
/// 				// pull extension off of name
/// 				var s = value.toString().split('.');
/// 				if ('cls' == s[s.length-1]) {
/// 					s.length = s.length-1;
/// 					var className = (s.join('.');
/// 				}
/// 			}
/// 			break;
/// 		}
/// 	}
/// </example>
/// To use this dialog, the current user must hold USE privileges on 
/// one of the following resources:<br/>
/// %Admin_Manage,%Admin_Operate,%Admin_Secure,%Development,%Ens_Portal 
Class %ZEN.Dialog.finderDialog Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "columns";

/// If this page has multiple categories, this is its initial value. 
/// Note: the "local" value has meaning only for "classes" mode. Other modes should set a different default category.
/// See %OnAfterCreatePage() for where these defaults are set for each mode. 
Parameter DEFAULTCATEGORY = "local";

/// AUTOLOGOUT is disabled for the finder dialog as we expect it to be called as a soft modal,
/// and the timeout behaviour should thus be controlled by the opening page.
Parameter AUTOLOGOUT = 0;

Parameter USESESSIONLANG As BOOLEAN = 1;

/// This value is passed in by the caller of this dialog. It indicates
/// what things to display. The default is "classes".
/// <p>
/// In "classes" mode the finderDialog supports four different sub-modes (stored in the currCategory 
/// property) which are chosen by the user clicking on an icon in the left-hand column of the finder.
/// <p>
/// The "local" sub-mode sets SYSTEM=0 and PERCENT=0 and PRODUCT=0. This is the default sub-mode for "classes".<br/>
/// The "persistent" sub-mode sets PERSISTENT=1 and, if they are undefined, SYSTEM=0, PERCENT=0, and PRODUCT=0. <br/>
/// The "datatype" sub-mode sets DATATYPE=1.
/// The "system" sub-mode sets SYSTEM=1 and PERCENT=1 and PRODUCT=1.
/// <p>
/// Any URL parameter for the finderDialog that is not set by a "classes" sub-mode 
/// as described above may be used effectively with "classes" mode.
/// <p>
/// Other mode options are:<br/>
/// "classes" -- show class finder.<br/>
/// "persistent" -- show persistent class finder. Do not use DATATYPE or CONTEXT modifiers with this mode.<br/>
/// "datatype" -- show datatype class finder. Do not use DATATYPE or CONTEXT modifiers with this mode.<br/>
/// "cubes" -- show DeepSee cube finder.<br/>
/// "bpl" -- show BPL business process finder.<br/>
/// "bplplus" -- show business process finder: BPL and non-BPL.<br/>
/// "dtl" -- show DTL data transformation finder.<br/>
/// "dtlplus" -- show DTL data transformation finder: DTL and non-DTL.<br/>
/// "request" -- show all message request classes.<br/>
/// "response" -- show all message response classes.<br/>
/// "allmessages" -- show all message classes, grouped into categories.<br/>
/// "rules" -- show rules finder.<br/>
/// "nms" -- show production-enabled namespaces.<br/>
/// "vdocclass" -- show VDoc or persistent classes.<br/>
/// "vdocschema" -- show VDoc schema categories for one or all VDoc families.<br/>
/// "vdoctype" -- show DocType structures. CATEGORY indicates the doc class.<br/>
/// "vdoccontents" -- show the contents of an VDoc structure. CATEGORY indicates the VDoc class and the DocType in the following format: CATEGORY=VDocClass|DocType.<br/>
/// "vdocsegtype" -- show segment types. CATEGORY indicates the VDoc class.<br/>
/// "vdocsegcontents" -- show property paths for a given segment. CATEGORY indicates the VDoc class and the DocType in the following format: CATEGORY=VDocClass|DocType.<br/>
/// "configurations" -- show configuration items for all Productions.<br/>
/// "folderitems" -- show DeepSee folder items.<br/>
/// "services" -- show all Business Service classes.<br/>
/// "operations" -- show all Business Operation classes.<br/>
/// "lookups" -- show all defined lookup tables.<br/>
/// "sqlstored" -- show all stored procedures.<br/>
/// "queries" -- show all stored procedures that return resultSets except default extent queries.</br>
/// "allqueries" -- show all stored procedures that return resultSets.</br>
/// "views" -- show all SQL views.<br/>
/// "querycontext" -- alternately show queries, allqueries or view. </br>
/// "prjfiles" -- show all Studio project files.<br/>
/// "production" -- show productions which are allowed in the namespace.<br/>
/// "datasettings" -- show all Deployable Settings Documents.<br/>
Property mode As %ZEN.Datatype.string(ZENURL = "MODE") [ InitialExpression = "classes" ];

/// Value to be returned by this dialog.
Property returnValue As %ZEN.Datatype.string;

/// If this page has "views", this is the current view type.
Property currViewMode As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTVIEWMODE} ];

/// Current Category.
Property currCategory As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTCATEGORY} ];

/// Current sort mode for this page.
Property currSortMode As %ZEN.Datatype.string [ InitialExpression = "name" ];

/// If defined, then use this as the extension for items returned by the finder (e.g., "bpl").
Property extension As %ZEN.Datatype.string;

/// Current search (filter) key value.
Property searchKey As %ZEN.Datatype.string;

/// Current super class filter value. If set, this overrides the mode behavior.
Property superKey As %ZEN.Datatype.string(ZENURL = "SUPER");

/// Current super class filter value which does not include the superclass in the output.
/// If set, this overrides the mode behaviour. Note that <property>superKey</property> takes precedence
/// if both properties are specified.
Property subKey As %ZEN.Datatype.string(ZENURL = "SUB");

/// Category used by some modes.
Property category As %ZEN.Datatype.string(ZENURL = "CATEGORY");

/// Page calling page might populate e.g dtleditor
Property caller As %ZEN.Datatype.string(ZENURL = "CALLER");

/// Include system items. Used by some modes.
/// Note that passing in the empty string when in "classes" mode and "local" category
/// will include both system and non-system classes.
Property includeSystem As %ZEN.Datatype.boolean(ZENURL = "SYSTEM");

/// Used with mode "classes". Include or do not include classes whose names include the % character.
Property includePercent As %ZEN.Datatype.boolean(ZENURL = "PERCENT");

/// Used with mode "classes". Include or do not include classes that are mapped to product databases, e.g. IRISSYS, IRISLIB, ENSLIB, HSLIB
Property includeProduct As %ZEN.Datatype.boolean(ZENURL = "PRODUCT");

/// Used with mode "classes". Include or do not include classes that are generated.
Property includeGenerated As %ZEN.Datatype.boolean(ZENURL = "GENERATED");

/// Used with mode "classes". Include or do not include classes that are datatypes.
Property includeDatatype As %ZEN.Datatype.boolean(ZENURL = "DATATYPE");

/// Used with mode "classes" for the business process context.
/// Include or do not include classes that are either persistent, serial, or datatype.
/// If true, accept any of these types. If false, accept none of them.
/// As you can see in %ZEN.FinderUtils, the value for includeContext overrides any value for includeDatatype.
/// The value for includeContext will also override mode "persistent" so they should not be used together.
/// Use includeContext only with mode "classes".
Property includeContext As %ZEN.Datatype.boolean(ZENURL = "CONTEXT");

/// Include abstract classes. Used by some modes.
Property includeAbstract As %ZEN.Datatype.boolean(ZENURL = "ABSTRACT") [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">

body {
	background: #C0C0C0;
	font-family: arial;
	overflow: hidden;
}

#body {
	background: #C0C0C0;
	padding: 0px;
	overflow: hidden;
	visibility: hidden;
}

/* do not show standard header */
#header {
	display: none;
}

#footer {
	color: black;
	background: #C0C0C0;
	background-image: none;
	width: 100%;
	padding: 0px;
	border-top: 1px solid gray;
}

#finder {
	width: 100px;
	background: white;
	overflow: hidden;
	border: 1px solid green;
}

.finderItemSelected {
	font-weight: bold;
	background: rgb(53,107,141);
	color: white;
}

.finderListRowSelected {
	color: white;
	background: rgb(53,107,141);
}

.category {
	overflow: hidden;
	text-align: center;
	color: #606060;
	padding: 10px;
	width: 130px;
}

/* style for lookout menu */
#lookout {
	border: 1px solid gray;
	overflow: hidden;
	background: white;
}

.lookoutTab {
	background: rgb(231,230,244);
	overflow-x: hidden;
	width: 100%;
}

.lookoutButton {
	background: rgb(211,210,224);
	border: 1px solid #808080;
	color: #606060;
	font-weight: bold;
}

.lookoutButton:hover {
	background: rgb(241,240,254);
}

/* tool ribbon */
.toolRibbon {
	height: 70px;
	background: white;
	border: 1px solid black;
	vertical-align: middle;
}

.ribbonTitle {
	font-size: 20px;
	color: white;
	background: rgb(53,107,141);
	border-left: 1px solid black;
}

.ribbonLabel {
	vertical-align: middle;
	color: #404040;
	font-weight: bold;
	font-size: 10pt;
}

.ribbonSortOption:hover,.ribbonSortOptionSelected:hover {
	color: darkred;
}

.ribbonSortOption {
	text-decoration: none;
	color: blue;
	font-weight: normal;
}

.ribbonSortOptionSelected {
	text-decoration: none;
	color: #404040;
	background: #FFEEAA;
	font-weight: normal;
}

.viewIconBar {
	vertical-align: bottom;
}

.viewIcon,.viewIconSelected,.viewIconDis {
	vertical-align: bottom;
	padding: 2px;
}

.viewIconSelected {
	padding: 0px;
	border: 2px solid darkred;
	background:#FFEEAA;
}

.viewIcon:hover,.viewIconSelected:hover {
	padding: 1px;
	border: 1px dotted gray;
}

/* command button styles */
/* buttons in footer */
#btnApply input,
#btnOK input,
#btnCancel input,
.commandButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonRemove {
	background: rgb(141,53,53);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonDisabled {
	background: darkgray;
	color: gray;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
}

#btnApply input:hover,
#btnOK input:hover,
#btnCancel input:hover,
.commandButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}

.commandButtonRemove:hover {
	background: rgb(141,53,53);
	color: white;
	background-image: url(portal/button_red_hover.png);
	background-repeat: repeat-x;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<jsonProvider id="json" OnGetArray="GetFinderArray">
<parameter id="jsonParent" paramName="parent" value=""/>
</jsonProvider>
<html id="toolRibbon" OnDrawContent="DrawRibbon"/>
<hgroup cellVAlign="top">
<!-- categories -->
<lookoutMenu id="lookout" remember="false">
<!-- tabs are created by OnAfterCreatePage -->
</lookoutMenu>
<!-- finder -->
<finderPane id="finder" ongetdata="return zen('json').getContentObject();" 
	onlazyload="return zenPage.loadChildren(item);"
	onselectitem="return zenPage.itemSelected(item);"
	ondrawdetails="return zenPage.drawDetails(item,finder,index);"
	ondblclick="return zenPage.itemDoubleClick(item);"
	ongeticon="return zenPage.getItemIcon(item);"
	listColumns="name,date"
	/>
</hgroup>
</pane>
}

/// Zen page notification of an HTTP request.
ClassMethod %OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	// test if user has resources
	If ($System.Security.Check("%Admin_Manage","USE")||
		$System.Security.Check("%Admin_Operate","USE")||
		$System.Security.Check("%Admin_Secure","USE")||
		$System.Security.Check("%Development","USE")||
		(##class(%Library.EnsembleMgr).IsEnsembleNamespace()&&$system.Security.Check("%Ens_Portal","USE"))
		) {
		Quit 1
	}
	Quit 0
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Finder Dialog")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select an item from the choices below.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	// escape %
	var value = (''==this.returnValue) ? '' : this.returnValue.replace(/%/g,'%25');
	return value;
}

/// Provide the source data (as an array) that will drive the finder.
Method GetFinderArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Kill tParms
	
	// assemble search parameters
	Set tParms("sort") = ..currSortMode
	Set tParms("search") = ..searchKey
	Set tParms("abstract") = ..includeAbstract

	#; Set category error in advance in case we fall through
	Set tSC=$$$ERROR($$$GeneralError,"Category '"_..currCategory_"' not supported for Finder mode '"_..mode_"'")

	If (..mode = "cubes") {
		Quit ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "request") {
		If $Case(..currCategory, "request":1, "persistentvdoc":1, "persistentselect":1, :0) {
			Set tParms = 2
			Set tParms(1) = ..mode
			Set tParms(2) = ..currCategory
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("EnsPortal.Utils","EnumerateMessageClasses",$LB("{Name}","","{Type}",""),".",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "response") {
		If $Case(..currCategory, "response":1, "persistentvdoc":1, "persistentselect":1, :0) {
			Set tParms = 2
			Set tParms(1) = ..mode
			Set tParms(2) = ..currCategory
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("EnsPortal.Utils","EnumerateMessageClasses",$LB("{Name}","","{Type}",""),".",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "allmessages") { 
		If (..currCategory = "request") || (..currCategory = "response") || (..currCategory = "persistentvdoc") || (..currCategory = "persistentselect") {
			Set tParms = 2
			Set tParms(1) = ..mode
			Set tParms(2) = ..currCategory
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("EnsPortal.Utils","EnumerateMessageClasses",$LB("{Name}","","{Type}",""),".",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "vdocclass") {
		If $Case(..currCategory, "messages":1, "classvdoc":1, "persistentselect":1, "classselect":1, :0) {
			Set tParms = 2
			Set tParms(1) = ..mode
			Set tParms(2) = ..currCategory
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("EnsPortal.Utils","EnumerateMessageClasses",$LB("{Name}","","{Type}",""),".",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "vdocschema") {
		Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("Ens.VDoc.Utils","EnumerateVDocSchemas",$LB("{Family}_"":""_{Category}","{SchemaDocExt}_"":""_{Category}","{SchemaDocExt}",""),":",,.pMetaData,.pData)
	}
	ElseIf (..mode = "vdoctype") {
		Set tClassName = ..category
		If (tClassName'="") {
			If $Case(tClassName,"EnsLib.EDI.EDIFACT.Segment":1,"EnsLib.EDI.X12.Segment":1,:0) {
				Set tParms = 3
				Set tParms(3)=1
			} ElseIf ((tClassName = "EnsLib.EDI.X12.Document")&&(..caller="dtleditor")) {
				Set tParms = 3
				Set tParms(3) = 1
			} Else {
				Set tParms = 0
			}
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery(tClassName,"EnumerateDocTypes",$LB("{Type}","","",""),":",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "vdocsegtype") {
		Set tClassName = ..category
		If (tClassName '= "") {
			Set tParms = 2
			Set tParms(1) = ""
			Set tParms(2) = 0
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery(tClassName,"EnumerateSegTypes",$LB("{SegType}","","",""),":",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "vdocsegcontents") {
		Set tClassName = $piece(..category, "|", 1)
		Set tDocType = $piece(..category, "|", 2)
		If (tClassName '= "") && (tDocType '= "") {
			Set tParms = 1
			Set tParms(1) = tDocType
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery(tClassName,"EnumerateSegTypes",$LB("$extract({Field},2,*)","","",""),".",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "vdoccontents") {
		Set tClassName = $piece(..category, "|", 1)
		Set tDocType = $piece(..category, "|", 2)
		If (tClassName '= "") && (tDocType '= "") {
			Set tParms = 6
			Set tParms(1) = tClassName
			Set tParms(2) = "source"
			Set tParms(3) = tDocType
			Set tParms(4) = 0
			Set tParms(5) = 0
			Set tParms(6) = 0
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("Ens.VDoc.Utils","EnumerateDocContents",$LB("{Property}","{Property}","",""),":.",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "nms") {
		Quit ##class(%ZEN.FinderUtils).%GetArrayForNamespaces(.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "hosts") {
		If $Case(..currCategory, "service":1, "process":1, "operation":1, :0) {
			Set tParms = 1
			Set tParms(1) = ..currCategory
			Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("Ens.Host","Enumerate",$LB("{Name}","{Name}","{Type}",""),".",.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "lookups") {
		#;LookupTables can differ in case. No need for other default parameter values
		Set tParms("sort")="namecasesensitive"
		Kill tParms("abstract")
		Kill tParms("search")
		Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("Ens.Util.LookupTable","Enumerate",$LB("{Name}","{Name}_"".lut""","lut",""),".",.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "datasettings") {
		Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("Ens.Util.SettingsDocument","List",$LB("$E({name},1,*-4)","{name}","esd",""),"^",,.pMetaData,.pData)
	}
	ElseIf (..mode = "configurations") {
		Set tProd = ..category
		Set tParms = 1
		Set tParms(1) = tProd
		Set tSC= ##class(%ZEN.FinderUtils).%GetArrayForQuery("Ens.Config.Production","EnumerateConfigItems",$LB("##class(EnsPortal.Utils).resolveHostType({BusinessType})_"":""_{ConfigName}","{ConfigName}","ptd",""),":",.tParms,.pMetaData,.pData)
		Quit tSC
	}
	ElseIf (..mode = "folderitems") {
		Set tFolderClass = ..category
		Set tParms = 5
		Set tParms(1) = ""
		Set tParms(2) = ""
		Set tParms(3) = ""
		Set tParms(4) = 1
		Set tParms(5) = tFolderClass
		Set tSC= ##class(%ZEN.FinderUtils).%GetArrayForQuery("%DeepSee.UI.FolderItemDocument","List",$LB("$P({name},""."",1,$L({name},""."")-1)","{name}","$P({name},""."",$L({name},""."")-2)",""),"-",.tParms,.pMetaData,.pData)
		Quit tSC
	} 
	ElseIf (..mode = "sqlstored") {
		Set tParms = 0
		Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("%Library.SQLCatalog","SQLProcedures",$LB("{CLASS_NAME}_"":""_{PROCEDURE_NAME}","{CLASS_NAME}_"":""_{PROCEDURE_NAME}","",""),":",.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "queries") {
		Set tParms("filterExtent") = 1
		Quit ##class(%ZEN.FinderUtils).%GetQueryListArray(.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "allqueries") {
		Set tParms("filterExtent") = 0
		Quit ##class(%ZEN.FinderUtils).%GetQueryListArray(.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "views") {
		Set tParms = 0
		Quit ##class(%ZEN.FinderUtils).%GetViewListArray(.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "querycontext") {
		If (..currCategory = "views") {
			Set tParms = 0
			Quit ##class(%ZEN.FinderUtils).%GetViewListArray(.tParms,.pMetaData,.pData)
		}
		Else {	
			Set tParms("filterExtent") = 1
			If (..currCategory = "allqueries") Set tParms("filterExtent") = 0
			Quit ##class(%ZEN.FinderUtils).%GetQueryListArray(.tParms,.pMetaData,.pData)
		}
	}
	ElseIf (..mode = "prjfiles") {
		Set tParms = 0 /* User ^ as group separator since Project name can contain : and . amongst other characters */
		Quit ##class(%ZEN.FinderUtils).%GetArrayForQuery("%Studio.Project","ProjectList",$LB("{Name}_"".PRJ""","{ID}","PRJ",""),"^",.tParms,.pMetaData,.pData)
	}
	ElseIf (..mode = "production") {
		Set tParms("super") = "Ens.Production"
		Set tParms("production") = 1
		Set tParms("abstract") = 0
		Quit ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
	}
	Else {
		Set tSC=$$$OK ; no category error, just a ClassList query
	}
	Quit:$$$ISERR(tSC) tSC ; quit category error now if we fell through

	#; else: ClassList queries

	If (..mode = "rules") {
		Set tParms("super") = "Ens.Rule.Definition"
		Set tParms("system") = 0
		Set tParms("abstract") = 0
	} 
	ElseIf (..mode = "bpl") {
		Set tParms("sub") = "Ens.BusinessProcessBPL"
		Set tParms("abstract") = 0
	}
	ElseIf (..mode = "bplplus") {
		Set tParms("super") = "Ens.BusinessProcess"
		Set tParms("abstract") = 0
	}
	ElseIf (..mode = "dtl") {
		Set tParms("super") = "Ens.DataTransformDTL"
		Set tParms("abstract") = 0
	}
	ElseIf (..mode = "dtlplus") {
		Set tParms("super") = "Ens.DataTransform"
		Set tParms("abstract") = 0
	}
	ElseIf (..mode = "services") {
		Set tParms("super") = "Ens.BusinessService"
		Set tParms("abstract") = 0
	}
	ElseIf (..mode = "operations") {
		Set tParms("super") = "Ens.BusinessOperation"
		Set tParms("abstract") = 0
	}
	ElseIf (..mode = "classescontext") { // class mode for BPL context objects
		If (..currCategory = "localcontext") {
			Set tParms("abstract") = 0
			Set tParms("generated") = 0
			Set tParms("context") = 1
			Set tParms("system") = 0
			Set tParms("percent") = 0
			Set tParms("product") = 0
		}
		ElseIf (..currCategory = "persistentcontext") {
			Set tParms("persistent") = 1
			Set tParms("system") = ""
			Set tParms("percent") = 0
			Set tParms("product") = ""
		}
		ElseIf (..currCategory = "datatypecontext") {
			Set tParms("datatype") = 1
			Set tParms("system") = ""
			Set tParms("percent") = ""
			Set tParms("product") = ""
		}
		ElseIf (..currCategory = "systemcontext") {
			Set tParms("abstract") = 0
			Set tParms("generated") = 0
			Set tParms("context") = 1
			Set tParms("system") = 1
			Set tParms("percent") = ""
			Set tParms("product") = ""
		}
	}
	Else {
		Quit:$Case(..mode,"classes":0,"persistent":0,"datatype":0,:1) $$$ERROR($$$GeneralError,"Finder does not support mode '"_..mode_"'")

		// When we initially display this dialog we get a "" empty string for the ZENURL
		// values that are of type %ZEN.Datatype.boolean and for which no value was supplied
		// in the URL string. So "" is what we test for to see that no value was supplied 
		// for the %ZEN.Datatype.boolean in the URL. However, upon updating the finderPane 
		// object in setCategoryHandler(), those %ZEN.Datatype.boolean values for which no 
		// value was supplied in the URL reset themselves to 0 instead of the empty string "" 
		// that we are testing for. Here we are setting them back to "" when no value was 
		// supplied.
		Set ..includeSystem = $Get(%request.Data("SYSTEM",1))
		Set ..includePercent = $Get(%request.Data("PERCENT",1))
		Set ..includeProduct = $Get(%request.Data("PRODUCT",1))
		Set ..includeGenerated = $Get(%request.Data("GENERATED",1))
		Set ..includeDatatype = $Get(%request.Data("DATATYPE",1))
		Set ..includeContext = $Get(%request.Data("CONTEXT",1))

		// set initial values for boolean flags
		If ..includeSystem '= "" Set tParms("system") = ..includeSystem
		If ..includePercent '= "" Set tParms("percent") = ..includePercent
		If ..includeProduct '= "" Set tParms("product") = ..includeProduct
		If ..includeGenerated '= "" Set tParms("generated") = ..includeGenerated
		If ..includeDatatype '= "" Set tParms("datatype") = ..includeDatatype
		If ..includeContext '= "" Set tParms("context") = ..includeContext

		If (..currCategory = "persistent") {
			Set tParms("persistent") = 1
			Set:'$D(tParms("system")) tParms("system") = 0
			Set:'$D(tParms("percent")) tParms("percent") = 0
			Set:'$D(tParms("product")) tParms("product") = 0
		}
		ElseIf (..currCategory = "system") {
			Set tParms("system") = 1
			Set:'$D(tParms("percent")) tParms("percent") = 1
			Set:'$D(tParms("product")) tParms("product") = 1
		}
		ElseIf (..currCategory = "datatype") {
			Set tParms("datatype") = 1
		}
		ElseIf (..currCategory = "local") {
			Set:'$D(tParms("system")) tParms("system") = 0
			Set:'$D(tParms("percent")) tParms("percent") = 0
			Set:'$D(tParms("product")) tParms("product") = 0
		}
		ElseIf (..currCategory = "zenpages") {
			Set tParms("super") = "%ZEN.Component.page"
		}
		ElseIf (..currCategory = "zenreports") {
			Set tParms("super") = "%ZEN.Report.reportPage"
		}
		ElseIf (..currCategory = "zenapps") {
			Set tParms("super") = "%ZEN.application"
		}
		ElseIf (..currCategory = "zencomps") {
			Set tParms("super") = "%ZEN.Component.object"
		}
		Else { 
			Quit:""'=..currCategory $$$ERROR($$$GeneralError,"Category '"_..currCategory_"' not supported for Finder mode '"_..mode_"'")
		}
	}
	If (..superKey '= "") {
		Set tParms("super") = ..superKey
	} ElseIf (..subKey '= "") {
		Set tParms("sub") = ..subKey
	}
	Quit ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
}

/// Return the icon for the item in "icons" mode.
ClientMethod getItemIcon(item) [ Language = javascript ]
{
	var icon = '';
	if (null == item.children) {
		if (item.type && 'cls' == item.type) {
			icon = 'portal/objects_48.gif';
			if (item.classtype) {
				if ('persistent' == item.classtype) {
					icon = 'portal/table_48.gif';
				}
				else if ('datatype' == item.classtype) {
					icon = 'portal/text_field_48.gif';
				}
			}
		}
	}
	return icon;
}

/// Provide HTML for details on selected item in finder.
ClientMethod drawDetails(item, finder, index) [ Language = javascript ]
{
	var html = new Array();
	switch (finder.viewType) {
	case 'columns':
		if (item && null == item.children) {
			html[html.length] = '<div style="text-align:center; padding: 5px;">';
			var name = zenEscapeHTML(item.value ? item.value : item.name);
			if (name) {
				html[html.length] = '<div style="font-weight:bold;" title="'+name+'">' + name + '</div>';
				html[html.length] = '<hr/>';
			}

			if (null == item._info) {
				// get more info from server
				item._info = this.GetItemInfo(this.mode,item.value,this.category);
				item.description = item._info.description;
			}

			var icon = item.icon;
			
			if (!icon || '' == icon) {
				if (item.type == 'cls') {
					if (item._info && (1==item._info.zenPage)) {
						icon = 'portal/mini_sites_48.gif';
					}
					else if (item._info && (1==item._info.zenApp)) {
						icon = 'portal/architecture_info_48.gif';
					}
					else if (item._info && (1==item._info.zenReport)) {
						icon = 'portal/report_48.gif';
					}
					else if (item._info && (1==item._info.zenComp)) {
						icon = 'portal/redesign_48.gif';
					}
					else if ('persistent' == item.classtype) {
						icon = 'portal/table_48.gif';
					}
					else if ('datatype' == item.classtype) {
						icon = 'portal/text_field_48.gif';
					}
					else if (item._info && (parseInt(item._info.system) > 0)) {
						icon = 'portal/objects_config_48.gif';
					}
					else {
						icon = 'portal/objects_48.gif';
					}
				}
				else {
				 	icon = 'portal/gear_48.gif';
				}
			}
		
			html[html.length] = '<img alt="" src="' + icon + '"/></b><br/>';

			if (item.date) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text("Last modified") + '</div>';
				html[html.length] = '<div style="">' + item.date + '</div><br/>';
			}

			if (item._info && ''!=item._info.generatedby) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Generated by') + '</div>';
				html[html.length] = '<div style="padding:5px;"><a href="#" title="' + $$$Text('Open this class') + '" onclick="zenPage.openSuper(\''+item._info.generatedby+'\');return false;">' + item._info.generatedby + '</a></div>';
				html[html.length] = '<br/>';
			}

			if (item._info && item._info.superclass) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text("Extends") + '</div>';
				var t = item._info.superclass.split(',');
				for (var n = 0; n < t.length; n++) {
					html[html.length] = '<div style="padding:5px;"><a href="#" title="' + $$$Text('Open this class') + '" onclick="zenPage.openSuper(\''+t[n]+'\');return false;">' + t[n] + '</a></div>';
				}
				html[html.length] = '<br/>';
			}

			var desc = item.description ? item.description : '';
			if (desc != '') {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Description') + '</div>';
				html[html.length] = '<div style="text-align:left;">' + desc + '</div>';
			}

			// command
			html[html.length] = '<hr/>';
			html[html.length] = '<a class="commandButton" href="#" onclick="zenPage.dialogFinish();return false;">'+$$$Text("Go")+'</a>' + '<br/>';
			html[html.length] = '</div>';
		}
		else if (item && null == item.children && this.mode == 'cubes') {
			// DeepSee cubes

			html[html.length] = '<div style="text-align:center; padding: 5px;">';
			var name = (item.value ? item.value : item.name);
			if (name) {
				html[html.length] = '<div style="font-weight:bold;" title="'+name+'">' + name + '</div>';
				html[html.length] = '<hr/>';
			}

			if (null == item._info) {
				// get more info from server
				item._info = this.GetItemInfo(this.mode,item.value,this.category);
				item.description = item._info.description;
			}

			var icon = item.icon;
			
			if (!icon || '' == icon) {
				if (item.type == 'cls') {
					if (item._info && (1==item._info.zenPage)) {
						icon = 'portal/mini_sites_48.gif';
					}
					else if (item._info && (1==item._info.zenApp)) {
						icon = 'portal/architecture_info_48.gif';
					}
					else if (item._info && (1==item._info.zenReport)) {
						icon = 'portal/report_48.gif';
					}
					else if (item._info && (1==item._info.zenComp)) {
						icon = 'portal/redesign_48.gif';
					}
					else if ('persistent' == item.classtype) {
						icon = 'portal/table_48.gif';
					}
					else if ('datatype' == item.classtype) {
						icon = 'portal/text_field_48.gif';
					}
					else if (item._info && (parseInt(item._info.system) > 0)) {
						icon = 'portal/objects_config_48.gif';
					}
					else {
						icon = 'portal/objects_48.gif';
					}
				}
				else {
				 	icon = 'portal/gear_48.gif';
				}
			}
		
			html[html.length] = '<img alt="" src="' + icon + '"/></b><br/>';

			if (item.date) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Last modified') + '</div>';
				html[html.length] = '<div style="">' + item.date + '</div><br/>';
			}

			if (item._info && ''!=item._info.generatedby) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Generated by') + '</div>';
				html[html.length] = '<div style="padding:5px;"><a href="#" title="' + $$$Text('Open this class') + '" onclick="zenPage.openSuper(\''+item._info.generatedby+'\');return false;">' + item._info.generatedby + '</a></div>';
				html[html.length] = '<br/>';
			}

			if (item._info && item._info.superclass) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Extends') + '</div>';
				var t = item._info.superclass.split(',');
				for (var n = 0; n < t.length; n++) {
					html[html.length] = '<div style="padding:5px;"><a href="#" title="' + $$$Text('Open this class') + '" onclick="zenPage.openSuper(\''+t[n]+'\');return false;">' + t[n] + '</a></div>';
				}
				html[html.length] = '<br/>';
			}

			var desc = item.caption ? item.caption : '';
			if (desc != '') {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Description') + '</div>';
				html[html.length] = '<div style="text-align:left;">' + desc + '</div>';
			}

			// command
			html[html.length] = '<hr/>';
			html[html.length] = '<a class="commandButton" href="#" onclick="zenPage.dialogFinish();return false;">'+ $$$Text('Go') +'</a>' + '<br/>';
			html[html.length] = '</div>';
		}
		break;
	case 'list':
		break;
	case 'icons':
		break;
	}	
	return html.join('');
}

/// Look up additional information for a given class.
ClassMethod GetClassInfo(pClassName As %String) As %ZEN.proxyObject [ Internal, ZenMethod ]
{
	Quit ..GetItemInfo("class",pClassName)
}

/// Look up additional information for a given item.
ClassMethod GetItemInfo(pMode As %String, pItemName As %String, pItemCategory As %String = "") As %ZEN.proxyObject [ Internal, ZenMethod ]
{
	Set tInfo = ##class(%ZEN.proxyObject).%New()

	If (pMode="vdoctype") {
		Set tInfo.generatedby = ""
		Set tInfo.superClass = ""

		// get info on vdoc item
		Set tSchemaClass = ""
		If (pItemCategory["HL7") {
			Set tElementSpec = "MT:"_pItemName
			Set tSchemaClass = "EnsLib.HL7.Schema"
		}
		ElseIf (pItemCategory["ASTM") {
			Set tElementSpec = "DS:"_pItemName
			Set tSchemaClass = "EnsLib.EDI.ASTM.Schema"
		}
		ElseIf (pItemCategory["X12") {
			Set tElementSpec = "DS:"_pItemName
			Set tSchemaClass = "EnsLib.EDI.X12.Schema"
		}
		ElseIf (pItemCategory["EDIFACT") {
			Set tElementSpec = "DS:"_pItemName
			Set tSchemaClass = "EnsLib.EDI.SEF.Schema"
		}
		If (tSchemaClass '= "") {
			Try {
				Set tInfo.description = ..EscapeHTML($classmethod(tSchemaClass,"GetDescription",tElementSpec))
			}
			Catch(ex) {
				Set tInfo.description = $ZCVT($ZE,"O","HTML")
			}
		}
		Set:""=tInfo.description tInfo.description = $$$Text("Document Type")
	}
	ElseIf (pMode = "vdocsegtype") {
		Set tInfo.generatedby = ""
		Set tInfo.superClass = ""
		
		Set tSchemaClass = $case(pItemCategory,
								"EnsLib.HL7.Message": 			"EnsLib.HL7.Schema",
								"EnsLib.EDI.ASTM.Document": 		"EnsLib.EDI.ASTM.Schema",
								"EnsLib.EDI.EDIFACT.Document": 	"EnsLib.EDI.SEF.Schema",
								"EnsLib.EDI.X12.Document": 		"EnsLib.EDI.X12.Schema",
								: "")
		If tSchemaClass '= "" {
			Set tElementSpec = $case(pItemCategory,
								"EnsLib.HL7.Message":			"SS:"_pItemName,
								"EnsLib.EDI.ASTM.Document":		"SS:"_pItemName,
								"EnsLib.EDI.EDIFACT.Document":	"SS:"_pItemName,
								"EnsLib.EDI.X12.Document":		"SS:"_pItemName,
								: "")
			If tElementSpec '= "" {
				Try {
					Set tInfo.description = ..EscapeHTML($classmethod(tSchemaClass, "GetDescription", tElementSpec))
				} Catch {}
			}
		}
		Set:""=tInfo.description tInfo.description = $$$Text("Segment Type")
	}
	ElseIf (pMode = "vdoccontents") {
		Set tInfo.generatedby = ""
		Set tInfo.superClass = ""
		Set tInfo.description = $$$Text("Message Property")
	}
	ElseIf pMode = "vdocsegcontents" {
		Set tInfo.generatedby = ""
		Set tInfo.superClass = ""
		Set tInfo.description = $$$Text("Segment Property")
	}
	Else {
		// assume a class
		Set tClass = pItemName

		// Description
		Set tDesc = $$$comClassKeyGet(tClass,$$$cCLASSdescription)
		If ($L(tDesc)>150) {
			Set tDesc = $E(tDesc,1,150) _ "..."
		}
		Set tInfo.description = ..EscapeHTML(tDesc)

		// Zen page?
		Try {
			Set tInfo.zenPage = $classmethod(tClass,"%IsA","%ZEN.Component.page")
			Set tInfo.zenApp = 0
			Set tInfo.zenComp = 0
			Set tInfo.zenReport = 0
		}
		Catch(ex) {
			Set tInfo.zenPage = 0
		}
		If ('tInfo.zenPage) {
			Try {
				Set tInfo.zenApp = $classmethod(tClass,"%IsA","%ZEN.application")
			}
			Catch(ex) {
				Set tInfo.zenApp = 0
			}
		}
		If ('tInfo.zenApp) {
			Try {
				Set tInfo.zenComp = $classmethod(tClass,"%IsA","%ZEN.Component.object")
			}
			Catch(ex) {
				Set tInfo.zenComp = 0
			}
		}
		If ('tInfo.zenReport) {
			Try {
				Set tInfo.zenReport = $classmethod(tClass,"%IsA","%ZEN.Report.reportPage")
			}
			Catch(ex) {
				Set tInfo.zenReport = 0
			}
		}

		// system
		Set tInfo.system = $$$defClassKeyGet(tClass,$$$cCLASSsystem)

		// superclass
		Set tInfo.superclass = $$$defClassKeyGet(tClass,$$$cCLASSsuper)

		// generated by
		Set tInfo.generatedby = $$$defClassKeyGet(tClass,$$$cCLASSgeneratedby)
		If (tInfo.generatedby'="") {
			// strip off CLS
			If ($E(tInfo.generatedby,*-3,*)=".CLS") {
				Set tInfo.generatedby = $E(tInfo.generatedby,1,*-4)
			}
		}
	}

	Quit tInfo
}

/// Item double-clicked within the Finder.
ClientMethod itemDoubleClick(item) [ Language = javascript ]
{
	if (null == item.children) {
		this.returnValue = item.value ? item.value : item.name;
		if ('' != this.returnValue && (item.type||this.extension)) {
			this.returnValue += '.' + ((this.extension == '') ? item.type : this.extension);
		}
		this.dialogFinish();
	}
}

/// User clicked on super class link.
ClientMethod openSuper(superclass) [ Language = javascript ]
{
	this.returnValue = superclass + '.cls';
	this.dialogFinish();
}

/// Item selected within the Finder.
ClientMethod itemSelected(item) [ Language = javascript ]
{
	if (item.children) {
		// not bottom-level choice
		this.returnValue = '';
	}
	else {
		// if item has a value, use it; otherwise use name
		this.returnValue = item.value ? item.value : item.name;
		if ('' != this.returnValue && (item.type||this.extension)) {
			this.returnValue += '.' + ((this.extension == '') ? item.type : this.extension);
		}
	}
	return true;
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	try {
		if (this.isSoftModal) { // prevent a possible resize feedback loop seen on mobile devices
			if (this._preventResize) {
				this._preventResize = false;
				return;
			}
			else {
				this._preventResize = true;
			}
		}
		//this.invokeSuper('setProperty',arguments);

		// now adjust size of finder
		var finder = zenPage.getComponentById('finder');
		var divFinder = finder.getEnclosingDiv();

		var lookout = zenPage.getComponentById('lookout');
		var divLookout = lookout.getEnclosingDiv();

		var ribbon = zenPage.getComponentById('toolRibbon');
		var divRibbon = ribbon.getEnclosingDiv();
	
		var header = zenPage.getComponentById('header');
		var body = zenPage.getComponentById('body');
		var footer = zenPage.getComponentById('footer');

		if (header && body && footer) {
			var divHeader = header.getEnclosingDiv();
			var divBody = body.getEnclosingDiv();
			var divFooter = footer.getEnclosingDiv();
			var winHeight = zenGetWindowHeight();
			var winWidth = zenGetWindowWidth();
		
			var hgt = winHeight - (parseInt(divHeader.offsetHeight) + parseInt(divFooter.offsetHeight));
			var rh =  parseInt(divRibbon.offsetHeight);

			divBody.style.height = hgt + 'px';
			divFinder.style.height = hgt-rh + 'px';

			// adjust size of menu
			lookout.setSize(150,hgt-rh);
			
			var fw = winWidth - divLookout.offsetWidth;
			divFinder.style.width = fw + 'px';

			// compute size of finder columns
			var cols = 3;
			var colWid = fw / cols;
			while (colWid > 300) {
				cols++;
				colWid = (fw-10) / cols;
			}
			colWid = (colWid < 100) ? 100 : colWid;
			finder.setProperty('columnWidth',colWid);

			divBody.style.visibility = 'visible';
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSize.');
	}
}

/// Draw the contents of the tool ribbon.
/// This is displayed if a subclass implements the <method>OnGetRibbonInfo</method>
/// callback.
Method DrawRibbon(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Set tDisplay = 0
	Set tSearchBox = 0
	Set tRibbonTitle = ""
	Set tSC = ..OnGetRibbonInfo(.tDisplay,.tViewIcons,.tSortOptions,.tSearchBox,.tRibbonTitle)
	If $$$ISERR(tSC) Quit tSC

	If ('tDisplay) Quit tSC
	
	&html<<div class="toolRibbon">>
	&html<<table border="0" cellspacing="0" cellpadding="0" height="100%" width="100%"><tr>>

	#; icons

	If ($D(tViewIcons)) {
		// view
		Set tTitle = $$$Text("Choose how options should be displayed")
		&html<<td style="width:40px;">&nbsp;</td>>
		&html<<td class="ribbonLabel" width="1%" title="#(tTitle)#">#($$$Text("View:"))#&nbsp;</td>>

		&html<<td nowrap="1">
		<div class="viewIconBar">>
		Set n = $O(tViewIcons(""))
		While (n'="") {
			Set tID = $LG(tViewIcons(n),1)
			Set tHelp = $LG(tViewIcons(n),2)
			Set tIcon = $LG(tViewIcons(n),3)
			&html<<img id="view_#(tID)#" class="#($S(..currViewMode=tID:"viewIconSelected",1:"viewIcon"))#" title="#(tHelp)#" src="#(tIcon)#" onclick="zenPage.setViewMode('#(tID)#');" />>
			Set n = $O(tViewIcons(n))
		}
		&html<</div></td>>
	}

	// sort
	If ($D(tSortOptions)) {
		&html<<td style="width:80px;">&nbsp;</td>>
		&html<<td class="ribbonLabel" nowrap="1">#($$$Text("Sort:"))#&nbsp;>
		Set n = $O(tSortOptions(""))
		While (n '= "") {
			Set tID = $LG(tSortOptions(n),1)
			Set tText = $LG(tSortOptions(n),2)
			Set tTitle = $LG(tSortOptions(n),3)
			Set tCls = $S(tID=..currSortMode:"ribbonSortOptionSelected",1:"ribbonSortOption")
			&html<&nbsp;<a id="sort_#(tID)#" title="#(tTitle)#" class="#(tCls)#" href="#" onclick="zenPage.setSortMode('#(tID)#');return false;">&nbsp;#(tText)#&nbsp;</a>>
			Set n = $O(tSortOptions(n))
		}
		&html<</td>>
	}

	If (tSearchBox) {
		// Search
		Set hlpSearch = $$$Text("List items containing text within their name")
		Set tSearchMsg = $$$Text("Search")
		&html<<td width="10%">&nbsp;</td>>
		&html<<td class="ribbonLabel" nowrap="1" title="#(hlpSearch)#">&nbsp;<input id="searchBox" type="search" placeHolder="#(tSearchMsg)#" size="25" onchange="zenPage.searchKeyChange(this.value);" value=""/></td>>
		&html<<td>&nbsp;</td>>
	}
	Else {
		&html<<td width="20%">&nbsp;</td>>
	}
	If (tRibbonTitle '= "") {
		&html<<td width="10%" class="ribbonTitle">&nbsp;&nbsp;<nobr>#(tRibbonTitle)#</nobr>&nbsp;&nbsp;</td>>
	}

	&html<</tr></table>>
	&html<</div>>
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = $$$Text("Finder")

	Set pViewIcons(1) = $LB("columns",$$$Text("Show columns view"),"portal/view_box_columns.png")
	Set pViewIcons(2) = $LB("list",$$$Text("Show list view"),"portal/view_box_list.png")
	Set pViewIcons(3) = $LB("icons",$$$Text("Show icons view"),"portal/view_box_icons.png")

	Set pSortOptions(1) = $LB("name",$$$Text("Name"),$$$Text("Sort items by name"))
	Set pSortOptions(2) = $LB("date",$$$Text("Date"),$$$Text("Sort items by last modified date"))

	Quit $$$OK
}

/// Change the current display mode for this page.
/// This is called by the icon buttons on the ribbon.
/// This will call the <method>setViewModeHandler</method> within a subclass.
ClientMethod setViewMode(mode) [ Language = javascript ]
{
	if (mode != this.currViewMode) {
		// update icon
		var el = self.document.getElementById('view_'+this.currViewMode);
		if (el) {
			el.className = 'viewIcon';
		}
		var oldmode = this.currViewMode;
		this.currViewMode = mode;
		var el = self.document.getElementById('view_'+this.currViewMode);
		if (el) {
			el.className = 'viewIconSelected';
		}
		
		this.setViewModeHandler(mode,oldmode);
	}
}

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode, oldmode) [ Language = javascript ]
{
	// update finder
	var finder = zen('finder');
	if (finder) {
		finder.setViewType(this.currViewMode);
	}
}

/// Change the current category for this page.
ClientMethod setCategory(cat) [ Language = javascript ]
{
	if (cat != this.currCategory) {
		// update icon
		var el = self.document.getElementById('category_'+this.currCategory);
		if (el) {
			el.className = 'viewIcon';
		}
		this.currCategory = cat;
		var el = self.document.getElementById('category_'+this.currCategory);
		if (el) {
			el.className = 'viewIconSelected';
		}
		this.setCategoryHandler(cat);
	}
}

/// Do the actual work of applying the new category selection.
ClientMethod setCategoryHandler(category) [ Language = javascript ]
{
	// get new object graph
	// show status message; this will be cleared by the update() call
	var msg = $$$Text('Loading...');
	zen('finder').getEnclosingDiv().innerHTML = '<div style="padding:10px;font-style:italic;color:#606060;">' + msg + '</div>';
	zen('json').refreshContent();

	var finder = zen('finder');
	if (finder) {
		finder.update(true);
	}
}

/// Change the current sort mode for the page.
ClientMethod setSortMode(mode) [ Language = javascript ]
{
	if (mode != this.currSortMode) {
		var el = self.document.getElementById('sort_'+this.currSortMode);
		if (el) {
			el.className = 'ribbonSortOption';
		}
		this.currSortMode = mode;
		var el = self.document.getElementById('sort_'+this.currSortMode);
		if (el) {
			el.className = 'ribbonSortOptionSelected';
		}
		this.setSortModeHandler(mode);
	}
}

/// Do the actual work of applying the new sort option.
ClientMethod setSortModeHandler(mode) [ Language = javascript ]
{
	// get new object graph
	zen('json').refreshContent();

	var finder = zen('finder');
	if (finder) {
		finder.update(true);
	}
}

/// User has changed search key value.
ClientMethod searchKeyChange(key) [ Language = javascript ]
{
	this.searchKey = key;

	// get new object graph
	zen('json').refreshContent();

	var finder = zen('finder');
	if (finder) {
		finder.update(true);
	}
}

/// Load the children for the given node in the finder.
ClientMethod loadChildren(item) [ Language = javascript ]
{
	var json = zen('json');
	var jsonParent = zen('jsonParent');

	if (''!=item.value) {
		var currGraph = zen('json').getContentObject();

		jsonParent.value = item.value;
		json.reloadContents();
		
		// splice new data into graph and restore old graph
		var newGraph = zen('json').getContentObject();

		item.children = newGraph.children;
		zen('json').setContentObject(currGraph);
		return newGraph.children;
	}
	return null;
}

/// Draw the contents of the Categories list on the left side of the dialog.
/// This is displayed if a subclass implements the <method>OnGetCategoryInfo</method>
/// callback.<br/>
/// <var>pSeed</var> indicates what to draw: "classes","zen", etc.
Method DrawCategories(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Set tDisplay = 0
	Set tSearchBox = 0
	Set tRibbonTitle = ""
	Set tSC = ..OnGetCategoryInfo(pSeed,.tDisplay,.tIcons)
	If $$$ISERR(tSC) Quit tSC

	If ('tDisplay) Quit tSC
	If ($D(tIcons)) {

		Set n = $O(tIcons(""))
		While (n'="") {
			Set tID = $LG(tIcons(n),1)
			Set tCaption = $LG(tIcons(n),2)
			Set tHelp = $LG(tIcons(n),3)
			Set tIcon = $LG(tIcons(n),4)
			&html<<div>>
			&html<<img id="category_#(tID)#" class="#($S(..currCategory=tID:"viewIconSelected",1:"viewIcon"))#" title="#(tHelp)#" src="#(tIcon)#" onclick="zenPage.setCategory('#(tID)#');" />>
			&html<<div>#(tCaption)#</div>>
			&html<</div><br/>>
			Set n = $O(tIcons(n))
		}
	}
	
	Quit $$$OK
}

/// Add components to page.
Method %OnAfterCreatePage() As %Status
{
	// Don't write out the session cookie if we are in an Ensemble Studio session
	If $get(%session.Data("Ensemble","StudioSession",$namespace)) Set %response.OutputSessionToken = 0
	// define set of category tabs to display in lookout menu
	Set tLookout = ..%GetComponentById("lookout")

	// If superKey or subKey is defined, bypass MODE logic
	If (..superKey'="") || (..subKey'="") || (..mode="production") {
		// some super classes are *built-in*
		Set tCaption = $select(..superKey '= "": $P(..superKey,".",$L(..superKey,".")), ..subKey '= "": $P(..subKey,".",$L(..subKey,".")), 1: "Production")
		Set tContent = $$$Text("Select a class from the options on the right")

		// Don't use special handling for subKey
		If (..superKey = "%DeepSee.CubeDefinition") {
			Set tCaption = $$$Text("DeepSee Cubes")
			Set tContent = $$$Text("Select a cube definition class from the options on the right")
		}
		ElseIf (..superKey = "Ens.VDOC.Interface") {
			Set tCaption = $$$Text("Document Types")
			Set tContent = $$$Text("Select a document type from the options on the right")
		}
		ElseIf (..superKey = "Namespace") {
			Set tCaption = $$$Text("Namespaces")
			Set tContent = $$$Text("Select a namespace on the right")			
		}
		Set tTab = ##class(%ZEN.Component.tab).%New()
		Set tTab.caption = ..EscapeHTML(tCaption)
		Set tTab.layout = "none"
		Set tTab.title = ""
		Do tLookout.%AddChild(tTab)

		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.enclosingClass = "category"
		Set tHTML.content = tContent
		Do tTab.%AddChild(tHTML)

		Quit $$$OK
	}

	// tCat(n)=$LB(id,caption,help)
	If ..mode="classes" {
		Set tCat(1) = $LB("classes",$$$Text("Classes"),$$$Text("Display class options"))
		Set tCat(2) = $LB("zen",$$$Text("Zen"),$$$Text("Display Zen options"))
	}
	ElseIf ..mode="classescontext" {
		Set tCat(1) = $LB("classescontext",$$$Text("Classes"),$$$Text("Display class options"))
		Set tCat(2) = $LB("zen",$$$Text("Zen"),$$$Text("Display Zen options"))
		Set ..currCategory = "localcontext"
	}
	ElseIf ..mode="cubes" {
		Set tCat(1) = $LB("cubes",$$$Text("DeepSee"),$$$Text("Display DeepSee options"))
		Set ..currCategory = "cubes"
	}
	ElseIf ..mode="vdoctype" {
		Set tCat(1) = $LB("vdoctype",$$$Text("Document Types"),$$$Text("Display Document Types"))
		Set ..currCategory = "vdoctype"
		Set ..extension = "vdoc"
	}
	ElseIf ..mode="bpl" {
		Set tCat(1) = $LB("bpl",$$$Text("BPL Business Processes"),$$$Text("Display BPL Business Process classes"))
		Set ..extension = "bpl"
	}
	ElseIf ..mode="bplplus" {
		Set tCat(1) = $LB("bplplus",$$$Text("Business Processes"),$$$Text("Display all Business Process classes"))
	}
	ElseIf ..mode="dtl" {
		Set tCat(1) = $LB("dtl",$$$Text("DTL Data Transforms"),$$$Text("Display DTL Data Transformation classes"))
		Set ..extension = "dtl"
	}
	ElseIf ..mode="dtlplus" {
		Set tCat(1) = $LB("dtlplus",$$$Text("Data Transforms"),$$$Text("Display all Data Transformation classes"))
	}
	ElseIf ..mode="persistent" {
		Set tCat(1) = $LB("classes",$$$Text("Classes"),$$$Text("Display class options"))
		Set ..currCategory = "persistent"
	}
	ElseIf ..mode="datatype" {
		Set tCat(1) = $LB("classes",$$$Text("Classes"),$$$Text("Display class options"))
		Set ..currCategory = "datatype"
	}
	ElseIf ..mode="request" {
		Set tCat(1) = $LB("classes",$$$Text("Classes"),$$$Text("Display class options"))
		Set ..currCategory = "request"
	}
	ElseIf ..mode="response" {
		Set tCat(1) = $LB("classes",$$$Text("Classes"),$$$Text("Display class options"))
		Set ..currCategory = "response"
	}
	ElseIf ((..mode="allmessages")) {
		Set tCat(1) = $LB("classes",$$$Text("Classes"),$$$Text("Display class options"))
		Set ..currCategory = "request" // arbitrarily choose request as the default selection
	}
	ElseIf ..mode="rules" {
		Set tCat(1) = $LB("rules",$$$Text("Business Rules"),$$$Text("Display Business Rules"))
		Set ..currCategory = "rules"
	}
	ElseIf ..mode="vdocclass" {
		Set tCat(1) = $LB("classes",$$$Text("Classes"),$$$Text("Display Virtual Document Classes"))
		Set ..currCategory = "classvdoc"
	}
	ElseIf ..mode="vdocschema" {
		Set tCat(1) = $LB("vdocschema",$$$Text("Exportable Schemas"),$$$Text("Display Virtual Document Schemas that can be exported"))
	}
	ElseIf ..mode="vdoccontents" {
		Set tCat(1) = $LB("vdoccontents",$$$Text("Virtual Properties"),$$$Text("Display Virtual Properties of the specified Virtual Document"))
	}
	ElseIf ..mode = "vdocsegtype" {
		Set tCat(1) = $LB("vdocsegtype",$$$Text("Segment Types"),$$$Text("Display Segment Types"))
	}
	ElseIf ..mode="vdocsegcontents" {
		Set tCat(1) = $LB("vdocsegcontents",$$$Text("Segment Properties"),$$$Text("Display Segment Properties"))
	}
	ElseIf ..mode="services" {
		Set tCat(1) = $LB("services",$$$Text("Business Service Classes"),$$$Text("Display all Business Service classes"))
	}
	ElseIf ..mode="operations" {
		Set tCat(1) = $LB("operations",$$$Text("Business Operation Classes"),$$$Text("Display all Business Operation classes"))
	}
	ElseIf ..mode = "lookups" {
		Set tCat(1) = $LB("lookups",$$$Text("Lookup Tables"),$$$Text("Display Lookup Tables"))
		Set ..extension = "lut"
	}
	ElseIf (..mode = "datasettings") {
		Set tCat(1) = $LB("datasettings",$$$Text("Deployable Settings"),$$$Text("Display Deployable Ensemble Setttings"))
		Set ..extension = "esd"
	}
	ElseIf ..mode = "configurations" {
		Set tCat(1) = $LB("configurations",$$$Text("Production Config Item definitions"),$$$Text("Display Config Items"))
		Set ..extension = "ptd"
	}
	ElseIf ..mode = "folderitems" {
		Set tCat(1) = $LB("folderitems",$$$Text("DeepSee Folder Items"),$$$Text("Display Dashboard definitions and other DeepSee folder items"))
		Set ..extension = "dfi"
	}
	ElseIf ..mode="sqlstored" {
		Set tCat(1) = $LB("sqlstored",$$$Text("Stored Procedures"),$$$Text("Display stored procedures"))
		Set ..currCategory = "sqlstored"
	}
	ElseIf ..mode="queries" {
		Set tCat(1) = $LB("queries",$$$Text("Query Procedures"),$$$Text("Display custom resultSet generators"))
		Set ..currCategory = "queries"
	}
	ElseIf ..mode="allqueries" {
		Set tCat(1) = $LB("allqueries",$$$Text("Query Procedures"),$$$Text("Display all resultSet generators"))
		Set ..currCategory = "allqueries"
	}
	ElseIf ..mode="querycontext" {
		Set tCat(1) = $LB("queries",$$$Text("Query Procedures"),$$$Text("Display resultSet generators"))
		Set ..currCategory = "queries"
	}
	ElseIf ..mode="prjfiles" {
		Set tCat(1) = $LB("prjfiles",$$$Text("Studio Project Files"),$$$Text("Display all Studio Project Files"))
	}
	Set k = $O(tCat(""))
	While (k'="") {
		Set tTab = ##class(%ZEN.Component.tab).%New()
		Set tTab.caption = $LG(tCat(k),2)
		Set tTab.layout = "none"
		Set tTab.title = $LG(tCat(k),3)
		Do tLookout.%AddChild(tTab)

		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.enclosingClass = "category"
		Set tHTML.OnDrawContent = "DrawCategories"
		Set tHTML.seed = $LG(tCat(k),1) // passed to DrawCategories method
		Do tTab.%AddChild(tHTML)
		Set k = $O(tCat(k))
	}

	Quit $$$OK
}

/// Get information to display in the category box.
Method OnGetCategoryInfo(pCategory As %String, Output pDisplay As %Boolean, Output pIcons As %List) As %Status
{
	Set pDisplay = 1
	
	If (..mode = "classes") {
		// id,caption,tooltip,icon
		If (pCategory = "classes") {
			Set pIcons(1) = $LB("local",$$$Text("Local"),$$$Text("Show all non-system classes in current namespace"),"portal/objects_48.gif")
			Set pIcons(2) = $LB("persistent",$$$Text("Persistent"),$$$Text("Show persistent classes"),"portal/table_48.gif")
			Set pIcons(3) = $LB("datatype",$$$Text("Datatype"),$$$Text("Show datatype classes"),"portal/text_field_48.gif")
			Set pIcons(4) = $LB("system",$$$Text("System"),$$$Text("Show classes in system library"),"portal/objects_config_48.gif")
		}
		ElseIf (pCategory = "zen") {
			Set pIcons(1) = $LB("zenpages",$$$Text("Pages"),$$$Text("Show zen page classes"),"portal/mini_sites_48.gif")
			Set pIcons(2) = $LB("zenapps",$$$Text("Applications"),$$$Text("Show zen application classes"),"portal/architecture_info_48.gif")
			Set pIcons(3) = $LB("zencomps",$$$Text("Components"),$$$Text("Show zen component classes"),"portal/redesign_48.gif")
			Set pIcons(4) = $LB("zenreports",$$$Text("Reports"),$$$Text("Show zen reports classes"),"portal/report_48.gif")
		}
	}
	ElseIf (..mode = "classescontext") {
		If (pCategory = "classescontext") {
			Set pIcons(1) = $LB("localcontext",$$$Text("Local"),$$$Text("Show all non-system classes in current namespace that can be context objects"),"portal/objects_48.gif")
			Set pIcons(2) = $LB("persistentcontext",$$$Text("Persistent"),$$$Text("Show persistent classes that can be context objects"),"portal/table_48.gif")
			Set pIcons(3) = $LB("datatypecontext",$$$Text("Datatype"),$$$Text("Show datatype classes that can be context objects"),"portal/text_field_48.gif")
			Set pIcons(4) = $LB("systemcontext",$$$Text("System"),$$$Text("Show classes in system library that can be context objects"),"portal/objects_config_48.gif")
		}
		ElseIf (pCategory = "zen") {
			Set pIcons(1) = $LB("zenpages",$$$Text("Pages"),$$$Text("Show zen page classes"),"portal/mini_sites_48.gif")
			Set pIcons(2) = $LB("zenapps",$$$Text("Applications"),$$$Text("Show zen application classes"),"portal/architecture_info_48.gif")
			Set pIcons(3) = $LB("zencomps",$$$Text("Components"),$$$Text("Show zen component classes"),"portal/redesign_48.gif")
			Set pIcons(4) = $LB("zenreports",$$$Text("Reports"),$$$Text("Show zen reports classes"),"portal/report_48.gif")
		}
	}
	ElseIf (..mode = "persistent") {
		Set pIcons(1) = $LB("persistent",$$$Text("Persistent"),$$$Text("Show persistent classes"),"portal/table_48.gif")
	}
	ElseIf (..mode = "datatype") {
		Set pIcons(1) = $LB("datatype",$$$Text("Datatype"),$$$Text("Show datatype classes"),"portal/text_field_48.gif")
	}
	ElseIf (..mode = "request") { // only request classes, persistent vdoc, or persistent classes (see EnsPortal.Utils for specific classes that get added or weeded out)
		Set pIcons(1) = $LB("request",$$$Text("Request Messages"),$$$Text("Show possible Request Message classes"),"portal/script_48.gif")
		Set pIcons(2) = $LB("persistentvdoc",$$$Text("Persistent VDoc"),$$$Text("Show persistent Virtual Document classes"),"deepsee/html_version_48.gif")
		Set pIcons(3) = $LB("persistentselect",$$$Text("Persistent Classes"),$$$Text("Show persistent classes that are more likely to be used in requests"),"portal/table_48.gif")
	}
	ElseIf (..mode = "response") { // only response classes, persistent vdoc, or persistent classes (see EnsPortal.Utils for specific classes that get added or weeded out)
		Set pIcons(1) = $LB("response",$$$Text("Response Messages"),$$$Text("Show possible Response Message classes"),"portal/script_48.gif")
		Set pIcons(2) = $LB("persistentvdoc",$$$Text("Persistent VDoc"),$$$Text("Show persistent Virtual Document classes"),"deepsee/html_version_48.gif")
		Set pIcons(3) = $LB("persistentselect",$$$Text("Persistent Classes"),$$$Text("Show persistent classes that are more likely to be used in responses"),"portal/table_48.gif")
	}
	ElseIf (..mode = "allmessages") { // only message classes, persistent vdoc, or persistent classes (see EnsPortal.Utils for specific classes that get added or weeded out)
		Set pIcons(1) = $LB("request",$$$Text("Request Messages"),$$$Text("Show possible Request Message classes"),"portal/script_48.gif")
		Set pIcons(2) = $LB("response",$$$Text("Response Messages"),$$$Text("Show possible Response Message classes"),"portal/script_48.gif")
		Set pIcons(3) = $LB("persistentvdoc",$$$Text("Persistent VDoc"),$$$Text("Show persistent Virtual Document classes"),"deepsee/html_version_48.gif")
		Set pIcons(4) = $LB("persistentselect",$$$Text("Persistent Classes"),$$$Text("Show persistent classes that are more likely to be used in requests"),"portal/table_48.gif")
	}
	ElseIf (..mode = "vdocclass") { // any message, any vdoc, or else any non-system class (a wider, less specific mode than "allmessages")
		Set pIcons(1) = $LB("messages",$$$Text("Message Classes"),$$$Text("Show Response and Request Message classes"),"portal/script_48.gif")
		Set pIcons(2) = $LB("classvdoc",$$$Text("Virtual Documents"),$$$Text("Show Virtual Document Classes"),"deepsee/html_version_48.gif")
		Set pIcons(3) = $LB("persistentselect",$$$Text("Persistent Classes"),$$$Text("Show persistent classes that may be used as messages"),"portal/table_48.gif")
		Set pIcons(4) = $LB("classselect",$$$Text("All Non-System Classes"),$$$Text("Show all non-system classes in current namespace"),"portal/objects_48.gif")
	}
	ElseIf (..mode = "services") {
		Set pIcons(1) = $LB("service",$$$Text("Businesss Service classes"),$$$Text("Show Businesss Service classes"),"portal/script_48.gif")
	}
	ElseIf (..mode = "operations") {
		Set pIcons(1) = $LB("operation",$$$Text("Businesss Operation classes"),$$$Text("Show Businesss Operation classes"),"portal/objects_48.gif")
	}
	ElseIf (..mode = "hosts") {
		Set pIcons(1) = $LB("service",$$$Text("Businesss Service classes"),$$$Text("Show Businesss Service classes"),"portal/script_48.gif")
		Set pIcons(2) = $LB("process",$$$Text("Businesss Process classes"),$$$Text("Show Businesss Process classes"),"deepsee/html_version_48.gif")
		Set pIcons(3) = $LB("operation",$$$Text("Businesss Operation classes"),$$$Text("Show Businesss Operation classes"),"portal/objects_48.gif")
	}
	ElseIf (..mode = "cubes") {
		Set pIcons(1) = $LB("cubes",$$$Text("Subject Areas"),$$$Text("Show DeepSee Subject Areas"),"portal/3D_design_48.gif")
	}
	ElseIf (..mode = "rules") {
		Set pIcons(1) = $LB("rules",$$$Text("Business Rules"),$$$Text("Show Business Rules"),"portal/3D_design_48.gif")
	}
	ElseIf (..mode = "vdoctype") {
		Set tClassName = ..category
		Try {
			Set tDocClassName = $classmethod(tClassName,"%GetParameter","DOCCLASSNAME")
		}
		Catch(ex) {
			Set tDocClassName = "Unknown"
		}
		Set pIcons(1) = $LB("vdoctype",..EscapeHTML(tDocClassName),$$$Text("Show Document Types"),"deepsee/html_version_48.gif")
	}
	ElseIf (..mode = "vdocschema") {
		Set pIcons(1) = $LB("vdocschema",$$$Text("Exportable Schemas"),$$$Text("Show Virtual Document Schemas that can be exported"),"portal/3D_design_48.gif")
	}
	ElseIf (..mode = "vdoccontents") {
		Set tSchemaName = $piece(..category,"|",2)
		If tSchemaName = "" { Set tSchemaName = $$$Text("Virtual Properties") }
		ElseIf $length(tSchemaName,":") > 1 {
			Set tSchemaLen = $length(tSchemaName,":")
			Set tSchemaName = ..EscapeHTML($piece(tSchemaName,":",1,tSchemaLen-1))_"<br/>"_..EscapeHTML($piece(tSchemaName,":",tSchemaLen))
		} Else {
			Set tSchemaName = ..EscapeHTML(tSchemaName)
		}
		Set pIcons(1) = $LB("vdoccontents",tSchemaName,$$$Text("Show Virtual Properties"),"portal/eye_chart_48.gif")
	}
	ElseIf (..mode = "vdocsegtype") {
		Set tClassName = ..category
		Try { Set tDocClassName = $classmethod(tClassName,"%GetParameter","DOCCLASSNAME") }
		Catch(ex) { Set tDocClassName = "Unknown" }
		Set pIcons(1) = $LB("vdocsegtype",..EscapeHTML(tDocClassName),$$$Text("Show Segment Types"),"portal/eye_chart_48.gif")
	}
	ElseIf (..mode = "vdocsegcontents") {
		Set tSegName = $piece(..category,"|",2)
		If tSegName = "" { Set tSegName = $$$Text("Unknown Segment") }
		ElseIf $length(tSegName,":") > 1 {
			Set tSegName = ..EscapeHTML($piece(tSegName,":",1))_"<br/>"_..EscapeHTML($piece(tSegName,":",2,$length(tSegName,":")))
		} Else {
			Set tSegName = ..EscapeHTML(tSegName)
		}
		Set pIcons(1) = $LB("vdocsegcontents",tSegName,$$$Text("Show Segment Properties"),"portal/eye_chart_48.gif")
	}
	ElseIf (..mode = "bpl") {
		Set pIcons(1) = $LB("bpl",$$$Text("BPL Business Processes"),$$$Text("Show BPL Business Process classes"),"portal/3D_design_48.gif")
	}	
	ElseIf (..mode = "bplplus") {
		Set pIcons(1) = $LB("bplplus",$$$Text("Business Processes"),$$$Text("Show all Business Process classes"),"portal/3D_design_48.gif")
	}
	ElseIf (..mode = "dtl") {
		Set pIcons(1) = $LB("dtl",$$$Text("DTL Data Transforms"),$$$Text("Show DTL Data Transformation classes"),"portal/3D_design_48.gif")
	}
	ElseIf (..mode = "dtlplus") {
		Set pIcons(1) = $LB("dtlplus",$$$Text("Data Transforms"),$$$Text("Show all Data Transformation classes"),"portal/3D_design_48.gif")
	}
	ElseIf (..mode = "folderitems") {
		Set pIcons(1) = $LB("dashboards",$$$Text("Dashboards"),$$$Text("Show all DeepSee Dashboard folder items"),"portal/3D_design_48.gif")
	}
	ElseIf (..mode = "sqlstored") {
		Set pIcons(1) = $LB("sqlstored",$$$Text("SQL Stored Procedures"),$$$Text("Show SQL Stored Procedures"),"portal/script_48.gif")
	}
	ElseIf (..mode = "queries") {
		Set pIcons(1) = $LB("queries",$$$Text("SQL Query Procedures"),$$$Text("Show SQL Procedures that return resultSets"),"portal/script_48.gif")
	}
	ElseIf (..mode = "allqueries") {
		Set pIcons(1) = $LB("allqueries",$$$Text("All SQL Query Procedures"),$$$Text("Show all SQL Procedures that return resultSets"),"portal/script_48.gif")
	}
	ElseIf (..mode = "views") {
		Set pIcons(1) = $LB("views",$$$Text("SQL Views"),$$$Text("Show all SQL Views that return resultSets"),"portal/script_48.gif")
	}
	ElseIf (..mode = "querycontext") {
		Set pIcons(1) = $LB("queries",$$$Text("Extent Filtered SQL Query Procedures"),$$$Text("Show SQL Procedures that return resultSets except basic extent queries"),"portal/script_48.gif")
		Set pIcons(2) = $LB("allqueries",$$$Text("All SQL Query Procedures"),$$$Text("Show All SQL Procedures that return resultSets"),"portal/script_48.gif")
		Set pIcons(3) = $LB("views",$$$Text("SQL Views"),$$$Text("Show all SQL Views that return resultSets"),"portal/script_48.gif")
	}

	ElseIf (..mode = "prjfiles") {
		Set pIcons(1) = $LB("prjfiles",$$$Text("Studio Project Files"),$$$Text("Show Studio Project Files"),"portal/software_development_48.gif")
	}
	Quit $$$OK
}

/// Avoid writing out the session cookie if we are in a Studio session.
ClassMethod OnPreHyperEvent(class As %String, method As %String) As %Status [ ServerOnly = 1 ]
{
	If $get(%session.Data("Ensemble","StudioSession",$namespace)) Set %response.OutputSessionToken = 0
	Quit ##super(class,method)
}

Method %OnDrawHTMLHead() As %Status
{
	If $get(%session.Data("Ensemble","StudioSession",$namespace)) && ##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
		Set tSC = ##class(EnsPortal.Template.base).%AddCSPShareHyperevents()
		If $$$ISERR(tSC) Quit tSC
		&html<<script type="text/javascript">
var useSharedHyperevents = true;
</script>>
	}
	Quit ##super()
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (window.useSharedHyperevents && window.cspIntHttpServerMethod && window.studioIntHttpServerMethod && !this._forceHypereventShare) {
		window.cspIntHttpServerMethod = window.studioIntHttpServerMethod;
		this._forceHypereventShare = true;
	}
}

}
