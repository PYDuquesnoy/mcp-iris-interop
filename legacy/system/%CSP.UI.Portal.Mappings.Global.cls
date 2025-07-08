/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit Service Popup Dialog for Management Portal
Class %CSP.UI.Portal.Mappings.Global Extends %CSP.UI.Portal.Mappings.Template [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mappings.Global.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Global Mapping";

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed="#(%page.MappingName)#"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="editGroup" labelPosition="left">
<group cellStyle="padding:0 4px;" labelPosition="left">
<dataCombo id="Database"
label="Global Database Location"
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
onchange="zenPage.doChangeDB(zenThis.getValue());zenPage.checkFields();"
>
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter id="DBParam" value="0"/>
</dataCombo>
<spacer height="5px"/>
<text id="GlobalName" label="Global Name" size="40" hint="Required." onkeyup="zenPage.checkFields();"/>
<hgroup label="Global Subscripts to be Mapped" cellVAlign="top">
<text id="Subscript" size="40" 
onkeyup="zenPage.doChangeSubscript(zenThis.getValue());zenPage.checkFields();"
hint="Subscript reference must begin with an open parenthesis."/>
<link caption="Click here to see examples" href="#" onclick="zenPage.toggle('ExampleText');"/>
</hgroup>
<html id="ExampleText" hidden="true" OnDrawContent="DrawExample"/>
</group>
<link id="AdvancedSettings" caption="Advanced Settings" href="#" onclick="zenPage.toggle('AdvancedGroup');"/>
<group id="AdvancedGroup" hidden="true" labelPosition="left" cellStyle="padding:0 4px;">
<select id="Collation" label="Collation" hint="Collation applies only to new subscript-level mapping globals." showEmpty="false"/>
<dataCombo id="LockDatabase"
label="Lock Database Location"
queryClass="Config.Databases"
queryName="List"
showEmpty="true"
dropdownHeight="300px"
dropdownWidth="200px"
displayColumns="1"
choiceColumn="1"
valueColumn="1"
maxRows="100000"
hint="Lock database can only be set for a global mapping itself, not subscript-level mapping."
>
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter id="LockDBParam" value="0"/>
</dataCombo>
</group>
</group>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zen('Database').getValue() == '') {
		zen('Database').focus();
	} else if (zen('GlobalName').getValue() == '') {
		zen('GlobalName').focus();
	} else {
		zen('Subscript').focus();
	}
}

ClientMethod toggle(groupID) [ Language = javascript ]
{
	var group = zen(groupID);
	group.setHidden(!group.getProperty('hidden'))
}

ClientMethod checkFields() [ Language = javascript ]
{
	var disableButtons = ((zen('Database').getValue() == "") || (zen('GlobalName').getValue() == ""))
	this.toggleButtons(disableButtons);
}

ClientMethod doChangeDB(newVal) [ Language = javascript ]
{
	zen('LockDatabase').setValue(newVal);
	zen('Subscript').setDisabled(newVal == "%DEFAULTDB");
}

ClientMethod doChangeSubscript(newVal) [ Language = javascript ]
{
	zen('LockDatabase').setDisabled(newVal != "");
	if (newVal != "") {
		zen('AdvancedGroup').setHidden(1);
		zen('AdvancedSettings').setHidden(1);
	} else {
		zen('AdvancedSettings').setHidden(0);
	}
}

