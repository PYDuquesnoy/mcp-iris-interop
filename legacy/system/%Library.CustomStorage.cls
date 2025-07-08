/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %systemInclude

/// The <b>%CustomStorage</b> class contains a set of empty storage interface methods. 
/// The <b>%CustomStorage class</b> serves as a storage class for objects in which you 
/// plan on providing your own storage interface methods. It is assumed that 
/// these methods will override all of the methods listed here. 
Class %Library.CustomStorage Extends %Storage [ Abstract, Not ProcedureBlock, System = 2 ]
{

/// SQLENABLED controls the projection of a persistent class to SQL. If TRUE,
/// then an SQL table will be created during compilation that is based on the
/// class. For classes using %Library.CustomStorage, the data model projected
/// is based on the SQL maps defined in the storage definition.
Parameter SQLENABLED = 0;

Parameter STORAGECOMPILERCLASS = "%Compiler.Storage.Common";

}
