/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Trigger member superclass, for internal use only
Class %Compiler.Type.Trigger [ NoContext, System = 1 ]
{

ClassMethod Execute(%oper As %Integer = 0, ByRef pNew, ByRef pOld, ByRef pChanged, ByRef %ok, ByRef %msg) [ CodeMode = generator, ProcedureBlock = 0 ]
{
	set %code=0
		// don't generate any code if it not for a trigger
	if %mode="method" { RETURN $$$OK }
	set tClassType = $$$getClassType(%class)
		// If this class is not currently persistent and not noextent then we are done
	RETURN:'((tClassType=$$$cCLASSCLASSTYPEPERSISTENT)&&('$$$comClassKeyGet(%class,$$$cCLASSnoextent))) $$$OK
 	$$$comMemberKeyGetLvar(tLanguage,%class,$$$cCLASStrigger,%pqname,$$$cTRIGGERlanguage)
 	if tLanguage = $$$cMETHLANGUAGEPYTHON { RETURN $$$OK }	// This method is not used for Python code
 	if tLanguage '= "" {
	 	set %language = tLanguage
	 	if tLanguage = $$$cMETHLANGUAGETSQL {
		 		// need to set PROCEDUREBLOCK to 1 (true)
			$$$comSubMemberKeySet(%class,$$$cCLASStrigger,%pqname,$$$cCLASSmethod,%method,$$$cMETHprocedureblock,1)
	 	}
	 	$$$comSubMemberKeySet(%class,$$$cCLASStrigger,%pqname,$$$cCLASSmethod,%method,$$$cMETHlanguage,tLanguage)
 	}
	$$$tMetadataUses("PrecompileTriggerCode^%occTrigger(%class)")
	merge %code = $$$tMetadata("c",%pqname)
	RETURN $$$OK
}

ClassMethod ExecutePy(trigger As %Library.TriggerHelper) [ CodeMode = generator, ProcedureBlock = 0 ]
{
	set %code=0
		// don't generate any code if it not for a trigger
	if %mode="method" { RETURN $$$OK }
	set tClassType = $$$getClassType(%class)
		// If this class is not currently persistent and not noextent then we are done
	RETURN:'((tClassType=$$$cCLASSCLASSTYPEPERSISTENT)&&('$$$comClassKeyGet(%class,$$$cCLASSnoextent))) $$$OK
 	$$$comMemberKeyGetLvar(tLanguage,%class,$$$cCLASStrigger,%pqname,$$$cTRIGGERlanguage)
 	if tLanguage '= $$$cMETHLANGUAGEPYTHON { RETURN $$$OK }	// This method is only used for Python code
 	set %language = tLanguage
 	$$$comSubMemberKeySet(%class,$$$cCLASStrigger,%pqname,$$$cCLASSmethod,%method,$$$cMETHlanguage,tLanguage)
	$$$tMetadataUses("PrecompileTriggerCode^%occTrigger(%class)")
	merge %code = $$$tMetadata("c",%pqname)
	RETURN $$$OK
}

}
