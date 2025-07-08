/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Quality Measure manager page.
Class %DeepSee.UI.QualityMeasures Extends (%DeepSee.UI.standardPage, %CSP.Portal.SourceControl.Base) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Quality Measures Manager";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE;

Parameter DOCBOOKID = "D2MODADV_ch_qualmeas";

Parameter RESOURCE = "%DeepSee_PortalEdit";

/// Name of Quality Measure we are looking at (without extension).
Property qmsrName As %ZEN.Datatype.string(ZENURL = "QMSR");

/// Name of class that defines the Quality Measure.
Property qmsrClass As %ZEN.Datatype.string;

/// If true, then show edit controls.
Property editMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, then show list of catalogs etc.
Property browseMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Local copy of qmsr model object.
Property %model As %DeepSee.Model.QualityMeasure.qualityMeasure;

/// This Style block contains page-specific CSS 3 style definitions.
XData CSS3Style
{
<style type="text/css">

body {
	overflow: hidden;
}

.modalGroup {
	border: 1px solid #808080;
	background: rgba(53,107,141,0.9);
}

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}
.zenLabelDisabled {
	font-size: 10pt;
}

a.radioSetCaption,
.mgLabel {
	color: rgb(227,227,227);
	font-size: 10pt;
}

table td.mdtLabel {
	padding-top: 10px;
	font-size: 12pt;
	font-weight: bold;
	color: #404040;
}

table td.mdtValue {
	font-size: 10pt;
	color: #606060;
	padding-left: 0px;
}

table td.mdtExpr {
	font-family: courier new;
	font-size: 22pt;
	font-weight: bold;
	color: #606060;
}

td.mdtLabel a {
	font-weight: normal;
	color: #606080;
	text-decoration: none;
}

li.popItem {
	font-size: 12pt;
	color: #606060;
}

.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}

#mainGroup {
	transition-property: opacity;
	transition-duration: 0.25s;
	transition-timing-function: ease;
}

.navDiv, .navDivEven,.navDivCurrent {
	transition-property: background;
	transition-duration: 0.25s;
	transition-timing-function: ease;
}

#mainGroup {
	overflow: hidden;
	border-bottom: 1px solid #F0F0F0;
	opacity: 0.0;
}

#qmsrDetails {
	padding-left: 10px;
	padding-right: 10px;
	overflow: auto;
	border-left: 1px solid #F0F0F0;
}

#qmsrNavigator {
	width: 250px;
	padding-left: 0px;
	padding-right: 0px;
	overflow-y: auto;
	opacity: 0.8;
}

#qmsrHelp {
	width: 250px;
	padding-left: 0px;
	padding-right: 0px;
	border-left: 1px solid #A0A0A0;
	background: #E0E0E0;
}

.divHelpTitle {
	padding: 10px;
	font-size: 14pt;
	color: #404040;
}

.divHelp {
	padding: 10px;
	font-size: 10pt;
	color: #404040;
}

.divHelpItem {
	margin-bottom: 5px;
}

.navTitle {
	padding-left: 10px;
	padding-right: 10px;
	color: #404040;
	font-size: 12pt;
	padding: 3px;
}

.navList {
	padding-left: 10px;
	padding-right: 10px;
	border-bottom: 1px solid #F0F0F0;
}

.navDiv,.navDivEven {
	border: 2px solid white;
}

.navDivEven {
	background: #F8F8F8;
}

.navDivCurrent {
	border: 2px solid #8080D0;
	background: rgb(148,190,221);
}

.navItem {
	color: #404040;
	font-size: 10pt;
	padding: 2px;
}

.navList a {
	color: #404040;
	display: block;
	text-decoration: none;
}

.navDiv:hover,
.navDivEven:hover,
.navDivCurrent:hover {
	background: #FFEEAA;
}

.navItemText {
	color: #606060;
	font-size: 10pt;
	padding: 2px;
	padding-bottom: 5px;
}

.browseDiv {
	background: #F0F0F0;
}
.browseCatalog {
	margin-top: 10px;
	color: #606080;
	font-size: 18pt;
	padding: 2px;
	background: #E0E0F8;
	border-top: 1px solid #B0B0D0;
	border-bottom: 1px solid #B0B0D0;
}

.browseSet {
	color: #606060;
	font-size: 12pt;
	padding: 2px;
}

.browseItems {
	overflow: auto;
}

.browseItem {
	color: #606060;
	font-size: 10pt;
	padding: 2px;
	float: left;
	text-decoration: none;
	font-size: 10pt;
	overflow: hidden;
	overflow-y: auto;
	color: black;
	text-align: center;
	margin: 1px;
	padding: 1px;
	width: 200px;
	height: 90px;
	border: 1px solid #808080;
	border-radius: 2px;
	box-shadow: 2px 2px 2px #A0A0A0;
	color: #404040;
	background: white;
}

.browseItem a {
	color: darkblue;
}
</style>
}

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

body {
	overflow: hidden;
}

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}
.zenLabelDisabled {
	font-size: 10pt;
}

a.radioSetCaption,
.mgLabel {
	color: rgb(227,227,227);
	font-size: 10pt;
}

table td.mdtLabel {
	padding-top: 10px;
	font-size: 12pt;
	font-weight: bold;
	color: #404040;
}

table td.mdtValue {
	font-size: 10pt;
	color: #606060;
	padding-left: 0px;
}

table td.mdtExpr {
	font-family: courier new;
	font-size: 22pt;
	font-weight: bold;
	color: #606060;
}

td.mdtLabel a {
	font-weight: normal;
	color: #606080;
	text-decoration: none;
}

li.popItem {
	font-size: 12pt;
	color: #606060;
}

.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}

#mainGroup {
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.navDiv, .navDivEven,.navDivCurrent {
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

#mainGroup {
	overflow: hidden;
	border-bottom: 1px solid #F0F0F0;
	opacity: 0.0;
}

