/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsRecordMap)

Class EnsPortal.Dialog.RecordMapSimpleBatch Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Edit a simple RecordMap Batch";

/// User needs READ permissions on either the %Ens_Code or the %Ens_RecordMap resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_RecordMap:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_RecordMap resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_RecordMap:WRITE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property recordMap As %ZEN.Datatype.string(ZENURL = "RECORDMAP");

Property batchClass As %ZEN.Datatype.string(ZENURL = "BATCHCLASS");

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
.classLabel {
	border-width: 0 1px 1px 1px;
	border-color: black;
	border-style: solid;
	background-color: white;
	padding: 2px;
	font-size: 0.95em;
}
.radioButtonCaption {
	text-decoration: none;
	color: #434343;
	font-size: 10pt;
}
.radioButtonCaption:visited {
	color: #434343;
}
.otherTextLabel {
	padding-right: 3px;
}
.charGroup {
	border: 1px solid gray;
	padding: 3px;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;" width="100%">

<label id="result" controlClass="redText" value=""/>
<hgroup id="supplied" width="100%" containerStyle="padding-left: 20px;">
<vgroup width="100%" id="id1" label="RecordMap Name:" labelClass="reqLabel">
<label id="recordMap" />
</vgroup>
</hgroup>
<html><hr/></html>
<hgroup>
<text id="batchName" size="40" label="Batch Classname" containerStyle="padding-left: 20px;" title="Name of SimpleBatch class, which will be created if it doesn't exist" />
<checkbox id="ignoreLeadingData" label="Ignore Leading Data" containerStyle="padding-left: 20px;" title="Don't report leading data as a warning" onchange="zenPage.applyDetails();" />
</hgroup>
<html><hr/></html>
<vgroup id="id3" cellStyle="padding:3px;padding-left:20px;">
<hgroup cellVAlign="top">
<textarea id="batchHeader" label="Batch Header" cols="20" rows="3" title="Batch Header text" />
<spacer width="20px" />
<group id="headerTermGroup" label="Batch Header Terminator" title="Character or characters used to indicate the end of the batch header" labelPosition="left" cellVAlign="bottom" enclosingClass="charGroup" layout="horizontal" >
<radioButton id="headerTerm_None" name="headerTerm" optionValue="" caption="None" title="No padding character" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'header');" />
<radioButton id="headerTerm_CRLF" name="headerTerm" optionValue="\x0d\x0a" caption="CRLF" title="Carriage Return, Line Feed" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'header');" />
<radioButton id="headerTerm_CR" name="headerTerm" optionValue="\x0d" caption="CR" title="Carriage Return" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'header');" />
<radioButton id="headerTerm_LF" name="headerTerm" optionValue="\x0a" caption="LF" title="Line Feed" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'header');" />
<spacer width="5px" />
<text id="headerTerm_Other" label="Other" labelClass="radioButtonCaption otherTextLabel" title="Other character - control characters must be represented in hex e.g. \x20 for space" size="10" onchange="zenPage.onRecTermChange(zenThis.value, false, 'header');" />
<text id="headerTerminator" hidden="true" onchange="zenPage.applyDetails();" />
</group>
</hgroup>
<hgroup cellVAlign="top">
<textarea id="batchTrailer" label="Batch Trailer" cols="20" rows="3" title="Batch Trailer text" />
<spacer width="20px" />
<group id="trailerTermGroup" label="Batch Trailer Terminator" title="Character or characters used to indicate the end of the batch trailer" labelPosition="left" cellVAlign="bottom" enclosingClass="charGroup" layout="horizontal" >
<radioButton id="trailerTerm_None" name="trailerTerm" optionValue="" caption="None" title="No padding character" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'trailer');" />
<radioButton id="trailerTerm_CRLF" name="trailerTerm" optionValue="\x0d\x0a" caption="CRLF" title="Carriage Return, Line Feed" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'trailer');" />
<radioButton id="trailerTerm_CR" name="trailerTerm" optionValue="\x0d" caption="CR" title="Carriage Return" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'trailer');" />
<radioButton id="trailerTerm_LF" name="trailerTerm" optionValue="\x0a" caption="LF" title="Line Feed" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true, 'trailer');" />
<spacer width="5px" />
<text id="trailerTerm_Other" label="Other" labelClass="radioButtonCaption otherTextLabel" title="Other character - control characters must be represented in hex e.g. \x20 for space" size="10" onchange="zenPage.onRecTermChange(zenThis.value, false, 'trailer');" />
<text id="trailerTerminator" hidden="true" onchange="zenPage.applyDetails();" />
</group>
</hgroup>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Create SimpleBatch for RecordMap")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod applyDetails() [ Language = javascript ]
{
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('batchName').getValue();
}

