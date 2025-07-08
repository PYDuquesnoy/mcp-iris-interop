/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit SQL View for Management Portal
Class %CSP.UI.Portal.Dialog.SQLView Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.SQLView.zen";

/// Displayed name of this page.
Parameter PAGENAME = "SQLViewEdit";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Development";

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "NAMESPACE");

/// Indicate whether this is to create or edit view.
Property isNew As %ZEN.Datatype.string(ZENURL = "isNew");

/// Schema name, may or may not be available.
Property SCHEMA As %ZEN.Datatype.string(ZENURL = "SCHEMA");

/// When editing, this is passed in.
Property VIEWNAME As %ZEN.Datatype.string(ZENURL = "VIEWNAME");

Property BuilderPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/%25CSP.UI.SQL.QueryBuilderWindow.cls",,1)} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();;"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="2"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<group id="editGroup" labelPosition="left" cellStyle="padding-bottom:5px;">
<radioSet id="radOption" showLabel="false" displayList="Select an existing schema,Enter a new schema" valueList="0,1" onchange="zenPage.showNewSchema();" value="0"/>
<dataCombo id="cmbSchema" label="Schema:" size="60" 
	queryClass="%SQL.Manager.Catalog" 
	queryName="Schemas"
	editable="false"
	multiColumn="false"
	choiceColumn="1"
	valueColumn="1"
	searchKeyLen="3"
	maxRows="100000"
	showEmpty="false"
	OnExecuteResultSet="ListSchemas"
 >
 </dataCombo>
 <text id="txtNewSchema" label="New Schema" size="30" hidden="true"/>
<text id="txtViewName" label="View Name" size="30" hint="Required." />
<hgroup cellAlign="even" label="With Check Option">
<select id="selCheckOption" valueList="READONLY,LOCAL,CASCADED" displayList="READONLY,LOCAL,CASCADED" showEmpty="true"/>
<checkbox id="chkPublic" caption="Grant all privileges on the View to _PUBLIC" captionClass="zenLabel"/>
</hgroup>
<textarea id="ViewText" label="View Text" rows="10" cols="60" hint="Required."/>
<button id="btnBuilder" caption="Query Builder" onclick="zenPage.doQueryBuilder();"/>
</group>
</pane>
}

ClientMethod showNewSchema() [ Language = javascript ]
{
	var option = zen("radOption").getValue();
	zen("cmbSchema").setHidden(option==1);
	zen("txtNewSchema").setHidden(option==0);
}

ClientMethod doQueryBuilder() [ Language = javascript ]
{
	var text = zen("ViewText").getValue();
	var url = this.BuilderPage+"ClassFilter=&ColumnType=2&$ID1="+encodeURIComponent(text)+"&zenLaunch=1";
	var win = window.open(url,'QueryBuilder','status=0,scrollbars,resizable,location=0,toolbar=0,titlebar=0,fullscreen=1');
	win.focus();
	zenPage._popupName = 'QueryBuilder';
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.VIEWNAME == "") {
		zen("txtViewName").focus();
	} else {
		zen("ViewText").focus();
	}
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return;
	switch(popupName) {
	case 'QueryBuilder':
		zen("ViewText").setValue(value);
		zen("ViewText").focus();
		break;
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.validate()==false) return false;
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var viewName = encodeURIComponent(zen("txtViewName").getValue());
	return viewName;
}

