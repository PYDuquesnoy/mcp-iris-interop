/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A version of the <CLASS>%ArrayOfObjects</CLASS> collection class that stores 
/// class names in OIDs.
/// These classes can be used 'stand alone' to store a collection.
Class %Library.ArrayOfObjectsWithClassName Extends %ArrayOfObjects [ OdbcType = VARCHAR, Not ProcedureBlock, StorageStrategy = Custom, System = 2 ]
{

/// This parameter determines how the collection object stores OID values. 
/// If this parameter is set to 0, then partially-formed OID values, containing only an ID number, 
/// are used. If this parameter is set to 1, then fully-formed OID values, containing both a class 
/// name and an ID number, are used.
Parameter CLASSNAMEINOID = 1;

Storage Custom
{
<Type>%CompleteCustomStorage</Type>
}

}
