/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occXSLT

/// Subclasses of this class represent the result of a single match following an XPATH expression evaluation
Class %XML.XPATH.Result Extends %Persistent [ StorageStrategy = custom, System = 4 ]
{

/// This holds the type of the result, $$$XPATHVALUE or $$$XPATHDOM
Property Type As %Integer [ Calculated ];

/// This holds the key into ^IRIS.Temp which holds the results
Property target As %Integer;

Method TypeGet() As %Integer
{
	Quit $$$JobPrivateGlobalRef(i%target)
}

Method %OnClose() As %Status [ Private ]
{
	#; Tidy up temp global storage
	Kill $$$JobPrivateGlobalRef(i%target) Quit $$$OK
}

Storage custom
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%XML.XPA.ResultS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
