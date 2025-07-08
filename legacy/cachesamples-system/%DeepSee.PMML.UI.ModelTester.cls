/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.UI.ModelTester Extends %DeepSee.PMML.UI.AbstractTester [ System = 4 ]
{

Parameter JSINCLUDES = "zenMenusSMP.js";

Parameter PAGENAME = "PMML Model Tester";

Parameter DOCBOOKID = "APMML_testpage";

Property modelName As %ZEN.Datatype.string(ZENURL = "MODEL");

Property dataSource As %ZEN.Datatype.string(ZENURL = "DATASOURCE");

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Predictive Analytics")

	//set pViewIcons(1) = $LB(id,help,icon)
	
	// commands
	// $LB(id,caption,help,onclick)
	set tCount = 0
	set pCommands($i(tCount)) = $lb("cmdNew",$$$Text("New"),$$$Text("Create a PMML definition class from a file"),"zenPage.newModel();")
	set pCommands($i(tCount)) = $lb("cmdOpen",$$$Text("Open"),$$$Text("Open a PMML model"),"zenPage.openModel();")
	set pCommands($i(tCount)) = $lb("cmdRun",$$$Text("Run"),$$$Text("Run this PMML model against the selected data source"),"zenPage.test();")
	set pCommands($i(tCount)) = $lb("cmdTest",$$$Text("Test"),$$$Text("Show PMML model test page"),"zenPage.showTestPage();")
	set pCommands($i(tCount)) = $lb("cmdExport",$$$Text("Export"),"Export test results to cube","zenPage.launchExport();")
	
	Quit $$$OK
}

XData dataSourcePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane >
<titleBox id="ttlMainTitle" title="PMML Model" />
<spacer height="5" />
<vgroup cellStyle="padding-bottom:10px;" labelPosition="left">
<select label="Model" id="selModel" showEmpty="false"
 onchange="zenPage.selectModel(zenThis.getValue());" />
<select label="Data source" id="selDataSource" showEmpty="false"
onchange="zenPage.selectDataSource(zenThis.getValue());" />

<textarea label="Custom data source" id="txtSQL" cols="40" rows="6" 
onchange="var msg = zenPage.CheckSQL(zenThis.getValue()); if (msg!='OK') { alert('Error testing custom SQL:\n' + msg); zenThis.focus(); }"
 disabled="true" hint="Enter a valid SQL query. Include an identifier column named _ID to enable drilldown." />
</vgroup>
<spacer height="20" />
</pane>
}

ClientMethod openModel() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE=pmmlModels','PMML','status,scrollbars,resizable=yes,width=800,height=600');
}

ClientMethod selectModel(model) [ Language = javascript ]
{
	var sc = zenPage.setProperty('modelName', model);
	sc = zenPage.OnSelectModel();
	if (sc!='OK') alert(sc);
	sc = zen('selDataSource').refreshContents(1);
	sc = zenPage.selectDataSource(zenPage.getProperty('dataSource'));
	zen('txtSQL').refreshContents();
	
	sc = zenPage.changeMode();
	sc = zenPage.reset();
}

ClientMethod showTestPage() [ Language = javascript ]
{
	zenLaunchPopupWindow(encodeURIComponent(zenPage.getProperty('definitionClass'))+'.zen?EMBEDDED=1&MODEL='+encodeURIComponent(zen('selModel').getValue()),'TEST','status,scrollbars,resizable=yes,width=800,height=600');
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler');// ZHJ036: SMP Reskin
	var model = zenPage.getProperty('modelName');
	if (model=='') return;
	var sc = zen('selModel').setValue(model);
	sc = zenPage.selectModel(model);
	
	var ds = zenPage.getProperty('dataSource');
	sc = zen('selDataSource').setValue(ds);
	sc = zenPage.selectDataSource(ds);
	
	zenPage.enableAutoRefresh = true;		// DTB816
	
	this.invokeSuper('onloadHandler', arguments);
}

ClientMethod checkDataSource() [ Language = javascript ]
{
	if (zen('selDataSource').getValue()=='') {
		alert($$$Text('Please select a data source'));
		zen('selDataSource').focus();
		return false;
	}
	return true;
}

