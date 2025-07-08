/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.Type.StreamLegacy Extends %Compiler.Type.Stream [ System = 2 ]
{

/// A logical value determines if classnames of referenced properties are stored.
/// 0 - store only the ID;
/// 1 - store the two element form of the OID
/// 2 - store the three element form of the OID (applies only to streams currently)
Parameter CLASSNAME As INTEGER [ Constraint = "0,1,2", Flags = ENUM ] = 1;

Method Set(newvalue As %RawString) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated or readonly
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPreadonly) QUIT $$$OK
	Set qprop=$$$QN(%property)
	$$$GENERATE("	If newvalue=$$$NULLOREF Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=$$$NULLOREF,i%"_qprop_"=$$$NULLOID Quit $$$OK")
	$$$GENERATE("	If '$$$objExists(newvalue) Quit $$$ERROR($$$OrefInvalid,newvalue)")
	$$$GENERATE("	If newvalue=r%"_qprop_" Quit $$$OK")
	$$$GENERATE("	If newvalue.%Extends(""%AbstractStream"") {")
	$$$GENERATE("		Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=newvalue,i%"_qprop_"=$$$NULLOID")
	$$$GENERATE("	} Else {")
	$$$GENERATE("		Do .."_qprop_".Rewind()")
	$$$GENERATE("		Quit .."_qprop_".CopyFrom(newvalue)")
	$$$GENERATE("	}")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

}
