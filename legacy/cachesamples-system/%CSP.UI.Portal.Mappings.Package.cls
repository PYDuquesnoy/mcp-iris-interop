/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit Service Popup Dialog for Management Portal
Class %CSP.UI.Portal.Mappings.Package Extends %CSP.UI.Portal.Mappings.Template [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mappings.Package.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Package Mapping";

Property SelectMapping As %Boolean [ InitialExpression = 0 ];

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
label="Package Database Location"
queryClass="Config.Databases"
queryName="List"
showEmpty="true"
dropdownHeight="250px"
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
<parameter value="0"/>
</dataCombo>
<spacer height="5px"/>
<radioSet id="selectList" displayList="Select an existing package,Specify a new package" valueList="1,0" value="1" onchange="zenPage.changeSelectList(zenThis);zenPage.checkFields();"/>
<dataCombo id="PackageName"
label="Package Name"
queryClass="Config.MapPackages"
queryName="ListPackages"
showEmpty="true"
dropdownHeight="250px"
dropdownWidth="350px"
size="55"
displayColumns="1"
choiceColumn="1"
valueColumn="1"
onchange="zenPage.checkFields();"
hint="Required."
maxRows="100000"
>
<parameter id="packageParam" value=""/>
</dataCombo>
<text id="NewPackageName" label="Package Name" size="55" onkeyup="zenPage.checkFields();" hint="Required." hidden="true"/>
</group>
</group>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.changeSelectList(zen('selectList'));
	this.doChangeDB(zen('Database').getValue());
	if (this.SelectMapping) {
		zen('PackageName').setValue(this.MappingName);
	}
	if (zen('Database').getValue() == '') {
		zen('Database').focus();
	} else if (zen('PackageName').getValue() == '') {
		zen('PackageName').focus();
	}
}

ClientMethod changeSelectList(radioSet) [ Language = javascript ]
{
	this.resetMsg();
	var v = radioSet.getValue() == 1;
	zen('PackageName').setHidden(!v);
	zen('NewPackageName').setHidden(v);
	zen('PackageName').setProperty("hintClass","helpText");
	zen('NewPackageName').setProperty("hintClass","helpText");
	zen('Database').setProperty("hintClass","helpText");
}

ClientMethod checkFields() [ Language = javascript ]
{
	var selectVal = zen('selectList').getValue();
	var disableButtons = ((zen('Database').getValue() == "") || 
					((selectVal == 1) && (zen('PackageName').getValue() == "")) ||
					((selectVal == 0) && (zen('NewPackageName').getValue() == "")))
	this.toggleButtons(disableButtons);
}

ClientMethod doChangeDB(newVal) [ Language = javascript ]
{
	var combo = zen('PackageName');
	combo.setValue('');
	if (newVal == "") {
		combo.setDisabled(true);
	} else {
		combo.setDisabled(false);
		zen('packageParam').value = newVal;
		combo.executeQuery();
	}
}

ClientMethod validate() [ Language = javascript ]
{
	this.resetMsg();
	var Database = zen('Database');
	var DatabaseValue = Database.getValue();
	var selectVal = zen('selectList').getValue();
	if (selectVal == 1) {
		var PackageName = zen('PackageName');
	} else {
		var PackageName = zen('NewPackageName');
	}
	var PackageNameValue = PackageName.getValue();
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
	if (PackageNameValue == '') {
		PackageName.setProperty('hintClass','redText');
		if (pass) {
			PackageName.focus();
		}
		pass = false;
	} else {
		PackageName.setProperty("hintClass","helpText");
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
		if (zen('selectList').getValue() == 1) {
			proxy.PackageName = zen('PackageName').getValue();
		} else {
			proxy.PackageName = zen('NewPackageName').getValue();
		}
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
		Set PackageName = pProxy.PackageName
		Set Properties("Database") = pProxy.Database

		TSTART
		Set inTrans = 1
	
		If 'pProxy.IsNew {
			#;If the name has changed, we need to delete the old name, and add in the new name
			#;as part of the same transaction.
			If PackageName '= pProxy.OldMappingName {
				Set tSC = ##class(Config.MapPackages).Delete(Namespace,pProxy.OldMappingName,pProxy.CPFMapFile,$$$CPFSave)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				Set createNew = 1
			} Else {
				Set tSC = ##class(Config.MapPackages).Modify(Namespace,PackageName,.Properties,pProxy.CPFMapFile,$$$CPFSave)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		
		If (pProxy.IsNew || $G(createNew)) {
			Set tSC = ##class(Config.MapPackages).Create(Namespace,PackageName,.Properties,pProxy.CPFMapFile,$$$CPFSave)
			If $$$ISERR(tSC) {
				If $$$GETERRORCODE(tSC) = $$$ERRORCODE($$$IDKeyNotUnique) {
					Set tSC = $$$ERROR($$$CPFMappingAlreadyExists,PackageName)
				}
				throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		
		#;Flag to let us know that we have changed mappings
		Set $$$CONFIG3(pProxy.CPFMapName,"MapPackages",Namespace) = 1
		TCOMMIT
		Set inTrans = 1
		
		#;These maybe used for defaults in this session
		Set %session.Data("Mapping","PackageDataLocation") = pProxy.Database
		Set %session.Data("Mapping","PackageName") = PackageName
		
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
	Quit $$$Text("Package Mapping")
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
	
	Set ..%GetComponentById("Database").value = $G(%session.Data("Mapping","PackageDataLocation"))
	
	If ..MappingName '= "" {
		Set tSC = ##class(Config.MapPackages).Get(..Namespace,..MappingName,.Properties,..CPFMapFile)
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
		
		Set isExisting = 0
		Set tRS = ##class(%ResultSet).%New("Config.MapPackages:ListPackages")
		Do tRS.Execute(Properties("Database"))
		While tRS.Next() {
			If tRS.Data("Name") = ..MappingName {
				Set isExisting = 1
				Quit
			}
		}
		
		If isExisting {
			Set ..SelectMapping = 1
		} Else {
			Set ..%GetComponentById("selectList").value = 0
			Set ..%GetComponentById("PackageName").hidden = 1
			Set ..%GetComponentById("NewPackageName").hidden = 0
			Set ..%GetComponentById("NewPackageName").value = ..MappingName
		}
	}
	
	Set ..%GetComponentById("packageParam").value = ..%GetComponentById("Database").value
	
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	If pSeed = "" {
		Set tPageTitle = $$$FormatText($$$Text("Map a new package in namespace %1"),..EscapeHTML(%page.Namespace))_"<br/>"
	} Else {
		Set tPageTitle = $$$FormatText($$$Text("Edit package mapping in namespace %1"),..EscapeHTML(%page.Namespace))_"<br/>"
	}
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
