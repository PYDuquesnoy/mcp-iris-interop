/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used to represent the names of entities,
/// such as cubes and dimensions, within DeepSee metadata.
Class %DeepSee.Datatype.entityName Extends %Library.String [ System = 3 ]
{

Parameter MAXLEN = 250;

}
