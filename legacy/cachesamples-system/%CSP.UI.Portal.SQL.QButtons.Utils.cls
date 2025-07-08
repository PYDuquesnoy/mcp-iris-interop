/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%SYS.PTools.Stats, %sqlui)

/// This class contains shared methods used by the QButtons UI pages.
Class %CSP.UI.Portal.SQL.QButtons.Utils [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

Property SQLHomePage As %ZEN.Datatype.string [ InitialExpression = {..Link("%25CSP.UI.Portal.SQL.Home.zen")} ];

/// Return server info per View Stats. 
Method GetSettingsInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.SQL.QButtons.Utils).GetSettingsData(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method returns information regarding view stats settings for the UI.
ClassMethod GetSettingsData(Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""
		Set flagType = 0
		Set returnActionFlag = ""
		Set tFlag = $SYSTEM.SQL.GetSQLStatsFlag(flagType,returnActionFlag,.ptInfo)
		Set terminateCond = $G(ptInfo("terminate","terminateCond"))
		Set defaultMiinutes = 50
		// If user has entered selection before and it has not expired:
		If $L(terminateCond,":") > 1 {
			Set timeoutOption = $E(terminateCond,1)
			Set resetOption = $P(terminateCond, ":", 3)
			If timeoutOption = "M" {
				Set min = $P(terminateCond, ":", 2)
				Set pObject.Hour = min\60
				Set pObject.Min = min-(pObject.Hour*60)
				// defaults:
				Set pObject.ExpHour = 23
				Set pObject.ExpMin = 59
			} Else {
				Set expirationTime = $P($P(terminateCond, ":", 2)," ",2)
				Set pObject.ExpHour = $E(expirationTime,1,2)
				Set pObject.ExpMin = $E(expirationTime,3,4)
				// defaults:
				Set pObject.Hour = ""
				Set pObject.Min = defaultMiinutes
			}
		} Else {
			// if user has not entered selection before, set defaults here
			Set timeoutOption = "M"
			Set pObject.Hour = ""
			Set pObject.Min = defaultMiinutes
			Set pObject.ExpHour = 23
			Set pObject.ExpMin = 59
			Set resetOption = 0	
		}
		Set pObject.TurnOnStats = $S(tFlag="":0,1:+tFlag)
		Set pObject.timeoutOption = timeoutOption
		Set pObject.resetOption = resetOption
		Set pObject.Today = $P($ZDT($H,3)," ",1)

		// ExpirationDisplay is used by the ViewStats main page to show when this will expire or when had it expired
		If ($G(ptInfo("expired","expiredHDate")) '= "") {
			Set pObject.Expired = 1
			Set pObject.Expiration = ptInfo("expired","expiredHDate")
		} Else {
			Set pObject.Expired = 0
			Set pObject.Expiration = ptInfo("terminate","stopHDate")
		}
		Set pObject.ExpirationDisplay = $S(pObject.Expiration="":"",1:$E($ZDT(pObject.Expiration,3),1,16))			
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

/// This method returns information regarding a cached query for the UI.
ClassMethod GetQueryData(pNamespace, pCursorName, pRoutineName, Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""
		Set pObject.children = ##class(%ListOfObjects).%New()
		Set pObject.routine = $$$FormatText($$$Text("Routine: %1"),pRoutineName)
		Set pObject.server = $$$FormatText($$$Text("Server: %1"), $zu(110))
		Set pObject.instance = $$$FormatText($$$Text("Instance: %1"), $P($zu(86),"*",2))
		Set pObject.namespace = $$$FormatText($$$Text("Namespace: %1"), pNamespace)
		Set pObject.user = $$$FormatText($$$Text("User: %1"), $Username)
		
		Set QueryText = ..GetQueryText(pNamespace,pRoutineName,pCursorName,0)
		If $LV(QueryText) {
			For pos=1:1:$LL(QueryText) {
				Set tChildObj = ##class(%ZEN.proxyObject).%New()
				Set tChildObj.pos = pos
				Set tChildObj.text = $LG(QueryText,pos)
				Do pObject.children.Insert(tChildObj)
			}
		}
		Set pObject.queryText = QueryText
		Set pObject.schema = ..GetImportSchema(pNamespace,pRoutineName,pCursorName,1)
		Set id = pRoutineName_"||"_pCursorName
		Set status = ..PrepareShowPlan(QueryText,pObject.schema,id)
		Set pObject.prepareShowPlan = status	


	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

/// Given a history ID, return query text
ClassMethod GetQueryHistoryText(pID) As %String [ ZenMethod ]
{
	If $D($$$CQ("SMPQueryHistory",$username,0,pID),tData) { 
		Quit $LG(tData,4)
	}
	Quit ""
}

/// This method returns 1 (success) or 0 and clears cached queries.
ClassMethod PurgeQuery(pNamespace) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Do $SYSTEM.SQL.Purge()
	Set proxy.msg = $$$Text("Purge all cached query completed successfully.")
	Quit proxy
}

/// Return PTools SQL Stats Query Text
ClassMethod GetQueryText(pNamespace, pRoutine, pCursor, pInternal = 0) As %String [ ZenMethod ]
{
	Try {
		if $$$collectOriginalSQLStats {	// --- Collect Original Stats ---
			Set QueryText = ##class(%SYS.PTools.SQLStats).QueryText(pCursor,pRoutine,pInternal)
		}
		else {							// --- Collect Optimal Stats ---
			Set QueryText = ##class(%SYS.PTools.StatsSQL).getQueryText(pNamespace,pRoutine,pCursor,pInternal)
		}
	}
	Catch(ex) {
		Set QueryText = ex.AsStatus()
	}
	Quit QueryText
}

ClassMethod GetImportSchema(pNamespace, pRoutine, pCursor, pInternal = 0) As %String [ ZenMethod ]
{
	Try {
		if $$$collectOriginalSQLStats {	// --- Collect Original Stats ---
			Set schema = ##class(%SYS.PTools.SQLStats).ImportSchema(pCursor,pRoutine,pInternal)
		}
		else {							// --- Collect Optimal Stats ---
			Set schema = ##class(%SYS.PTools.StatsSQL).getImportSchema(pNamespace,pRoutine,pCursor)
		}
	}
	Catch(ex) {
		Set schema = ex.AsStatus()
	}
	Quit schema
}

ClassMethod PrepareShowPlan(query, schema = "", id = "") As %String [ ZenMethod ]
{
	//Set %session.Data("$SQLQUERY") = query
	set RoutineName=$p(id,"||",1)
	set ^mqh($Username)=$s(RoutineName="":$s($LV(query):$LISTTOSTRING(query,$c(10)),1:query),$D($$$CQ("QueryText",$S(RoutineName[".cls":$E(RoutineName,1,*-2),1:RoutineName))):$P($$$CQ("QueryText",$S(RoutineName[".cls":$E(RoutineName,1,*-2),1:RoutineName),1),"~RUNTIME~",1),1:$s($LV(query):$LISTTOSTRING(query,$c(10)),1:query))
	set ^mqh($Username,"schema")=schema
	set ^mqh($Username,"id")=id
	QUIT $$$OK
}

/// Returns display messages for settings
/// json should be passed in containing the settings data
ClientMethod getSettingMessages(json) [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	if (!json) {
		return proxy;	
	}
	try {
		var msg = '';
		var tOptionText = '';
		var tOptionText1 = '';
		var tExpiration = '';
		proxy.settingNoteHTML = '<span style="font-weight:800;">' + $$$Text("NOTE: ") + '</span>' + $$$Text("These settings are System-wide setting and apply to all users on the system.  If you wish to collect statistics for a specific Process/Job, or for a specific Namespace, please refer to the 'SQL Runtime Statistics' section of the documentation for additional details.");
		proxy.option = [];
		proxy.option[0] = $$$Text("0 - SQL Runtime Stats is off, and no stats-collection will be included in query code generation");
		proxy.option[1] = $$$Text("1 - SQL Runtime Stats is off, but stats-collection will be included in query code generation");
		proxy.option[2] = $$$Text("2 - SQL Runtime Stats is on, and stats will be collected for the Open and Close modules of a query");
		proxy.option[3] = $$$Text("3 - SQL Runtime Stats is on, and stats will be collected for all modules of a query");
		// when deemed necessary, you can define hint for each option here.
		proxy.hintOption = [];
		proxy.hintOption[0] = '';
		proxy.hintOption[1] = '';
		proxy.hintOption[2] = '';
		proxy.hintOption[3] = '';
		
		proxy.changeOption = [];
		var purgeMsg = $$$Text("After saving the changes, you should purge all of your Cached Queries, and recompile all of your classes and routines that contain Embedded SQL.");
		proxy.changeOption['01'] = $$$Text(". Stats-collection will be included in query code generation. ") + purgeMsg;
		proxy.changeOption['02'] = $$$Text(", enabling Stats-collection from an environment which previously did not include Stats-collection in query code generation. ") + purgeMsg;
		proxy.changeOption['03'] = $$$Text(", enabling Stats-collection from an environment which previously did not include Stats-collection in query code generation. ") + purgeMsg;
		proxy.changeOption['10'] = $$$Text(". Query code generation for Stats-collection will be stopped, but please note, while off, Stats-collection will continue to remain in the query code generation until you purge all of your Cached Queries and recompile all of your classes and routines that contain Embedded SQL.");
		proxy.changeOption['12'] = $$$Text(", enabling Stats-collection from an environment which previously did include Stats-collection in query code generation. Stats will be collected for the Open and Close modules of a query.");
		proxy.changeOption['13'] = $$$Text(", enabling Stats-collection from an environment which previously did include Stats-collection in query code generation. Stats will be collected for all modules of a query.");
		proxy.changeOption['20'] = $$$Text(", disabling Stats-collection functionality entirely. After saving the settings changes, you should purge all of your Cached Queries, as well as recompiling your classes and routines that contain Embedded SQL to remove this functionality entirely.");
		proxy.changeOption['21'] = $$$Text(", disabling Stats-collection, but Stats-collection will still remain in query code generation.");
		proxy.changeOption['23'] = $$$Text(", levels of Stats collected will be changed from Open and Close modules only to all modules.");
		proxy.changeOption['30'] = proxy.changeOption['20'];
		proxy.changeOption['31'] = $$$Text(", stopping Stats-collection, but Stats-collection will still remain in query code generation.");
		proxy.changeOption['32'] = $$$Text(", levels of Stats collected will be changed from all modules to Open and Close modules only.");
		
		if (json.ExpirationDisplay) {
			if (json.Expired) {
				tExpiration = $$$FormatText($$$Text("SQL Runtime Stats collection has expired at %1."),json.ExpirationDisplay)	
			} else {
				tExpiration = $$$FormatText($$$Text("SQL Runtime Stats collection will expire at %1."),json.ExpirationDisplay)		
			}
		}
		tOptionText1 = proxy.option[json.TurnOnStats];
		var tCurrent = $$$Text("The current SQL Runtime Statistics setting is:")
		msg = "<h2>" + tCurrent + "</h2>";
		msg += "<h3>" + tOptionText1 + "</h3>";
		if (tExpiration != "") {
			msg += "<h3>" + tExpiration + "</h3>";
		}
		proxy.msg = msg;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	return proxy
}

ClassMethod CheckJobStatus(PID) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.msg = ""
	// check if background job has errorred
	If $G($$$TempMgtPortalTask(PID,"Status")) = $$$Text("ERROR") {
		Set proxy.status = "error" 
		Set proxy.msg = $G($$$TempMgtPortalTask(PID,"Details"))
	}
	// check if it is finished
	Set Status = $G($$$TempMgtPortalTask(PID,"FinishStatus"))
	// if it has not finished, check if the process has been terminated or suspended
	If Status '= 1 {
		Set tCurrentNS = $ZU(5)
		Set $Namespace = "%SYS"
		Set tPOBJ = ##class(%CSP.UI.Portal.ProcessDetails).GetPIDOBJ(PID)
		If '$IsObject(tPOBJ) {
			Set proxy.status = "terminated"
			Set proxy.msg = $$$FormatText($$$Text("Process '%1' no longer exists"),PID)
		} Else {
			If tPOBJ.CanBeSuspended = 0 {
				Set proxy.status = "suspended"
				Set proxy.msg = $$$FormatText($$$Text("Process '%1' has been suspended."),PID)
			} Else {
				Set proxy.status = "running"
			}
		}
		Set $Namespace = tCurrentNS
	} Else {
		Set proxy.status = "done"
	}
	Quit proxy
}

/// Goto a particular page
ClientMethod gotoPToolsPage(pageId) [ Language = javascript ]
{
	var url = '';
	switch (pageId) {
		case 'sqlhome':
			url = this.SQLHomePage;	
			break;
		case 'runtime':
			var delim = (this.RuntimePage.indexOf('?$NAMESPACE') == -1) ? '?' : '&';
			url = this.RuntimePage + delim + 'openTab=2';
			break;
		case 'indexanalyzer':
			url = this.IndexAnalyzerPage;
			break;

	}
	if (url != '') {
		self.document.location= url;
	}
}

/// show or hide the Clear image for Query Text or Filter
ClientMethod toggleClearText(tControl) [ Language = javascript ]
{
	var flag = tControl.getValue()=="";
	zen("imageClear"+tControl.getProperty("id")).setHidden(flag);
	return true;
}

/// Return json data for SQL page 
ClassMethod GetSQLPageData(Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""
		Set pObject.pTools = ##class(%ListOfObjects).%New()
		Set pMenuObj = ##class(%ZEN.proxyObject).%New()
		Set pMenuObj.menu = "RuntimeStats"
		Set pMenuObj.url = ##class(%CSP.Page).Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.RuntimeStats.zen")
		Do pObject.pTools.Insert(pMenuObj)
		Set pMenuObj = ##class(%ZEN.proxyObject).%New()
		Set pMenuObj.menu = "IndexAnalyzer"
		Set pMenuObj.url = ##class(%CSP.Page).Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.IndexAnalyzer.zen")
		Do pObject.pTools.Insert(pMenuObj)
		Set pMenuObj = ##class(%ZEN.proxyObject).%New()
		Set pMenuObj.menu = "AlternateShowPlan"
		Set pMenuObj.url = ##class(%CSP.Page).Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.ShowPlanAlt.zen")
		Do pObject.pTools.Insert(pMenuObj)
		Set pMenuObj = ##class(%ZEN.proxyObject).%New()
		Set pMenuObj.menu = "ReportGenerator"
		Set pMenuObj.url = ##class(%CSP.Page).Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.ReportGenerator.zen")
		Do pObject.pTools.Insert(pMenuObj)
		Set pMenuObj = ##class(%ZEN.proxyObject).%New()
		Set pMenuObj.menu = "ImportReport"
		Set pMenuObj.url = ##class(%CSP.Page).Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.ReportLoader.zen")
		Do pObject.pTools.Insert(pMenuObj)
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

/// This method returns proxyObject that contains information for the UI
ClassMethod GetIndexAnalyzerProperties(Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""
		Set pObject.reportOptions = ##class(%ListOfObjects).%New()
		/// the following are query names used by the UI that are defined in queryClass %SYS.PTools.UtilSQLAnalysis.
		Set queryList = "indexUsage,tableScans,tempIndices,joinIndices,outlierIndices"
		/// the following are the query name titles displayed by the UI as choice option buttons
		Set queryCaptionList = $$$TextHTML("Index Usage,Queries with Table Scans,Queries with Temp Indices,Queries with Missing JOIN Indices,Queries with Outlier Indices")
		Set option = 1
		While option <= 5 {
			Set tChildObj = ##class(%ZEN.proxyObject).%New()
			Set tChildObj.queryName = $P(queryList,",",option)
			Set tChildObj.caption = $P(queryCaptionList,",",option)
			Do pObject.reportOptions.Insert(tChildObj)
			Set option = option + 1
		}
		Set pObject.msgInprogress = $$$Text("Gathering analytical results. Please wait ...")
		Set pObject.msgDone = $$$Text("Gathering analytical results ... DONE!")
		Set pObject.msgStatementInprogress = $$$Text("Gathering SQL statements. Please wait ...")
		Set pObject.msgStatementDone = $$$Text("Gathering SQL statements ... DONE!")
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

/// Method to job off Show Plan process in the background.
ClassMethod JobShowPlan(query) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tParms("Username") = $Username
	Set tParms("Namespace") = $ZU(5)
	Set tParms("QueryText") = query
	Set tParms("stats") = 1
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("JobShowPlan",$zu(5),.tParms,.tItems,.tJob)
	If $$$ISERR(status) {
		Set tError = $System.Status.GetErrorText(status)
		Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg(tError)
		Set proxy.status = 0
		Set proxy.error = tError
	} Else {
		Set proxy.status = 1
		Set proxy.jobNumber = tJob
		Set proxy.Username = $Username
		Set proxy.msg = $$$TextHTML("Show Plan process started in the background.")
	}
	Quit proxy
}

/// Write upto 40 characters of any field in tablePane
Method DrawUpto40Text(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	
	#; Draw query text upto 40 characters.
	If $G(%query(pName)) '= "" {
		Set tText = $E(%query(pName),1,40) _ $S($L(%query(pName))>40:"...",1:"")
		&html<&nbsp;<span title='#(..EscapeHTML(%query(pName)))#'>#(..EscapeHTML(tText))#<span>>
	}
	Quit $$$OK
}

}