/// If creating a new view, make sure that the view name is not empty.
ClientMethod validate() [ Language = javascript ]
{
	var pass = true;
	if (this.isNew == 1) {
		if (!this.validateRequired(zen('txtViewName'),pass,"S")) pass = false;
	}
	if (!this.validateRequired(zen('ViewText'),pass,"S")) pass = false;
	return pass;
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	var radOption = zen("radOption").getValue();
	var Schema = (radOption==0) ? zen("cmbSchema").getValue() : zen("txtNewSchema").getValue();
	var ViewName = zen("txtViewName").getValue();
	var CheckOption = zen("selCheckOption").getValue();
	var ViewText = zen("ViewText").getValue();
	var GrantPublic = zen("chkPublic").getValue() ? 1 : 0;
	var ok = this.SaveData(this.isNew, Schema, ViewName, ViewText, CheckOption, GrantPublic);
	if (ok != "") {
		this.showMsg(ok);
		return false;
	}
	return true;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If %page.isNew = 1 Quit $$$Text("Create a View")
	Quit $$$Text("Edit View")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..VIEWNAME '= "" {
		#; Edit Existing View:
		If ..isNew = 0 {
			Set %page.SCHEMA = $P(..VIEWNAME,"==",1)
			Set ViewName = $P(..VIEWNAME,"==",2)
			Set ..%GetComponentById("cmbSchema").disabled = 1
			Set ..%GetComponentById("txtViewName").value = ViewName
			Set ..%GetComponentById("txtViewName").disabled = 1
			Set ..%GetComponentById("radOption").hidden = 1
			#; find ReadOnly and CheckOption
			Do ##class(%CSP.UI.Portal.SQL.Utils).GetViewInfo2(%page.SCHEMA, ViewName, .Owner, .ReadOnly, .CheckOption)
			If ReadOnly = 1 Set ..%GetComponentById("selCheckOption").value = "READONLY"
			Else  Set ..%GetComponentById("selCheckOption").value = CheckOption
			#; find query text
			Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewInfo")
			Do tRS.Execute(%page.SCHEMA,ViewName)
			If tRS.Next() Set tQuery = tRS.GetData(1),..%GetComponentById("ViewText").value = tQuery		
			Set ..%GetComponentById("chkPublic").hidden = 1
		} Else {
			#; Creat New View from Cached Query:
			Set ..%GetComponentById("txtViewName").value = ..VIEWNAME
			Set ..%GetComponentById("ViewText").value = ##class(%SQL.Manager.API).GetCachedQueryInfo(..VIEWNAME,.sCreate,.sLast,.bSource,.sQueryType)
		}
	}
	Else {
		Set ..%GetComponentById("txtViewName").value = "NEWVIEW"
	}
	Set ..%GetComponentById("cmbSchema").value = %page.SCHEMA	
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	If %page.isNew = 1 {
		Set tPageTitle = $$$TextHTML("Create a View")_"<br/>"
	} Else {
		Set tPageTitle = $$$FormatText($$$Text("Edit View %1"),..EscapeHTML(%page.SCHEMA)_"."_..EscapeHTML($P(%page.VIEWNAME,"==",2)))_"<br/>"
	}
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit 1
}

/// VIEWNAME, Schema, ViewName, ViewText, CheckOption, ReadOnly
ClassMethod SaveData(isNew, Schema, ViewName, ViewText, CheckOption, GrantPublic) As %String [ ZenMethod ]
{
	Set $ZT = "Trap"	
	Set tSC = $$$OK
	Set tMsg = ""
	Set sAction = $S(isNew=0:"Alter View ",1:"Create View ")
	Set CheckOption("READONLY") = "WITH READ ONLY"
	Set CheckOption("LOCAL") = "WITH LOCAL CHECK OPTION"
	Set CheckOption("CASCADED") = "WITH CASCADE CHECK OPTION"
	Set sCheckOption = ""
	If CheckOption '= "" Set sCheckOption = CheckOption(CheckOption)

	Set Schema = $S(Schema'="":Schema_".",1:"")
	Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.ViewName)
    Set sQueryText = sAction _ Schema _ ViewName _ " AS " _ ViewText _ " " _ sCheckOption
	Set EventDesc = sAction _ $S(GrantPublic: " Grant privileges to _PUBLIC",1:"")
	Set EventData = "View text:"_$$$CRLF_sQueryText
	If $L(EventData) > 16300 Set EventData = $E(EventData,1,16300)_"..."
	$$$SMPAuditChange
	#; pass "SMP" as %call to SQLExecuteQuery will prevent the DDL API from checking the DDLAllowed flag for the class
	Set tResult = ##class(%CSP.UI.Portal.SQL.Utils).SQLExecuteQuery(sQueryText, .tClassName,,,,"SMP")
	If tResult.%SQLCODE < 0 {
		Set tMessages = 0
		Do ##CLASS(%CSP.UI.Portal.SQL.Utils).GetError(tResult,.tMessages)
		Set n = ""
		for  { 
			set n = $O(tMessages(n)) Quit:n=""  
			Set tMsg=tMsg_tMessages(n)_"<br/>"
		}
	} Else {
		If GrantPublic {
			Do setup^%SYS.SQLSEC("*",3,$lb(Schema _ ViewName),"_PUBLIC",0,0)
		}
	}
	Quit tMsg
Trap
	Set $ZT=""
	Quit $ZCVT($ZE,"O","HTML")
}

/// Method for executing the schemas query.
Method ListSchemas(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set NAMESPACE = %page.NAMESPACE
	If NAMESPACE '= $namespace Set $Namespace = NAMESPACE
	Set tSC = pRS.Execute()
	Quit tSC
}

}