Method TestModel() As %String [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set ..testId = 0
		set tSC = ..%RunBackgroundMethod("TestModelAsync", ..definitionClass, ..modelName, ..dataSource, ..customSQL)
				
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:"OK")
}

Method CheckDataSourceHasIdentifier() As %Boolean [ Internal, ZenMethod ]
{
	set tSC = $$$OK, tHasIDColumn = 0
	try {
		if (..dataSource = "CUSTOM") {
			set tHasIDColumn = 0, tCustomSQL = ..customSQL
			
			if (tCustomSQL'="") {
				set tCustomSQLResult = ##class(%SQL.Statement).%New()
				set tSC = tCustomSQLResult.%Prepare(tCustomSQL)
				quit:$$$ISERR(tSC)
				set tHasIDColumn = $d(tCustomSQLResult.%Metadata.columnIndex("_ID"))
			}
		} elseif (..dataSource="VERIFICATION") {
			set tHasIDColumn = 1
		} else {
			#dim tDataset As %DeepSee.PMML.Dataset
			set tSC = $classmethod(..definitionClass, "%CreateDataset", $p(..dataSource,":",2,*), .tDataset)
			quit:$$$ISERR(tSC)
			
			set tHasIDColumn = ($isobject(tDataset.IdField) && (tDataset.IdField.Spec'=""))
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tHasIDColumn
}

ClassMethod TestModelAsync(pDefinition As %String, pModelName As %String, pDataSource As %String, pSQL As %String) As %Status [ Internal ]
{
	set tSC = $$$OK, tTestId=0, tTaskId = +$job
	try {
		do ..%SetBackgroundMethodStatus("Running...", 0)
		kill ^IRIS.Temp.PMML.BgrTask(tTaskId)
		
		if (pDataSource="CUSTOM") {
			set tSC = ##class(%DeepSee.PMML.Utils).%RunModelFromSQL(.tTestId, pDefinition, pModelName, pSQL,, 1)
		} elseif (pDataSource="VERIFICATION") {
			set tSC = ##class(%DeepSee.PMML.Utils).%RunModelFromPMMLRows(.tTestId, pDefinition, pModelName,, 1)
		} else {
			set tSC = ##class(%DeepSee.PMML.Utils).%RunModel(.tTestId, pDefinition, pModelName, $p(pDataSource,":",2,*),, 1)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus() 
	}
	set ^IRIS.Temp.PMML.BgrTask(tTaskId) = $lb(tTestId, tSC)
	do ..%EndBackgroundMethod()
	quit tSC
}

Method OnSelectModel() As %String [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set (tDisplayList,tValueList,tDefaultSQL) = ""
		
		if (..testId) {
			do ..DropTestResults(..testId)
			set ..testId = 0
		}
		
		if (..definitionClass'="") {
			
			// first find the right Model definition
			set tSC = $classmethod(..definitionClass, "%GetDefinition", .tPMML)
			quit:$$$ISERR(tSC)
			if (..modelName="") {
				set tModelDef = tPMML.Models.GetAt(1)
			} else {
				set tModelCount = tPMML.Models.Count()
				for i = 1:1:tModelCount {
					set tThisModel = tPMML.Models.GetAt(i)
					if (tThisModel.modelName=..modelName) {
						set tModelDef = tThisModel
						quit
					}
					
					// BDB504 - reproduce pseudo model name
					if (tThisModel.modelName="") {
						set tModelClass = $classname(tThisModel)
						set tIndex = $i(tClasses(tModelClass))-1
						set tName = $piece(tModelClass,".",*)_$s(tIndex:tIndex, 1:"")
						if (..modelName=tName) {
							set tModelDef = tThisModel
							quit
						}
					}
				}
			}
			if (tModelDef="") {
				set tSC = $$$ERROR($$$GeneralError, "Could not find model named '"_..modelName_"' in class '"_..definitionClass_"'")
				quit
			}
			
			// store model target type
			set tModelClass = $classmethod(..definitionClass, "%GetModelClassName", ..modelName)
			do $classmethod(tModelClass, "%GetPredictedFieldInfo", .tFieldName, .tFieldDataType, .tFieldOpType)
			set ..mode = tFieldOpType
			
			
			// check if there is a ModelVerification element
			if $isobject(tModelDef.ModelVerification) {
				set tValueList = "VERIFICATION,"
				set tDisplayList = "ModelVerification element in PMML definition,"
			}
			
			
			// now find any X-*DataSource element
			for i = 1:1:tPMML.DataDictionary.Extension.Count() {
				set tExtension = tPMML.DataDictionary.Extension.GetAt(i)
				continue:tExtension.name'="isc:datasource"
				
				for j = 1:1:tExtension.iscExtensions.Count() {
					set tCustomExtension = tExtension.iscExtensions.GetAt(j)
					continue:'tCustomExtension.%Extends("%DeepSee.PMML.Definition.Extension.DataSource")
					
					// use the first SQLDataSource's SQL to populate the SQL textbox
					if (tDefaultSQL="") && tCustomExtension.%Extends("%DeepSee.PMML.Definition.Extension.SQLDataSource") {
						set tDefaultSQL = tCustomExtension.SQL
					}
					
					set tValueList = tValueList _ "DS:"_tCustomExtension.name_","
					set tDisplayList = tDisplayList _ tCustomExtension.name_","
				}
			}
			
			
			// add custom datasource
			set tValueList = tValueList _ "CUSTOM"
			set tDisplayList = tDisplayList _ "Custom data source (SQL)"
			
			
		}
		
		set tSelect = ..%GetComponentById("selDataSource")
		set tSelect.valueList = tValueList
		set tSelect.displayList = tDisplayList
		
		// this value will be picked up by selectModel()
		set (tSelect.value, ..dataSource) = $p(tValueList,",",1)
		
		do ..%SetValueById("txtSQL", tDefaultSQL)
		set ..customSQL = tDefaultSQL
		
		
		set ..currentActualValue = ""
		set ..currentPredictedValue = ""
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:"OK")
}

Method %OnAfterCreatePage() As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ##super()
		quit:$$$ISERR(tSC)
		
		set (..%GetComponentById("txtSQL").value, ..customSQL) = $g(%session.Data($classname(),"CustomSQL"))
		
		
		// populate selModel
		set (tValueList, tDisplayList) = ""
		if (..definitionClass'="") {
			if '$$IsDerivedFrom^%occLibrary(..definitionClass, "%DeepSee.PMML.Definition") {
				set tSC = $$$ERROR($$$GeneralError, "Selected class is not a PMML definition: "_..definitionClass)
				quit
			}
			
			set tSC = $classmethod(..definitionClass, "%GetModels", .tModels)
 			quit:$$$ISERR(tSC)
			
			for i = 1:1:tModels {
				set tModel = tModels(i)
				set tValueList = tValueList _ $s(tValueList="":"", 1:",") _ $lg(tModel,1)
				set tDisplayList = tDisplayList _ $s(tDisplayList="":"", 1:",") _ $lg(tModel,1)_" ("_$lg(tModel,3)_")"
			}
		}
		
		set tSelPMMLDef = ..%GetComponentById("selModel")
		set tSelPMMLDef.valueList = tValueList
		set tSelPMMLDef.displayList = tDisplayList
		
		// will be picked up by onloadHandler()
		set (tSelPMMLDef.value, ..modelName) = $p(tValueList,",",1)
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("PMML Model Tester")
}

Method DrawRowID(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	write %query("_ID")
	quit $$$OK
}

Method GetExportPackageName() As %String [ ZenMethod ]
{
	quit ..definitionClass _ "." _ ..modelName
}

Method OnBuildRowDetailsQuery(Output pSQL As %String) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tHasIDColumn = 0, tCustomSQL = ""
		
		if ($e(..dataSource,1,3)="DS:") {
			
			set tSC = $classmethod(..definitionClass, "%CreateDataset", $e(..dataSource,4,*), .tDS)
			quit:$$$ISERR(tSC)
			if (tDS.%Extends("%DeepSee.PMML.Dataset.SQL")) {
				set tCustomSQL = tDS.SQL
			} else {
				set tSC = $$$ERROR($$$NotImplemented) // not supported
				quit
			}
			
		} elseif (..dataSource="CUSTOM") {
			set tCustomSQL = ..customSQL
		}
		
		if (tCustomSQL'="") {
			// we need an _ID column in the custom SQL to tie back to the original row
			set tCustomSQLResult = ##class(%SQL.Statement).%New()
			set tSC = tCustomSQLResult.%Prepare(tCustomSQL)
			quit:$$$ISERR(tSC)
			merge tColumns = tCustomSQLResult.%Metadata.columnIndex
			set tHasIDColumn = $d(tColumns("_ID"))
			set tSELECT = "", tCol = ""
			for {
				set tCol = $order(tColumns(tCol), 1, tColData)
				quit:tCol=""
				continue:tCol="_ID"
				set tColName = $li(tColData,2)
				if $system.SQL.IsReservedWord(tColName) {
					set tSELECT = tSELECT _ ", s."_$$$QUOTE(tColName)
				} else {
					set tSELECT = tSELECT _ ", s."_tColName
				}
			}
		}
		
		if 'tHasIDColumn {
			set tSC = $$$ERROR($$$GeneralError, "Can only drill to row-level details if _ID column selected in custom SQL")
			quit
		}
		
		set tSELECT = "SELECT s._ID"_tSELECT
		set pSQL = tSELECT _ " FROM ("_tCustomSQL_") s, %DeepSee_PMML_Utils.TempResult r"
		set pSQL = pSQL _ " WHERE r.TestId = "_..testId_" AND r.ActualValue = '"_..currentActualValue_"' AND r.PredictedValue = '"_..currentPredictedValue_"' AND r.TestRecordId = s._ID"
		
	} catch (ex) {
		set tSC = $$$OK
	}
	quit tSC
}

