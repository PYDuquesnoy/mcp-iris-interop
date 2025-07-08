/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the SQL Statement export output of the System Management Portal.
Class %CSP.UI.Portal.SQL.ExportOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.ExportOutput.zen";

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$DevelopmentResourceName,"USE")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		&html<<html><head></head>>
		&html<<body>>

		Set Namespace = $G(%request.Data("NAMESPACE",1))
		If Namespace '= "",Namespace '= $namespace Set $Namespace = Namespace
		#; EXPORTALL = 1  indicates Export 
		#; EXPORTALL = -1 indicates Import
		Set EXPORTALL = +$G(%request.Data("EXPORTALL",1))
		Set RUNBACKGROUND = $G(%request.Data("RUNBACKGROUND",1))
		Set FileName = $G(%request.Data("FILENAME",1))
		Set:($E(FileName,*) = ".") FileName = FileName_"xml"
		Set Hash = $G(%request.Data("HASH",1))
		Set DownloadFile = $G(%request.Data("DOWNLOADNAME",1))
		Set:($E(DownloadFile,*) = ".") DownloadFile = DownloadFile_"xml"
		If EXPORTALL = 1 {
			Set EventData = "Export to: "_FileName_$$$CRLF_"Export All SQL Statements from "_Namespace
		} Else {
			Set EventData = "Export to: "_FileName_$$$CRLF_"Export SQL Statement from "_Namespace			
		}
		Set EventDesc = " " _ $Case(EXPORTALL, 1:"Export", :"Import")_" "_$G(%request.Data("FILETYPE",1))
		Set EventData = EventData _ $$$CRLF _ "Run in background: "_ RUNBACKGROUND
		$$$SMPAuditExport
		If RUNBACKGROUND = 1 {
			Set tParms("FileName") = FileName
			Set tParms("ExportAll") = EXPORTALL
			Set tParms("Hash") = Hash
			Set msg1 = $$$TextHTML("Export started in the background.")				
			Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
			Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
			Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("SQLExportStatement",$namespace,.tParms,.tItems,.tJob)
			If $$$ISERR(status) {
				Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
			}
			&html<<p>#(msg1)#<br/><a href="#(linkpage)#">#(msg2)#</a></p>>
		} Else {
			#; this is for exporting a single SQL statement only
			Set Hash = $G(%request.Data("HASH",1))
			Write $$$FormatText($$$Text("Exporting statement %1 from %2"),..EscapeHTML(Hash),..EscapeHTML(Namespace)),"<br/>"
			Do %response.Flush()
			&html<<pre>>
			Write !,$$$TextHTML("Export to file: "),$Select(""'=DownloadFile:$zconvert(DownloadFile,"O","HTML"),1:$zconvert(FileName,"O","HTML"))
			If $ZCVT($E(FileName,*-3,*),"l") '= ".xml" Set FileName = FileName _ ".xml"
			
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			If EXPORTALL = 1 {
				Set tSC = $System.SQL.ExportAllSQLStatements(FileName)
			} Else {
				Set tSC = $SYSTEM.SQL.ExportSQLStatement(FileName, Hash)
			}
			Kill EscapeObj
			
			If $$$ISERR(tSC) {
				Write !,$zconvert($System.Status.GetErrorText(tSC),"O","HTML")
			} Else {
				Write !!,$$$FormatText($$$Text("Completed at %1"),$ZDT($h,3))
			}
			&html<</pre>>
			Do %response.Flush()
		}
		&html<</body>>
		&html<</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write $System.Status.GetErrorText(tSC)	
	}
	Quit $$$OK
}

}
