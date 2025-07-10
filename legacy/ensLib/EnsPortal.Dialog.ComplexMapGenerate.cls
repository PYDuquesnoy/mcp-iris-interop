/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

Class EnsPortal.Dialog.ComplexMapGenerate Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Generate Complex RecordMap Classes";

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
.genList {
	border: 1px solid darkgray;
	border-bottom: none;
	background-color: white;
	font-size: 0.95em;
}
.genHeader {
	font-weight: bold;
	font-size: 0.8em;
	padding-top: 4px;
}
.genListCell {
	border-bottom: 1px solid darkgray;
}
.genListEntry {
	padding: 2px;
}
.genListEntry.generated {
	font-weight: bold;
}
.genListEntry.exists {
	font-weight: bold;
	color: red;
}
.genListEntry.intact {
}
.genListEntry.new {
}
.clearStorageCaption {
	font-size: 10pt;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<jsonProvider id="expectedClasses" OnRenderJSON="GetExpectedClasses">
<parameter id="includeRecordMaps" paramName="includeRecordMaps" value="0" />
</jsonProvider>
<label id="result" controlClass="redText" value=""/>
<hgroup id="supplied">
<vgroup width="60%" id="id1" label="Complex RecordMap Name:" labelClass="reqLabel">
<label id="mapName" />
</vgroup>
<vgroup width="60%" id="id2" label="Target Classname:" labelClass="reqLabel">
<label id="targetClassname" />
</vgroup>
</hgroup>
<html><hr/></html>
<vgroup id="id3" cellStyle="padding:3px;padding-left:20px;">
<checkbox id="generateRecordMaps" label="Generate RecordMaps" title="Regenerate all RecordMaps as well as the batch classes" onchange="zenPage.toggleRecordMapGeneration(zenThis.value);" />
<hgroup>
<select id="Compile" label="Compile generated classes" showEmpty="false" valueList="0,1,2" 
displayList="Do not compile,Compile entire package,Compile generated classes"
value="2" onchange="zenPage.changedCompile();"
/>
<text id="CompileFlags" label="Compile flags" containerStyle="padding-left:15px;" controlClass="padding-left:3px;" value="ck" />
</hgroup>
<select id="Overwrite" label="Overwrite behavior" showEmpty="false" valueList="0,2" 
displayList="Always overwrite existing classes,Never overwrite existing classes"
value="0"
/>
<checkbox id="ClearStorage" label="Clear existing storage" value="0" caption="Clear the existing storage definition" captionClass="clearStorageCaption" hint="You should only clear the storage if you do not have any data. In most cases, you should leave this option unchecked." />
</vgroup>
<html><hr/></html>
<vgroup id="genList" label="Generated Classes" labelStyle="font-weight: bold;" containerStyle="padding:3px;padding-left:20px;">
<spacer height="5" />
<html id="classList"></html>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Generate Complex RecordMap")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// User changed Compile drop-down. Show/hide Compile flags field.
ClientMethod changedCompile() [ Language = javascript ]
{
	var compileValue = zen('Compile').getValue();
	zen('CompileFlags').setHidden(compileValue=='0');
}

ClientMethod toggleRecordMapGeneration(newValue) [ Language = javascript ]
{
	var includeParm = zen('includeRecordMaps');
	var numValue = (newValue ? 1 : 0);
	includeParm.value = numValue;
	zen('expectedClasses').reloadContents();
	this.drawExpectedClasses();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.complexMap;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var genList = new zenProxy();
		var includeRecordMaps = zen('generateRecordMaps').getValue();
		var compile = zen('Compile').getValue();
		var compileFlags = zen('CompileFlags').getValue();
		var overwrite = zen('Overwrite').getValue();
		var keepStorage = !zen('ClearStorage').getValue();
		var errMsg = this.GenerateMap(includeRecordMaps,compile,compileFlags,overwrite,genList,keepStorage);
		if (errMsg != '') {
			alert($$$Text('An error occurred during Complex RecordMap generation:')+'\n'+errMsg);
			return false;
		}
		var genMessage = $$$Text('Complex RecordMap successfully generated');
		var classList = [];
		for (var genIndex in genList) {
			if (genIndex.substring(0,9) == 'classList') classList.push(genList[genIndex]);
		}
		if (classList.length > 0) {
			genMessage += '\n' + $$$Text('The following classes were successfully generated:') + '\n';
			genMessage += classList.join('\n\t');
		}
		alert(genMessage);
		return true;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClientMethod ondialogStart() [ Language = javascript ]
{
	this.drawExpectedClasses();
}

ClientMethod drawExpectedClasses() [ Language = javascript ]
{
	var classList = zen('classList');
	if (!classList) return;
	classList.setContent('');
	var html = [];
	var expectedClasses = zen('expectedClasses');
	if (expectedClasses) {
		var classData = expectedClasses.getContentObject();
		if (classData && classData.targetClassname) {
			zen('targetClassname').setValue(classData.targetClassname);
		}
		var types = {	"exists": $$$Text('Existing classes which will be overwritten'),
						"generated": $$$Text('Generated classes which will be overwritten (RECORDMAPGENERATED = 1)'),
						"intact": $$$Text('Existing classes which will not be overwritten (RECORDMAPGENERATED = 0)'),
						"new": $$$Text('New classes') };
		for (var type in types) {
			if (classData && classData[type]) {
				html.push('<div class="genGroup">');
				html.push('<span class="genHeader">'+types[type]+'</span>');
				html.push('<table class="genList" cellspacing="0">');
				for (var i = 0; i < classData[type].length; i++) {
					html.push('<tr><td class="genListCell"><span class="genListEntry '+type+'">'+classData[type][i]+'</span></td></tr>');
				}
				
				html.push('</table>');
				html.push('</div>');
			}
		}
		classList.setContent(html.join(''));
	}
}

ClientMethod writeMsg(msg) [ Language = javascript ]
{
	var result = zenPage.getComponentById('result');
	result.setHidden(false);
	result.setValue(msg);
}

/// Save general association data to server
Method GenerateMap(pIncludeRecordMaps As %Boolean = 0, pCompile As %Integer = 2, pCompileFlags As %String = "ck", pOverwriteBehaviour As %Integer = 0, ByRef pGeneratedClasses As %ZEN.proxyObject, pKeepStorage As %Boolean = 1) As %String [ ZenMethod ]
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = ##class(EnsLib.RecordMap.ComplexGenerator).Generate(..complexMap,pIncludeRecordMaps,pCompile,0,pCompileFlags,pOverwriteBehaviour,.tClasses,''pKeepStorage)
		If $$$ISERR(tStatus) Quit
		
		Do pGeneratedClasses.%Clear()
		// Use numeric subscripts to avoid a bug in the proxy object where it doesn't accept subscripts that contain .'s
		Set tClass = ""
		Set tCounter = 0
		For {
			Set tClass = $order(tClasses(tClass))
			Quit:(tClass = "")
			Set tCounter = tCounter + 1
			Set tNumList("classList"_tCounter) = tClass
		}
		Do pGeneratedClasses.%CopyFromArray(.tNumList)
	}
	Catch ex {
		Set tStatus = $$$SystemError
	}
	If $$$ISOK(tStatus) Quit ""
	Quit $system.Status.GetErrorText(tStatus)
}

