/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A %Monitor data type class representing a boolean Integer Flag. Corresponds to the SNMP Integer32 data type.
/// A Flag expressed as an Integer which may only be 1 (True) or 0 (False).
Class %Monitor.Flag Extends %Monitor.Integer [ Not ProcedureBlock, System = 3 ]
{

/// Used for enumerated (multiple-choice) attributes.
/// <var>VALUELIST</var> is either a null string ("") or a delimiter
/// separated list (where the delimiter is the first character) of logical values.
/// If a non-null value is present, then the attribute is restricted to values
/// in the list, and the validation code simply checks to see if the value is in the list.
Parameter VALUELIST As BOOLEAN;

}
