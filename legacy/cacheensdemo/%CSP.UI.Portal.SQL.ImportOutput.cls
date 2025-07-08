/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the SQL Statement import output of the System Management Portal.
Class %CSP.UI.Portal.SQL.ImportOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.ImportOutput.zen";

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
		Set RUNBACKGROUND = $G(%request.Data("RUNBACKGROUND",1))
		Set FileName = $G(%request.Data("FILENAME",1))
		Set:($E(FileName,*) = ".") FileName = FileName_"xml"
		If '##class(%File).Exists(FileName) {
			&html<<p>#($$$Text("File does not exist."))#</p>>
			Quit
		}
		//Set DownloadFile = $G(%request.Data("DOWNLOADNAME",1))
		//Set:($E(DownloadFile,*) = ".") DownloadFile = DownloadFile_"xml"
		Set EventDesc = "Import SQL Statements"
		Set EventData = "Import from: "_FileName_$$$CRLF_"Import SQL Statements to "_Namespace		
		Set EventData = EventData _ $$$CRLF _ "Run in background: "_ RUNBACKGROUND
		$$$SMPAuditExport
		If RUNBACKGROUND = 1 {
			Set tParms("FileName") = FileName
			Set tParms("ImportLocal") = ($G(%request.Data("INPUTTYPE",1))="LOCAL")
			Set msg1 = $$$TextHTML("Import started in the background.")		
			Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
			Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
			Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("SQLImportStatement",$namespace,.tParms,.tItems,.tJob)
			If $$$ISERR(status) {
				Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
			}
			&html<<p>#(msg1)#<br/><a href="#(linkpage)#">#(msg2)#</a></p>>
		} Else {
			Write $$$FormatText($$$Text("Importing statement to %1"),..EscapeHTML(Namespace)),"<br/>"
			Do %response.Flush()
			&html<<pre>>
			Write !,..EscapeHTML(FileName)
			If (($G(%request.Data("INPUTTYPE"))="REMOTE") && ($ZCVT($E(FileName,*-3,*),"l") '= ".xml")) {
				Set FileName = FileName _ ".xml"
			}
			
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			Set tSC = $SYSTEM.SQL.ImportSQLStatement(FileName)
			Kill EscapeObj
			
			If $$$ISERR(tSC) {
				Write !,$zconvert($System.Status.GetErrorText(tSC),"O","HTML")
			} Else {
				Write !!,$$$FormatText($$$Text("Completed at %1"),$ZDT($h,3))
			}
			If $G(%request.Data("INPUTTYPE",1))="LOCAL" {
				Do ##class(%CSP.UI.System.Utils).DeleteLocalUpload(FileName)
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