#qmsrDetails {
	padding-left: 10px;
	padding-right: 10px;
	overflow: auto;
	border-left: 1px solid #F0F0F0;
}

#qmsrNavigator {
	width: 250px;
	padding-left: 0px;
	padding-right: 0px;
	overflow-y: auto;
	opacity: 0.8;
}

#qmsrHelp {
	width: 250px;
	padding-left: 0px;
	padding-right: 0px;
	border-left: 1px solid #A0A0A0;
	background: #E0E0E0;
}

.divHelpTitle {
	padding: 10px;
	font-size: 14pt;
	color: #404040;
}

.divHelp {
	padding: 10px;
	font-size: 10pt;
	color: #404040;
}

.divHelpItem {
	margin-bottom: 5px;
}

.navTitle {
	padding-left: 10px;
	padding-right: 10px;
	color: #404040;
	font-size: 12pt;
	padding: 3px;
}

.navList {
	padding-left: 10px;
	padding-right: 10px;
	border-bottom: 1px solid #F0F0F0;
}

.navDiv,.navDivEven {
	border: 2px solid white;
}

.navDivEven {
	background: #F8F8F8;
}

.navDivCurrent {
	border: 2px solid #8080D0;
	background: rgb(148,190,221);
}

.navItem {
	color: #404040;
	font-size: 10pt;
	padding: 2px;
}

.navList a {
	color: #404040;
	display: block;
	text-decoration: none;
}

.navDiv:hover,
.navDivEven:hover,
.navDivCurrent:hover {
	background: #FFEEAA;
}

.navItemText {
	color: #606060;
	font-size: 10pt;
	padding: 2px;
	padding-bottom: 5px;
}

.browseDiv {
	background: #F0F0F0;
}
.browseCatalog {
	margin-top: 10px;
	color: #606080;
	font-size: 18pt;
	padding: 2px;
	background: #E0E0F8;
	border-top: 1px solid #B0B0D0;
	border-bottom: 1px solid #B0B0D0;
}

.browseSet {
	color: #606060;
	font-size: 12pt;
	padding: 2px;
}

.browseItems {
	overflow: auto;
}

.browseItem {
	color: #606060;
	font-size: 10pt;
	padding: 2px;
	float: left;
	text-decoration: none;
	font-size: 10pt;
	overflow: hidden;
	overflow-y: auto;
	color: black;
	text-align: center;
	margin: 1px;
	padding: 1px;
	width: 200px;
	height: 90px;
	border: 1px solid #808080;
	border-radius: 2px;
	box-shadow: 2px 2px 2px #A0A0A0;
	color: #404040;
	background: white;
}

.browseItem a {
	color: darkblue;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee">

<!-- qmsr model as JSON -->
<jsonProvider id="model"
	OnGetTargetObject="GetQMsrDefinition"
	OnSubmitContent="SubmitQMsr"
/>

<!-- list of all qmsrs as JSON -->
<jsonProvider id="list"
	OnGetArray="GetQMsrList"
/>

<hgroup id="mainGroup" cellVAlign="top">
<html id="qmsrNavigator" OnDrawContent="DrawNavigator"/>
<html id="qmsrDetails" />
<html id="qmsrHelp" OnDrawContent="DrawHelp"/>
</hgroup>

<!-- popup edit forms -->
<modalGroup id="mgMeta" groupTitle="Meta" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="Name" id="metaName" labelClass="mgLabel"/>
<text label="Caption" id="metaCaption" labelClass="mgLabel"/>
<textarea label="Content" id="metaContent" rows="8" cols="80" labelClass="mgLabel"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgCaption" groupTitle="Caption" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="Caption" id="msrCaption" labelClass="mgLabel" size="40"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgDescription" groupTitle="Description" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<textarea label="Description" id="msrDescription" labelClass="mgLabel" rows="3" cols="40"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgGroup" groupTitle="Group" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="Name" id="metaGroupName" labelClass="mgLabel"/>
<textarea label="Description" id="metaGroupDescription" rows="2" cols="80" labelClass="mgLabel"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgElement" groupTitle="Element" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="Name" id="metaElementName" labelClass="mgLabel"/>
<text label="MDX Expression" id="metaElementExpression" labelClass="mgLabel" size="40" controlStyle="font-size:15pt;"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgSubjectArea" groupTitle="Subject Area" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="Subject Area" id="metaSubjectArea" labelClass="mgLabel" size="30" controlStyle="font-size:20pt;"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgMeasure" groupTitle="Measure" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="Expression" id="metaExpression" labelClass="mgLabel" size="40" controlStyle="font-size:20pt;"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgFormat" groupTitle="Format" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="Format String" id="metaFormat" labelClass="mgLabel" size="40" controlStyle="font-family:courier new;"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgHREF" groupTitle="Link" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<text label="URL of link" id="metaHREF" labelClass="mgLabel" size="40" controlStyle="font-size:15pt;"/>
<spacer height="10"/>
<button caption="OK" onclick="zenPage.applyChange();"/>
</modalGroup>

<modalGroup id="mgPublished" groupTitle="Published" cellStyle="padding:3px;padding-left:40px;padding-right:40px;">
<spacer height="10"/>
<radioSet id="metaPublished" label="Publish this measure?" valueList="1,0" displayList="Yes,No"  labelClass="mgLabel" onchange="zenPage.applyChange();"/>
<spacer height="10"/>
</modalGroup>

</pane>
}

