/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %systemInclude

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
Class %Library.qccServer [ ClassType = donotuse ]
{

ClassMethod Run(action As %String, arg1 As %String, arg2 As %String, arg3 As %String) As %String [ PublicList = serialized ]
{
	If '$system.Security.Check("%Development","USE") Quit $$ErrorText^%qccServer($$$ERROR($$$SecurityNotDeveloper))
	If action="GetClassIndex"              Set output=$$GetClassIndex^%qccServer(.arg1,.arg2)
	If action="GetSpecialList"             Set output=$$GetSpecialList^%qccServer(.arg1,.arg2)
	If action="GetClassTimestamp"          Set output=$$GetClassTimestamp^%qccServer(.arg1)
	If action="GetClassDefinition"         Set output=$$GetClassDefinition^%qccServer(.arg1,.serialized)
	If action="GetClassDefinitionCP"       Set output=$$GetClassDefinitionCP^%qccServer(.arg1,,.serialized)
	If action="GetClassDefinitionExcess"   Set output=$$GetClassDefinitionExcess^%qccServer(.arg1,.serialized)
	If action="SaveClassDefinitionPrepare" Set output=$$SaveClassDefinitionPrepare^%qccServer(.arg1,.arg2,.serialized)
	If action="SaveClassDefinition"        Do SaveClassDefinitionPrepare^%qccServer(.arg1,.arg2,.serialized) Set output=$$SaveClassDefinition^%qccServer(.serialized)
	If action="DeleteClassDefinition"      Set output=$$DeleteClassDefinition^%qccServer(.arg1)
	If action="GetSchemaDefinition"        Set output=$$GetSchemaDefinition^%qccServer(.arg1,.arg2,0,.serialized)
	If action="LockClass"                  Set output=$$LockClass^%qccServer(.arg1)
	If action="UnlockClass"                Set output=$$UnlockClass^%qccServer(.arg1)
	If action="IsClassnameConflict"        Set output=$$IsClassnameConflict^%qccServer(.arg1)
	If action="OutputLog"                  Set output=$$OutputLog^%qccServer(.arg1)
	If action="SupportFeature"             Set output=$$SupportFeature^%qccServer(.arg1)
	If action="GetMacroList"			   Set output=$$GetMacroList^%qccServer(.arg1,.arg2,.arg3)
	If action="GetMacroSignature"		   Set output=$$GetMacroSignature^%qccServer(.arg1,.arg2)
	If action="GetMacroLocation"           Set output=$$GetMacroLocation^%qccServer(.arg1,.arg2)
	If action="GetMacroDefinition"         Set output=$$GetMacroDefinition^%qccServer(.arg1,.arg2) 
	If action="GetMacroExpansion"          Set output=$$GetMacroExpansion^%qccServer(.arg1,.arg2,.arg3)
	If action="CheckSchemaCacheUpToDate"   Set output=$$CheckSchemaCacheUpToDate^%qccServer(.arg1)
	If action="NormalizeClassname"         Set output=$$NormalizeClassname^%qccServer(.arg1,.arg2,.arg3)
	If $data(output) Quit output 
	Quit $$ErrorText^%qccServer($$$ERROR($$$GeneralError,"Invalid function for %qccServer"))
}

}
