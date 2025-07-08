/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Java Gateway Wizard 
Class %ZEN.Template.ObjectGatewayWizard.JavaDone Extends %ZEN.Template.cspTemplate [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter PAGENAME = "Java Gateway Wizard Result";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set $ZTRAP = "Trap"
	Set SelectedRows = $G(%session.Data("JavaGatewayWizard","SelectedRows"))
	Set type = $G(%session.Data("JavaGatewayWizard","FileType"))
	Set filename = $G(%session.Data("JavaGatewayWizard","FileName",type))
	Set server = $G(%session.Data("JavaGatewayWizard","Host"))
	Set port = $G(%session.Data("JavaGatewayWizard","Port"))
	Set classpaths = $G(%session.Data("JavaGatewayWizard","Classpaths"))
	Set exclusions = $G(%session.Data("JavaGatewayWizard","Excludes"))
	Set NAMESPACE = $G(%session.Data("JavaGatewayWizard","NAMESPACE"))
	If NAMESPACE '= $namespace ZN NAMESPACE
	&html<<html>
	<head>
	<title>#($$$Text("Java Gateway Wizard Result"))#</title>
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

	If type="j" {
		Do paths.Insert(filename)
		If SelectedRows '= "" {
			Set classes = ""
			For i = 1:1:$length(SelectedRows) Set class=$P(SelectedRows,",",i) if class'="" Set classes = classes_$S(classes'="":";",1:"")_class
			Do ..ImportClasses(server, port, classes,"class", paths, elist)
		} Else {
			Do ..ImportClasses(server, port, filename,"jar", paths, elist)
		}
	} ElseIf type="c" {
		// Do not pass ".class" as file name
		// Set file path only into paths
		Set classname = ##class(%File).GetFilename(filename)
		Set tRS = ##class(%ResultSet).%New("%File:ParseDirectory")
		Do tRS.Execute(filename)
		Set tDir = ""
		For  Quit:'tRS.Next()  Set tDir = tRS.Data("Directory")
		If tDir '= "" Do paths.Insert(tDir)
		Do ..ImportClasses(server, port, $P(classname,".class",1),"class",paths,elist)
	} Else {
		Write $$$Text("Internal Error: Bad Type = ")_type,!
	}
		
	Write !,$$$FormatText($$$Text("Finished at %1"),$zdt($h))
	Kill %session.Data("JavaGatewayWizard","SelectedRows")
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

/// Draw HTML for the page title
ClassMethod DrawTitle(pSeed As %String) As %Status
{
	Set pSeed = $$$Text("Activate Wizard Result")
	Do ##class(%Activate.UI.Wizard).DrawTitle(pSeed)
	Quit $$$OK
}

ClassMethod ImportClasses(server, port, name, type, paths, elist)
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
			Set %session.Data("JavaGatewayWizard","ClassList",classes.GetAt(i))=""
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
