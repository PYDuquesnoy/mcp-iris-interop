/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages displays the integrity log of the System Management Portal.
Class %CSP.UI.Portal.Dialog.IntegLogContent Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.IntegLogContent.zen";

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

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
		Set tTitle = $$$Text("Integrity Log")
		Set FILENAME = $SYSTEM.Util.ManagerDirectory()_"integ.txt"
		&html<<html><title>#(tTitle)#</title><head></head>
		<link rel="stylesheet" href='#(..Link("/csp/sys/intersystems.css"))#'>>
		&html<<body>>
		&html<<div style="padding:20px;"><pre>>
		If ##class(%File).Exists(FILENAME) = 0 Write $$$Text("File does not exist."),!
	 	Set stream = ##class(%FileCharacterStream).%New()
	 	Set stream.Filename = FILENAME
	 	While 'stream.AtEnd {
	 		Set line = stream.ReadLine()
	 		&html<#($ZCVT(line,"O","HTML"))#>
		}
		&html<</pre></div>
		<br>&nbsp;<br>>
		Kill stream		
		Do %response.Flush()
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
