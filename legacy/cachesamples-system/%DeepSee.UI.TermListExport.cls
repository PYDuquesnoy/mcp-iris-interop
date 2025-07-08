/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %ZEN.Utils)

/// DeepSee term list export page.
/// This writes out a term list in CSV format.
Class %DeepSee.UI.TermListExport Extends %CSP.Page [ System = 4 ]
{

Parameter PAGENAME = "TermListExport";

Parameter CONTENTTYPE = "text/plain";

/// Required for IE!
Parameter EXPIRES;

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If ('$System.Security.Check("%DeepSee_Portal","USE")) {
		Quit 0
	}

	#; Avoid IE HTTP 1.1 bugs with plugins
	If (%request.UserAgent["MSIE") {
		Set %response.HTTPVersion = "HTTP/1.0"
		If (%request.Secure) {
			#; work-around IE HTTPS bug
			Do %response.SetHeader("Cache-Control","private")
		}
	}

	// + WAL044 -- force download so we know user gets a UTF8 file
	Set tTermListName = %request.Get("TERMLIST")
	Set tContentDisposition = "attachment;filename=" _ $S($G(tTermListName)'="":""""_tTermListName,1:"""TermList") _ ".txt"""  // WAL056 -- add quotes around termlist name
	Do %response.SetHeader("Content-Disposition",tContentDisposition)
	// - WAL044
	
	Quit 1
}

ClassMethod OnPage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tName = %request.Get("TERMLIST")
		If (tName = "") {
			Write $$$Text("Nothing to do!","%DeepSee")
		}
		Else {
			If (##class(%DeepSee.TermList).%TermListExists(tName)) {
				// + WAL044 -- don't UTF8 encode; page CHARSET already does
				Set tSC = ##class(%DeepSee.TermList).%ExportCSV(tName,,0)
				// - WAL044
			}
			Else {
				Write $$$Text("Term list is not defined: ","%DeepSee"),$ZCVT(tName,"O","HTML"),!
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
