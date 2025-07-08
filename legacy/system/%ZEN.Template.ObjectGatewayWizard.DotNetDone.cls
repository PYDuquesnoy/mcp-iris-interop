/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Java Gateway Wizard 
Class %ZEN.Template.ObjectGatewayWizard.DotNetDone Extends %ZEN.Template.cspTemplate [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter PAGENAME = ".NET Gateway Wizard Result";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set $ZTRAP = "Trap"
	Set SelectedRows = $G(%session.Data("DotNetGatewayWizard","SelectedRows"))
	Set filename = $G(%session.Data("DotNetGatewayWizard","FileName"))
	Set server = $G(%session.Data("DotNetGatewayWizard","Host"))
	Set port = $G(%session.Data("DotNetGatewayWizard","Port"))
	Set classpaths = $G(%session.Data("DotNetGatewayWizard","Classpaths"))
	Set exclusions = $G(%session.Data("DotNetGatewayWizard","Excludes"))
	Set NAMESPACE = $G(%session.Data("DotNetGatewayWizard","NAMESPACE"))
	If NAMESPACE '= $namespace ZN NAMESPACE
	&html<<html>
	<head>
	<title>#($$$Text(".NET Gateway Wizard Result"))#</title>
	<link rel="stylesheet" type="text/css" href="#(..Link("/csp/sys/intersystems.css"))#">
	
	<style type="text/css">
	.body {
		padding:10px;
		font-family: Verdana, Arial, Helvetica, sans-serif;
	}
	</style>
	</head>
	<body onload="self.focus();">>
	&html<<form style="margin-left:10px;margin-right:10px;padding-top:2px;"><div>#($ZCVT($$$FormatText($$$Text("Prepare to import %1"),filename),"O","HTML"))#:</div>>
	If '##class(%File).Exists(filename) Write !,$$$TextHTML("File does not exist!"),"</form></body></page>" Quit 1
	&html<<hr><div id="PROGRESS" class="PROGRESS">#($$$TextHTML("Connecting..."))#</div>>
	&html<<pre>>
	// Build object for classpaths
	Set paths=##class(%ListOfDataTypes).%New()
	For i=1:1:$length(classpaths,";") {
		Set cp=$piece(classpaths,";",i)
		If cp'="" Do paths.Insert(cp)
	}
	
	// Build object for exclusions
	Kill elist
	Set elist=""
	For i=1:1:$length(exclusions,";") {
		Set ex=$piece(exclusions,";",i)
		If ex'="" {
			If elist="" Set elist=##class(%ListOfDataTypes).%New()
			Do elist.Insert(ex)
		}
	}

	Do paths.Insert(filename)
	If SelectedRows '= "" {
		Set classes = ""
		For i = 1:1:$length(SelectedRows) Set class=$P(SelectedRows,",",i) if class'="" Set classes = classes_$S(classes'="":";",1:"")_class
		Do ..ImportClasses(server, port, classes, paths, elist)
	} Else {
		Do ..ImportClasses(server, port, filename, paths, elist)
	}
		
	Write !,$$$FormatText($$$Text("Finished at %1"),$zdt($h))
	Kill %session.Data("DotNetGatewayWizard","SelectedRows")
	&html<</pre>>
	&html<</form>>
	&html<</body></html>>
	Quit $$$OK
Trap	///
	Set $ztrap=""
	Write $$$Text("Error: "),$ZCVT($ze,"O","HTML"),!
	Quit 1
Done	;
	Quit 1
}

ClassMethod ImportClasses(server, port, name, paths, elist)
{
	Set $ZTRAP = "Trap"
	
	Write "<div class=""CLASSMSG""><span class=""CLASSNAME"">",name,"</span>",!
	Write "<script language=""JavaScript"" type=""text/javascript"">",!
	Write "document.getElementById('PROGRESS').innerHTML='<br>"_$$$Text("Importing....")_"<br><br>';",!
	Write "</"_"script>",!
	Do:$data(%response) %response.Flush()
	Set classes = ##class(%Net.Remote.Gateway).%ExpressImport(name,port,server,,paths,elist)
	If $IsObject(classes) {
		For i=1:1:classes.Count() {
			Write "<br>&nbsp;&nbsp;&nbsp;"_$ZCVT($$$FormatText($$$Text("%1 imported."),classes.GetAt(i)),"O","HTML"),!
			Set %session.Data("DotNetGatewayWizard","ClassList",classes.GetAt(i))=""
		}
	} 
	Write "</div>",!	
	Do:$data(%response) %response.Flush()
	Quit
Trap	///
	Set $ztrap=""
	Write $$$Text("Error: "),$ZCVT($ze,"O","HTML"),!
	Quit
}

}
