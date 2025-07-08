/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.call Extends reportNode [ Deprecated, System = 4 ]
{

/// Name of method that returns an XML stream to include
Property method As %ZEN.Datatype.string;

/// User-defined list of call parameters. These are used to supply
/// parameter values for the call.
Property parameters As list Of %ZEN.Report.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// return status by reference in last parameter to method
Property hasStatus As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

}
