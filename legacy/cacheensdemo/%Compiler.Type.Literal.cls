/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Property class for literal values, for internal use only.
/// <p>
/// The property interface consists of several accessor methods. For literals, the following methods are defined: 
/// <method>Get</method>
/// <method>Set</method>
/// <method>IsValid</method>
/// </p>
/// <p>
/// For complex types, the following methods are defined in subclasses of this class. Refer to <class>%Compiler.Type.Object</class> 
/// for object types.
Class %Compiler.Type.Literal [ NoContext, System = 1 ]
{

/// A caption for the property usually used by client applications.
Parameter CAPTION;

/// The name of the column in an external SQL table (gateway) to which this property is linked.
Parameter EXTERNALSQLNAME As STRING;

/// The original type of the column in an external SQL table (gateway) to which this property is linked.
Parameter EXTERNALSQLTYPE As STRING;

/// This parameter controls whether the SELECTIVITY of this property is calculated during TuneTable
/// 1 means TuneTable will calculate the SELECTIVITY of the property/field.  0 means it will be skipped by TuneTable.
Parameter CALCSELECTIVITY As BOOLEAN = 1;

/// The Java type to be used when exported.
Parameter JAVATYPE;

/// STORAGEDEFAULT is the type of storage used for the property if it is not already
/// allocated in a DATA definition in the active STORAGE definition. 
/// Used to define a property as being stored as columnar in a hybrid row/column table.
/// globalnode is used to store long data in its own global.
Parameter STORAGEDEFAULT As STRING [ Constraint = ",columnar,row,globalnode", Flags = ENUM ];

/// STORAGEDEFAULTTARGET is the type of storage that will be used for the property after
/// an ALTER TABLE ... CONVERT STORAGETYPE statement. This parameter is for internal use only.
Parameter STORAGEDEFAULTTARGET As STRING [ Constraint = "row,columnar", Flags = ENUM, Internal ];

Method Get() As %RawString [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
		#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(blCalculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	$$$comMemberKeyGetLO(blSQLComputed,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	If ('blCalculated) && ('blSQLComputed) {
		$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype))
			#; Signify this is system implemented method
		Set %code=-1
	} ElseIf blSQLComputed {
		Set strIDExpr = $Select($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT:"$$$idCurrent",1:"""""")
			#; Construct the Compute() method parameter list using in-memory props as actual args
		$$$comMemberKeyGetLO(lstRefs,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputedependency)
		set strComputeParms = "" For ptr = 1:1:$ListLength(lstRefs) {
			set parmProp = $List(lstRefs,ptr)
			Set qparmProp="" For i=1:1:$length(parmProp,".") { Set qparmProp=qparmProp_"."_$$$QN($piece(parmProp,".",i)) } Set qparmProp=$extract(qparmProp,2,*)
			if $$$comMemberDefined(%class,$$$cCLASSproperty,parmProp) {
				$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,parmProp,$$$cPROPruntimetype)
				set classtype=$$$getClassType(type)
				if parmProp = %property { set parmExpr = "i%"_qparmProp }
				elseif classtype = $$$cCLASSCLASSTYPEDATATYPE { set parmExpr = ".."_qparmProp }
				else {
					$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,parmProp,$$$cPROPcollection)
					if collection = "" {
						set classinoid = +$$$comMemberArrayGet(%class,$$$cCLASSproperty,parmProp,$$$cPROPparameter,"CLASSNAME")
						set parmExpr = ".."_$$$QN(parmProp_"GetObject" _ $Select('classinoid:"Id",1:""))_"(0)"
					}
					else {
						$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,parmProp,$$$cPROPtype)
						set classtype=$$$getClassType(type)
						set parmExpr = ".."_qparmProp_".Serialize(" _ $Select(classtype=$$$cCLASSCLASSTYPEDATATYPE:"",1:"0")_")"
					}
				}
			}
			else { set parmExpr = ".." _ qparmProp }
			Set strComputeParms = strComputeParms _ "," _ parmExpr
		}
		$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype))
		If blCalculated {
			Set %codemode = $$$cMETHCODEMODEEXPRESSION, %code = ".."_$$$QN(%property_"Compute")_"(" _ strIDExpr _ strComputeParms _ ")"
		}
		Elseif $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly) {
			$$$GENERATE("	If i%"_$$$QN(%property)_" = """" { do .."_$$$QN(%property_"SetT")_"() } Quit i%"_$$$QN(%property))
		}
		Else {
			$$$GENERATE("	If i%"_$$$QN(%property)_" = """" { Set .."_$$$QN(%property)_"=.."_$$$QN(%property_"Compute")_"(" _ strIDExpr _strComputeParms_") } Quit i%"_$$$QN(%property))
		}
	}
	QUIT $$$OK
}

