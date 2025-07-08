/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the export output of the System Management Portal.
Class %CSP.UI.Portal.Dialog.ImportOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.ImportOutput.zen";

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
		&html<<body><pre>>
		Set Namespace = $G(%request.Data("NAMESPACE",1))
		If Namespace '= "",Namespace '= $namespace Set $Namespace = Namespace
		Set INPUTTYPE = $G(%request.Data("INPUTTYPE",1))
		Set IMPORTTYPE = $G(%request.Data("IMPORTTYPE",1))
		Set RUNBACKGROUND = $G(%request.Data("RUNBACKGROUND",1))
		Set IMPORTALL = +$G(%request.Data("IMPORTALL",1))
		If IMPORTALL = 1 Set RUNBACKGROUND = 1
		Set FILETYPE = $G(%request.Data("FILETYPE",1))
		Set FileName = $G(%request.Data("FILENAME",1))
		If FileName = "" Write !,$$$TextHTML("FileName is empty!"),"</pre>" Quit
		If IMPORTTYPE = "DIR",##class(%File).DirectoryExists(FileName) = 0 {
			Write !,$$$TextHTML("Directory cannot be imported."),"</pre>"
			Quit
		}
		If IMPORTTYPE = "FILE",##class(%File).Exists(FileName) = 0 {
			Write !,$$$TextHTML("File cannot be imported."),"</pre>" 
			Quit
		}
		If IMPORTTYPE = "FILE" {
			set FileNameDirectory = ##class(%File).GetDirectory(FileName)
		} Else {
			set FileNameDirectory = FileName
		}
		If '##class(%CSP.Portal.Utils).IsDirectoryAllowed(FileNameDirectory) {
			Write !,$$$TextHTML("File cannot be imported."),"</pre>" 
			Quit
		}

		Set CompileFlags = $G(%request.Data("COMPILEFLAGS",1))
		Set Recurse = $G(%request.Data("RECURSE",1))
		
		#; Charset is for Globals and Routines only
		Set Charset = $G(%request.Data("CHARSET",1))
		//Set ExtCharset = ""
		//If Charset '= "" Set ExtCharset = $$MapExtCharset^%SYS.NLS(Charset)		
		Set selectedRows = $G(%session.Data($Username,FILETYPE,"selectedRows"))
		Kill tItems
		Set tTotal = 0
		Set tDelimiter = $S(FILETYPE'="Global":",",1:"^")
		Set EventDesc = " Import "_FILETYPE
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
		While tRow '= "" {
			Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)		
			For n = 1:1:$L(selectedRows,tDelimiter) Set tItem = $P(selectedRows,tDelimiter,n) If tItem '= "" Set:FILETYPE="Global" tItem="^"_tItem Set tItems(tItem) = "",tTotal = tTotal + 1
			Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
		}
		Set EventData = "Run in background: "_ RUNBACKGROUND
		If FILETYPE = "Class",IMPORTTYPE="DIR" {
			Set EventData = EventData _ $$$CRLF _ $$$FormatText("Importing All Classes from %1",FileName)
			$$$SMPAuditImport
		} Else {
			Set EventData = EventData _ $$$CRLF _ "Import from: "_FileName_$$$CRLF
			Do $$$PatEventRows(.EventData,.tItems)
			$$$SMPAuditImport		
		}
		If RUNBACKGROUND = 1 {
			Set tParms("NAMESPACE") = Namespace
			Set tParms("Columns") = ""
			Set tParms("TotalColumns") = tTotal
			Set tParms("FileName") = FileName
			Set tParms("qspec") = CompileFlags
			Set tParms("Charset") = Charset
			Set tParms("ImportFormat") = "XML"
			Set tParms("IMPORTTYPE") = IMPORTTYPE
			Set tParms("ImportAll") = $S(IMPORTTYPE="DIR":"LoadDir",1:IMPORTALL)
			Set tParms("Recurse") = Recurse
			Set tParms("ImportLocal") = (INPUTTYPE="LOCAL")
			Set msg1 = $$$TextHTML("This task will be run in the background.")
			Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
			Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
		 	If IMPORTTYPE="DIR"!(IMPORTTYPE="FILE"&&(tTotal>0))!(IMPORTALL) {
			 	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("Import",$namespace,.tParms,.tItems,.tJob)
				If $$$ISERR(status) Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
			 	&html<<p>#(msg1)#<br/><a href="#(linkpage)#">#(msg2)#</a></p>>
		 	}				
		} Else {
			If FILETYPE = "Class" {
				If IMPORTTYPE="DIR" Write $$$FormatText($$$Text("Importing All Classes from %1"),$zconvert(FileName,"O","HTML")),"<br/>"
				Else  Write $$$FormatText($$$Text("Importing Selected Classes from %1"),$zconvert(FileName,"O","HTML")),"<br/>"
			}
			Write !,$$$FormatText($$$Text("Import to Namespace %1."),$namespace)
			Do %response.Flush()
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			If IMPORTTYPE = "DIR" {
				Set tSC = $System.OBJ.LoadDir(FileName,CompileFlags,.err,Recurse)
			} Else {
				Set tSC = $System.OBJ.Load(FileName,CompileFlags,.err,.loadlist,0,.tItems,,Charset)
			}
			Kill EscapeObj
			If $O(err("")) '="" Do ..DrawError(err)
			Do %response.Flush()
			
			If INPUTTYPE="LOCAL" {
				Do ##class(%CSP.UI.System.Utils).DeleteLocalUpload(FileName)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write $System.Status.GetErrorText(tSC)	
	}
	&html<</pre>>
	&html<</body>>
	&html<</html>>
	Quit $$$OK
}

ClassMethod DrawError(err)
{
	Set errno = ""
	For  Set errno = $O(err(errno)) Quit:errno=""  Write $ZCVT(err(errno),"O","HTML"),"<br/>"
}

}
