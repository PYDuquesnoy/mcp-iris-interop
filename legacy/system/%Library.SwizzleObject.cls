/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.SwizzleObject Extends %RegisteredObject [ Abstract, System = 2 ]
{

/// DEFAULTCONCURRENCY is the default value for the concurrency formal argument
/// defined for %Open, %OpenId, %Delete and %DeleteId methods. It is not the default
/// value of the %Concurrency property of persistent classes. If the value of the actual
/// concurrency argument passed to any of the above methods is -1 then the formal argument value will
/// be set to the value of the DEFAULTCONCURRENCY parameter value defined for the class.
Parameter DEFAULTCONCURRENCY = "$zu(115,10)";

/// If OBJJOURNAL is true then the value of the JOURNALSTREAM parameter defines whether or not
/// streams will be journaled. If JOURNALSTREAM is false (0) then no streams will be journaled.
/// If JOURNALSTREAM is true (1) then streams will be journaled and if Object Synchronization tools
/// are used to produce SyncSets (%SYNC.SyncSet) then journaled streams will be added to the sync set
/// when the referencing object is added.
Parameter JOURNALSTREAM As INTEGER [ Constraint = "0,1", Flags = ENUM ] = 0;

/// if OBJJOURNAL is TRUE then inserts, updates and deletes will be logged in ^OBJ.JournalT
/// if OBJJOURNAL = 2 then the entire object will also be journaled in ^OBJ.Journal
Parameter OBJJOURNAL As INTEGER [ Constraint = "0,1,2", Flags = ENUM ] = 0;

/// Deletes the stored version of the object with OID <var>oid</var> from the database. 
/// It does not remove any in-memory versions of the object that may be present.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument. If no value for the <var>concurrency</var>
/// argument is passed or the value passed is -1 then it will be assigned the value of the
/// DEFAULTCONCURRENCY parameter as defined for the class.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// 
/// <p>Internally, <METHOD>%Delete</METHOD> initiates a transaction and then invokes the storage 
/// interface method <METHOD>%DeleteData</METHOD>. If <METHOD>%DeleteData</METHOD> succeeds, the 
/// transaction is committed, otherwise it is rolled back. 
ClassMethod %Delete(oid As %ObjectIdentity = "", concurrency As %Integer = -1) As %Status [ ServerOnly = 1 ]
{
	Quit:oid="" $$$ERROR($$$NullOid,$classname()) s id=$$$oidPrimary(oid) Quit:id="" $$$ERROR($$$NullId,$classname())
	#; get class name
	Set class=$$$oidClassName(oid)
	#; if class name is not present in oid, we must call the
	#; class method %OnDetermineClass
	If class="" {
		If $system.CLS.IsMthd("%OnDetermineClass") { Set sc=..%OnDetermineClass(oid,.class) Quit:$$$ISERR(sc) sc } Else { Set class=$classname() }
		Set oid=$$$oidInsertClassName(oid,class)
	} Else {
		Set class=$$$NormalizeClassname(class)
	}
	#; See if we are the correct class. If not, dispatch polymorphically to correct %Delete()
	If class'= "",class'=$classname() Quit $classmethod(class,"%Delete",oid,.concurrency)
	Quit $$$ERROR($$$AbstractClassNotInstantiable,$classname())
}

/// Deletes the stored version of the object with ID <var>id</var> from the database. 
/// 
/// <p><METHOD>%DeleteId</METHOD> is identical in operation to the <METHOD>%Delete</METHOD> method except 
/// that it uses and Id value instead of an OID value to find an object.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument. If no value for the <var>concurrency</var>
/// argument is passed or the value passed is -1 then it will be assigned the value of the
/// DEFAULTCONCURRENCY parameter as defined for the class.
ClassMethod %DeleteId(id As %String, concurrency As %Integer = -1) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
..%Delete($$$oidForm(id),.concurrency)
}

