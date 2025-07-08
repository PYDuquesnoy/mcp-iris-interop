/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Property superclass for object values, for internal use only
Class %Compiler.Type.Object Extends %Compiler.Type.Literal [ NoContext, System = 1 ]
{

/// A logical value determines if classnames of referenced properties are stored.
/// 0 - store only the ID;
/// 1 - store the two element form of the OID
/// 2 - store the three element form of the OID (applies only to streams currently)
Parameter CLASSNAME As INTEGER [ Constraint = "0,1,2", Flags = ENUM ] = 0;

/// Returns an oref, performing swizzling if necessary
/// it returns "" ($$$NULLOREF) if there is no oref and the id=""
Method Get() As %RawString [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLO(sqlcomputed,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If sqlcomputed,calculated {
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
		Set strIDExpr = $Select($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT:"$$$idCurrent",1:"""""")
			#; Construct the Compute() method parameter list using in-memory props as actual args
		$$$comMemberKeyGetLO(lstRefs,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputedependency)
		set strComputeParms = "" For ptr = 1:1:$ListLength(lstRefs) {
			set parmProp = $List(lstRefs,ptr)
				#; Quote the property name elements in the dotted expression and compute the typeclass of the last dotted expression
			set tParameterType = %class, qparmProp=""
			if parmProp [ "." {
				set tParamExpression = ".."
				set tParamElementCount = $length(parmProp,".")
				For i=1:1:tParamElementCount - 1 {
					set tParamElement = $Piece(parmProp,".",i)
					if $$$comMemberDefined(tParameterType,$$$cCLASSproperty,tParamElement) { $$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPtype) Set tParameterType=type }
					Set tParamExpression = tParamExpression_$$$QN(tParamElement)_"."
				}
				set tParamElement = $Piece(parmProp,".",tParamElementCount)
			}
			else { set tParamElement = parmProp, tParamExpression = ".." }
			if $$$comMemberDefined(tParameterType,$$$cCLASSproperty,tParamElement) {
				$$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPruntimetype)
				set classtype=$$$getClassType(type)
				if classtype = $$$cCLASSCLASSTYPEDATATYPE { set tParamExpression = tParamExpression _ $$$QN(tParamElement) }
				else {
					$$$comMemberKeyGetLvar(collection,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPcollection)
					if collection = "" {
						set classinoid = +$$$comMemberArrayGet(tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPparameter,"CLASSNAME")
						set tParamExpression = tParamExpression_$$$QN(tParamElement_"GetObject" _ $Select('classinoid:"Id",1:""))_"(0)"
					}
					else {
						$$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPtype)
						set classtype=$$$getClassType(type)
						set tParamExpression =  tParamExpression_$$$QN(tParamElement)_".Serialize(" _ $Select(classtype=$$$cCLASSCLASSTYPEDATATYPE:"",1:"0")_")"
					}
				}
			}
			else { set tParamExpression = $$$QN(tParamElement) }
			Set strComputeParms = strComputeParms _ "," _  tParamExpression
		}
		$$$GENERATE("	Set oref=##class("_runtimetype_").%OpenId(.."_$$$QN(%property_"Compute")_"(" _ strIDExpr _strComputeParms_"),,.sc) If $$$ISERR(sc) $$$THROWSWIZZLEERR")
		$$$GENERATE("	Quit oref")
	} ElseIf 'calculated {
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
		#; Signify this is system implemented method
		Set %code="-1"
	}
	QUIT $$$OK
}

/// Returns an oref, performing swizzling if necessary it returns "" ($$$NULLOREF) if there is no oref and the id="".
/// If <var>noswizzle</var> is passed as true then this will just return the current value for the property, so if it
/// has been swizzled already then it will return the oref, if it has not been swizzled it will return "" ($$$NULLOREF).
Method GetSwizzled(noswizzle As %Boolean = 0) As %RegisteredObject [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) If calculated Quit $$$OK
	$$$comMemberKeyGetLO(sqlcomputed,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	Set qprop=$$$QN(%property)
	$$$GENERATE("	If noswizzle Quit r%"_qprop)
	If sqlcomputed {
		Set strIDExpr = $Select($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT:"$$$idCurrent",1:"""""")
			#; Construct the Compute() method parameter list using in-memory props as actual args
		$$$comMemberKeyGetLO(lstRefs,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputedependency)
		set strComputeParms = "" For ptr = 1:1:$ListLength(lstRefs) {
			set parmProp = $List(lstRefs,ptr)
				#; Quote the property name elements in the dotted expression and compute the typeclass of the last dotted expression
			set tParameterType = %class, qparmProp=""
			if parmProp [ "." {
				set tParamExpression = ".."
				set tParamElementCount = $length(parmProp,".")
				For i=1:1:tParamElementCount - 1 {
					set tParamElement = $Piece(parmProp,".",i)
					if $$$comMemberDefined(tParameterType,$$$cCLASSproperty,tParamElement) { $$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPtype) Set tParameterType=type }
					Set tParamExpression = tParamExpression_$$$QN(tParamElement)_"."
				}
				set tParamElement = $Piece(parmProp,".",tParamElementCount)
			}
			else { set tParamElement = parmProp, tParamExpression = ".." }
			if $$$comMemberDefined(tParameterType,$$$cCLASSproperty,tParamElement) {
				$$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPruntimetype)
				set classtype=$$$getClassType(type)
				if classtype = $$$cCLASSCLASSTYPEDATATYPE { set tParamExpression = tParamExpression _ $$$QN(tParamElement) }
				elseif tParamElement=%property { set tParamExpression = """""" }	// This field, and we only call Compute if it is "", so just pass in "" as the value
				else {
					$$$comMemberKeyGetLvar(collection,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPcollection)
					if collection = "" {
						set classinoid = +$$$comMemberArrayGet(tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPparameter,"CLASSNAME")
						set tParamExpression = tParamExpression_$$$QN(tParamElement_"GetObject" _ $Select('classinoid:"Id",1:""))_"(0)"
					}
					else {
						$$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPtype)
						set classtype=$$$getClassType(type)
						set tParamExpression =  tParamExpression_$$$QN(tParamElement)_".Serialize(" _ $Select(classtype=$$$cCLASSCLASSTYPEDATATYPE:"",1:"0")_")"
					}
				}
			}
			else { set tParamExpression = $$$QN(tParamElement) }
			Set strComputeParms = strComputeParms _ "," _  tParamExpression
		}
		$$$GENERATE("	If $Get(i%"_qprop_") = """" { Set i%"_qprop_"=.."_$$$QN(%property_"Compute")_"(" _ strIDExpr _strComputeParms_") }")
	}
	Set runtimeclasstype=$$$getClassType(runtimetype)
	Set hasclassname=0 $$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	If collection="" Set hasclassname=%parameter("CLASSNAME")
		#; don't swizzle if the property type does not have swizzling interface
	Set oid=$select(hasclassname:"i%"_qprop,1:"$$$oidForm(i%"_qprop_")")
	If (runtimeclasstype = $$$cCLASSCLASSTYPEPERSISTENT) {
		$$$GENERATE("	If i%"_qprop_"="""" Quit $$$NULLOREF")
		$$$GENERATE("	Set oref=##class("_runtimetype_").%Open("_oid_",,.sc) If $$$ISERR(sc) $$$THROWSWIZZLEERR Quit $$$NULLOREF")
		$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_qprop_"=oref Do $system.CLS.SetModifiedBits(modstate)")
		$$$GENERATE("	Quit oref")
	} ElseIf (runtimeclasstype = $$$cCLASSCLASSTYPESERIAL) {
		$$$GENERATE("	If '$data(i%"_qprop_") Set modstate=$system.CLS.GetSModifiedBits() Set oref=.."_$$$QN(%property_"NewObject")_"() Do $system.CLS.SetSModifiedBits(modstate) Set r%"_qprop_"=0,r%"_qprop_"=oref Quit oref")
		$$$GENERATE("	Set oref=##class("_runtimetype_").%Open("_oid_",,.sc) If $$$ISERR(sc) $$$THROWSWIZZLEERR Quit $$$NULLOREF")
		$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_qprop_"=oref Do $system.CLS.SetModifiedBits(modstate)")
		$$$GENERATE("	Quit oref")
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="r%"_qprop
	}
	QUIT $$$OK
}

