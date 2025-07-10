/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Request Extends (Ens.MessageBody, Ens.Util.RequestBodyMethods) [ Inheritance = right, System = 4 ]
{

Parameter RESPONSECLASSNAME As %String;

/// Prevent this class from having the same default XML Type and Name as any of its subclasses that have the short classname "Request".
Parameter XMLTYPE As %String = "Ens_Request";

/// Prevent the XML Type and Name of classes derived from this class from interfering with one another if they have the same short classname.
Parameter XMLINCLUDEINGROUP As %Boolean = 0;

ClassMethod NewResponse(Output pResponse As Ens.Response) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		If ..#RESPONSECLASSNAME="" Set pResponse=$$$NULLOREF, tSC=$$$ERROR($$$EnsErrGeneral,$$$CurrentClass_" has no value for parameter RESPONSECLASSNAME") Quit
		Set pResponse = $zobjclassmethod(..#RESPONSECLASSNAME,"%New")  Set:'$IsObject(pResponse) tSC=%objlasterror
	} while (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
