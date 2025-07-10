/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.XML.Entity Extends %Persistent [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// This property holds the key by which the entity is known
Property EntityKey As %String;

/// This property holds the external schema/dtd definition
Property Stream As %GlobalBinaryStream;

Index Primary On EntityKey [ IdKey, PrimaryKey, Unique ];

ClassMethod StoreEntity(pFileName As %String, pKey As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Check for file existence
		If '##class(%File).Exists(pFileName) {
			Set tSC=$$$ERROR($$$FileDoesNotExist,pFileName)
			Quit
		}

		#; Check for previous existence of entity
		If ##class(Ens.Util.XML.Entity).%ExistsId(pKey) {
			Set tSC=$$$ERROR($$$EnsErrObjectAlreadyExists,pKey,"Ens.Util.XML.Entity")
			Quit
		}
		 
		#; Create a file binary stream
		Set tFileStream=##class(%FileBinaryStream).%New()
		$$$ASSERT($IsObject(tFileStream))

		#; Link it to the file
		Set tSC=tFileStream.LinkToFile(pFileName)
		If $$$ISERR(tSC) Quit

		#; Now create an instance of the Entity object
		Set tEntity=##class(Ens.Util.XML.Entity).%New(tFileStream)
		$$$ASSERT($IsObject(tEntity))

		#; Set the key property
		Set tEntity.EntityKey=pKey

		#; Save the entity object		
		Set tSC=tEntity.%Save()

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method %OnNew(pInit) As %Status
{
	do {
		Set tSC=..StreamNewObject()
		If $$$ISERR(tSC) Quit
		Set tSC=..Stream.CopyFrom(pInit)
	} while (0)
	Quit tSC
}

/// Load an entity instance given it's key
ClassMethod LoadEntity(pID As %String, Output pEntity As Ens.Util.XML.Entity) As %Status
{
	Set tSC=$$$OK
	do {
		Set pEntity=##class(Ens.Util.XML.Entity).%OpenId(pID,,.tSC)
		If $$$ISERR(tSC) Quit
	} while (0)
	Quit tSC
}

Storage Default
{
<Data name="EntityDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>EKey</Value>
</Value>
<Value name="3">
<Value>Stream</Value>
</Value>
<Value name="4">
<Value>EntityKey</Value>
</Value>
</Data>
<DataLocation>^Ens.Util.EntityD</DataLocation>
<DefaultData>EntityDefaultData</DefaultData>
<IdLocation>^Ens.Util.EntityD</IdLocation>
<IndexLocation>^Ens.Util.EntityI</IndexLocation>
<StreamLocation>^Ens.Util.EntityS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