/// Obtains the state/id of the referenced object
/// if swizzling has not occurred, it simply returns the stored
/// state else it references the specified object
/// force = an optional parameter, if its value is 1 then if the
/// referenced object is an ID object it must return its ID,
/// which may force it to file itself.
/// no code for this method if the property is a datatype
Method GetObject(force As %Integer = 0) As %ObjectIdentity [ CodeMode = generator, ServerOnly = 0 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(tComputed,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	$$$comMemberKeyGetLO(tCalculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If ('tComputed)&&(tCalculated) QUIT $$$OK
	Set qprop=$$$QN(%property)
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set classtype=$$$getClassType(runtimetype)
	Set hasclassname=0 $$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	If collection="" Set hasclassname=%parameter("CLASSNAME")
	If collection'="" $$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,%property,$$$cPROPrelationship)
	if '(tCalculated) {
		Set cond="r%"_qprop_"=$$$NULLOREF"
		If classtype=$$$cCLASSCLASSTYPESERIAL {
			Set cond=cond_"&&($data(i%"_qprop_"))"
		} ElseIf classtype=$$$cCLASSCLASSTYPEPERSISTENT {
			#; Once the id is set for a persistent object it never changes
			Set cond=cond_"||(i%"_qprop_"'=$$$NULLOID)"
		}
		If collection'="",'relationship {
			$$$GENERATE("	Set id=.."_qprop_".Serialize(force)")
			$$$GENERATE("	Quit $$$oidForm(id)")
		} ElseIf hasclassname {
			set %codemode=$$$cMETHCODEMODEEXPRESSION
			Set %code="$select("_cond_":i%"_qprop_",$$$ISOK(.."_qprop_".%GetSwizzleObject(force,.oid)):oid,1:"""")"
		} Else {
			set %codemode=$$$cMETHCODEMODEEXPRESSION
			Set %code="$select("_cond_":$$$oidForm(i%"_qprop_"),$$$ISOK(.."_qprop_".%GetSwizzleObject(force,.oid)):oid,1:"""")"
		}
	}
	else {
			#; computed/calculated property reference - no instance variables
		if 'hasclassname {
				#; this is the common case - no classname in the OID. In this case, just return the computed value.
			Set strIDExpr = $Select($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT:"$$$idCurrent",1:"""""")
				#; Construct the Compute() method parameter list using in-memory props as actual args
			$$$comMemberKeyGetLO(lstRefs,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputedependency)
			set strComputeParms = "" For ptr = 1:1:$ListLength(lstRefs) {
				set parmProp = $List(lstRefs,ptr)
					#; Quote the property name elements in the dotted expression and compute the typeclass of the last dotted expression
				set tParameterType = %class, qparmProp=""
				if parmProp [ "." {
					set tParamExpression = ".."
					set tParamElementCount = $length(parmProp,".")
					For i=1:1:tParamElementCount - 1 {
						set tParamElement = $Piece(parmProp,".",i)
						if $$$comMemberDefined(tParameterType,$$$cCLASSproperty,tParamElement) { $$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPtype) Set tParameterType=type }
						Set tParamExpression = tParamExpression_$$$QN(tParamElement)_"."
					}
					set tParamElement = $Piece(parmProp,".",tParamElementCount)
				}
				else { set tParamElement = parmProp, tParamExpression = ".." }
				if $$$comMemberDefined(tParameterType,$$$cCLASSproperty,tParamElement) {
					$$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPruntimetype)
					set classtype=$$$getClassType(type)
					if classtype = $$$cCLASSCLASSTYPEDATATYPE { set tParamExpression = tParamExpression _ $$$QN(tParamElement) }
					else {
						$$$comMemberKeyGetLvar(collection,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPcollection)
						if collection = "" {
							set classinoid = +$$$comMemberArrayGet(tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPparameter,"CLASSNAME")
							set tParamExpression = tParamExpression_$$$QN(tParamElement_"GetObject" _ $Select('classinoid:"Id",1:""))_"(0)"
						}
						else {
							$$$comMemberKeyGetLvar(type,tParameterType,$$$cCLASSproperty,tParamElement,$$$cPROPtype)
							set classtype=$$$getClassType(type)
							set tParamExpression =  tParamExpression_$$$QN(tParamElement)_".Serialize(" _ $Select(classtype=$$$cCLASSCLASSTYPEDATATYPE:"",1:"0")_")"
						}
					}
				}
				else { set tParamExpression = $$$QN(tParamElement) }
				Set strComputeParms = strComputeParms _ "," _  tParamExpression
			}
			$$$GENERATE("	Set id=.."_$$$QN(%property_"Compute")_"(" _ strIDExpr _strComputeParms_")")
			$$$GENERATE("	Quit $$$oidForm(id)")
		}
		else {
				#; We have a classname in the OID. For now, just get the property and call the %GetSwizzleObject() method.
			$$$GENERATE("	Set oref=.."_qprop)
			$$$GENERATE("	Quit $select(oref=$$$NULLOREF:"""",$$$ISOK(oref.%GetSwizzleObject(force,.oid)):oid,1:"""")")
		}
	}
	QUIT $$$OK
}

/// Stores simply calls GetObject() with decomposes Oid into Id
Method GetObjectId(force As %Integer = 0) As %String [ CodeMode = generator, GenerateAfter = GetObject, ServerOnly = 0 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if GetObject() is not there
	If $$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"GetObject")=0 QUIT $$$OK
	Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="$$$oidPrimary(.."_$$$QN(%property_"GetObject")_"(force))"
	QUIT $$$OK
}

/// Can be used to test whether an embedded object is in
/// NULL state exists for embedded object only, not for persistent objects
Method IsEmpty() As %Integer [ CodeMode = generator, GenerateAfter = GetObject, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	If $$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"GetObject") {
		$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		If $$$classIsSerial(runtimetype) Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="$$$oidPrimary(.."_$$$QN(%property_"GetObject")_"(1))="""""
	}
	QUIT $$$OK
}

/// Creates a new object for the referenced property
Method NewObject() As %ObjectHandle [ CodeMode = generator, GenerateAfter = Set, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	
	#; if calculated, then don't generate this method
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	
	Set qprop=$$$QN(%property)
	#; set-up return type
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$comMemberKeyGetLO(initialexpression,origin,%class,$$$cCLASSinstancevar,%property,$$$cIVARinitialexpression)
	If initialexpression="""""" Set initialexpression=""
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	If initialexpression'="",$$IsA^%occLibrary(runtimetype,"%Library.DynamicAbstractObject") {
		$$$GENERATE("	Set newobject="_initialexpression_" If newobject=$$$NULLOREF Quit $$$NULLOREF")
	} Else {
		$$$GENERATE("	Set newobject=##class("_runtimetype_").%New("_initialexpression_") If newobject=$$$NULLOREF Quit $$$NULLOREF")
	}
	If ('$$$comMemberDefined(%class,$$$cCLASSmethod,%property_"Set")) && ($$$comSubMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"Set",$$$cMETHorigin) = "%Compiler.Type.Object") {
		$$$GENERATE("	Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=newobject,i%"_qprop_"=$$$NULLOID")
	} Else {
		$$$GENERATE("	Set .."_qprop_"=newobject")
	}
	$$$GENERATE("	Quit newobject")
	QUIT $$$OK
}

/// Set the property to an oref value
/// if the new oref is different from an old oref, the old object
/// is closed
Method Set(newvalue As %RawString) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
		#; don't generate any code if the property is calculated or readonly
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	$$$comMemberKeyGetLO(readonly,origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly)
	If calculated||readonly QUIT $$$OK
	Set qprop=$$$QN(%property)
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set runtimeclasstype=$$$getClassType(runtimetype)
		#; this is the $list of properties whose Compute is triggered whenever this property changes value
	$$$comMemberKeyGetLO(lstTrigger,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputetriggers)
	Set aTrigger = 0
	If lstTrigger '= "" {
		For ptr = 1:1:$ListLength(lstTrigger) {
			set tTriggeredProp = $list(lstTrigger,ptr)
				// Don't worry about triggering calculated properties - we only want to set IV's for triggered properties.
			if ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPcalculated)) {
				if ($Extract($$$comSubMemberKeyGet(%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPmethod,"Set",$$$cXXXXorigin),1,14) = "%Compiler.Type") {
					set aTrigger($Increment(aTrigger)) = $Char(9)_"do .."_$$$QN(tTriggeredProp_"SetT")_"()"
				}
				else {
					$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPruntimetype)
					$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPcollection)
					set tTriggeredPropQ = $$$QN(tTriggeredProp)
					if collection'="" {
						set aTrigger($increment(aTrigger)) = $Char(9)_"kill i%"_tTriggeredPropQ_",r%"_tTriggeredPropQ_" Set i%"_tTriggeredPropQ_"="""",r%"_tTriggeredPropQ_"="""" If .."_tTriggeredPropQ
					} elseif $case($$$getClassType(runtimetype),$$$cCLASSCLASSTYPEPERSISTENT:0,$$$cCLASSCLASSTYPESERIAL:0,:1) {
						set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""" if .."_tTriggeredPropQ
					} else {
						set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""",r%"_tTriggeredPropQ_"="""" if .."_tTriggeredPropQ
					}
				}
			}
		}
	}
	#; If you set a serial object to $$$NULLOREF then initialize it as if the object was brand new
	If (runtimeclasstype = $$$cCLASSCLASSTYPESERIAL) {
		#; if newvalue if not a valid oref, quit with error, or if new value is same as old value we are done
		$$$GENERATE("	If newvalue=$$$NULLOREF {")
		$$$GENERATE("		Kill i%"_qprop_",r%"_qprop_" Set r%"_qprop_"=$$$NULLOREF")
		$$$GENERATE("	} Else {")
		$$$GENERATE("		If '$$$objExists(newvalue) { Quit $$$ERROR($$$OrefInvalid,newvalue) } If r%"_qprop_"=newvalue { Quit $$$OK }")
		$$$GENERATE("		Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=newvalue,i%"_qprop_"=$$$NULLOID")
		$$$GENERATE("	}")
	} Else {
		If 'aTrigger {
			Set %code=-1
			Quit $$$OK
		} Else {
			#; if newvalue if not a valid oref, quit with error, or if new value is same as old value we are done
			$$$GENERATE("	If newvalue'=$$$NULLOREF { If '$$$objExists(newvalue) { Quit $$$ERROR($$$OrefInvalid,newvalue) } If r%"_qprop_"=newvalue { Quit $$$OK } }")
			$$$GENERATE("	Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=newvalue,i%"_qprop_"=$$$NULLOID")
		}
	}
	If aTrigger { For ptr = 1:1:aTrigger { $$$GENERATE($char(9)_aTrigger(ptr)) } }
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Stores a new value for the OID of the referenced
/// object. if swizzling has not occurred, it simply stores the
/// OID (after perhaps stripping the class name if CLASSNAME=0).
/// if swizzling has occurred, then it references the object to
/// obtain its OID.  If it is the same, then nothing happens.
/// If they are different then the old object is closed and the
/// new OID is stored.
Method SetObject(newvalue As %ObjectIdentity) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	Set qprop=$$$QN(%property)
	#; if we don't want a classname, then strip it
	If collection'="" {
		$$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,%property,$$$cPROPrelationship)
		If relationship {
			Quit $$$OK
		} Else {
			$$$GENERATE("	Set sc=.."_qprop_".DeSerialize($$$oidPrimary(newvalue)) If $$$ISERR(sc) Quit sc")
		}
	} ElseIf %parameter("CLASSNAME") {
		$$$GENERATE("	If newvalue'="""",$data(i%"_qprop_",tmp),$listsame(tmp,newvalue) Quit $$$OK")
		$$$GENERATE("	Set i%"_qprop_"=newvalue,r%"_qprop_"=0,r%"_qprop_"=$$$NULLOREF")
	} Else {
		$$$GENERATE("	If newvalue'="""",$data(i%"_qprop_",tmp),tmp=$$$oidPrimary(newvalue) Quit $$$OK")
		$$$GENERATE("	Set i%"_qprop_"=$$$oidPrimary(newvalue),r%"_qprop_"=0,r%"_qprop_"=$$$NULLOREF")
	}
		#; this is the $list of properties whose Compute is triggered whenever this property changes value
	$$$comMemberKeyGetLO(lstTrigger,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputetriggers)
	Set aTrigger = 0
	If lstTrigger '= "" {
		For ptr = 1:1:$ListLength(lstTrigger) {
			set tTriggeredProp = $list(lstTrigger,ptr)
				// Don't worry about triggering calculated properties - we only want to set IV's for triggered properties.
			if ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPcalculated)) {
				if ($Extract($$$comSubMemberKeyGet(%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPmethod,"Set",$$$cXXXXorigin),1,14) = "%Compiler.Type") {
					set aTrigger($Increment(aTrigger)) = $Char(9)_"do .."_$$$QN(tTriggeredProp_"SetT")_"()"
				}
				else {
					$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPruntimetype)
					$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,tTriggeredProp,$$$cPROPcollection)
					set tTriggeredPropQ = $$$QN(tTriggeredProp)
					if collection'="" {
						set aTrigger($increment(aTrigger)) = $Char(9)_"kill i%"_tTriggeredPropQ_",r%"_tTriggeredPropQ_" Set i%"_tTriggeredPropQ_"="""",r%"_tTriggeredPropQ_"="""" If .."_tTriggeredPropQ
					} elseif $case($$$getClassType(runtimetype),$$$cCLASSCLASSTYPEPERSISTENT:0,$$$cCLASSCLASSTYPESERIAL:0,:1) {
						set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""" if .."_tTriggeredPropQ
					} else {
						set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""",r%"_tTriggeredPropQ_"="""" if .."_tTriggeredPropQ
					}
				}
			}
		}
	}
	If aTrigger { For ptr = 1:1:aTrigger { $$$GENERATE($char(9)_aTrigger(ptr)) } }
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Stores simply calls SetObject() with constructed Oid
Method SetObjectId(newid As %String) As %Status [ CodeMode = generator, GenerateAfter = SetObject, ServerOnly = 0 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if SetObject() is not there
	If ($$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"SetObject")=0) && ($$$comMemberDefined(%class,$$$cCLASSmethod,%property_"SetObject")=0) { QUIT $$$OK }
	//If $$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"SetObject")=0 QUIT $$$OK
	Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code=".."_$$$QN(%property_"SetObject")_"($$$oidForm(newid))"
	QUIT $$$OK
}

/// Unswizzles a property, if it has an oref
Method UnSwizzle(force As %Integer = 0) As %Status [ CodeMode = generator, Private, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is a collection
	$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	If collection'="" QUIT $$$OK
	#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	#; don't generate any code if the property is datatype
	Set qprop=$$$QN(%property)
	
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set runtimeclasstype=$$$getClassType(runtimetype)
	#; quit if there is no oref
	#; if the serial object is modified, then the property is modified, this is picked up by the update to i% value
	If runtimeclasstype = $$$cCLASSCLASSTYPESERIAL {
		$$$GENERATE("	If r%"_qprop_"=$$$NULLOREF,$data(i%"_qprop_") Quit $$$OK")
	} Else {
		$$$GENERATE("	If r%"_qprop_"=$$$NULLOREF Quit $$$OK")
	}
	$$$GENERATE("	Set sc=.."_qprop_".%GetSwizzleObject(force,.newvalue) Quit:$$$ISERR(sc) sc")
	$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_qprop_"=$$$NULLOREF Do $system.CLS.SetModifiedBits(modstate)")
	If %parameter("CLASSNAME") {
		$$$GENERATE("	Set i%"_qprop_"=newvalue")
	} Else {
		$$$GENERATE("	Set i%"_qprop_"=$$$oidPrimary(newvalue)")
	}
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

}
