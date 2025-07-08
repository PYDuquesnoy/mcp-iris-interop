/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// Display routine code.
Class %CSP.UI.System.ViewCode Extends %CSP.Page [ System = 4 ]
{

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE.
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
		Set namespace = $G(%request.Data("$NAMESPACE",1))
		Set filename = $G(%request.Data("FILENAME",1))
		Set msgServer = $$$TextHTML("Name of the machine this system is running on")
		Set msgInstance = $$$TextHTML("Configuration name of this system")
		Set ServerName = $zu(110)
		Set InstanceName = $P($zu(86),"*",2)
		Set cmdRoutine = $$$TextHTML("Routine")
		Set cmdServer = $$$TextHTML("Server")
		Set cmdInstance = $$$TextHTML("Instance")
		Set cmdNamespace = $$$TextHTML("Namespace")
	 	If namespace '= "",namespace'=$namespace Set $Namespace = namespace
		Set EventDesc = "Routine - View Code"
		Set EventData = "Routine: "_filename
		$$$SMPAuditView

		Write "<html><head><title>",$$$TextHTML("View Code")," - ",$zcvt(filename,"O","HTML"),"</title>"
		&html<<head><link rel="stylesheet" href='#(..Link("/csp/sys/intersystems.css"))#'></head>>
		&html<<body bgcolor="#FFFFFF" text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">>
	 	&html<<table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
		<tr class="portalTitle">
		<td nowrap><span style="padding:5px;">#(cmdRoutine)#:</span><b>#($zcvt(filename,"O","HTML"))#</b></td>
		<td title="#(msgServer)#" nowrap><span style="padding:5px;">#($zcvt(cmdServer,"O","HTML"))#:</span><b>#($zcvt(ServerName,"O","HTML"))#</b></td>
		<td title="#(msgInstance)#" nowrap><span style="padding:5px;">#(cmdInstance)#:</span><b>#($zcvt(InstanceName,"O","HTML"))#</b></td>
		<td nowrap><span style="padding:5px;">#(cmdNamespace)#:</span><b>#($ZCVT(namespace,"O","HTML"))#</b></td>
		</tr>
		</table>>

	 	Do ..RenderPrinter()
	 	If ##class(%RoutineMgr).Exists(filename) {
		 	Set stream = ##class(%RoutineMgr).%New(filename)
			 If '$IsObject(stream) {
			 	&html<<div class="ErrorBox">#($$$FormatText($$$Text("Cannot open %1"),$zconvert(filename,"O","HTML")))#</div>>		
		 	} Else {
		 		&html<<div style="padding:10px;"><pre>>
	 			While 'stream.Code.AtEnd {
					Write $ZCVT(stream.Code.Read(10000),"O","HTML")
	 			}
				&html<</pre>
				<br><div class="normal">[#($$$TextHTML("End of Routine"))#]</div><br></div>>
				Kill stream	
		 	}
		 } Else {
			Write $$$TextHTML("File does not exists!")
		 }
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write "Unexpected Error: "_tSC
	}
	Write "</body></html>"
	Do %response.Flush()
	Quit $$$OK
}

/// Display Printer link
ClassMethod RenderPrinter() [ Private ]
{
	Set tPrintImage = ..Link("/csp/broker/deepsee/printer_24.png")
	Set tPrintTitle = $$$TextHTML("Print")
	&html<<div align="right" valign="middle" style="margin-right:8px;">
	<a href="javascript:window.print();" title="#(tPrintTitle)#" target="_top" style="pointer-events:auto;cursor:pointer;">
	<img src="#(tPrintImage)#" width="24" height="24" border="0"></a></div>>
}

}
