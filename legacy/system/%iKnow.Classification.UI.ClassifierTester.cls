/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.UI.ClassifierTester Extends (%DeepSee.PMML.UI.AbstractTester, TestUtils) [ Deprecated, System = 4 ]
{

Parameter JSINCLUDES = "zenMenusSMP.js";

Parameter DOMAIN = "%iKnow";

Parameter PAGENAME = "Text Classifier Tester";

Property domain As %ZEN.Datatype.integer;

Property testset As %ZEN.Datatype.string;

Property categoryField As %ZEN.Datatype.string;

Property dataSourceType As %ZEN.Datatype.string [ InitialExpression = "SQL" ];

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text(..#PAGENAME)

	//set pViewIcons(1) = $LB(id,help,icon)
	
	// commands
	// $LB(id,caption,help,onclick)
	set tCount = 0
	set pCommands($i(tCount)) = $lb("cmdOpen",$$$Text("Open"),$$$Text("Open a Text Classifier"),"zenPage.openClassifier();")
	set pCommands($i(tCount)) = $lb("cmdRun",$$$Text("Run"),$$$Text("Run this Text Classifier against the SQL query results"),"zenPage.test();")
	set pCommands($i(tCount)) = $lb("cmdTest",$$$Text("Test"),$$$Text("Show Text Classifier test page"),"zenPage.showTestPage();")
	set pCommands($i(tCount)) = $lb("cmdExport",$$$Text("Export"),"Export test results to cube","zenPage.launchExport();")
	
	quit $$$OK
}

XData dataSourcePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane >
<titleBox id="ttlMainTitle" title="Text to Categorize" />
<spacer height="5" />
<tabGroup id="tgrDataSource" showTabBar="true"
onshowTab="zenPage.setProperty('dataSourceType', (zenThis.getCurrTabNo()==1) ? 'SQL' : 'domain');" >
<tab caption="SQL" cellStyle="padding-bottom:10px;" labelPosition="left">
<textarea label="Data source" id="txtSQL" cols="40" rows="6" 
onchange="var msg = zenPage.CheckSQL(zenThis.getValue()); if (msg!='OK') { alert('Error testing custom SQL:\n' + msg); zenThis.focus(); }"
 hint="Enter a valid SQL query retrieving _Text and _Category columns. Optional columns: _ID and _Config" />
</tab>
<tab caption="Domain">
<vgroup cellStyle="padding-bottom:10px;" labelPosition="left">
<select id="selDSDomain" label="Domain"
onchange="zenPage.changeDomain(zenThis.getValue());"
 queryClass="%iKnow.Domain" queryName="GetAllDomains">
<parameter value="1" />
</select>
<select id="selDSCategoryField" label="Category field" showEmpty="false"
onchange="zenPage.setProperty('categoryField', zenThis.getValue());" />
</vgroup>
<hgroup labelPosition="left" enclosingStyle="padding-bottom:8px;">
<select id="selDSFilterField" label="Test filter" 
onchange="zenPage.changeFilter(zenThis.getValue());" />
<spacer width="10" />
<select id="selDSFilterOperator" showEmpty="false" />
<spacer width="10" />
<text id="selDSFilterValue" />
</hgroup>
</tab>
</tabGroup>
</pane>
}

XData rowLevelTracePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<modalGroup id="popText" groupTitle="Categorized text input" >
<spacer height="5" />
<pane paneName="textInputDetails" />
</modalGroup>
</pane>
}

ClientMethod openClassifier() [ Language = javascript ]
{
	var parms = {
		MODE: '%iKnow.Classification.Classifier',
	};
	zenLaunchPopupWindow('_iKnow.UI.Dialog.openDomain.zen','iKnow','status,scrollbars,resizable=yes,width=800,height=600',parms);
}

ClientMethod showTestPage() [ Language = javascript ]
{
	zenLaunchPopupWindow('_iKnow.Classification.UI.ManualTester.zen?CLASSIFIER='+encodeURIComponent(zenPage.getProperty('definitionClass')),'TEST','status,scrollbars,resizable=yes,width=600,height=500');
}

Method TestModel() As %String [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set ..testId = 0
		if (..dataSourceType = "SQL") {
			set tSC = ..%RunBackgroundMethod("TestClassifierAsync", ..definitionClass, 0, ..customSQL)
		} else {
			set tSC = ..%RunBackgroundMethod("TestClassifierAsync", ..definitionClass, ..domain, ..testset, ..categoryField)
		}
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:"OK")
}

