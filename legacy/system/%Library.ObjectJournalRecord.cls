/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

Class %Library.ObjectJournalRecord Extends %Persistent [ Final, System = 4 ]
{

Parameter READONLY = 1;

Index IDKey On JrnId [ IdKey ];

Property JrnId As %Integer;

Property ObjectId As %String;

Property Extent As %String;

/// The filing operation - 0 = UPDATE, 1 = INSERT, 2 = DELETE
Property FilingType As %Integer;

Property SystemId As %String;

Property NamespaceId As %String;

Property OriginSystemId As %String;

Property OriginNamespaceId As %String;

Property SysTranId As %SYS.Journal.Transaction;

Property ObjectGUID As %String;

Relationship Transaction As %Library.ObjectJournalTransaction [ Cardinality = parent, Inverse = Records, SqlFieldName = Tran ];

Property JournalPtr As %Integer;

Property ChangedProperties As %List;

Property Filter As %String(MAXLEN = 32000);

/// OpenObjectVersion()
/// 		This method returns a reference to an object that is an instance of the same class
/// 		as the object that was journalled by this ObjectJournalRecord. The referenced object
/// 		does not have an ID assigned but all property values are the same as the journalled
/// 		object's property values at the time of this filing activity.
/// 
/// 		This method returns a null reference if the filing action is a DELETE or if the
/// 		system journal is not available for this filing activity. Also, for classes using
/// 		OBJJOURNAL = 2 a null reference is returned.
Method OpenObjectVersion(ByRef status As %Library.Status) As %Library.ObjectHandle
{
	try {
		set status = $$$OK, objRef = $$$NULLOREF
		Set iCount = 0
		Set ctpRefs = $Increment($$$ISCQUERYTEMP)
		Set ctpValues = $Increment($$$ISCQUERYTEMP)
		Kill $$$ISCQUERYTEMP(ctpValues)
		Kill $$$ISCQUERYTEMP(ctpRefs)
		Set objRec = $this ; class(%Library.ObjectJournalRecord).%Open(objRecOid) If '$isobject(objRec) { Set sc = $$$ERROR($$$GeneralError,"Invalid object in journal") Ztrap "EX" }
		Set system = objRec.SystemId 
		If system = "" { Set system = $$$txSIDlocal }
		Set ns = objRec.NamespaceId
		If ns = "" { Set ns = $$$txNSIDlocal }
			#; This is a delete operation - no journal retrieval necessary
		if objRec.FilingType = 2 { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Cannot open deleted version")) }
				#; If this object version is journalled in %ObjectJournal then add it to the syncset
		elseIf objRec.JournalPtr { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Cannot open object version from journal global")) }
				#; ...otherwise, attempt to grab this object version from the system journal.
				#; We probably want to encapsulate this behavior in an overridable method in a later version!!
		else {
			Kill paddr
			Set sc = $classmethod(objRec.Extent,"%PhysicalAddress",objRec.ObjectId,.paddr) If $$$ISERR(sc) { throw ##class(%Exception.StatusException).CreateFromStatus(sc) }
				#; Save this object ID so we know what objects are involved...
			Set ^||%isc.sync(objRec.Extent,objRec.ObjectId) = objRec.FilingType, ^||%isc.sync(objRec.Extent,objRec.ObjectId,1) = $Select($Get(^||%isc.sync(objRec.Extent,objRec.ObjectId,1))="":objRec.ChangedProperties,1:$$MergeList(^||%isc.sync(objRec.Extent,objRec.ObjectId,1),objRec.ChangedProperties)), ^||%isc.sync(objRec.Extent,objRec.ObjectId,2) = objRec.ObjectGUID, ^||%isc.sync(objRec.Extent,objRec.ObjectId,3) = objRec.OriginSystemId, ^||%isc.sync(objRec.Extent,objRec.ObjectId,4) = objRec.OriginNamespaceId
			Set ^||%isc.sync.ord(objRec.JrnId)=$lb(objRec.Extent,objRec.ObjectId)
				#; Create the structure needed by the %SYS.Journal.Transaction class for extracting persistent state data
				#; The structure is documented in that class.
				#; 		^IRIS.Temp(ctpRefs,<globalhash>) = ""	<<== This is simply a quick top level value intended to quickly eliminate uninteresting globals
				#; 		^IRIS.Temp(ctpRefs,<globalreferencehash>,<sub>) = $ListBuild(<globalreference>,<extentname>,<addressname>,<addressstructure>,<objectid>)
			For ptr = 1:1:paddr {
				Set gref = $List(paddr(ptr),1)
				Set globalhash = $zcrc($zwunpack($Name(@gref,0)),7)
				Set globalrefhash = $zcrc($zwunpack(gref),7)
				Set $$$ISCQUERYTEMP(ctpRefs,globalhash) = ""
				If $List(paddr(ptr),4) = "subnode" {
					Set sptr = $Increment($$$ISCQUERYTEMP(ctpRefs,globalhash,"s"))
					Set $$$ISCQUERYTEMP(ctpRefs,globalhash,"s",sptr) = paddr(ptr)
				}
				Else { Set $$$ISCQUERYTEMP(ctpRefs,globalrefhash,$Increment($$$ISCQUERYTEMP(ctpRefs,globalrefhash))) = paddr(ptr) }
			}
		}
			#; Retrieve interesting values for this transaction from the system journal...
		If $d($$$ISCQUERYTEMP(ctpRefs)) {
			Set sc = ..SysTranId.RetrieveSelectedValues(ctpRefs,ctpValues)
			Merge objectstate = $$$ISCQUERYTEMP(ctpValues,..Extent)
				#; objects(extent,id,1) is the %%CHANGED value from the ObjectJournalTransaction object
			set objRef = $classmethod(..Extent,"%LoadFromMemory",..ObjectId,.objectstate)
		}
	}
	catch tException {
		set status = tException.AsStatus()
		set objRef = $$$NULLOREF
	}
	Kill $$$ISCQUERYTEMP(ctpRefs), $$$ISCQUERYTEMP(ctpValues)
	Quit objRef

MergeList(lst1,lst2)
	For ptr = 1:1:$ListLength(lst1) { Set arT($List(lst1,ptr)) = "" }
	For ptr = 1:1:$ListLength(lst2) { Set arT($List(lst2,ptr)) = "" }
	Set lstReturn = "", ptr = $Order(arT("")) While ptr '= "" { Set lstReturn = lstReturn _ $ListBuild(ptr) Set ptr = $Order(arT(ptr)) }
	Quit lstReturn
}

ClassMethod OpenObjectByTime(pGUID As %String = "", pSyncTime As %Integer = "", ByRef pStatus As %Library.Status) As %Library.ObjectHandle
{
	if '$Data(^OBJ.GUID(0,pGUID)) { set pStatus = $$$OK quit $$$NULLOREF }
	set tTransactionRecord = $Order(^OBJ.GUID(0,pGUID,pSyncTime),-1)
	if tTransactionRecord {
		set tTransaction = $Order(^OBJ.JournalT(tTransactionRecord),-1)
		if tTransaction {
			set tMe = ..IDKeyOpen(tTransaction,tTransactionRecord)
			if $Isobject(tMe) { set tReturn = tMe.OpenObjectVersion(.pStatus) }
			else { set tReturn = $$$NULLOREF, pStatus = $$$ERROR($$$GeneralError,"Object Journal is not available at time = "_pSyncTime) }
		}
		else { set tReturn = $$$NULLOREF, pStatus = $$$ERROR($$$GeneralError,"Object Journal is not available at time = "_pSyncTime) }
	}
	else { set tReturn = $$$NULLOREF, pStatus = $$$OK }
	quit tReturn
}

Storage Default
{
<Data name="ChangedProperties">
<Attribute>ChangedProperties</Attribute>
<Structure>node</Structure>
<Subscript>"%%CHANGED"</Subscript>
</Data>
<Data name="Filter">
<Attribute>Filter</Attribute>
<Structure>node</Structure>
<Subscript>"%%FILTER"</Subscript>
</Data>
<Data name="ObjectTransactionJournalDefaultData">
<Value name="1">
<Value>ObjectId</Value>
</Value>
<Value name="2">
<Value>FilingType</Value>
</Value>
<Value name="3">
<Value>Extent</Value>
</Value>
<Value name="4">
<Value>SystemId</Value>
</Value>
<Value name="5">
<Value>NamespaceId</Value>
</Value>
<Value name="6">
<Value>OriginSystemId</Value>
</Value>
<Value name="7">
<Value>OriginNamespaceId</Value>
</Value>
<Value name="8">
<Value>SysTranId</Value>
</Value>
<Value name="9">
<Value>ObjectGUID</Value>
</Value>
<Value name="10">
<Value>JournalPtr</Value>
</Value>
<Value name="11">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^OBJ.JournalT</DataLocation>
<DefaultData>ObjectTransactionJournalDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^OBJ.JournalT</IdLocation>
<IndexLocation>^OBJ.JournalI</IndexLocation>
<StreamLocation>^OBJ.JournalS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
