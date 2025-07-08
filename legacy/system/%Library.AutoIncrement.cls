/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>%Library.AutoIncrement is a datatype class that extends %Library.BigInt. It does not override any
/// inherited behavior.</p>
/// <p>
/// Any property whose type class is %Library.AutoIncrement will be assigned a value on insert if no value is
/// specified, or a 0 or null value is specified. The AutoIncrement value is assigned by incrementing a counter that is defined in the storage
/// definition of the class. The default AutoIncrement counter location is the same as the DATALOCATION default but with
/// a "C" suffix instead of a "D". Individual AutoIncrement counters are located in the COUNTERLOCATION subscripted by the
/// property name.
/// </p>
/// <p>
/// The value of a AutoIncrement property is assigned automatically only when a new object is inserted into the database,
/// either using Objects or an SQL INSERT statement. No value is assigned if a value other than 0 or null is specified.
/// A %Library.AutoIncrement property value is only unique if the value is auto-generated.  If an explicit value is
/// saved, inserted, or updated, it may conflict with other rows/objects.  There is no guarantee the %Library.AutoIncrement
/// value is consecutive or sequential.
/// </p>
/// <p>
/// A compiled class/table may have one %Library.AutoIncrement property.  %Library.AutoIncrement is supported for
/// sharded class/tables, and the auto-incremented value will be unique across the shard cluster as long as explicit values are not saved for the property.
/// </p>
Class %Library.AutoIncrement Extends %Library.BigInt [ Final, System = 2 ]
{

}
