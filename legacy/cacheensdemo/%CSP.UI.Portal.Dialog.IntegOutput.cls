/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %sySystem)

/// This pages shows the integrity output of the System Management Portal.
Class %CSP.UI.Portal.Dialog.IntegOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.IntegOutput.zen";

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

Parameter PRIVATE = 1;

/// Ensure user has %Admin_Operate:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$AdminOperateResourceName,"USE")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		&html<<html><head></head>>
		&html<<body>>
		Set FILETYPE = "Integ"
		Set FILENAME = $SYSTEM.Util.ManagerDirectory()_"integ.txt"
		Set STOPAFTERERROR = +$G(%request.Data("STOPAFTERERROR",1))
		Set GLOBALLIST = +$G(%request.Data("GLOBALLIST",1))
		Set $$$IRISTempMgt($Username,"Integ","FILENAME") = FILENAME
		#; Build items in selectedRows into CheckList^Integrity required $List format.
		Set (tDirList,tGlbList,tListOfGloList) = ""
		Set tTotal = 0
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
		While tRow '= "" {
			Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)		
			For n = 1:1:$L(selectedRows,",") Set tItem = $P(selectedRows,",",n) If tItem '= "" Set tDirList = tDirList_$lb(tItem),tTotal = tTotal + 1
			Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
		}
		If GLOBALLIST = 1 {
			#; Build global names into CheckList^Integrity required $List of $List format.
			Set tRow = $O(%session.Data($Username,"IntegGlobals","selectedRows",""))
			While tRow '= "" {
				Set selectedRows = %session.Data($Username,"IntegGlobals","selectedRows",tRow)
				For n = 1:1:$L(selectedRows,",") Set tItem = $P(selectedRows,",",n) If tItem '= "" Set tGlbList = tGlbList_$lb(tItem)
				Set tRow = $O(%session.Data($Username,"IntegGlobals","selectedRows",tRow))
			}
			#; Only one database is allowed to select global names, therefore we are only build the first $list.
			If tGlbList '= "" Set tListOfGloList = $lb(tGlbList)
		}
		Set tTotalDatabases = +$G(%session.Data($Username,FILETYPE,"TotalSelected"))
		Set tParms("TotalColumns") = tTotal
		Set tParms("FILENAME") = FILENAME
		#; Output Global will be set and cleaned up in DatabaseIntegrityCheck (%CSP.UI.System.BackgroundTask).RunTask & ^Integrity)
		Set tParms("OUTPUTGLO") = ""
		Set tParms("STOPAFTERERROR") = STOPAFTERERROR
		Set tParms("DirList") = tDirList
		Set tParms("ListOfGloList") = tListOfGloList
		Set tParms("TotalDatabases") = tTotalDatabases
	 	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("DatabaseIntegrityCheck",$namespace,.tParms,,.tJob)
		&html<<pre>>
		Set tTitle = $S(tTotalDatabases>1:$$$Text("Integrity check for %1 databases"),1:$$$Text("Integrity check for %1 database"))
		Write $$$FormatText(tTitle,$zconvert(tTotalDatabases,"O","HTML")),!
		If $$$ISERR(status) Write $zcvt($System.Status.GetErrorText(status),"O","HTML"),!
		Else  Write $$$Text("Background job id: ")_tJob
		Set msg2 = $$$TextHTML("Click here for a quick view of the background task.")
		Set linkpage = $P(##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls"),"$NAMESPACE",1)_"?ID="_tJob
		&html<<p><a href="#(linkpage)#">#(msg2)#</a></p>>
		&html<</pre>>
		Do %response.Flush()
		&html<</body>>
		&html<</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write $zcvt($System.Status.GetErrorText(tSC),"O","HTML")
	}

	Quit $$$OK
}

ClassMethod DrawError(err)
{
	Set errno = ""
	For  Set errno = $O(err(errno)) Quit:errno=""  Write $ZCVT(err(errno),"O","HTML"),"<br/>"
}

}
