/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Advanced Configuration
Class %CSP.UI.Portal.Config.AdvancedEdit [ Abstract, System = 4 ]
{

/// ID for edit. Null if adding new device.
Property PID As %String;

/// Subject name for the setting page. 
Property Subject As %String;

XData Style
{
<style type="text/css">
.zenLabelDisabled,a.radioSetCaptionDisabled { color:black; }
</style>
}

/// Override in subclass
ClientMethod validate() [ Language = javascript ]
{
	return true;
}

/// Override in subclass
ClientMethod getProxy() [ Language = javascript ]
{
	var proxy = new zenProxy();
	return proxy;
}

/// Save current item. Subclass may override.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		// if user has not changed anything but hit Save, then we can just close out.
		if (!this.pageModified) {
			this.doCancel();
			return;
		}
		if (!this.validate()) {
			this.afterValidate();
			return;
		}
		
		var proxy = zenPage.getProxy();

		var result = this.SaveData(this.Subject,this.PID,proxy);
		this.afterSave(result);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod GetPropertyArray(pProxy As %ZEN.proxyObject, Output Properties) As %Status
{
	Quit $$$OK
}

/// Call server save method.
ClassMethod SaveData(Subject As %String, PID As %String, pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tClass = "Config."_..GetClassName(Subject)
		
		Set tSC = ..GetPropertyArray(pProxy,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If (PID '= "") {
			Set tSC = $classmethod(tClass,"Modify",PID,.Properties)
		} Else {
			Set tSC = $classmethod(tClass,"Create",pProxy.Name,.Properties)
		}
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","HTML")
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

Method PopulateFields() As %Status
{
	If ..PID '= "" {
		Set ..%GetComponentById("Name").value = ..PID
		
		If '$$$comMemberDefined("Config."_..GetClassName(..Subject),$$$cCLASSmethod,"Get") {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Quit $$$OK
		}
		
		Set tSC = $classmethod("Config."_..GetClassName(..Subject),"Get",..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Quit $$$OK
		}
		Set (tProperty,p) = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
				If ..IsEMSReadOnly Set Component.disabled = 1
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
		
		If (..Subject = "Device") {
			Set ..%GetComponentById("SubType").originalValue = Properties("SubType")
		}
		
		Set ..%GetComponentById("Name").disabled = 1
	}
	
	Quit $$$OK
}

}
