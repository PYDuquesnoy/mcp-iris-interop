/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsPortal.Dialog.RecordMapDelete Extends (EnsPortal.Dialog.standardDialog, EnsPortal.Template.scUtils) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Delete RecordMap";

/// Domain used for localization.
Parameter DOMAIN = "Ensemble";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_RecordMap resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_RecordMap:WRITE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property recordMap As %ZEN.Datatype.string(ZENURL = "RECORDMAP");

Property objectName As %ZEN.Datatype.string(ZENURL = "OBJECTNAME");

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
<vgroup width="60%" id="id1" label="RecordMap Name:" labelClass="reqLabel">
<label id="docName" />
</vgroup>
<vgroup width="60%" id="id2" label="Target Classname:" labelClass="reqLabel">
<label id="ObjectName" />
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
	Quit $$$TextHTML("Delete RecordMap")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method DeleteRecordMap(RecordMap As %String, DeleteTarget As %Boolean = 0, DeleteTargetExtent As %Boolean = 0) As %String [ ZenMethod ]
{
	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tNonSCRetVal = ""

	Try {
		#; Handle here if Record Map in SourceControl
		Try {
			#dim tHandleDeleteHere
			#; Populate docSCStatus object -docSCStatus in order to identify if record map covered by Source Control
			Do ..GetStatusExtension($$$NormalizeClassname(RecordMap), ".CLS")
			Set tHandleDeleteHere = ..docSCStatus.inSourceControl
		} Catch {
			Set tHandleDeleteHere = 0
		}

		#dim tTargetClass

		Set tStatus = ##class(EnsLib.RecordMap.RecordMap).DeleteRecordMap(RecordMap, DeleteTarget, DeleteTargetExtent, tHandleDeleteHere, .tTargetClass)
		// Ignore errors if either the RecordMap or Target class don't exist
		If $System.Status.Equals(tStatus, $$$ERRORCODE($$$ClassDoesNotExist), $$$ERRORCODE($$$DeleteObjectNotFound)) {Set tStatus = $$$OK}

		If $$$ISOK(tStatus) && tHandleDeleteHere {
			// One or more of the classes to be deleted might not exist but Source Control framework might need to act accordingly.

			#dim tJSONMessage = ""

			#; RecordMap checked for being a Record Map class in EnsLib.RecordMap.RecordMap::DeleteRecordMap
			Do ..DeleteDoc($$$NormalizeClassname(RecordMap), ".CLS", .tJSONMessage)

			If DeleteTarget && (tTargetClass'="") {
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

/// Get the value that will be applied when the user presses the OK button.
/// This is implemented by subclasses.
ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.getComponentById('docName').getValue();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var msg = "";
		var RecordMap = this.recordMap;
		var DeleteTarget = zen('deleteTarget').getValue();
		var DeleteTargetExtent = zen('deleteTargetExtent').getValue()
		
		var ret = this.DeleteRecordMap(RecordMap, DeleteTarget, DeleteTargetExtent);
		if (!this.processDeleteReturn(ret,RecordMap)) return false;
		alert($$$Text('Delete operation succeeded.'));
		return true;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set ..%GetComponentById("docName").label = ..recordMap
	If ..objectName '= "" { Set ..%GetComponentById("ObjectName").value = ..objectName }
	Else { Set ..%GetComponentById("ObjectName").value =  $select($length(..recordMap,".") = 1: "User."_..recordMap, 1: ..recordMap) _ ".Record" }
	Quit ##super()
}

/// Server method to handle Source Control framework AfterUserAction
Method AfterUserDeleteAction(RecordMap, pExtension) As %String [ Internal, ZenMethod ]
{
	#dim tMessage = ##super(..recordMap, ".CLS")
	If ''(..%GetComponentById("deleteTargetExtent").value) {
		Set tMessage = tMessage_$Case($Length(tMessage),0:"",:" ")_##super(..%GetComponentById("ObjectName").value, ".CLS")
	}
	Return tMessage
}

}
