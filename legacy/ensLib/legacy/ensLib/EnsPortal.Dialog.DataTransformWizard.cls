/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user create a new Data Transformation.
Class EnsPortal.Dialog.DataTransformWizard Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_DTL resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_DTL:WRITE";

Parameter APPLYBUTTON = 0;

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

<selector id="dtPackage" label="Package" hint="Class package containing this Data Transformation" size="50" context="Ens.ContextSearch/ClassPackages"/>
<text id="dtName" label="Name" hint="Name of this Data Transformation" size="50"  onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<textarea id="dtDesc" label="Description" rows="3" cols="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

<vgroup enclosingStyle="border: 1px solid #D0D0D0; padding: 10px;">
<radioSet id="dtSourceType" label="Source Type" valueList=",HL7,X12,ASTM,EDIFACT,XML" displayList="All Messages,HL7,X12,ASTM,EDIFACT,XML" onchange="zenPage.changeType('source',zenThis.getValue());"/>
<hgroup cellVAlign="bottom">
<text id="dtSourceClass" label="Source Class" size="40" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" onchange="zenPage.changeValue(zenThis.id, zenThis.value);"/>
<image id="dtSourceClassBtn" src="deepsee/zoom_16.png" onclick="zenPage.selectType('source_class');" title="Select new source class"/>
<spacer width="10"/>
<text id="dtSourceDocType" label="Source Document Type" size="30" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" onchange="zenPage.changeValue(zenThis.id, zenThis.value);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectType('source_doctype');" title="Select new source document type"/>
</hgroup>
</vgroup>

<vgroup enclosingStyle="border: 1px solid #D0D0D0; padding: 10px;">
<radioSet id="dtTargetType" label="Target Type" valueList=",HL7,X12,ASTM,EDIFACT,XML" displayList="All Messages,HL7,X12,ASTM,EDIFACT,XML" onchange="zenPage.changeType('target',zenThis.getValue());"/>
<hgroup cellVAlign="bottom">
<text id="dtTargetClass" label="Target Class" size="40" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" onchange="zenPage.changeValue(zenThis.id, zenThis.value);"/>
<image id="dtTargetClassBtn" src="deepsee/zoom_16.png" onclick="zenPage.selectType('target_class');" title="Select new target class"/>
<spacer width="10"/>
<text id="dtTargetDocType" label="Target Document Type" size="30" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" onchange="zenPage.changeValue(zenThis.id, zenThis.value);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectType('target_doctype');" title="Select new target document type"/>
</hgroup>
</vgroup>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Data Transformation Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create a new Data Transformation definition.")
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
		var pkg = zenTrim(zen('dtPackage').getValue());
		var name = zenTrim(zen('dtName').getValue());

		var dtName = (''!==pkg)? (pkg+'.'+name) : name;
		var dtDescription = zen('dtDesc').getValue();
		var dtSourceClass = zen('dtSourceClass').getValue();
		var dtSourceDocType = zen('dtSourceDocType').getValue();
		var dtTargetClass = zen('dtTargetClass').getValue();
		var dtTargetDocType = zen('dtTargetDocType').getValue();

		// test for missing package portion
		if ('' == pkg) {
			alert($$$Text('Please enter a package for this Business Process.'));
			return false;
		}

		// test for missing name portion
		if ('' == name) {
			alert($$$Text('Please enter a name for this Data Transformation.'));
			return false;
		}

		// test for valid full name
		var msg = zenPage.IsNameValid(dtName); // get everything for the next two tests in one call to the server
		var bool = msg.split(":");
		if (bool[0] == "0") {
			alert($$$Text('Name or Package is not valid for this Data Transformation.'));
			return false;
		}

		// test for overwrite
		if (bool[1] == "0") {
			if (!confirm($$$Text('A Data Transformation by this name already exists in this package. Do you wish to overwrite it?'))) {
				return false;
			}
		}

		// create new class
		var msg = this.CreateDTClass(dtName,dtDescription,dtSourceClass,dtSourceDocType,dtTargetClass,dtTargetDocType);
		if (msg != '') {
			alert(msg);
			return false;
		}

		this.retValue = dtName + '.dtl';
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
		zen('dtName').focus();
		zen('dtName').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		Set tPkgCtrl = ..%GetComponentById("dtPackage")
		Set tNameCtrl = ..%GetComponentById("dtName")

		Set tPkgCtrl.value = ""
		Try {
			Set tPkgCtrl.value = $G(^EnsPortal.Settings($UserName,"LastPackage"))
		}
		Catch(ex) {
		}

		//Amend according to packages installed: valueList=",HL7,X12,ASTM,EDIFACT,XML" displayList="All Messages,HL7,X12,ASTM,EDIFACT,XML"
		#dim sourceTypeRadio = ..%GetComponentById("dtSourceType")
		#dim targetTypeRadio = ..%GetComponentById("dtTargetType")
		#dim tPackages
		Set tPackages("HL7")=""
		Set tPackages("X12")=""
		Set tPackages("ASTM")=""
		Set tPackages("EDIFACT")=""
		Set tPackages("XML")=""
		#dim tOption = ""
		#dim tClass = ""
		For {
			Set tOption = $Order(tPackages(tOption))
			If tOption = "" Quit
			If '##class(%Library.InteroperabilityMgr).IsPackageInstalled(tOption) {
				Set sourceTypeRadio.valueList = $Replace($Replace(sourceTypeRadio.valueList,tOption,""),",,",",")
				Set sourceTypeRadio.displayList = $Replace($Replace(sourceTypeRadio.displayList,tOption,""),",,",",")
				Set targetTypeRadio.valueList = $Replace($Replace(targetTypeRadio.valueList,tOption,""),",,",",")
				Set targetTypeRadio.displayList = $Replace($Replace(targetTypeRadio.displayList,tOption,""),",,",",")
			}
		}
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given name is valid.
/// Returns a colon-separated string. The first position is a 1 or 0 indicating
/// whether this is (1) or is not (0) a valid class name. The second position is
/// a 1 or 0 indicating whether the name is free and clear to use (1) 
/// or is the name of an existing data transformation (0).
ClassMethod IsNameValid(pName As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	If ($ZNAME(pName,4)) {
		Set tMsg = "1"
	}
	Else {
		Set tMsg = "0"
	}
	If (##class(%Dictionary.ClassDefinition).%ExistsId(pName)) {
		Set tMsg = tMsg _ ":0"
	}
	Else {
		Set tMsg = tMsg _ ":1"
	}
	Quit tMsg
}

