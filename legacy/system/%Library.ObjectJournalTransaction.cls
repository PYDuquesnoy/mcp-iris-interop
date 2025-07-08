/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

Class %Library.ObjectJournalTransaction Extends %Persistent [ Final, System = 4 ]
{

Parameter READONLY = 1;

Relationship Records As %Library.ObjectJournalRecord [ Cardinality = children, Inverse = Transaction ];

Index IDKey On TranId [ IdKey ];

Property TranId As %Integer;

Property SysTranId As %SYS.Journal.Transaction;

Property ChangedProperties As %List;

///  This method removes entries from the object journal up to minValue (exclusive)
ClassMethod PurgeUpToTxn(minValue As %Integer) As %Status
{
 		#dim eException as %Exception.AbstractException
 	Set tSC=$$$OK
 	try {
 		If minValue {
 			Set tItem=""
 			For  {
 				Set tItem=$O(^OBJ.JournalT(tItem))
 				Quit:tItem=""
 				Quit:tItem>=minValue
 				Set tSubItem=""
 				For  {
 					Set tSubItem=$O(^OBJ.JournalT(tItem,tSubItem)) Quit:tSubItem=""
 					Set tGUID=$lg(^OBJ.JournalT(tItem,tSubItem),9)
 					Kill:tGUID]"" ^OBJ.GUID(0,tGUID,tSubItem)
 					
 				}
				Kill ^OBJ.JournalT(tItem)
 			}
 		}
 	} Catch (eException) {
 		Set tSC = eException.AsStatus()
 	}
 	Quit tSC
}

