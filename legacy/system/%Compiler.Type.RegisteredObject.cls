/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Property superclass for registered object values, for internal use only
Class %Compiler.Type.RegisteredObject Extends %Compiler.Type.Literal [ NoContext, System = 1 ]
{

Method Get() As %RawString [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLvar(calculated,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) If calculated Quit $$$OK
	#; Signify this is system implemented method
	Set %code="-1"
	QUIT $$$OK
}

/// Returns an oref, performing swizzling if necessary
/// it returns "" ($$$NULLOREF) if there is no oref and the id=""
Method GetSwizzled() As %RegisteredObject [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLvar(calculated,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) If calculated Quit $$$OK
	$$$GENERATE("	Quit i%"_$$$QN(%property))
	QUIT $$$OK
}

/// Creates a new object for the referenced property
Method NewObject() As %ObjectHandle [ CodeMode = generator, GenerateAfter = Set, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	
	#; if calculated, then don't generate this method
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	
	#; set-up return type
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$comMemberKeyGetLO(initialexpression,origin,%class,$$$cCLASSinstancevar,%property,$$$cIVARinitialexpression)
	If initialexpression="""""" Set initialexpression=""
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	$$$GENERATE("	Set newobject=##class("_runtimetype_").%New("_initialexpression_") If newobject=$$$NULLOREF Quit $$$NULLOREF")
	$$$GENERATE("	Set .."_$$$QN(%property)_"=newobject")
	$$$GENERATE("	Quit newobject")
	QUIT $$$OK
}

/// Set the property to an oref value
/// if the new oref is different from an old oref, the old object
/// is closed
Method Set(newvalue As %RawString) As %Status [ CodeMode = generator, GenerateAfter = Get, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly) QUIT $$$OK
	#; Signify this is system implemented method
	Set %code="-1"
	Quit $$$OK
}

}
