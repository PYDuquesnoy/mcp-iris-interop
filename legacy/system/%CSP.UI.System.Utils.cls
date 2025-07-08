/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Utility methods used by SMP - mostly by background jobs called from %CSP.UI.System.BackgroundTask.
Class %CSP.UI.System.Utils Extends %RegisteredObject [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Method to Compile in the background (copied from %CSP.UI.System.CompilePane)
ClassMethod Compile(ByRef pParms As %String, ByRef tItems As %String) As %Status
{
#define LogError If $O(err("")) '="" Set HasError=1 Set errno = "" For  Set errno = $O(err(errno)) Quit:errno=""  Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg(err(errno))
#define LogDone  Else  Do ..LogMsg($$$FormatText($$$Text("Completed at %1"),$ZDT($H)),msgDone)
#define LogMsg   If $$$ISERR(tSC) Set HasError=1 Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($System.Status.GetErrorText(tSC))	
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set msgDone = $$$Text("Done")
	Set HasError = 0
	Do {
		Set Flags = $G(pParms("Flags"))_"-d"
		Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
		If pParms("CompileClass") = 1 {
			If pParms("CompileAll") {
				Do $System.OBJ.CompileAll(Flags,.err)
			} Else {
				Do $System.OBJ.CompileList(.tItems,Flags,.err)
			}
			$$$LogError
		} Else {
			Set tName = $O(tItems(""))
			While tName '= "" {
				Set tType =  $ZCVT($E(tName,$L(tName)-2,$L(tName)),"L")
				If tType = "cls" {	// Compile Class
					Do $System.OBJ.Compile($E(tName,1,$L(tName)-4),Flags,.err)
					$$$LogError
				} ElseIf tType = "mac" ! (tType = "int") ! (tType = "bas") ! (tType = "mvb") ! (tType="mvi") {
					#;YSD2501 Set tSC = $$CompileRoutine^%apiRTN(tName,Flags_"k")
						Set tRtnObj = ##class(%RoutineMgr).%OpenId(tName)
						If $IsObject(tRtnObj) {
							Set tSC = tRtnObj.Compile("k")
							$$$LogMsg
						}
				} ElseIf tType = "csp" {
					Set tSC = $System.CSP.LoadPage(tName,Flags)
					$$$LogMsg
				} ElseIf tType = "csr" {
					Set tSC = $System.CSP.LoadRule(tName,Flags)
					$$$LogMsg
				} ElseIf tType = 10 {
					Set tSC = $System.CSP.LoadPageDir(tName,Flags_"k")
					$$$LogMsg
				} ElseIf tType = "pkg" {  		// Compile Package
					Set tSC = $System.OBJ.CompilePackage(tName,Flags_"k",.err)
					$$$LogError
				} Else {
					Set HasError=1
					Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($$$Text("Unknown file extension: ")_tName)
				}
				Set tName = $O(tItems(tName))
			}
		}
		Kill EscapeObj ; To remove the oref and turn off redirection.
		If HasError = 1 Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $$$Text("ERROR")
		Else  $$$LogDone
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Do ..LogMsg($ZE)
	Goto Done
}

/// Method to Export in the background 
ClassMethod Export(FileName As %String, ExportFormat As %String, ByRef pParms As %String, ByRef tItems As %String) As %Status
{
#define LogError If $O(err("")) '="" Set errno = "" For  Set errno = $O(err(errno)) Quit:errno=""  Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg(err(errno),msgError)
#define LogDone  Else  Do ..LogMsg($$$FormatText($$$Text("Completed at %1"),$ZDT($H)),msgDone)
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set msgDone = $$$Text("Done")
	Set msgError = $$$Text("ERROR")
	Do {
		If ExportFormat = "GO" {
			Set tSC = ##class(%Global).Export($namespace, .tItems, FileName, $G(pParms("OutputFormat"),7), $G(pParms("RecordFormat"),"V"), "-d", $G(pParms("Charset")))
			If $$$ISERR(tSC) Do ..LogMsg($System.Status.GetErrorText(tSC))
			$$$LogDone
		} ElseIf ExportFormat = "XML" {
			Do $System.OBJ.Export(.tItems,.FileName,"-d",.err,$G(pParms("Charset")))
			$$$LogError
			$$$LogDone
		} ElseIf ExportFormat = "RO" {
			Do Export^%apiRTN(.tItems,FileName,,$G(pParms("Parameter")),"-d",.err)
			$$$LogError
			$$$LogDone
		}
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Do ..LogMsg($ZE)
	Goto Done
}

/// Method to Import in the background
ClassMethod Import(FileName As %String, ByRef pParms As %String, ByRef tItems As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		If $G(pParms("NAMESPACE")) '= "",pParms("NAMESPACE") '= $namespace Set $Namespace = pParms("NAMESPACE")
		//YSD1368 If $G(pParms("Columns")) '= "" {
		//	For tRow = 1:1:pParms("TotalColumns") Set tItem = $li(pParms("Columns"),tRow) Quit:tItem=""  Set tItems(tItem) = ""
		//}
		Set qspec = pParms("qspec")_"-d"
		Set Charset = $G(pParms("Charset"))
		Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
		If $G(pParms("ImportAll")) = 1 {
			Set tSC = $System.OBJ.Load(FileName,qspec,.err,,,,,Charset)
		} Else {
			If $G(pParms("ImportAll")) = "LoadDir" {
				Set tSC = $System.OBJ.LoadDir(FileName,qspec,.err,1)
			} Else {
				Set Recurse = $S($G(pParms("IMPORTTYPE"))="FILE":0,1:+$G(pParms("Recurse")))
				Set tSC = $System.OBJ.Load(FileName,qspec,.err,.loadlist,Recurse,.tItems,,Charset)
			}
		}
		Kill EscapeObj
		If $$$ISERR(tSC) Do ..LogMsg($System.Status.GetErrorText(tSC))
		Else  Do ..LogMsg($$$FormatText($$$Text("Completed at %1"),$ZDT($H)),$$$Text("Done"))
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Do ..LogMsg($ZE)
	Goto Done
}

/// Log error into ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") and ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
ClassMethod LogMsg(ErrMsg As %String = "", Status As %String = "ERROR")
{
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = $G(^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")) _" " _ ErrMsg
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = Status
}

/// This method will delete the temporary file used when importing data from a file on the user's 
/// local machine. It will only delete files from the system Temp directory. 
ClassMethod DeleteLocalUpload(FileName As %String)
{
	Set tmpName = ##class(%File).NormalizeFilename(##class(%File).GetFilename(FileName),##class(%SYS.System).TempDirectory())
	
	If ##class(%File).Exists(tmpName),'##class(%File).DirectoryExists(tmpName) {
		Do ##class(%File).Delete(tmpName)
	}
}

}
