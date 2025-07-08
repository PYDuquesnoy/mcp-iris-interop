/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an additional property class for properties of a persistent class.
Class %Library.PersistentProperty [ System = 2 ]
{

ClassMethod GetStored(id As %String) As %RawString [ CodeMode = generator, NoContext, ServerOnly = 1 ]
{
	s %code=0
		#; don't generate any code if it not for a property
	i %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLvar(blStorable,%class,$$$cCLASSproperty,%property,$$$cPROPstorable)
	$$$comMemberKeyGetLvar(blSQLComputed,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	Set strStored = $Get($$$EXTPROPondisk($$$pEXT,%class,%property))
	If (blStorable) && (strStored '= "") {
		$$$comMemberKeyGetLvar(blPrivate,%class,$$$cCLASSproperty,%property,$$$cPROPprivate)
		If blPrivate $$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHprivate,1)
		$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,$$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype))
		Set %code="$Select(id'="""":"_strStored_",1:"""")", %codemode = $$$cMETHCODEMODEEXPRESSION
	}
	QUIT $$$OK
}

}
