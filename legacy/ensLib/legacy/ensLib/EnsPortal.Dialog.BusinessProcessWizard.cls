/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user create a new Business Process.
Class EnsPortal.Dialog.BusinessProcessWizard Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_BPL:WRITE";

/// Default package name.
Property package As %ZEN.Datatype.string(ZENURL = "PACKAGE");

/// Holder for return value.
Property retValue As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
a.radioSetCaption {
	color: #404040;
	font-size: 10pt;
}


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="bpPackage" label="Package" hint="Class package containing this Business Process" size="50" context="/Packages"/>
<text id="bpName" label="Name" hint="Name of this Business Process" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<textarea id="bpDesc" label="Description" rows="3" cols="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Business Process Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create a new Business Process definition.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.retValue;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();

		var pkg = zenTrim(zen('bpPackage').getValue());
		var name = zenTrim(zen('bpName').getValue());

		var bpName = (''!==pkg)? (pkg+'.'+name) : name;
		var bpDescription = zen('bpDesc').getValue();

		// test for missing package portion
		if ('' == pkg) {
			alert($$$Text('Please enter a package for this Business Process.'));
			return false;
		}

		// test for missing name portion
		if ('' == name) {
			alert($$$Text('Please enter a name for this Business Process.'));
			return false;
		}

		// test for valid full name
		if (!zenPage.IsNameValid(bpName)) {
			alert($$$Text('Name or Package is not valid for this Business Process.'));
			return false;
		}

		// create new class and validate that the class doesn't already exist
		var msg = this.CreateBPClass(bpName,bpDescription);
		if (msg != '') {
			alert(msg);
			return false;
		}

		this.retValue = bpName + '.bpl';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		zen('bpName').focus();
		zen('bpName').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		Set tPkgCtrl = ..%GetComponentById("bpPackage")
		Set tNameCtrl = ..%GetComponentById("bpName")

		Try {
			Set tPkgCtrl.value = $G(^EnsPortal.Settings($UserName,"LastPackage"))
		}
		Catch(ex) {
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given name is valid.
ClassMethod IsNameValid(pName As %String) As %Boolean [ ZenMethod ]
{
	Quit $ZNAME(pName,4)
}

/// Create a new BP class. Return "" if ok otherwise and error message.
ClassMethod CreateBPClass(pClassName As %String, pDesc As %String = "") As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		If '($system.Security.Check("%Ens_Code","WRITE") || $system.Security.Check("%Ens_BPL","WRITE")) {
			Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
			Quit
		}
		Set pSuper = ""
		Set tRequestClass = "Ens.Request"
		Set tResponseClass = "Ens.Response"

		Set tPkg = $P(pClassName,".",1,$L(pClassName,".")-1)
		Try {
			Set:tPkg'="" ^EnsPortal.Settings($UserName,"LastPackage") = tPkg
		}
		Catch(ex) {
		}

		// it is an error if the class definition already exists
		If (##class(%Dictionary.ClassDefinition).%ExistsId(pClassName)) {
			Set tSC = $$$ERROR($$$ClassNameExists,pClassName)
			Quit
		}
		// create a new class
		Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
		Set tClassDefinition.Name = pClassName
		Set tClassDefinition.ClassVersion = $$$CLASSDEFINITIONVERSION
		Set tClassDefinition.Super = $S(pSuper="":"Ens.BusinessProcessBPL",1:pSuper)
		Set tClassDefinition.Description = $Replace(pDesc,$C(10),$C(13,10))

		// sequence number controls the order in which class members are displayed
		Set tSeqNo = 0

		// create XData block
		Set tCubeXData = ##class(%Dictionary.XDataDefinition).%New()
	
		Set tCubeXData.SequenceNumber = $I(tSeqNo)
		Set tCubeXData.Description = "BPL Definition."
		Set tCubeXData.XMLNamespace = "http://www.intersystems.com/bpl"

		// create initial BPL as an error block (as it is not yet valid!)
		Set tCubeXData.Name = "BPLError"
		Set tCubeXData.parent = tClassDefinition

		Set tSC = tCubeXData.Data.WriteLine("<diagram Name="""_pClassName_""" HasErrors=""1"" Language=""objectscript"" ContextSuperClass="""" Layout=""automatic"" Version="""" Includes="""" Request="""_tRequestClass_""" Response="""_tResponseClass_""" Width=""2000"" Height=""2000"" ShowAnnotation=""1"">")
		Set tSC = tCubeXData.Data.WriteLine("<shape _Type=""start"" Name="""" xPos=""200"" yPos=""150"" _index=""0""/>")
		Set tSC = tCubeXData.Data.WriteLine("<shape _Type=""end"" Name="""" xPos=""200"" yPos=""250"" _index=""1""/>")
		Set tSC = tCubeXData.Data.WriteLine("</diagram>")
		If $$$ISERR(tSC) Quit

		// save the class
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Key handler for value edit control.
ClientMethod ctrlKeyDown(evt, escOnly) [ Language = javascript ]
{
	switch(evt.keyCode) {
	case zenENTER:
		if (!escOnly) {
			this.dialogFinish();
		}
		break;
	case zenESC:
		this.dialogCancel();
		break;
	}
	return true;
}

}