/// Create a new DT class. Return "" if ok otherwise and error message.
ClassMethod CreateDTClass(pClassName As %String, pDesc As %String, pSourceClass As %String, pSourceDocType As %String, pTargetClass As %String, pTargetDocType As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tPkg = $P(pClassName,".",1,$L(pClassName,".")-1)
		Try {
			Set:tPkg'="" ^EnsPortal.Settings($UserName,"LastPackage") = tPkg
		}
		Catch(ex) {
		}

		// open the class definition
		If (##class(%Dictionary.ClassDefinition).%ExistsId(pClassName)) {
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
			#; delete the old XDATA block named DTL
			Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||DTL")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = pClassName
			Set tClassDefinition.ClassVersion = 25

			Set tParam = ##class(%Dictionary.ParameterDefinition).%New()
			Set tParam.Name="REPORTERRORS"
			Set tParam.Default = 1
			Do tClassDefinition.Parameters.Insert(tParam)

			Set tParam = ##class(%Dictionary.ParameterDefinition).%New()
			Set tParam.Name="IGNOREMISSINGSOURCE"
			Set tParam.Default = 1
			Do tClassDefinition.Parameters.Insert(tParam)
			
			Set tParam = ##class(%Dictionary.ParameterDefinition).%New()
			Set tParam.Name="TREATEMPTYREPEATINGFIELDASNULL"
			Set tParam.Default = 0
			Do tClassDefinition.Parameters.Insert(tParam)
		}

		Set tClassDefinition.Super = "Ens.DataTransformDTL"
		Set tClassDefinition.DependsOn = pSourceClass_$Case(pSourceClass, pTargetClass:"", "":pTargetClass, :$S(""=pTargetClass:"",1:","_pTargetClass))

		// sequence number controls the order in which class members are displayed
		Set tSeqNo = 0

		// create XData block
		Set tCubeXData = ##class(%Dictionary.XDataDefinition).%New()
	
		Set tCubeXData.SequenceNumber = $I(tSeqNo)
		Set tCubeXData.Description = "DTL Definition."
		Set tCubeXData.XMLNamespace = "http://www.intersystems.com/dtl"

		Set tCubeXData.Name = "DTL"
		Set tCubeXData.parent = tClassDefinition

		// defaults
		#dim tSourceClass = ""
		#dim tSourceDocType = ""
		#dim tTargetClass = ""
		#dim tTargetDocType = ""

		Set tClass = "EnsLib.HL7.Message"
		If ##class(%Dictionary.CompiledClass).%ExistsId(tClass) {
			Set tSourceClass = "EnsLib.HL7.Message"
			Set tSourceDocType = "2.1:ACK"
			Set tTargetClass = "EnsLib.HL7.Message"
			Set tTargetDocType = "2.1:ACK"
		}

		Set tLanguage = "objectscript"
		Set tCreate = "new"

		If (pSourceClass '= "") || (pSourceDocType '= "") {
			Set tSourceClass = pSourceClass
			Set tSourceDocType = pSourceDocType
		}
		If (pTargetClass '= "") || (pTargetDocType '= "") {
			Set tTargetClass = pTargetClass
			Set tTargetDocType = pTargetDocType
		}

		Set tSC = tCubeXData.Data.WriteLine("<transform targetClass='"_tTargetClass_"' targetDocType='"_tTargetDocType_"' sourceClass='"_tSourceClass_"' sourceDocType='"_tSourceDocType_"' create='"_tCreate_"' language='"_tLanguage_"'>")
		If pDesc '= "" {
			Set pDesc = $Replace(pDesc,$C(13,10),$C(10))
			Do tCubeXData.Data.WriteLine("<annotation>"_$zconvert(pDesc,"O","XML")_"</annotation>")
		}
		Set tSC = tCubeXData.Data.WriteLine("</transform>")
		If $$$ISERR(tSC) Quit

		// save the class
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

