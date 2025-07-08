/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// Display resource profile.
Class %CSP.UI.System.ResourceProfile Extends %CSP.Page [ System = 4 ]
{

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Ensure user has %Admin_Secure:USE.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$AdminSecureResourceName,"USE")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		Set namespace = "%SYS"
		Set resource = $G(%request.Data("RESOURCE",1))
		Set msgServer = $$$TextHTML("Name of the machine this system is running on")
		Set msgInstance = $$$TextHTML("Configuration name of this system")
		Set ServerName = $zu(110)
		Set InstanceName = $P($zu(86),"*",2)
		Set cmdResource = $$$TextHTML("Resource Profile")
		Set cmdServer = $$$TextHTML("Server")
		Set cmdInstance = $$$TextHTML("Instance")
		Set cmdNamespace = $$$TextHTML("Namespace")
	 	If namespace '= "",namespace'=$namespace Set $Namespace = namespace
	 	Set lblRoles = $$$TextHTML("Roles")
	 	Set lblDatabases = $$$TextHTML("Databases")
	 	Set lblApplications = $$$TextHTML("Applications")
	 	Set lblDescription = $$$TextHTML("Description")
	 	Set lblPermission = $$$TextHTML("Public Permission")
	 	Set lblType = $$$TextHTML("Type")
	 	Set lblNone = "("_$$$TextHTML("none")_")"
	 	Set lblNotInUse = $$$TextHTML("Resource is not specified by any role, database, or application.")
		Set FILETYPE = "Resource"
		Write "<html><head><title>",$$$TextHTML("View Resource Profile"),"</title>"
		&html<<link rel="stylesheet" href='#(..Link("/csp/sys/intersystems.css"))#'>>
		Do ..DrawStyle()
		Do ##class(%CSP.Util.AutoPage).DrawAutoLogout()
		&html<</head>>
		&html<<body bgcolor="#FFFFFF" text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">>
	 	&html<<table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
		<tr class="portalTitle">
		<td nowrap><span style="padding:5px;font-weight:bold;">#(cmdResource)#</span></td>
		<td title="#(msgServer)#" nowrap><span style="padding:5px;">#($zcvt(cmdServer,"O","HTML"))#:</span><b>#(ServerName)#</b></td>
		<td title="#(msgInstance)#" nowrap><span style="padding:5px;">#(cmdInstance)#:</span><b>#(InstanceName)#</b></td>
		<td nowrap><span style="padding:5px;">#(cmdNamespace)#:</span><b>#($ZCVT(namespace,"O","HTML"))#</b></td>
		</tr>
		</table>>

	 	Do ..RenderPrinter()
	 	Set tTotal = 0
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
		While tRow '= "" {
			Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)		
			For n = 1:1:$L(selectedRows,",") Set tItem = $P(selectedRows,",",n) If tItem '= "" Set tItems(tItem) = "",tTotal = tTotal + 1
			Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
		}
		&html<<table class="InfoTable">>
		Set tTitle = $S(tTotal>1:$$$Text("Profile for %1 Resources"),1:$$$Text("Profile for %1 Resource"))
		&html<<tr><th colspan="6" class="title" height="30">#($$$FormatText(tTitle,tTotal))#</th></tr>>
		Do %response.Flush()
	 	Set resource = $O(tItems(""))
	 	While resource '= "" {
		 	Kill InUse,Roles,Databases,App
		 	&html<<tr><td class="label">#(..EscapeHTML(resource))#</td>>
		 	Set tSC = ##Class(Security.Resources).InUse(resource,.InUse,.Roles,.Databases,.App)
		 	If $$$ISERR(tSC) {
			 	Do ..DrawError(tSC)
			 	&html<</tr>>
		 	} Else {
			 	Set Exists = ##class(Security.Resources).Exists(resource,.SYSOBJ,.status)
			 	If $$$ISERR(status) { 
					 Do ..DrawError(status)
			 	}
			 	Else {
				 	Set PublicPermission = $S(SYSOBJ.PublicPermission'=0:..EscapeHTML(SYSOBJ.PublicPermissionLogicalToDisplay(SYSOBJ.PublicPermission)),1:lblNone)
				 	Set Type = SYSOBJ.TypeLogicalToDisplay(SYSOBJ.Type)
				 	&html<<td colspan="4"><div>#(lblDescription)#: #(..EscapeHTML(SYSOBJ.Description))#</div>
				 	<div>#(lblType)#: #(Type)#</div><div>#(lblPermission)#: #(PublicPermission)#</div>
				 	>
				 	If 'InUse &html<#(lblNotInUse)#</td></tr>>
				 	If InUse {
				 	    &html<<br><table class="InuseTable"><th>#(lblRoles)#</th><th>#(lblDatabases)#</th><th>#(lblApplications)#</th></tr>>
				 	    &html<<tr><td valign="top">>
				 	    For i=1:1 Quit:$lg(Roles,i)=""  Write $zconvert($lg(Roles,i),"O","HTML"), "<br/>"
				 	    If i = 1 Write "&nbsp;"
				 	    &html<</td><td valign="top">>
				 	    For i=1:1 Quit:$lg(Databases,i)=""  Write $zconvert($lg(Databases,i),"O","HTML"), "<br/>"
				 	    //If i = 1 Write "&nbsp;"
				 	    &html<</td><td class="right" valign="top">>
				 	    For i=1:1 Quit:$lg(App,i)=""  Write $zconvert($lg(App,i),"O","HTML"), "<br/>"
				 	    If i = 1 Write "&nbsp;"
				 	    &html<</td></tr></table></td></tr>>
				 	}
			 	}
		 	}
		 	Set resource = $O(tItems(resource))
	 	}
	 	&html<</table><p>&nbsp;</p>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write "Unexpected Error: "_tSC
	}
	Write "</body></html>"
	Do %response.Flush()
	Quit $$$OK
}

ClassMethod DrawError(status)
{
	&html<<td colspan="4" class="ErrorBox">#($zconvert($System.Status.GetErrorText(status),"O","HTML"))#</td>>
}

ClassMethod DrawStyle()
{
	&html<<style type="text/css">
	
table.InfoTable	{ 
	margin-left: 40px;
	background: #F1F0EB;
}
table.InfoTable th.title { 
	text-align: center;
}
table.InfoTable td.label {
	border-right: gray solid 1px;
	padding-top: 5px;
	padding-bottom: 5px;
	font-size: 14px;
	font-weight: bold;
}
table.InuseTable	{ 
	border: 1px #888888 solid;
	font-size: 12px;
	margin-left: 2px; 
	margin-right:2px;
	width: 100%;
}
table.InuseTable td {
	background: white;
	border-bottom: gray solid 0px; 
	border-right: gray solid 1px;
}
table.InuseTable td.right {
	border-right: gray solid 0px;
}
</style>>
}

/// Display Printer link
ClassMethod RenderPrinter() [ Private ]
{
	Set tPrintImage = ..Link("/csp/broker/deepsee/printer_24.png")
	Set tPrintTitle = $$$TextHTML("Print")
	&html<<div align="right" valign="moddle" style="margin-right:8px;">
	<a href="javascript:window.print();" title="#(tPrintTitle)#" target="_top" style="pointer-events:auto;cursor:pointer;">
	<img src="#(tPrintImage)#" width="24" height="24" border="0"></a></div>>
}

}