/// SetT() is the "triggered set" method generated solely for READONLY properties that are SQLCOMPUTED
/// and are triggered by a non-null set of properties defined in SQLCOMPUTEONCHANGE. Not to be called by user code.
Method SetT() As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a property
	if %mode="method" quit $$$OK
		#; don't generate any code if the property is calculated or multidimensional
	if '$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed) quit $$$OK
	if $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) quit $$$OK
	if $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPmultidimensional) quit $$$OK
	set qprop=$$$QN(%property)
		#; if property is datatype
	$$$comMemberKeyGetLvar(validate,%class,$$$cCLASSparameter,"PROPERTYVALIDATION",$$$cPARAMdefault)
	$$$comMemberKeyGetLO(lstTrigger,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputetriggers)
	$$$comMemberKeyGetLO(tREADONLY,origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly)
	set tClassType = $$$getClassType(%class)
		// Construct the Compute expression
	set tIDExpr = $select(tClassType=$$$cCLASSCLASSTYPEPERSISTENT:"$$$idCurrent",1:"""""")
		// Construct the Compute() method parameter list using in-memory props as actual args
	$$$comMemberKeyGetLO(tReferenceList,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputedependency)
	set tComputeParms = ""
	for tPtr = 1:1:$listlength(tReferenceList) {
		set tParmProp = $list(tReferenceList,tPtr)
		set tParmPropQ = ""
			// We don't currently allow a dot in any delimited identifier. If that changes then so should this next line:
		for tDot=1:1:$length(tParmProp,".") { set tParmPropQ = tParmPropQ _ "." _ $$$QN($piece(tParmProp,".",tDot)) }
		set tParmPropQ = $extract(tParmPropQ,2,*)
		if $$$comMemberDefined(%class,$$$cCLASSproperty,tParmProp) {
			$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,tParmProp,$$$cPROPruntimetype)
			set classtype=$$$getClassType(type)
			if tParmProp = %property { set tParmExpr = $Select(classtype'=$$$cCLASSCLASSTYPESERIAL:"i%"_tParmPropQ,1:"$g(i%"_tParmPropQ_")") }
			elseif classtype = $$$cCLASSCLASSTYPEDATATYPE { set tParmExpr = ".." _ tParmPropQ }
			else {
				$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,tParmProp,$$$cPROPcollection)
				if collection = "" {
					set classinoid = +$$$comMemberArrayGet(%class,$$$cCLASSproperty,tParmProp,$$$cPROPparameter,"CLASSNAME")
					set tParmExpr = ".."_$$$QN(tParmProp_"GetObject" _ $select('classinoid:"Id",1:""))_"(0)"
				}
				else {
					$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,tParmProp,$$$cPROPtype)
					set classtype=$$$getClassType(type)
					set tParmExpr = ".."_tParmPropQ_".Serialize(" _ $select(classtype=$$$cCLASSCLASSTYPEDATATYPE:"",1:"0")_")"
				}
			}
		}
		else { set tParmExpr = ".." _ tParmPropQ }
		set tComputeParms = tComputeParms _ "," _ tParmExpr
	}
		// the check for the origin is working but it might not be completely correct. It works here but....
		// When a property method is inherited through the property super classes then we define a property method and that is what I'm checking in the SetT generator.
		// It also defines a method "stub" here:
		// 	^oddCOM("Sample.Person","m","DOBGet",47)="DOB.Get.a"
		// The 47 node tells us it is a stub method for a member type of "a" and the member name is DOB, the member method is Get.
		// To be completely accurate, we should start with the "m" member check, if it is a stub then get the origin using the reference already there, otherwise get the origin from the method member itself (as opposed to the sub member method).
	if ($Extract($$$comSubMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"Get",$$$cXXXXorigin),1,14) = "%Compiler.Type") { set tOverride = 0,tComputeExpr = ".."_$$$QN(%property_"Compute")_"(" _ tIDExpr _tComputeParms_")" }
	else { set tOverride = 1, tComputeExpr = ".."_$$$QN(%property) }
	if 'tREADONLY {
			// if the property is a datatype call Set, otherwise call SetObjectId or SetObject depending on the CLASSNAME parameter
		$$$comMemberKeyGetLvar(tPropertyType,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		set tPropertyType = $$$getClassType(tPropertyType)
		set classinoid = +$$$comMemberArrayGet(%class,$$$cCLASSproperty,%property,$$$cPROPparameter,"CLASSNAME")
		set tSetMethod = $Select(tOverride:"Set",tPropertyType=$$$cCLASSCLASSTYPEDATATYPE:"Set",'classinoid:"SetObjectId",1:"SetObject")
		if 'tOverride { 
			set %codemode = $$$cMETHCODEMODEEXPRESSION, %code = ".."_$$$QN(%property_tSetMethod)_"("_tComputeExpr_")"
		}
		else {
				// updated SetT to set the instance variable to null in the Get override case.
			$$$GENERATE($Char(9)_"set i%"_qprop_"="""""_$s(tPropertyType'=$$$cCLASSCLASSTYPEDATATYPE:",r%"_qprop_"=""""",1:"")_" quit .."_$$$QN(%property_tSetMethod)_"("_tComputeExpr_")")
		}
	}
	elseif (validate'=1) && (lstTrigger = "") {
		$$$GENERATE($Char(9)_"set i%"_qprop_"="_$Select('tOverride:"",1:""""", i%"_qprop_"=")_tComputeExpr)
		$$$GENERATE($Char(9)_"quit $$$OK")
	}
	else {
			#; if autovalidation on a SET has been specified, then perform the validation
		if 'tOverride {
			$$$GENERATE($Char(9)_"set newvalue="_tComputeExpr)
			if validate=1 { $$$GENERATE($Char(9)_"if newvalue'="""" { Set sc=.."_$$$QN(%property_"IsValid")_"(newvalue) Quit:$$$ISERR(sc) sc }") }
		}
		else {
			$$$GENERATE($Char(9)_"set oldvalue=i%"_qprop_",i%"_qprop_"="""",newvalue="_tComputeExpr)
			if validate=1 { $$$GENERATE($Char(9)_"if newvalue'="""" { Set sc=.."_$$$QN(%property_"IsValid")_"(newvalue) if $$$ISERR(sc) { set i%"_qprop_"=oldvalue quit sc } }") }
		}
		set aTrigger = 0
		if lstTrigger '= "" {
			for ptr = 1:1:$listlength(lstTrigger) {
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
							set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""" If .."_tTriggeredPropQ
						} else {
							set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""",r%"_tTriggeredPropQ_"="""" If .."_tTriggeredPropQ
						}
					}
				}
			}
		}
		if aTrigger {
			$$$GENERATE($Char(9)_"If i%"_qprop_"'=newvalue {")
			$$$GENERATE($Char(9,9)_"set i%"_qprop_"=newvalue")
			for ptr = 1:1:aTrigger { $$$GENERATE($char(9)_aTrigger(ptr)) }
			$$$GENERATE($Char(9)_"}")
			$$$GENERATE($Char(9)_"Quit $$$OK")
		} else {
			$$$GENERATE($Char(9)_"set i%"_qprop_"=newvalue")
			$$$GENERATE($Char(9)_"Quit $$$OK")
		}
	}
	Quit $$$OK
}

