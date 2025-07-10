/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for search criteria in the Portal.
Class EnsPortal.Util.AbstractSearchCriteria [ Abstract, System = 4 ]
{

Property SortOrder As %Integer(DISPLAYLIST = ",Newest First,Oldest First", VALUELIST = ",0,1") [ InitialExpression = 0 ];

Property TimeFormat As %Integer(DISPLAYLIST = ",Complete,Time Only", VALUELIST = ",0,1") [ InitialExpression = 0 ];

Property StartTime As %TimeStamp;

Property EndTime As %TimeStamp;

Property StartId As %Integer;

Property EndId As %Integer;

Property Source As %String(MAXLEN = 128);

ClassMethod CreateFromProxyObject(pProxy As %ZEN.proxyObject, Output pSearchCriteria As EnsPortal.Util.AbstractSearchCriteria) As %Status [ CodeMode = objectgenerator ]
{
	If %class.Abstract {
		Do %code.WriteLine($c(9)_"Set pSearchCriteria = """"")
		Do %code.WriteLine($c(9)_"Quit $$$ERROR($$$NotImplemented)")
		Quit $$$OK
	}

	Do %code.WriteLine($c(9)_"Set tStatus = $$$OK")
	Do %code.WriteLine($c(9)_"Try {")
	Do %code.WriteLine($c(9,9)_"Set pSearchCriteria = """"")
	Do %code.WriteLine($c(9,9)_"Set tSearchCriteria = ..%New()")
	For i=1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(i)
		If ($extract(tProp.Name) = "%") Continue

		Do %code.WriteLine($c(9,9)_"Set tSearchCriteria." _ tProp.Name _ " = pProxy." _ tProp.Name)
	}
	Do %code.WriteLine($c(9,9)_"Set pSearchCriteria = tSearchCriteria")
	Do %code.WriteLine($c(9)_"}")
	Do %code.WriteLine($c(9)_"Catch ex {")
	Do %code.WriteLine($c(9,9)_"Set tStatus = ex.AsStatus()")
	Do %code.WriteLine($c(9)_"}")
	Do %code.WriteLine($c(9)_"Quit tStatus")
	Quit $$$OK
}

}
