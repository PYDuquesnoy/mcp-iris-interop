/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used to represent expressions (such as an SQL expression)
/// within DeepSee metadata.
Class %DeepSee.Datatype.expression Extends %Library.String [ System = 3 ]
{

Parameter LANGUAGE As STRING;

Parameter MAXLEN = 2000;

}
