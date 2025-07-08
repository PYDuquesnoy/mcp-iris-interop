/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is used to represent the name of a delegator method:
/// this is a method within the current page object that serves
/// as a server-side callback method.
Class %ZEN.Datatype.delegator Extends datatype [ Deprecated, System = 3 ]
{

/// This is the formal spec of the delegator method.
/// E.g., "pComp:%ZEN.Component.object,pText:%String"
Parameter FORMALSPEC As STRING;

/// This is the return type of the delegator method.
Parameter RETURNTYPE As STRING;

Parameter XMLPROJECTION = "attribute";

Parameter ZENSETTING = 0;

Parameter MAXLEN = 64;

Parameter ZENENCRYPT = 1;

ClassMethod IsValid(%val) As %Status
{
	Quit $$$OK
}

}
