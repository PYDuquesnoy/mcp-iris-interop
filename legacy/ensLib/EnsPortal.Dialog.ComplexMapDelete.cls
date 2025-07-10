/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsPortal.Dialog.ComplexMapDelete Extends (EnsPortal.Dialog.standardDialog, EnsPortal.Template.scUtils) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Delete Complex RecordMap";

/// Domain used for localization.
Parameter DOMAIN = "Ensemble";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_RecordMap resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_RecordMap:WRITE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property complexMap As %ZEN.Datatype.string(ZENURL = "COMPLEXMAP");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.reqLabel {
	color: #404040;
	font-size: 10pt;
	font-weight: bold;
}
.zenLabel {
	color: rgb(71,72,67);
	font-size: 1em;
	font-weight: normal;
}
.redText {
	color:red;
	font-size:0.8em;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<label id="result" controlClass="redText" value=""/>
<hgroup id="supplied" width="400">
<vgroup width="60%" id="id1" label="Complex RecordMap Name:" labelClass="reqLabel">
<label id="mapName" />
</vgroup>
<vgroup width="60%" id="id2" label="Target Classname:" labelClass="reqLabel">
<label id="targetClassname" />
</vgroup>
</hgroup>
<html><hr/></html>
<vgroup id="id3" cellStyle="padding:3px;padding-left:20px;" width="400">
<checkbox id="deleteTarget" caption="Delete Target Class" value="false" onchange="zenPage.onDeleteTargetChange();" />
<checkbox id="deleteTargetExtent" caption="Delete Target Extent" value="false" disabled="true" />
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Delete Complex RecordMap")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method DeleteMap(pComplexMap As %String, pDeleteTarget As %Boolean = 0, pDeleteTargetExtent As %Boolean = 0) As %String [ ZenMethod ]
{
	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tNonSCRetVal = ""

	Try {
		#; Handle here if Record Map in SourceControl
		Try {
			#dim tHandleDeleteHere
			#; Populate docSCStatus object in order to identify if record map covered by Source Control
			Do ..GetStatusExtension($$$NormalizeClassname(pComplexMap), ".CLS")
			Set tHandleDeleteHere = ..docSCStatus.inSourceControl
		} Catch {
			Set tHandleDeleteHere = 0
		}

		#dim tTargetClass

		Set tStatus = ##class(EnsLib.RecordMap.ComplexMap).DeleteComplexMap(pComplexMap,pDeleteTarget,pDeleteTargetExtent, tHandleDeleteHere, .tTargetClass)
		// Ignore errors if either the ComplexMap or Target class don't exist.
		If $System.Status.Equals(tStatus, $$$ERRORCODE($$$ClassDoesNotExist), $$$ERRORCODE($$$DeleteObjectNotFound)) {Set tStatus = $$$OK}

		If $$$ISOK(tStatus) && tHandleDeleteHere {
			// One or more of the classes to be deleted might not exist but Source Control framework might need to act accordingly.

			#dim tJSONMessage = ""

			#; ComplexMap checked for being a Complex Map class in EnsLib.RecordMap.ComplexMap::DeleteComplexMap
			Do ..DeleteDoc($$$NormalizeClassname(pComplexMap), ".CLS", .tJSONMessage)

			If pDeleteTarget && (tTargetClass'="") {
				#; We won't return the possible question to remove from SC since covered by RecordMap removal question.
				Do ..DeleteDoc(tTargetClass, ".CLS")
			}

		}

	} Catch ex {
		Set tStatus = $$$SystemError
	}

	If $$$ISERR(tStatus) || 'tHandleDeleteHere {
		#; processDeleteReturn will present this in an alert or accept tNonSCRetVal as empty string as OK
		If $$$ISERR(tStatus) Set tNonSCRetVal = $zcvt($System.Status.GetErrorText(tStatus), "O", "HTML")
		Return tNonSCRetVal
	}
	Return tJSONMessage
}

ClientMethod onDeleteTargetChange() [ Language = javascript ]
{
	var deleteTarget = zen('deleteTarget').getValue();
	if (!deleteTarget) {
		zen('deleteTargetExtent').setValue(false);
	}
	zen('deleteTargetExtent').setDisabled(!deleteTarget);
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.complexMap;
}

ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var msg = "";
		var DeleteTarget = zen('deleteTarget').getValue();
		var DeleteTargetExtent = zen('deleteTargetExtent').getValue()
		
		var ok = this.DeleteMap(this.complexMap, DeleteTarget, DeleteTargetExtent);
		if (ok != '') {
			var msg = $$$Text('Delete failed!')+'\n'+ok;
			alert(msg);
			return false;
		}
		alert($$$Text('Delete operation succeeded.'));
		return true;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set ..%GetComponentById("mapName").label = ..complexMap

	Set tComplexMap = $$$NormalizeClassname(..complexMap)
	Set ..%GetComponentById("targetClassname").value = $$$comMemberKeyGet(tComplexMap,$$$cCLASSparameter,"BATCHCLASS",$$$cPARAMdefault)

	Quit ##super()
}

ClientMethod ondialogStart() [ Language = javascript ]
{
	if (zen('targetClassname').getValue() == '') {
		zen('targetClassname').setValue('&nbsp;');
	}
}

}
