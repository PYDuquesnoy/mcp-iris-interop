/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Property superclass for dynamic object values, for internal use only.
Class %Compiler.Type.Dynamic Extends %Compiler.Type.Object [ NoContext, System = 1 ]
{

Parameter FORMAT As STRING [ Constraint = JSON, Flags = ENUM ] = "JSON";

Parameter CLASSNAME As INTEGER [ Constraint = 0, Final, Flags = ENUM ] = 0;

/// Returns an oref, performing swizzling if necessary
/// it returns "" ($$$NULLOREF) if there is no oref and the id=""
Method Get() As %RawString [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		// don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)

	set propertyQN = $$$QN(%property)

	$$$comMemberKeyGetLO(COMPUTED,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	$$$comMemberKeyGetLO(CALCULATED,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
		// We need to generate the <property>Compute call if this is a computed property
	if COMPUTED {
		set strIDExpr = $Select($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT:"$$$idCurrent",1:"""""")
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
	}
		// CALCULATED simply means we have no instance memory, implying that the <property>Get method returns the value. 
		// If CALCULATED and SQLCOMPUTED then the <property>Get method invokes the Compute() method.
		// If CALCULATED and NOT SQLCOMPUTED then the user must override the <property>Get method and we shouldn't even be here.
	if 'CALCULATED {
		$$$comClassKeyGetLvar(typeAbstract,runtimetype,$$$cCLASSabstract)
		$$$GENERATE("	if r%" _ propertyQN _ "'= $$$NULLOREF return r%"_propertyQN)
		if COMPUTED {
			$$$GENERATE("	if i%"_propertyQN_"="""" { set i%"_propertyQN_"=.."_$$$QN(%property_"Compute")_"(" _ strIDExpr _strComputeParms_"),,.sc) If $$$ISERR(sc) { $$$THROWSWIZZLEERR } }")
		}
		$$$GENERATE("	if i%"_propertyQN_"'="""" { set r%" _ propertyQN _ "=##class("_runtimetype_").%SetSerial(i%"_propertyQN_") } else { set r%" _ propertyQN _ "="_$select(typeAbstract:"$$$NULLOREF",1:"##class("_runtimetype_").%New()")_" }")
		$$$GENERATE("	return r%" _ propertyQN)
	} elseif COMPUTED {
			// CALCULATED AND COMPUTED, generate the call
		$$$GENERATE("	set oref=##class("_runtimetype_").%SetSerial(.."_$$$QN(%property_"Compute")_"(" _ strIDExpr _strComputeParms_"),,.sc) If $$$ISERR(sc) $$$THROWSWIZZLEERR")
		$$$GENERATE("	return oref")
	}
	return $$$OK
}

ClassMethod GetStored(id As %String) As %RawString [ CodeMode = generator, NoContext, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a property
	if %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLvar(STORABLE,%class,$$$cCLASSproperty,%property,$$$cPROPstorable)
	$$$comMemberKeyGetLvar(COMPUTED,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	SET stored = $GET($$$EXTPROPondisk($$$pEXT,%class,%property))
	IF (STORABLE) && (stored '= "") {
		$$$comMemberKeyGetLvar(PRIVATE,%class,$$$cCLASSproperty,%property,$$$cPROPprivate)
		if PRIVATE {
			$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHprivate,1)
		}
		$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,$$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype))
		set %code="$Select(id'="""":"_stored_",1:"""")", %codemode = $$$cMETHCODEMODEEXPRESSION
	}
	QUIT $$$OK
}

}
