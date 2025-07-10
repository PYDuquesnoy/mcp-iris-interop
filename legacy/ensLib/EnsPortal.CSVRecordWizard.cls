/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Wizard to create a RecordMap definition based on a sample file
/// which contains delimited data, possibly with a header row.
Class EnsPortal.CSVRecordWizard Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter PAGENAME = "CSV Record Wizard";

/// User needs READ permissions on either the %Ens_Code or the %Ens_RecordMap resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_RecordMap:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_RecordMap resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_RecordMap:WRITE";

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

Property sampleFile As %ZEN.Datatype.string(ZENURL = "SAMPLEFILE");

Property msgReqSeparator As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Separator is required")} ];

Property msgReqSample As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Sample file is required")} ];

Property msgReqRecordMap As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("RecordMap name is required")} ];

Property msgReqRecTerm As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Record Terminator is required")} ];

Property msgClassExists As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Class '%1' already exists. Overwrite?")} ];

Property msgErrCreating As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Error creating RecordMap:")} ];

XData Style
{
<style type="text/css">
.zenLabel {
	padding-right: 5px;
}
.radioButtonCaption {
	text-decoration: none;
	color: #434343;
	font-size: 10pt;
}
.radioButtonCaption:visited {
	color: #434343;
}
.charGroup {
	border: 1px solid gray;
	padding: 3px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup containerStyle="padding:10px;">
<vgroup labelPosition="left" containerStyle="padding:10px; border: 1px solid black; background-color: lightgrey;">
<hgroup label="Sample file" labelPosition="left">
<text id="sampleFile" title="Filename of sample file" size="30" value="#(%page.sampleFile)#" />
<spacer width="5px" />
<button caption="Select file" controlClass="commandButton" onclick="zenPage.selectFile(); return false;" />
</hgroup>
<spacer height="8px;" />
<text id="recordMapName" label="RecordMap name" title="Name of RecordMap to generate" size="30" />
<spacer height="8px;" />
<text id="separator" label="Separator" value="," title="Separator to use - hex must be used for control characters, e.g. \x0A for Line Feed" size="10" />
<spacer height="8px;" />
<group id="recTermGroup" label="Record Terminator" title="Character or characters used to indicate the end of a record" labelPosition="left" cellVAlign="bottom" enclosingClass="charGroup" layout="horizontal" >
<radioButton id="recTerm_CRLF" name="recTerm" optionValue="\x0d\x0a" value="\x0d\x0a" caption="CRLF" title="Carriage Return, Line Feed" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true);" />
<radioButton id="recTerm_CR" name="recTerm" optionValue="\x0d" caption="CR" title="Carriage Return" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true);" />
<radioButton id="recTerm_LF" name="recTerm" optionValue="\x0a" caption="LF" title="Line Feed" captionClass="radioButtonCaption" onclick="zenPage.onRecTermChange(zenThis.optionValue, true);" />
<spacer width="5px" />
<text id="recTerm_Other" label="Other" labelClass="radioButtonCaption zenLabel" title="Other character - control characters must be represented in hex e.g. \x20 for space" size="10" onchange="zenPage.onRecTermChange(zenThis.value, false);" />
<text id="recTerminator" hidden="true" value="\x0d\x0a" />
</group>
<spacer height="5px" />
<selector id="charEncoding" label="Character Encoding" name="charEncoding" context="Ens.ContextSearch/CharacterSets" title="Character encoding of the source file - the character set must exist within IRIS. A prefix of '@' means to use the named table." size="15" value="UTF-8"/>
<checkbox id="hasHeader" label="Sample has header row" value="0" title="Sample has column names" />
<checkbox id="keepSQLCols" label="Keep SQL Column order" value="0" title="Keep SQL Column order in generated object" />
<checkbox id="escaping" label="Quote-style escaping in use" value="0" title="Quote-style escaping in use" onchange="zenPage.onEscapingChange(!zenThis.value);" />
<text id="escapeChars" label="Quote character" value='"' title="Quote character - hex must be used for control characters, e.g. \x0A for Line Feed" hidden="true" />
<checkbox id="allowEmbeddedRecTerm" label="Allow embedded Record Terminator" value="0" title="Allow quoted field data to have embedded Record Terminators" hidden="true" />
<spacer height="20px;" />
<button id="createBtn" caption="Create RecordMap" controlClass="commandButton" title="Create RecordMap and open in RecordMapper" onclick="zenPage.createRecordMap();" />
</vgroup>
</hgroup>
</pane>
}