/// %AddToSyncSet() adds an object to a sync set.
ClassMethod %AddToSyncSet(objSS As %SYNC.SyncSet, oref As %ObjectHandle = "", fileop As %Integer = 0, oid As %ObjectIdentity = "", changed As %List = "", guid As %String = "", originSystem As %String = "", originNS As %String = "") As %Integer [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code = 0
	If '$$$comMemberKeyGet(%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault) { Quit $$$OK }
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) Quit $$$OK
	Set classtype = $$$getClassType(%class)
	Set property = $$$comMemberNext(%class,$$$cCLASSproperty,""), required = 0, setcoll = 0, setprop = 0, setref = 0, setreq = 0
	While property '= "" {
		Kill origin
		$$$comMemberKeyGetLO(storable,origin,%class,$$$cCLASSproperty,property,$$$cPROPstorable)
		If storable && ('$$$comMemberArrayGet(%class,$$$cCLASSproperty,property,$$$cPROPparameter,"SYNCIGNORE")) {
			Set qp=$$$QuoteName(property),prop=$$$QN(property)
			$$$comMemberKeyGetLO(proptype,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
			Set propclasstype = $$$getClassType(proptype)
			$$$comMemberKeyGetLO(required,origin,%class,$$$cCLASSproperty,property,$$$cPROPrequired)
			$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,property,$$$cPROPcollection)
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

/// %IsNull() returns true if the current object is NULL. A NULL object is one whose serialized value is NULL. This instance method
/// predicts whether or not the serialization of the current object will be NULL and returns TRUE (1) if the serialization will be null.
/// Persistent objects can not ever be NULL since at least the %ID is not null. Streams can return a non-NULL serialization but the stream
/// is determined to be NULL if it has not ever been written to. This method is expected to be overridden by more specific subclasses.
Method %IsNull() As %Boolean [ CodeMode = expression ]
{
0
}

/// Return true if pOID is a null object and false if the object is not null
ClassMethod %ObjectIsNull(pOID As %ObjectIdentity) As %Boolean
{
	if pOID = $$$NULLOID quit 1
	If $isobject(pOID)=1 Quit pOID.%IsNull()
	set class = $$$oidClassName(pOID)
	if class '= "" {
		set class=$$$NormalizeClassname(class) if $classname()'=class quit $classmethod(class,"%ObjectIsNull",pOID)
	}
	set oref=..%Open(pOID) if oref=$$$NULLOREF quit 1
	quit oref.%IsNull()
}