ClientMethod validate() [ Language = javascript ]
{
	this.resetMsg();
	var Database = zen('Database');
	var DatabaseValue = Database.getValue();
	var GlobalName = zen('GlobalName');
	var GlobalNameValue = GlobalName.getValue();
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
	if (GlobalNameValue == '') {
		GlobalName.setProperty('hintClass','redText');
		if (pass) {
			GlobalName.focus();
		}
		pass = false;
	} else {
		GlobalName.setProperty("hintClass","helpText");
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
		proxy.GlobalName = zen('GlobalName').getValue();
		proxy.Subscript = zen('Subscript').getValue();
		proxy.Collation = zen('Collation').getValue();
		proxy.LockDatabase = zen('LockDatabase').getValue();
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

ClassMethod DrawExample(pSeed) As %Status
{
	&html<<span style="font-weight:normal;font-size:11px;">(1)<br>("A")<br>(1):(5)<br>("A"):("Z")<br>
	(#($$$TextHTML("BEGIN"))#):("X")<br>("Y"):(#($$$TextHTML("END"))#)</span>>
	Quit $$$OK
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set inTrans = 0
		
		#;Make sure subscript starts with a "(". If this is not here, then we can't tell where the
		#;global name ends, and the subscript begins when we concatentate them.
		Set Subscript = pProxy.Subscript
		If Subscript '= "" {
			If ($E(Subscript) '= "(") Set Subscript = "("_Subscript
			If ($E(Subscript,*) '= ")") Set Subscript = Subscript_")"
		}

		Set Namespace = pProxy.Namespace
		Set GlobalName = pProxy.GlobalName
		Set FullGlobalName = GlobalName_Subscript
		
		Set Properties("Database") = pProxy.Database
		Set Properties("LockDatabase") = pProxy.LockDatabase
		Set Properties("Collation") = pProxy.Collation

		TSTART
		Set inTrans = 1
	
		If 'pProxy.IsNew {
			#;If the name has changed, we need to delete the old name, and add in the new name
			#;as part of the same transaction.
			If FullGlobalName '= pProxy.OldMappingName {
				Set tSC = ##class(Config.MapGlobals).Delete(Namespace,pProxy.OldMappingName,pProxy.CPFMapFile,$$$CPFSave)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				Set createNew = 1
			} Else {
				Set tSC = ##class(Config.MapGlobals).Modify(Namespace,FullGlobalName,.Properties,pProxy.CPFMapFile,$$$CPFSave)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		
		If (pProxy.IsNew || $G(createNew)) {
			Set tSC = ##class(Config.MapGlobals).Create(Namespace,FullGlobalName,.Properties,pProxy.CPFMapFile,$$$CPFSave)
			If $$$ISERR(tSC) {
				If $$$GETERRORCODE(tSC) = $$$ERRORCODE($$$IDKeyNotUnique) {
					Set tSC = $$$ERROR($$$CPFMappingAlreadyExists,FullGlobalName)
				}
				throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		
		#;Flag to let us know that we have changed mappings
		Set $$$CONFIG3(pProxy.CPFMapName,"MapGlobals",Namespace) = 1
		TCOMMIT
		Set inTrans = 1
		
		#;These maybe used for defaults in this session
		Set %session.Data("Mapping","GlobalDataLocation") = pProxy.Database
		Set %session.Data("Mapping","GlobalName") = GlobalName
		Set %session.Data("Mapping","GlobalSubscript") = Subscript
		
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
	Quit $$$Text("Global Mapping")
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
	
	Set tSC = ..DrawCollations()
	If $$$ISERR(tSC) Quit tSC
	
	Set (..%GetComponentById("Database").value,..%GetComponentById("LockDatabase").value) = $G(%session.Data("Mapping","GlobalDataLocation"))
	
	Set ..%GetComponentById("DBParam").value = 0
	Set ..%GetComponentById("LockDBParam").value = 0
	If ..MappingName '= "" {
		If ..MappingName [ "(" {
			Set (..%GetComponentById("GlobalName").value,GlobalName) = $P(..MappingName,"(",1)
			Set (..%GetComponentById("Subscript").value,Subscript) = "("_$P(..MappingName,"(",2,*)
			Set ..%GetComponentById("LockDatabase").disabled = 1
			Set ..%GetComponentById("AdvancedSettings").hidden = 1
		} Else {
			Set (..%GetComponentById("GlobalName").value,GlobalName) = ..MappingName
			Set (..%GetComponentById("Subscript").value,Subscript) = ""
			if ..Namespace = $$$NamespaceALL {
				Set ..%GetComponentById("DBParam").value = 9
				Set ..%GetComponentById("LockDBParam").value = 9
			}
		}
	
		Set tSC = ##class(Config.MapGlobals).Get(..Namespace,GlobalName_Subscript,.Properties,..CPFMapFile)
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
		if ..Namespace = $$$NamespaceALL,..%GetComponentById("Database").value=$$$DefaultDBALL  {
			Set ..%GetComponentById("Subscript").disabled = 1
		}
	} Else {
		Set ..%GetComponentById("Collation").value = 5
		if ..Namespace = $$$NamespaceALL {
			Set ..%GetComponentById("DBParam").value = 9
			Set ..%GetComponentById("LockDBParam").value = 9
		}
		If $G(%session.Data("Mapping","GlobalSubscript")) '= "" {
			Set ..%GetComponentById("GlobalName").value = $G(%session.Data("Mapping","GlobalName"))
		}
	}
	
	Quit $$$OK
}

Method DrawCollations() As %Status
{
	Set tSC = ##class(%Collate).MakeArray(.lst,1,0,1)
	If $$$ISERR(tSC) Quit tSC
	Set (tDisplayList,tValueList) = ""
	Set ListEmpty = 1
	Set name = $O(lst(""))
	While name '= "" {
		If ('ListEmpty) {
			Set tDisplayList = tDisplayList_","
			Set tValueList = tValueList_","
		}
		Set number = $li(lst(name),3)
		
		Set tDisplayList = tDisplayList_..EscapeHTML(name)
		Set tValueList = tValueList_number
		Set ListEmpty = 0
		Set name = $O(lst(name))
	}
	Set ..%GetComponentById("Collation").displayList = tDisplayList
	Set ..%GetComponentById("Collation").valueList = tValueList
	
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	If pSeed = "" {
		Set tPageTitle = $$$FormatText($$$Text("Map a new global in namespace %1"),..EscapeHTML(%page.Namespace))_"<br/>"
	} Else {
		Set tPageTitle = $$$FormatText($$$Text("Edit global mapping in namespace %1"),..EscapeHTML(%page.Namespace))_"<br/>"
	}
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
