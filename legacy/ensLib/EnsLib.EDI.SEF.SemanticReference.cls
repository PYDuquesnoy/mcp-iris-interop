/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a semantic reference or rule which may be employed for intra-segment 
/// validation
Class EnsLib.EDI.SEF.SemanticReference Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the location
Property Location As Location;

/// This holds the Rule
Property Rule As Rule;

}
