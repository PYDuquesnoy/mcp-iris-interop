/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%RowVersion</b> type represents a 64 bit integer value.
/// <p>This is identical to the <CLASS>%BigInt</CLASS> data type with the exception a property of type %RowVersion has special meaning to the Object and SQL filers.
/// <p>A property/field of type %RowVersion will increment a namespace-wide counter located at ^rINDEXEXT("rv"), and that incremented value will be stored in the %RowVersion property/field for each INSERT, UPDATE, or %Save that occurs on the class/table.  A %RowVersion property/field is typically used to enforce concurrency for the row/object.
/// <p>Only one property/field per class/table may be defined with type %RowVersion.
/// <p>A property/field of type %RowVersion may not be a property of the IdKey index.
/// <p>A property/field of type %RowVersion may not have a value explicitly set by an INSERT or UPDATE statement or %Save call.
/// <p>The %Library.RowVersion class is Final, and cannot be subclassed.
Class %Library.RowVersion Extends %Library.BigInt [ ClientDataType = BIGINT, Final, OdbcType = BIGINT, SqlCategory = INTEGER, System = 2 ]
{

/// The minimum allowed logical value for the data type.
Parameter MINVAL As INTEGER = 1;

}
