/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.UI.Dialog.compileDomainOutput Extends %CSP.Page [ Deprecated, System = 4 ]
{

Parameter SECURITYRESOURCE = "%Development";

/// Set this to the correct domain.
Parameter DOMAIN = "%iKnow";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try 
	{
		Set tClass = $G(%request.Data("DOMAINDEF",1))
		&html<<html><head></head>>
		&html<<body>>
		If tClass = "" {
			Write $$$TextHTML("Class name is empty. Nothing to compile.")
			&html<</body></html>>
			Quit
		}
		Set ^IRIS.Temp.iKnowDomainCompile($Username,tClass,+$J) = $H
		Write $$$FormatTextHTML($$$Text("Compiling class: %1"),tClass),"<br/>"
		Do %response.Flush()
		&html<<pre>>
		Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
		Set model = ##class(%iKnow.UI.Architect).%GetModel(tClass)
		do model.%SaveToClass(tClass,0,1,1,"%iKnow.DomainDefinition")
		Kill EscapeObj
		&html<</pre>>
		Write $$$Text("Complete"),"<br/>"
		Do %response.Flush()
		Set ^IRIS.Temp.iKnowDomainCompile($Username,tClass,+$J) = "Done"
		&html<</body>>
		&html<</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit $$$OK
}

}