Method GetExpectedClasses(ByRef pParms) As %Status
{
	Set tIncludeRecordMaps = $get(pParms("includeRecordMaps"),0)
	Set tStatus = ##class(EnsLib.RecordMap.ComplexGenerator).GetGeneratedObjects(..complexMap,tIncludeRecordMaps,.tClasses,.tTargetClassname)
	If $$$ISERR(tStatus) Quit tStatus
	
	Set tClass = ""
	For {
		Set tClass = $order(tClasses(tClass))
		Quit:(tClass = "")
		Set tType = ""
		If ##class(%Dictionary.ClassDefinition).%ExistsId(tClass) {
			Set tGenParm = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(tClass,$$$RecordMapGenerated)
			If $IsObject(tGenParm) {
				If tGenParm.Default {
					Set tType = "generated"
				}
				Else { // won't be overwritten
					Set tType = "intact"
				}
			}
			Else {
				Set tType = "exists"
			}
		}
		Else { Set tType = "new" }
		If tType '= "" Set tOutputList(tType,tClass) = ""
	}
	
	Write "{ ""targetClassname"": """ _ tTargetClassname _ """",!
	Set tType = ""
	For {
		Set tType = $order(tOutputList(tType))
		Quit:(tType = "")
		Write ","""_tType_""": [ "
		Set tFirst = 1
		Set tClass = ""
		For {
			Set tClass = $order(tOutputList(tType,tClass))
			Quit:(tClass = "")
			If tFirst { Set tFirst = 0 }
			Else { Write ", " }
			Write """"_tClass_""""
		}
		Write " ]"
	}
	Write " }"
	Quit $$$OK
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
	Set ..complexMap = $$$NormalizeClassname(..complexMap)
	Set ..%GetComponentById("mapName").label = ..complexMap

	Quit $$$OK
}

}
