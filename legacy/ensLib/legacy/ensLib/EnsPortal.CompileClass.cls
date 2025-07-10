/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.CompileClass Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tClass = $get(%request.Data("CLASS",1))
	Set tType = $get(%request.Data("TYPE",1))
	Set tPermitted = ..CheckPermissions(tClass, tType)
	&html<<html>
<head>
<style type="text/css">
body {
	font-family: "courier new";
	font-size: 0.8em;
}
.compilerOutput {
	background: white;
	margin: 0px;
	padding: 4px;
	white-space: pre-wrap;
}
</style>
<body>>
	If 'tPermitted {
		&html<<span class="notPermittedErr">#($$$TextHTML("You are not permitted to perform this action.")_"&nbsp;"_$$$TextHTML("Contact your system administrator for access."))#</span>>
	}
	Else {
		Set tExists = ..CheckExists(tClass, tType)
		If 'tExists {
			Set tNotExistsError = $system.Status.GetErrorText($$$ERROR($$$ClassDoesNotExist, tClass))
			&html<<span class="notExistsErr">#($zconvert(tNotExistsError, "O", "HTML"))#</span>>
		}
		Else {
			&html<<div class="compilerOutput">>
			New %SourceControl
			Set tSC = ##class(Ens.Util.SourceControl).CreateSourceControl(.tSourceControl,.tCreated)
			If $$$ISOK(tSC) && $get(tCreated) {
				Set %SourceControl = tSourceControl
			}

			// HTML Escape the output from $System.OBJ.Load()
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			Do $system.OBJ.Compile(tClass,"k")
			Kill EscapeObj // disable HTML Escaping
			
			&html<</div>>
		}
	}
	&html<</body>>
	
	Write ..%StartScript()
	&js<

	setTimeout(function() {
		try {
			parent.document.getElementById('btnOK').getElementsByTagName('input')[0].focus();
		} catch (err) {}
	}, 100);

	>
	Write ..%EndScript()
	Quit $$$OK
}

ClassMethod CheckPermissions(pClass As %String = "", pType As %String = "") As %Boolean
{
	If pClass = "" Quit 0
	If $case(pType, "BPL": 0, "DTL": 0, "RecordMap": 0, :1) Quit 0
	
	If $system.Security.Check("%Ens_Code", "WRITE") || $system.Security.Check("%Ens_"_pType, "WRITE") {
		Quit 1
	}
	
	Quit 0
}

ClassMethod CheckExists(pClass As %String = "", pType As %String = "") As %Boolean
{
	If '##class(%Dictionary.ClassDefinition).%ExistsId(pClass) Quit 0
	Quit 1

	Set tModelClass = $case(pType, "BPL": "Ens.BPL.UI.BPLDocument", "DTL": "Ens.DTL.UI.DTLDocument", "RecordMap": "EnsLib.RecordMap.RecordMap")
	Quit $classmethod(tModelClass, "Exists", pClass)
}

}