ClientMethod onRecTermChange(newValue, isRadio, type) [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var idlist = ['CR','LF','CRLF','Other','None'];
	for (key in idlist) {
		var val = idlist[key];
		var button = zen(type+'Term_'+val);
		if (button) {
			if (val == 'Other') {
				if (isRadio) {
					button.setProperty('value', '');
				}
			}
			else {
				button.setProperty('value', newValue);
			}
		}
	}
	zen(type+'Terminator').setValue(newValue);
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tBatchClassText = ..%GetComponentById("batchName")
	If $IsObject(tBatchClassText) {
		Set tBatchClassText.value = ..batchClass
	}
	
	If ..batchClass '= "" {
		Set tParmNames = $lb("BatchHeader","BatchTrailer","HeaderTerm","TrailerTerm","IgnoreLeadingData")
		For i=1:1:$listlength(tParmNames) {
			Set tParmName = $listget(tParmNames,i)
			If (tParmName '= "") {
				Set tParm = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(..batchClass,tParmName)
				If $IsObject(tParm) {
					Set tFieldRef = $zconvert($extract(tParmName,1),"L") _ $extract(tParmName,2,*)
					If (tParmName = "HeaderTerm") || (tParmName = "TrailerTerm") {
						Set tHiddenID = tFieldRef _ "inator"
						Set tHiddenComponent = ..%GetComponentById(tHiddenID)
						If $IsObject(tHiddenComponent) { Set tHiddenComponent.value = tParm.Default }
						Set tGroup = ..%GetComponentByName(tFieldRef)
						If $IsObject(tGroup) { Set tGroup.value = tParm.Default }
					}
					Else {
						Set tComponent = ..%GetComponentById(tFieldRef)
						If ($IsObject(tComponent)) { Set tComponent.value = tParm.Default }
					}
				}
			}
		}
	}
	
	If ..recordMap '= "" {
		Set tRecordMap = ..%GetComponentById("recordMap")
		If $IsObject(tRecordMap) {
			Set tRecordMap.value = $$$NormalizeClassname(..recordMap)
		}
	}
	Quit ##super()
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	if (this.checkEdit()) {
		var batchName = zen('batchName').getValue();
		if (batchName != '') {
			var batchHeader = zen('batchHeader').getValue();
			var headerTerm = zen('headerTerminator').getValue();
			var batchTrailer = zen('batchTrailer').getValue();
			var trailerTerm = zen('trailerTerminator').getValue();
			var ignoreLeadingData = zen('ignoreLeadingData').getValue();
		
			var ok = zenPage.SaveSimpleBatch(batchName, batchHeader, headerTerm, batchTrailer, trailerTerm,ignoreLeadingData);
			if (ok != 1) {
				alert(ok);
				return false;
			}
		}
	}
	return true;
}

ClassMethod SaveSimpleBatch(batchName As %String = "", batchHeader As %String = "", headerTerm As %String = "", batchTrailer As %String = "", trailerTerm As %String = "", ignoreLeadingData As %Boolean = 0) As %String [ ZenMethod ]
{
	#Define SimpleBatch		"EnsLib.RecordMap.SimpleBatch"
	Try {
		Set tStatus = $$$OK
		If batchName = "" Quit
		
		Set tBatchName = $$$NormalizeClassname(batchName)
		Set tBatchDef = ##class(%Dictionary.ClassDefinition).%OpenId(tBatchName)
		If '$IsObject(tBatchDef) {
			Set tBatchDef = ##class(%Dictionary.ClassDefinition).%New()
			Set tBatchDef.Name = tBatchName
			Set tBatchDef.Super = "%Library.Persistent,"_$$$SimpleBatch
			Set tBatchDef.ClassVersion = 25
			Set tTypeParam = ##class(%Dictionary.ParameterDefinition).%New()
			Set tTypeParam.Name = "XMLTYPE"
			Set tTypeParam.Default = $Translate(tBatchName, ".", "_")
			Do tBatchDef.Parameters.Insert(tTypeParam)
		}
		
		If ","_tBatchDef.Super_"," '[ (","_$$$SimpleBatch_",") {
			Set tStatus = $$$ERROR($$$EnsRecordMapErrInvalidClass, tBatchName, $$$SimpleBatch)
			Quit
		}
		Set tGenerated = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(tBatchName, "RECORDMAPGENERATED")
		If $IsObject(tGenerated)&&(tGenerated.Default = 0) {
			Set tStatus = $$$ERROR($$$EnsRecordMapErrClassNotRMGenerated, tBatchName)
			Quit
		}
		
		Set tNameParam = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(tBatchName,"XMLNAME")
		If '$IsObject(tNameParam) {
			Set tNameParam = ##class(%Dictionary.ParameterDefinition).%New()
			Set tNameParam.parent = tBatchDef
			Set tNameParam.Name = "XMLNAME"
			Set tNameParam.SequenceNumber = 1
			Set tNameParam.Default = $Translate(tBatchName, ".", "_")
			Set tStatus = tNameParam.%Save()
			If $$$ISERR(tStatus) Quit
		}
		
		Set tParmList = $lb($lb("RECORDMAPGENERATED",1),$lb("BatchHeader",batchHeader),$lb("HeaderTerm",headerTerm),$lb("BatchTrailer",batchTrailer),$lb("TrailerTerm",trailerTerm),$lb("IgnoreLeadingData",''ignoreLeadingData))
		For i=1:1:$listlength(tParmList) {
			Set tParmName = $listget($listget(tParmList, i), 1)
			Set tParmVal = $listget($listget(tParmList, i), 2)
			Set tParmDef = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(tBatchName, tParmName)
			If '$IsObject(tParmDef) {
				Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New()
				Set tParmDef.parent = tBatchDef
				Set tParmDef.Name = tParmName
				Set tParmDef.SequenceNumber = i+1
			}
			Set tParmDef.Default = tParmVal
			Set tStatus = tParmDef.%Save()
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit
		
		Set tStatus = tBatchDef.%Save()
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $$$ISERR(tStatus) Quit $zconvert($system.Status.GetErrorText(tStatus), "O", "HTML")
	Quit 1
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "SaveSimpleBatch": ..#EDITRESOURCE, : "")
}

}
