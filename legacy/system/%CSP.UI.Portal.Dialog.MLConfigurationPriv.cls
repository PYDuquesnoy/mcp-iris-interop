/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Page to define ML Configuration privileges.
Class %CSP.UI.Portal.Dialog.MLConfigurationPriv Extends (%CSP.Portal.standardDialog, %CSP.UI.Component.SelectBoxUtils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter AUTONS As BOOLEAN = 1;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.MLConfigurationPriv.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ML Configuration Privileges";

Parameter RESOURCE = "%Admin_Secure:USE";

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

/// ObjName = null for Add, or ML Configuration
Property ObjName As %String(ZENURL = "ObjName");

/// ObjName = null for Add, or ML COnfiguration name for Edit
Property ObjPriv As %String(ZENURL = "ObjPriv");

/// "MLCONFIGURATION".
Property ObjectType As %String(ZENURL = "Type");

Property Names As %String;

/// Total number of existing ML Configurations for edit
Property TotalMLConfigurations As %Integer [ InitialExpression = 0 ];

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
<html id="selectBoxes" OnDrawContent="DrawSelectBoxes"/>
<hgroup id="PrivTable">
<vgroup>
<vgroup label="Privilege" align="center" containerStyle="border:1px white solid;font-size:12px;font-weight:bold;padding:2px;">
</vgroup>
<vgroup containerStyle="border:1px white solid;">
<checkbox id="chkPriv8" caption="USE" captionClass="normal" value="1" onclick="zenPage.checkboxModified(8,0);"/>
</vgroup>
</vgroup>
<vgroup>
<vgroup label="Grant Admin" align="center" containerStyle="border:1px white solid;font-size:12px;font-weight:bold;padding:2px;">
</vgroup>
<vgroup containerStyle="border:1px white solid;">
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

/// User clicked the Privilege/Grant Admin checkbox.
ClientMethod toggleChecks(g, newVal) [ Language = javascript ]
{
	// if Grant Adm is checked, then the Priv is also checked.
	if (g == 1) {
		for (var r=8;r<=this.PrivCount;r++) {
			// check/uncheck Grant
			zen("chkGrant"+r).setValue(newVal);
			// check Priv only if newVal is 1
			if (newVal == 1) zen("chkPriv"+ r).setValue(newVal);
		}
		if (newVal == 1) zen("chkPriv").setValue(newVal);
	} else {
		for (var r=8;r<=this.PrivCount;r++) {
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
	this.doModified();
}

/// Check if Priv or Grant are all checked. 
/// check chkPriv/chkGrant if all its checkboxes are checked; uncheck if at least one is unchecked.
ClientMethod checkAll(ID) [ Language = javascript ]
{
	var checked = 0;
	for (var r=8;r<=this.PrivCount;r++) {
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
	if (zen("chkPriv"+8).getValue() == 1) return true;
	if (zen("chkGrant"+8).getValue() == 1) return true;
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
			this.Names = this.getSelList(',',false,true);
		}
		if (this.Names == "") return;
		
		var priv = "";
		var grant = "";
		for (var r=8;r<=this.PrivCount;r++) {
			if (zen("chkPriv"+r).getValue() == 1) priv = priv+","+ r;
			if (zen("chkGrant"+r).getValue() == 1) grant = grant+","+r;
		}
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.ObjectType = this.ObjectType;
		proxy.Names = this.Names;
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

/// Save ML Configuration priv data to server
/// If this is to revoke priv, then pRevoke = 1, pPrivs and pGrant will be null.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Set tResult = ""

		Set GrantedBy = $Username
		Set nType = 6
		
		For i=1:1:$LENGTH(pProxy.Names,",") {
			Set sObj = $p(pProxy.Names,",",i)
			
			// first remove all privileges then save the ones user selected.
			Set tSC = ##class(%SQL.Manager.API).SaveObjPriv("*",nType,sObj,pProxy.PID,0,1,.SQLCODE,.sMsg,GrantedBy)
			If $$$ISERR(tSC) { throw ##Class(%Exception.StatusException).CreateFromStatus(tSC) }
			If SQLCODE '= 0 {
				Set tResult = pProxy.ObjName_$$$TextHTML("Save failed. Could not remove existing privileges.")_" "_sMsg_"</br>"
				Throw
			}
			
			#; for every selected priv, grant the privilege:
			For j=2:1:$LENGTH(pProxy.priv,",") {
				Set priv = $PIECE(pProxy.priv,",",j)
				Set nGrant = pProxy.grant [ priv
				Set action = "l"
				Set tSC = ##class(%SQL.Manager.API).SaveObjPriv(action,nType,sObj,pProxy.PID,nGrant,0,.SQLCODE,.sMsg,GrantedBy,.fields)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			     	If SQLCODE '= 0 {
				     	Set tResult = pProxy.ObjName_$$$TextHTML("Save failed. Please make sure that you have sufficient SQL privileges to perform this operation.")_" "_sMsg_"</br>"
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

ClassMethod MLConfigurations(PID As %String, objtype As %String, Output tSC As %Status) As %Integer
{
	Try {
		Set tSC = $$$OK
		Set total = 0
		
		Set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:MLConfigurations")
		Set tSC = rs.Execute(1)
 		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
 		
		While rs.Next() {
			Set mlconfig = rs.GetData(1)
			If '$D(Defined(mlconfig)) {
				Set total = total + 1
				&html<<option value="#(mlconfig)#">#(..EscapeHTML(mlconfig))#</option>>
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
		
		Set ..TotalMLConfigurations = ..MLConfigurations(..PID,..ObjectType,.tSC)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		// Draw the arrows and Select list box
		Set tSC = ..DrawSelectList("",1)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		&html<<span class="normal">#($$$TextHTML("Total found"))#: #(..TotalMLConfigurations)#</span>>
		
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
	
	Set ..ObjectType = "MLCONFIFIGURATION"
	
	#; ObjName = null for Add, or Table name or View name for Edit
	If ..ObjName '= "" {
		Set ..Names = ..ObjName
		Set ObjNameComp = ..%GetComponentById("ObjName")
		Set ObjNameComp.value = ..ObjName
		Set ObjNameComp.hidden = 0
		Set ObjNameComp.label = $$$TextHTML("ML Configurations")
		
		Set GrantedBy = $PIECE(..ObjPriv,",",3)
		Set (checkAll1,checkAll2) = 1
		Set p = $P(..ObjPriv,",",1)
		Set ..%GetComponentById("chkPriv8").value = $S(p>0:1,1:0)
		Set ..%GetComponentById("chkGrant8").value = $S(p=2:1,1:0)
		
		Set ..%GetComponentById("selectBoxes").hidden = 1
	}
	
	Set ..PrivCount = 8
	
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set tTitle = $$$FormatText($$$TextHTML("Grant ML Configuration privileges to %1"),$zconvert(..PID,"O","HTML"))
	Quit tTitle
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