/// Set the property to <var>newvalue</var> if is different from the current value. 
Method Set(newvalue As %RawString) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	s %code=0
		#; don't generate any code if it not for a property
	i %mode="method" QUIT $$$OK
		#; don't generate any code if the property is calculated or readonly
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly) QUIT $$$OK
	Set qprop=$$$QN(%property)
		#; if property is datatype
	$$$comMemberKeyGetLvar(validate,%class,$$$cCLASSparameter,"PROPERTYVALIDATION",$$$cPARAMdefault)
	$$$comMemberKeyGetLO(lstTrigger,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputetriggers)
		#; if autovalidation on a SET has been specified, then perform the validation
	If ((validate'=1) && (lstTrigger = "")) || ($$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPmultidimensional)) {
		Set %code=-1
		Quit $$$OK
	} Else {
		If validate=1 { $$$GENERATE($Char(9)_"if newvalue'="""" { Set sc=.."_$$$QN(%property_"IsValid")_"(newvalue) Quit:$$$ISERR(sc) sc }") }
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
							set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""" If .."_tTriggeredPropQ
						} else {
							set aTrigger($increment(aTrigger)) = $Char(9)_"set i%"_tTriggeredPropQ_"="""",r%"_tTriggeredPropQ_"="""" If .."_tTriggeredPropQ
						}
					}
				}
			}
		}
		If aTrigger {
			$$$GENERATE("	If i%"_qprop_"'=newvalue {")
			$$$GENERATE("		Set i%"_qprop_"=newvalue")
			For ptr = 1:1:aTrigger { $$$GENERATE($char(9)_aTrigger(ptr)) }
			$$$GENERATE("	}")
			$$$GENERATE("	Quit $$$OK")
		} Else {
			If validate'=1 {
				Set %code=-1
			} Else {
				$$$GENERATE("	Set i%"_qprop_"=newvalue")
				$$$GENERATE("	Quit $$$OK")
			}
		}
	}
	Quit $$$OK
}

