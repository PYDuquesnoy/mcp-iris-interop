/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This pages shows the output of SOAP Wizard.
Class %ZEN.Template.AddInWizard.XSLTransformWizardOutput Extends %ZEN.Template.cspTemplate [ Deprecated, System = 4 ]
{

/// Set this to the correct domain.
Parameter DOMAIN = "%TemplateMessages";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {

		&html<<html><head>
		<style type="text/css">
		body {
			font-family: courier new, sans-serif;
		}
		</style>
		</head>>
		&html<<body><pre>>
		Do %response.Flush()
		Set NAMESPACE = $G(%request.Data("$NAMESPACE",1),$namespace)
		If $namespace '= NAMESPACE Set $Namespace = NAMESPACE
		Set xmlout = $G(^ISC.XSLTWizard($Username,"xmlout"))
		If xmlout '= "" {
			Set stream = ##class(%FileCharacterStream).%New()
			Set stream.Filename = xmlout
			While 'stream.AtEnd {
	 			Set line = stream.ReadLine()
	 			&html<#($ZCVT(line,"O","HTML"))#>
		 	}
		}
		&html<</pre></body></html>>
		}

	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set ^ISC.XSLTWizard($Username,"Error") = "Unexpected Error: "_tSC
		Write "Unexpected Error: "_tSC
	}
	Do %response.Flush()
	Quit $$$OK
}

/// Event handler for <b>PreHTTP</b> event: this is invoked before
/// the HTTP headers for a CSP page have been sent.  All changes to the
/// <class>%CSP.Response</class> class, such as adding cookies, HTTP headers,
/// setting the content type etc. must be made from within the OnPreHTTP() method.
/// Also changes to the state of the CSP application such as changing
/// %session.EndSession or %session.AppTimeout must be made within the OnPreHTTP() method.
/// It is prefered that changes to %session.Preserve are also made in the OnPreHTTP() method
/// as this is more efficient, although it is supported in any section of the page.
/// Return <b>0</b> to prevent <method>OnPage</method> from being called.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '##super() Quit 0
	// Allow one hour for compiles.
	Set %response.Timeout = 3600
	Quit 1
}

}
