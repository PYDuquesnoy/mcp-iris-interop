/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Transport contents of a REST HTTP request or response
Class EnsLib.REST.GenericMessage Extends EnsLib.HTTP.GenericMessage [ System = 4 ]
{

/* Backwards compatibility
	Previously super class HTTP.GenericMessage did not
	have XMLNAME and hence need to explicitly set these
	to the class short name.
*/
Parameter XMLTYPE = "GenericMessage";

Parameter XMLNAME = "GenericMessage";

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