Method AddJrnTranToSyncSet(objSyncSet As %ObjectHandle, lExclude As %List) As %Status
{
	Set $ZTrap = "CatchError"
	Set iCount = 0
	Set ctpRefs = $Increment($$$ISCQUERYTEMP)
	Set ctpValues = $Increment($$$ISCQUERYTEMP)
	Kill $$$ISCQUERYTEMP(ctpValues)
	Kill $$$ISCQUERYTEMP(ctpRefs)
	kill ^||%isc.sync, ^||%isc.sync.ord
	Set recPtr = ..Records.Next("")
	Set %objsync = objSyncSet.GlobalName()
	While recPtr '= "" {
			#; Set journal = ^OBJ.JournalT(iTranPtr,iTJrnPtr)
			#; DLP1742: Swizzle the related child object outside of the relationship object so that we don't keep it in memory after this
			#;			loop is finished with it.
			#; An error here will exit the method and return the error to the caller.
		Set objRecOid = ..Records.GetObjectAt(recPtr) set objRec = ##class(%Library.ObjectJournalRecord).%Open(objRecOid) If '$isobject(objRec) { Set sc = $$$ERROR($$$GeneralError,"Invalid object in journal") Ztrap "EX" }
		Set system = objRec.SystemId 
		If system = "" { Set system = $$$txSIDlocal }
		Set ns = objRec.NamespaceId
		If ns = "" { Set ns = $$$txNSIDlocal }
		if objSyncSet.FilterObject'="",objRec.ObjectGUID'="" {
			If $classmethod(objRec.Extent,"%OnBeforeAddToSync",objRec.ObjectGUID,objSyncSet.FilterObject,objRec.FilingType,objRec.Filter) Set recPtr = ..Records.Next(recPtr)  Continue
		}
			#; This is a delete operation - no journal retrieval necessary
		If objRec.FilingType = 2 { Set iPtr = $Increment(@%objsync),@%objsync@(iPtr)=2,@%objsync@(iPtr,"%GUID") = objRec.ObjectGUID, @%objsync@(iPtr,"%%CLASS") = objRec.Extent, @%objsync@(iPtr,"%%OSID") = objRec.OriginSystemId, @%objsync@(iPtr,"%%ONSID") = objRec.OriginNamespaceId Kill ^||%isc.sync(objRec.Extent,objRec.ObjectId) }
			#; If this object version is journalled in %ObjectJournal then add it to the syncset
			#; If we formally support type 2 journaling again then we need to report and log errors from this call:
		ElseIf objRec.JournalPtr { Do ##class(%Library.ObjectJournal).AddJrnRecToSyncSet(objSyncSet,..TranId,objRec.JournalPtr,system,ns,objRec.ChangedProperties, objRec.OriginSystemId, objRec.OriginNamespaceId) Set iCount = iCount + 1 }
			#; ...otherwise, attempt to grab this object version from the system journal.
			#; We probably want to encapsulate this behavior in an overridable method in a later version!!
		Else {
			Kill paddr
				#; compute the physical global references used to store this object. If an error occurs, exit the method and report the error.
			Set sc = $classmethod(objRec.Extent,"%PhysicalAddress",objRec.ObjectId,.paddr) If $$$ISERR(sc) ZTrap "EX"
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
		Set recPtr = ..Records.Next(recPtr)
	}
		#; Retrieve interesting values for this transaction from the system journal...
	If $d($$$ISCQUERYTEMP(ctpRefs)) {
		kill %objlasterror
			#; Exit if an error is reported by the journal extract...
		set tSystemJournal = ..SysTranId
		if $IsObject(tSystemJournal)=1 {
			Set sc = ..SysTranId.RetrieveSelectedValues(ctpRefs,ctpValues) if $$$ISERR(sc) do objSyncSet.QueueError(..TranId,sc)
		} elseif $$$ISERR($Get(%objlasterror,$$$OK)) {
			set sc = %objlasterror
			do objSyncSet.QueueError(..TranId,sc)
		} else {
			set sc = $$$ERROR($$$JournalFileOpenIdFailed,..SysTranIdGetObjectId())
			do objSyncSet.QueueError(..TranId,sc)
		}
		Set jrnId = $Order(^||%isc.sync.ord(""))
		While jrnId '= "" {
			Kill object, objectstate
			Set extent=$li(^||%isc.sync.ord(jrnId),1)
			Set id=$li(^||%isc.sync.ord(jrnId),2)
			Merge objectstate = $$$ISCQUERYTEMP(ctpValues,extent)
				#; objects(extent,id,1) is the %%CHANGED value from the ObjectJournalTransaction object
				#; %AddJrnObjToSyncSet returns an iPtr integer, not a status
			Set recPtr = $classmethod(extent,"%AddJrnObjToSyncSet",objSyncSet,^||%isc.sync(extent,id),$$$oidForm(id),.objectstate,^||%isc.sync(extent,id,1),^||%isc.sync(extent,id,2),^||%isc.sync(extent,id,3),^||%isc.sync(extent,id,4))
			Set jrnId=$o(^||%isc.sync.ord(jrnId))
		}
	}
	Kill $$$ISCQUERYTEMP(ctpRefs), $$$ISCQUERYTEMP(ctpValues)
	Quit $$$OK
CatchError
	set tError = $ZError
	Set $ZTrap = ""
	Kill $$$ISCQUERYTEMP(ctpRefs)
	If $Extract(tError,1,5) = "<ZEX>" Quit sc
	Quit $$$ERROR($$$ObjectScriptError,tError)
MergeList(lst1,lst2)
	For ptr = 1:1:$ListLength(lst1) { Set arT($List(lst1,ptr)) = "" }
	For ptr = 1:1:$ListLength(lst2) { Set arT($List(lst2,ptr)) = "" }
	Set lstReturn = "", ptr = $Order(arT("")) While ptr '= "" { Set lstReturn = lstReturn _ $ListBuild(ptr) Set ptr = $Order(arT(ptr)) }
	Quit lstReturn
}

Storage Default
{
<Data name="ObjectJournalTransactionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SysTranId</Value>
</Value>
<Value name="3">
<Value>ChangedProperties</Value>
</Value>
</Data>
<DataLocation>^OBJ.JournalT</DataLocation>
<DefaultData>ObjectJournalTransactionDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^OBJ.JournalT</IdLocation>
<IndexLocation>^OBJ.JournalI</IndexLocation>
<StreamLocation>^OBJ.JournalS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
