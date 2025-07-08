/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit Service Popup Dialog for Management Portal
Class %CSP.UI.Portal.Mappings.Routine Extends %CSP.UI.Portal.Mappings.Template [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mappings.Routine.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Routine Mapping";

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed="#(%page.MappingName)#"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group cellStyle="padding:0 4px;" labelPosition="left">
<dataCombo id="Database"
label="Routine Database Location"
queryClass="Config.Databases"
queryName="List"
showEmpty="true"
dropdownHeight="300px"
dropdownWidth="200px"
displayColumns="1"
choiceColumn="1"
valueColumn="1"
maxRows="100000"
hint="Required."
onchange="zenPage.checkFields();"
>
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="0"/>
</dataCombo>
<spacer height="5px"/>
<text id="RoutineName" label="Routine Name" size="40" hint="Required." onkeyup="zenPage.checkFields();"/>
</group>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zen('Database').getValue() == '') {
		zen('Database').focus();
	} else if (zen('RoutineName').getValue() == '') {
		zen('RoutineName').focus();
	}
}

ClientMethod checkFields() [ Language = javascript ]
{
	var disableButtons = ((zen('Database').getValue() == "") || (zen('RoutineName').getValue() == ""))
	this.toggleButtons(disableButtons);
}

ClientMethod validate() [ Language = javascript ]
{
	this.resetMsg();
	var Database = zen('Database');
	var DatabaseValue = Database.getValue();
	var RoutineName = zen('RoutineName');
	var RoutineNameValue = RoutineName.getValue();
	var pass = true;
	var msg = $$$Text("There was a problem with the form. See the highlighted fields below.");
	
	if (DatabaseValue == '') {
		Database.setProperty('hintClass','redText');
		if (pass) {
			Database.focus();
		}
		pass = false;
	} else {
		Database.setProperty("hintClass","helpText");
	}
	if (RoutineNameValue == '') {
		RoutineName.setProperty('hintClass','redText');
		if (pass) {
			RoutineName.focus();
		}
		pass = false;
	} else {
		RoutineName.setProperty("hintClass","helpText");
	}
		
	if (!pass) {
		this.showMsg(msg);
	}
	
	return pass;
}

ClientMethod doSave() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.Database = zen('Database').getValue();
		proxy.RoutineName = zen('RoutineName').getValue();
		proxy.RoutineType = "ALL";
		proxy.Namespace = this.Namespace;
		proxy.IsNew = this.IsNew;
		proxy.OldMappingName = this.MappingName;
		proxy.CPFMapFile = this.CPFMapFile;
		proxy.CPFMapName = this.CPFMapName;
		
		var result = zenPage.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage,true);
			return false;
		} 
		return true;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	return false;
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set inTrans = 0
		
		Set Namespace = pProxy.Namespace
		Set RoutineName = pProxy.RoutineName
		Set RoutineType = pProxy.RoutineType
		Set FullRoutineName = RoutineName_$s(RoutineType="":"",1:"_"_RoutineType)
		Set Properties("Database") = pProxy.Database

		TSTART
		Set inTrans = 1
	
		If 'pProxy.IsNew {
			#;If the name has changed, we need to delete the old name, and add in the new name
			#;as part of the same transaction.
			If FullRoutineName '= pProxy.OldMappingName {
				Set tSC = ##class(Config.MapRoutines).Delete(Namespace,pProxy.OldMappingName,pProxy.CPFMapFile,$$$CPFSave)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				Set createNew = 1
			} Else {
				Set tSC = ##class(Config.MapRoutines).Modify(Namespace,FullRoutineName,.Properties,pProxy.CPFMapFile,$$$CPFSave)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		
		If (pProxy.IsNew || $G(createNew)) {
			Set tSC = ##class(Config.MapRoutines).Create(Namespace,FullRoutineName,.Properties,pProxy.CPFMapFile,$$$CPFSave)
			If $$$ISERR(tSC) {
				If $$$GETERRORCODE(tSC) = $$$ERRORCODE($$$IDKeyNotUnique) {
					Set tSC = $$$ERROR($$$CPFMappingAlreadyExists,FullRoutineName)
				}
				throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		
		#;Flag to let us know that we have changed mappings
		Set $$$CONFIG3(pProxy.CPFMapName,"MapRoutines",Namespace) = 1
		TCOMMIT
		Set inTrans = 1
		
		#;These maybe used for defaults in this session.
		Set %session.Data("Mapping","RoutineDataLocation") = pProxy.Database
		Set %session.Data("Mapping","RoutineName") = RoutineName
		Set %session.Data("Mapping","RoutineType") = RoutineType
		
		Set tProxy.ok = 1
	} Catch Error {
		If $G(inTrans) TROLLBACK
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Routine Mapping")
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
	
	Set tSC = ##Class(Config.CPF).FileToName(,,.CPFMapFile,.CPFMapName)
	If $$$ISERR(tSC) Quit tSC
	Set ..CPFMapFile = CPFMapFile
	Set ..CPFMapName = CPFMapName
	
	Set ..%GetComponentById("Database").value = $G(%session.Data("Mapping","RoutineDataLocation"))
	
	If ..MappingName '= "" {
		Set ..%GetComponentById("RoutineName").value = $P(..MappingName,"_",1)

		Set tSC = ##class(Config.MapRoutines).Get(..Namespace,..MappingName,.Properties,..CPFMapFile)
		If $$$ISERR(tSC) Quit tSC
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
				If ..IsEMSReadOnly Set Component.disabled = 1
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
	} Else {
		If $G(%session.Data("Mapping","RoutineSubscript")) '= "" {
			Set ..%GetComponentById("RoutineName").value = $G(%session.Data("Mapping","RoutineName"))
		}
	}
	
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	If pSeed = "" {
		Set tPageTitle = $$$FormatText($$$Text("Map a new routine in namespace %1"),..EscapeHTML(%page.Namespace))_"<br/>"
	} Else {
		Set tPageTitle = $$$FormatText($$$Text("Edit routine mapping in namespace %1"),..EscapeHTML(%page.Namespace))_"<br/>"
	}
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
