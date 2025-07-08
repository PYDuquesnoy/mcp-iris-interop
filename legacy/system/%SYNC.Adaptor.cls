/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %callout

/// Subclasses of %SYNC.Adaptor are enabled for Object Synchronization and
/// may be used when creating sync sets for the purpose of synchronizing object
/// data with other systems.<br>
/// 
/// Classes that extend %Library.SwizzleObject can also be enabled for synchronization
/// simply by defining OBJJOURNAL as 1. There is no need to use %SYNC.Adaptor unless<br>
/// additional features are needed such as the ability to suppress some properties from
/// being synchronized. One reason to suppress a property (SYNCIGNORE=1) would be if the
/// property values are not relevant or perhaps not even valid on other systems.
Class %SYNC.Adaptor [ Abstract, PropertyClass = %SYNC.PropertyParameters, System = 2 ]
{

/// If OBJJOURNAL is true then the value of the JOURNALSTREAM parameter defines whether or not
/// streams will be journaled. If JOURNALSTREAM is false (0) then no streams will be journaled.
/// If JOURNALSTREAM is true (1) then streams will be journaled and if Object Synchronization tools
/// are used to produce SyncSets (%SYNC.SyncSet) then journaled streams will be added to the sync set
/// when the referencing object is added.
Parameter JOURNALSTREAM As INTEGER [ Constraint = "0,1", Flags = ENUM ] = 0;

/// %AddToSyncSet() adds an object to a sync set.
ClassMethod %AddToSyncSet(objSS As %SYNC.SyncSet, oref As %ObjectHandle = "", fileop As %Integer = 0, oid As %ObjectIdentity = "", changed As %List = "", guid As %String = "", originSystem As %String = "", originNS As %String = "") As %Integer [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set %code = 0
	If '$$$comMemberKeyGet(%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault) { Quit $$$OK }
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) Quit $$$OK
	Set classtype = $$$getClassType(%class)
	Set property = $$$comMemberNext(%class,$$$cCLASSproperty,""), required = 0, setcoll = 0, setprop = 0, setref = 0, setreq = 0
	While property '= "" {
		If ($$$comMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPstorable)) && ('$$$comMemberArrayGet(%class,$$$cCLASSproperty,property,$$$cPROPparameter,"SYNCIGNORE")) {
			Set qp=$$$QuoteName(property),prop=$$$QN(property)
			$$$comMemberKeyGetLvar(proptype,%class,$$$cCLASSproperty,property,$$$cPROPtype)
			Set propclasstype = $$$getClassType(proptype)
			$$$comMemberKeyGetLvar(required,%class,$$$cCLASSproperty,property,$$$cPROPrequired)
			$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,property,$$$cPROPcollection)
			If propclasstype = $$$cCLASSCLASSTYPEDATATYPE {
				If collection = "" { Set setprop = setprop + 1, setprop(setprop) = "Set:($lf(changed,"_qp_"))||(changed="""") @%objsync@(iPtr,"_qp_") = oref."_prop }
				Else { Set setcoll = setcoll + 1, setcoll(setcoll) = "If ($lf(changed,"_qp_"))||(changed="""") { Set key = """", count = 0, elem = oref."_prop_".GetNext(.key) While key '= """" { Set @%objsync@(iPtr,"_qp_",key) = elem, elem = oref."_prop_".GetNext(.key) } Set @%objsync@(iPtr,"_qp_") = count }" }
			}
			ElseIf propclasstype = $$$cCLASSCLASSTYPEPERSISTENT {
				If collection = "" { Set setprop = setprop + 1, setprop(setprop) = "If ($lf(changed,"_qp_"))||(changed="""") { Set propoid = oref."_$$$QN(property_"GetObject")_"() Set @%objsync@(iPtr,"_qp_") = $Select(propoid'="""":##class("_$$$QN(proptype)_").%GUID(propoid,1),1:"""") }" }
				Else { Set setcoll = setcoll + 1, setcoll(setcoll) = "If ($lf(changed,"_qp_"))||(changed="""") { Set key = """",count = 0, elem = oref."_prop_".GetObjectNext(.key) While key '= """" { Set @%objsync@(iPtr,"_qp_",key) = $Select(elem'="""":##class("_$$$QN(proptype)_").%GUID(elem,1),1:""""), elem = oref."_prop_".GetObjectNext(.key),count = count + 1 } Set @%objsync@(iPtr,"_qp_") = count }" }
			}
			ElseIf propclasstype = $$$cCLASSCLASSTYPESERIAL {
				If collection = "" { Set setprop = setprop + 1, setprop(setprop) = "Set:($lf(changed,"_qp_"))||(changed="""") @%objsync@(iPtr,"_qp_") = oref."_prop_".%AddToSyncSet(objSS,oref."_prop_",fileop,,,,originSystem,originNS)" }
				Else { Set setcoll = setcoll + 1, setcoll(setcoll) = "If ($lf(changed,"_qp_"))||(changed="""") { Set key = """",count = 0, elem = oref."_prop_".GetNext(.key) While key '= """" { Set @%objsync@(iPtr,"_qp_",key) = $Select($Isobject(elem):elem.%AddToSyncSet(objSS,elem,fileop,,,,originSystem,originNS),1:""""), elem = oref."_prop_".GetNext(.key),count = count + 1 } Set @%objsync@(iPtr,"_qp_") = count }" }
			}
			ElseIf propclasstype = $$$cCLASSCLASSTYPESTREAM {
				Set setprop = setprop + 1, setprop(setprop) = "If ($lf(changed,"_qp_"))||(changed="""") { Do oref."_prop_".SerializeToSyncSet(objSS,iPtr,"_qp_") }"
			}
			Else {
				Set setprop = setprop + 1, setprop(setprop) = "Set:($lf(changed,"_qp_"))||(changed="""") @%objsync@(iPtr,"_qp_") = oref."_prop
			}
		}
		Set property = $$$comMemberNext(%class,$$$cCLASSproperty,property)
	}
	$$$GENERATE("	Set %objsync = objSS.GlobalName()")
	$$$GENERATE("	Set iPtr = $Increment(@%objsync),@%objsync@(iPtr)=fileop")
	$$$GENERATE("	Set @%objsync@(iPtr,""%%CLASS"") = $classname()")
	$$$GENERATE("	Set @%objsync@(iPtr,""%%OSID"") = originSystem")
	$$$GENERATE("	Set @%objsync@(iPtr,""%%ONSID"") = originNS")
	If classtype = $$$cCLASSCLASSTYPEPERSISTENT {
		$$$GENERATE("	if guid '= """" {Set @%objsync@(iPtr,""%GUID"") = guid }")
		$$$GENERATE("	else {Set @%objsync@(iPtr,""%GUID"") = oref.%GUID($Select(oid'="""":oid,1:oref.%Oid()))}")
		$$$GENERATE("	If fileop = 2 { Quit iPtr }")
	}
	If setprop {
		Set setline = $c(9) _ setprop(1) For ptr = 2:1:setprop { If ($Length(setprop(ptr)) + $Length(setline)) < 2000 { Set setline = setline _ " " _ setprop(ptr) } Else { $$$GENERATE(setline) Set setline = $c(9) _ setprop(ptr) } }
		If setline '= "" { $$$GENERATE(setline) }
	}
	For ptr = 1:1:setcoll $$$GENERATE($c(9) _ setcoll(ptr))
	$$$GENERATE("	Quit iPtr")
	Quit $$$OK
}

/// <p>This method synchronizes an entry from a %SYNC.SyncSet with the local database. The method is generated and should not be overridden by
/// the user and there are no callbacks from this method. The return value of this method is a %Status value that indicates success or failure. Inputs to this
/// method include an oref to a %SYNC.SyncSet object, a pointer to the entry in the SyncSet and the type of modification represented by the SyncSet entry.
/// Modifications are of three types - insert a new object, update to an existing object, and delete an existing object. A parameter
/// passed by reference allows the caller to receive an oref to the affected object in the local database.
/// </p>
/// <br>
/// <p>
/// An entry in a SyncSet corresponds to one object in the local database. It contains values for properties of the object and represents some modification to an object
/// made in another database called the 'source' database. To synchronize the modifications made to the object in the source database it is necessary to repeat those
/// modifications in the local database. The first task is to resolve the GUID that identifies the modified object with the local database. If the object exists in the
/// local database and the type of modification, <var>fileop</var>, is a delete then the object is deleted from the local database and the status is returned to the caller.
/// If the object does not exists in the local database and the modification is a delete then nothing is done and a success status is returned to the caller. For other modification
/// types, inserts and updates, the object is opened if it exists or a new object created if it does not exist. It is to this object that modifications contained in the
/// SyncSet are applied by copying each value from the SyncSet entry to the corresponding property. Property values are either literals or objects. If the value is a literal
/// it is simply copied into the object. If the property is an object then the value is either a GUID or a link to an object that exists in the SyncSet. Object links are
/// used to resolve references to other object values that have not yet been synchronized to the local database. If the value is a GUID then the value is resolved by
/// resolving the GUID to an OID using the local database's GUID tables. If the GUID cannot be resolved then a new SyncSet entry is added to the end of the SyncSet and
/// the pointer to that SyncSet entry is used to link the current SyncSet entry to the newly created SyncSet entry. If the property whose value cannot be resolved is a
/// required property then the new SyncSet entry is a complete copy of the current entry, otherwise it is simply a partial entry containing the unresolvable values.
/// For serial objects, there is no 'partial' sync so any failure to resolve a GUID or linked object must be treated the same as a required property.
/// </p>
/// <p>
/// Once all values from the SyncSet entry have been processed by either synchronizing them with the local object or deferring resolution through link creation an oref
/// to the local object is returned to the caller. If the local object is an instance of a %Persistent class then it is also saved. Any failure reported by %Save is
/// reported to the caller.
/// </p>
ClassMethod %SyncObjectIn(objSS As %SYNC.SyncSet, iPtr As %Integer, ByRef oref As %ObjectHandle, fileop As %Integer = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
		#; While it is normal that a SyncSet will be produced in an order that will normally allow all object references
		#; to be resolved, there are some conditions that will require some rescheduling. Rescheduling of entire persistent objects
		#; only occurs when a required reference is not resolved. Otherwise, partial rescheduling is done. Rescheduling involves adding
		#; another object to the SyncSet that is another sync of the object that failed to resolve.
	Set %code = 0
	If '$$$comMemberKeyGet(%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault) { Quit $$$OK }
	Set journalstream=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"JOURNALSTREAM",$$$cPARAMdefault)
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) Quit $$$OK
	Set classtype = $$$getClassType(%class)
	If classtype = $$$cCLASSCLASSTYPEPERSISTENT {
		$$$GENERATE("	Set guid = $Get(@%objsync@(iPtr,""%GUID"")), link = 0")
	}
	Set property = $$$comMemberNext(%class,$$$cCLASSproperty,""), required = 0, setcoll = 0, setprop = 0, setrcoll = 0, setref = 0, setreq = 0
	While property '= "" {
		If ($$$comMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPstorable)) && ('$$$comMemberArrayGet(%class,$$$cCLASSproperty,property,$$$cPROPparameter,"SYNCIGNORE")) {
			Set qp=$$$QuoteName(property),prop=$$$QN(property)
			Set proptype = $$$comMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPtype)
			Set propclasstype = $$$getClassType(proptype)
			$$$comMemberKeyGetLvar(required,%class,$$$cCLASSproperty,property,$$$cPROPrequired)
			$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,property,$$$cPROPcollection)
			If propclasstype = $$$cCLASSCLASSTYPEDATATYPE {
				If collection = "" {
						#; There is no need to check for required here as all objects being synchronized have already passed validation
					Set setprop = setprop + 1, setprop(setprop) = "Set:$d(@%objsync@(iPtr,"_qp_")) oref."_prop_" = @%objsync@(iPtr,"_qp_")"
				}
				ElseIf (collection = $$$cPROPCOLLECTIONLIST) || (collection = $$$cPROPCOLLECTIONARRAY){
					Set setcoll = setcoll + 1, setcoll(setcoll) = "If $d(@%objsync@(iPtr,"_qp_")) { Do oref."_prop_".Clear()  s key="""" f  s key=$o(@%objsync@(iPtr,"_qp_",key)) q:key=""""  d oref."_prop_$Select(collection=$$$cPROPCOLLECTIONLIST:".Insert(@%objsync@(iPtr,"_qp_",key))",1:".SetAt(@%objsync@(iPtr,"_qp_",key),key)")_" }"
				}
			}
			ElseIf propclasstype = $$$cCLASSCLASSTYPEPERSISTENT {
				If classtype = $$$cCLASSCLASSTYPESERIAL {
						#; Persistent object reference from a serial container:
						#; 
						#;		Serial containers of object valued properties implicitly require every object to be resolved.
						#;		If not, don't create a forward link, just suspend the sync and let it happen later when this serial's container resolves
						#;		the serial again. When a container finds that a serial object doesn't resolve, it can either suspend (in the case of a serial container)
						#;		or create a forward link (in the case of a persistent container).
					Set required(property) = propclasstype, required = required + 1
					If collection = "" {
							#; A required property that is a reference to a persistent class causes the serial container to fail to load so set the reference in the
							#; 'required' code queue and the actual set of the property in the property set queue
						Set setreq = setreq + 1, setreq(setreq) = "If $d(@%objsync@(iPtr,"_qp_")) { Set rguid = $Get(@%objsync@(iPtr,"_qp_")) If rguid'="""" { Set oid=##class(%GUID).%GUIDFind(rguid) If oid'="""" { s temp(" _ qp _ ")=oid } Else { Set suspend = 1,oref="""" Quit $$$OK} } Else { s temp("_qp_")="""" }}"
						Set setprop = setprop + 1, setprop(setprop) = "Do:$d(temp(" _ qp _ ")) oref."_$$$QN(property_"SetObject")_"(temp(" _ qp _ "))"
					}
					ElseIf (collection = $$$cPROPCOLLECTIONLIST) || (collection = $$$cPROPCOLLECTIONARRAY){
							#; The same is true for collections in a serial container. Any failure to resolve is an overall failure to serialize
							#; the container. Set the references in the 'reference collection' queue and copy them out of the temp array in the
							#; 'collection set' code queue
						Set setrcoll = setrcoll + 1, setrcoll(setrcoll) = "If $d(@%objsync@(iPtr,"_qp_")) { s key="""",temp("_qp_")="""" f  s key=$o(@%objsync@(iPtr,"_qp_",key)) q:key=""""  s rguid=$Get(@%objsync@(iPtr,"_qp_",key)) Set oid=##class(%GUID).%GUIDFind(rguid) If oid'="""" { s temp(" _ qp _ ",key)=oid } Else { Set suspend = 1 Quit } }"
						Set setcoll = setcoll + 1, setcoll(setcoll) = "	If $d(temp("_qp_")) { d oref."_prop_".Clear() s key="""" f  s key=$o(temp("_qp_",key)) q:key=""""  d oref."_prop_$Select(collection=$$$cPROPCOLLECTIONLIST:".InsertObject(temp("_qp_",key))",1:".SetObjectAt(temp("_qp_",key))")_" }"
					}
				}
				Else {
						#; This isn't a serial container (must be persistent)
					If collection = "" {
						If 'required { Set setref = setref + 1, setref(setref) = "If $d(@%objsync@(iPtr,"_qp_")) { Set rguid = $Get(@%objsync@(iPtr,"_qp_")) If rguid'="""" { Set oid=##class(%GUID).%GUIDFind(rguid) If oid'="""" { s temp("_qp_")=oid } Else { Set:'link link = $Increment(@%objsync) Set @%objsync@(link,"_qp_")=rguid } } Else { Set temp("_qp_")="""" } }" }
						Else { Set required(property) = propclasstype, required = required + 1, setreq = setreq + 1, setreq(setreq) = "If $d(@%objsync@(iPtr,"_qp_")) { Set rguid = $Get(@%objsync@(iPtr,"_qp_")) If rguid'="""" { Set oid=##class(%GUID).%GUIDFind(rguid) If oid'="""" { s temp(" _ qp _ ")=oid } Else { Set:'link link = $Increment(@%objsync) Set suspend = 1 Merge @%objsync@(link)=@%objsync@(iPtr) if guid '= """" { set @%objsync@(""Requeue"",guid,link) = iPtr } } } Else { Set temp("_qp_")="""" } }" }
							#; and the line to bring in the resolved GUID
						Set setprop = setprop + 1, setprop(setprop) = "Do:$d(temp(" _ qp _ ")) oref."_$$$QN(property_"SetObject")_"(temp(" _ qp _ "))"
					}
					ElseIf (collection=$$$cPROPCOLLECTIONLIST) || ( collection=$$$cPROPCOLLECTIONARRAY ) {
						Set setrcoll = setrcoll + 1, setrcoll(setrcoll) = "If $d(@%objsync@(iPtr,"_qp_")) { s key=$o(@%objsync@(iPtr,"_qp_","""")),clink=0,temp("_qp_")="""" while key'="""" { s rguid=$Get(@%objsync@(iPtr,"_qp_",key)) Set oid=##class(%GUID).%GUIDFind(rguid) If oid'="""" { s temp(" _ qp _ ",key)=oid } Else { Set:'link link = $Increment(@%objsync) Merge @%objsync@(link,"_qp_")=@%objsync@(iPtr,"_qp_") Set clink=1 k temp("_qp_") } Quit:clink  s key=$o(@%objsync@(iPtr,"_qp_",key)) } }"
						Set setcoll = setcoll + 1, setcoll(setcoll) = "If $d(temp("_qp_")) { d oref."_prop_".Clear() s key="""" f  s key=$o(temp("_qp_",key)) q:key=""""  d oref."_prop_$Select(collection=$$$cPROPCOLLECTIONLIST:".InsertObject(temp("_qp_",key))",1:".SetObjectAt(temp("_qp_",key),key)")_" }"
					}
				}
			}
			ElseIf propclasstype = $$$cCLASSCLASSTYPESERIAL {
				If classtype = $$$cCLASSCLASSTYPESERIAL {
						#; Every object value is implicitly required in a serial container:
					Set required(property) = propclasstype, required = required + 1
					If collection = "" {
						Set setreq = setreq + 1, setreq(setreq) = "If $d(@%objsync@(iPtr,"_qp_")) { s rguid=$g(@%objsync@(iPtr,"_qp_")) If rguid'="""" { s serialtype=$g(@%objsync@(rguid,""%%CLASS"")),sc=$classmethod(serialtype,""%SyncObjectIn"",objSS,rguid,.soref) i soref'="""" { s temp(" _ qp _ ")=soref } Else { Set suspend=1,oref="""" Quit $$$OK } } Else { Set temp("_qp_")="""" } }"
						Set setprop = setprop + 1, setprop(setprop) = "Set:$d(temp(" _ qp _ ")) oref."_prop_"=temp(" _ qp _ ")"
					}
					ElseIf (collection=$$$cPROPCOLLECTIONLIST) || ( collection=$$$cPROPCOLLECTIONARRAY ) {
						Set setrcoll = setrcoll + 1, setrcoll(setrcoll) = "If $d(@%objsync@(iPtr,"_qp_")) { s key="""",temp("_qp_")="""" f  s key=$o(@%objsync@(iPtr,"_qp_",key)) q:key=""""  s rguid=$Get(@%objsync@(iPtr,"_qp_",key)) If rguid'="""" { Set sc=##class("_$$$QN(proptype)_").%SyncObjectIn(objSS,rguid,.soref) If soref'="""" { s temp(" _ qp _ ",key)=soref } Else { Set suspend=1 Quit } Else { Set temp("_qp_",key)="""" } }"
						Set setcoll = setcoll + 1, setcoll(setcoll) = "If $d(temp("_qp_")) { d oref."_prop_".Clear() s key=$o(temp("_qp_","""")) while key'="""" { d oref."_prop_$Select(collection=$$$cPROPCOLLECTIONLIST:".Insert(temp("_qp_",key))",1:".SetAt(temp("_qp_",key),key)")_" s key=$o(temp("_qp_",key)) } }"
					}
				}
				Else {
						#; Must be a persistent container of a serial object
					If collection = "" {
							#; Don't worry about required serial objects since a serial object is implicitly present all of the time
						Set setref = setref + 1, setref(setref) = "If $d(@%objsync@(iPtr,"_qp_")) { s rguid=$Get(@%objsync@(iPtr,"_qp_")) If rguid'="""" { Set sc=oref."_prop_".%SyncObjectIn(objSS,rguid,.soref) If soref'="""" { s temp(" _ qp _ ")=soref }"_$Select(classtype=$$$cCLASSCLASSTYPEPERSISTENT:" Else { Set:'link link = $Increment(@%objsync) Set @%objsync@(link,"_qp_")=rguid }",1:"") _ " } Else { Set temp("_qp_")="""" } }"
						Set setprop = setprop + 1, setprop(setprop) = "Set:$d(temp(" _ qp _ ")) oref."_prop_"=temp(" _ qp _ ")"
					}
					ElseIf (collection=$$$cPROPCOLLECTIONLIST) || ( collection=$$$cPROPCOLLECTIONARRAY ) {
						Set setrcoll = setrcoll + 1, setrcoll(setrcoll) = "If $d(@%objsync@(iPtr,"_qp_")) { s key=$o(@%objsync@(iPtr,"_qp_","""")),clink=0,temp("_qp_")="""" while key'="""" { s rguid=$Get(@%objsync@(iPtr,"_qp_",key)) If rguid'="""" { Set sc=##class("_$$$QN(proptype)_").%SyncObjectIn(objSS,rguid,.soref) If soref'="""" { s temp(" _ qp _ ",key)=soref } Else { Set:'link link = $Increment(@%objsync) Merge @%objsync@(link,"_qp_")=@%objsync@(iPtr,"_qp_") Set clink=1 k temp("_qp_") } } Else { Set temp("_qp_",key)="""" } Quit:clink  s key=$o(@%objsync@(iPtr,"_qp_",key)) } }"
						Set setcoll = setcoll + 1, setcoll(setcoll) = "If $d(temp("_qp_")) { d oref."_prop_".Clear() s key="""" f  s key=$o(temp("_qp_",key)) q:key=""""  d oref."_prop_$Select(collection=$$$cPROPCOLLECTIONLIST:".Insert(temp("_qp_",key))",1:".SetAt(temp("_qp_",key),key)")_" }"
					}
				}
			}
			ElseIf (propclasstype = $$$cCLASSCLASSTYPESTREAM) && (journalstream) { Set setcoll = setcoll + 1, setcoll(setcoll) = "If $d(@%objsync@(iPtr,"_qp_")) { d oref."_prop_".SyncStreamIn(objSS,iPtr,"_qp_") }" }
			Else {
				Set setprop = setprop + 1, setprop(setprop) = "Set:$d(@%objsync@(iPtr,"_qp_")) oref." _ prop _" = $Get(@%objsync@(iPtr,"_qp_"))"
			}
		}
		Set property = $$$comMemberNext(%class,$$$cCLASSproperty,property)
	}
	If setreq || setrcoll {
		$$$GENERATE("	Set suspend=0"_$Select(classtype = $$$cCLASSCLASSTYPEPERSISTENT:"",1:",link=0"))
		For ptr = 1:1:setreq $$$GENERATE($c(9)_setreq(ptr))
		If setreq $$$GENERATE("	If suspend { Set oref = """" Quit $$$OK }")
	}
#;Resolve object valued properties. Any optional object references which cannot be resolved are suspended.

		#;Instantiate the class
	If classtype = $$$cCLASSCLASSTYPEPERSISTENT {
		$$$GENERATE("	If guid '= """" { Set oid = ##class(%GUID).%GUIDFind(guid) } Else { Quit $$$ERROR($$$NullGUID,$classname()) }")
		$$$GENERATE("	If fileop = 2 { If (oid '= """") && (..%Exists(oid)) { Quit ..%Delete(oid) } Else { Quit $$$OK }}")
		$$$GENERATE("	If oid '= """" && (fileop=0) && ('..%Exists(oid)) { Set oid=""""}")
		$$$GENERATE("	If oid '= """" { Set oref = ..%Open(oid),insert = 0 }Else { Set oref = ..%New(), insert = 1 }")
		$$$GENERATE("	If oref = $$$NULLOREF,$O(^OBJ.GUID(0,guid,""""),-1,lastType) IF lastType=2 Quit $$$OK")
		$$$GENERATE("	If oref = $$$NULLOREF { Quit $Select('insert:$$$ERROR($$$FailedToOpenClass,$classname()_""(""_guid_"")""),1:$$$ERROR($$$FailedToNewClass,$classname()_""(sync)"")) }")
	}
	Else {
		$$$GENERATE("	Set oref = ..%New()")
		$$$GENERATE("	If oref = $$$NULLOREF { Quit $$$ERROR($$$FailedToNewClass,$classname()_""(sync)"") }")
	}
		#; Dequeue any code in the set reference collection queue
	If setrcoll {
		For ptr = 1:1:setrcoll $$$GENERATE($c(9)_setrcoll(ptr))
		$$$GENERATE("	If suspend { Set oref = """" Quit $$$OK }")
	}
		#;And synchronize the values
	If setref {
		Set setline = $c(9) _ setref(1) For ptr = 2:1:setref { If ($Length(setref(ptr)) + $Length(setline)) < 2000 { Set setline = setline _ " " _ setref(ptr) }Else { $$$GENERATE(setline) Set setline = $c(9) _ setref(ptr) }}
		If setline '= "" { $$$GENERATE(setline) }
	}
	If setprop {
		Set setline = $c(9) _ setprop(1) For ptr = 2:1:setprop { If ($Length(setprop(ptr)) + $Length(setline)) < 2000 { Set setline = setline _ " " _ setprop(ptr) }Else { $$$GENERATE(setline) Set setline = $c(9) _ setprop(ptr) }}
		If setline '= "" { $$$GENERATE(setline) }
	}
	For ptr = 1:1:setcoll $$$GENERATE($c(9) _ setcoll(ptr))
	If classtype = $$$cCLASSCLASSTYPEPERSISTENT {
		$$$GENERATE("	Set %objGUID(+oref) = guid, sc = oref.%Save() Kill %objGUID(+oref) If $$$ISERR(sc) Kill:link @%objsync@(link) Quit sc")
			// Generate the requeue
		$$$GENERATE("	If link { Set @%objsync@(link,""%GUID"") = @%objsync@(iPtr,""%GUID""), @%objsync@(link,""%%CLASS"") = @%objsync@(iPtr,""%%CLASS""), @%objsync@(link,""%%OSID"") = @%objsync@(iPtr,""%%OSID""), @%objsync@(link,""%%ONSID"") = @%objsync@(iPtr,""%%ONSID""), @%objsync@(iPtr,""%%FLINK"") = link, @%objsync@(link,""%%BLINK"") = iPtr set:@%objsync@(link,""%GUID"")'="""" @%objsync@(""Requeue"",@%objsync@(link,""%GUID""),link) = iPtr }")
		$$$GENERATE("	Quit sc")
	}
	Else { 	$$$GENERATE("	Quit $$$OK") }
	Quit $$$OK
}

}
