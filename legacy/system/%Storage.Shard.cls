/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class contains a set of storage interface methods for use in sharded environments.
/// It is not for customer use.
Class %Storage.Shard Extends %Storage
{

Parameter STORAGECOMPILERCLASS = "%Compiler.Storage.Persistent";

/// STORAGEINTERFACE defines the type of serialization implemented by this class.
/// The value has to match the classtype of the class that is inheriting the serialization
/// interface.
Parameter STORAGEINTERFACE As STRING [ Constraint = ",persistent,serial", Flags = ENUM ] = "persistent";

Projection %ShardProjection As %Projection.Shard;

/// Generate the shard key from the fields that make up the key.
/// Not used currently.
ClassMethod %ShardKey(args... As %String) As %String [ Abstract ]
{
	; Can convert this to a generator and put in logic to build the shard key here
	; For now this is not required.
}

/// %DeleteData()
/// 	Delete object from persistent storage
/// 	The caller is responsible for calling %IdSet()
/// 	Don't include class name with id in input parameter
ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ CodeMode = generator, Final, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("DeleteData")
	RETURN $$$OK
}

/// 	Load object from persistent storage into memory. The caller is responsible for calling %IdSet()
/// 	Don't include class name with id in input parameter
Method %LoadData(id As %String) As %Status [ CodeMode = generator, Final, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("LoadData")
	RETURN $$$OK
}

/// %SaveData() - Save the object to a persistent state (e.g. store it on disk).
/// Returns: oid or "" if save fails
Method %SaveData(id As %String) As %Status [ CodeMode = generator, Final, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("SaveData")
	QUIT $$$OK
}

/// Intercept calls to %PurgeIndices and cause them to be executed on all the shards
ClassMethod %PurgeIndices(idxlist As %List = "", lockExtent As %Boolean = 0, pIgnoreIndexList As %RawString = "") As %Status [ ProcedureBlock = 1, ServerOnly = 1 ]
{
 	return ##class(%BigData.ShardedSQL).%CallClassMethod($classname(),"%PurgeIndices",$lb(idxlist,lockExtent,pIgnoreIndexList))
}

/// Intercept calls to %BuildIndices and cause them to be executed on all the shards
ClassMethod %BuildIndices(pIndexList As %RawString = "", pAutoPurge As %Integer = 1, pLockFlag As %Integer = 0, pJournalFlag As %Integer = "", pStartID As %RawString = "", pEndID As %RawString = "", pIgnoreIndexList As %RawString = "", pKeepSelectability As %Integer = 0) As %Status [ ProcedureBlock = 1, ServerOnly = 0 ]
{
	return ##class(%BigData.ShardedSQL).%CallClassMethod($classname(),"%BuildIndices",$lb(pIndexList,pAutoPurge,pLockFlag,pJournalFlag,pStartID,pEndID,pIgnoreIndexList,pKeepSelectability))
}

/// Intercept calls to %BuildDeferredIndices and cause them to be executed on all the shards
ClassMethod %BuildDeferredIndices(pLockFlag As %Integer = 0, pJournalFlag As %Integer = 1) As %Status [ ProcedureBlock = 1, ServerOnly = 0 ]
{
	return ##class(%BigData.ShardedSQL).%CallClassMethod($classname(),"%BuildDeferredIndices",$lb(pLockFlag,pJournalFlag))
}

/// %LockExtent acquires a lock on the entire extent of the class. If <var>shared</var> is true then a shared lock
/// is acquired, otherwise an exclusive lock is acquired. If the requested lock cannot be acquired then a failure
/// %Status value is returned. The default implementation returns an error indicating that the method is not implemented.
/// This method is automatically generated for persistent classes using <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %LockExtent(shared As %Boolean = 0) As %Status [ PlaceAfter = %LockId, ServerOnly = 1 ]
{
	RETURN $$$ERROR($$$MethodNotImplemented,"%Storage.Shard::%LockExtent (for sharded classes)")
}

/// %UnlockExtent releases a lock on the entire extent of the class. If <var>shared</var> is true then a shared lock
/// is acquired, otherwise an exclusive lock is acquired. If the requested lock cannot be acquired then a failure
/// %Status value is returned. The default implementation returns an error indicating that the method is not implemented.
/// This method is automatically generated for persistent classes using <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %UnlockExtent(shared As %Boolean = 0, immediate As %Boolean = 0) As %Status [ PlaceAfter = %LockExtent, ServerOnly = 1 ]
{
	RETURN $$$ERROR($$$MethodNotImplemented,"%Storage.Shard::%UnlockExtent (for sharded classes)")
}

}
