/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>%Library.Counter is a datatype class that extends %Library.BigInt. It does not override any
/// inherited behavior.</p>
/// <p>
/// Any property whose type class is %Library.Counter will be assigned a value on insert if no value is
/// specified. The counter value is assigned by incrementing a counter that is defined in the storage
/// definition of the class. The default counter location is the same as the DATALOCATION default but with
/// a "C" suffix instead of a "D". Individual counters are located in the COUNTERLOCATION subscripted by the
/// property name.
/// </p>
/// <p>
/// The value of a counter property is assigned automatically only when a new object is inserted into the database,
/// either using Objects or an SQL INSERT statement. No value is assigned if a value is specified. If a value is specified
/// and that value is greater than the current counter value then the value of the counter is set to the property's value.
/// </p>
Class %Library.Counter Extends %Library.BigInt [ System = 2 ]
{

}
