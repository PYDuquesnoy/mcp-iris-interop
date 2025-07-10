/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsRecordMap, EnsRecordMapGen)

Class EnsLib.RecordMap.ComplexGenerator Extends EnsLib.RecordMap.GenUtils [ Abstract, System = 4 ]
{

/// Advisory to include on generated Class and Method Definitions that further external customization is not supported
Parameter GENERATEDADVISORY = {"THIS IS GENERATED CODE. DO NOT EDIT.<br/>"_$C(13,10)};

/// Generate a parser and persistent objects for the Complex RecordMap specified in <var>pComplexMap</var>.
/// The arguments are as follows:
/// <ul><li><var>pComplexMap</var>: the Complex RecordMap to generate the class definitions from.</li>
/// <li><var>pGenerateRecordMaps</var> controls updates to the RecordMaps specified in the map. The permitted values are:
/// <ul><li>0: No updates to any generated RecordMap classes.</li>
/// <li>1: The RecordMaps referenced by the Complex RecordMap should be completely regenerated.</li></ul></li>
/// <li><var>pCompile</var>: control compilation of the generated classes. Possible values are:
/// <ul><li>0: Do not compile. A list of generated classes will be returned in the "Generated" subscript
/// 				of the pCompile variable.</li>
/// <li>1: Compile entire package using $system.OBJ.CompilePackage() (also compiles RecordMap class)</li>
/// <li>2: Compile generated classes as a group and then recompile ComplexMap class [Default]</li></ul>
/// <li><var>pDisplay</var>: control display options for the current device. Possible values are:
/// 	<ul><li>0: Do not display any output</li>
/// 	<li>1: Display basic object structure and compiler output</li>
/// 	<li>2: Display detailed object structure, including type information [Default]</li></ul>
/// <li><var>pCompileFlags</var>: compiler flags to use during the compilation.
/// 		Note that "-d" is added to the compiler flags if <var>pDisplay</var>=0</li>
/// <li><var>pOverwriteBehaviour</var>: control behaviour if a class already exists. Options are:
/// 	<ul><li>0: Always overwrite existing classes</li>
/// 	<li>1: Prompt for user input before overwriting. NOTE: this option requires a terminal interface.</li>
/// 	<li>2: Never overwrite. This prevents generation of further classes [Default from terminal]</li></ul></li>
/// <li><var>pGeneratedClasses</var>: an array of classes that were generated in the call to the method.
/// The list includes all classes that were generated, even if an error occurs.</li>
/// <li><var>pKeepStorage</var>: flag to control whether we retain the existing storage definition. The flag is
/// needed to ensure that we can add properties to an existing object without corrupting existing data. That said,
/// it may be necessary during development to modify the structure, so this flag can be set to 0 to remove
/// the existing storage definition.</li>
/// </ul>
ClassMethod Generate(pComplexMap As %String = "", pGenerateRecordMaps As %Integer = 0, ByRef pCompile As %Integer = 2, pDisplay As %Integer = 2, pCompileFlags As %String = "ck", pOverwriteBehaviour As %Integer = 2, Output pGeneratedClasses As %String, pKeepStorage As %Boolean = 1) As %Status
{
	Set tStatus = $$$OK
	Try {
		Kill pGeneratedClasses
		Set pGeneratedClasses = 0
		Kill tOldStorage
		If '##class(EnsLib.RecordMap.Model.ComplexBatch).Exists(pComplexMap) {
			Set tStatus = $$$ERROR($$$ClassDoesNotExist,pComplexMap)
			Quit
		}
		Set pComplexMap = $$$NormalizeClassname(pComplexMap)
		Set tBatchModel = ##class(EnsLib.RecordMap.Model.ComplexBatch).LoadFromClass(pComplexMap,.tStatus)
		If $$$ISERR(tStatus) Quit
		
		If pDisplay = 0 { Set pCompileFlags = pCompileFlags_"-d" }

		Set tTargetClass = tBatchModel.targetClassname
		If ##class(%Dictionary.ClassDefinition).%ExistsId(tTargetClass) {
			If (pKeepStorage) {
				Merge tOldStorage = ^oddDEF(tTargetClass,$$$cCLASSstorage)
			}
			Set tStatus = ..checkExistingClass(tTargetClass,.tRegenerate,pOverwriteBehaviour,pDisplay)
			If $$$ISERR(tStatus) || ('tRegenerate) Quit
		}

		Set tClassDef = ##class(%Dictionary.ClassDefinition).%New()
		Set tClassDef.Name = tTargetClass
		Set tClassDef.Super = "EnsLib.RecordMap.ComplexBatch,Ens.Request"
		Set tClassDef.ProcedureBlock = 1
		Set tClassDef.Description = ..#GENERATEDADVISORY_tBatchModel.annotation
		Do ..updateDescription(tClassDef,pComplexMap,1,,"Complex RecordMap")
		Set tStatus = tClassDef.%Save()
		If $$$ISERR(tStatus) Quit
		$$$addGeneratedClass(pGeneratedClasses,tTargetClass)
		Merge ^oddDEF(tTargetClass,$$$cCLASSstorage) = tOldStorage

		Set tSequenceNumber = 1

		Set tGeneratedParm = ##class(%Dictionary.ParameterDefinition).%New()
		Set tGeneratedParm.parent = tClassDef
		Set tGeneratedParm.Name = $$$RecordMapGenerated
		Set tGeneratedParm.Default = 1
		Set tGeneratedParm.SequenceNumber = $$$nextSequenceNumber(tSequenceNumber)

		Set tGroupPackage = $piece(tTargetClass,".",1,$length(tTargetClass,".")-1)
		Set tStatus = ..buildMap(tBatchModel,tGroupPackage,.tMap)
		If $$$ISERR(tStatus) Quit
		New %map
		Merge %map = tMap

		If $IsObject(tBatchModel.Header) {
			Set tStatus = ..generateReference(tBatchModel.Header,tClassDef,.tSequenceNumber,pGenerateRecordMaps,pCompile,pDisplay,pCompileFlags,pOverwriteBehaviour,.pGeneratedClasses,pKeepStorage)
			If $$$ISERR(tStatus) Quit
		}

		For i=1:1:tBatchModel.Elements.Count() {
			Set tRecord = tBatchModel.Elements.GetAt(i)
			If $classname(tRecord) = "EnsLib.RecordMap.Model.RecordReference" {
				Set tStatus = ..generateReference(tRecord,tClassDef,.tSequenceNumber,pGenerateRecordMaps,pCompile,pDisplay,pCompileFlags,pOverwriteBehaviour,.pGeneratedClasses,pKeepStorage)
				If $$$ISERR(tStatus) Quit
			}
			ElseIf $classname(tRecord) = "EnsLib.RecordMap.Model.RecordSequence" {
				Set tStatus = ..generateSequence(tRecord,tClassDef,.tSequenceNumber,pGenerateRecordMaps,pCompile,pDisplay,pCompileFlags,pOverwriteBehaviour,.pGeneratedClasses,pKeepStorage,","_i)
				If $$$ISERR(tStatus) Quit
			}
		}
		If $$$ISERR(tStatus) Quit

		If $IsObject(tBatchModel.Trailer) {
			Set tStatus = ..generateReference(tBatchModel.Trailer,tClassDef,.tSequenceNumber,pGenerateRecordMaps,pCompile,pDisplay,pCompileFlags,pOverwriteBehaviour,.pGeneratedClasses,pKeepStorage)
			If $$$ISERR(tStatus) Quit
		}
		
		Set tStatus = ..generateOnClose(tClassDef)
		If $$$ISERR(tStatus) Quit

		Set tMapDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pComplexMap,,.tStatus)
		If $$$ISERR(tStatus) Quit

		Set tBatchSequence = 2
		
		If ##class(%Dictionary.ParameterDefinition).IDKEYExists(pComplexMap,$$$RecordMapGenerated) {
			Set tGenParm = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(pComplexMap,$$$RecordMapGenerated,,.tStatus)
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Set tGenParm = ##class(%Dictionary.ParameterDefinition).%New()
			Set tGenParm.parent = tMapDefinition
			Set tGenParm.Name = $$$RecordMapGenerated
		}
		Set tGenParm.Default = 1
		
		If ##class(%Dictionary.ParameterDefinition).IDKEYExists(pComplexMap,"BATCHCLASS") {
			Set tMapParm = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(pComplexMap,"BATCHCLASS",,.tStatus)
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Set tMapParm = ##class(%Dictionary.ParameterDefinition).%New()
			Set tMapParm.parent = tMapDefinition
			Set tMapParm.Name = "BATCHCLASS"
		}
		Set tMapParm.SequenceNumber = $$$nextSequenceNumber(tBatchSequence)
		Set tMapParm.Default = tTargetClass
		
		Set tStatus = ..generatePutBatch(tMapDefinition,.tBatchSequence)
		If $$$ISERR(tStatus) Quit
		
		Set tStatus = ..generateGetBatch(tMapDefinition,.tBatchSequence)
		If $$$ISERR(tStatus) Quit
		
		Set tStatus = tMapDefinition.%Save()
		If $$$ISERR(tStatus) Quit
		Set pGeneratedClasses(tMapDefinition.Name) = ""
		
		Kill tCompiledClasses
		Set tClass = ""
		For {
			Set tClass = $order(pGeneratedClasses(tClass),1,tIsCompiled)
			Quit:(tClass = "")
			If tIsCompiled {
				Set tCompiledClasses(tClass) = ""
				Kill pGeneratedClasses(tClass)
			}
		}
		
		Kill %map
		If pCompile {
			Set tStatus = ..doCompile(pComplexMap,.pGeneratedClasses,pCompile,pCompileFlags,tGroupPackage)
			If $$$ISERR(tStatus) Quit
		}
		Merge pGeneratedClasses = tCompiledClasses
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Given a saved Complex RecordMap, produce a list of the classes which
/// will be generated for the RecordMap
ClassMethod GetGeneratedObjects(pComplexMap As %String, pIncludeRecordMaps As %Boolean = 0, Output pClassList, Output pTargetClassname As %String = "") As %Status [ Internal ]
{
	Try {
		Set tStatus = $$$OK
		Kill pClassList
		If '##class(EnsLib.RecordMap.Model.ComplexBatch).Exists(pComplexMap,.tStatus) {
			If $$$ISERR(tStatus) Quit
			Set tStatus = $$$ERROR($$$ClassDoesNotExist,pComplexMap)
			Quit
		}
		
		Set tModel = ##class(EnsLib.RecordMap.Model.ComplexBatch).LoadFromClass(pComplexMap,.tStatus)
		If $$$ISERR(tStatus) Quit
		
		Set pTargetClassname = $$$NormalizeClassname(tModel.targetClassname)
		
		Set tStatus = ..buildMap(tModel,,.tMap)
		If $$$ISERR(tStatus) Quit
		
		Merge pClassList = tMap("ClassList")
		Set pClassList($$$NormalizeClassname(pComplexMap)) = ""
		Set pClassList(pTargetClassname) = ""
		If pIncludeRecordMaps {
			Set tMapKey = ""
			For {
				Set tMapKey = $order(tMap("RecordMaps",tMapKey))
				Quit:(tMapKey = "")
				Kill tMapClasses
				Set tStatus = ##class(EnsLib.RecordMap.Generator).GetGeneratedObjects(tMapKey,.tMapClasses)
				If $$$ISERR(tStatus) Quit
				Merge pClassList = tMapClasses
			}
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

ClassMethod generateSequence(pSequence As EnsLib.RecordMap.Model.RecordSequence, pParentDefinition As %Dictionary.ClassDefinition, ByRef pSequenceNumber As %Integer = 1, pGenerateRecordMaps As %Boolean = 0, ByRef pCompile As %Integer = 2, pDisplay As %Integer = 2, pCompileFlags As %String = "ck", pOverwriteBehaviour As %Integer = 2, Output pGeneratedClasses As %String, pKeepStorage As %Boolean = 1, pSeqNode As %String = "") As %Status
{
	Set tStatus = $$$OK
	Kill tOldStorage
	Set tSequenceClassname = $get(%map("GroupPackage")) _ "." _ pSequence.name
	If ##class(%Dictionary.ClassDefinition).%ExistsId(tSequenceClassname) {
		If (pKeepStorage) {
			Merge tOldStorage = ^oddDEF(tSequenceClassname,$$$cCLASSstorage)
		}
		Set tStatus = ..checkExistingClass(tSequenceClassname,.tRegenerate,pOverwriteBehaviour,pDisplay)
		If $$$ISERR(tStatus) || ('tRegenerate) Quit tStatus
	}
	Set tSequenceDef = ##class(%Dictionary.ClassDefinition).%New()
	Set tSequenceDef.Name = tSequenceClassname
	Set tSequenceDef.ProcedureBlock = 1
	Set tSequenceDef.Super = "EnsLib.RecordMap.ComplexSequence,%XML.Adaptor"
	Do ..updateAnnotation(tSequenceDef,pSequence.annotation)
	
	$$$addGeneratedClass(pGeneratedClasses,tSequenceDef.Name)
	
	Set tGenParm = ##class(%Dictionary.ParameterDefinition).%New()
	Set tGenParm.parent = tSequenceDef
	Set tGenParm.Name = $$$RecordMapGenerated
	Set tGenParm.Default = 1
	Do ..updateDescription(tSequenceDef,$get(%map("ComplexMap")),1,,"Complex RecordMap")
	
	// Generate all referenced classes first
	Set tSequenceNumber = 1
	For i=1:1:pSequence.Elements.Count() {
		#dim tElement As EnsLib.RecordMap.Model.BatchElement
		Set tElement = pSequence.Elements.GetAt(i)
		If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
			Set tStatus = ..generateReference(tElement,tSequenceDef,.tSequenceNumber,pGenerateRecordMaps,pCompile,pDisplay,pCompileFlags,pOverwriteBehaviour,.pGeneratedClasses,pKeepStorage)
			If $$$ISERR(tStatus) Quit
		}
		ElseIf $classname(tElement) = "EnsLib.RecordMap.Model.RecordSequence" {
			Set tStatus = ..generateSequence(tElement,tSequenceDef,.tSequenceNumber,pGenerateRecordMaps,pCompile,pDisplay,pCompileFlags,pOverwriteBehaviour,.pGeneratedClasses,pKeepStorage,pSeqNode_","_i)
			If $$$ISERR(tStatus) Quit
		}
	}
	If $$$ISERR(tStatus) Quit tStatus
	Set tStatus = ..generateOnClose(tSequenceDef,pSeqNode)
	If $$$ISERR(tStatus) Quit tStatus
	Set tStatus = ..generatePutSequence(tSequenceDef,pSequence,.tSequenceNumber)
	If $$$ISERR(tStatus) Quit tStatus
	
	Set tOnDelTrigger = ##class(%Dictionary.TriggerDefinition).%New()
	Set tOnDelTrigger.parent = tSequenceDef
	Set tOnDelTrigger.Name = "OnDeleteTrigger"
	Set tOnDelTrigger.Event = "DELETE"
	Set tOnDelTrigger.Code = $c(9)_"Set %ok = ##class("_tSequenceDef.Name_").%OnDelete($$$oidForm({ID}))"_$c(13,10)
	Set tOnDelTrigger.SequenceNumber = $$$nextSequenceNumber(tSequenceNumber)

	Set tStatus = tSequenceDef.%Save()
	If $$$ISERR(tStatus) Quit tStatus

	Set tPropDef = ##class(%Dictionary.PropertyDefinition).%New()
	Set tPropDef.parent = pParentDefinition
	Set tPropDef.Name = pSequence.name

	Set tPropDef.Type = tSequenceDef.Name
	Set tPropDef.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
	If pSequence.repeating {
		Set tPropDef.Collection = "array"
	}
	Set tMinRepeats = pSequence.minRepeats
	If pSequence.required {
		Set tPropDef.Required = 1
		If tMinRepeats = 1 Set tMinRepeats = 0
	}
	If tMinRepeats {
		Do tPropDef.Parameters.SetAt(tMinRepeats,"MINREPEATS")
	}
	If pSequence.maxRepeats {
		Do tPropDef.Parameters.SetAt(pSequence.maxRepeats,"MAXREPEATS")
	}
	Set tStatus = tPropDef.%Save()
	If $$$ISERR(tStatus) Quit tStatus
	Merge ^oddDEF(tSequenceClassname,$$$cCLASSstorage) = tOldStorage
	Quit tStatus
}

ClassMethod generateReference(pReference As EnsLib.RecordMap.Model.RecordReference, pParentDefinition As %Dictionary.ClassDefinition, ByRef pSequenceNumber As %Integer = 1, pGenerateRecordMaps As %Integer = 1, ByRef pCompile As %Integer = 2, pDisplay As %Integer = 2, pCompileFlags As %String = "ck", pOverwriteBehaviour As %Integer = 2, ByRef pGeneratedClasses As %String, pKeepStorage As %Boolean = 1) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tRecordModel = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(pReference.recordMap,.tStatus)
		If $$$ISERR(tStatus) Quit
		If pGenerateRecordMaps {
			Kill tGenerated
			Set tStatus = ##class(EnsLib.RecordMap.Generator).GenerateObject(pReference.recordMap,tRecordModel.targetClassname,,,pCompile,pDisplay,pCompileFlags,pOverwriteBehaviour,.tGenerated,pKeepStorage)
			If $$$ISERR(tStatus) Quit
			Set tGenKey = ""
			For {
				Set tGenKey = $order(tGenerated(tGenKey))
				Quit:(tGenKey = "")
				If pCompile {
					$$$addCompiledClass(pGeneratedClasses,tGenKey)
				}
				Else {
					$$$addGeneratedClass(pGeneratedClasses,tGenKey)
				}
			}
		}
		ElseIf pDisplay {
			Write !,"Not (re)generating RecordMap '"_pReference.recordMap_"'"
		}
		Set tPropDef = ##class(%Dictionary.PropertyDefinition).%New()
		Set tPropDef.parent = pParentDefinition
		Set tPropDef.Name = pReference.name
		Set tPropDef.Type = tRecordModel.targetClassname
		Set tPropDef.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
		If pReference.%IsA("EnsLib.RecordMap.Model.HeaderTrailer") {
			Set tPropDef.Required = 1
		}
		Else {
			If pReference.repeating {
				Set tPropDef.Collection = $select(pParentDefinition.Name = $get(%map("BatchClass")): "array", 1: "array")
			}
			Set tMinRepeats = pReference.minRepeats
			If pReference.required {
				Set tPropDef.Required = 1
				If tMinRepeats = 1 Set tMinRepeats = 0
			}
			If tMinRepeats {
				Do tPropDef.Parameters.SetAt(tMinRepeats,"MINREPEATS")
			}
			If pReference.maxRepeats {
				Do tPropDef.Parameters.SetAt(pReference.maxRepeats,"MAXREPEATS")
			}
		}
		Set tStatus = tPropDef.%Save()
		If $$$ISERR(tStatus) Quit
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod generateGetBatch(pDefinition As %Dictionary.ClassDefinition, ByRef pSequenceNumber As %Integer = 1) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Try {
		If ##class(%Dictionary.MethodDefinition).IDKEYExists(pDefinition.Name,"GetBatch") {
			Set tMethod = ##class(%Dictionary.MethodDefinition).IDKEYOpen(pDefinition.Name,"GetBatch",,.tStatus)
			If $$$ISERR(tStatus) Quit
			Do tMethod.Implementation.Clear()
		}
		Else {
			Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
			Set tMethod.Name = "GetBatch"
			Set tMethod.parent = pDefinition
		}
		Set tMethod.ClassMethod = 1
		Set tMethod.FormalSpec = "pIOStream:%IO.DeviceStream,pTimeout:%Numeric=-1,*pBatch:EnsLib.RecordMap.ComplexBatch,&pLookAhead:%String="""""
		Set tMethod.ReturnType = "%Status"
		Set tMethod.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
	
		$$$WriteCode(tMethod,$c(9)_"Set tStatus = $$$OK")
		$$$WriteCode(tMethod,$c(9)_"Try {")
		$$$WriteCode(tMethod,$c(9,9)_"If '$IsObject(pIOStream) {")
		$$$WriteCode(tMethod,$c(9,9,9)_"Set tFilename = pIOStream")
		$$$WriteCode(tMethod,$c(9,9,9)_"Set pIOStream = ##class(%IO.FileStream).%New()")
		$$$WriteCode(tMethod,$c(9,9,9)_"Do pIOStream.Open(tFilename,,pTimeout,"""_$get(%map("charEncoding"),"UTF-8")_""",.tStatus)")
		$$$WriteCode(tMethod,$c(9,9,9)_"If $$$ISERR(tStatus) Quit")
		$$$WriteCode(tMethod,$c(9,9)_"}")
		$$$WriteCode(tMethod,$c(9,9)_"Set pIOStream.CharEncoding = """_$get(%map("charEncoding"),"UTF-8")_"""")
		$$$WriteCode(tMethod,$c(9,9)_"Set pBatch = ##class("_$get(%map("BatchClass"))_").%New()")
		$$$WriteCode(tMethod,$c(9,9)_"Set pBatch.%Source = pIOStream.Name")
		$$$WriteCode(tMethod,$c(9,9)_"Set pLookAhead = $get(pLookAhead)")
	
		If $data(%map("Header"))#10 {
			Set tHeader = $$$ComplexMapGetOref("Header")
			$$$WriteCode(tMethod,$c(9,9)_"Set tStatus = ##class("_tHeader.recordMap_").GetObject(pIOStream,.tHeader,pTimeout,.pLookAhead)")
			$$$WriteCode(tMethod,$c(9,9)_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexBasic,"""_tHeader.name_""","""_tHeader.recordMap_""",$classname()),tStatus) Quit")
			$$$WriteCode(tMethod,$c(9,9)_"Set pBatch."_tHeader.name_" = tHeader")		}
	
		If $listget($get(%map)) { // explicit map
			Set tKey = ""
			For {
				Set tKey = $order(%map("Records",tKey))
				Quit:(tKey = "")
				Continue:(tKey '= +tKey)
				If $data(%map("Records",tKey,1)) {
					Set tStatus = ..generateGetSequence(tMethod,tKey,.pSequenceNumber)
					If $$$ISERR(tStatus) Quit
				}
				Else {
					Set tRecordRef = $$$ComplexMapGetOref("Records",tKey)
					Set tStatus = ..generateGetRecord(tMethod,tRecordRef,tKey,1)
					If $$$ISERR(tStatus) Quit
				}
			}
			If $$$ISERR(tStatus) Quit
		}
		Else { // variable map
			Set tKey = ""
			For {
				Set tKey = $order(%map("Records",tKey),1,tExplicit)
				Quit:(tKey = "")
				Continue:(tKey '= +tKey)
				Set tElement = $$$ComplexMapGetOref("Records",tKey)
				If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
					Set tStatus = ..generateGetRecord(tMethod,tElement,tKey,tExplicit)
					If $$$ISERR(tStatus) Quit
				}
				ElseIf $data(%map("Records",tKey,1)) {
					Set tStatus = ..generateGetSequence(tMethod,tKey,.pSequenceNumber)
					If $$$ISERR(tStatus) Quit
				}
			}
			If $$$ISERR(tStatus) Quit
		}
		If $data(%map("Trailer")) {
			Set tTrailer = $$$ComplexMapGetOref("Trailer")
			$$$WriteCode(tMethod,$c(9,9)_"Set tStatus = ##class("_tTrailer.recordMap_").GetObject(pIOStream,.tTrailer,pTimeout,.pLookAhead)")
			$$$WriteCode(tMethod,$c(9,9)_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexBasic,"""_tTrailer.name_""","""_tTrailer.recordMap_""",$classname()),tStatus) Quit")
			$$$WriteCode(tMethod,$c(9,9)_"Set pBatch."_tTrailer.name_" = tTrailer")
		}
	
		$$$WriteCode(tMethod,$c(9)_"} Catch {")
		$$$WriteCode(tMethod,$c(9,9)_"Set tStatus = $$$SystemError")
		$$$WriteCode(tMethod,$c(9)_"}")
		$$$WriteCode(tMethod,$c(9)_"Quit tStatus")
		Set tStatus = tMethod.%Save()
		If $$$ISERR(tStatus) Quit
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod generateGetRecord(pMethodDefinition As %Dictionary.MethodDefinition, pRecordRef As EnsLib.RecordMap.Model.RecordReference, pSeqNode As %String, pExplicit As %Boolean = 1, pParentRef As %String = "pBatch", pIndent As %String = {$c(9,9)}) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Try {
		Set tIndent = pIndent
		If pExplicit {
			If pRecordRef.repeating && (pRecordRef.minRepeats > 1) {
				$$$WriteCode(pMethodDefinition,tIndent_"For i=1:1:"_pRecordRef.minRepeats_" {")
				Set tIndent = tIndent _ $c(9)
			}
			$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = ##class("_pRecordRef.recordMap_").GetObject(pIOStream,.tObject,pTimeout,.pLookAhead)")
			If pRecordRef.repeating && (pRecordRef.minRepeats > 1) {
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = tObject.%Save()")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = "_pParentRef_"."_pRecordRef.name_".SetAt(tObject,i)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = "_pParentRef_"."_pRecordRef.name_".%UnSwizzleAt(i)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				Set tIndent = $extract(tIndent,1,*-1)
				$$$WriteCode(pMethodDefinition,tIndent_"}")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexRepeating,"""_pRecordRef.name_""","""_pRecordRef.recordMap_""",$classname(),i),tStatus) Quit")
			}
			Else {
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexBasic,"""_pRecordRef.name_""","""_pRecordRef.recordMap_""",$classname()),tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set "_pParentRef_"."_pRecordRef.name_" = tObject")
			}
		}
		Else {
			Set tLoc = "%map(""Records"","_pSeqNode_")"
			Set tIdent = $order(@tLoc@("idents",""))
			Set tIdentLen = $length(tIdent)
			$$$WriteCode(pMethodDefinition,tIndent_"If ("_tIdentLen_" > $length(pLookAhead)) {")
			$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set pLookAhead = pLookAhead _ pIOStream.Read("_tIdentLen_"-$length(pLookAhead),pTimeout,.tStatus)")
			$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
			$$$WriteCode(pMethodDefinition,tIndent_"}")
			
			If pRecordRef.repeating {
				#; The code below gets as many records as it can until we trigger the maxRepeats condition
				#; We could get only as many as specified, but would then choke on next record in a possible non-user-friendly way
				$$$WriteCode(pMethodDefinition,tIndent_"Set tCount = 0")
				$$$WriteCode(pMethodDefinition,tIndent_"While ($extract(pLookAhead,1,"_tIdentLen_") = """_$Replace(tIdent,"""","""""")_""") {")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set tStatus = ##class("_pRecordRef.recordMap_").GetObject(pIOStream,.tObject,pTimeout,.pLookAhead)")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set tCount = tCount + 1")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
				If pRecordRef.maxRepeats {
					$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If ("_pRecordRef.maxRepeats_" < tCount) {")
					$$$WriteCode(pMethodDefinition,tIndent_$c(9,9)_"Set tStatus = $$$ERROR($$$EnsRecordMapErrRepeatMax,"_pRecordRef.maxRepeats_","""_pRecordRef.name_""")")
					$$$WriteCode(pMethodDefinition,tIndent_$c(9,9)_"Quit")
					$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"}")
				}
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set tStatus = tObject.%Save()")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set tStatus = "_pParentRef_"."_pRecordRef.name_".SetAt(tObject,tCount)")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set tStatus = "_pParentRef_"."_pRecordRef.name_".%UnSwizzleAt(tCount)")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If ("_tIdentLen_" > $length(pLookAhead)) {")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9,9)_"Set pLookAhead = pLookAhead _ pIOStream.Read("_tIdentLen_"-$length(pLookAhead),pTimeout,.tStatus)")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9,9)_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"}")
				$$$WriteCode(pMethodDefinition,tIndent_"}")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexRepeating,"""_pRecordRef.name_""","""_pRecordRef.recordMap_""",$classname(),tCount),tStatus) Quit")
				If pRecordRef.minRepeats {
					$$$WriteCode(pMethodDefinition,tIndent_"If ("_pRecordRef.minRepeats_" > tCount) {")
					$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set tStatus = $$$ERROR($$$EnsRecordMapErrRepeatMin,"_pRecordRef.minRepeats_","""_pRecordRef.name_""")")
					$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Quit")
					$$$WriteCode(pMethodDefinition,tIndent_"}")
				}
			}
			Else {
				$$$WriteCode(pMethodDefinition,tIndent_"If ($extract(pLookAhead,1,"_tIdentLen_") = """_$Replace(tIdent,"""","""""")_""") {")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set tStatus = ##class("_pRecordRef.recordMap_").GetObject(pIOStream,.tObject,pTimeout,.pLookAhead)")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexBasic,"""_pRecordRef.name_""","""_pRecordRef.recordMap_""",$classname()),tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_$c(9)_"Set "_pParentRef_"."_pRecordRef.name_" = tObject")
				$$$WriteCode(pMethodDefinition,tIndent_"}")
			}
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod generateGetSequence(pMethodDefinition As %Dictionary.MethodDefinition, pSeqNode As %String, ByRef pSequenceNumber As %Integer = 1, pParentRef As %String = "pBatch", pIndent As %String = {$c(9,9)}) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Try {
		Set tIndent = pIndent
		Set tLoc = "%map(""Records"","_pSeqNode_")"
		Set tOrefLoc = "%map(""Records"","_pSeqNode_",""oref"")"
		Set tExplicit = $get(@tLoc)
		Set tSequence = $get(@tOrefLoc)
		Set tSeqMethodName = "getSeq"_tSequence.name
		Set tSeqClassname = $get(%map("GroupPackage"))_"."_tSequence.name
		
		// Generate wrapper code in parent method
		If tExplicit { // Explicit definition
			If tSequence.repeating && (tSequence.maxRepeats > 1) {
				$$$WriteCode(pMethodDefinition,tIndent_"For i=1:1:"_tSequence.maxRepeats_" {")
				Set tIndent = tIndent _ $c(9)
			}
			$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = .."_tSeqMethodName_"(pIOStream,.tSequence,.pLookAhead,pBatch,pTimeout)")
			If tSequence.repeating && (tSequence.maxRepeats > 1) {
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = tSequence.%Save()")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = "_pParentRef_"."_tSequence.name_".SetAt(tSequence,i)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = "_pParentRef_"."_tSequence.name_".%UnSwizzleAt(i)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				Set tIndent = $extract(tIndent,1,*-1)
				$$$WriteCode(pMethodDefinition,tIndent_"}")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexRepeating,"""_tSequence.name_""","""_tSeqClassname_""",$classname(),i),tStatus) Quit")
			}
			Else {
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexBasic,"""_tSequence.name_""","""_tSeqClassname_""",$classname()),tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set "_pParentRef_"."_tSequence.name_" = tSequence")
			}
		}
		Else {
			Set tIdentCondition = ""
			Set tMaxIdent = 0
			Set tIdent = ""
			For {
				Set tIdent = $order(@tLoc@("idents",tIdent))
				Quit:(tIdent = "")
				Set tIdentLen = $length(tIdent)
				If tIdentLen > tMaxIdent Set tMaxIdent = tIdentLen
				Set tIdentCondition = tIdentCondition_$select(tIdentCondition="": "", 1:"||")_"($extract(pLookAhead,1,"_tIdentLen_")="""_$Replace(tIdent,"""","""""")_""")"
			}
			$$$WriteCode(pMethodDefinition,tIndent_"If ("_tMaxIdent_" > $length(pLookAhead)) {")
			Set tIndent = tIndent _ $c(9)
			$$$WriteCode(pMethodDefinition,tIndent_"Set pLookAhead = pLookAhead _ pIOStream.Read("_tMaxIdent_"-$length(pLookAhead),pTimeout,.tStatus)")
			$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexBasic,"""_tSequence.name_""","""_tSeqClassname_""",$classname()),tStatus) Quit")
			Set tIndent = $extract(tIndent,1,*-1)
			$$$WriteCode(pMethodDefinition,tIndent_"}")
			
			If tSequence.repeating {
				#; The code below gets as many records as it can until we trigger the maxRepeats condition
				#; We could get only as many as specified, but would then choke on next record in a possible non-user-friendly way
				$$$WriteCode(pMethodDefinition,tIndent_"Set tCount = 0")
				$$$WriteCode(pMethodDefinition,tIndent_"While "_tIdentCondition_" {")
				Set tIndent = tIndent _ $c(9)
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = .."_tSeqMethodName_"(pIOStream,.tSequence,.pLookAhead,pBatch,pTimeout)")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tCount = tCount + 1")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				If tSequence.maxRepeats {
					$$$WriteCode(pMethodDefinition,tIndent_"If ("_tSequence.maxRepeats_" < tCount) {")
					Set tIndent = tIndent _ $c(9)
					$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = $$$ERROR($$$EnsRecordMapErrRepeatMax,"_tSequence.maxRepeats_","""_tSequence.name_""")")
					$$$WriteCode(pMethodDefinition,tIndent_"Quit")
					Set tIndent = $extract(tIndent,1,*-1)
					$$$WriteCode(pMethodDefinition,tIndent_"}")
				}
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = tSequence.%Save()")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = "_pParentRef_"."_tSequence.name_".SetAt(tSequence,tCount)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = "_pParentRef_"."_tSequence.name_".%UnSwizzleAt(tCount)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"If ("_tMaxIdent_" > $length(pLookAhead)) {")
				Set tIndent = tIndent _ $c(9)
				$$$WriteCode(pMethodDefinition,tIndent_"Set pLookAhead = pLookAhead _ pIOStream.Read("_tMaxIdent_"-$length(pLookAhead),pTimeout,.tStatus)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Quit")
				Set tIndent = $extract(tIndent,1,*-1)
				$$$WriteCode(pMethodDefinition,tIndent_"}")
				Set tIndent = $extract(tIndent,1,*-1)
				$$$WriteCode(pMethodDefinition,tIndent_"}")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexRepeating,"""_tSequence.name_""","""_tSeqClassname_""",$classname(),tCount),tStatus) Quit")
				If tSequence.minRepeats {
					$$$WriteCode(pMethodDefinition,tIndent_"If ("_tSequence.minRepeats_" > tCount) {")
					Set tIndent = tIndent _ $c(9)
					$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = $$$ERROR($$$EnsRecordMapErrRepeatMin,"_tSequence.minRepeats_","""_tSequence.name_""")")
					$$$WriteCode(pMethodDefinition,tIndent_"Quit")
					Set tIndent = $extract(tIndent,1,*-1)
					$$$WriteCode(pMethodDefinition,tIndent_"}")
				}
			}
			Else {
				$$$WriteCode(pMethodDefinition,tIndent_"If "_tIdentCondition_" {")
				Set tIndent = tIndent _ $c(9)
				$$$WriteCode(pMethodDefinition,tIndent_"Set tStatus = .."_tSeqMethodName_"(pIOStream,.tSequence,.pLookAhead,pTimeout)")
				$$$WriteCode(pMethodDefinition,tIndent_"If $$$ISERR(tStatus) Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsRecordMapErrComplexBasic,"""_tSequence.name_""","""_tSeqClassname_""",$classname()),tStatus) Quit")
				$$$WriteCode(pMethodDefinition,tIndent_"Set "_pParentRef_"."_tSequence.name_" = tSequence")
				Set tIndent = $extract(tIndent,1,*-1)
				$$$WriteCode(pMethodDefinition,tIndent_"}")
			}
		}

		// Generate code inside sequence method
		If ##class(%Dictionary.MethodDefinition).IDKEYExists(pMethodDefinition.parent.Name,tSeqMethodName) {
			Set tSeqMethod = ##class(%Dictionary.MethodDefinition).IDKEYOpen(pMethodDefinition.parent.Name,tSeqMethodName,,.tStatus)
			If $$$ISERR(tStatus) Quit
			// Swizzle tSeqMethod.parent to ensure the parent has a reference to this method during save
			If (tSeqMethod.parent '= pMethodDefinition.parent) Set tSeqMethod.parent = pMethodDefinition.parent
		}
		Else {
			Set tSeqMethod = ##class(%Dictionary.MethodDefinition).%New()
			Set tSeqMethod.parent = pMethodDefinition.parent
			Set tSeqMethod.Name = tSeqMethodName
		}
		Set tSeqMethod.ClassMethod = 1
		Set tSeqMethod.Private = 1
		Set tSeqMethod.FormalSpec = "pIOStream:%IO.DeviceStream,*pSequence:EnsLib.RecordMap.ComplexSequence,&pLookAhead:%String="""",pBatch:EnsLib.RecordMap.ComplexBatch,pTimeout:%Numeric=-1"
		Set tSeqMethod.ReturnType = "%Status"
		Set tSeqMethod.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
		Set tStatus = tSeqMethod.Implementation.Clear(1)
		If $$$ISERR(tStatus) Quit

		Set tSeqIndent = $c(9)
		$$$WriteCode(tSeqMethod,tSeqIndent_"Set tStatus = $$$OK")
		$$$WriteCode(tSeqMethod,tSeqIndent_"Try {")
		Set tSeqIndent = $c(9,9)
		$$$WriteCode(tSeqMethod,tSeqIndent_"Set pSequence = ##class("_$get(%map("GroupPackage"))_"."_tSequence.name_").%New()")

		Set tKey = ""
		For {
			Set tExplicit = 0
			Set tKey = $order(@tLoc@(tKey),1,tExplicit)
			Quit:(tKey = "")
			Continue:(tKey '= +tKey)
			Set tElement = $get(@tLoc@(tKey,"oref"))
			If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
				Set tStatus = ..generateGetRecord(tSeqMethod,tElement,pSeqNode_","_tKey,tExplicit,"pSequence",tSeqIndent)
				If $$$ISERR(tStatus) Quit
			}
			Else {
				Set tStatus = ..generateGetSequence(tSeqMethod,pSeqNode_","_tKey,.pSequenceNumber,"pSequence",tSeqIndent)
				If $$$ISERR(tStatus) Quit
			}
		}
		Set tSeqIndent = $c(9)
		$$$WriteCode(tSeqMethod,tSeqIndent_"}")
		$$$WriteCode(tSeqMethod,tSeqIndent_"Catch {")
		$$$WriteCode(tSeqMethod,tSeqIndent_$c(9)_"Set tStatus = $$$SystemError")
		$$$WriteCode(tSeqMethod,tSeqIndent_"}")
		$$$WriteCode(tSeqMethod,tSeqIndent_"Quit tStatus")
		#; Don't call tSeqMethod.%Save() as it will trigger a save of the main definition which can reset the
		#; stream position for the main GetBatch() method implementation.
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Generate method to ensure cleanup if batch/sequence closed without saving
ClassMethod generateOnClose(pDefinition As %Dictionary.ClassDefinition, pSeqNode As %String = "") As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Try {
		If ##class(%Dictionary.MethodDefinition).IDKEYExists(pDefinition.Name,"%OnClose") {
			Set tMethod = ##class(%Dictionary.MethodDefinition).IDKEYOpen(pDefinition.Name,"%OnClose",,.tStatus)
			If $$$ISERR(tStatus) Quit
			Do tMethod.Implementation.Clear()
		}
		Else {
			Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
			Set tMethod.Name = "%OnClose"
			Set tMethod.parent = pDefinition
		}
		Set tMethod.ReturnType = "%Status"
		Set tMethod.Private = 1
		Set tMethod.ServerOnly = 1
	
		Set tIndent = $c(9)
		$$$WriteCode(tMethod,tIndent_"Set tStatus = $$$OK")
		$$$WriteCode(tMethod,tIndent_"Try {")
		Set tIndent = tIndent_$c(9)
		$$$WriteCode(tMethod,tIndent_"Set tId = ..%Id()")
		$$$WriteCode(tMethod,tIndent_"If """"=tId {")
		Set tIndent = tIndent_$c(9)
		
		Set tKey = ""
		For {
			Set tLoc = "%map(""Records"""_pSeqNode_")"
			Set tKey = $order(@tLoc@(tKey))
			Quit:(tKey = "")
			Continue:(tKey '= +tKey)
			Set tOrefLoc = "%map(""Records"""_pSeqNode_","_tKey_",""oref"")"
			Set tBatchEl = $get(@tOrefLoc)
			Set tStatus = ..generateBatchElementDelete(tMethod,tBatchEl,tIndent)
			If $$$ISERR(tStatus) Quit
		}
		
		If $$$ISERR(tStatus) Quit		
		Set tIndent = $extract(tIndent,1,*-1)
		$$$WriteCode(tMethod,tIndent_"}")
		Set tIndent = $extract(tIndent,1,*-1)
		$$$WriteCode(tMethod,tIndent_"} Catch ex {")
		Set tIndent = tIndent_$c(9)
		$$$WriteCode(tMethod,tIndent_"Set tStatus = $$$SystemError")
		Set tIndent = $extract(tIndent,1,*-1)
		$$$WriteCode(tMethod,tIndent_"}")
		$$$WriteCode(tMethod,tIndent_"Quit tStatus")
		Set tStatus = tMethod.%Save()		
	} Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod generatePutBatch(pDefinition As %Dictionary.ClassDefinition, ByRef pSequenceNumber As %Integer = 1) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Try {
		If ##class(%Dictionary.MethodDefinition).IDKEYExists(pDefinition.Name,"PutBatch") {
			Set tMethod = ##class(%Dictionary.MethodDefinition).IDKEYOpen(pDefinition.Name,"PutBatch",,.tStatus)
			If $$$ISERR(tStatus) Quit
			Do tMethod.Implementation.Clear()
		}
		Else {
			Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
			Set tMethod.Name = "PutBatch"
			Set tMethod.parent = pDefinition
		}
		Set tMethod.ClassMethod = 1
		Set tMethod.FormalSpec = "pIOStream:%IO.DeviceStream,pBatch:EnsLib.RecordMap.ComplexBatch"
		Set tMethod.ReturnType = "%Status"
		Set tMethod.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
	
		Set tIndent = $c(9,9)
		$$$WriteCode(tMethod,$c(9)_"Set tStatus = $$$OK")
		$$$WriteCode(tMethod,$c(9)_"Try {")
		$$$WriteCode(tMethod,tIndent_"If '$IsObject($get(pBatch)) Set tStatus = $$$ERROR($$$ObjectInstanceRequired) Quit")
		$$$WriteCode(tMethod,tIndent_"If '$IsObject(pIOStream) {")
		$$$WriteCode(tMethod,tIndent_$c(9)_"Set tFilename = pIOStream")
		$$$WriteCode(tMethod,tIndent_$c(9)_"Set pIOStream = ##class(%IO.FileStream).%New()")
		$$$WriteCode(tMethod,tIndent_$c(9)_"Do pIOStream.Open(tFilename,""WAE"",,"""_$get(%map("charEncoding"),"UTF-8")_""",.tStatus)")
		$$$WriteCode(tMethod,tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
		$$$WriteCode(tMethod,tIndent_"}")
		If $data(%map("Header"))#10 {
			Set tHeader = $$$ComplexMapGetOref("Header")
			$$$WriteCode(tMethod,tIndent_"Set tStatus = ##class("_tHeader.recordMap_").PutObject(pIOStream,pBatch."_tHeader.name_",0)")
			$$$WriteCode(tMethod,tIndent_"If $$$ISERR(tStatus) Quit")
		}
		Set tKey = ""
		For {
			Set tKey = $order(%map("Records",tKey))
			Quit:(tKey = "")
			Continue:(tKey '= +tKey)
			Set tBatchEl = $$$ComplexMapGetOref("Records",tKey)
			Set tStatus = ..generateBatchElementPut(tMethod,tBatchEl,"pBatch.",tIndent)
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit

		// Make sure we flush after the trailer (even if there is no trailer)
		If $data(%map("Trailer"))#10 {
			Set tTrailer = $$$ComplexMapGetOref("Trailer")
			$$$WriteCode(tMethod,tIndent_"Set tStatus = ##class("_tTrailer.recordMap_").PutObject(pIOStream,pBatch."_tTrailer.name_",1)")
			$$$WriteCode(tMethod,tIndent_"If $$$ISERR(tStatus) Quit")
		}
		Else {
			$$$WriteCode(tMethod,tIndent_"Do pIOStream.Flush(.tStatus)")
			$$$WriteCode(tMethod,tIndent_"If $$$ISERR(tStatus) Quit")
		}
		$$$WriteCode(tMethod,$c(9)_"} Catch ex {")
		$$$WriteCode(tMethod,$c(9,9)_"Set tStatus = $$$SystemError")
		$$$WriteCode(tMethod,$c(9)_"}")
		$$$WriteCode(tMethod,$c(9)_"Quit tStatus")
		Set tStatus = tMethod.%Save()
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod generatePutSequence(pSequenceDef As %Dictionary.ClassDefinition, pSequence As EnsLib.RecordMap.Model.RecordSequence, ByRef pSequenceNumber As %Integer = 1) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tPutSequence = ##class(%Dictionary.MethodDefinition).%New()
		Set tPutSequence.parent = pSequenceDef
		Set tPutSequence.Name = "PutSequence"
		Set tPutSequence.FormalSpec = "pIOStream:%IO.DeviceStream"
		Set tPutSequence.ReturnType = "%Status"
		Set tPutSequence.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
		$$$WriteCode(tPutSequence,$c(9)_"Set tStatus = $$$OK")
		$$$WriteCode(tPutSequence,$c(9)_"Try {")

		Set tIndent = $c(9,9)
		For i=1:1:pSequence.Elements.Count() {
			Set tElement = pSequence.Elements.GetAt(i)
			Set tStatus = ..generateBatchElementPut(tPutSequence,tElement,"..",tIndent)
			If $$$ISERR(tStatus) Quit
		}
		$$$WriteCode(tPutSequence,$c(9)_"}")
		$$$WriteCode(tPutSequence,$c(9)_"Catch {")
		$$$WriteCode(tPutSequence,$c(9,9)_"Set tStatus = $$$SystemError")
		$$$WriteCode(tPutSequence,$c(9)_"}")
		$$$WriteCode(tPutSequence,$c(9)_"Quit tStatus")
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod generateBatchElementDelete(pMethod As %Dictionary.MethodDefinition, pBatchElement As EnsLib.RecordMap.Model.BatchElement, pIndent As %String = {$char(9,9)}) As %Status
{
	Set tStatus = $$$OK
	Try {
		If pBatchElement.repeating {
			Set tIndent = pIndent
			$$$WriteCode(pMethod,tIndent_"Set seqKey = """"")
			$$$WriteCode(pMethod,tIndent_"For {")
			Set tRef = "tElement"
			Set tCollRef = ".."_pBatchElement.name
			Set tIndent = tIndent _ $char(9)
			$$$WriteCode(pMethod,tIndent_"Set "_tRef_" = "_tCollRef_".GetNext(.seqKey)")
			$$$WriteCode(pMethod,tIndent_"If (seqKey = """") Quit")
			$$$WriteCode(pMethod,tIndent_"If $IsObject("_tRef_") && (""""'="_tRef_".%Id()) {")
			Set tIndent = tIndent_$char(9)
			$$$WriteCode(pMethod,tIndent_"Set tElementId = "_tRef_".%Id()")
			If $classname(pBatchElement) = "EnsLib.RecordMap.Model.RecordReference" {
				Set tModel = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(pBatchElement.recordMap,.tStatus)
				Quit:$$$ISERR(tStatus)
				Set tClassname = tModel.targetClassname
			} Else {
				Set tClassname = $get(%map("GroupPackage"))_"."_pBatchElement.name
			}
			$$$WriteCode(pMethod,tIndent_"Set tStatus = ##class("_tClassname_").%DeleteId(tElementId)")
			Set tIndent = $E(tIndent,1,*-1)
			$$$WriteCode(pMethod,tIndent_"}")
			$$$WriteCode(pMethod,tIndent_"If $$$ISERR(tStatus) Quit")
			Set tIndent = $E(tIndent,1,*-1)
			$$$WriteCode(pMethod,tIndent_"}")
		}
	} Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Helper method to generate valid put code for a BatchElement object in the model.
