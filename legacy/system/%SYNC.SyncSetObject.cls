/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SYNC.SyncSetObject models a record in a %SYNC.SyncSet. SyncSets are globals containing records corresponding to
/// filing events. A filing event is an insert of a new object, update of an existing object or delete of an existing object.
/// Each time a filing event occurs in a class that is OBJJOURNALENABLED, the event is recorded in the %ObjectJournalTransaction class.
/// SyncSets are created from the %ObjectJournalTransaction class and each record in the SyncSet corresponds to a %ObjectJournalRecord.
/// %ObjectJournalRecords are individual filing events that occur with a transaction, the transaction being an instance of %ObjectJournalTransaction.
/// The SyncSetObject contains information that identifies the SyncSet as well as specific information about the filing event
/// described by a record in the SyncSet.
Class %SYNC.SyncSetObject Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 3 ]
{

/// The Sync Set pointer. This property references the SyncSet object on disk.
Property Ptr As %Integer;

/// sId is the global identifier and it is used to qualify the global name. Sync sets are constructed on
/// a system and then exported to other systems for synchronizing the objects it contains with a database
/// on the target system. The sId is used to generate a unique name for this sync set on the target system.
Property sId As %String [ Private ];

/// The GUID of the system where the SyncSet was created.
Property SysGUID As %String;

/// The Namespace in which the SyncSet was created.
Property Namespace As %String;

/// The name of the Class of which this object in the SyncSet is an instance.
Property Class As %String;

/// The GUID of this object in the SyncSet.
Property GUID As %String;

/// OREF referencing the object identified by GUID as it exists in the target database.
/// If the object does not yet exist in the target database then this oref will be null.
Property SSObject As %RegisteredObject;

/// The type of filing event that produced this SyncSet object. Values are:
/// 0 - UPDATE
/// 1 - INSERT
/// 2 - DELETE
Property FileOperation As %Integer;

/// ForwardLink is a link to another SyncSet instance in the same SyncSet. ForwardLinks are
/// created when an object cannot be synchronized due to some error. Errors that produce forward
/// links are typically unresolvable references to other objects. The most common unresolvable reference
/// in a properly constructed SyncSet will be a reference to an object that has not yet been created because
/// it occurs later in the SyncSet.
Property ForwardLink As %Integer;

/// BackwardLink is a link to the SyncSet instance that caused this SyncSet instance to be created. Creating a new
/// SyncSet instance is triggered by the Requeue mechanism. Requeue is the operation triggered by a failure to successfully
/// synchronize an object, usually because of an unresolvable reference. When a SyncSet instance is requeued the system
/// is basically saying to 'try this operation again later'. The idea being that the cause of the sync failure will have been
/// resolved by the time we process the requeued instance.
Property BackwardLink As %Integer;

/// This is a list of errors that are recorded for this SyncSet instance.
Property Error As %List;

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	if initvalue]"" {
		/// Pointer to ^OBJ.SYNC
		Set i%sId=$LG(initvalue,1)
		Set %objsync = "^OBJ.SYNC."_i%sId
		Set i%Ptr=$LG(initvalue,2)
		Set i%SysGUID=$Get(@%objsync@(i%Ptr,"%%SYSID"))
		Set i%Namespace=$Get(@%objsync@(i%Ptr,"%%NSID"))
		Set i%Class=$Get(@%objsync@(i%Ptr,"%%CLASS"))
		Set i%GUID=$Get(@%objsync@(i%Ptr,"%GUID"))
		Set i%FileOperation=$Get(@%objsync@(i%Ptr),0)
		Set i%Error=$Get(@%objsync@(i%Ptr,"%%SERR"))
		set i%ForwardLink = $Get(@%objsync@(i%Ptr,"%%FLINK"))
		set i%BackwardLink = $Get(@%objsync@(i%Ptr,"%%BLINK"))
	}
	Quit $$$OK
}

Method sIdGet() As %String
{
	Quit i%sId
}

/// Overridden SSObject Get method. This method looks up the object in the local GUID index.
/// If the GUID is found then attempt to open the object associated with the GUID and return the result.
/// If the GUID is not found in the GUID index then return NULLOREF.
Method SSObjectGet() As %RegisteredObject
{
	If i%GUID="" Quit ""
	Set oid = ##class(%Library.GUID).%GUIDFind(i%GUID)
	Quit $classmethod(i%Class,"%Open",oid)
}

/// Sync this SyncSet instance with the current database. This method returns a %Status value.
Method %SyncObjectIn(SyncSet As %SYNC.SyncSet) As %Status
{
	Set sc = $classmethod(..Class,"%SyncObjectIn",SyncSet,..Ptr,,..FileOperation)
	Quit sc
}

}
