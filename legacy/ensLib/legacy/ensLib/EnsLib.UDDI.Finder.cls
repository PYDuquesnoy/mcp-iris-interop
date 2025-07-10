/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for all the Find* classes in the EnsLib.UDDI package
Class EnsLib.UDDI.Finder Extends EnsLib.UDDI.Base [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Affects the behavior of the find, EnsLib.UDDI.DT.FindQualifier for details
Property FindQualifiers As EnsLib.UDDI.uddi.findQualifiers;

/// Max number of matches to return ( rows ). A search will set the 'truncated' output
/// parameter to TRUE (1) if the number of available matches  exceeds the MaxRows specified
/// in the call
Property MaxRows As %Integer [ InitialExpression = 100 ];

}
