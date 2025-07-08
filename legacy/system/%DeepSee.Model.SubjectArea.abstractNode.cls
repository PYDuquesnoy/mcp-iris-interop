/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occUtility

IncludeGenerator %occUtility

/// Abstract base class for various DeepSee SubjectArea meta-data objects.<br/>
Class %DeepSee.Model.SubjectArea.abstractNode Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, Inheritance = right, System = 3 ]
{

/// Do not include *this* class in the XML groupings.
Parameter XMLINCLUDEINGROUP = 0;

Parameter XMLIGNORENULL = "inputonly";

Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject
{
	#; not supported
	Quit ""
}

Method %NormalizeObject() As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %AddToSaveSet(depth As %Integer = 3, refresh As %Integer = 0, norecurseon As %String = "") As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %RemoveFromSaveSet() As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status
{
	#; not needed;
	Quit $$$OK
}

Method %BindExport(dev As %String, ByRef Seen As %String, RegisterOref As %Boolean, AllowedDepth As %Integer, AllowedCapacity As %Integer) As %Status
{
	#; not needed; 
	Quit $$$ERROR($$$NotImplemented)
}

ClassMethod XMLDTD(top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status
{
	#; not needed; 
	Quit $$$ERROR($$$NotImplemented)
}

}
