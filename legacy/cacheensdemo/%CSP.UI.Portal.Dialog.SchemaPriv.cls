/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Page to define SQL Table/View column privileges.
Class %CSP.UI.Portal.Dialog.SchemaPriv Extends (%CSP.Portal.standardDialog, %CSP.UI.Component.SelectBoxUtils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter AUTONS As BOOLEAN = 1;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.SchemaPriv.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Schema Privileges";

Parameter RESOURCE = "%Admin_Secure:USE";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 1;

/// User or Role whose privileges are being granted
Property PID As %String(ZENURL = "PID");

/// Flag indicating whether user checked the "Include System Items" checkbox.
Property IncludeSystem As %Integer(ZENURL = "IncludeSystem") [ InitialExpression = 0 ];

Property IsProcedure As %Boolean;

Property IsNotProcedure As %Boolean;

Property IsRelation As %Boolean;

Property IsNotRelation As %Boolean;

Property IsMLConfiguration As %Boolean;

Property IsNotMLConfiguration As %Boolean;

Property IsForeignServer As %Boolean;

Property IsNotForeignServer As %Boolean;

Property HideUse As %Boolean;

/// Namespace indicating where the schemas/tables/views are coming from.
Property Namespace As %String(ZENURL = "$NAMESPACE");

/// ObjName = null for Add, or Table name or View name for Edit
Property ObjName As %String(ZENURL = "ObjName");

/// ObjName = null for Add, or Table name or View name for Edit
Property ObjPriv As %String(ZENURL = "ObjPriv");

/// "TABLE" or "VIEW".
Property ObjectType As %String(ZENURL = "Type");

Property Schema As %String;

Property Tables As %String;

/// Total number of existing columns for edit
Property TotalTables As %Integer [ InitialExpression = 0 ];

Property PrivCount As %Integer;

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
<label id="Namespace" label="Namespace" value="#(%page.Namespace)#" controlClass="normal"/>
<label id="ObjName" controlClass="normal" hidden="true"/>
<select id="cmbSchema" label="Select a Schema" onchange="zenPage.changeSchema(zenThis.getValue());" showEmpty="false"/>
<html id="selectBoxes" OnDrawContent="DrawSelectBoxes"/>
<hgroup id="PrivTable">
<vgroup>
<vgroup label="Privilege" align="center" containerStyle="border:1px white solid;font-size:12px;font-weight:bold;padding:2px;">
<checkbox id="chkPriv" onclick="zenPage.toggleChecks(0,zenThis.getValue());" hidden="#(%page.IsNotRelation)#"/>
</vgroup>
<vgroup containerStyle="border:1px white solid;border-bottom:0;" hidden="#(%page.IsNotRelation)#">
<checkbox id="chkPriv1" caption="ALTER" captionClass="normal" onclick="zenPage.checkboxModified(1,0);"/>
<checkbox id="chkPriv2" caption="SELECT" captionClass="normal" value="1" onclick="zenPage.checkboxModified(2,0);"/>
<checkbox id="chkPriv3" caption="INSERT" captionClass="normal" onclick="zenPage.checkboxModified(3,0);"/>
<checkbox id="chkPriv4" caption="UPDATE" captionClass="normal" onclick="zenPage.checkboxModified(4,0);"/>
<checkbox id="chkPriv5" caption="DELETE" captionClass="normal" onclick="zenPage.checkboxModified(5,0);"/>
<checkbox id="chkPriv6" caption="REFERENCES" captionClass="normal" onclick="zenPage.checkboxModified(6,0);"/>
</vgroup>
<vgroup containerStyle="border:1px white solid;" hidden="#(%page.IsNotProcedure)#">
<checkbox id="chkPriv7" caption="EXECUTE" captionClass="normal" value="1" onclick="zenPage.checkboxModified(7,0);"/>
</vgroup>
<vgroup containerStyle="border:1px white solid;" hidden="#(%page.HideUse)#">
<checkbox id="chkPriv8" caption="USE" captionClass="normal" value="1" onclick="zenPage.checkboxModified(8,0);"/>
</vgroup>
</vgroup>
<vgroup>
<vgroup label="Grant Admin" align="center" containerStyle="border:1px white solid;font-size:12px;font-weight:bold;padding:2px;">
<checkbox id="chkGrant" onclick="zenPage.toggleChecks(1,zenThis.getValue());" hidden="#(%page.IsNotRelation)#"/>
</vgroup>
<vgroup align="center" containerStyle="border:1px white solid;border-bottom:0;" hidden="#(%page.IsNotRelation)#">
<checkbox id="chkGrant1" onclick="zenPage.checkboxModified(1,1);"/>
<checkbox id="chkGrant2" onclick="zenPage.checkboxModified(2,1);"/>
<checkbox id="chkGrant3" onclick="zenPage.checkboxModified(3,1);"/>
<checkbox id="chkGrant4" onclick="zenPage.checkboxModified(4,1);"/>
<checkbox id="chkGrant5" onclick="zenPage.checkboxModified(5,1);"/>
<checkbox id="chkGrant6" onclick="zenPage.checkboxModified(6,1);"/>
</vgroup>
<vgroup containerStyle="border:1px white solid;" hidden="#(%page.IsNotProcedure)#">
<checkbox id="chkGrant7" onclick="zenPage.checkboxModified(7,1);"/>
</vgroup>
<vgroup containerStyle="border:1px white solid;" hidden="#(%page.HideUse)#">
<checkbox id="chkGrant8" onclick="zenPage.checkboxModified(8,1);"/>
</vgroup>
</vgroup>
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
	if (this.ObjName != "") {
		this.toggleSave(true);
	} else {
		if (this.Schema == "") {
			this.toggleSave(false);
		} else {
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
	this.Schema = newVal;
	this.Tables = '';
	this.clearList(this.avaList,1);
	this.clearList(this.selList,1);
	zen('selectBoxes').refreshContents();
	this.doModified();
}

/// User clicked the Privilege/Grant Admin checkbox.
ClientMethod toggleChecks(g, newVal) [ Language = javascript ]
{
	// if Grant Adm is checked, then the Priv is also checked.
	if (g == 1) {
		for (var r=1;r<=this.PrivCount;r++) {
			// check/uncheck Grant
			zen("chkGrant"+r).setValue(newVal);
			// check Priv only if newVal is 1
			if (newVal == 1) zen("chkPriv"+ r).setValue(newVal);
		}
		if (newVal == 1) zen("chkPriv").setValue(newVal);
	} else {
		for (var r=1;r<=this.PrivCount;r++) {
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
	if (this.IsNotProcedure) {
		this.checkAll('chkPriv');
		this.checkAll('chkGrant');
	}
	
	this.doModified();
}

/// Check if Priv or Grant are all checked. 
/// check chkPriv/chkGrant if all its checkboxes are checked; uncheck if at least one is unchecked.
ClientMethod checkAll(ID) [ Language = javascript ]
{
	var checked = 0;
	for (var r=1;r<=this.PrivCount;r++) {
		if (zen(ID + r).getValue()==1) {
			checked++;
		}
	}
	var chkID = zen(ID);
	if (checked == this.PrivCount) {
		chkID.setValue(1);	
	} else {
		chkID.setValue(0);
	}
}

ClientMethod isSomethingChecked() [ Language = javascript ]
{
	if (this.IsRelation) {
		if (zen("chkPriv").getValue() == 1) return true;
		if (zen("chkGrant").getValue() == 1) return true;

		for (var r=1;r<=this.PrivCount;r++) {
			if (zen("chkPriv"+r).getValue() == 1) return true;
			if (zen("chkGrant"+r).getValue() == 1) return true;
		}
	} else if (this.IsProcedure) {
		if (zen("chkPriv"+7).getValue() == 1) return true;
		if (zen("chkGrant"+7).getValue() == 1) return true;
	} else if (this.IsMLConfiguration || this.IsForeignServer) {
		// USE
		if (zen("chkPriv"+8).getValue() == 1) return true;
		if (zen("chkGrant"+8).getValue() == 1) return true;
	}
	return false;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		// "new" dialog
		if (this.ObjName == '') {
			this.Tables = this.getSelList(',',false,true);
		}
		if (this.Tables == "") this.Tables = this.ObjName, this.Schema = "";	// ML Configuration has no schema
		
		var priv = "";
		var grant = "";
		for (var r=1;r<=this.PrivCount;r++) {
			if (zen("chkPriv"+r).getValue() == 1) priv = priv+","+ r;
			if (zen("chkGrant"+r).getValue() == 1) grant = grant+","+r;
		}
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.ObjectType = this.ObjectType;
		proxy.Schema = this.Schema;
		proxy.Tables = this.Tables;
		proxy.priv = priv;
		proxy.grant = grant;
		proxy.IncludeSystem = this.IncludeSystem;
		
		var result = this.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage,true);
			return false;
		} else {
			zen('btnCancel').setProperty('caption',$$$Text('Close'));
			return true;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Save column priv data to server
/// If this is to revoke column priv, then pRevoke = 1, pPrivs and pGrant will be null.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Set tResult = ""

		Set GrantedBy = $Username
		Set nType = $S(pProxy.ObjectType="TABLE":1,pProxy.ObjectType="VIEW":3,pProxy.ObjectType="ML CONFIGURATION":6,pProxy.ObjectType="FOREIGN SERVER":7,1:9)
		
		For i=1:1:$LENGTH(pProxy.Tables,",") {
			if pProxy.Schema'="" { Set sObj = pProxy.Schema_"."_$tr($PIECE(pProxy.Tables,",",i),".",$c(2)) }
			else                 { Set sObj = pProxy.Tables }	// ML Configuration
			
			// first remove all privileges then save the ones user selected.
			Set tSC = ##class(%SQL.Manager.API).SaveObjPriv("*",nType,sObj,pProxy.PID,0,1,.SQLCODE,.sMsg,GrantedBy)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			If SQLCODE '= 0 {
				Set tResult = pProxy.ObjName_$$$TextHTML("Save failed. Could not remove existing privileges.")_" "_sMsg
				Throw
			}
			
			#; for every selected priv, grant the privilege:
			For j=2:1:$LENGTH(pProxy.priv,",") {
				Set priv = $PIECE(pProxy.priv,",",j)
				Set nGrant = pProxy.grant [ priv
				Set action = $CASE(priv,1:"a",2:"s",3:"i",4:"u",5:"d",6:"r",8:"l",:"e")
				if nType=9,action'="e" { continue }
				if nType=6,action'="l" { continue }
				if nType=7,",a,l,"'[(","_action_",") { continue }
				Set tSC = ##class(%SQL.Manager.API).SaveObjPriv(action,nType,sObj,pProxy.PID,nGrant,0,.SQLCODE,.sMsg,GrantedBy,.fields)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			     	If SQLCODE '= 0 {
				     	Set tResult = pProxy.ObjName_$$$TextHTML("Save failed. Please make sure that you have sufficient SQL privileges to perform this operation.")_" "_sMsg
				     	Throw
			     	}
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

Method PopulateSchemas() As %Status
{
	Try {
		Set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:SchemasOnly")
		Set tSC = rs.Execute(+..IncludeSystem,..ObjectType,1)
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

ClassMethod MatchSchema(PID As %String, Schema As %String, Output Defined As %String) As %Status
{
	Try {
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserPrivs")
		Do tRS.Execute(PID,1)
		Set schema = $ZCVT(Schema,"L")_"."
		While tRS.Next() {
			Set name = tRS.Get("NAME")
			If (tRS.Get("HAS_COLUMN_PRIV") = 1) Continue
			If $ZCVT($E(name,1,$L(Schema)),"L")_"." = schema {
				Set name = $E(name,$L(schema)+1,$L(name))
				If name'="" Set Defined(name) = "" 
			}
		}
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

/// tables based on object type and schema name
ClassMethod ListTables(PID As %String, objtype As %String, schema As %String, Output tSC As %Status) As %Integer
{
	Try {
		Set tSC = $$$OK
		Set total = 0
		
		If objtype = "TABLE" {
			Set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:TablesOnly")
			Set tSC = rs.Execute(schema,1)
		} ElseIf objtype = "VIEW" {
			Set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewsOnly")
			Set tSC = rs.Execute(schema,1)
		} ElseIf objtype = "FOREIGN SERVER" {
			Set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ForeignServers")
			Set tSC = rs.Execute(schema, 1)
		} Else {
			Set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Procedures")
			Set tSC = rs.Execute(schema,1,,2)
		}
 		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
 		
		Set tSC = ..MatchSchema(PID,schema,.Defined)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		While rs.Next() {
			Set tablename = rs.GetData(1)
			set:(objtype = "FOREIGN SERVER") tablename = $$$LastPiece(tablename, ".")
			If '$D(Defined(tablename)) {
				Set total = total + 1
				&html<<option value="#(tablename)#">#(..EscapeHTML(tablename))#</option>>
			}
		}
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit total
}

Method DrawSelectBoxes(seed As %String) As %Status
{
	Try {
		// Draw the Available list box
		Set tSC = ..DrawAvailableList("",1)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If ..Schema '= "" {
			Set ..TotalTables = ..ListTables(..PID,..ObjectType,..Schema,.tSC)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}

		// Draw the arrows and Select list box
		Set tSC = ..DrawSelectList("",1)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		&html<<span class="normal">#($$$TextHTML("Total found"))#: #(..TotalTables)#</span>>
		
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
	
	If ..ObjectType = "STORED PROCEDURE" Set ..ObjectType = "PROCEDURE"
	
	If ..ObjectType = "VIEW" {	
		Set ..%GetComponentById("chkPriv6").hidden = 1
		Set ..%GetComponentById("chkGrant6").hidden = 1
	}

	#; ObjName = null for Add, or Table name or View name for Edit
	If ..ObjName '= "" {
		Set ..Schema = $PIECE(..ObjName,".",1)
		Set ..Tables = $PIECE(..ObjName,".",2,*)
		Set ObjNameComp = ..%GetComponentById("ObjName")
		Set ObjNameComp.value = ..ObjName
		Set ObjNameComp.hidden = 0
		Set ObjNameComp.label = $CASE(..ObjectType,"TABLE":$$$TextHTML("Table"),"VIEW":$$$TextHTML("View"),"ML CONFIGURATION":$$$TextHTML("ML Configuration"),:$$$TextHTML("Procedure"))
		
		Set GrantedBy = $S(..ObjectType'="PROCEDURE":$PIECE(..ObjPriv,",",8),1:$PIECE(..ObjPriv,",",3))
		Set (checkAll1,checkAll2) = 1
		If (..ObjectType="TABLE")||(..ObjectType="VIEW") {
			For i = 1:1:6 {
				Set p = $P(..ObjPriv,",",i)
				Set ..%GetComponentById("chkPriv"_i).value = $S(p>0:1,1:0)
				Set ..%GetComponentById("chkGrant"_i).value = $S(p=2:1,1:0)
				Set:p="" checkAll1 = 0
				Set:p'=2 checkAll2 = 0
			}
			Set ..%GetComponentById("chkPriv").value = checkAll1
			Set ..%GetComponentById("chkGrant").value = checkAll2
		} Elseif (..ObjectType="PROCEDURE") {
			Set p = $P(..ObjPriv,",",1)
			Set ..%GetComponentById("chkPriv7").value = $S(p>0:1,1:0)
			Set ..%GetComponentById("chkGrant7").value = $S(p=2:1,1:0)
		} Else {	// ML Configuration
			Set p = $P(..ObjPriv,",",1)
			Set ..%GetComponentById("chkPriv8").value = $S(p>0:1,1:0)
			Set ..%GetComponentById("chkGrant8").value = $S(p=2:1,1:0)
		}
		Set ..%GetComponentById("cmbSchema").hidden = 1
		Set ..%GetComponentById("selectBoxes").hidden = 1
	}
	
	Set ..IsProcedure = (..ObjectType="PROCEDURE"),..IsNotProcedure='..IsProcedure
	Set ..IsMLConfiguration=(..ObjectType="ML CONFIGURATION"),..IsNotMLConfiguration='..IsMLConfiguration
	Set ..IsForeignServer=(..ObjectType="FOREIGN SERVER"),..IsNotForeignServer='..IsForeignServer
	Set ..IsRelation = (('..IsProcedure)&&('..IsMLConfiguration)&&('..IsForeignServer)),..IsNotRelation='..IsRelation
	// privs are labeled 1-8 which determines what to loop over, e.g. USE is chkPriv8, so even though it's the only
	// priv for ML Configs, they need to loop through to the 8th to check for it
	Set ..PrivCount = $SELECT(..IsProcedure=1:7,..IsMLConfiguration=1:8,..IsForeignServer:8,1:6)

	// We can't use logic inside of the hidden attribute of the HTML elements in the XData block above (shows the user which privileges they can
	// assign based on the type). So we'll do the logic here and store the value
	Set ..HideUse = (..IsNotMLConfiguration && ..IsNotForeignServer)
	
	Set tSC = ..PopulateSchemas()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If ..ObjectType = "TABLE" {
		Set tTitle = $$$FormatText($$$TextHTML("Grant table privileges to %1"),$zconvert(..PID,"O","HTML"))
	} ElseIf ..ObjectType = "VIEW" {
		Set tTitle = $$$FormatText($$$TextHTML("Grant view privileges to %1"),$zconvert(..PID,"O","HTML"))
	} ElseIf ..ObjectType = "ML CONFIGURATION" {
		Set tTitle = $$$FormatText($$$TextHTML("Grant ml configuration privileges to %1"),$zconvert(..PID,"O","HTML"))
	} ElseIf ..ObjectType = "FOREIGN SERVER" {
		Set tTitle = $$$FormatText($$$TextHTML("Grant foreign server privileges to %1"),$zconvert(..PID,"O","HTML"))
	} Else {
		Set tTitle = $$$FormatText($$$TextHTML("Grant procedure privileges to %1"),$zconvert(..PID,"O","HTML"))
	}
	
	Quit tTitle
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
