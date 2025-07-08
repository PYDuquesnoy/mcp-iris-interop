/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>GUID,OID value pairs are recorded in ^OBJ.GUID. %ExtentMgr.GUID is a persistent class that
/// models ^OBJ.GUID. This class can be queried using SQL. It is also a fully functioning persistent
/// class with the GUID as the ID value. The OID property is swizzle-able. Instances of this class
/// can be deleted and updated. New instances can be created.</p>
/// <br>
/// This class defines two indexes. <index>idxGUID</index> is the IDKEY for the class and indexes the GUID
/// value. <index>idxOID</index> is a unique index on OID and indexes the OID value. The GUID value is stored
/// in the <index>idxOID</index> as data. Index methods Open and Exists can be used for various purposes. For example,
/// to see if an OID is defined in the GUID registry, simply call the idxOIDExists() method, passing in the requested
/// OID value. All index Exists() methods will return the ID corresponding to the requested key value in an option pass by reference
/// argument. For example:
/// <pre>
/// 	SAMPLES>set person = ##class(Sample.Person).%OpenId(5)
/// 	
/// 	SAMPLES>write "Exists: ",##class(%ExtentMgr.GUID).idxOIDExists(person.%Oid(),.id),", GUID: ",id
/// 	Exists: 1, GUID: A7413A9A-F73C-11DF-BF93-23DF9B6F8200
/// 	SAMPLES>
/// </pre>
/// Remember, OIDs are meant to be opaque values and simply constructing an OID value using $ListBuild
/// is breaking encapsulation and it might not produce the desired results. For example:
/// <pre>
/// 	SAMPLES>write "Exists: ",##class(%ExtentMgr.GUID).idxOIDExists($ListBuild(5,"Sample.Person"),.id),", GUID: ",id
/// 	Exists: 0, GUID: 
/// 	SAMPLES>
/// </pre>
Class %ExtentMgr.GUID Extends %Persistent [ Final, StorageStrategy = GUID, System = 3 ]
{

Property GUID As %Library.Binary;

Property OID As %Library.Persistent(CLASSNAME = 1) [ Required ];

Index idxGUID On GUID [ IdKey ];

Index idxOID On OID [ Data = GUID, Type = key, Unique ];

/// GetGUID returns a GUID value registered to the object whose OID is <var>pOID</var>. If no
/// GUID is currently assigned to that object or if <var>pOID</var> is NULL then NULL is returned.
ClassMethod GetGUID(pOID As %Library.Binary = "") As %Library.Binary [ SqlName = GetGUID, SqlProc ]
{
	QUIT $s(pOID'="":$Get(^OBJ.GUID(1,pOID)),1:"")
}

/// idxOIDExists()
/// 	This method returns true if a GUID exists whose OID matches the <var>pOID</var> value passed
/// 	in by the caller. The optional byref id parameter will contain the id matching the object that
/// 	was found to match the index key value upon a successful return.
ClassMethod idxOIDExists(pOID As %Library.Binary = "", ByRef id As %String = "") As %Boolean [ ServerOnly = 0 ]
{
	set id = $s(pOID'="":$Get(^OBJ.GUID(1,pOID)),1:"")
	quit id'=""
}

Storage GUID
{
<Data name="GUIDData">
<Attribute>OID</Attribute>
<Structure>node</Structure>
<Value name="1">
<Value>OID</Value>
</Value>
</Data>
<DataLocation>^OBJ.GUID(0)</DataLocation>
<DefaultData>GUIDDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^OBJ.GUID</IdLocation>
<Index name="idxOID">
<Location>^OBJ.GUID(1)</Location>
</Index>
<IndexLocation>^OBJ.GUIDI</IndexLocation>
<StreamLocation>^OBJ.GUIDS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
