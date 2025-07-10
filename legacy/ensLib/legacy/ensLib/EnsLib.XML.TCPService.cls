/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.XML.TCPService Extends EnsLib.TCP.PassthroughService [ System = 4 ]
{

/// Store a set of searchable properties associated with each XML document processed. <br>
/// These records will be stored in the named SearchTable class, if any.
Property SearchTableClass As %String(MAXLEN = 100) [ InitialExpression = "EnsLib.XML.SearchTable" ];

Parameter SETTINGS = "SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.XML.TCPService}";

/// Do the SearchTable indexing if configured
Method resolveAndIndex(pInput As %Persistent) As %Status
{
	If ""'=..SearchTableClass {
		TRY {
			Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",pInput)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_pInput_"/"_pInput.%Id()_" ' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_pInput_"/"_pInput.%Id()_" : "_errobj.AsSystemError()) }
		Kill $$$EnsJobLocal("CurrentXPATHDoc")
	}
	Quit $$$OK
}

}