ClassMethod TestClassifierAsync(pDefinition As %String, pDomainId As %Integer, pSpec As %String, pMetaField As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK, tTestId=0, tTaskId = +$job
	try {
		do ..%SetBackgroundMethodStatus("Running...", 0)
		kill ^IRIS.Temp.PMML.BgrTask(tTaskId)
		
		if (pDomainId) {
			set tSC = ##class(%iKnow.Classification.Utils).%RunModelFromDomain(.tTestId, pDefinition, pDomainId, pMetaField, pSpec,, 1)
			quit:$$$ISERR(tSC)
		} else {
			set tSC = ##class(%iKnow.Classification.Utils).%RunModelFromSQL(.tTestId, pDefinition, pSpec,,,, 1)
			quit:$$$ISERR(tSC)
		}
	} catch (ex) {
		set tSC = ex.AsStatus() 
	}
	set ^IRIS.Temp.PMML.BgrTask(tTaskId) = $lb(tTestId, tSC)
	do ..%EndBackgroundMethod()
	quit tSC
}

Method %OnAfterCreatePage() As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ##super()
		quit:$$$ISERR(tSC)
		
		if (..definitionClass'="") && '$$IsDerivedFrom^%occLibrary(..definitionClass, "%iKnow.Classification.Classifier") {
			set tSC = $$$ERROR($$$GeneralError, "Selected class is not an iKnow Classifier: "_..definitionClass)
			quit
		}
		
		set (..%GetComponentById("txtSQL").value, ..customSQL) = $g(%session.Data($classname(),"CustomSQL"))
		
		set ..%GetComponentById("chkExportIKMsr").hidden = 0
		
		if (..definitionClass'="") {
			#dim tDefinition As %iKnow.Classification.Definition.Classifier
			set tSC = ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(..definitionClass, .tDefinition)
			quit:$$$ISERR(tSC)
			set tDomainId = 0
			for i = 1:1:tDefinition.BuilderParameters.Count() {
				set tParam = tDefinition.BuilderParameters.GetAt(i)
				if (tParam.name="MetadataField") {
					set ..categoryField = tParam.value
				} elseif (tParam.name="DomainId") {
					set tDomainId = tParam.value
				} elseif (tParam.name="TestSet") {
					set ..testset = tParam.value
				}
			}
			
			// if a test set is defined, its domain gets priority over the domain used to build the model
			if (..testset'="") {
				set tTestSet = ##class(%iKnow.Filters.Filter).RestoreFilterFromString(..testset)
				if (tTestSet.%IsA("%iKnow.Filters.SimpleMetadataFilter")) {
					set tFilterField = ##class(%iKnow.Objects.MetadataField).PKINDEXOpen(tTestSet.DomainId, tTestSet.FieldId)
					if (tFilterField'="") && $$$ISOK(..OnChangeDomain(tTestSet.DomainId)) {
						
						set ..%GetComponentById("selDSDomain").value = ..domain
						set ..%GetComponentById("selDSCategoryField").value = ..categoryField
						
						set ..%GetComponentById("selDSFilterField").value = tFilterField.Name
						set tSC = ..OnChangeFilter(tFilterField.Name)
						quit:$$$ISERR(tSC)
						set ..%GetComponentById("selDSFilterOperator").value = tTestSet.FilterOperator
						set ..%GetComponentById("selDSFilterValue").value = tTestSet.FilterValue
					}
				} elseif (tTestSet.%IsA("%iKnow.Filters.SqlFilter")) {
					set ..%GetComponentById("selDSFilterField").value = ":SQL"
					set tSC = ..OnChangeFilter(":SQL")
					quit:$$$ISERR(tSC)
					set ..%GetComponentById("selDSFilterValue").value = tTestSet.SqlQuery
				} 
			}

			if tDomainId && '..domain && $$$ISOK(..OnChangeDomain(tDomainId)) {
				set ..%GetComponentById("selDSDomain").value = ..domain
				set ..%GetComponentById("selDSCategoryField").value = ..categoryField
			}
			
			if ..domain {
				set ..%GetComponentById("tgrDataSource").currTab = 2
				set ..dataSourceType = "DOMAIN"
			}
		}
		
		set tSC = ..%OnAfterCreateDetailPane()
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Text Categorization")
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return this.definitionClass;
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$PRODUCT1
	Set pLink($I(pLink)) = $LB(tPageName,..homePage)

	Set tPageName = $$$PRODUCT5
	Set pLink($I(pLink)) = $LB(tPageName,..homePage)
	
	set tPageName = ..%OnGetPageName()
	set pLink($i(pLink)) = $lb(tPageName,$zcvt($className(),"O","URL")_".zen")
	quit $$$OK
}