ClientMethod selectDataSource(ds) [ Language = javascript ]
{
	var sc = zenPage.setProperty('dataSource', ds);
	zen('txtSQL').setProperty('disabled', (ds=='CUSTOM') ? false : true);
	zenPage.DropTestResults(0);
	zenPage.reset();
}

XData moreContentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<modalGroup id="modNew" groupTitle="New PMML class" >
<form id="formUpload" enctype="multipart/form-data" labelPosition="left" cellStyle="padding: 3px;">
<text id="txtUploadClass" label="Class name" name="ClassName" controlStyle="width:350px;" />
<hidden id="txtFileNameHidden" name="FileName" />
<fileUpload id="fileUpload" label="PMML file" name="File" size="30" onchange="zenPage.onUpload();" accept=".xml,.pmml"/>
<submit id="btnImport" caption="Import" onclick="zen('btnImport').setProperty('caption','Importing...'); zen('btnImport').setProperty('disabled',true);" />
</form>
</modalGroup>
</pane>
}

ClientMethod newModel() [ Language = javascript ]
{
	zen('btnImport').setProperty('caption','Import');
	zen('btnImport').setProperty('disabled',false);
	zen('modNew').show();
}

ClientMethod onUpload() [ Language = javascript ]
{
	zen('btnImport').setProperty('disabled',false);
	var fileName = zenPage.getComponentById('fileUpload').getValue()
	if (fileName==''){ //special case to handle the file name reset on clicking cancel in Chromium-based browsers
		zen('btnImport').setProperty('disabled',true);
		zen('txtFileNameHidden').setValue(fileName);
		return;
	}
	fileName = fileName.toString().replace(/\\/g,'/');
	var t = fileName.split('/');
	fileName = t[t.length-1]; 
	var ext = fileName.substr(fileName.lastIndexOf('.')+1).toLowerCase()
	var allowedTypes=['xml','pmml']
	
	if (allowedTypes.includes(ext)){
		zen('txtFileNameHidden').setValue(fileName);
	}
	else{
		zen('btnImport').setProperty('disabled',true);
		alert('Invalid file type: "'+ext+'". The file must be of one of the following types: '+allowedTypes.join(', '));
	}
}

ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	set tSC = $$$OK
	try {
		set tName = pSubmit.%GetValue("ClassName")
		set tStream = pSubmit.%GetStream("File")
		set tUploadFileName = pSubmit.%GetValue("FileName")
		Set tExt = $ZCVT($P(tUploadFileName, ".",*),"L")
		Set tAllowedTypes = $lb("xml", "pmml")
		If '$LF(tAllowedTypes, tExt){
			Set tSC=$$$ERROR($$$InvalidFileType, """"_tExt_""". Valid file types are: "_$ListToString(tAllowedTypes, ", "))
			Quit
		}
		
		if ((tName'="") && ($IsObject(tStream))) {
			
			set tSC = ##class(%DeepSee.PMML.Utils).CreateFromStream(tStream, tName, 0, 1, 0)
			quit:$$$ISERR(tSC)
			
			set %response.Context("CLASS") = tName
		}

	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawRecordDetails(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		
		if '..CheckDataSourceHasIdentifier() {
			write "<p>Data source should select a row identifier to be able to drill to the detail level.</p>"
			quit
		}
		
		// first build an array with all available fields, based on the selected data source row
		kill tData
		set tCubeBased = 0
		if (..dataSource="CUSTOM") {
			
			//set tSQL = "SELECT s.*, t.* FROM ("_..customSQL_") s JOIN %DeepSee_PMML_Utils.TempResult t ON s._ID = t.TestRecordId WHERE t.TestId = ? AND _ID = ?"
			set tSQL = "SELECT * FROM ("_..customSQL_") s WHERE _ID = ?"
			set tStatement = ##class(%SQL.Statement).%New()
			set tSC = tStatement.%Prepare(tSQL)
			quit:$$$ISERR(tSC)
			
			set tResult = tStatement.%Execute(..currentRowId)
			quit:'tResult.%Next()
			
			for i = 1:1:tStatement.%Metadata.columnCount {
				set tData(tStatement.%Metadata.columns.GetAt(i).colName) = tResult.%GetData(i)
			}
			
		} elseif (..dataSource="VERIFICATION") {
			
			#dim tPMML As %DeepSee.PMML.Definition.PMML
			set tSC = $classmethod(..definitionClass, "%GetDefinition", .tPMML)
			quit:$$$ISERR(tSC)
			#dim tModel As %DeepSee.PMML.Definition.Models.AbstractModel
			if (..modelName="") {
				set tModel = tPMML.Models.GetAt(1)
			} else {
				kill tModelNames
				for i = 1:1:tPMML.Models.Count() {
					set tThisModel = tPMML.Models.GetAt(i)
					if (tThisModel.modelName = ..modelName) {
						set tModel = tThisModel
					} elseif (tThisModel.modelName = "") {
						set tModelClass = $piece($classname(tThisModel),".",*)
						if (..modelName = (tModelClass_$i(tModelNames(tModelClass)))) {
							set tModel = tThisModel
						}
					}
				}
			}
			set tSC = tModel.ModelVerification.InlineTable.%GetRows(.tRowData)
			quit:$$$ISERR(tSC)
			for i = 1:1:tModel.ModelVerification.Fields.Fields.Count() {
				set tField = tModel.ModelVerification.Fields.Fields.GetAt(i)
				set tData(tField.field) = tRowData(..currentRowId, i)
			}
			
		} else {
			
			#dim tDataset As %DeepSee.PMML.Dataset
			set tDataSourceName = $p(..dataSource,":",2,*)
			set tSC = $classmethod(..definitionClass, "%CreateDataset", tDataSourceName, .tDataset)
			quit:$$$ISERR(tSC)
			
			if tDataset.%Extends("%DeepSee.PMML.Dataset.SQL") {
				
				set tStatement = ##class(%SQL.Statement).%New()
				set tIdFieldSpec = tDataset.IdField.Spec
				$$$QUOTEIFRESERVED(tIdFieldSpec)
				set tSC = tStatement.%Prepare("SELECT * FROM (" _tDataset.SQL_ ") WHERE "_tIdFieldSpec_" = ?")
				quit:$$$ISERR(tSC)
				
				set tResult = tStatement.%Execute(..currentRowId)
				quit:'tResult.%Next()
				
				for i = 1:1:tStatement.%Metadata.columnCount {
					set tData(tStatement.%Metadata.columns.GetAt(i).colName) = tResult.%GetData(i)
				}
				
			} elseif tDataset.%Extends("%DeepSee.PMML.Dataset.Cube") {
				
				set tCubeBased = 1, tCubeName = tDataset.CubeName
				
			} else {
				set tSC = $$$ERROR($$$NotImplemented)
				quit
			}
		}
		
		// now create an input object for this data array
		set tSC = $classmethod(..definitionClass, "%GetModelInstance", ..modelName, .tModel)
		quit:$$$ISERR(tSC)
		#dim tInputObj As %DeepSee.PMML.ModelInput
		if (tCubeBased) {
			set tSC = $classmethod(tModel.%GetDataClassName(), "%CreateFromDeepSee", ..currentRowId, .tDataObj, tDataSourceName)
			quit:$$$ISERR(tSC)
			set tInputObj = $classmethod(tModel.%GetInputClassName(), "%CreateFromObject", tDataObj, .tSC)
		} else {
			set tInputObj = $classmethod(tModel.%GetInputClassName(), "%CreateFromArray", .tData, .tSC)
		}
		quit:$$$ISERR(tSC)
		
		// run the model for convenience
		#dim tOutputObj As %DeepSee.PMML.ModelOutput
		set tSC = tModel.%ExecuteModel(tInputObj, .tOutputObj)
		quit:$$$ISERR(tSC)
		set tPredictedField = tModel.%GetPredictedField()
		
		// now finally start drawing!
		write "<table class=""recordDetails"">"
		
		// main target
		write "<tr class=""recordDetailTitle""><td colspan=""2"">Target field: "_tPredictedField_"</td></tr>"
		write "<tr><td>Actual: "_$justify($s(tCubeBased:$property(tDataObj,tPredictedField), 1:$g(tData(tPredictedField))),"",4)_"</td>"
		write "<td>Predicted: "_$justify(tOutputObj.%GetFeatureValue(,tPredictedField),"",4)_"</td></tr>"
		
		// inputs
		do tInputObj.%GetFields(.tInputFields)
		write "<tr class=""recordDetailTitle""><td colspan=""2"">Input fields</td></tr>"
		write "<tr><td>"
		set tField = "", i=0
		for { set tField = $order(tInputFields(tField)) q:tField=""  s x = $i(tInputFields) }
		for {
			set tField = $order(tInputFields(tField))
			quit:tField=""
			set tPropVal = $property(tInputObj, tField)
			set:$isvalidnum(tPropVal)&&(tPropVal#0.0001) tPropVal = $justify(tPropVal,"",4)
			write tField_": "_tPropVal_"<br/>"
			if tInputFields && ($i(i)>=(tInputFields/2)) {
				write "</td><td>"
				set tInputFields = 0
			}
		}
		write "</tr></td>"
		
		// outputs
		do tOutputObj.%GetFields(.tOutputFields)
		write "<tr class=""recordDetailTitle""><td colspan=""2"">Output fields</td></tr>"
		write "<tr><td>"
		set tField = "", i=0
		for { set tField = $order(tOutputFields(tField)) q:tField=""  s x = $i(tOutputFields) }
		for {
			set tField = $order(tOutputFields(tField))
			quit:tField=""
			set tPropVal = $property(tOutputObj, tField)
			set:$isvalidnum(tPropVal)&&(tPropVal#0.0001) tPropVal = $justify(tPropVal,"",4)
			write tField_": "_tPropVal_"<br/>"
			if tOutputFields && ($i(i)>=(tOutputFields/2)) {
				write "</td><td>"
				set tOutputFields = 0
			}
		}
		write "</tr></td>"
		
		// all data
		
		write "</table>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

XData Style
{
<style type="text/css">

.modalGroupBody {
	background-color: rgb(231, 230, 244);
}

table.recordDetails {
	font-size: 0.8em;
	margin: 10px;
	margin-top: 0px;
}

tr.recordDetailTitle {
	font-size: 1em;
	font-weight: bold;
	height: 24px;
	vertical-align: bottom;
}
tr.recordDetailTitle td {
	border-bottom: 1px solid black;
}

</style>
}

}