ClassMethod IsVDoc(pClass As %String = "") As %Boolean [ ZenMethod ]
{
	Quit ##class(Ens.VDoc.Utils).IsVirtualDocument(pClass)
}

/// Launch the select type dialog.
ClientMethod selectType(which) [ Language = javascript ]
{
	var mode = '';
	var cls = '';

	switch(which) {
	case 'source_class':
		mode = 'vdocclass';
		break;
	case 'source_doctype':
		cls = zen('dtSourceClass').getValue();
		mode = 'vdoctype';
		break;
	case 'target_class':
		mode = 'vdocclass';
		break;
	case 'target_doctype':
		cls = zen('dtTargetClass').getValue();
		mode = 'vdoctype';
		break;
	default:
		return;
	}

	if (mode=='vdoctype') {
		if (cls=='') {
			alert($$$Text('Please select a message class first.'));
			return;
		} 
		else if (!zenPage.IsVDoc(cls)) {
			alert($$$Text('The message class is not a virtual document. No DocType can be specified.'));
			return;
		}
	}
	
	var parms = {
		MODE:mode,
		CATEGORY:cls,
		CALLER:'dtleditor'
	};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode),this.addPopupSuffix(which),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	// chop last piece off of value
	var s = value.toString().split('.');
	s.length--;
	var shortValue = s.join('.');

	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'source_class':
			zen('dtSourceClass').setValue(shortValue);
			this.changeValue('dtSourceClass', shortValue);
			break;
		case 'source_doctype':
			zen('dtSourceDocType').setValue(shortValue);
			this.changeValue('dtSourceDocType', shortValue);
			break;
		case 'target_class':
			zen('dtTargetClass').setValue(shortValue);
			break;
		case 'target_doctype':
			zen('dtTargetDocType').setValue(shortValue);
			break;
	}
}

/// Handle updates based on a new value for one of the fields.
ClientMethod changeValue(componentId, newValue) [ Language = javascript ]
{
	switch (componentId) {
		case 'dtSourceClass':
			// Set target class to source class if the target class is empty.
			if (zen('dtTargetClass').getValue() == '') {
				zen('dtTargetClass').setValue(newValue);
				zen('dtTargetType').setValue(zen('dtSourceType').getValue());
			}
			break;
		case 'dtSourceDocType':
			if (zen('dtTargetDocType').getValue() == '') {
				// If the target DocType is empty:
				// (1) Set target class to the source class if the target class is empty
				// (2) If the source and target classes are the same, set the target DocType to the source DocType
				if (zen('dtTargetClass').getValue() == '') {
					zen('dtTargetClass').setValue(zen('dtSourceClass').getValue())
					zen('dtTargetType').setValue(zen('dtSourceType').getValue());
				}
				if (zen('dtTargetClass').getValue() == zen('dtSourceClass').getValue()) {
					zen('dtTargetDocType').setValue(newValue);
				}
			}
			break;
	}
}

/// User has changed the message type radio button.
ClientMethod changeType(which, value) [ Language = javascript ]
{
	var cls = '';
	var doctype = '';

	switch(value) {
	case 'HL7':
		cls = 'EnsLib.HL7.Message';
		doctype = '';
		break;
	case 'X12':
		cls = 'EnsLib.EDI.X12.Document';
		doctype = '';
		break;
	case 'ASTM':
		cls = 'EnsLib.EDI.ASTM.Document';
		doctype = '';
		break;
	case 'EDIFACT':
		cls = 'EnsLib.EDI.EDIFACT.Document';
		doctype = '';
		break;
	case 'XML':
		cls = 'EnsLib.EDI.XML.Document';
		doctype = '';
		break;
	}

	switch(which) {
	case 'target':
		zen('dtTargetClass').setValue(cls);
		zen('dtTargetDocType').setValue(doctype);
		if (cls!='') {
			zen('dtTargetClass').setProperty('disabled',true);
			zen('dtTargetClassBtn').setProperty('disabled',true);
		}
		else {
			zen('dtTargetClass').setProperty('disabled',false);
			zen('dtTargetClassBtn').setProperty('disabled',false);
		}
		break;
	case 'source':
		zen('dtSourceClass').setValue(cls);
		zen('dtSourceDocType').setValue(doctype);
		if (cls!='') {
			zen('dtSourceClass').setProperty('disabled',true);
			zen('dtSourceClassBtn').setProperty('disabled',true);
		}
		else {
			zen('dtSourceClass').setProperty('disabled',false);
			zen('dtSourceClassBtn').setProperty('disabled',false);
		}
		break;
	}
}

}
