/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a specific member definition within a dimension level within a DeepSee cube.<br/>
Class %DeepSee.Model.member Extends %DeepSee.Model.node [ System = 3 ]
{

/// Specification of this member. Typically this is the KEY value to be used for a member.
Property spec As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

}