ClientMethod createRecordMap() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	// Structure to check and get values from page
	// format: 'propertyName': [ zenId, requiredMsg, isBoolean ]
	var fields = { 	'filename': [ 'sampleFile', this.msgReqSample, false ],
					'recordMap': [ 'recordMapName', this.msgReqRecordMap,  false ],
					'separator': [ 'separator', this.msgReqSeparator, false ],
					'escaping': [ 'escaping', '', true ],
					'quoteChar': [ 'escapeChars', '', false ],
					'hasHeader': [ 'hasHeader', '', true ],
					'recTerm': [ 'recTerminator', this.msgReqRecTerm, false ],
					'charEncoding': [ 'charEncoding', '', false ],
					'keepSQLCols': [ 'keepSQLCols', '', true ],
					'allowEmbeddedRecTerm': ['allowEmbeddedRecTerm', '', false] };
	// Use variables to keep column references readable
	var idCol = 0;
	var msgCol = 1;
	var boolCol = 2;
	var obj = new Object();
	for (var fieldName in fields) {
		var info = fields[fieldName];
		obj[fieldName] = zen(info[idCol]).getValue();
		if (info[msgCol] != '') {
			if (obj[fieldName] == '') {
				alert(info[msgCol]);
				return;
			}
		}
		if (info[boolCol]) {
			obj[fieldName] = (obj[fieldName] == 0 ? false : obj[fieldName]);
		}
	}
	// Set quoteChar = '' if escaping isn't used
	if (!obj.escaping) {
		obj.quoteChar = '';
	}

	if (zenPage.ClassExists(obj.recordMap)) {
		var overwrite = confirm($$$FormatText(this.msgClassExists, obj.recordMap));
		if (!overwrite) { return; }
	}
	
	var ok = zenPage.ProcessCSVFile(obj.filename, obj.recordMap, obj.separator, obj.quoteChar, obj.hasHeader, obj.recTerm, obj.charEncoding, obj.keepSQLCols, obj.allowEmbeddedRecTerm);
	if (ok != '') {
		alert(this.msgErrCreating+ '\n' +ok);
		return;
	}
	// Call synchronously to ensure it returns before we leave the page
	var ok = zenPage.SaveSampleFilename(obj.recordMap, obj.filename);
	zenPage.gotoPage('EnsPortal.RecordMapper.cls?MAP='+obj.recordMap);
}

ClassMethod ClassExists(classname As %String) As %Boolean [ ZenMethod ]
{
	If $get(classname) = "" Quit 0
	Quit ##class(%Dictionary.ClassDefinition).%ExistsId($$$NormalizeClassname(classname))
}

ClassMethod SaveSampleFilename(recordMap = "", filename) As %String [ ZenMethod ]
{
	Do ##class(EnsPortal.RecordMapper).SaveSampleFilename(recordMap, filename)
	Quit ""
}

ClientMethod selectFile() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	var dir = zen('sampleFile').getValue();
	if (dir.length <= 0) dir = zenPage.GetDefaultDir();
	var parms = {
		Dir: dir,
		wildcard:"*.csv"
		};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.fileSelect.zen'),this.addPopupSuffix('CSVSampleFile'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
	case 'CSVSampleFile':
		zen('sampleFile').setValue(value);
		zenPage.SetDefaultDir(value);
		break;
	case 'switchNamespace':
		zenPage.changeURLNamespace(value);
		break;
	}
}