/// %JournalObject constructs a list of properties whose values have changed and records that list in the object journal. No list
/// is constructed if the filing operation is 2 (DELETE). This method also journals the current property values to the object journal global
/// if OBJJOURNAL is 2. This setting is useful for SQL mapped classes or classes using %CustomStorage as it isn't easy to extract the data
/// from the system journal for such classes. This method will invoke %OnJournalObject if it is implemented.
/// 
/// Users should not call this method directly as it is expected to be called by the Object and SQL filers.
Method %JournalObject(tranid As %Integer = 0, jrnid As %Integer = 0, fileop As %Integer = 0, sqlcontext As %Integer = 0, sqlmod As %String = "") As %Integer [ CodeMode = generator, GenerateAfter = %OnJournalObject, Internal, ServerOnly = 1 ]
{
	Set %code = 0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set objjournal = +$$$comMemberKeyGet(%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault)
	If '(objjournal) { Quit $$$OK }
	Set classtype = $$$getClassType(%class)
	Set journalstream=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"JOURNALSTREAM",$$$cPARAMdefault)
		#; The ObjectJournal structure is:
		#; 		^OBJ.Journal(tranid,jrnPtr,property) = <collection><type>_<value>
		#;	where:	<collection>	0 - simple
		#;							1 - list
		#;							2 - array
		#;
		#;			<type>			0 - literal
		#;							1 - persistent
		#;							2 - serial
		#;							4 -	character stream
		#;							5 -	binary stream
	Set property = $$$comMemberNext(%class,$$$cCLASSproperty,""), required = 0, setcoll = 0, setprop = 0, setref = 0, setreq = 0
	While property '= "" {
		Kill origin
		$$$comMemberKeyGetLO(storable,origin,%class,$$$cCLASSproperty,property,$$$cPROPstorable)
		If storable {
			Set qp=$$$QuoteName(property),prop=$$$QN(property)
			$$$comMemberKeyGetLO(propType,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
			Set propclasstype = $$$getClassType(propType)
			$$$comMemberKeyGetLO(required,origin,%class,$$$cCLASSproperty,property,$$$cPROPrequired)
			$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,property,$$$cPROPcollection)
			If classtype = $$$cCLASSCLASSTYPEPERSISTENT {
				Set intColNumber = $Get($$$EXTPROPsqlcolumnnumber($$$pEXT,%class,property))
				If intColNumber '= "" {
					set sqlmodexpr = ")||($Ascii(sqlmod,"_intColNumber_")>0)", sqlcontextexpr = "(('sqlcontext)&&"
				} else { Set sqlmodexpr = "", sqlcontextexpr = "" }
			} else {
				set sqlmodexpr = "", sqlcontextexpr = ""
			}
			If objjournal = 1 {
				If propclasstype = $$$cCLASSCLASSTYPESTREAM {
					If journalstream {
						Set setprop = setprop + 1, setprop(setprop) = "If "_sqlcontextexpr_"((.."_$$$QN(property_"IsModified")_"())||(($isobject(r%"_prop_")=1)))"_sqlmodexpr_" { Set changed=changed_$lb("_qp_") }"
					}
				} else {
					Set setprop = setprop + 1, setprop(setprop) = "If "_sqlcontextexpr_"(.."_$$$QN(property_"IsModified")_"())"_sqlmodexpr_" { Set changed=changed_$lb("_qp_") }"
				}
			} elseif objjournal = 2 {
				If propclasstype = $$$cCLASSCLASSTYPEDATATYPE {
					If collection = "" { Set setprop = setprop + 1, setprop(setprop) = "If "_sqlcontextexpr_"(.."_$$$QN(property_"IsModified")_"())"_sqlmodexpr_" { Set ^OBJ.Journal(tranid,iPtr,"_qp_") = ""00""_oref."_prop_",changed=changed_$lb("_qp_") }" }
					Else { Set setcoll = setcoll + 1, setcoll(setcoll) = "If "_sqlcontextexpr_"(.."_$$$QN(property_"IsModified")_"())"_sqlmodexpr_" { Set changed=changed_$lb("_qp_"), key = """", elem = oref."_prop_".GetNext(.key) Set:key'="""" ^OBJ.Journal(tranid,iPtr,"_qp_") = """ _ $Case(collection,$$$cPROPCOLLECTIONLIST: 1, $$$cPROPCOLLECTIONARRAY: 2, :3) _ "0"" While key '= """" { Set ^OBJ.Journal(tranid,iPtr,"_qp_",key) = elem, elem = oref."_prop_".GetNext(.key) } }" }
				} elseif propclasstype = $$$cCLASSCLASSTYPEPERSISTENT {
					if collection = "" {
							// We need to know if the instance value is in OID form or simple ID form
						set classinoid = +$$$comMemberArrayGet(%class,$$$cCLASSproperty,property,$$$cPROPparameter,"CLASSNAME")
						if classinoid {
							set oidExpr = "$Get(i%"_prop_")"
						} else {
							set oidExpr = "$Select($Get(i%"_prop_")'="""":##class("_propType_").%ComposeOid(i%"_prop_"),1:"""")"
						}
						set setprop = setprop + 1
						set setprop(setprop) = "If "_sqlcontextexpr_"(.."_$$$QN(property_"IsModified")_"())"_sqlmodexpr_"  { Set ^OBJ.Journal(tranid,iPtr,"_qp_") = ""01"" _ $s($isobject(r%"_prop_")=1:.."_prop_".%Oid(),1:"_oidExpr_"),changed=changed_$lb("_qp_") }"
					} elseif (collection = $$$cPROPCOLLECTIONLIST) || (collection = $$$cPROPCOLLECTIONARRAY) {
						set setcoll = setcoll + 1
						set setcoll(setcoll) = "If "_sqlcontextexpr_"(.."_$$$QN(property_"IsModified")_"())"_sqlmodexpr_" { Set changed=changed_$lb("_qp_"), key = """", elem = oref."_prop_".GetNext(.key) Set:key'="""" ^OBJ.Journal(tranid,iPtr,"_qp_") = """ _ $Case(collection,$$$cPROPCOLLECTIONLIST: 1, $$$cPROPCOLLECTIONARRAY: 2, :3) _ "1"" While key '= """" { Set ^OBJ.Journal(tranid,iPtr,"_qp_",key) = $Select($Isobject(elem):elem.%Oid(),1:""""), elem = oref."_prop_".GetNext(.key) } }"
					}
				} elseif propclasstype = $$$cCLASSCLASSTYPESERIAL {
					If collection = "" {
						set setprop = setprop + 1
						set setprop(setprop) = "If "_sqlcontextexpr_"((.."_$$$QN(property_"IsModified")_"())||(($isobject(r%"_prop_")=1)&&(.."_prop_".%IsModified())))"_sqlmodexpr_" { Set ^OBJ.Journal(tranid,iPtr,"_qp_") = ""02"" _ oref."_prop_".%JournalObject(tranid,fileop),changed=changed_$lb("_qp_") }"
					} elseif (collection = $$$cPROPCOLLECTIONLIST) || (collection = $$$cPROPCOLLECTIONARRAY) {
						Set setcoll = setcoll + 1
						set setcoll(setcoll) = "If "_sqlcontextexpr_"(.."_$$$QN(property_"IsModified")_"())"_sqlmodexpr_" { Set changed=changed_$lb("_qp_"),key = """", elem = oref."_prop_".GetNext(.key) Set:key'="""" ^OBJ.Journal(tranid,iPtr,"_qp_") = """ _ $Case(collection,$$$cPROPCOLLECTIONLIST: 1, $$$cPROPCOLLECTIONARRAY: 2, :3) _ "2"" While key '= """" { Set ^OBJ.Journal(tranid,iPtr,"_qp_",key) = $Select($Isobject(elem):elem.%JournalObject(tranid,fileop),1:""""), elem = oref."_prop_".GetNext(.key) } }"
					}
				} ElseIf propclasstype = $$$cCLASSCLASSTYPESTREAM {
					If journalstream {
						Set setprop = setprop + 1
						set setprop(setprop) = "If "_sqlcontextexpr_"((.."_$$$QN(property_"IsModified")_"())||(($isobject(r%"_prop_")=1)))"_sqlmodexpr_" { Set ^OBJ.Journal(tranid,iPtr,"_qp_")=""04"",changed=changed_$lb("_qp_") }"
					}
				}
				Else { Set setprop = setprop + 1, setprop(setprop) = "If "_sqlcontextexpr_"(.."_property_"IsModified())"_sqlmodexpr_" { Set ^OBJ.Journal(tranid,iPtr,"""_property_""") = ""01"" _ oref."_property_",changed=changed_$lb("""_property_""") }" }
			}
		}
		Set property = $$$comMemberNext(%class,$$$cCLASSproperty,property)
	}
	$$$comMemberKeyGetLvar(onjournal,%class,$$$cCLASSmethod,"%OnJournalObject",$$$cMETHrunnable)
		// Generate the method starting here
	If classtype = $$$cCLASSCLASSTYPEPERSISTENT {
		If objjournal = 1 {
			If onjournal {
				$$$GENERATE("	If fileop = 2 { Do ..%OnJournalObject(tranid,jrnid,.filter) If filter '= """" Set ^OBJ.JournalT(tranid,jrnid,""%%FILTER"")=filter Quit """" }")
			} else {
				$$$GENERATE("	If fileop = 2 { Quit """" }")
			}
			$$$GENERATE("	Set oref = $this, changed = """", iPtr = """"")
		} else {
			$$$GENERATE("	Set oref = $this, changed = """", iPtr = $Increment(^OBJ.Journal),^OBJ.Journal(tranid,iPtr) = $ListBuild("""",$classname(),fileop,oref.%Oid())")
			If onjournal {
				$$$GENERATE("	If fileop = 2 { Do ..%OnJournalObject(tranid,jrnid,.filter) If filter '= """" Set ^OBJ.JournalT(tranid,jrnid,""%%FILTER"")=filter Quit iPtr }")
			} Else {
				$$$GENERATE("	If fileop = 2 { Quit iPtr }")
			}
		}
	} else {
		if objjournal = 1 {
			$$$GENERATE("	Set oref = $this, changed = """", iPtr = """"")
		} else {
			$$$GENERATE("	Set oref = $this, changed = """", iPtr = $Increment(^OBJ.Journal),^OBJ.Journal(tranid,iPtr) = $ListBuild("""",$classname(),fileop,"""")")
		}
		if classtype = $$$cCLASSCLASSTYPESERIAL {
				// We need to check to see if there are modbits that we can temporarily restore. Since serial objects are 
				// only ever journalled from a container, the serialization of the serial object is already complete and 
				// modbits cleared by the time %JournalObject sees it. By checking the save graph/transaction state, we 
				// can discover which, if any, properties of the serial object were modified prior to serialization.
			$$$GENERATE($Char(9)_"if $data($$$txMODIFIED($this)) {")
			$$$GENERATE($Char(9,9)_"set modrestore = 1")
			$$$GENERATE($Char(9,9)_"set modbits = $system.CLS.GetModifiedBits($this)")
			$$$GENERATE($Char(9,9)_"do $system.CLS.SetModifiedBits($$$txMODIFIED($this))")
			$$$GENERATE($Char(9)_"} else {")
			$$$GENERATE($Char(9,9)_"set modrestore = 0")
			$$$GENERATE($Char(9)_"}")
		}
	}
		// Generate the property (state) journaling code
	If setprop {
		Set setline = $c(9) _ setprop(1) For ptr = 2:1:setprop { If ($Length(setprop(ptr)) + $Length(setline)) < 2000 { Set setline = setline _ " " _ setprop(ptr) }Else { $$$GENERATE(setline) Set setline = $c(9) _ setprop(ptr) }}
		If setline '= "" {
			$$$GENERATE(setline)
		}
	}
	For ptr = 1:1:setcoll {
		$$$GENERATE($c(9) _ setcoll(ptr))
	}
		// And wrap it up - finish the journaling process and restore anything that we may be temporarily altered here.
	if classtype '= $$$cCLASSCLASSTYPESERIAL {
		$$$GENERATE("	If changed'="""" { Set ^OBJ.JournalT(tranid,jrnid,""%%CHANGED"")=changed }")
		If onjournal {
			$$$GENERATE("	Do ..%OnJournalObject(tranid,jrnid,.filter) If filter '= """" Set ^OBJ.JournalT(tranid,jrnid,""%%FILTER"")=filter")
		}
	} else {
			// We need to check to see if there are modbits that we can temporarily restore. Since serial objects are 
			// only ever journalled from a container, the serialization of the serial object is already complete and 
			// modbits cleared by the time %JournalObject sees it. By checking the save graph/transaction state, we 
			// can discover which, if any, properties of the serial object were modified prior to serialization.
		$$$GENERATE($Char(9)_"if modrestore {")
		$$$GENERATE($Char(9,9)_"do $system.CLS.SetModifiedBits(modbits)")
		$$$GENERATE($Char(9)_"}")
	}
	$$$GENERATE("	Quit iPtr")
	Quit $$$OK
}

