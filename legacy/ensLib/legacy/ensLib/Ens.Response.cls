/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Response Extends (Ens.MessageBody, Ens.Util.ResponseBodyMethods) [ Inheritance = right, System = 4 ]
{

/// Prevent this class from having the same default XML Type and Name as any of its subclasses that have the short classname "Response".
Parameter XMLTYPE As %String = "Ens_Response";

/// Prevent the XML Type and Name of classes derived from this class from interfering with one another if they have the same short classname.
Parameter XMLINCLUDEINGROUP As %Boolean = 0;

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
