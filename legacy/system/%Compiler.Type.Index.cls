/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class Member Class: Index
Class %Compiler.Type.Index [ NoContext, Not ProcedureBlock, System = 2 ]
{

/// <index>Exists()
/// 	This method returns true if an object whose index key value matches the value/values passed
/// 	in by the caller. The optional byref id parameter will contain the id matching the object that
/// 	was found to match the index key value upon a successful return.
ClassMethod Exists(ByRef id As %String = "") As %Boolean [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 0 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault) QUIT $$$OK
		#; don't generate for EXTENT, and BITMAP indices:
	if ($$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXextent))||($$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXtype)="bitmap") { QUIT $$$OK }
	if '$$projectIndex^%occIndex(%class,%property) QUIT $$$OK
	set cardinality = $Get($$$EXTIDXlogicalcardinality($$$pEXT,%class,%property),1)
	$$$comMemberKeyGetLvar(isIdkey,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
		#; Start with the defined formal spec and serialize it
	$$$comSubMemberKeyGetLvar(formalSpec,%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspec)
	set sc=$$serializeFormal^%occName(%class,"method",%class_"."_%method,formalSpec,.formal) q:$$$ISERR(sc)
	if isIdkey {
		if cardinality = 1 { set formal2 = $lb($lb("K1","%Library.RawString","","",)), keySerial = "K1" }
		else {
			set formal2 = "", keySerial = ""
			for tPtr = 1:1:cardinality { set formal2 = formal2_$lb($lb("K"_tPtr,"%Library.RawString","","",)), keySerial = keySerial _ "_""||""_K"_tPtr }
			set keySerial = $Extract(keySerial,7,*)
		}
			#; Reset the formal list to the index declaration:
		set formal = formal2 _ formal
		$$$comSubMemberKeySet(%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspecparsed,formal)
		set sc=$$SetOneIndexMeth^%occIndex(%class,%property,%method)
		$$$GENERATE($Char(9)_"s id="_keySerial_" q ..%ExistsId("_keySerial_")")
	} else {
		$$$comMemberKeyGetLvar(prop,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		set formal2 = "", stream=0
		for tPtr = 1:1:prop {
			$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,tPtr,$$$cINDEXPROPproperty)
			if property '= "" {
					#; Strip the quotes of a delimited property name
				if $Extract(property) = """" {
					set property = $Replace($Extract(property,2,*-1),"""""","""")
				}
				$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				if type'="",$$$getClassType(type)=$$$cCLASSCLASSTYPESTREAM Set stream=1 Quit
				if type = "" { Set type = $Get($$$EXTPROPtype($$$pEXT,%class,property)) }
				if type'="",$$$getClassType(type)=$$$cCLASSCLASSTYPEPERSISTENT set type="%Library.RawString"
				set formal2 = formal2_$lb($lb("K"_tPtr,type,"","",))
			}
		}
		#; Do not generate indexExists method if one of the properties is a stream
		if stream Quit $$$OK
			#; Reset the formal list to the index declaration:
		set formal = formal2 _ formal
		$$$comSubMemberKeySet(%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspecparsed,formal)
		set sc=$$SetOneIndexMeth^%occIndex(%class,%property,%method) QUIT:$$$ISERR(sc) sc
		set method=$$$nameMemberMethodName(%property,"Exists")
			#; Check to see if the storage compiler left any code lying around...
		If $Data($$$tEXTcode(method)) {	merge %code=$$$tEXTcode(method) }
		ElseIf $$$comMemberKeyGet(%class,$$$cCLASSparameter,"SQLENABLED",$$$cPARAMdefault) {
				#; If not, see if this class is projected to SQL...
			$$$comClassKeyGetLvar(qtable,%class,$$$cCLASSsqlqualifiednameQ)
			set tNullCheck = "", tWhere = "", tWhereNull1 = "", tWhereNull2 = ""
			$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,1,$$$cINDEXPROPproperty)
				#; This is a temporary line to allow IVA indices to compile cleanly w/o SQL projection
				#; skip this method if the index contains subvalues
			if property["(" {
				goto Exit
			}
				#; Strip the quotes of a delimited property name
			if $Extract(property) = """" {
				set property = $Replace($Extract(property,2,*-1),"""""","""")
			}
				// Code generation of the query is based on index definition and nullability (required) of each property in the key
			set sc = $$QuoteId^%occStorage($g($$$EXTPROPsqlcolumnname($$$pEXT,%class,property)),"SQL column",.column) q:$$$ISERR(sc)

			if prop = 1 {
				set tWhere = "(:K1 is not null and "_column_" = :K1) OR (:K1 IS NULL AND "_column_" IS NULL)"
			} else {
					// Multiple columns in the key
				if ($$$comMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPrequired)) {
					set tWhere = "(" _ column _" = :K1)"
				} else {
					set tWhere = "((" _ column _ "=:K1 OR " _ column _ " IS NULL) AND (" _ column _ "=:K1 or (:K1 IS NULL AND " _ column _ " IS NULL)))"
				}
				for tPtr=2:1:prop {
					$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,tPtr,$$$cINDEXPROPproperty)
						#; skip this method if the index contains subvalues
					if property["(" {
						goto Exit
					}
						#; Strip the quotes of a delimited property name
					if $Extract(property) = """" {
						set property = $Replace($Extract(property,2,*-1),"""""","""")
					}
					set sc=$$QuoteId^%occStorageUtil($g($$$EXTPROPsqlcolumnname($$$pEXT,%class,property)),.column) if $$$ISERR(sc) { goto Exit }
					if ($$$comMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPrequired)) {
						set tWhere = tWhere _ " AND ("_column_" = :K" _ tPtr _ ")"
					}
					else {
						set tWhere = tWhere _ " AND ((" _ column _ "=:K" _ tPtr _ " OR " _ column _ " IS NULL) AND ((" _ column _ "=:K" _ tPtr _ ") OR (:K" _ tPtr _ " IS NULL AND " _ column _ " IS NULL)))"
					}
				}
			}
			$$$GENERATE($Char(9)_"&sql(SELECT %ID INTO :id FROM "_qtable_" WHERE "_tWhere_")")
			$$$GENERATE($Char(9)_"Quit $select('SQLCODE:1,1:0)")
		}
		if '%code $$$GENERATE($Char(9)_"QUIT 0")
	}
