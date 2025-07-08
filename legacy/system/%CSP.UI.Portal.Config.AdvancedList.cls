/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Advanced Configuration
Class %CSP.UI.Portal.Config.AdvancedList [ Abstract, System = 4 ]
{

Property EditPage As %String;

/// Subject name for the setting page. 
Property Subject As %String;

XData Style
{
<style type="text/css">
.brownnote {
	font-size: 0.8em;
	color: #000000;
}
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}
table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
</style>
}

/// User clicked the "New" button
ClientMethod doNew(passSubject) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	this.editItem('',true,passSubject);
}

/// User clicked the Add or Edit button.
ClientMethod editItem(PID, isNew, passSubject) [ Language = javascript ]
{
	try {
		if (!isNew && (PID == "")) PID = zen("table").getValue();
		var url = this.EditPage+"?PID="+encodeURIComponent(PID);
		if (passSubject) {
			url += "&Subject="+this.Subject;
		}
		this.gotoPage(url);
	 } catch (ex) {
		alert("Error: " + ex);
	 }
}

/// Delete existing item.
ClientMethod deleteItem(name) [ Language = javascript ]
{
	try {
		if (this.IsEMSReadOnly) return;
 		var idRow = zen("table").getValue();
		var result = this.DeleteData(this.Subject,idRow);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage);
		} else {
			this.refreshTable();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Refresh table.
ClientMethod refreshTable() [ Language = javascript ]
{
	try {
		var table = zen('table');
		table.executeQuery();
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Call server delete method.
ClassMethod DeleteData(Subject As %String, Name As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tClass = "Config."_..GetClassName(Subject)
		Set tSC = $classmethod(tClass,"Delete",Name)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
 	Quit tProxy
}

/// Get Class Name by Subject for package = "Config"
ClassMethod GetClassName(Subject As %String) As %String
{
	If Subject [ "Device" Quit "Devices"
	If Subject [ "MagTape" Quit "MagTapes"
	If Subject [ "SubType" Quit "DeviceSubTypes"
	If Subject [ "SystemDataType" Quit "SqlSysDatatypes"
	If Subject [ "UserDataType" Quit "SqlUserDatatypes"
	Quit Subject
}

}