ClientMethod showText(id) [ Language = javascript ]
{
	var sc = zenPage.setProperty('currentRowId',id);
	zenPage.refreshDetails();
	/*zen('htmlText').refreshContents();
	zen('htmlCategories').refreshContents();
	sc = zen('htmlTrace').setProperty('seed', '');
	zen('htmlTrace').refreshContents();*/
	zen('popText').show();
}

Method DrawRowID(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set tRowId = %query("_ID")
	&html<<a href="javascript:zenPage.showText('#(tRowId)#');">#(tRowId)#</a>>
	quit $$$OK
}

Method GetClassifierClass() As %String [ Private ]
{
	quit ..definitionClass
}

Method GetDetailInput(Output pText As %String, Output pConfig As %String, Output pDomainId As %Integer, Output pSrcId As %Integer) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set pText = "", pConfig = "", pSrcId = 0, pDomainId = 0
		quit:..currentRowId=""
		
		if (..dataSourceType = "SQL") {
			set tHasConfig = ''$f($$$UPPER(..customSQL),"_CONFIG")
			set tStmt = ##class(%SQL.Statement).%New()
			set tSC = tStmt.%Prepare("SELECT _Text"_$s(tHasConfig:", _Config", 1:"")_" FROM ("_..customSQL_") WHERE _ID = '"_..currentRowId_"'")
			quit:$$$ISERR(tSC)
			
			set tResult = tStmt.%Execute()
			do tResult.%Next()
			set pText = tResult.%Get("_Text")
			set:tHasConfig pConfig = tResult.%Get("_Config")
		} else {
			set pSrcId = ..currentRowId, pDomainId = ..domain
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetExportPackageName() As %String [ ZenMethod ]
{
	quit ..definitionClass
}

XData Style
{
<style type="text/css">

.vtLabelLeft, .hzLabelLeft {
	width: 110px;
	padding-right: 10px;
}

.tabGroupBody {
	padding: 10px;
	min-height: 0px;
}

.highlightedTextPane {
	background-color: white;
	overflow-y: scroll;
	height: 250px;
	width: 400px;
}

span.highlightedTerm {
	background-color: #ccccff; 
	border: 1px solid #ccccff; 
	border-left: 2px solid #ccccff; 
	border-right: 2px solid #ccccff; 
	padding-left: 1px; 
	padding-right: 1px;
}

</style>
}

ClientMethod onRefresh() [ Language = javascript ]
{
	zen('selTraceCategories').setValue('');
	zen('selTraceCategories').refreshContents();
}

Method CheckDataSourceHasIdentifier() As %Boolean [ Internal, ZenMethod ]
{
	set tSC = $$$OK, tHasIDColumn = 0
	try {
		if (..dataSourceType = "SQL") {
			set tHasIDColumn = 0, tCustomSQL = ..customSQL
			
			if (tCustomSQL'="") {
				// we need an _ID column in the custom SQL to tie back to the original row
				set tCustomSQLResult = ##class(%SQL.Statement).%New()
				set tSC = tCustomSQLResult.%Prepare(tCustomSQL)
				quit:$$$ISERR(tSC)
				set tHasIDColumn = $d(tCustomSQLResult.%Metadata.columnIndex("_ID"))
			}
			
		} else {
			set tHasIDColumn = 1
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tHasIDColumn
}

Method OnBuildRowDetailsQuery(Output pSQL As %String) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		if '..CheckDataSourceHasIdentifier() {
			set tSC = $$$ERROR($$$GeneralError, "Can only drill to row-level details if _ID column selected in custom SQL")
			quit
		}
		
		if (..dataSourceType = "SQL") {
			set tCustomSQL = ..customSQL
			
			if (tCustomSQL'="") {
				// we need an _ID column in the custom SQL to tie back to the original row
				set tCustomSQLResult = ##class(%SQL.Statement).%New()
				set tSC = tCustomSQLResult.%Prepare(tCustomSQL)
				quit:$$$ISERR(tSC)
				merge tColumns = tCustomSQLResult.%Metadata.columnIndex
				set tSELECT = "", tCol = ""
				for {
					set tCol = $order(tColumns(tCol), 1, tColData)
					quit:tCol=""
					continue:tCol="_CATEGORY"
					continue:tCol="_ID"
					continue:tCol="_CONFIG"
					
					if (tCol="_TEXT") {
						// append this to the front
						set tSELECT = ", SUBSTR(s._TEXT, 1, 60) || CASE WHEN LENGTH(s._TEXT)>60 THEN '...' ELSE '' END Text" _ tSELECT
					} else {
						set tSELECT = tSELECT _ ", s."_$li(tColData,2)
					}
				}
			}
			
			set tSELECT = "SELECT s._ID"_tSELECT
			set pSQL = tSELECT _ " FROM ("_tCustomSQL_") s, %DeepSee_PMML_Utils.TempResult r"
			set pSQL = pSQL _ " WHERE r.TestId = "_..testId_" AND r.ActualValue = '"_..currentActualValue_"' AND r.PredictedValue = '"_..currentPredictedValue_"' AND r.TestRecordId = s._ID"
		 
		} else {
			
			set pSQL = "SELECT s.SourceId _ID, SUBSTR(s.FullText, 1, 60) || CASE WHEN LENGTH(s.FullText)>60 THEN '...' ELSE '' END Text "
			set pSQL = pSQL _ "FROM %iKnow_Objects.Source s, %DeepSee_PMML_Utils.TempResult r"
			set pSQL = pSQL _ " WHERE s.DomainId = "_..domain_" AND r.TestId = "_..testId_" AND r.ActualValue = '"_..currentActualValue_"' AND r.PredictedValue = '"_..currentPredictedValue_"' AND r.TestRecordId = s.SourceId"
			
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod changeDomain(domain) [ Language = javascript ]
{
	if (zenPage.OnChangeDomain(domain) == 1) {
		zen('selDSFilterField').refreshContents();
		zen('selDSFilterOperator').refreshContents();
		
		var sc = zen('selDSCategoryField').refreshContents();
		var catField = zenPage.getProperty('categoryField');
		if ((catField != '') && (catField != null)) {
			zen('selDSCategoryField').setValue(catField);
		}
	}
}

/// called when selDSDomain changes
Method OnChangeDomain(pDomainId As %Integer, pAlertOnError As %Boolean = 1) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set ..domain = pDomainId
	
		set:pDomainId tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
		quit:$$$ISERR(tSC)
		set i = "", tValues=""
		for {
			set i = $order(tFields(i), 1, tField)
			quit:i=""
			
			set tValues = tValues _ "," _ $li(tField,2)
		}
		set tValues = $e(tValues,2,*)
		
		set ..%GetComponentById("selDSCategoryField").valueList = tValues
		set ..%GetComponentById("selDSFilterField").valueList = tValues_",:SQL"
		set ..%GetComponentById("selDSFilterField").displayList = tValues_",SQL"
		
		set ..%GetComponentById("selDSFilterOperator").disabled = 1
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) && pAlertOnError {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

ClientMethod changeFilter(field) [ Language = javascript ]
{
	if (zenPage.OnChangeFilter(field) == 1) {
		zen('selDSFilterOperator').refreshContents();
	}
}

Method OnChangeFilter(pField As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set selDSFilterOperator = ..%GetComponentById("selDSFilterOperator")
		if (pField=":SQL") || (pField="") {
			set selDSFilterOperator.valueList = ""
			set selDSFilterOperator.disabled = 1
		} else {
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFieldInfo(..domain, pField, .tInfo)
			quit:$$$ISERR(tSC)
			set selDSFilterOperator.valueList = tInfo("SupportedOperators")
			set selDSFilterOperator.disabled = 0
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

ClientMethod checkDataSource() [ Language = javascript ]
{
	if (zenPage.getProperty('dataSourceType')=='SQL') return true;
	
	var field = zen('selDSFilterField').getValue();
	var op = zen('selDSFilterOperator').getValue();
	var value = zen('selDSFilterValue').getValue();
	return (zenPage.CheckTestFilter(field, op, value) == 1);
}

Method CheckTestFilter(pField As %String, pOperator As %String, pValue As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		quit:'..domain
		
		if (pField="") {
			set ..testset = ""
			quit
		}
		
		if (pField = ":SQL") {
			set tFilter = ##class(%iKnow.Filters.SqlFilter).%New(..domain, pValue)
		} else {
			set tFilter = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(..domain, pField, pOperator, pValue)
		}
		if (tFilter="") {
			set tSC = %objlasterror
			quit
		}
		
		set ..testset = tFilter.ToString()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

}
