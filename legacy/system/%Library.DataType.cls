/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Datatype superclass.
/// <p>Note that data types do not have to inherit from this class
/// in order to be a data type but this is used by the built
/// in data types.
Class %Library.DataType [ ClassType = datatype, System = 1 ]
{

/// Override this parameter value to specify what value should be used as a null marker when a property of the type is used in a subscript of an index map.
/// The default null marker used is -1E14, if none is specfied for the datatype.
/// However %Library.PosixTime and %Library.BigInt datatypes could have values that collate before -1E14, 
/// and this means null values would not sort before all non-NULL values.
Parameter INDEXNULLMARKER;

/// Return $$$OK if the value is valid for the datatype, or an error code otherwise.
ClassMethod IsValid(%val As %RawString) As %Status [ Abstract, ServerOnly = 0 ]
{
	Quit $$$OK
}

}
