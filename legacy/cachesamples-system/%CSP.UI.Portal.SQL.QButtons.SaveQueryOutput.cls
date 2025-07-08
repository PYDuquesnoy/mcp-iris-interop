/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the SQL SaveQuery output when the process is run in the background.
Class %CSP.UI.Portal.SQL.QButtons.SaveQueryOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.SaveQueryOutput.zen";

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
		&html<<html>>
		Do ..DrawHEAD()
		&html<<body>>
		Set Namespace = $G(%request.Data("namespace",1))
		If Namespace '= "",Namespace '= $ZU(5) {
			Set $Namespace = Namespace
		}
		Set tJobNumber = $G(%request.Data("jobNumber",1))
		Set tStatus = $G(%request.Data("status",1))
		Set tMsg = $G(%request.Data("msg",1))
		If (tStatus = "error") {
			If ($G($$$TempMgtPortalTask(tJobNumber,"Status")) = $$$Text("ERROR")) {
				Set err = $$$TextHTML("ERROR: ")_..EscapeHTML($$$TempMgtPortalTask(tJobNumber,"Details"))
			} Else {
				Set err = $$$Text("Unspecified error")	
			}
			&html<<div class="errorNote">#(err)#</div>>
		} Else {
			If tJobNumber '= "" {
				If ((tStatus = "error") || (tStatus = "terminated") || (tStatus = "suspended")) {
					&html<<div class="errorNote">#($zconvert(tMsg,"O","HTML"))#</div>>	
				} Else {
					&html<<p class="note">#($$$FormatTextHTML($$$Text("Save Query job %1 is running ... please wait!"),tJobNumber))#</p>>	
					&html<<progress ></progress>>
				}
			} Else {
				&html<<p class="note">#($$$TextHTML("Save Query job is started ... please wait!"))#</p>>
				&html<<progress ></progress>>
			}
		}
		Do %response.Flush()
		&html<</body>>
		&html<</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write $zconvert($System.Status.GetErrorText(tSC),"O","HTML")
	}

	Quit $$$OK
}

ClassMethod DrawHEAD()
{
	&html<<head><title></title>
	<style type="text/css">
	.errorNote {
		background: #F2F1EC;
		border: 1px solid #da4848;
		border-radius: 5px;
		color: #da4848;
		font-family: Futura,Arial,sans-serif;
		font-size: 12px;
		font-weight: bold;
		padding: 10px;
		text-align: left;
		display:inline-block;
	}
	</style>
	>
}

}