Exit
	QUIT sc
}

/// <key>Check()
/// 	This method checks for the existence of the key and locks the object associated with that key.
/// 
/// 	The optional lockonly parameter is used to validate the key. If lockonly is true then we just want
/// 	to acquire/release a lock for the id associated with the key value. If the key value doesn't exist then
/// 	lockonly causes a success status to be returned, otherwise failure is returned. If lockonly is not true
/// 	then the id associated with the key is looked up, if found the associated object is locked/released.
/// 	Also, the key is validated again after the lock is acquired.
/// 
/// 		A %Status value is returned.
ClassMethod Check(lockonly As %Integer = 0, concurrency As %Integer = -1) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
		#; only generate for unique index (key):
	$$$comMemberKeyGetLvar(isIdkey,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
	if '$$projectIndex^%occIndex(%class,%property) Quit $$$OK
	if ($$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXextent))||($$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXtype)="bitmap")||(('isIdkey)&&('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXprimarykey))&&('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXunique))) { QUIT $$$OK }
	set cardinality = $Get($$$EXTIDXlogicalcardinality($$$pEXT,%class,%property),1)
		#; Start with the defined formal spec and serialize it
	$$$comSubMemberKeyGetLvar(formalSpec,%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspec)
	set sc=$$serializeFormal^%occName(%class,"method",%class_"."_%method,formalSpec,.formal) q:$$$ISERR(sc)
	if isIdkey {
		if cardinality = 1 { set formal2 = $lb($lb("K1","%Library.RawString","","",)), keySerial = "K1" }
		else {
			set formal2 = "", keySerial = ""
			for tPtr = 1:1:cardinality { set formal2 = formal2_$lb($lb("K"_tPtr,"%Library.RawString","","",)), keySerial = keySerial _ "_""||""_K"_tPtr }
			set keySerial = $Extract(keySerial,7,*)
		}
			#; Reset the formal list to the index declaration:
		set formal = formal2 _ formal
		$$$comSubMemberKeySet(%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspecparsed,formal)
		set sc=$$SetOneIndexMeth^%occIndex(%class,%property,%method)
		$$$GENERATE($Char(9)_"s id="_keySerial_",exists=..%ExistsId(id) q:'exists $s('lockonly:$$$ERROR($$$KeyNotFound,$classname(),"""_%property_""",id),1:$$$OK) s:concurrency=-1 concurrency=$select(..#DEFAULTCONCURRENCY=""$zu(115,10)"":$zu(115,10),1:$xecute(""q ""_..#DEFAULTCONCURRENCY)) if concurrency { s status=..%LockId(id,1) q:$$$ISERR(status) status } if 'lockonly { s exists=..%ExistsId(id) d:concurrency ..%UnlockId(id,1,0) quit $s('exists:$$$ERROR($$$KeyNotFound,$classname(),"""_%property_""",id),1:$$$OK) } else { d:concurrency ..%UnlockId(id,1,0) q $$$OK }")
	}
	else {
		$$$comMemberKeyGetLvar(prop,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		set formal2 = "",existsArgs = "", keySerial = ""
		for tPtr = 1:1:prop {
			$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,tPtr,$$$cINDEXPROPproperty)
			if property '= "" {
					#; Strip the quotes of a delimited property name
				if $Extract(property) = """" {
					set property = $Replace($Extract(property,2,*-1),"""""","""")
				}
				$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				if type = "" { Set type = $Get($$$EXTPROPtype($$$pEXT,%class,property)) }
				if type'="",$$$getClassType(type)=$$$cCLASSCLASSTYPEPERSISTENT set type="%Library.RawString"
				set formal2 = formal2_$lb($lb("K"_tPtr,type,"","",))
				set existsArgs = existsArgs _ "K"_tPtr_",", keySerial = keySerial _ "_""||""_K"_tPtr
			}
		}
		set keySerial = $Extract(keySerial,7,*)
			#; Reset the formal list to the index declaration:
		set formal = formal2 _ formal
		$$$comSubMemberKeySet(%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspecparsed,formal)
		set sc=$$SetOneIndexMeth^%occIndex(%class,%property,%method) QUIT:$$$ISERR(sc) sc
		set existsMethod=$$$nameMemberMethodName(%property,"Exists")
		set existsCall = ".."_$$$QN(existsMethod)_"("_existsArgs
		$$$GENERATE($Char(9)_"s exists="_existsCall_".id) q:'exists $s('lockonly:$$$ERROR($$$KeyNotFound,$classname(),"""_%property_""","_keySerial_"),1:$$$OK) s:concurrency=-1 concurrency=$select(..#DEFAULTCONCURRENCY=""$zu(115,10)"":$zu(115,10),1:$xecute(""q ""_..#DEFAULTCONCURRENCY)) if concurrency { s status=..%LockId(id,1) q:$$$ISERR(status) status } if 'lockonly { s exists="_existsCall_".idcheck) d:concurrency ..%UnlockId(id,1,0) quit $s(('exists)||(id'=idcheck):$$$ERROR($$$KeyNotFound,$classname(),"""_%property_""","_keySerial_"),1:$$$OK) } else { d:concurrency ..%UnlockId(id,1,0) q $$$OK }")
	}
Exit
	QUIT sc
}

/// <p>The index Open method is generated as a member method for for unique and primary key indices as well as an IDKEY index based on more than one index property.
/// This method, Open, will open the object whose index property values match the supplied values. If no object that matches the supplied values is found
/// then if the optional status parameter is set to an error message. This interface is the same as %OpenId except that <index>Open accepts one parameter
/// corresponding to each property in the index. For example:</p><br>
/// <pre>
///    Set person = ##class(Sample.Person).SSNKeyOpen("111-22-3333",2,.sc)
/// </pre>
/// <br>
/// <p>
/// Upon successful execution, person will be the oref that references an instance of Sample.Person whose SSN property value is "111-22-3333".
/// The concurrency value is 2 and, if an error occurred its value will be in the variable <var>sc</var>.</p>
ClassMethod Open(concurrency As %Integer = -1, ByRef sc As %Status = {$$$OK}) As %ObjectHandle [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 0 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	$$$comMemberKeyGetLO(prop,origin,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		#; only generate for candidate keys - IDKEY, PRIMARYKEY and UNIQUE:
	$$$comMemberKeyGetLO(isIdkey,origin,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
	$$$comMemberKeyGetLO(isUnique,origin,%class,$$$cCLASSindex,%property,$$$cINDEXunique)
	$$$comMemberKeyGetLO(isPrimary,origin,%class,$$$cCLASSindex,%property,$$$cINDEXprimarykey)
	if ('isUnique) && ('isIdkey) && ('isPrimary) { Quit $$$OK }
	set cardinality = $Get($$$EXTIDXlogicalcardinality($$$pEXT,%class,%property),1)
		#; Reset the formal list to the index declaration:
		#; Start with the defined formal spec and serialize it
	$$$comSubMemberKeyGetLvar(formalSpec,%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspec)
	set sc=$$serializeFormal^%occName(%class,"method",%class_"."_%method,formalSpec,.formal) q:$$$ISERR(sc)
	set existscall="", formal2=""
	if isIdkey {
			#; If the idkey is simple then just dispatch to %OpenId():
		if (cardinality = 1) {
			set formal2 = $lb($lb("K1","%Library.RawString","","",))
			set %code="..%OpenId(.K1,concurrency,.sc)",%codemode=$$$cMETHCODEMODEEXPRESSION
		}
		else {
			set formal2 = "", keySerial = ""
			for tPtr = 1:1:cardinality { set formal2 = formal2_$lb($lb("K"_tPtr,"%Library.RawString","","",)), keySerial = keySerial _ "_""||""_K"_tPtr }
			set keySerial = $Extract(keySerial,7,$Length(keySerial))
			Set %code = "..%OpenId("_keySerial_",concurrency,.sc)",%codemode=$$$cMETHCODEMODEEXPRESSION
		}
		set formal = formal2 _ formal
	}
	else {
		set keyDisplay = ""
		for tPtr = 1:1:prop {
			$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,tPtr,$$$cINDEXPROPproperty)
			if property '= "" {
					#; Strip the quotes of a delimited property name
				if $Extract(property) = """" {
					set property = $Replace($Extract(property,2,*-1),"""""","""")
				}
	 			$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				If type = "" { Set type = $Get($$$EXTPROPtype($$$pEXT,%class,property)) }
				if type'="",$$$getClassType(type)=$$$cCLASSCLASSTYPEPERSISTENT set type="%Library.RawString"
	 			Set formal2=formal2_$lb($lb("K"_tPtr,type,"","",)),existscall=existscall_"K"_tPtr_",", keyDisplay = keyDisplay _ "_"":""_K"_tPtr
			}
		}
		set formal=formal2_formal, keyDisplay = $Extract(keyDisplay,6,*)
		set existscall=".."_$$$QN($$$nameMemberMethodName(%property,"Exists"))_"("_existscall_".id)"
		$$$GENERATE(" i "_existscall_"{ s return=..%OpenId(id,concurrency,.sc) } Else { s sc=$$$ERROR($$$KeyValueNotFoundOpen,"""_%property_""","_keyDisplay_"),return=$$$NULLOREF }")
		$$$GENERATE(" QUIT return")
	}
	set method=$$$nameMemberMethodName(%property,"Open")
		#; Check to see if the storage compiler left any code lying around...
		#; if so then discard what we generated, reset the formal spec and take what the compiler left us
	If $Data($$$tEXTcode(method)) { kill %code m %code=$$$tEXTcode(method) }
	$$$comSubMemberKeySet(%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspecparsed,formal)
	$$$comSubMemberKeySet(%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHreturntype,%class)
	set sc=$$SetOneIndexMeth^%occIndex(%class,%property,%method)
	QUIT sc
}

ClassMethod Delete(concurrency As %Integer = -1) As %Status [ CodeMode = generator, GenerateAfter = Open, ProcedureBlock = 1, ServerOnly = 0 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
	#; don't generate any code if Open() is not there
	If $$$comSubMemberDefined(%class,$$$cCLASSindex,%property,$$$cPROPmethod,"Open")=0 QUIT $$$OK
	$$$comMemberKeyGetLO(prop,origin,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		#; only generate for candidate keys - IDKEY, PRIMARYKEY and UNIQUE:
	$$$comMemberKeyGetLO(isIdkey,origin,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
	set cardinality = $Get($$$EXTIDXlogicalcardinality($$$pEXT,%class,%property),1)
		#; Reset the formal list to the index declaration:
		#; Start with the defined formal spec and serialize it
	$$$comSubMemberKeyGetLvar(formalSpec,%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspec)
	set sc=$$serializeFormal^%occName(%class,"method",%class_"."_%method,formalSpec,.formal) q:$$$ISERR(sc)
	set existscall="", formal2=""
	if isIdkey {
			#; If the idkey is simple then just dispatch to %DeleteId():
		if (cardinality = 1) {
			set formal2 = $lb($lb("K1","%Library.RawString","","",))
			set %code="..%DeleteId(.K1,concurrency)",%codemode=$$$cMETHCODEMODEEXPRESSION
		}
		else {
			set formal2 = "", keySerial = ""
			for tPtr = 1:1:cardinality { set formal2 = formal2_$lb($lb("K"_tPtr,"%Library.RawString","","",)), keySerial = keySerial _ "_""||""_K"_tPtr }
			set keySerial = $Extract(keySerial,7,*)
			Set %code = "..%DeleteId("_keySerial_",concurrency)",%codemode=$$$cMETHCODEMODEEXPRESSION
		}
		set formal = formal2 _ formal
	}
	else {
		set keyDisplay = ""
		for tPtr = 1:1:prop {
			$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,tPtr,$$$cINDEXPROPproperty)
			if property '= "" {
					#; Strip the quotes of a delimited property name
				if $Extract(property) = """" {
					set property = $Replace($Extract(property,2,*-1),"""""","""")
				}
	 			$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				If type = "" { Set type = $Get($$$EXTPROPtype($$$pEXT,%class,property)) }
				if type'="",$$$getClassType(type)=$$$cCLASSCLASSTYPEPERSISTENT set type="%Library.RawString"
				Set formal2=formal2_$lb($lb("K"_tPtr,type,"","",)),existscall=existscall_"K"_tPtr_",", keyDisplay = keyDisplay _ "_"":""_K"_tPtr
			}
		}
		set formal=formal2_formal, keyDisplay = $Extract(keyDisplay,6,*)
		set existscall=".."_$$$QN($$$nameMemberMethodName(%property,"Exists"))_"("_existscall_".id)"
		$$$GENERATE($Char(9)_"i "_existscall_"{ s sc=..%DeleteId(id,concurrency) } Else { s sc=$$$ERROR($$$KeyValueNotFoundDelete,"""_%property_""","_keyDisplay_") }")
		$$$GENERATE($Char(9)_"QUIT sc")
	}
	set method=$$$nameMemberMethodName(%property,"Delete")
		#; Check to see if the storage compiler left any code lying around...
		#; if so then discard what we generated, reset the formal spec and take what the compiler left us
	If $Data($$$tEXTcode(method)) { kill %code m %code=$$$tEXTcode(method) }
	$$$comSubMemberKeySet(%class,$$$cCLASSindex,%property,$$$cINDEXmethod,%method,$$$cMETHformalspecparsed,formal)
	set sc=$$SetOneIndexMeth^%occIndex(%class,%property,%method)
	QUIT sc
}

ClassMethod SQLExists(pLockOnly As %Boolean = 0, ByRef pUnlockRef As %String, %pVal... As %String) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	$$$comMemberKeyGetLvar(prop,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		#; only generate for candidate keys - IDKEY, PRIMARYKEY and UNIQUE:
	$$$comMemberKeyGetLvar(isIdkey,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
	if ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXunique)) && ('isIdkey) && ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXprimarykey)) { Quit $$$OK }
	$$$GENERATE(" QUIT $$$ERROR($$$MethodNotImplemented,""%Persistent::"_%property_"SQLExists"")")
	// This is just a stub that will be overwritten by code in %ocsCacheSQLFiler2
	QUIT $$$OK
}

ClassMethod SQLCheckUnique(pFromOrig As %Boolean = 0, %pID As %String, %pVals... As %String) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	$$$comMemberKeyGetLvar(prop,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		#; only generate for candidate keys - IDKEY, PRIMARYKEY and UNIQUE:
	$$$comMemberKeyGetLvar(isIdkey,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
	if ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXunique)) && ('isIdkey) && ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXprimarykey)) { Quit $$$OK }
	$$$GENERATE(" QUIT $$$ERROR($$$MethodNotImplemented,""%Persistent::"_%property_"SQLCheckUnique"")")
	// This is just a stub that will be overwritten by code in %ocsCacheSQLFiler2
	QUIT $$$OK
}

ClassMethod SQLFindPKeyByConstraint(%con As %String) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	$$$comMemberKeyGetLvar(prop,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		#; only generate for candidate keys - UNIQUE:
	$$$comMemberKeyGetLvar(isIdkey,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
	if ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXunique)) && ('isIdkey) && ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXprimarykey)) { Quit $$$OK }
	$$$GENERATE(" QUIT $$$ERROR($$$MethodNotImplemented,""%Persistent::"_%property_"SQLFindPKeyByConstraint"")")
	// This is just a stub that will be overwritten by code in %ocsCacheSQLFiler2
	QUIT $$$OK
}

ClassMethod SQLFindRowIDByConstraint(%con As %String, pInternal As %Boolean = 0) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	$$$comMemberKeyGetLvar(prop,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
		#; only generate for candidate keys - UNIQUE, PKEY, IDKEY:
	$$$comMemberKeyGetLvar(isIdkey,%class,$$$cCLASSindex,%property,$$$cINDEXidkey)
	if ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXunique)) && ('isIdkey) && ('$$$comMemberKeyGet(%class,$$$cCLASSindex,%property,$$$cINDEXprimarykey)) { Quit $$$OK }
	$$$GENERATE(" QUIT $$$ERROR($$$MethodNotImplemented,""%Persistent::"_%property_"SQLFindRowIDByConstraint"")")
	// This is just a stub that will be overwritten by code in %ocsCacheSQLFiler2
	QUIT $$$OK
}

}