/// Return JSON array of qmeasures.
Method GetQMsrList(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMetaData = $LB("name","caption")

		If ('..browseMode) Quit

		Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureList(.tList)
		If $$$ISERR(tSC) Quit

		Set k = $O(tList(""))
		While (k'="") {
			Set pData($I(n)) = $LB($LG(tList(k),1),$LG(tList(k),5))
			Set k = $O(tList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get QMsr definition for JSON provider.
Method GetQMsrDefinition(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		If $IsObject(..%model) {
			Set pObject = ..%model
		}
		ElseIf (..qmsrName'="") {
			If ('##class(%DeepSee.QualityMeasure.Utils).%QualityMeasureExists(..qmsrName, .tSC)) {
				Set ..%model = ""
				Set tSC = $$$OK
				Quit
			}
			Set pObject = ##class(%DeepSee.QualityMeasure.Utils).%GetModel(..qmsrName, .tSC,1)
			If $$$ISERR(tSC) Quit
			If $$$ISOK(tSC) && $IsObject(pObject) {
				If ..IsSourceControlReadOnly(..GetInternalName()) {
					Set pObject.ReadOnly = 2
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the quality measures details pane.
Method DrawNavigator(pSeed As %String) As %Status
{
	If (..browseMode) {
		Set tMsg = $$$TextHTML("The complete set of available measures are displayed on the right.")

		&html<<div class="navList" onmouseover="zen('qmsrNavigator').getEnclosingDiv().style.opacity=1.0;" onmouseout="zen('qmsrNavigator').getEnclosingDiv().style.opacity='';">>
		&html<<div class="navItemText">#($ZCVT(tMsg,"O","HTML"))#</div>>
		&html<</div>>
	}
	ElseIf (..qmsrName'="") {
		Set tCatalog = $P(..qmsrName,"/",1)
		Set tSet = $P(..qmsrName,"/",2)

		// List of measures in this set
		Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureList(.tList,tCatalog,tSet)
		If $$$ISERR(tSC) Quit tSC

		Set tMsg = $$$TextHTML("Other measures within this set")


		&html<<div class="navList" onmouseover="zen('qmsrNavigator').getEnclosingDiv().style.opacity=1.0;" onmouseout="zen('qmsrNavigator').getEnclosingDiv().style.opacity='';">>

		If $D(tList) {
			&html<<div class="navItemText">#($ZCVT(tMsg,"O","HTML"))#</div>>
		}

		Set n = 0
		Set k = $O(tList(""))
		While (k'="") {
			Set n = n + 1
			Set tName = $LG(tList(k),1)
			Set tCaption = $LG(tList(k),2)
			Set tText = $LG(tList(k),5)
			Set tCls = $S(tName=..qmsrName:"navDivCurrent",(n#2):"navDiv",1:"navDivEven")
			&html<<div class="#(tCls)#" onclick="zenPage.loadMeasure('#($ZCVT(tName,"O","JS"))#')">>
			&html<<div class="navItem">#($ZCVT(tCaption,"O","HTML"))#</div>>
			&html<<div class="navItemText">#($ZCVT(tText,"O","HTML"))#</div>>
			&html<</div>>
			Set k = $O(tList(k))
		}
		&html<</div>>
	}
	Quit $$$OK
}

/// Draw the "help" pane. This displays help on the current selection.
Method DrawHelp(pSeed As %String) As %Status
{
	&html<<div class="divHelpTitle"><image src="portal/binocular_48.gif"/></div>>

	&html<<div class="divHelp">>

	Set tMsg($I(n)) = $$$Text("The Quality Measure Manager displays the catalog of quality measures.")

	If (..browseMode) {
		Set tMsg($I(n)) = $$$Text("Select a quality measure in the list to view its details.")
	}
	ElseIf (..editMode) {

		Set tMsg($I(n)) = $$$FormatText($$$Text("Press %1 to edit a specific detail."),"<image src=""deepsee/notepad_16.png""/>")

		Set tMsg($I(n)) = $$$Text("Press View to go back to viewing to this quality measure.")
		Set tMsg($I(n)) = $$$Text("Press Save to save the changes to this quality measure.")
	}
	ElseIf (..qmsrName'="") {
		Set tMsg($I(n)) = $$$Text("Press Edit to edit the details of this quality measure.")
	}
	Else {
		Set tMsg($I(n)) = $$$Text("Press Browse to see a list of available measures.")
		Set tMsg($I(n)) = $$$Text("Press Open to find a specific quality measure.")
	}

	Set k = $O(tMsg(""))
	While (k'="") {
		&html<<div class="divHelpItem">#(tMsg(k))#</div>>
		Set k = $O(tMsg(k))
	}
	&html<</div>>
	Quit $$$OK
}

/// Return the internal name of the current document, including the three letter
/// extension in upper-case. For example, MyPackage.MyClass.CLS would be the internal name
/// for the class MyPackage.MyClass.
Method GetInternalName() As %String
{
	Quit ..qmsrClass_".CLS"
}

/// Return the current name of the class/object being modified.
ClientMethod getCurrentName() [ Language = javascript ]
{
	return this.qmsrClass
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return this.getCurrentName();
}

/// Get the jsonProvider object on the client.
ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('model');
}

/// Callback method invoked after we have successfully loaded the current document.
ClientMethod onDocumentLoadComplete() [ Language = javascript ]
{
	this.updateDocumentState(true);
}

/// This callback is called at the end of the HTML HEAD section of the page.<br/>
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = ..%DrawSourceControlHead()
	Quit tSC
}

/// Draw additional stuff in the ribbon bar
Method OnDrawRibbon() As %Status
{
	Quit ..%DrawSourceControlCommands()
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit ..qmsrName
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Quality Measure Manager","%DeepSee")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Quality Measure Manager")

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdBrowse",$$$Text("Browse"),$$$Text("Browse the catalog of quality measures"),"zenPage.browse();")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Open an existing quality measure"),"zenPage.changeMeasure();")
	Set pCommands(3) = $LB("cmdEdit",$$$Text("Edit"),$$$Text("Edit this quality measure"),"zenPage.editMeasure();")
	Set pCommands(4) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new quality measure"),"zenPage.newMeasure();")
	Set pCommands(5) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save changes to this quality measure"),"zenPage.saveMeasure(false);")
	Set pCommands(6) = $LB("cmdSaveAs",$$$Text("Save As"),$$$Text("Save a copy of this quality measure"),"zenPage.saveMeasure(true);")
	Set pCommands(7) = $LB("cmdRemove",$$$Text("Remove"),$$$Text("Delete this quality measure"),"zenPage.deleteMeasure();")
	Quit $$$OK
}

/// Launch the quality measure finder dialog.
ClientMethod changeMeasure() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=qualityMeasures','QualityMeasure','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the subject area finder dialog.
ClientMethod changeSubjectArea() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=subjectAreas','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the master quality measure finder dialog.
ClientMethod changeLinkedTo() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=qualityMeasures','LinkedTo','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Add check to ensure that we correctly load documents on the client when source control hooks are in use.
/// Also set up a timer to ensure we don't hit timeouts while editing documents in Studio, as well as
/// When in Studio mode, also detect whether we are running IE10, as we need to save documents differently if that
/// is the case.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.initializeSourceControl();
	if (this.readOnly) {
		this.disableCommandButton("cmdEdit");
		this.disableCommandButton("cmdSave");
		this.disableCommandButton("cmdSaveAs");
		this.disableCommandButton("cmdRemove");
	}
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			var btn = self.document.getElementById('command_cmdRemove');
			if (btn) {
				btn.className = 'commandButtonRemove';
			}
			this.renderDetails();
			
			// reveal
			zen('mainGroup').getEnclosingDiv().style.opacity = 1.0;
		}
		this.adjustSizes();

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var details = zen('qmsrDetails');
		var divDetails = details.getEnclosingDiv();

		var nav = zen('qmsrNavigator');
		var divNav = nav.getEnclosingDiv();

		var other = zen('qmsrHelp');
		var divOther = other.getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var cwid = winWidth - (divNav.offsetWidth + divOther.offsetWidth) - 25;
		var chgt = winHeight - th - 75;

		// we need these commands or Chrome will make the title area too big
		// when initially displayed (on this page only)
		// (which is kind of disappointing)
		var tdiv = zen('title').getEnclosingDiv();
		tdiv.style.width = winWidth + 'px';

		divDetails.style.width = cwid + 'px';
		divDetails.style.height = chgt + 'px';
		divNav.style.height = chgt + 'px';
		divOther.style.height = chgt + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// make sure soft modals are on
		Set ..useSoftModals = 1

		Set tSC = ##super()
		If $$$ISERR(tSC) Quit

		// check privileges
		If (..qmsrName = "") {
			Set ..qmsrName = $G(^DeepSee.LastQMSR($UserName))
		}

		// Does measure exist?
		If ('##class(%DeepSee.QualityMeasure.Utils).%QualityMeasureExists(..qmsrName, .tSCX)) {
			Set ..qmsrName = ""
			Set ..%model = ##class(%DeepSee.Model.QualityMeasure.qualityMeasure).%New()
			Set ..%model.published = 0
			Quit
		}

		Set ..qmsrClass = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureClass(..qmsrName, .tSCX)
		If $$$ISERR(tSC) Quit

		Set ..%model = ##class(%DeepSee.QualityMeasure.Utils).%GetModel(..qmsrName, .tSC, 1)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'QMsrSave':
		var json = zen('model');
		var model = json.getContentObject();
		var changed = false;

		// clear out model
		if (this._isNew) {
			model.caption = 'New Quality Measure';
			model.description = '';
			model.expression = '[Numerator]/[Denominator]';
			model.metas = [];
			model.groups = [
{
_class:'%DeepSee.Model.QualityMeasure.group',
caption:"",
description:"Numerator",
disabled:false,
elements:[
{
_class:'%DeepSee.Model.QualityMeasure.element',
caption:"",
disabled:false,
group:null,
mdx:"100",
name:"Numerator Cohort"
}],
name:"Numerator",
qualityMeasure:null
},
{
_class:'%DeepSee.Model.QualityMeasure.group',
caption:"",
description:"Denominator",
disabled:false,
elements:[
{
_class:'%DeepSee.Model.QualityMeasure.element',
caption:"",
disabled:false,
group:null,
mdx:"100",
name:"Denominator Cohort"
}],
name:"Denominator",
qualityMeasure:null
}
			];
		}

		// test for name change
		if (this._isNew || model.name!=this.qmsrName) {
			changed = true;
			model.name = this.qmsrName;
			var t = model.name.toString().split('/');
			model.catalog = t[0];
			model.set = t[1];
			model.id = t[2];
		}
		/// call source control save method
		var ok = this.saveDocument();
		if (ok) {
			this.setModified(false);
		}
		
		if (changed) {
			this.loadMeasure(this.qmsrName,true);
		}
		this._isNew = false;
		break;
	case 'QualityMeasure':
		// pull extension off of name
		var name = '';
		var s = value.toString().split('.');
		if ('qmsr' == s[s.length-1]) {
			s.length = s.length-1;
			name = s.join('.');
			this.loadMeasure(name);
		}
		break;
	case 'SubjectArea':
		// pull extension off of name
		var isCube = true;
		var name = '';
		var s = value.toString().split('.');
		if ('cube' == s[s.length-1]) {
			s.length = s.length-1;
			name = s.join('.');
			isCube = true;
		}
		else if ('subjectArea' == s[s.length-1]) {
			s.length = s.length-1;
			name = s.join('.');
			isCube = false;
		}
		var model = zen('model').getContentObject();
		if (model.subjectArea != name) {
			model.subjectArea = name;
			this.renderDetails();
			this.setModified(true);
		}
		break;

	case 'LinkedTo':
		// remove .qmsr
		if (value) {
			var t = value.toString().split('.');
			t.length--;
			value = t.join('.');
		}

		var model = zen('model').getContentObject();
		if (model.linkedTo != value) {
			var ok = false;
			if (value) {
				ok = confirm($$$FormatText($$$Text('Do you wish to link this measure to %1?','%DeepSee'),value));
			}
			else {
				ok = confirm($$$FormatText($$$Text('Do you wish to unlink this measure from %1?','%DeepSee'),model.linkedTo));
			}
			if (ok) {	
				model.linkedTo = value;
				this.onPopupAction('QMsrSave','ok','');

				// reload
				self.document.location = zenLink('_DeepSee.UI.QualityMeasures.zen?QMSR=' + encodeURIComponent(this.qmsrName));
			}
		}
		break;

	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.QualityMeasures.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		self.document.location = url;
		break;		
	}
}

/// Display a different measure.
ClientMethod loadMeasure(name, force) [ Language = javascript ]
{
	force = zenGet(force,false);
	force = true;
	if (!force && this.qmsrName == name) {
		return;
	}

	this.browseMode = false;
	if (this.editMode) {
		// stop edit
		this.editMeasure();
	}

	this.qmsrName = name;
	this.qmsrClass = this.GetClassName(name);
	zen('model').reloadContents();
	this.renderDetails();
	zen('qmsrNavigator').refreshContents();
	zen('qmsrHelp').refreshContents();

	zen('qmsrNavigator').getEnclosingDiv().scrollTop = 0;
	zen('qmsrDetails').getEnclosingDiv().scrollTop = 0;

	this.setTitleText();
}

/// Set content of title bar.
ClientMethod setTitleText() [ Language = javascript ]
{
	// update title bar
	var title = this.getPageTitle();
	this.setPageTitle(title);
	this.setModified(this.pageModified);
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	return true
}

/// Change in search box value. Can be overridden by subclasses.
ClientMethod searchBoxHandler(searchKey) [ Language = javascript ]
{
	this.searchKey = searchKey;
}

/// Update the details pane.
ClientMethod updateList() [ Language = javascript ]
{
	this.renderDetails();
}

/// Set browse mode.
ClientMethod browse() [ Language = javascript ]
{
	if (!this.browseMode) {
		this.browseMode = true;
		this.setTitleText();
		zen('list').reloadContents();

		zenPage.renderDetails();
		zen('qmsrNavigator').refreshContents();
		zen('qmsrHelp').refreshContents();
	}
}

/// Start/stop edit mode.
ClientMethod editMeasure() [ Language = javascript ]
{
	if (this.qmsrName=='') {
		alert($$$Text('Please load a quality measure.'));
		return;
	}
	var btn = self.document.getElementById('command_cmdEdit');
	if (this.editMode) {
		this.editMode = false;
		btn.innerHTML = $$$Text('Edit');
	}
	else {
		this.editMode = true;
		btn.innerHTML = $$$Text('View');
	}
	this.updateList();
	zen('qmsrHelp').refreshContents();
}

/// Create a new quality measure.
ClientMethod newMeasure() [ Language = javascript ]
{
	this._isNew = true;
	
	// show save dialog
	var parms = {
			NEW:1,
			QMSR:'',
			QMSRCLASS:''
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.QualityMeasureSave.zen','QMsrSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Save measure.
ClientMethod saveMeasure(showDialog) [ Language = javascript ]
{
	this._isNew = (this.qmsrName==='');

	if (this.browseMode) {
		alert($$$Text('Please load a quality measure.'));
		return;
	}

	if (showDialog || this.qmsrName==='') {
		// show save dialog
		var parms = {
				QMSR:this.qmsrName,
				QMSRCLASS:this.qmsrClass
				};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.QualityMeasureSave.zen','QMsrSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
	}
	else {
		this.onPopupAction('QMsrSave','ok','');
	}
}

/// Delete measure.
ClientMethod deleteMeasure() [ Language = javascript ]
{
	if (!confirm($$$Text('Do you wish to delete this Quality Measure?'))) {
		return;
	}

	var msg = this.DeleteQMeasure(this.qmsrName);
	if (msg != '') {
		alert(msg);
	}

	// reload
	self.document.location = zenLink('_DeepSee.UI.QualityMeasures.zen?QMSR=' + encodeURIComponent(this.qmsrName));
}

/// Find the class name for the qmsr.
ClassMethod GetClassName(pName As %String) As %String [ ZenMethod ]
{
	Quit ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureClass(pName)
}

/// Delete the given qmsr.
ClassMethod DeleteQMeasure(pName As %String) As %String [ ZenMethod ]
{
	Set tClass = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureClass(pName)
	If (tClass'="") {
		Do $System.OBJ.Delete(tClass,"-d")
	}
	Else {
		Quit $$$Text("Measure not found! ") _ pName
	}
	Quit $$$Text("Measure deleted")
}

/// Object submit handler JSON provider.
/// This is called when the client submits the qmsr definition.
Method SubmitQMsr(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tClass = ..qmsrClass
		If (tClass="") {
			Set tSC = $$$ERROR($$$GeneralError,"Class name is required for Quality Measure")
			Quit
		}

		Set tDomain = "" // ..cubeDomain
		Set tDesc = ""
		Set tReadOnly = 0

		If (pCommand '= "forcesave") && ##class(%Dictionary.ClassDefinition).%ExistsId(tClass) {
			Set tSC = ..LoadClassDefinition(tClass,.tModelDef,.tReadOnly,1)
			If $$$ISERR(tSC) Quit
			If $zdatetime(tModelDef.TimeChanged,3,,6) '= pSubmitObject.Timestamp {
				Set pProvider.error = "timestamp"
				Quit
			}
		}

		// Save (and compile) the class definition
		Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%SaveQMsrDefinition(tClass,"",tDesc,pSubmitObject,tDomain)

		If $$$ISERR(tSC) Quit
		// send up-to-date model back to client, this should include updated timestamp
		Set pResponseObject = pSubmitObject
		// correct the ReadOnly flag on the response object
		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set pResponseObject.ReadOnly = 2
		}
		Else {
			Set pResponseObject.ReadOnly = tReadOnly
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Edit the given value.
ClientMethod editValue(id) [ Language = javascript ]
{
	var main = id.toString().split(';')[0];
	var name = main.toString().split(':')[0];
	var idx = main.toString().split(':')[1];

	var model = zen('model').getContentObject();
	this._currId = id;

	switch(name) {
	case 'caption':
		zen('msrCaption').setValue(model.caption);
		zen('mgCaption').show();
		break;
	case 'description':
		zen('msrDescription').setValue(model.description);
		zen('mgDescription').show();
		break;
	case 'expression':
		zen('metaExpression').setValue(model.expression);
		zen('mgMeasure').show();
		break;
	case 'format':
		zen('metaFormat').setValue(model.format);
		zen('mgFormat').show();
		break;
	case 'href':
		zen('metaHREF').setValue(model.href);
		zen('mgHREF').show();
		break;

	case 'subjectArea':
		this.changeSubjectArea();
		//zen('metaSubjectArea').setValue(model.subjectArea);
		//zen('mgSubjectArea').show();
		break;

	case 'linkedTo':
		this.changeLinkedTo();
		//zen('metaSubjectArea').setValue(model.subjectArea);
		//zen('mgSubjectArea').show();
		break;

	case 'group':
		var group = model.groups[idx];
		if (group) {
			zen('metaGroupName').setValue(group.name);
			zen('metaGroupDescription').setValue(group.description);
			zen('mgGroup').show();
		}
		break;

	case 'element':
		var main2 = id.toString().split(';')[1];
		var name2 = main2.toString().split(':')[0];
		var idx2 = main2.toString().split(':')[1];
		var group = model.groups[idx2];
		if (group) {
			var element = group.elements[idx];
			if (element) {
				zen('metaElementName').setValue(element.name);
				zen('metaElementExpression').setValue(element.mdx);
				zen('mgElement').show();
			}
		}
		break;

	case 'meta':
		var meta = model.metas[idx];
		if (meta) {
			// caption, content
			zen('metaName').setValue(meta.name);
			zen('metaCaption').setValue(meta.caption);
			zen('metaContent').setValue(meta.content);
			zen('mgMeta').show();
		}
		break;
	case 'published':
		zen('metaPublished').setValue(model.published?1:0);
		zen('mgPublished').show();
		break;
	default:
		alert('Unknown name: ' + name);
		break;
	}
}

/// Delete the given item.
ClientMethod deleteItem(id) [ Language = javascript ]
{
	var main = id.toString().split(';')[0];
	var name = main.toString().split(':')[0];
	var idx = main.toString().split(':')[1];

	var model = zen('model').getContentObject();
	this._currId = id;

	if (!confirm($$$Text('Do you wish to delete this item?'))) {
		return;
	}

	switch(name) {
	case 'group':
		model.groups.splice(idx,1);
		break;

	case 'element':
		var main2 = id.toString().split(';')[1];
		var name2 = main2.toString().split(':')[0];
		var idx2 = main2.toString().split(':')[1];
		var group = model.groups[idx2];
		if (group) {
			group.elements.splice(idx,1);
		}
		break;

	case 'meta':
		model.metas.splice(idx,1);
		break;
	default:
		break;
	}

	this.renderDetails();
	this.setModified(true);
}

/// Move the given item.
ClientMethod moveItem(id, up) [ Language = javascript ]
{
	var main = id.toString().split(';')[0];
	var name = main.toString().split(':')[0];
	var idx = parseInt(main.toString().split(':')[1]);

	var model = zen('model').getContentObject();
	this._currId = id;
	var moved = false;

	switch(name) {
	case 'group':
		if (up && idx > 0) {
			var swap = model.groups[idx];
			model.groups[idx] = model.groups[idx-1];
			model.groups[idx-1] = swap;
			moved = true;
		}
		else if (!up && idx < model.groups.length) {
			var swap = model.groups[idx];
			model.groups[idx] = model.groups[idx+1];
			model.groups[idx+1] = swap;
			moved = true;
		}
		break;

	case 'element':
		var main2 = id.toString().split(';')[1];
		var name2 = main2.toString().split(':')[0];
		var idx2 = main2.toString().split(':')[1];
		var group = model.groups[idx2];
		if (group) {
			if (up && idx > 0) {
				var swap = group.elements[idx];
				group.elements[idx] = group.elements[idx-1];
				group.elements[idx-1] = swap;
				moved = true;
			}
			else if (!up && idx < group.elements.length) {
				var swap = group.elements[idx];
				group.elements[idx] = group.elements[idx+1];
				group.elements[idx+1] = swap;
				moved = true;
			}
		}
		break;

	case 'meta':
		if (up && idx > 0) {
			var swap = model.metas[idx];
			model.metas[idx] = model.metas[idx-1];
			model.metas[idx-1] = swap;
			moved = true;
		}
		else if (!up && idx < model.metas.length) {
			var swap = model.metas[idx];
			model.metas[idx] = model.metas[idx+1];
			model.metas[idx+1] = swap;
			moved = true;
		}
		break;
	default:
		break;
	}

	if (moved) {
		this.renderDetails();
		this.setModified(true);
	}
}

/// Add an item to the model.
ClientMethod addItem(id, idx) [ Language = javascript ]
{
	var main = id.toString().split(';')[0];
	var name = main.toString().split(':')[0];
	var idx = main.toString().split(':')[1];

	var model = zen('model').getContentObject();
	this._currId = id;

	switch(name) {
	case 'meta':
		var newItem = {
					_class:'%DeepSee.Model.QualityMeasure.meta',
					caption:"",
					disabled:false,
					qualityMeasure:null,
					name:"New Item",
					caption:"New Item",
					content:"",
					section:""
					};

		model.metas[model.metas.length] = newItem;
		break;

	case 'expression':
		var newItem = {
					_class:'%DeepSee.Model.QualityMeasure.group',
					caption:"",
					disabled:false,
					qualityMeasure:null,
					name:"New Group",
					description:"",
					elements:[]
					};

		model.groups[model.groups.length] = newItem;
		break;

	case 'group':
		var newItem = {
					_class:'%DeepSee.Model.QualityMeasure.element',
					caption:"",
					disabled:false,
					group:null,
					mdx:"",
					name:"New Element"
					};
		model.groups[idx].elements.splice(idx,0,newItem);
		break;

	default:
		break;
	}

	this.renderDetails();
	this.setModified(true);
}

/// Apply change from dialog
ClientMethod applyChange() [ Language = javascript ]
{
	var id = this._currId;
	var main = id.toString().split(';')[0];
	var name = main.toString().split(':')[0];
	var idx = main.toString().split(':')[1];
	var model = zen('model').getContentObject();

	switch(name) {
	case 'meta':
		var meta = model.metas[idx];
		if (meta) {
			meta.name = zen('metaName').getValue();
			meta.caption = zen('metaCaption').getValue();
			meta.content = zen('metaContent').getValue();
		}
		break;
	case 'group':
		var group = model.groups[idx];
		if (group) {
			group.name = zen('metaGroupName').getValue();
			group.description = zen('metaGroupDescription').getValue();
		}
		break;
	case 'element':
		var main2 = id.toString().split(';')[1];
		var name2 = main2.toString().split(':')[0];
		var idx2 = main2.toString().split(':')[1];
		var group = model.groups[idx2];
		if (group) {
			var element = group.elements[idx];
			if (element) {
				element.name = zen('metaElementName').getValue();
				element.mdx = zen('metaElementExpression').getValue();
			}
		}
		break;
	case 'subjectArea':
		model.subjectArea = zen('metaSubjectArea').getValue();
		break;
	case 'expression':
		model.expression = zen('metaExpression').getValue();
		break;
	case 'format':
		model.format = zen('metaFormat').getValue();
		break;
	case 'href':
		model.href = zen('metaHREF').getValue();
		break;
	case 'caption':
		model.caption = zen('msrCaption').getValue();
		break;
	case 'description':
		model.description = zen('msrDescription').getValue();
		break;
	case 'published':
		model.published = zen('metaPublished').getValue()==1?true:false;
		break;
	}

	this.endModal();
	this.renderDetails();
	this.setModified(true);
}

/// Draw details using JSON model.
ClientMethod renderDetails() [ Language = javascript ]
{
	if (this.browseMode) {
		this.renderCatalog();
		return;
	}
	
	var html = [];
	var model = zen('model').getContentObject();
	if (!model||(model.id=='')) {
		html[html.length] = '<div style="color:darkred; padding: 5px; font-size:14pt;">' + $$$Text('Press Browse to see a list of quality measures.') + '</div>';
	}
	else {
		// create list of details
		var details = [];
		details[details.length] = { name:'catalog',label:$$$Text('Measure Catalog'),value:model.catalog, style:'font-size:20pt;'};
		details[details.length] = { name:'set',label:$$$Text('Measure Set'),value:model.set, style:'font-size:20pt;'};
		details[details.length] = { name:'id',label:$$$Text('Measure ID'),value:model.id, style:'font-size:24pt;' };
		details[details.length] = { name:'caption',label:$$$Text('Caption'),value:model.caption, style:'' };
		details[details.length] = { name:'description',label:$$$Text('Description'),value:zenGet(model.description), style:'' };
		details[details.length] = { name:'linkedTo',label:$$$Text('Linked To'),value:model.linkedTo, style:'' };

		// line
		details[details.length] = null;

		// measure
		details[details.length] = { name:'expression',label:$$$Text('Measure'),value:model.expression, style:'font-size:22pt;' };

		// groups
		for (var g = 0; g < model.groups.length; g++) {
			var group = model.groups[g];
			details[details.length] = { name:'group:'+g,label:group.caption==''?group.name:group.caption,value:group.description, style:'', index:g };
			for (var n = 0; n < group.elements.length; n++) {
				var el = group.elements[n];
				details[details.length] = { name:'element:'+n+';group:'+g,label:el.caption==''?el.name:el.caption,value:el.mdx, style:'', index:n };
			}
		}

		// line
		details[details.length] = null;

		details[details.length] = { name:'subjectArea',label:$$$Text('Subject Area'),value:model.subjectArea, style:'' };
		details[details.length] = { name:'className',label:$$$Text('Class Name'),value:zenPage.qmsrClass, style:'' };
		details[details.length] = { name:'published',label:$$$Text('Published'),value:model.published?$$$Text('Yes'):$$$Text('No'), style:'' };
		details[details.length] = { name:'href',label:$$$Text('Link to additional info'),value:model.href, style:'' };

		// meta data
		for (var m = 0; m < model.metas.length; m++) {
			var meta = model.metas[m];
			details[details.length] = { name:'meta:'+m,label:meta.caption==''?meta.name:meta.caption,value:meta.content, style:'' };
		}

		if (this.editMode && !model.linkedTo) {
			// place [add meta} button at end of list
			details[details.length] = { name:'addMeta' };
		}

		details[details.length] = { name:'format',label:$$$Text('Numeric Format'),value:model.format, style:'font-family:courier new;' };

		// end of details

		// display it
		html[html.length] = '<table border="0" cellpadding="0" cellspacing="0"  style="width:100%;">';
		for (var n = 0; n < details.length; n++) {
			var detail = details[n];
			if (detail) {
				if (detail.name == 'addMeta') {
					html[html.length] = '<tr><td class="mdtLabel">'+'<a href="#" onclick="zenPage.addItem(\'meta:0;\');return false;">['+$$$Text('Add Meta Item')+ ']</a>'+'</td></tr>';
				}
				else {
					var isIndent = detail.name && (detail.name.indexOf('element:')!=-1);
					var readOnly = (detail.name=='className')||(detail.name=='id')||(detail.name=='set')||(detail.name=='catalog');
					var isParent = detail.name && ((detail.name.indexOf('group:')==0)||(detail.name.indexOf('expression')==0));
					var isListElement = detail.name && ((detail.name.indexOf('element:')!=-1)||(detail.name.indexOf('group:')==0)||(detail.name.indexOf('meta:')!=-1));
					var isLink = detail.name && (detail.name.indexOf('href')==0);
					
					// everything but caption,linkedTo,published,and subjectArea is readonly for linked measures
					if (!readOnly && model.linkedTo) {
						readOnly = (detail.name!='caption' && detail.name!='linkedTo' && detail.name!='published' && detail.name!='subjectArea');
					}

					// indent group elements
					var indent = isIndent ? 'padding-left:34px;padding-top:4px;padding-bottom:4px;background:#F8F8FF;' : '';
					var dot = isIndent ? '<image src="portal/star_24.gif" style="width:12px;padding-left:22px;"/>&nbsp;' : '';
					var value = detail.value;
					var editIcon = (this.editMode&&!readOnly) ? '&nbsp;<image src="deepsee/notepad_16.png" onclick="zenPage.editValue(\''+detail.name+'\');" title="'+$$$Text('Edit this item')+'"/>' : '';
					if (this.editMode&&!readOnly&&isParent) {
						var idx = 0;
						if (detail.name.indexOf('group:')==0) {
							idx = detail.index ? detail.index : 0;
						}
						editIcon += '&nbsp;<image src="deepsee/ds_plus_16.gif" onclick="zenPage.addItem(\''+detail.name+'\','+idx+');" title="'+$$$Text('Add an item to this group')+'"/>';
					}
					if (this.editMode&&!readOnly&&isListElement) {
						editIcon += '&nbsp;<image src="deepsee/close_a_16.png" onclick="zenPage.deleteItem(\''+detail.name+'\');" title="'+$$$Text('Delete this item')+'"/>';
						// move
						editIcon += '&nbsp;<image src="deepsee/ds_up_16.png" onclick="zenPage.moveItem(\''+detail.name+'\',true);" title="'+$$$Text('Delete this item')+'"/>';
						editIcon += '&nbsp;<image src="deepsee/ds_down_16.png" onclick="zenPage.moveItem(\''+detail.name+'\',false);" title="'+$$$Text('Delete this item')+'"/>';
					}
					if (isLink && !this.editMode) {
						if (value != '') {
							html[html.length] = '<tr><td class="mdtLabel"><a href="'+value+'">'+detail.label+'</a></td></tr>';
						}
					}
					else {
						if (this.editMode || value != '') {
							html[html.length] = '<tr><td class="mdtLabel">'+dot+detail.label+editIcon+'</td></tr>';
							html[html.length] = '<tr><td class="mdtValue" style="'+indent+detail.style+'">'+value+'</td></tr>';
						}
					}
				}
			}
			else {
				// line
				html[html.length] = '</table>';
				html[html.length] = '<hr/>';
				html[html.length] = '<table border="0" cellpadding="0" cellspacing="0"  style="width:100%;">';
			}
		}
		html[html.length] = '</table>';
	}
	html[html.length] = '<br/>';

	zen('qmsrDetails').setContent(html.join(''));
}

/// Draw qmsr catalog using JSON list.
ClientMethod renderCatalog() [ Language = javascript ]
{
	var html = [];
	var list = zen('list').getContentObject();
	if (!list) {
		html[html.length] = '<div style="color:darkred; padding: 5px; font-size:14pt;">' + $$$Text('There are no Quality Measures defined in this namespace.') + '</div>';
	}
	else {
		html[html.length] = '<div class="browseDiv">';

		// organize list
		var catalogs = {};

		for (var n = 0; n < list.children.length; n++) {
			var item = list.children[n];
			var name = item.name;
			var t = name.split('/');
			var cat = t[0];
			var set = t[1];
			
			if (!catalogs[cat]) {
				catalogs[cat] = { sets:{}, name:cat };
			}
			if (!catalogs[cat].sets[set]) {
				catalogs[cat].sets[set] = { items:[], name:set };
			}
			catalogs[cat].sets[set].items[catalogs[cat].sets[set].items.length] = {name: t[2], caption: item.caption};
		}

		for (var cat in catalogs) {
			html[html.length] = '<div class="browseCatalog"><div style="font-size:8pt;">'+$$$Text('Catalog')+'</div><div>' + zenEscapeXML(cat) + '</div></div>';
			for (var set in catalogs[cat].sets) {
				html[html.length] = '<div class="browseSet">' + zenEscapeXML(set) + '</div>';
				html[html.length] = '<div class="browseItems">';
				for (var n = 0 ; n < catalogs[cat].sets[set].items.length; n++) {
					var item = catalogs[cat].sets[set].items[n];
					var qname = cat + '/' + set + '/' + item.name;
					var style = '';
					if (qname==this.qmsrName) {
						style = 'background: rgb(148,190,221);';
					}
					html[html.length] = '<div class="browseItem" style="'+style+'"><div style="font-weight:bold;">' + zenEscapeXML(item.name) + '</div><div style="font-size:8pt;padding:4px;">' + zenEscapeXML(item.caption) + '</div><div><a href="#" onclick="zenPage.loadMeasure(\''+qname+'\');return false;">'+$$$Text('View')+'</a></div></div>';
				}
				html[html.length] = '</div>';
			}
		}
		html[html.length] = '</div>';
	}
	html[html.length] = '<br/>';
	zen('qmsrDetails').setContent(html.join(''));
}

/// method used by Source Control to set the value of the readOnly flag.
ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	this.readOnly = !!readOnly;
}

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	// DTB287 - Redirect to the error page if privileges are not met
	Set tUse = $System.Security.Check("%DeepSee_PortalEdit","USE")
	
	If 'tUse {
		Set %response.Redirect = ##class(%DeepSee.Utils).%GetErrorPageURL("Privilege")
	}
	
	Quit tUse
}

}
