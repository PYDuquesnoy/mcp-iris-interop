/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Advanced Configuration
Class %CSP.UI.Portal.Config.Advanced [ Abstract, System = 4 ]
{

Property Properties As %String;

/// Subject name for the setting page. 
Property Subject As %String;

/// Override in subclass
ClientMethod validate() As %Boolean [ Language = javascript ]
{
	return true;
}

/// Save current item. Subclass may override.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		// if user has not changed anything but hit Save, then we can just close out.
		if (!this.validate()) {
			this.afterValidate();
			return;
		}
		if (!this.pageModified) {
			this.doCancel();
			return;
		}
		var parray = this.Properties.split(",");
		var len = parray.length;
		var id = "";
		var values = "";
		for (i=0;i<len;i++) {
			id = parray[i];
			values = values + "|$|" + zen(id).getValue();
		}
		var result = this.SaveData(this.Subject,this.Properties,values);
		this.afterSave(result);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod SaveData(Subject As %String, Properties As %String, Values As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		For i=1:1:$L(Properties,",") {
			Set t = $P(Properties,",",i)
			Set p(t) = $P(Values,"|$|",i+1)
		}
		If Subject = "Cluster" {
			Set tSC = ##class(Config.config).Get(.Prop)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			// Save this directory only if it is changed
			If Prop("pijdir") '= p("pijdir") {
				Set Prop("pijdir") = p("pijdir")
				Set tSC = ##class(Config.config).Modify(.Prop)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
			Kill Prop,p("pijdir")
		}
		Set tSC = $classmethod("Config."_Subject,"Modify",.p)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","HTML")
	}
	Quit tProxy
}

Method PopulateFields() As %Status
{
	Set tSC = $classmethod("Config."_..Subject,"Get",.Properties)
	If $$$ISERR(tSC) Quit tSC
	
	#; For Cluster, add pijdir from Config.config to the list
	If ..Subject = "Cluster" {
		Set tSC = ##class(Config.config).Get(.Properties2)
		If $$$ISERR(tSC) Quit tSC
		Set Properties("pijdir") = Properties2("pijdir")
		Kill Properties2
	}
	Set (tProperty,p) = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set p = p_","_tProperty
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	Set ..Properties = $E(p,2,9999)
	
	If (..Subject = "Cluster") && ..IsEMSReadOnly {
		Set ..%GetComponentById("Browse").hidden = 1
	}
	
	Quit $$$OK
}

}