ClientMethod onRecTermChange(newValue, isRadio) [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var idlist = ['CR','LF','CRLF','Other'];
	for (key in idlist) {
		var val = idlist[key];
		var button = zen('recTerm_'+val);
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
	zen('recTerminator').setValue(newValue);
}

ClientMethod onEscapingChange(notEscaping) [ Language = javascript ]
{
	zen('escapeChars').setHidden(notEscaping);
	zen('allowEmbeddedRecTerm').setHidden(notEscaping);
	if (notEscaping) zen('allowEmbeddedRecTerm').setValue(false);
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "CSVSampleFileDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "CSVSampleFileDir") = ##class(%File).GetDirectory(pPathname, 1)
}

ClassMethod ProcessCSVFile(pFilename As %String, pRecordMapName As %String, pSep As %String = ",", pQuoteChar As %String = """", pHasHeaderRow As %Boolean = 0, pRecTerm As %String = "\x0d\x0a", pCharEncoding As %String = "UTF-8", pKeepSQLCols As %Boolean = 1, pAllowEmbeddedRecTerm As %Boolean = 0) As %String [ Internal, ZenMethod ]
{
	New %recTerm,%sep,%quoteChar
	Try {
		Set tStatus = $$$OK
		
		If '($system.Security.Check("%Ens_Code","WRITE") || $system.Security.Check("%Ens_RecordMap","WRITE"))||'$system.Security.Check("%Ens_ViewFileSystem","USE") {
			Set tStatus = $$$ERROR($$$InsufficientPrivilegeForOperation)
			Quit
		}
		
		Set tIO = ##class(%IO.FileStream).%New()
		
		// Make sure we check for a BOM
		Set tEncodingTable = tIO.GetCharEncodingTable(pCharEncoding)
		Set tCheckBOM = $case(tEncodingTable, "Unicode": 1, "UnicodeLittle": 1, "UnicodeBig": 1, "UTF8": 1, : 0)
		If tCheckBOM {
			Set tReadBOM = 0
			Do tIO.Open(pFilename, "R",,"RAW",.tStatus)
			If $$$ISERR(tStatus) Quit
			Set tTestBOM = tIO.Read(2,,.tStatus)
			If $$$ISERR(tStatus) Quit
			If tTestBOM = $char(239,187) {
				Set tTestBOM = tTestBOM _ tIO.Read(1,,.tStatus)
				If $$$ISERR(tStatus) Quit
			}
			Set tExpectedBOM = $case(tEncodingTable, "Unicode": $char(255,254), "UnicodeLittle": $char(255,254), "UnicodeBig": $char(254,255), "UTF8": $char(239,187,191), : "")
			If (tTestBOM '= "") && (tTestBOM = tExpectedBOM) {
				Set tReadBOM = 1
			}
			Do tIO.Rewind(.tStatus)
			If $$$ISERR(tStatus) Quit
			
			Set tStatus = tIO.CharEncodingSet(pCharEncoding)
			If $$$ISERR(tStatus) Quit
			If tReadBOM Do tIO.Read(1,,.tStatus)
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Do tIO.Open(pFilename, "R",,pCharEncoding,.tStatus)
			If $$$ISERR(tStatus) Quit
		}
		
		Set tCount = 0
	
		Set tRecTerm = ##class(EnsLib.RecordMap.Generator).getLogicalChars(pRecTerm)
		Set tGetTerm = "Set %recTerm = "_tRecTerm
		Xecute tGetTerm
		Set tRecTerm = %recTerm
	
		If (pQuoteChar '= "") {
			Set tQuoteChar = ##class(EnsLib.RecordMap.Generator).getLogicalChars(pQuoteChar)
			Set tGetQuote = "Set %quoteChar = "_tQuoteChar
			Xecute tGetQuote

			Set tAllowEmbeddedRecTerm =  ''pAllowEmbeddedRecTerm
		}
		Else { Set %quoteChar = "", tAllowEmbeddedRecTerm = 0 }
	
		Set tSep = ##class(EnsLib.RecordMap.Generator).getLogicalChars(pSep)
		Set tGetSep = "Set %sep = "_tSep
		Xecute tGetSep

		Set tStatus = ##class(EnsLib.RecordMap.RecordMap).chunkRecord(tIO, .tRecData,,,,.tRecTerm,,, %quoteChar, tAllowEmbeddedRecTerm)
		If $$$ISERR(tStatus) Quit
	
		Set tRecordMap = ##class(EnsLib.RecordMap.Model.Record).%New()
		Set tRecordMap.name = $$$NormalizeClassname(pRecordMapName)
		Set tRecordMap.targetClassname = $$$NormalizeClassname(pRecordMapName) _ ".Record"
		Set tRecordMap.charEncoding = pCharEncoding
		If pQuoteChar '= "" {
			Set tRecordMap.escaping = "quote"
			Set tRecordMap.escapeSequence = pQuoteChar
			Set tRecordMap.allowEmbeddedRecordTerminator = tAllowEmbeddedRecTerm
		}
		Set tRecordMap.recordTerminator = pRecTerm
		Set tRecordMap.type = "delimited"
		Do tRecordMap.Separators.Insert(pSep)
		// name and target name
	
		Set tCurrChunk = 1
		Set tCurrPiece = 1
		Set tCurrString = $select($data(tRecData(tCurrChunk,"block")): tRecData(tCurrChunk), 1: $piece(tRecData(tCurrChunk), %sep, tCurrPiece))

		While tCurrChunk {
			Set tCount = tCount + 1
		
			Set tField = ##class(EnsLib.RecordMap.Model.Field).%New()
			Set tField.datatype = "%String"
			Set tField.name = $select(pHasHeaderRow: $zstrip(tCurrString, "*WP"), 1: "Property"_tCount)
			If pKeepSQLCols { // Column numbers start at 2
				Set tField.sqlColumn = tCount+1
			}
			Do tRecordMap.Contents.Insert(tField)
			Do ##class(EnsLib.RecordMap.RecordMap).checkMerge(.tCurrChunk, .tRecData, .tCurrString, %sep, .tCurrPiece, "block")
			If tCurrChunk > tRecData Quit
			Set tCurrString = $select($data(tRecData(tCurrChunk,"block")): tRecData(tCurrChunk), 1: $piece(tRecData(tCurrChunk), %sep, tCurrPiece))
			If (tCurrString = "") && (tCurrChunk = tRecData) && ($length(tRecData(tCurrChunk), %sep) < tCurrPiece) Quit
			// Finished when last item (header or data) is quoted
			If ($get(tRecData(tCurrChunk,"block")) = "end") && (tCurrPiece > 1) && (tCurrChunk = tRecData) Quit
		}

		Set tStatus = tRecordMap.SaveToClass()
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Quit $System.Status.GetErrorText(tStatus)
	}
	Quit ""
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("CSV Record Wizard")

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdCreate",$$$Text("Create"),$$$Text("Create the record map, then edit in the RecordMapper"),"zenPage.createRecordMap();")
	Set pCommands(2) = $LB("cmdRecordMap",$$$Text("RecordMapper"),$$$Text("Go to the RecordMapper"),"zenPage.gotoPage('EnsPortal.RecordMapper.cls');")
	Quit $$$OK
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("CSV Record Wizard","Ensemble")
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, 
						"ProcessCSVFile": ..#EDITRESOURCE,
						: "")
}

}
