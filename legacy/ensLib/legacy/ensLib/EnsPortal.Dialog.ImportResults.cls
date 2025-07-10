/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This pages shows the export output of the System Management Portal.
Class EnsPortal.Dialog.ImportResults Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Resource from the import popup.
Parameter RESOURCE As COSEXPRESSION = "$G(%session.Data(""ImportDocuments"",""Resource""))";

Parameter PRIVATE = 1;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
pre {
	margin: 0px;
	padding: 4px;
	white-space: pre-line;
	word-wrap: break-word;
}
</style>
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		&html<<html><head></head>>
		&html<<body><pre>>
		Set FileName = $G(%request.Data("FILENAME",1))
		If FileName = "" Write !,$$$TextHTML("File name is empty") Quit
		If ##class(%File).Exists(FileName) = 0 Write !,$$$TextHTML("File does not exist!") Quit
		Set Charset = $G(%request.Data("CHARSET",1))
		Set CompileFlags = "csko3" //$G(%request.Data("COMPILEFLAGS",1))
		Kill SelectedItems
		Merge SelectedItems = %session.Data("ImportDocuments","Docs")
		// To do: In case of auditing enabled for the type being imported, generate auditing record(s)
		Write $$$FormatText($$$Text("Importing into namespace %1..."),$Namespace)
		Do %response.Flush()
		Hang 0.1

		// HTML Escape the output from $System.OBJ.Load()
		Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
		Set tSC = $System.OBJ.Load(FileName,CompileFlags,.err,.loadlist,0,.SelectedItems,,Charset)
		Kill EscapeObj // disable HTML Escaping

		If $O(err(""))'="" Do ..DrawError(err)
		Do %response.Flush()
		Hang 0.1
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ERR(tSC) {
		Write ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	&html<</pre>>
	&html<</body>>
	&html<</html>>
	Quit $$$OK
}

ClassMethod DrawError(err)
{
	Set errno = ""
	For  {
		Set errno = $O(err(errno))
		Quit:errno=""
		Write $ZCVT(err(errno),"O","HTML"),"<br/>"
	}
}

ClassMethod %OnPreHTTP() As %Boolean
{
	Set tResult = ##super()

	If %response.Redirect = "" {
		// Adjust page timeout if needed
		Set:%request.GatewayTimeout<300 %response.Timeout = 300
	}

	Quit tResult
}

}
