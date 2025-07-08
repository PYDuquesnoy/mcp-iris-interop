/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the export output of the System Management Portal.
Class %CSP.UI.Portal.Dialog.ExportOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.ExportOutput.zen";

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
		Set EXPORTALL = +$G(%request.Data("EXPORTALL",1))
		Set EXPORTFORMAT = $G(%request.Data("EXPORTFORMAT",1))
		Set RUNBACKGROUND = $G(%request.Data("RUNBACKGROUND",1))
		Set FILETYPE = $G(%request.Data("FILETYPE",1))
		Set FileName = $G(%request.Data("FILENAME",1))
		Set:($E(FileName,*) = ".") FileName = FileName_"xml"
		Set DownloadFile = $G(%request.Data("DOWNLOADNAME",1))
		Set:($E(DownloadFile,*) = ".") DownloadFile = DownloadFile_"xml"

		#; for Charset:
		Set Charset = $G(%request.Data("CHARSET",1))
		Set ExtCharset = ""
		If Charset '= "" Set ExtCharset = $$MapExtCharset^%SYS.NLS(Charset)		

		#; for Global export:
		Set OutputFormat = $G(%request.Data("OutputFormat",1),7)
		Set RecordFormat = $G(%request.Data("RecordFormat",1),"V")

		#; Build items in selectedRows into tItem array
		Kill tItems
		Set tTotal = 0
		Set tDelimiter = $S(FILETYPE'="Global":",",1:"^")
		Set EventDesc = " Export "_FILETYPE
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
		While tRow '= "" {
			Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)		
			For n = 1:1:$L(selectedRows,tDelimiter) Set tItem = $P(selectedRows,tDelimiter,n) If tItem '= "" Set tItems(tItem) = "",tTotal = tTotal + 1
			Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
		}
		Set EventData = "Export to: "_FileName_$$$CRLF
		If EXPORTALL = 1 {
			Set EventData = EventData_$$$FormatText("Exporting All Classes in %1",$namespace)
		} Else {
			Do $$$PatEventRows(.EventData,.tItems)
		}
		Set EventData = EventData _ $$$CRLF _ "Run in background: "_ RUNBACKGROUND
		$$$SMPAuditExport
		If EXPORTFORMAT = "RO" {
			Set Parameter = "WNS" 
			If Charset '= "" Set Parameter = "WNSk\"_Charset_"\"
			Set tParms("Parameter") = Parameter
		}
		If RUNBACKGROUND = 1 {
			Set tParms("TotalColumns") = tTotal
			Set tParms("FileName") = FileName
			Set tParms("Charset") = ExtCharset
			Set tParms("ExportFormat") = EXPORTFORMAT
			Set tParms("ExportAll") = EXPORTALL
			Set tParms("OutputFormat") = OutputFormat
			Set tParms("RecordFormat") = RecordFormat
			Set msg1 = $$$TextHTML("Export started in the background.")
			Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
			Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
		 	If EXPORTALL!('EXPORTALL&&(tTotal>0)) {
			 	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("Export",$namespace,.tParms,.tItems,.tJob)
				If $$$ISERR(status) Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
			 	&html<<p>#(msg1)#<br/><a href="#(linkpage)#">#(msg2)#</a></p>>
		 	}				
		} Else {
			If EXPORTALL = 1 Write $$$FormatText($$$Text("Exporting All Classes in %1"),$zconvert($namespace,"O","HTML")),"<br/>"
			Else  Write $$$FormatText($$$Text("Exporting Selected Items in %1"),$zconvert($namespace,"O","HTML")),"<br/>"
			Do %response.Flush()
			&html<<pre>>
			Write !,$$$TextHTML("Export to file: "),$Select(""'=DownloadFile:$zconvert(DownloadFile,"O","HTML"),1:$zconvert(FileName,"O","HTML"))
			#; EXPORTFORMAT could be XML when export OBJ code is checked
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			If EXPORTFORMAT = "XML" {
				If $ZCVT($E(FileName,*-3,*),"l") '= ".xml" Set FileName = FileName _ ".xml"
				If EXPORTALL = 1,FILETYPE="Class" {
					Do $System.OBJ.ExportAllClasses(.FileName,,.err,ExtCharset)
				} Else {
					Do $System.OBJ.Export(.tItems,.FileName,,.err,ExtCharset)
				}
				Write !!,$$$FormatText($$$Text("Completed at %1"),$ZDT($h,3))
			} ElseIf EXPORTFORMAT = "RO" {
					Do Export^%apiRTN(.tItems,FileName,,Parameter,,.err)
					Write !!,$$$FormatText($$$Text("Completed at %1"),$ZDT($h,3))
			} Else {
				Write !,$$$TextHTML("Output Format: "),$S(OutputFormat=5:$$$Text("Sequential file"),1:$$$Text("Block format"))
				Write !,$$$TextHTML("Record Format: "),$S(RecordFormat="V":$$$Text("Variable Length Records"),1:$$$Text("Stream Data"))
				Write !,$$$TextHTML("Character Set: "),$S(Charset="":$$$TextHTML("Device Default"),1:$zconvert(Charset,"O","HTML"))
				Set Skipped = 0
				Set tSC = ##class(%Global).Export($namespace, .tItems, FileName, OutputFormat, RecordFormat, "d", Charset, .Skipped)
				If $$$ISERR(tSC) Write !,$System.Status.GetErrorText(tSC)
				If $O(Skipped(0)) '= "" {
					Write !,$$$TextHTML("The following mapped globals are skipped for the export"),":"
					Set skipped = 0
					For  Set skipped = $O(Skipped(skipped)) Quit:skipped=""  Write !,$zconvert(skipped,"O","HTML"),". ^",$ZCVT(Skipped(skipped),"O","HTML")
				}
				If $$$ISOK(tSC)  Write !!,$$$FormatText($$$Text("Completed at %1"),$ZDT($h,3))
			}
			Kill EscapeObj ; To remove the oref and turn off redirection.
			If $O(err("")) '="" Do ..DrawError(err)
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

ClassMethod DrawError(err)
{
	Set errno = ""
	For  Set errno = $O(err(errno)) Quit:errno=""  Write $ZCVT(err(errno),"O","HTML"),"<br/>"
}

}