ClassMethod generateBatchElementPut(pMethod As %Dictionary.MethodDefinition, pBatchElement As EnsLib.RecordMap.Model.BatchElement, pPropRef As %String = "..", pIndent As %String = {$char(9,9)}) As %Status
{
	Set tStatus = $$$OK
	Try {
		If pBatchElement.repeating {
			$$$WriteCode(pMethod,pIndent_"Set seqKey = """"")
			$$$WriteCode(pMethod,pIndent_"For {")
			Set tRef = "tElement"
			Set tCollRef = pPropRef_pBatchElement.name
			Set tIndent = pIndent _ $char(9)
			$$$WriteCode(pMethod,tIndent_"Set "_tRef_" = "_tCollRef_".GetNext(.seqKey)")
			$$$WriteCode(pMethod,tIndent_"If (seqKey = """") Quit")
		}
		Else {
			Set tRef = pPropRef_pBatchElement.name
			Set tIndent = pIndent
		}
		$$$WriteCode(pMethod,tIndent_"If $IsObject("_tRef_") {")
		If $classname(pBatchElement) = "EnsLib.RecordMap.Model.RecordReference" {
			$$$WriteCode(pMethod,tIndent_$c(9)_"Set tStatus = ##class("_pBatchElement.recordMap_").PutObject(pIOStream,"_tRef_",0)")
		}
		Else {
			$$$WriteCode(pMethod,tIndent_$c(9)_"Set tStatus = "_tRef_".PutSequence(pIOStream)")
		}
		$$$WriteCode(pMethod,tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
		$$$WriteCode(pMethod,tIndent_"}")
		If pBatchElement.repeating {
			$$$WriteCode(pMethod,tIndent_"Set tStatus = "_tCollRef_".%UnSwizzleAt(seqKey)")
			$$$WriteCode(pMethod,tIndent_"If $$$ISERR(tStatus) Quit")
			$$$WriteCode(pMethod,pIndent_"}")
			$$$WriteCode(pMethod,pIndent_"If $$$ISERR(tStatus) Quit")
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod buildMap(pComplexModel As EnsLib.RecordMap.Model.ComplexBatch, pGroupPackage As %String = "", Output pMap) As %Status
{
	Set tStatus = $$$OK
	Try {
		Kill pMap
		New $$$ComplexMap
		Set tCurrPath = 0
		Set tCounter = 1
	
		Set pMap("BatchClass") = $$$NormalizeClassname(pComplexModel.targetClassname)
		Set pMap("ComplexMap") = pComplexModel.name
		If pGroupPackage = "" {
			Set pGroupPackage = $piece(pMap("BatchClass"),".",1,$length(pMap("BatchClass"),".")-1)
		}
		Set pMap("GroupPackage") = pGroupPackage
		Set pMap("charEncoding") = pComplexModel.charEncoding
	
		If $IsObject(pComplexModel.Header) {
			$$$ComplexMapCheckName(pComplexModel.Header,tStatus)
			If $$$ISERR(tStatus) Quit
			Set pComplexModel.Header.recordMap = $$$NormalizeClassname(pComplexModel.Header.recordMap)
			Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(pComplexModel.Header.recordMap)
			Set $$$ComplexMapIdentIndex(pComplexModel.Header.recordMap) = tIdentifier
			If tIdentifier = "" {
				Set pMap("Header","idents") = -1
			}
			Else {
				Set pMap("Header","idents") = 1
				Set pMap("Header","idents",tIdentifier) = pComplexModel.Header
			}
			$$$ComplexMapAdd(pMap,"Header",1,pComplexModel.Header)
			Set $$$ComplexMap("RecordMaps",pComplexModel.Header.recordMap) = ""
		}
	
		Set tAllExplicit = 1
		Set tWasNotExplicit = 0
		If pComplexModel.Elements.Count() {
			For i=1:1:pComplexModel.Elements.Count() {
				Set tElement = pComplexModel.Elements.GetAt(i)
				Kill tMap, tPrevIdents
				If tWasNotExplicit {
					Set tPrevKey = ""
					For {
						Set tPrevKey = $O(pMap("Records",tPrevKey),-1)
						Quit:((tPrevKey=+tPrevKey) || (""=tPrevKey))
					}
					Merge:""'=tPrevKey tPrevIdents = pMap("Records",tPrevKey,"idents")
				}
				If tElement.isExplicitSpec() {
					If tWasNotExplicit {
						Set tCounter = tCounter + 1
					}
					Set tWasNotExplicit = 0
					If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
						Set tStatus = ..buildExplicitMap(tElement,.tMap,.tCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
						Merge pMap("Records") = tMap
					} Else {
						Kill tSubCounter
						Set tStatus = ..buildExplicitMap(tElement,.tMap,.tSubCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
						Merge pMap("Records",tCounter) = tMap
						Set tCounter = tCounter + 1
					}
				}
				Else {
					Set tAllExplicit = 0
					Set tWasNotExplicit = 1
					If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
						Set tStatus = ..buildVariableMap(tElement,.tMap,.tCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
						Merge pMap("Records") = tMap
					}
					Else {
						Kill tSubCounter
						Set tStatus = ..buildVariableMap(tElement,.tMap,.tSubCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
						Merge pMap("Records",tCounter) = tMap
						Set tCounter = tCounter + 1
					}
				}
			}
			If $$$ISERR(tStatus) Quit
		}
		If $IsObject(pComplexModel.Trailer) {
			$$$ComplexMapCheckName(pComplexModel.Trailer,tStatus)
			If $$$ISERR(tStatus) Quit
			Set pComplexModel.Trailer.recordMap = $$$NormalizeClassname(pComplexModel.Trailer.recordMap)
			If tWasNotExplicit {
				Set tCounter = tCounter + 1
			}
			If $data($$$ComplexMapIdentIndex(pComplexModel.Trailer.recordMap)) {
				Set tIdentifier = $$$ComplexMapIdentIndex(pComplexModel.Trailer.recordMap)
			}
			Else {
				#; No need to cache this last one
				Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(pComplexModel.Trailer.recordMap)
			}
			If tIdentifier = "" {
				Set pMap("Trailer","idents") = -1
			}
			Else {
				If tWasNotExplicit {
					Set tPrevKey = ""
					For {
						Set tPrevKey = $O(pMap("Records",tPrevKey),-1)
						Quit:((tPrevKey=+tPrevKey) || (""=tPrevKey))
					}
					If $data(pMap("Records",tPrevKey,"idents",tIdentifier),tPrevElement) && $IsObject($get(tPrevElement)) {
						Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,pComplexModel.Trailer.recordMap,pComplexModel.Trailer.name)
						Quit
					}
				}

				Set pMap("Trailer","idents") = 1
				Set pMap("Trailer","idents",tIdentifier) = pComplexModel.Trailer
			}
			$$$ComplexMapAdd(pMap,"Trailer",1,pComplexModel.Trailer)
			Set $$$ComplexMap("RecordMaps",pComplexModel.Trailer.recordMap) = ""
		}
		Set pMap = $lb(tAllExplicit)
		Merge pMap("RecordMaps") = $$$ComplexMap("RecordMaps")
		Set tSeqName = ""
		For {
			Set tSeqName = $order($$$ComplexMap("SeqNames",tSeqName))
			Quit:(tSeqName = "")
			Set pMap("ClassList",pGroupPackage _ "." _ tSeqName) = ""
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Kill $$$ComplexMap
	Quit tStatus
}

ClassMethod buildVariableMap(pBatchElement As EnsLib.RecordMap.Model.BatchElement, ByRef pMap, ByRef pCounter As %Integer = 1, ByRef pPrevIdents) As %Status
{
	Set tStatus = $$$OK
	Try {
		$$$ComplexMapCheckName(pBatchElement,tStatus)
		If $$$ISERR(tStatus) Quit
		If $classname(pBatchElement) = "EnsLib.RecordMap.Model.RecordReference" {
			Set pBatchElement.recordMap = $$$NormalizeClassname(pBatchElement.recordMap)
			If $data($$$ComplexMapIdentIndex(pBatchElement.recordMap)) {
				Set tIdentifier = $$$ComplexMapIdentIndex(pBatchElement.recordMap)
			}
			Else {
				Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(pBatchElement.recordMap)
				Set $$$ComplexMapIdentIndex(pBatchElement.recordMap) = tIdentifier
			}
			If tIdentifier = "" {
				Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierRequired,pBatchElement.recordMap,pBatchElement.name)
				Quit
			}
			// If previous element was variable and used the same identifier, parser won't be able to figure out whether a record belongs to that element or this one
			If $data(pPrevIdents(tIdentifier),tPrevElement) && $IsObject($get(tPrevElement)) {
				Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,pBatchElement.recordMap,pBatchElement.name)
				Quit
			}
			Else {
				Set pMap(pCounter,"idents",tIdentifier) = pBatchElement
			}
			$$$ComplexMapAdd(pMap,pCounter,0,pBatchElement)
			Set pCounter = pCounter + 1
			Set $$$ComplexMap("RecordMaps",pBatchElement.recordMap) = ""
		}
		ElseIf $classname(pBatchElement) = "EnsLib.RecordMap.Model.RecordSequence" {
			Set tStatus = $$$OK
			Set tWasNotExplicit = 0
			$$$ComplexMapAddRoot(pMap,0,pBatchElement)
			Set $$$ComplexMap("SeqNames",pBatchElement.name) = ""
			For i=1:1:pBatchElement.Elements.Count() {
				Set tElement = pBatchElement.Elements.GetAt(i)
				Kill tPrevIdents
				If tWasNotExplicit {
					Set tPrevKey = ""
					For {
						Set tPrevKey = $O(pMap(tPrevKey),-1)
						Quit:((tPrevKey=+tPrevKey) || (""=tPrevKey))
					}
					Merge:""'=tPrevKey tPrevIdents = pMap(tPrevKey,"idents")
				}
				If tElement.isExplicitSpec() {
					If tWasNotExplicit {
						Set pCounter = pCounter + 1
					}
					Set tWasNotExplicit = 0
					If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
						Set tStatus = ..buildExplicitMap(tElement,.pMap,.pCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
					} Else {
						Kill tMap,tSubCounter
						Set tStatus = ..buildExplicitMap(tElement,.tMap,.tSubCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
						Merge pMap(pCounter) = tMap
						Set pCounter = pCounter + 1
					}
				}
				Else {
					Set tWasNotExplicit = 1
					Set tRequired(pCounter) = tElement.required
					If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
						Set tStatus = ..buildVariableMap(tElement,.pMap,.pCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
					}
					Else {
						Kill tMap,tSubCounter
						Set tStatus = ..buildVariableMap(tElement,.tMap,.tSubCounter,.tPrevIdents)
						If $$$ISERR(tStatus) Quit
						Merge pMap(pCounter) = tMap
						Set pCounter = pCounter + 1
					}
				}
			}
			If $$$ISERR(tStatus) Quit
			#; Find which identifiers will trigger this particular sequence and check that they don't conflict with the previous element
			Do pBatchElement.getIdentifiers(.tSeqIdentifiers)
			Set tIdentifier = ""
			Set tCount = 0
			For {
				Set tIdentifier = $O(tSeqIdentifiers(tIdentifier))  Quit:(""=tIdentifier)
				Set tCount = tCount + 1
				Set pMap("idents",tIdentifier) = pBatchElement
			}
			// If the only identifier for this sequence matches an identifier from the previous element, then it is impossible to distinguish between the two
			If (1 = tCount) {
				Set tIdentifier = $O(tSeqIdentifiers(""))
				If $data(pPrevIdents(tIdentifier),tPrevElement) && $IsObject(tPrevElement) {
					Set tConflictingRecord = tSeqIdentifiers(tIdentifier)
					Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,tConflictingRecord.recordMap,tConflictingRecord.name)
					Quit
				}
			}
		}
		Else {
			Set tStatus = $$$ERROR($$$GeneralError,"Unknown model type: "_$classname(pBatchElement))
			Quit
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod buildExplicitMap(pBatchElement As EnsLib.RecordMap.Model.BatchElement, ByRef pMap, ByRef pCounter As %Integer = 1, ByRef pPrevIdents) As %Status
{
	Set tStatus = $$$OK
	Try {
		$$$ComplexMapCheckName(pBatchElement,tStatus)
		If $$$ISERR(tStatus) Quit
		If $classname(pBatchElement) = "EnsLib.RecordMap.Model.RecordReference" {
			Set pBatchElement.recordMap = $$$NormalizeClassname(pBatchElement.recordMap)
			If (pBatchElement.recordMap '= "") {
				If $data($$$ComplexMapIdentIndex(pBatchElement.recordMap)) {
					Set tIdentifier = $$$ComplexMapIdentIndex(pBatchElement.recordMap)
				}
				Else {
					Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(pBatchElement.recordMap)
					Set $$$ComplexMapIdentIndex(pBatchElement.recordMap) = tIdentifier
				}
			}
			Else { Set tIdentifier = "" }
			If tIdentifier = "" {
				Set pMap(pCounter,"idents") = -1
			}
			Else {
				// If previous element was variable and used the same identifier, the parser won't be able to figure out whether a record belongs to that element or this one
				If $data(pPrevIdents(tIdentifier),tPrevElement) && $IsObject($get(tPrevElement)) {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,pBatchElement.recordMap,pBatchElement.name)
					Quit
				}
				Else {
					Set pMap(pCounter,"idents") = 1
					Set pMap(pCounter,"idents",tIdentifier) = pBatchElement
				}
			}
			$$$ComplexMapAdd(pMap,pCounter,1,pBatchElement)
			Set pCounter = pCounter + 1
			Set $$$ComplexMap("RecordMaps",pBatchElement.recordMap) = ""
		}
		ElseIf $classname(pBatchElement) = "EnsLib.RecordMap.Model.RecordSequence" {
			$$$ComplexMapAddRoot(pMap,1,pBatchElement)
			Set $$$ComplexMap("SeqNames",pBatchElement.name) = ""
			For i=1:1:pBatchElement.Elements.Count() {
				Set tElement = pBatchElement.Elements.GetAt(i)
				If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
					Set tStatus = ..buildExplicitMap(tElement,.pMap,.pCounter,.pPrevIdents)
					If $$$ISERR(tStatus) Quit
				}
				Else {
					Kill tMap,tCounter
					Set tStatus = ..buildExplicitMap(tElement,.tMap,.tCounter,.pPrevIdents)
					If $$$ISERR(tStatus) Quit
					Merge pMap(pCounter) = tMap
					Set pCounter = pCounter + 1
				}
				#; Only first record in explicit sequence can be in conflict with earlier records' leading data
				Kill pPrevIdents
			}
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Set tStatus = $$$ERROR($$$GeneralError,"Unknown model type: "_$classname(pBatchElement))
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

}
