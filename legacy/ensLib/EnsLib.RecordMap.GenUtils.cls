/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsRecordMap, EnsRecordMapGen)

Class EnsLib.RecordMap.GenUtils [ Abstract, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

ClassMethod checkExistingClass(pClassname As %String, Output pRegenerate As %Boolean, pOverwriteBehaviour As %Integer, pDisplay As %Integer = 2) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Set pRegenerate = 0
	If 0 = $$$defMemberKeyGet(pClassname,$$$cCLASSparameter,$$$RecordMapGenerated,$$$cPARAMdefault) {
		If pDisplay Write !,$$$FormatText($$$Text("Skipping generation for class '%1' with RECORDMAPGENERATED = 0"),pClassname)
		Quit $$$OK
	}
	If pOverwriteBehaviour = 2 {
		Quit $$$ERROR($$$ClassNameExists,pClassname)
	}
	ElseIf pOverwriteBehaviour = 1 {
		Set tOverwrite = ..confirmOverwrite(pClassname,.tStatus)
		If $$$ISERR(tStatus) Quit tStatus
		If 'tOverwrite Quit $$$OK
	}
	If pDisplay Write !,$$$FormatText($$$Text("Removing old definition for class '%1'"),pClassname)
	Set tStatus = ##class(%Dictionary.ClassDefinition).%DeleteId(pClassname)
	Set pRegenerate = $$$ISOK(tStatus) 
	Quit tStatus
}

/// Confirm overwrite of classes when running the generator from an interactive device.
ClassMethod confirmOverwrite(pClassName As %String, Output pStatus As %Status) As %Boolean [ Internal ]
{
	Try {
		Set pStatus = $$$OK
		Set tOverwrite = 0
		Write !,$$$FormatText($$$Text("Confirm overwrite of class '%1'?"),pClassName)_" Y/N "
		Read confirm:5
		If '$Test {
			Write !,$$$Text("No response entered")_"; "_$$$Text("assuming NO overwrite")
			Set tOverwrite = 0
		}
		Else {
			Set confirm = $zcvt($e(confirm),"U")
			If confirm = "Y" { 
				Write !,$$$Text("Overwriting class")
				Set tOverwrite = 1
			}
			Else { 
				Write !,$$$Text("Not overwriting class")
				Set tOverwrite = 0 
			}
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tOverwrite = 0
	}
	Quit tOverwrite
}

ClassMethod updateDescription(pDefinition As %Dictionary.ClassDefinition, pSource As %String, pModified As %Boolean = 0, pPiece As %String = "RECORDMAP: ", pType As %String = "RecordMap") [ Internal ]
{
	Set tOldDesc = $piece(pDefinition.Description,pPiece)
	Set tTS = $now()
	Set tDate = $zdate(tTS, 3)
	Set tTime = $ztime($piece(tTS, ",", 2), 1, 3)
	Set tUTCTime = $zdatetime($now(0),3,,3)
	Set tDesc = pPiece_$select(pModified: "Modified during compilation of", 1: "Generated from")_ " "_pType_" '"_pSource_"'"_$c(13,10)_"on "_tDate_" at "_tTime_" ["_tUTCTime_" UTC]"_$c(13,10)_"by user "_$Username
	Set tOldDesc = tOldDesc _ $select((tOldDesc '= "")&&($extract(tOldDesc,*-1,*) '= $c(13,10)): $c(13,10), 1:"")
	Set pDefinition.Description = tOldDesc _ tDesc
	Quit
}

ClassMethod updateAnnotation(pDefinition As %Dictionary.ClassDefinition, pAnnotation As %String = "", pDescPiece As %String = "RECORDMAP: ") [ Internal ]
{
	Set tAnnotPiece = "ANNOTATION: "
	Set tGenDesc = $piece(pDefinition.Description,pDescPiece,2)
	Set tAnnotation = $piece(pDefinition.Description,pDescPiece)
	Set tDesc = $piece(tAnnotation,tAnnotPiece,1)
	Set tAnnotation = $piece(tAnnotation,tAnnotPiece,2)
	If (pAnnotation '= "") {
		If ((pAnnotation'[$C(13,10))) Set pAnnotation = $replace(pAnnotation,$C(10),$C(13,10))
		Set tDesc = tDesc _ $select((tDesc '= "")&&($extract(tDesc,*-1,*) '= $c(13,10)): $c(13,10), 1: "") _ tAnnotPiece _ pAnnotation
	}
	If (tGenDesc '= "") {
		Set tDesc = tDesc _ $select((tDesc '= "")&&($extract(tDesc,*-1,*) '= $c(13,10)): $c(13,10), 1: "") _ pDescPiece _ tGenDesc
	}
	Set pDefinition.Description = tDesc
}

ClassMethod doCompile(pSourceClass As %String, ByRef pGeneratedClasses As %String, pCompile As %Integer = 2, pCompileFlags As %String = "ck", pPackage As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK , tGenList=""
	If (pCompile = 1) {
		Set tState = ##class(%SQL.Statement).%New()
		Set tSC = tState.%Prepare("SELECT %ID As Classname FROM %Dictionary.ClassDefinition WHERE %ID %STARTSWITH ?")
		If $$$ISERR(tSC) Quit tSC
		Set tRS = tState.%Execute(pPackage _ ".")
		While tRS.%Next() {
			$$$addGeneratedClass(tGenList,tRS.Classname)
		}
		$$$addGeneratedClass(tGenList,pSourceClass)
		Set tSC = $system.OBJ.Compile(.tGenList, pCompileFlags)
		If $$$ISERR(tSC) Quit tSC
	}
	ElseIf (pCompile = 2) {
		Merge tGenList = pGeneratedClasses
		Set tSC = $system.OBJ.Compile(.tGenList, pCompileFlags)
		If $$$ISERR(tSC) Quit tSC
	}
	Quit tSC
}

}