/// This method should be implemented by the user. This method is invoked by %SYNC.SyncSet.Import when the object being imported
/// has been modified on the local system since the last time it was synchronized with the system which produced the SyncSet.
/// Passed to this method are the oid of the conflicting object, and oref to the SyncSet containing the version to sync to, and the pointer
/// to this object in the SyncSet. It is the responsibility of this method to either resolve the conflict and process the resolved object or
/// to return a failure status to the caller. The resolved object can be processed by saving, invoking the %SyncObjectIn method or by whatever
/// means the class author deems appropriate. If a failure status is returned to %SYNC.SyncSet.Import then the object will be requeued in the SyncSet.
/// That might result in another call at a later time to this method.
/// 
ClassMethod %ResolveConcurrencyConflict(oid As %ObjectIdentity, objSS As %SYNC.SyncSet, iPtr As %Integer, ByRef bAcceptYours As %Boolean = 0) As %Status [ ServerOnly = 1 ]
{
	Quit $$$ERROR($$$MethodNotImplemented,$classname()_"::%ResolveConcurrencyConflict")
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
ClassMethod %SyncObjectIn(objSS As %SYNC.SyncSet, iPtr As %Integer, ByRef oref As %ObjectHandle, fileop As %Integer = 0) As %Status [ CodeMode = generator, ServerOnly = 1 ]
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
		Kill origin
		$$$comMemberKeyGetLO(storable,origin,%class,$$$cCLASSproperty,property,$$$cPROPstorable)
		If (storable) && ('$$$comMemberArrayGet(%class,$$$cCLASSproperty,property,$$$cPROPparameter,"SYNCIGNORE")) {
			Set qp=$$$QuoteName(property),prop=$$$QN(property)
			$$$comMemberKeyGetLO(proptype,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
			Set propclasstype = $$$getClassType(proptype)
			$$$comMemberKeyGetLO(required,origin,%class,$$$cCLASSproperty,property,$$$cPROPrequired)
			$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,property,$$$cPROPcollection)
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
						Set setrcoll = setrcoll + 1, setrcoll(setrcoll) = "If $d(@%objsync@(iPtr,"_qp_")) { s key="""",temp("_qp_")="""" f  s key=$o(@%objsync@(iPtr,"_qp_",key)) q:key=""""  s rguid=$Get(@%objsync@(iPtr,"_qp_",key)) If rguid'="""" { Set sc=##class("_$$$QN(proptype)_").%SyncObjectIn(objSS,rguid,.soref) If soref'="""" { s temp(" _ qp _ ",key)=soref } Else { Set suspend=1 Quit } } Else { Set temp("_qp_",key)="""" } }"
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
#;Resolve object valued properties. Any optional object references which cannot be resolved are suspended....

		#;Instantiate the class
	If classtype = $$$cCLASSCLASSTYPEPERSISTENT {
		$$$GENERATE("	If guid '= """" { Set oid = ##class(%GUID).%GUIDFind(guid) } Else { Quit $$$ERROR($$$NullGUID,$classname()) }")
		$$$GENERATE("	If fileop = 2 { If (oid '= """") && (..%Exists(oid)) { Quit ..%Delete(oid) } Else { Quit $$$OK }}")
		$$$GENERATE("	If oid '= """" && ('..%Exists(oid)) { Set oid=""""}")
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

/// %SyncTransport uses a JITGenerated routine to extract an object from the transporter into the current database.
Method %SyncTransport(pOID As %Library.ObjectIdentity, pTransporterRtn As %Library.RawString = "", pTransportGlobal As %Library.RawString = "", pTransportPtr As %Library.Integer = 0, pTransporter As %SYNC.Transporter = "", ByRef pUnresolved As %Library.RawString = "") As %Status [ ServerOnly = 1 ]
{
	try {
		set tImportOID = $$import^@(pTransporterRtn)(pOID,pTransportGlobal,pTransportPtr,pTransporter,.pUnresolved)
		set tSC = $$$OK
	}
	catch tException {
		set tSC = tException.AsStatus()
	}
	quit tSC
}

/// This callback method is invoked by the <METHOD>%JournalObject</METHOD> method to 
/// construct the %%FILTER value. %%FILTER is placed in the journal, exported with
/// a SyncSet and is made available when importing the SyncSet.
/// 
Method %OnJournalObject(tranid As %Integer, jrnid As %Integer, ByRef filter As %String) As %Status [ Abstract, Private, ServerOnly = 1 ]
{
}

/// Should be overridden in classes using filtering for synchronization
ClassMethod %OnBeforeAddToSync(guid As %String, filterObject As %ObjectHandle, filingType As %Integer, filter As %String(MAXLEN=32000)) As %Boolean [ ServerOnly = 1 ]
{
	Quit 0
}

/// This callback method is invoked by the <METHOD>%Open</METHOD> method to 
/// determine the classname of the object specified by <VAR>oid</VAR>.
ClassMethod %OnDetermineClass(oid As %ObjectIdentity, ByRef class As %String) As %Status [ Abstract, ServerOnly = 1 ]
{
	Set class=$classname()
	Quit $$$OK
}

}