ClassMethod IsValid(value As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	s %code=0
	; don't generate any code if it not for a property
	i %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLvar(calculated,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) If calculated QUIT $$$OK
	Set %code=$$$OK
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %code="$select(##class("_$$$QN(%class)_")."_$$$QN(%property_"IsValidDT")_"(value):1,1:$$$ERROR($$$DatatypeValidationFailed,$classname()_"":""_"_$$$QuoteName(%property)_",value))"
	}
	Set %codemode=$$$cMETHCODEMODEEXPRESSION
	QUIT $$$OK
}

/// This internal method is generated for properties with SQLCOMPUTED = true. It contains code to compute a value for the property as defined in SQLCOMPUTECODE. SQLCOMPUTECODE is scanned for {<field>} references and those references are replaced by a formal argument.
/// Do not attempt to call this method from user code.
ClassMethod Compute(%id As %RawString) As %String [ CodeMode = generator, Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	New a,aProperty,b,c,code,columns,componentClass,componentProperty,computecode,dotPtr,extinfo,field,field2,flag,fld,formal,formal2,lstRefs,i,intcode,j,lastdotpos,ldiff,locationmsg,mlcomment,pos,ptr,sc,sqlcomputecode,strProperty,strRowIdName,strSDEFName,strSQLName,tEtrap,type,tCode,tLine,tTab,tZtrap,origin
	Set %code = 0
		#; don't generate any code if it not for a property
	If %mode = "method" QUIT $$$OK
	Set sc = $$$OK
	$$$comMemberKeyGetLO(sqlcomputed,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed) If 'sqlcomputed Quit $$$OK
	$$$comMemberKeyGetLO(field,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlfieldname)
	$$$comMemberKeyGetLO(lstRefs,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputedependency)
		#; Currently, SQLCOMPUTECODE is a single string that contains lines of code delimited by $$$NL.
	$$$comMemberKeyGetLO(sqlcomputecode,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputecode)
	If sqlcomputecode '= "" {
			#; Reset the formal list to the list of referenced properties:
		$$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHformalspecparsed)
		Set formal2 = ""
		For ptr = 1:1:$ListLength(lstRefs) {
			Set strProperty  = $List(lstRefs,ptr)
				#; Let's populate the list of SQLNAME aliases here
			if strProperty '[ "." {
				$$$comMemberKeyGetLvar(strSQLName,%class,$$$cCLASSproperty,strProperty,$$$cPROPsqlfieldname)
				If strSQLName '= "" { Set columns($$$UPPER(strSQLName)) = strProperty }
			}
			else {
				set componentProperty = $Piece(strProperty,".",1), componentClass = %class
				$$$comMemberKeyGetLvar(strSQLName,%class,$$$cCLASSproperty,componentProperty,$$$cPROPsqlfieldname)
				for dotPtr = 2:1:$Length(strProperty,".") {
					$$$comMemberKeyGetLvar(type,componentClass,$$$cCLASSproperty,componentProperty,$$$cPROPtype) Set componentClass=type
					set componentProperty = $Piece(strProperty,".",dotPtr)
					set strSQLName = strSQLName _ "_" _ $$$comMemberKeyGet(componentClass,$$$cCLASSproperty,componentProperty,$$$cPROPsqlfieldname)
				}
				set columns($$$UPPER(strSQLName)) = strProperty
			}
			Set aProperty(strProperty) = "%d" _ ptr
			$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,strProperty,$$$cPROPtype)
			If type = "" { Set type = $Get($$$EXTPROPtype($$$pEXT,%class,strProperty)) }
			Set formal2 = formal2_$lb($lb("%d"_ptr,type,"",""))
		}
		If formal2 '= "" {
			s formal=formal_formal2
			$$$comSubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHformalspecparsed,formal)
			Do SetOnePropertyMeth^%occProperty(%class,%property,%method)
		}
		$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype))
		set columns($$$UPPER(field)) = %property
			#; if this property is in the formal list then bind the its value to the initial value of %val, otherwise, initialize %val to null:
		if $Data(aProperty(%property)) { set tInitialize = aProperty(%property) } else { set tInitialize = "" }
			#; And, if this class is persistent, add in the %%ID name
		Set aProperty(%property) = "%val", aProperty("%%ID") = "%id"
		$$$comMemberKeyGetLO(field,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlfieldname)
		$$$comClassKeyGetLvar(strSDEFName,%class,$$$cCLASSstoragestrategy)
		If strSDEFName '= "" {
			$$$comMemberKeyGetLvar(strRowIdName,%class,$$$cCLASSstorage,strSDEFName,$$$cSDEFsqlrowidname)
			If strRowIdName '= "" { Set columns($$$UPPER(strRowIdName)) = "%%ID" }
		}
		set tZtrap = 0, tEtrap = 0, mlcomment = 0, tHasSQL=0
		For i = 1:1:$Length(sqlcomputecode,$$$NL) {
			Set code = $Piece(sqlcomputecode,$$$NL,i)
 			Set intcode = code, pos = 1, ldiff = 0
			For  {
				Set pos=$$find^%qarmac(code,"{",pos,$$$MaxStringLength,.mlcomment) Quit:'pos||(code'["}")  
				Set a=$Extract(code,1,pos-2),b=$Extract(code,pos,*)
				Set flag="",fld=$Piece(b,"}"),b=$Piece(b,"}",2,*)
				Set ldiff=$Length(code)-$Length(intcode),c=$Extract(intcode,1,pos-2-($Length(code)-$Length(intcode)))
				If '$ZName($Extract($Translate(fld,"*_%@#$"))),$Extract(fld)'="""",fld'="*" Continue  // Must not be a field.  Field has to be {A or {", where A is the beginning of a field name
				If fld["." {  // Strip off relation name, we allow but ignore schema.table since the field has to be from this table
					If fld'["""" { Set fld=$Piece(fld,".",$Length(fld,".")) }	// Strip off [schema.table] name, Easy, regular identifier
					Else {
						Set field=fld,lastdotpos=0
						For j=1:1 If $Extract(fld,j)="" || ($Extract(fld,j)="." && ($Length($Extract(fld,1,j),"""")#2)) Set field=$Extract(fld,lastdotpos+1,j-1),lastdotpos=j Quit:$Extract(fld,j)=""
						Set fld=field
					}
				}
				If fld["*",fld'="*" {
					If fld'["""" {
						Set flag=$Piece(fld,"*",2+($Extract(fld)="*")),fld=$Piece(fld,"*",1,1+($Extract(fld)="*"))	// easy case, no delimited identifiers
					}
					Else {
						Set field=fld
						For j=1:1 Set field=$Piece(fld,"*",1,j),flag=$Piece(fld,"*",j+1,*) Quit:flag=""  Quit:$Length(field,"""")#2
							#; At this point field is the field name and flag is the flag name or is empty
						If flag="" {}  ; No flag, leave fld as is
						Else { Set fld=field }
					}
				}
				If $$$UPPER(fld)="%%CLASSNAME" Set intcode=c_%class_b Continue
				If $$$UPPER(fld)="%%CLASSNAMEQ" Set intcode=c_$$$QUOTE(%class)_b Continue
				If $$$UPPER(fld)="%%OPERATION" Set intcode=c_"$g(%oper)"_b Continue
				If $$$UPPER(fld)="%%TABLENAME" Set intcode=c_$$$QUOTE($$$comClassKeyGet(%class,$$$cCLASSsqlqualifiednameQ))_b Continue
				If $$$UPPER(fld)="%%ID" Set intcode=c_"%id"_b Continue
				If $$$UPPER(fld)="X__CLASSNAME" Set intcode=c_$$$QUOTE($Get($$$EXTPROPserialexpression($$$pEXT,%class,"%%CLASSNAME")))_b Continue
				If $Extract(fld)="""" Set fld=$replace($Extract(fld,2,*-1),"""""","""")  ; remove quotes from fld name
				If $Extract(fld)="*" Set field2 = $Get(columns($$$UPPER(field)))
				Else  Set field2=$Get(columns($$$UPPER(fld)))
				If field2="" && '$ZName(fld) && '($Extract(fld)="""" && $Extract(fld,$Length(fld))="""") Continue  ; If not a field, leave alone
				If field2="" Set sc=$$$ADDSC(sc,$$$ERROR($$$InvalidCurlyBraceField,$Get(code),$Get(locationmsg))) Continue
				Set intcode = c_$Get(aProperty(field2),"%dunknown")_b
			}
			if $$$ucase(intcode) [ "$ZT"  { set tLine = $$$ucase($zstrip(intcode,"*W")) if (tLine [ "$ZTRAP=") || (tLine [ "$ZT=") { set tZtrap = 1 } }
			if $$$ucase(intcode) [ "$ET"  { set tLine = $$$ucase($zstrip(intcode,"*W")) if (tLine [ "$ETRAP=") || (tLine [ "$ET=") { set tEtrap = 1 } }
			if 'tHasSQL && ( $tr(intcode,"SQL","sql")["&sql" || ( $tr(intcode,"SQL","sql")["##sql" ) ) { set tHasSQL = 1 }
			set tCode($i(tCode)) = intcode
		}
		if tHasSQL {
			$$$GENERATE("#sqlcompile select=Logical")	// The ComputCode probably has SQL in it, make sure it runs in Logical mode
		}
		if '(tZtrap+tEtrap) {
			$$$GENERATE("	New %tException,%val set %val = " _ $Select(tInitialize="":"""""",1:tInitialize))
			$$$GENERATE("	try {")
			set tTab = $c(9)
		}
		else {
			if tInitialize '= "" { $$$GENERATE("	set %val = " _ tInitialize) }
			set tTab = ""
		}
		for i = 1:1:tCode { $$$GENERATE(tTab_tCode(i)) }
		if '(tZtrap+tEtrap) { $$$GENERATE("	} catch %tException { throw %tException }") }
		$$$GENERATE("	Quit %val")
	}
	else { $$$GENERATE("	Quit """"") }
	Quit sc
}

/// This internal method is generated for properties with SQLCOMPUTED = true. 
/// It contains code to compute a value for the property as defined in SQLCOMPUTECODE for the SQL Filer. 
/// Not to be called by user code.
ClassMethod SQLCompute() [ CodeMode = generator, Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	Set %code = 0
		#; don't generate any code if it not for a property
	If %mode = "method" QUIT $$$OK
	New sqlcomputecode
	$$$comMemberKeyGetLvar(sqlcomputecode,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputecode)
	If sqlcomputecode="" Set %code=0 Quit $$$OK
	$$$GENERATE("	Quit")
	Quit $$$OK
}

}
