/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Page to define SQL Table/View column privileges.
Class %CSP.UI.Portal.Dialog.ColumnPriv Extends (%CSP.Portal.standardDialog, %CSP.UI.Component.SelectBoxUtils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter AUTONS As BOOLEAN = 1;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.ColumnPriv.zen";

Parameter RESOURCE = "%Admin_Secure:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Column Privileges";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 1;

/// User or Role whose privileges are being granted
Property PID As %String(ZENURL = "PID");

/// Flag indicating whether user checked the "Include System Items" checkbox.
Property IncludeSystem As %Integer(ZENURL = "IncludeSystem") [ InitialExpression = 0 ];

/// Namespace indicating where the schemas/tables/views are coming from.
Property Namespace As %String(ZENURL = "$NAMESPACE");

/// ObjName = null for Add, or Table name or View name for Edit
Property ObjName As %String(ZENURL = "ObjName");

/// "TABLE" or "VIEW".
Property ObjectType As %String(ZENURL = "Type");

/// User selected schema name
Property Schema As %String;

/// User selected table name
Property Table As %String;

/// Table column name if user is editing or revoking
Property Column As %String;

/// Total number of existing columns for edit
Property TotalColumns As %Integer [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
table.content {
	padding: 0px;
	font-size: 0.8em;
	background: white;
	width: 95%;
	margin-left: 0px; margin-right: 10px;
	border: gray solid 1px; 
}
table.content th {
	border-bottom: gray solid 1px; 	
	border-right: gray solid 1px; 	
	background: #CCCCFF; color: black;
	padding: 2px;
	text-align: left;
}
table.content td {
	border-bottom: gray solid 1px; 	
	border-right: gray solid 1px;
	padding: 2px;
	text-align: left;
}
table.content tr.OddRow { background: white; }
table.content tr.EvenRow { background: #DDFFFF; }
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
<button id="btnApply" caption="Apply" onclick="zenPage.dialogApply();" />
<spacer width="5" />
<button id="btnCancel" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="idRespond" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<vgroup width="100%">
<form cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">
<label id="Namespace" label="Namespace" controlClass="normal" value="#(%page.Namespace)#"/>
<select id="cmbSchema" label="Select a Schema" onchange="zenPage.changeSchema(zenThis.getValue());" showEmpty="false"/>
<dataCombo id="cmbTable" label="Select a Table"
disabled="true"
queryClass="%SQL.Manager.Catalog" 
queryName="TablesOnly" 
multiColumn="false" 
displayColumns="1"
valueColumn="1"
choiceColumn="1"
searchKeyLen="3"
maxRows="100000"
onchange="zenPage.changeTable(zenThis.getValue());"
 >
 <parameter value="#(%page.Schema)#"/>
 <parameter value="1"/>
 </dataCombo>
<html id="idTable" OnDrawContent="DrawTable"/>
<checkbox id="chkAdd" caption="Add Columns" captionClass="normal" onclick="zenPage.doAddColumn(zenThis.getValue());"/>
<hgroup>
<html id="selectBoxes" OnDrawContent="DrawSelectBoxes" />
<hgroup id="PrivTable">
<vgroup>
<vgroup label="Privilege" align="center" containerStyle="border:1px white solid;font-size:12px;font-weight:bold;padding:2px;">
<checkbox id="chkPriv" onclick="zenPage.toggleChecks(0,zenThis.getValue());"/>
</vgroup>
<vgroup containerStyle="border:1px white solid;">
<checkbox id="chkPriv1" caption="SELECT" captionClass="normal" value="1" onclick="zenPage.checkboxModified(1,0);"/>
<checkbox id="chkPriv2" caption="INSERT" captionClass="normal" onclick="zenPage.checkboxModified(2,0);"/>
<checkbox id="chkPriv3" caption="UPDATE" captionClass="normal" onclick="zenPage.checkboxModified(3,0);"/>
<checkbox id="chkPriv4" caption="REFERENCES" captionClass="normal" onclick="zenPage.checkboxModified(4,0);"/>
</vgroup>
</vgroup>
<vgroup>
<vgroup label="Grant Admin" align="center" containerStyle="border:1px white solid;font-size:12px;font-weight:bold;padding:2px;">
<checkbox id="chkGrant" onclick="zenPage.toggleChecks(1,zenThis.getValue());"/>
</vgroup>
<vgroup align="center" containerStyle="border:1px white solid;" >
<checkbox id="chkGrant1" onclick="zenPage.checkboxModified(1,1);"/>
<checkbox id="chkGrant2" onclick="zenPage.checkboxModified(2,1);"/>
<checkbox id="chkGrant3" onclick="zenPage.checkboxModified(3,1);"/>
<checkbox id="chkGrant4" onclick="zenPage.checkboxModified(4,1);"/>
</vgroup>
</vgroup>
</hgroup>
</hgroup>
</form>
</vgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.toggleSave(false);
}

/// Disable or enable the apply,cancel, and ok buttons for this dialog.
/// Overriding %ZEN.Dialog.standardDialog
/// (called by dialogFinish() and dialogCancel())
ClientMethod disableButtons(flag) [ Language = javascript ]
{
	this.invokeSuper('disableButtons',arguments);
	this.toggleSave(false);
}

ClientMethod onSelectBoxMove(flag, isPage) [ Language = javascript ]
{
	this.doModified();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

ClientMethod toggleSave(enable) [ Language = javascript ]
{
	var btn = zen('btnApply');
	var btnStyle = enable ? '' : this.disabledStyle;
	btn.setProperty('controlStyle',btnStyle);
	btn.setProperty('disabled',!enable);
}

ClientMethod doModified() [ Language = javascript ]
{
	if ((this.ObjName != "") && (this.Column != '')) {
		// editing an existing column of an existing table
		if (this.isSomethingChecked()) {
			this.toggleSave(true);
		} else {
			this.toggleSave(false);
		}
	} else {
		if ((this.ObjName != "") && (zen('chkAdd').getValue() == 0)) {
			// nothing selected for an existing table
			this.toggleSave(false);
		} else {
			// adding a new column to an existing table or adding a new table
			if ((document.getElementById(this.selList).options.length > 1) && this.isSomethingChecked()) {
				this.toggleSave(true);
			} else {
				this.toggleSave(false);
			}
		}
	}
}

/// User changed or selected a schema. Load Table list based on the schema selected.
ClientMethod changeSchema(newVal) [ Language = javascript ]
{
	this.Schema =  newVal;
	var tCombo = zen("cmbTable");
	// first reset the existing table value and clear columns lists
	tCombo.setValue("");
	this.clearList(this.avaList,1);
	this.clearList(this.selList,1);
	// enable the table
	tCombo.setProperty("disabled",false);
	// clear cache to force dataCombo to reload list:
	tCombo.clearCache();
	this.doModified();
}

/// User selected a table. Load Available/Selected list boxes.
ClientMethod changeTable(newVal) [ Language = javascript ]
{
	this.Table = newVal;
	if ((this.Schema == "") || (this.Table == "")) return;
	
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	zen("selectBoxes").setHidden(false);
	this.clearList(this.avaList,1);
	this.clearList(this.selList,1);
	
	var result = this.UpdateDetails(this.Schema,this.Table,this.PID,this.IncludeSystem);
	if (result.ok == 1) {
		var options = result.Options.split(',');
		for (var i=0;i<options.length;i++) {
			document.getElementById(this.avaList).options[i+1] = new Option(options[i],options[i]);
		}
	} else {
		alert(result.ErrorMessage);
	}
	this.doModified();
	
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod uncheckAllBoxes() [ Language = javascript ]
{
	zen("chkPriv").setValue(0);
	zen("chkGrant").setValue(0);
	
	for (var r=1;r<5;r++) {
		zen("chkPriv"+r).setValue(0);
		zen("chkGrant"+r).setValue(0);
	}
}

/// User clicked the Privilege/Grant Admin checkbox.
ClientMethod toggleChecks(g, newVal) [ Language = javascript ]
{
	// if Grant Adm is checked, then the Priv is also checked.
	if (g == 1) {
		for (var r=1;r<5;r++) {
			// check/uncheck Grant
			zen("chkGrant"+r).setValue(newVal);
			// check Priv only if newVal is 1
			if (newVal == 1) zen("chkPriv"+ r).setValue(newVal);
		}
		if (newVal == 1) zen("chkPriv").setValue(newVal);
	} else {
		for (var r=1;r<5;r++) {
			// check/uncheck Priv
			zen("chkPriv"+r).setValue(newVal);
			// uncheck Grant only if newVal is 0
			if (newVal == 0) zen("chkGrant"+ r).setValue(newVal);
		}
		if (newVal == 0) zen("chkGrant").setValue(newVal);
	}
	this.doModified();
}

/// User changed a checkbox.
ClientMethod checkboxModified(id, g) [ Language = javascript ]
{
	// if Grand Adm is checked, then the Priv is also checked.
	if (g == 1) {
		if (zen("chkGrant"+ id).getValue() == 1) {
			zen("chkPriv" + id).setValue(1);
		}
	} else {
		// if Priv is unchecked, then the Grant is also unchecked.
		if (zen("chkPriv"+ id).getValue() != 1 ) {
			zen("chkGrant" + id).setValue(0);
		}
	}
	this.checkAll('chkPriv');
	this.checkAll('chkGrant');
	
	this.doModified();
}

/// Check if Priv or Grant are all checked. 
/// check chkPriv/chkGrant if all its checkboxes are checked; uncheck if at least one is unchecked.
ClientMethod checkAll(ID) [ Language = javascript ]
{
	var checked = 0;
	for (var r=1;r<5;r++) {
		if (zen(ID + r).getValue()==1) {
			checked++;
		}
	}
	var chkID = zen(ID);
	if (checked == 4) {
		chkID.setValue(1);	
	} else {
		chkID.setValue(0);
	}
}

/// User clicked "Add Columns" to add more columns to existing schema.table
ClientMethod doAddColumn(newVal) [ Language = javascript ]
{
	zen('chkAdd').setValue(newVal);
	this.uncheckAllBoxes();
	if (newVal == 1) {
		zen("selectBoxes").setHidden(false);
		zen("PrivTable").setHidden(false);
		zen("PrivTable").setProperty("label","");
		this.Column = "";
		this.changeTable(this.Table);
	} else {
		zen("selectBoxes").setHidden(true);
		zen("PrivTable").setHidden(true);
	}
	this.doModified();
}

/// User clicked "Edit" to edit existing column priv
ClientMethod doEditColumn(column) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	this.Column = column;
	zen('chkAdd').setValue(0);
	zen('selectBoxes').setHidden(true);
	var PrivTable = zen("PrivTable");
	PrivTable.setProperty("hidden",false);
	PrivTable.setProperty("label",column);
	for (var r = 1; r < 5; r++) {
		zen("chkPriv" + r).setValue(0);
		zen("chkGrant"+ r).setValue(0);
	}
	var result = this.ColumnEdit(this.Schema,this.Table,column);
	if (result.ok == 1) {
		var flag = 1;
		if (result.SELECT != "") {
			zen("chkPriv1").setValue(flag);
			if (result.SELECT == 1) {
				zen("chkGrant1").setValue(flag);
			}
		} 
		if (result.INSERT != "") {
			zen("chkPriv2").setValue(flag);
			if (result.INSERT == 1) {
				zen("chkGrant2").setValue(flag);
			}
		} 
		if (result.UPDATE != "") {
			zen("chkPriv3").setValue(flag);
			if (result.UPDATE == 1) {
				zen("chkGrant3").setValue(flag);
			}
		} 
		if (result.REFERENCES != "") {
			zen("chkPriv4").setValue(flag);
			if (result.REFERENCES == 1) {
				zen("chkGrant4").setValue(flag);
			}
		}
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod isSomethingChecked() [ Language = javascript ]
{
	if (zen("chkPriv").getValue() == 1) return true;
	if (zen("chkGrant").getValue() == 1) return true;

	for (var r=1;r<5;r++) {
		if (zen("chkPriv"+r).getValue() == 1) return true;
		if (zen("chkGrant"+r).getValue() == 1) return true;
	}
	return false;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var oldSynchronousMode = zenSynchronousMode;
		zenSynchronousMode = true;
		
		this.resetMsg();
		
		var columns = this.getSelList(',',false,true);
		var pid = "";	
		var priv = "";
		var grant = "";
		for (var r=1;r<5;r++) {
			pid = "chkPriv" + r;
			if (zen(pid).value == 1) priv = priv + "," + r;
			pid = "chkGrant" + r;
			if (zen(pid).value == 1) grant = grant + "," + r;
		}
		/// if editing column then this is the column name
		if ((this.ObjName != "") && (columns == "")) columns = this.Column;
		if (columns == "") return;
		
		var proxy = new zenProxy();
		if (this.ObjName == '') {
			proxy.ObjName = this.Schema+"."+this.Table;
		} else {
			proxy.ObjName = this.ObjName;
		}
		proxy.PID = this.PID;
		proxy.ObjectType = this.ObjectType;
		proxy.Schema = this.Schema;
		proxy.Table = this.Table;
		proxy.columns = columns;
		proxy.priv = priv;
		proxy.grant = grant;
		proxy.revoke = 0;
		proxy.IncludeSystem = this.IncludeSystem;
		
		var result = this.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage,true);
			zenSynchronousMode = oldSynchronousMode;
			return false;
		} else {
			zen('idTable').refreshContents();
			zen('btnCancel').setProperty('caption',$$$Text('Close'));
			zenSynchronousMode = oldSynchronousMode;
			return true;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// User clicked "Revoke" to revoke existing column priv
ClientMethod doRevokeColumn(column) [ Language = javascript ]
{
	if (column == "*") {
		if (!confirm($$$Text("Revoke all column privileges for this table?"))) return;
	}
	
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	this.disableButtons(true);
	
	this.doAddColumn(0);

	var proxy = new zenProxy();
	if (this.ObjName == '') {
		proxy.ObjName = this.Schema+"."+this.Table;
	} else {
		proxy.ObjName = this.ObjName;
	}
	proxy.PID = this.PID;
	proxy.ObjectType = this.ObjectType;
	proxy.Schema = this.Schema;
	proxy.Table = this.Table;
	proxy.columns = column;
	proxy.priv = "";
	proxy.grant = "";
	proxy.revoke = 1;
	proxy.IncludeSystem = this.IncludeSystem;
	
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		this.showMsg(result.ErrorMessage,true);
	} else {
		if (column == "*" || (this.TotalColumns == 1)) {
			this.firePopupAction('revoke',this.getDialogValue());
		} else {
			zen('idTable').refreshContents();
			this.disableButtons(false);
		}
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// When editing existing column priv, this method loads existing column priv into check boxes
ClassMethod ColumnEdit(pSchema, pTable, pColumn) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Set s = $G(%session.Data("Columns",pSchema,pTable,pColumn,"SELECT"))
		Set i = $G(%session.Data("Columns",pSchema,pTable,pColumn,"INSERT"))
		Set u = $G(%session.Data("Columns",pSchema,pTable,pColumn,"UPDATE"))
		Set r = $G(%session.Data("Columns",pSchema,pTable,pColumn,"REFERENCES"))
		Set tProxy.SELECT = $Case(s,"Yes":1,"No":0,:"")
		Set tProxy.INSERT = $Case(i,"Yes":1,"No":0,:"") 
		Set tProxy.UPDATE = $Case(u,"Yes":1,"No":0,:"") 
		Set tProxy.REFERENCES = $Case(r,"Yes":1,"No":0,:"")
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Save column priv data to server
/// If this is to revoke column priv, then pRevoke = 1, pPrivs and pGrant will be null.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Set tResult = ""

		New $namespace
		Set $namespace = pProxy.Namespace

		Set GrantedBy = $Username
		Set nType = $S(pProxy.ObjectType="TABLE":1,pProxy.ObjectType="VIEW":3,1:9)
		
		#; Set columns into $list
		Set fields = $LISTFROMSTRING(pProxy.columns,",")
		
		If pProxy.revoke = 0 {
			#; first remove all privileges
    		Set tSC = ##class(%SQL.Manager.API).SaveObjPriv("*",nType,pProxy.ObjName,pProxy.PID,0,1,.SQLCODE,.sMsg,GrantedBy,.fields)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			If SQLCODE '= 0 {
				Set tResult = pProxy.ObjName_$$$TextHTML("Save failed. Could not remove existing privilege.")_" "_sMsg
				Throw
			}
						
			#; for every selected priv, grant the privilege:
			For i=2:1:$LENGTH(pProxy.priv,",") {
				Set priv = $PIECE(pProxy.priv,",",i)
				Set nGrant = pProxy.grant [ priv
				Set action = $CASE(priv,1:"s",2:"i",3:"u",:"r")
			    Set tSC = ##class(%SQL.Manager.API).SaveObjPriv(action,nType,pProxy.ObjName,pProxy.PID,nGrant,0,.SQLCODE,.sMsg,GrantedBy,.fields)
			    If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		     	If SQLCODE '= 0 {
			     	Set tResult = pProxy.ObjName_$$$TextHTML("Save failed. Please make sure that you have sufficient SQL privilege to perform this operation.")_" "_sMsg
			     	Throw
		     	}
			}
		} Else {
			#; If it is revoke all, gather all columns now
			If (pProxy.columns = "*") {
				Set tSC = ..GetColumns(pProxy.PID,pProxy.Schema,pProxy.Table,pProxy.IncludeSystem,.columns)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				If (columns = "") {
					Throw
				}
				#; Set columns into $list
				Set fields = $LISTFROMSTRING(columns,",")
			}
	    	Set tSC = ##class(%SQL.Manager.API).SaveObjPriv("*",nType,pProxy.ObjName,pProxy.PID,0,1,.SQLCODE,.sMsg,GrantedBy,.fields)
	    	If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	    	If SQLCODE '= 0 {
		       	Set tResult = " ["_SQLCODE_"]"_sMsg
		       	Throw
	       	}
    	}
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		If tResult '= "" {
			Set tProxy.ErrorMessage = tResult
		} Else {
			Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
		}
	}
	Quit tProxy
}

/// Load fields into Available/Selected list boxes.
ClassMethod UpdateDetails(Schema As %String, Table As %String, PID As %String, IncludeSystem As %Integer) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Options = ""
	
	Try {
		#; Check if this file has already been selected. If yes, whether it has specific fields mapped.
		Set tSC = ..GetColumns(PID,Schema,Table,IncludeSystem,.tColumns)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tField = ""
		For cnt = 1:1 Set tField = $P(tColumns,",",cnt) Quit:tField=""  Set tFields(tField) = 1
		
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Fields")
		Set tSC = tRS.Execute(Schema,Table)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set options = ""
		While tRS.Next() {
			Set tText = tRS.Data("FIELD_NAME")
			If tText = "x__classname" Continue
			If $G(tFields(tText)) = "" {
				Set eText = $ZCVT(tText,"O","JS")
				If (options '= "") Set options = options_","
				Set options = options_eText
			}						
		}
		Set tProxy.Options = options
		Set tProxy.ok = 1
	}  Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tProxy
}

Method PopulateSchemas() As %Status
{
	Try {
		Set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:SchemasOnly")
		Set tSC = rs.Execute(+..IncludeSystem,..ObjectType,0)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set valueList = ""
		Set displayList = $$$Text("----- Select a schema -----")
		While rs.Next() {
			Set valueList = valueList_","_rs.Data("SCHEMA_NAME")
			Set displayList = displayList_","_rs.Data("SCHEMA_NAME")
		}
		Set ..%GetComponentById("cmbSchema").valueList = ..EscapeHTML(valueList)
		Set ..%GetComponentById("cmbSchema").displayList = ..EscapeHTML(displayList)
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

/// Return existing columns
ClassMethod GetColumns(PID As %String, Schema As %String, Table As %String, IncludeSystem As %Integer, Output Columns As %String) As %Status
{
	Set Columns = ""
	
	Try {
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserColumnPrivs")
		Set tSC = tRS.Execute(PID,Schema,Table,IncludeSystem)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		While tRS.Next() {
			Set Columns = Columns_$S(Columns'="":",",1:"")_tRS.Data("COLUMN_NAME")
		}
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

Method DrawSelectBoxes(seed As %String) As %Status
{
	Try {
		// Draw the Available list box
		Set tSC = ..DrawAvailableList("",1)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		// Draw the arrows and Select list box
		Set tSC = ..DrawSelectList("",1)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

/// Draws table for existing table column priv allowing user to edit or revoke.
Method DrawTable(seed As %String) As %Status
{
	If ..ObjName = "" Quit $$$OK
	Try {
		Kill %session.Data("Columns")

		Set PrivilegeString = "SELECT,INSERT,UPDATE,REFERENCES"
		If ..ObjectType = "VIEW" {
			Set PrivilegeString = "SELECT,INSERT,UPDATE"
		}
		Set nPrivilegesLen = $L(PrivilegeString,",")	
		
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserColumnPrivs")
		Set tSC = tRS.Execute(..PID,..Schema,..Table,..IncludeSystem)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		&html<
			<div>
			<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">>
		&html<
			<thead class="tpHead">
				<th nowrap>#($$$Text("Column Name"))#</th>>
		For i=1:1:nPrivilegesLen {
			&html<<th nowrap>#($P(PrivilegeString,",",i))#</th>>
		}
		&html<
				<th nowrap>#($$$TextHTML("Granted Via"))#</th>
				<th nowrap>#($$$TextHTML("Granted By"))#</th>
				<th>&nbsp;</th>
				<th>&nbsp;</th>
			</thead>
			<tbody class="tpBody">>

		Set tLastName = ""
		While tRS.Next() {
			Set tLastName = tRS.Data("COLUMN_NAME")
			Set tGrantedVia = $SELECT(tRS.Data("GRANTED_VIA")="":0,1:tRS.Data("GRANTED_VIA"))
			Set tGrantedBy = $SELECT(tRS.Data("GRANTED_BY")="":0,1:tRS.Data("GRANTED_BY"))
			Set tPrivName = tRS.Data("PRIVILEGE")
			Set tGrant = tRS.Data("GRANT_OPTION")
			Set tObjects(tLastName,tGrantedVia,tGrantedBy,0) = ..ObjectType
			For i=1:1:nPrivilegesLen {
				If $P(PrivilegeString,",",i) = tPrivName {
					Set $P(tObjects(tLastName,tGrantedVia,tGrantedBy),",",i) = $S(tGrant="Yes":2,1:1)
				}
			}
			Set $P(tObjects(tLastName,tGrantedVia,tGrantedBy),",",i+1) = tRS.Data("GRANTED_VIA")
			Set $P(tObjects(tLastName,tGrantedVia,tGrantedBy),",",i+2) = tRS.Data("GRANTED_BY")
			Set %session.Data("Columns",..Schema,..Table,tLastName,tPrivName) = tGrant
		}

		Set tRow = 0
		Set tLastName = $O(tObjects(""))
		While tLastName '= "" {
			Set tRow = tRow + 1
			Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")
			Set tGrantedVia = $O(tObjects(tLastName,""))
			While tGrantedVia '= "" {
				Set tGrantedBy = $O(tObjects(tLastName,tGrantedVia,""))
				While tGrantedBy '= "" {
					Set tObj = tObjects(tLastName,tGrantedVia,tGrantedBy)
					&html<
					<tr class="#(rowClass)#">
						<td class="tpStr" nowrap>#($ZCVT(tLastName,"O","HTML"))#</td>>
					Do ##class(%CSP.UI.Component.SQLTables).BuildLine(tObj,nPrivilegesLen)
					
					If $P(tObj,",",nPrivilegesLen+1) = "Direct" {
						&html<
						<td class="tpAction" style="text-align:center;"><a href="#" onclick="zenPage.doEditColumn('#($ZCVT(tLastName,"O","JS"))#');">#($$$TextHTML("Edit"))#</a></td>
						<td class="tpAction" style="text-align:center;"><a href="#" onclick="zenPage.doRevokeColumn('#($ZCVT(tLastName,"O","JS"))#');">#($$$TextHTML("Revoke"))#</a></td>>
					} Else {
						&html<
						<td nowrap>&nbsp;</td>
						<td nowrap>&nbsp;</td>>
					}
					&html<
						</tr>>
					Set tGrantedBy = $O(tObjects(tLastName,tGrantedVia,tGrantedBy))
				}
				Set tGrantedVia = $O(tObjects(tLastName,tGrantedVia))	
			}
			Set tLastName = $O(tObjects(tLastName))
		}

		Set ..TotalColumns = tRow

		If tRow = 0 {
			&html<<tr><td colspan="12">#($$$TextHTML("None."))#</td></tr>>	
		} Else {
			&html<<tr><td colspan="12">&nbsp;&nbsp;>
			&html<#($$$TextHTML("Legend"))#: <span style="font-size:14px;">&nbsp;-&nbsp;</span>>
			&html<#($$$TextHTML("Not Granted"))#<span style="font-size:14px;">&nbsp;&nbsp;&#186;&nbsp;</span>>
			&html<#($$$TextHTML("Granted"))#<span style="font-size:14px;">&nbsp;&nbsp;&#8226;&nbsp;</span>>
			&html<#($$$TextHTML("Granted with Grant Admin Option"))#</td></tr>>
		}
		&html<</tbody></table></div>>
		
		If ..TotalColumns > 1 {
			&html<
				<button onclick="zenPage.doRevokeColumn('*');">#($$$TextHTML("Revoke All"))#</button>>
		}
		
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set cmbTable = ..%GetComponentById("cmbTable")
	
	If ..ObjectType = "VIEW" {
		Set cmbTable.label = $$$TextHTML("Select a View:")
		Set cmbTable.queryName = "ViewsOnly"	
		Set ..%GetComponentById("chkPriv4").hidden = 1
		Set ..%GetComponentById("chkGrant4").hidden = 1
	}
	
	#; ObjName = null for Add, or Table name or View name for Edit
	If ..ObjName '= "" {
		Set ..Schema = $P(..ObjName,".",1,$L(..ObjName,".")-1)
		Set ..Table = $P(..ObjName,".",$L(..ObjName,"."))
		
		Set cmbSchema = ..%GetComponentById("cmbSchema")
		Set cmbSchema.value = ..Schema
		Set cmbSchema.disabled = 1		
		
		Set cmbTable.value = ..Table
		Set cmbTable.disabled = 1
		Set ..%GetComponentById("selectBoxes").hidden = 1
		Set ..%GetComponentById("PrivTable").hidden = 1
	} Else {
		Set ..%GetComponentById("chkAdd").hidden = 1
		Set ..%GetComponentById("idTable").hidden = 1
	}
	
	Set tSC = ..PopulateSchemas()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$FormatText($$$TextHTML("Grant column privileges to %1"),$zconvert(..PID,"O","HTML"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
