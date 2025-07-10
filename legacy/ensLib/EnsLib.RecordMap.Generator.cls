/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsRecordMap, EnsRecordMapGen)

/// Class that controls displaying and creating object projections for RecordMaps.
/// See the documentation for individual methods to see detailed information 
/// regarding usage and available options.
Class EnsLib.RecordMap.Generator Extends EnsLib.RecordMap.GenUtils [ Abstract, System = 4 ]
{

/// The subscript used for objects declared without a container object.
Parameter DEFAULTSUBSCRIPT [ Internal ] = -9999999;

/// Advisory to include on generated Class and Method Definitions that further external customization is not supported
Parameter GENERATEDADVISORY = {"THIS IS GENERATED CODE. DO NOT EDIT.<br/>"_$C(13,10)};

/// Generate a parent object for a particular RecordMap.
/// <ul><li><var>pRecordMap</var>: the RecordMap to generate the class definitions from.</li>
/// <li><var>pTargetClassname</var>: the container object to generate the classes in; any generated 
/// 		classes will be created in the same package. If this is not supplied, it will be retrieved
/// 		from the RecordMap definition.</li>
/// <li><var>pStructure</var>: the structure to use for the generated object and the objects 
/// embedded within the main class. All classes below the top two levels extend %SerialObject.
/// Possible values are:
/// 	<ul><li>1: %Persistent main class, %SerialObject for embedded objects [Default]</li>
/// 		<li>2: %RegisteredObject main class, %Persistent for  embedded objects</li>
/// 		<li>3: %SerialObject for all objects</li>
/// 		<li>4: %Persistent main class, %SerialObject for embedded objects AND ensure 
/// 					each serial object uses its own storage node. This can be 
/// 					useful for very large input files with many properties.</li>
/// 		<li>5: %Persistent main class with %Persistent object properties, and
/// 					%SerialObject subobjects below the second level. Note that this approach
/// 					generates an OnDelete trigger and uses the %OnDelete() callback in the main
/// 					class to ensure that its persistent properties are deleted along with their 
/// 					container.</li></ul></li>
/// <li><var>pGenTopFields</var>: control generation of properties without an object defined.
/// 		These properties will be generated in the top level class if the flag is enabled.</li>
/// <li><var>pCompile</var>: control compilation of the generated classes. Possible values are:
/// <ul><li>0: Do not compile. A list of generated classes will be returned in the "Generated" subscript
/// 				of the pCompile variable.</li>
/// <li>1: Compile entire package using $system.OBJ.CompilePackage() (also compiles RecordMap class)</li>
/// <li>2: Compile generated classes as a group and then recompile RecordMap class [Default]</li></ul>
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
ClassMethod GenerateObject(pRecordMap As %String = "", ByRef pTargetClassname As %String, ByRef pStructure As %Integer = 1, pGenTopFields As %Boolean = 1, ByRef pCompile As %Integer = 2, pDisplay As %Integer = 2, pCompileFlags As %String = "ck", pOverwriteBehaviour As %Integer = 2, Output pGeneratedClasses As %String, pKeepStorage As %Boolean = 1) As %Status
{
	Kill pGeneratedClasses
	Set pGeneratedClasses = ""
	
	If '##class(EnsLib.RecordMap.Model.Record).Exists(pRecordMap, .tSC) {
		If $$$ISERR(tSC) Quit tSC
		Quit $$$ERROR($$$ClassDoesNotExist, pRecordMap)
	}
	Set tRecordMap = $$$NormalizeClassname(pRecordMap)
	
	If pDisplay = 0 { Set pCompileFlags = pCompileFlags_"-d" }
	
	If (pOverwriteBehaviour = 1) && (1 '= ##class(%Device).GetType()) {
		Quit $$$ERROR($$$NoSuchDeviceOrWrongUse)
	}
	
	Set tSC = ..GetObjectStructure(pRecordMap, .tStruct, pGenTopFields)
	If $$$ISERR(tSC) Quit tSC
	If $get(pTargetClassname) = "" {
		Set pTargetClassname = $get(tStruct("objdata", "path"))
	}
	ElseIf ($extract(pTargetClassname,1)="%")&&($zconvert($extract(pTargetClassname,2),"U")'="Z") {
		Quit $$$ERROR($$$ClassNameInvalid, pTargetClassname)
	}
	
	Set tBatchName = $get(tStruct("objdata", "batch"))
	Set tGenTarget = $$$NormalizeClassname(pTargetClassname)
	Set tPackage= $piece(tGenTarget, ".", 1, $length(tGenTarget, ".") - 1)
	Set tClassname = $piece(tGenTarget, ".", $length(tGenTarget, "."))
	
	Set tStruct("objdata","path") = tGenTarget
	If pDisplay {
		Set tSC = ..DisplayObjectStructure(.tStruct, pGenTopFields, (pDisplay = 2))
		If $$$ISERR(tSC) Quit tSC
	}
	
	#; Generate all sub-objects
	Set tObjectName = ..#DEFAULTSUBSCRIPT
	For {
		Set tObjectName = $order(tStruct("objorder", tObjectName))
		Quit:tObjectName=""
		Kill tObjStruc
		Merge tObjStruc = tStruct("objorder", tObjectName)
		Set tObjData = $get(tStruct("objdata", "path", tObjectName))
		Set tObjLevel = $listget(tObjData, 1)
		Set tClassType = $case(pStructure,
								2: $case(tObjLevel, 1: 1, :3),
								5: $case(tObjLevel, 1: 1, :3),
								:3
								)
		Set tHasTopPath = $listget(tObjData, 2)
		If tHasTopPath {
			Set tGenName = tPackage _ "." _ $listget(tObjData, 3)
		}
		Else {
			Set tGenName = tGenTarget _ "." _ tObjectName
		}
		
		Set tSC = ..generateClass(tGenName, .tObjStruc, pRecordMap, tClassType, pDisplay,, pOverwriteBehaviour,, tGenTarget, .tGenerated,, pKeepStorage)
		If $$$ISERR(tSC) Quit
		If tGenerated Set pGeneratedClasses(tGenName) = ""
	}
	If $$$ISERR(tSC) Quit tSC
	
	Kill tObjStruc
	Merge tObjStruc = tStruct("objorder",..#DEFAULTSUBSCRIPT)
	Set tClassType = $case(pStructure, 1: 1, 2: 2, 3: 3, 4: 1, 5: 1)
	Set tComplexBatch = $get(tStruct("parse","complexBatchManaged"),0)
	If tComplexBatch && (tClassType '= 1) Quit $$$ERROR($$$EnsRecordMapErrGeneral,"ComplexBatch-managed Records must extend %Library.Persistent, which is incompatible with pStructure = '"_pStructure_"'")
	Set tSC = ..generateClass(tGenTarget, .tObjStruc, pRecordMap, tClassType, pDisplay, pStructure, pOverwriteBehaviour, pGenTopFields, tGenTarget, .tGenerated, tComplexBatch, pKeepStorage)
	If $$$ISERR(tSC) Quit tSC
	
	If tGenerated Set pGeneratedClasses(tGenTarget) = ""
	
	If ('tComplexBatch) && (tBatchName '= "") {
		Set tSC = ..addBatchRelationship(tBatchName, tGenTarget, .pGeneratedClasses, pRecordMap)
		If $$$ISERR(tSC) Quit tSC
	}
	
	Set tRecordMapDef = ##class(%Dictionary.ClassDefinition).%OpenId(tRecordMap,,.tSC)
	If $$$ISERR(tSC) Quit tSC
	New $$$localStructure
	Merge $$$localStructure = tStruct
	Set tSC = ..generateGetObject(tRecordMapDef)
	If $$$ISERR(tSC) Quit tSC
	Set tSC = ..generatePutObject(tRecordMapDef)
	If $$$ISERR(tSC) Quit tSC
	Set tRecordSequence = 7
	Set tSC = ..generateGeneratedClasses(tRecordMapDef,.pGeneratedClasses,.tRecordSequence)
	If $$$ISERR(tSC) Quit tSC
	Set tSC = ..generateGetIdentifier(tRecordMapDef,.tRecordSequence)
	If $$$ISERR(tSC) Quit tSC
	Set tSC = ..generateGetType(tRecordMapDef,.tRecordSequence)
	If $$$ISERR(tSC) Quit tSC
	Kill $$$localStructure
	Do ..updateDescription(tRecordMapDef, pRecordMap, 1)
	Set tSC = tRecordMapDef.%Save()
	If $$$ISERR(tSC) Quit tSC
	
	Set pGeneratedClasses(pRecordMap) = ""
	
	If pCompile {
		Set tSC = ..doCompile(pRecordMap,.pGeneratedClasses,pCompile,pCompileFlags,tPackage)
		If $$$ISERR(tSC) Quit tSC
	}
	Quit tSC
}

/// Given a saved RecordMap, produce a list of the classes which
/// will be generated for the RecordMap
ClassMethod GetGeneratedObjects(pRecordMap As %String, Output pClassList, pTargetClassname As %String = "", pIncludeBatch As %Boolean = 0) As %Status [ Internal ]
{
	Try {
		Set tStatus = $$$OK
		Kill pClassList
		If '##class(EnsLib.RecordMap.Model.Record).Exists(pRecordMap, .tStatus) {
			If $$$ISERR(tStatus) Quit
			Set tStatus = $$$ERROR($$$ClassDoesNotExist, pRecordMap)
			Quit
		}
		
		Set tStatus = ..GetObjectStructure(pRecordMap, .tStruc)
		If $$$ISERR(tStatus) Quit
		
		If pTargetClassname = "" { Set tTargetName = $$$NormalizeClassname($get(tStruc("objdata", "path"))) }
		Else { Set tTargetName = $$$NormalizeClassname(pTargetClassname) }
		
		Set pClassList(tTargetName) = ""
		Set tTargetPackage = $piece(tTargetName, ".", 1, $length(tTargetName, ".") -1)
		Set tObjName = ""
		For {
			Set tObjName = $order(tStruc("objdata", "path", tObjName),1, tObjData)
			Quit:(tObjName = "")
			
			If '$data(tObjData) Continue
			If '$listvalid(tObjData) Continue
			
			If $listget(tObjData, 2) { // has $ prefix
				Set pClassList(tTargetPackage _ "." _ $listget(tObjData,3)) = ""
			}
			Else {
				Set pClassList(tTargetName _ "." _ tObjName) = ""
			}
		}
		If pIncludeBatch {
			Set tBatch = $get(tStruc("objdata","batch"))
			If tBatch '= "" {
				Set pClassList(tBatch) = ""
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// NOTE: The structure returned from this method is subject to change without notice.
/// Applications should make use of the object model to navigate the RecordMap structure programmatically.
/// <br/>
/// Retrieve an array describing the object structure for a particular RecordMap.
/// <ul><li><var>pRecordMap</var>: the RecordMap to retrieve</li>
/// <li><var>pStructure</var>: an array to contain the retrieved structure</li>
/// <li><var>pGetTopFields</var>: indicates whether fields without an explicit object type should be included in the structure</li></ul>
ClassMethod GetObjectStructure(pRecordMap As %String = "", Output pStructure As %String, pGetTopFields As %Boolean = 1) As %Status [ Internal ]
{
	Try {
		Set tSC = $$$OK
		Kill pStructure
		If '##class(EnsLib.RecordMap.Model.Record).Exists(pRecordMap, .tSC) {
			If $$$ISERR(tSC) Quit
			Set tSC=$$$ERROR($$$ClassDoesNotExist, pRecordMap)
			Quit
		}

		Set tRecord = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(pRecordMap, .tSC)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ..getStructure(tRecord, .tObjStruc)
		If $$$ISERR(tSC) Quit
		
		Merge pStructure = tObjStruc
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Write the object structure for a particular RecordMap to the current device. <br/>
/// <ul><li><var>pRecordMap</var> the name of a RecordMap, or an array constructed by GetObjectStructure()</li>
/// <li><var>pShowTopFields</var> indicates whether fields without an explicit object type should be included in the display</li>
/// <li><var>pDisplayDetails</var> indicates whether detailed information about each field's object representation should be displayed</li>
/// <li><var>pTopObjectName</var> specifies the name to be used for the topmost object in the tree.</ul>
ClassMethod DisplayObjectStructure(ByRef pRecordMap As %String = "", pShowTopFields As %Boolean = 1, pDisplayDetails As %Boolean = 1) As %Status
{
	If $data(pRecordMap) < 10 {
		Set tStatus = ..GetObjectStructure($get(pRecordMap), .tStructure, pShowTopFields)
		If $$$ISERR(tStatus) Quit tStatus
	}
	Else {
		Merge tStructure = pRecordMap
	}
	
	Write !,$$$Text("Object structure is as follows:"),!
	
	Set tTopObjectName = $get(tStructure("objdata", "path"), "**"_$$$Text("Top Object")_"**")
	
	Merge tObjStruc = tStructure("objorder",..#DEFAULTSUBSCRIPT)
	Do ..displayObject(tTopObjectName, .tObjStruc, .tFound, pShowTopFields, pDisplayDetails, tTopObjectName)
	
	Set tObjName = ..#DEFAULTSUBSCRIPT
	For {
		Set tObjName = $order(tStructure("objorder", tObjName))
		Quit:tObjName=""
		
		If $get(tFound(tObjName)) Continue
		
		Set tDisplayName = tTopObjectName _ "." _ tObjName
		If $listget(tStructure("objdata", "path", tObjName), 2) {
			Set tDisplayName = $piece(tTopObjectName, ".", 1, $length(tTopObjectName, ".")-1) _ "." _ $listget(tStructure("objdata", "path", tObjName),3)
		}
		Kill tObjStruc
		Merge tObjStruc = tStructure("objorder",tObjName)
		Do ..displayObject(tDisplayName, .tObjStruc, .tFound, 1, pDisplayDetails, tTopObjectName)
	}
	
	Quit $$$OK
}

/// Internal method to iterate over the RecordMap model. It is used both in retrieving
/// the structure of the map and in validating that there are no object collisions in the map
ClassMethod getStructure(pRecord As EnsLib.RecordMap.Model.Record, ByRef pStructure, a) As %Status [ Internal ]
{
	New $$$localParseTree
	Try {
		Set tStatus = $$$OK
		Kill pStructure

		Set $$$parseRecordProp("charEncoding") = pRecord.charEncoding
		Set $$$parseRecordProp("recordTerminator") = ..getLogicalChars(pRecord.recordTerminator)
		Set $$$parseRecordProp("label") = $Replace(pRecord.label,"""","""""")
		Set $$$parseRecordProp("complexBatchManaged") = ''pRecord.complexBatchManaged
		Set $$$parseRecordProp("paddingChars") = ..getLogicalChars(pRecord.paddingChars)
		Set $$$parseRecordProp("type") = pRecord.type
		If pRecord.batchClass '= "" { Set tObjStruc("objdata","batch") = pRecord.batchClass }
		If pRecord.annotation '= "" {
			Set $$$parseRecordProp("annotation") = pRecord.annotation
		}

		Set tPath = """struc"""
		Set tLocPath = tPath
		If pRecord.type = "fixedwidth" {
			Set $$$parseRecordProp("allowEarlyTerminator") = pRecord.allowEarlyTerminator
			Set tPath = tPath_",1"
			Set $$$parseRecordProp("fieldSeparator") = ..getLogicalChars(pRecord.fieldSeparator)
			Set $$$parseRecordProp("padFromLeft") = pRecord.padFromLeft
		}
		ElseIf pRecord.type = "delimited" {
			Set tSeps = ""
			For k=1:1:pRecord.Separators.Count() {
				Set $list(tSeps,k) = ..getLogicalChars(pRecord.Separators.GetAt(k))
			}
			Set $$$parseRecordProp("separators") = tSeps
			Set $$$parseRecordProp("repeatSeparator") = ..getLogicalChars(pRecord.repeatSeparator)
			Set $$$parseRecordProp("escaping") = pRecord.escaping
			Set $$$parseRecordProp("escapeSequence") = ..getLogicalChars(pRecord.escapeSequence)
			Set $$$parseRecordProp("allowEmbeddedRecordTerminator") = pRecord.allowEmbeddedRecordTerminator
		}
		Set tObjStruc("objdata","path") = pRecord.targetClassname

		Set tPropKey = ""
		For k=1:1:pRecord.Contents.Count() {
			Set tProp = pRecord.Contents.GetNext(.tPropKey)
			If pRecord.type = "delimited" Set tPath = tLocPath _ "," _ k
			If tProp.%IsA("EnsLib.RecordMap.Model.Composite") {
				Set tStatus = ..getCompositeObjects(tProp, pRecord, .tObjStruc, .tPath, 1)
				If $$$ISERR(tStatus) Quit
			}
			Else {
				Set tStatus = ..addField(tProp, pRecord, .tObjStruc, "", .tPath, 1)
				If $$$ISERR(tStatus) Quit
			}
		}
		If $$$ISERR(tStatus) Quit

		Merge tObjStruc("parse") = $$$localParseTree
		Kill $$$localParseTree
		Merge pStructure = tObjStruc
	}
	Catch ex {
		Kill $$$localParseTree
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

ClassMethod generateGeneratedClasses(pRecordMapDef As %Dictionary.ClassDefinition, ByRef pGeneratedClasses As %String, ByRef pSequenceNumber As %Integer = 1) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	If ##class(%Dictionary.MethodDefinition).IDKEYExists(pRecordMapDef.Name,"GetGeneratedClasses") {
		Set tMethod = ##class(%Dictionary.MethodDefinition).IDKEYOpen(pRecordMapDef.Name,"GetGeneratedClasses",,.tStatus)
		If $$$ISERR(tStatus) Quit tStatus
		Do tMethod.Implementation.Clear()
	}
	Else {
		Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
		Set tMethod.parent = pRecordMapDef
		Set tMethod.Name = "GetGeneratedClasses"
	}
	Set tMethod.FormalSpec = "*pClasses:%String"
	Set tMethod.ClassMethod = 1
	Set tMethod.ReturnType = "%Status"
	Set tMethod.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
	$$$WriteCode(tMethod,$c(9)_"Kill pClasses")
	Set tClass = ""
	For {
		Set tClass = $order(pGeneratedClasses(tClass))
		Quit:(tClass = "")
		$$$WriteCode(tMethod,$c(9)_"Set pClasses("""_tClass_""")=""""")
	}
	$$$WriteCode(tMethod,$c(9)_"Set pClasses($classname())=""""")
	$$$WriteCode(tMethod,$c(9)_"Quit $$$OK")
	Quit tMethod.%Save()
}

ClassMethod generateGetIdentifier(pRecordMapDef As %Dictionary.ClassDefinition, ByRef pSequenceNumber As %Integer = 1) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	If ##class(%Dictionary.MethodDefinition).IDKEYExists(pRecordMapDef.Name,"getIdentifier") {
		Set tMethod = ##class(%Dictionary.MethodDefinition).IDKEYOpen(pRecordMapDef.Name,"getIdentifier",,.tStatus)
		If $$$ISERR(tStatus) Quit tStatus
		Do tMethod.Implementation.Clear()
	}
	Else {
		Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
		Set tMethod.parent = pRecordMapDef
		Set tMethod.Name = "getIdentifier"
	}
	Set tMethod.FormalSpec = ""
	Set tMethod.ClassMethod = 1
	Set tMethod.ReturnType = "%String"
	Set tMethod.CodeMode = "expression"
	Set tMethod.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
	Do tMethod.Implementation.Write(""""_$$$GetRecordProp("label")_"""")
	Quit tMethod.%Save()
}

ClassMethod generateGetType(pRecordMapDef As %Dictionary.ClassDefinition, ByRef pSequenceNumber As %Integer = 1) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	If ##class(%Dictionary.MethodDefinition).IDKEYExists(pRecordMapDef.Name,"getType") {
		Set tMethod = ##class(%Dictionary.MethodDefinition).IDKEYOpen(pRecordMapDef.Name,"getType",,.tStatus)
		If $$$ISERR(tStatus) Quit tStatus
		Do tMethod.Implementation.Clear()
	}
	Else {
		Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
		Set tMethod.parent = pRecordMapDef
		Set tMethod.Name = "getType"
	}
	Set tMethod.FormalSpec = ""
	Set tMethod.ClassMethod = 1
	Set tMethod.ReturnType = "EnsLib.RecordMap.Model.DataType.RecordType"
	Set tMethod.CodeMode = "expression"
	Set tMethod.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
	Do tMethod.Implementation.Write(""""_$$$GetRecordProp("type")_"""")
	Quit tMethod.%Save()
}

/// Helper method to generate GetObject() code.
ClassMethod generateGetObject(pRecordMapDef As %Dictionary.ClassDefinition) As %Status [ Internal ]
{
	Try {
		Set tStatus = $$$OK
		Set tDef = pRecordMapDef		
		
		// Ensure OBJECTNAME parameter is correct
		Set tParm = ##class(%Dictionary.ParameterDefinition).%OpenId(pRecordMapDef.Name_"||OBJECTNAME")
		If '$IsObject(tParm) {
			Set tParm = ##class(%Dictionary.ParameterDefinition).%New()
			Set tParm.Name = "OBJECTNAME"
		}
		Set tParm.parent = tDef
		Set tParm.Default = $get($$$localStructure("objdata", "path"))
		Set tSequenceNumber = 2
		Set tParm.SequenceNumber = tSequenceNumber
	
		Set tMethodCount = $$$nextSequenceNumber(tSequenceNumber)
		Set tMainMethod = ..addGetMethod(tDef, "GetObject", 0, tMethodCount)
	
		$$$WriteCode(tMainMethod,$char(9)_"Try {")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tStatus = $$$OK")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set pObject = $$$NULLOREF")
		$$$WriteCode(tMainMethod,$char(9,9) _ "If '$IsObject(pStream) {")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "Set tFilename = pStream")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "Set pStream = ##class(%IO.FileStream).%New()")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "Do pStream.Open(tFilename,,pTimeout,"""_$$$GetRecordProp("charEncoding")_""", .tStatus)")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "If $$$ISERR(tStatus) Quit")
		$$$WriteCode(tMainMethod,$char(9,9) _ "}")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tObjectName = $parameter($this,""OBJECTNAME"")")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tObject = $classmethod(tObjectName,""%New"")")
		$$$WriteCode(tMainMethod,$char(9,9) _ "If '$IsObject(tObject) {")
		$$$WriteCode(tMainMethod,$char(9,9,9) _	"Set tStatus = $$$ERROR($$$CannotCreateObject,tObjectName)")
		$$$WriteCode(tMainMethod,$char(9,9,9) _	"Quit")
		$$$WriteCode(tMainMethod,$char(9,9) _ "}")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tObject.%Source = pStream.Name")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tGetTopFields = $parameter(tObject,""INCLUDETOPFIELDS"")")
		$$$WriteCode(tMainMethod,$char(9,9) _ "If pStream.AtEnd && (""""=pLookAhead) {")
		$$$WriteCode(tMainMethod,$char(9,9,9) _	"Set tStatus = $$$ERROR($$$EnsRecordMapErrStreamAtEnd, pStream.Name)")
		$$$WriteCode(tMainMethod,$char(9,9,9) _	"Quit")
		$$$WriteCode(tMainMethod,$char(9,9) _ "}")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set pStream.CharEncoding = """_ $$$GetRecordProp("charEncoding") _ """")
		$$$WriteCode(tMainMethod,"")
	
		$$$WriteCode(tMainMethod,$char(9,9) _ "#; Parse incoming stream")
	
		Set tMethodCount = $$$nextSequenceNumber(tMethodCount)
		Set tMethodName = "GetRecord"
		Set tHelper = ..addGetMethod(tDef, tMethodName,,tMethodCount)
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tStatus = .."_tMethodName_"(pStream, tObject, tGetTopFields, pTimeout, .pLookAhead, pLabelFound)")
		$$$WriteCode(tMainMethod,$char(9,9) _ "If $$$ISERR(tStatus) Quit")
	
		Set tRecTerminator = $$$GetRecordProp("recordTerminator")
		If tRecTerminator = "" Set tRecTerminator = """"""
		Set tRecLabel = $$$GetRecordProp("label")
		Set tRecType = $$$GetRecordProp("type")
		Set tRecFieldSep = $$$GetRecordProp("fieldSeparator")
		Set tSeps = $$$GetRecordProp("separators")
		Set tRepSeparator = $$$GetRecordProp("repeatSeparator")
		Set tQuoteChar = $case($$$GetRecordProp("escaping"), "quote" : $$$GetRecordProp("escapeSequence"), "all" : $$$GetRecordProp("escapeSequence"), : """""")
		Set tAllowEmbeddedRecTerm = ''$$$GetRecordProp("allowEmbeddedRecordTerminator")

		$$$WriteCode(tHelper,$char(9) _ "Set tStatus = $$$OK")
		$$$WriteCode(tHelper,$char(9) _ "If pLabelFound { Set tRecLabel = """" } ")
		$$$WriteCode(tHelper,$char(9) _ "Else { Set tRecLabel = """ _ tRecLabel _ """ } ")
	
		If tRecType = "fixedwidth" {
			Set tMaxLen = ""
			Set tMaxLen = $$$PrevField("")
			Set tMaxLen = tMaxLen + $$$GetTopFieldProp(tMaxLen,"width") - 1
			
			$$$WriteCode(tHelper,$char(9) _ "Set tMaxLen = " _ +tMaxLen _ " + $length(tRecLabel)")
			$$$WriteCode(tHelper,$char(9) _ "Set tStatus = ..chunkRecord(pStream, .tRecordData, .tCharCount, tMaxLen, pTimeout, "_tRecTerminator_", tRecLabel, .pLookAhead)")
			$$$WriteCode(tHelper,$char(9) _ "If $$$ISERR(tStatus) Quit tStatus")
			$$$WriteCode(tHelper,$char(9) _ "Set tIgnoreEarlyTerminator = "_+$$$GetRecordProp("allowEarlyTerminator"))
			
		}
		ElseIf tRecType = "delimited" {
			$$$WriteCode(tHelper,$char(9) _ "Set tStatus = ..chunkRecord(pStream, .tRecordData, .tCharCount, """", pTimeout, "_tRecTerminator_", tRecLabel, .pLookAhead, "_tQuoteChar_", "_tAllowEmbeddedRecTerm_")")
		}
		
		$$$WriteCode(tHelper,$char(9) _ "If $$$ISERR(tStatus) Quit tStatus")
	
		$$$WriteCode(tHelper,$char(9) _ "Set tMaxLocal = $$$MaxLocalLength")
		Set tStripAction = $select($$$GetRecordProp("padFromLeft"):"""<""",1:""">""")
		Set tPadChars = $$$GetRecordProp("paddingChars")
		
		$$$WriteCode(tHelper,$char(9) _ "Set tRecordData(""charcount"") = +$get(tCharCount)")
		$$$WriteCode(tHelper,$char(9) _ "Set tCurrChunk = 1")
	
		If tRecType = "fixedwidth" {
			$$$WriteCode(tHelper,$char(9) _ "Set tCurrPos = 1")
			$$$WriteCode(tHelper,$char(9) _ "Set tNewChunk = 1")
			Set tFieldSep = $$$GetRecordProp("fieldSeparator")
			If tFieldSep = "" Set tFieldSep = """"""
			
			Set tLastKey = $$$PrevField("")
			Set tColKey = ""
			For {
				Set tColKey = $$$NextField(tColKey)
				Quit:tColKey=""
				Set:tColKey=tLastKey tFieldSep = """"""
				
				Set tTrailing = $$$GetTopFieldProp(tColKey, "trailingData")
				If tTrailing = "" Set tTrailing = """"""
				Set tObjProperty = $TR($$$GetTopFieldProp(tColKey, "objproperty"), "$", "")
				Set tDatatype = $$$GetTopFieldProp(tColKey, "datatype")
				Set tConvert = ""
				If tDatatype '= "" Set tConvert = "pObject." _ tObjProperty _ "DisplayToLogical("
				
				$$$WriteCode(tHelper,$char(9) _ "Set tCurrVal = ..checkFixedWidthChunk(.tStatus,.tNewChunk,.tCurrChunk,.tRecordData,.tCurrString,.tCurrLen,.tCurrPos,"_+$$$GetTopFieldProp(tColKey,"width")_","_tFieldSep_","_tTrailing_","""_tObjProperty_""",tIgnoreEarlyTerminator)")
				$$$WriteCode(tHelper,$char(9) _ "If $$$ISERR(tStatus) Quit tStatus")

				Set tIgnored = +$$$GetTopFieldProp(tColKey,"ignored")
				If 'tIgnored {
					Set tGetString = ""
					If $length(tObjProperty,".") = 1 {
						Set tGetString = "If pGetTopFields "
					}
					Set tGetString = tGetString _ "Set pObject." _ tObjProperty _ " = " _ tConvert 
							_ $select(tPadChars = "": "tCurrVal", 1: "$ZStrip(tCurrVal, " _ tStripAction _ ", " _ tPadChars _ ")")
							_ $select(tConvert '= "": ")", 1: "")
					$$$WriteCode(tHelper,$char(9) _ tGetString)
				}
			}
		}
		ElseIf tRecType = "delimited" {
			Set tSepPos = 1
			Set tCurrSep = $listget(tSeps, tSepPos)
			Set tSepString = "$listbuild(" _ $listtostring(tSeps) _ ")"
			Set tFirst = 1
			Set tIndent = $char(9)
			$$$WriteCode(tHelper,$char(9) _ "Set tTopPiece = 1")
			$$$WriteCode(tHelper,$char(9) _ "Set tCurrSep = 1")
			$$$WriteCode(tHelper,$char(9) _ "Set tStrings = 1")
			$$$WriteCode(tHelper,$char(9) _ "Set tCurrString = """"")
			$$$WriteCode(tHelper,$char(9) _ "Set tSeps = " _ tSepString)
			
			New $$$RepeatData
			Set tColKey = ""
			For {
				Set tColKey = $$$NextField(tColKey)
				Quit:tColKey=""
				
				Set tIgnored = +$$$GetTopFieldProp(tColKey,"ignored")
				If 'tIgnored {
					$$$WriteCode(tHelper,$char(9) _ "If '$data(tRecordData(tCurrChunk, ""block"")) {")
					$$$WriteCode(tHelper,$char(9,9) _ "Set tCurrString = $piece(tRecordData(tCurrChunk), "_tCurrSep_ ", tTopPiece)")
					$$$WriteCode(tHelper,$char(9) _ "}")
					If tFirst {
						Set tFirst = 0
						$$$WriteCode(tHelper,$char(9) _ "Else {")
						$$$WriteCode(tHelper,$char(9,9) _ "Set tCurrString = tRecordData(tCurrChunk)")
						$$$WriteCode(tHelper,$char(9,9) _ "Set tCurrPiece = 1")
						$$$WriteCode(tHelper,$char(9) _ "}")
					}
				} Else {
					Set:tFirst tFirst = 0
				}
				$$$WriteCode(tHelper,$char(9) _ "Do ..checkMerge(.tCurrChunk, .tRecordData, .tCurrString, "_tCurrSep_", .tTopPiece)")
				
				#; If this field is being ignored, we still need to update tCurrChunk and tTopPiece in order to move on to the next one, but we don't want to set it as a property value
				Continue:tIgnored
				
				If $data($$$localStructure("parse","struc",tColKey,1)) {
					Set tPath = """parse"",""struc"","_tColKey
					$$$WriteCode(tHelper,$char(9) _ "Set tStrings(tStrings) = tCurrString")
					Do ..addDelimLevel(tHelper.Implementation, tPath, tSeps, tSepPos + 1, tPadChars, tStripAction, tRepSeparator)
				}
				Else {
					Set tObjProperty = $TR($$$GetTopFieldProp(tColKey, "objproperty"), "$", "")
					Set tConvert = ""
					Set tRepeating = +$$$GetTopFieldProp(tColKey, "repeating")
					Set tDatatype = $$$GetTopFieldProp(tColKey, "datatype")
					If (tDatatype '= "")&&($$$NormalizeClassname(tDatatype)'="%Library.String") Set tConvert = " pObject." _ tObjProperty _ "DisplayToLogical("
					
					Set tGetPrefix = tConvert _ $select(tPadChars = "": "", 1: "$zstrip(")
					Set tGetSuffix = $select(tPadChars = "": "", 1: ", "_ tStripAction _ ", " _ tPadChars _ ")") _ $select(tConvert = "": "", 1: ")")
					Set tTopField = ($length(tObjProperty, ".") = 1)
					If tTopField {
						$$$WriteCode(tHelper,$char(9) _ "If pGetTopFields {")
						Set tIndent = tIndent _ $char(9)
					}
					If tRepeating {
						Set tLoopVar = $$$LoopVar
						$$$WriteCode(tHelper,tIndent _ "For "_tLoopVar_"=1:1:$length(tCurrString," _ tRepSeparator _ ") {")
						$$$WriteCode(tHelper,tIndent _ $char(9) _ "Set tRepString = " _ tGetPrefix _ "$piece(tCurrString," _ tRepSeparator _ ","_tLoopVar_")" _ tGetSuffix)
						$$$WriteCode(tHelper,tIndent _ $char(9) _ "Set tStatus = pObject." _ tObjProperty _ ".Insert(tRepString)")
						$$$WriteCode(tHelper,tIndent _ $char(9) _ "If $$$ISERR(tStatus) Quit")
						$$$WriteCode(tHelper,tIndent _ "}")
						$$$WriteCode(tHelper,tIndent _ "If $$$ISERR(tStatus) Quit")
					}
					Else {
						$$$WriteCode(tHelper,tIndent _ "Set pObject." _ tObjProperty _ " = " _ tGetPrefix _ "tCurrString" _ tGetSuffix)
					}
					If tTopField {
						Set tIndent = $extract(tIndent,1,*-1)
						$$$WriteCode(tHelper,tIndent _ "}")
					}
				}
			}
		}
		
		$$$WriteCode(tHelper,$char(9) _ "Quit tStatus")
	
		$$$WriteCode(tMainMethod,$char(9) _ "}")
		$$$WriteCode(tMainMethod,$char(9) _ "Catch ex {")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tStatus = ex.AsStatus()")
		$$$WriteCode(tMainMethod,$char(9) _ "}")
		$$$WriteCode(tMainMethod,$char(9) _ "If $$$ISERR(tStatus) { Set pObject = $$$NULLOREF }")
		$$$WriteCode(tMainMethod,$char(9) _ "Else { Set pObject = tObject }")
		$$$WriteCode(tMainMethod,$char(9) _ "Quit tStatus")
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Helper method to generate PutObject() code.
ClassMethod generatePutObject(pRecordMapDef As %String) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set tDef = pRecordMapDef
		
		Set tMethodCount = 2
		Set tMainMethod = ..addPutMethod(tDef, "PutObject", 0, tMethodCount)
	
		
		$$$WriteCode(tMainMethod,$char(9)_"Try {")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tStatus = $$$OK")
		$$$WriteCode(tMainMethod,$char(9,9) _ "If '$IsObject(pStream) {")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "Set tFilename = pStream")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "Set pStream = ##class(%IO.FileStream).%New()")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "Do pStream.Open(tFilename,""WAE"",,"""_$$$GetRecordProp("charEncoding")_""", .tStatus)")
		$$$WriteCode(tMainMethod,$char(9,9,9) _ "If $$$ISERR(tStatus) Quit")
		$$$WriteCode(tMainMethod,$char(9,9) _ "}")

		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tHasTopFields = $parameter(pObject,""INCLUDETOPFIELDS"")")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set pStream.CharEncoding = """_ $$$GetRecordProp("charEncoding") _ """")
		$$$WriteCode(tMainMethod,"")
		
		Set tMethodCount = $$$nextSequenceNumber(tMethodCount)
		Set tMethodName = "PutRecord"
		Set tHelper = ..addPutMethod(tDef, tMethodName,,tMethodCount)
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tStatus = .."_tMethodName_"(pStream, pObject, tHasTopFields, .pPadArray)")
		$$$WriteCode(tMainMethod,$char(9,9) _ "If $$$ISERR(tStatus) Quit")
	
		$$$WriteCode(tHelper,$char(9) _ "Set tStatus = $$$OK")
		$$$WriteCode(tHelper,$char(9) _ "Set tmpStream=##class(%Stream.TmpBinary).%New()")
		Set tRecTerminator = $$$GetRecordProp("recordTerminator")
		Set tRecType = $$$GetRecordProp("type")
		Set tRecFieldSep = $$$GetRecordProp("fieldSeparator")
		Set tSeps = $$$GetRecordProp("separators")
		Set tPadFromLeft = $$$GetRecordProp("padFromLeft")
		Set tPadChars = $$$GetRecordProp("paddingChars")
		
		Set tRecLabel = $$$GetRecordProp("label")
		If tRecLabel '= "" {
			$$$WriteCode(tHelper,$char(9) _ "Set tStatus = tmpStream.Write("""_tRecLabel_""")")
			$$$WriteCode(tHelper,$char(9) _ "If $$$ISERR(tStatus) Quit tStatus")
		}
		
		Set tObjects(..#DEFAULTSUBSCRIPT) = $get($$$localStructure("objdata", "path"))
		Set tTopPackage = $piece(tObjects(..#DEFAULTSUBSCRIPT), ".", 1, $length(tObjects(..#DEFAULTSUBSCRIPT), ".")-1)
		Set tKey = ""
		For {
			Set tKey = $order($$$localStructure("objdata", "path", tKey), 1, tObjData)
			Quit:(tKey = "")
			If '$data(tObjData) Continue
			If $listget(tObjData, 2) { Set tObjectName = tTopPackage _ "." _ $listget(tObjData, 3) }
			Else { Set tObjectName = tObjects(..#DEFAULTSUBSCRIPT) _ "." _ tKey }
			Set tObjects(tKey) = tObjectName
		}
		
		If tRecType = "fixedwidth" {
			Set tFieldSep = $$$GetRecordProp("fieldSeparator")
			
			Set tLastProp = $$$PrevField("")
			Set tProp = ""
			For {
				Set tProp = $$$NextField(tProp)
				Quit:tProp=""
				Set tObjProperty = $TR($$$GetTopFieldProp(tProp, "objproperty"),"$","")
				Set tWidth = $$$GetTopFieldProp(tProp, "width")
				Set tIgnored = +$$$GetTopFieldProp(tProp,"ignored")
				If 'tIgnored {
					Set tObjPart = $piece(tObjProperty, ".", 1, $length(tObjProperty, ".")-1)
					Set tPropPart = $piece(tObjProperty, ".", $length(tObjProperty,"."))
					If tObjPart = "" { Set tObjPart = ..#DEFAULTSUBSCRIPT }
					Set tObjectName = tObjects(tObjPart)
					If $length(tObjProperty, ".") = 1 {
						$$$WriteCode(tHelper,$char(9) _ "If pHasTopFields { Set tValue = ##class("_tObjectName_")."_tPropPart _"LogicalToDisplay(pObject."_tObjProperty _"), tLen = $length(tValue) }")
						$$$WriteCode(tHelper,$char(9) _ "Else { Set tValue = """", tLen = 0}")
					}
					Else {
						$$$WriteCode(tHelper,$char(9) _ "Set tValue = ##class("_tObjectName_")."_tPropPart_"LogicalToDisplay(pObject."_tObjProperty _"), tLen = $length(tValue)")
					}
				} Else {
					$$$WriteCode(tHelper,$char(9) _ "Set tValue = """", tLen = 0")
				}
				$$$WriteCode(tHelper,$char(9) _ "If "_tWidth_" > tLen {")
				$$$WriteCode(tHelper,$char(9,9) _ "Set tPadding = $get(pPadArray("_tWidth_" - tLen))")
				$$$WriteCode(tHelper,$char(9,9) _ "If tPadding = """" {")
				$$$WriteCode(tHelper,$char(9,9,9) _ "Set $piece(tPadding, "_tPadChars_", ("_tWidth_" - tLen + 1)) = """"")
				$$$WriteCode(tHelper,$char(9,9,9) _ "Set pPadArray("_tWidth_"-tLen) = tPadding")
				$$$WriteCode(tHelper,$char(9,9) _ "}")
				$$$WriteCode(tHelper,$char(9,9) _ "Set tValue = " _ $select(tPadFromLeft: "tPadding_tValue", 1: "tValue_tPadding"))
				$$$WriteCode(tHelper,$char(9) _ "}")

				Set tTrailingData = $$$GetTopFieldProp(tProp, "trailingData")
				If tTrailingData '= "" $$$WriteCode(tHelper,$char(9) _ "Set tValue = tValue _ " _tTrailingData)
				If (tFieldSep '= "")&&('(tLastProp = tProp)) $$$WriteCode(tHelper,$char(9) _ "Set tValue = tValue _ "_ tFieldSep)
				$$$WriteCode(tHelper,$char(9) _ "Set tStatus = tmpStream.Write(tValue)")
				$$$WriteCode(tHelper,$char(9) _ "If $$$ISERR(tStatus) Quit tStatus")

				If tProp = tLastProp Quit
			}
		}
		ElseIf tRecType = "delimited" {
			Merge $$$localStructure("objnames") = tObjects
			New $$$RepeatData
			Do ..delimPutTraverse(tHelper.Implementation, tSeps, "",$char(9))
		}
		
		If tRecTerminator '= "" {
			$$$WriteCode(tHelper,$char(9) _ "Set tStatus = tmpStream.Write("_tRecTerminator_")")
			$$$WriteCode(tHelper,$char(9) _ "If $$$ISERR(tStatus) Quit tStatus")
		}

		$$$WriteCode(tHelper,$char(9) _ "Do pStream.CopyFrom(tmpStream,,0,.tStatus)")

		$$$WriteCode(tHelper,$char(9) _ "Quit tStatus")
		
		$$$WriteCode(tMainMethod,$char(9,9) _ "If pFlush Do pStream.Flush(.tStatus)")
		$$$WriteCode(tMainMethod,$char(9,9) _ "If $$$ISERR(tStatus) Quit")
		$$$WriteCode(tMainMethod,$char(9) _ "}")
		$$$WriteCode(tMainMethod,$char(9) _ "Catch ex {")
		$$$WriteCode(tMainMethod,$char(9,9) _ "Set tStatus = ex.AsStatus()")
		$$$WriteCode(tMainMethod,$char(9) _ "}")
		$$$WriteCode(tMainMethod,$char(9) _ "Quit tStatus")
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Helper method to create %Dictionary.MethodDefinition objects for generateGetObject().
ClassMethod addGetMethod(pDef As %Dictionary.ClassDefinition, pMethodName As %String, pIsHelper As %Boolean = 1, pSequenceNumber As %Integer) As %Dictionary.MethodDefinition [ Internal, Private ]
{
	Set tMethodId = pDef.Methods.FindObjectId(pDef.Name_"||"_pMethodName)
	If tMethodId {
		Set tMethod = pDef.Methods.GetAt(tMethodId)
	}
	Else {
		Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
		Set tMethod.Name = pMethodName
		Set tMethod.parent = pDef
		Set tMethod.Description=..#GENERATEDADVISORY
	}
	
	Set tSuper = ##class(%Dictionary.MethodDefinition).%OpenId("EnsLib.RecordMap.RecordMap||"_pMethodName,0)
	If $IsObject(tSuper) {
		Set tMethod.Description = ..#GENERATEDADVISORY_tSuper.Description
	}
	
	If pIsHelper {
		Set tMethod.FormalSpec = "pStream:%IO.DeviceStream,pObject:%RegisteredObject,pGetTopFields:%Boolean,pTimeout:%Numeric,&pLookAhead:%String="""",pLabelFound:%Boolean=0"
		Set tMethod.ReturnType = "%Status"
		Set tMethod.Internal = 1
		Set tMethod.Private = 1
	}
	Else { ; Main GetObject() Method
		Set tMethod.FormalSpec = "pStream:%IO.DeviceStream,*pObject:%RegisteredObject,pTimeout:%Numeric=-1,&pLookAhead:%String="""",pLabelFound:%Boolean=0"
		Set tMethod.ReturnType = "%Status"
	}
	Set tMethod.ClassMethod = 1
	Set tMethod.SequenceNumber = pSequenceNumber
	Do tMethod.Implementation.Clear()
	Quit tMethod
}

/// Helper method to create %Dictionary.MethodDefinition objects for generatePutObject().
ClassMethod addPutMethod(pDef As %Dictionary.ClassDefinition, pMethodName As %String, pIsHelper As %Boolean = 1, pSequenceNumber As %Integer) As %Dictionary.MethodDefinition [ Internal, Private ]
{
	Set tMethodId = pDef.Methods.FindObjectId(pDef.Name_"||"_pMethodName)
	If tMethodId {
		Set tMethod = pDef.Methods.GetAt(tMethodId)
	}
	Else {
		Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
		Set tMethod.Name = pMethodName
		Set tMethod.parent = pDef
		Set tMethod.Description=..#GENERATEDADVISORY
	}
	
	Set tSuper = ##class(%Dictionary.MethodDefinition).%OpenId("EnsLib.RecordMap.RecordMap||"_pMethodName,0)
	If $IsObject(tSuper) {
		Set tMethod.Description = ..#GENERATEDADVISORY_tSuper.Description
	}
	
	If pIsHelper {
		Set tMethod.FormalSpec = "pStream:%IO.DeviceStream,pObject:%RegisteredObject,pHasTopFields:%Boolean,&pPadArray:%String"
		Set tMethod.ReturnType = "%Status"
		Set tMethod.Internal = 1
		Set tMethod.Private = 1
	}
	Else { ; Main PutObject() Method
		Set tMethod.FormalSpec = "pStream:%IO.DeviceStream,pObject:%RegisteredObject,pFlush:%Boolean=1,&pPadArray:%String"
		Set tMethod.ReturnType = "%Status"
	}
	Set tMethod.ClassMethod = 1
	Set tMethod.SequenceNumber = pSequenceNumber
	Do tMethod.Implementation.Clear()
	Quit tMethod
}

/// Recursive method used by generateGetObject() to traverse and generate code for 
/// delimited RecordMap structures.
ClassMethod addDelimLevel(pCode As %Stream.Object, pPath As %String, pSeps As %List, pCurrSepPos As %Integer, pPadChars As %String, pStripAction As %String, pRepSeparator As %String, pIndent As %String = {$char(9)}) [ Internal, Private ]
{
	Set tStruc = $name($$$localStructure)_"("_pPath_")"
	Set tIndent = pIndent
	
	Set tKey = ""
	For {
		Set tKey = $order(@tStruc@(tKey))
		Quit:(tKey = "")
		Continue:(tKey '= +tKey)
		
		Set tIgnored = +$get(@tStruc@(tKey, "ignored"))
		Continue:tIgnored
		
		Do pCode.WriteLine(tIndent _ "Set tStrings(tStrings+1) = $piece(tStrings(tStrings), "_$listget(pSeps, pCurrSepPos)_", "_tKey_")")
		Do pCode.WriteLine(tIndent _ "Set tStrings = tStrings + 1")
		
		If $data(@tStruc@(tKey,1)) {
			Do ..addDelimLevel(pCode, pPath _ ","_ tKey, pSeps, pCurrSepPos + 1, pPadChars, pStripAction, pRepSeparator, tIndent)
		}
		Else {
			Set tObjProperty = $TR($get(@tStruc@(tKey, "objproperty")), "$", "")
			Set tRepeating = +$get(@tStruc@(tKey, "repeating"))
			Set tConvert = ""
			Set tDatatype = $get(@tStruc@(tKey, "datatype"))
			If (tDatatype '= "")&&($$$NormalizeClassname(tDatatype)'= "%Library.String") Set tConvert = "pObject." _ tObjProperty _ "DisplayToLogical("
			
			Set tGetPrefix = tConvert _ $select(pPadChars = "": "", 1: "$zstrip(")
			Set tGetSuffix = $select(pPadChars = "": "", 1: ", "_pStripAction _ ", " _ pPadChars _ ")") _ $select(tConvert = "": "", 1: ")")
			Set tTopField = ($length(tObjProperty, ".") = 1)
			If tTopField {
				Do pCode.WriteLine(tIndent _ "If pGetTopFields {")
				Set tIndent = tIndent _ $char(9)
			}
			If tRepeating {
				Set tLoopVar = $$$LoopVar
				Do pCode.WriteLine(tIndent _ "For "_tLoopVar_"=1:1:$length(tStrings(tStrings), " _ pRepSeparator _") {")
				Do pCode.WriteLine(tIndent _ $char(9) _ "Set tRepString = " _ tGetPrefix _ "$piece(tStrings(tStrings)," _ pRepSeparator _ ", " _ tLoopVar _ ")" _ tGetSuffix)
				Do pCode.WriteLine(tIndent _ $char(9) _ "Set tStatus = pObject." _ tObjProperty _ ".Insert(tRepString)")
				Do pCode.WriteLine(tIndent _ $char(9) _ "If $$$ISERR(tStatus) Quit")
				Do pCode.WriteLine(tIndent _ "}")
				Do pCode.WriteLine(tIndent _ "If $$$ISERR(tStatus) Quit tStatus")
			}
			Else {
				Do pCode.WriteLine(tIndent _ "Set pObject." _ tObjProperty _ " = " _ tGetPrefix _ "tStrings(tStrings)" _ tGetSuffix)
			}
			If tTopField {
				Set tIndent = $extract(tIndent,1,*-1)
				Do pCode.WriteLine(tIndent _ "}")
			}
		}
		Do pCode.WriteLine(tIndent _ "Kill tStrings(tStrings)")
		Do pCode.WriteLine(tIndent _ "Set tStrings = tStrings - 1")
	}
}

/// Recursive method used by generatePutObject() to traverse and generate code for 
/// delimited RecordMap structures.
ClassMethod delimPutTraverse(pCode As %Stream.Object, pSeps As %List, pLoc As %String, pIndentChars As %String = "") [ Internal, Private ]
{
	Set tStruc = $name($$$localStructure)_"(""parse"",""struc"""_$select(pLoc '= "":","_pLoc, 1:"")_")"
	Set tEscaping = $$$GetRecordProp("escaping")
	If $Case(tEscaping, "quote":1, "all":1, :0) { Set tEscChar = $$$GetRecordProp("escapeSequence") }
	Else { Set tEscChar = "" }
	Set tSeps = $$$GetRecordProp("separators")
	Set tSepList = ""
	If $listlength(tSeps) Set tSepList = $listtostring(tSeps)
	Set tSepList = "$lb("_tSepList_")"
	Set tEscCodePre = $select(tEscChar '= "": "..Escape(", 1: "")
	Set tEscCodePost = $select(tEscChar '="": ", "_tSepList_","""_tEscaping_""","_tEscChar_")", 1: "")
	Set tEmptyField = $select(tEscaping = "all" : tEscChar_"_"_tEscChar, 1:"""""")
	
	Set tSepDepth = $select(pLoc = "": 1, 1:$length(pLoc, ",")+1)
	Set tCurrentSep = $listget(pSeps, tSepDepth)
	Set tRepSeparator = $$$GetRecordProp("repeatSeparator")
	Set tWriteCount = 0
	Set tKey = ""
	For {
		Set tKey = $order(@tStruc@(tKey))
		Quit:(tKey = "")
		Continue:(tKey '= +tKey)

		Set tWriteCount = tWriteCount + 1
		If $data(@tStruc@(tKey,1)) {
			If (tWriteCount > 1) Do pCode.WriteLine(pIndentChars _ "Do tmpStream.Write("_tCurrentSep_")")
			Do ..delimPutTraverse(pCode, pSeps, $select(pLoc'="":pLoc_",",1:"")_tKey,pIndentChars)
		}
		Else {
			Set tObjProperty = $TR($get(@tStruc@(tKey, "objproperty")),"$","")
			Set tObjRef = "pObject." _ tObjProperty
			Set tTopField = ($length(tObjProperty, ".") = 1)
			Set tIsRepeating = +$get(@tStruc@(tKey,"repeating"))
			Set tIgnored = +$get(@tStruc@(tKey,"ignored"))
			Set tConvert = ""
			Set tDatatype = $get(@tStruc@(tKey, "datatype"))
			If (tDatatype '= "")&&($$$NormalizeClassname(tDatatype)'= "%Library.String") Set tConvert = tObjRef_"LogicalToDisplay("
			Set tPutValue =  tEscCodePre _ tConvert _ tObjRef _ $select(tConvert = "": "", 1: ")") _ tEscCodePost

			If tIsRepeating && 'tIgnored {
				If (tWriteCount > 1) Do pCode.WriteLine(pIndentChars _ "Do tmpStream.Write(" _ tCurrentSep _")")
				If tTopField {
					Do pCode.WriteLine(pIndentChars _ "If pHasTopFields {")
					Set pIndentChars = pIndentChars _ $char(9)
				}
				Set tLoopVar = $$$LoopVar
				Do pCode.WriteLine(pIndentChars _ "For " _ tLoopVar _ "=1:1:" _ tObjRef _ ".Count() {")
				Set pIndentChars = pIndentChars _ $char(9)
				Do pCode.WriteLine(pIndentChars _ "Do tmpStream.Write($select("_tLoopVar_"=1: """", 1: "_tRepSeparator_") _ "_tEscCodePre_tConvert_tObjRef_".GetAt("_tLoopVar_")"_$select(tConvert="": "", 1:")")_tEscCodePost_")")
				Set pIndentChars = $Extract(pIndentChars,1,*-1)
				Do pCode.WriteLine(pIndentChars _ "}")
				If tTopField {
					Set pIndentChars = $Extract(pIndentChars,1,*-1)
					If (tEscaping="all") {
						Do pCode.WriteLine(pIndentChars _ "} Else {")
						Set pIndentChars = pIndentChars _ $char(9)
						Do pCode.WriteLine(pIndentChars _ "Do tmpStream.Write("_tEmptyField _ ")")
						Set pIndentChars = $Extract(pIndentChars,1,*-1)
					}
					Do pCode.WriteLine(pIndentChars _ "}" )
				}
			}
			Elseif 'tIgnored {
				Do pCode.WriteLine(pIndentChars _ "Do tmpStream.Write("_$select(tWriteCount > 1: tCurrentSep _ " _ ", 1: "") _ $select(tTopField: "$select(pHasTopFields: "_tPutValue_",1: "_tEmptyField_")", 1: tPutValue) _ ")")
			}
			Else {
				Set tPutValue = $select(tWriteCount > 1:tCurrentSep,1:"")
				If (tEscaping="all") {
					Set tPutValue = tPutValue_$select(tPutValue'="": "_", 1:"")_tEscChar_"_"_tEscChar
				}
				If (tPutValue '= "") {
					Do pCode.WriteLine(pIndentChars _ "Do tmpStream.Write("_tPutValue _ ")")
				}
			}
		}
	}
}

/// Helper method to output an object definition to the current device.
ClassMethod displayObject(pObjName As %String, ByRef pObjArray, ByRef pFound, pShowTopFields As %Boolean = 1, pDisplayDetails As %Boolean = 1, pTopObjectName As %String = "") [ Internal ]
{
	Write !,$$$Text("Object")_": ",pObjName
	Set tPackagePrefix = $piece(pTopObjectName, ".", 1, $length(pTopObjectName, ".")-1)
	Set tFieldKey = ""
	For {
		Set tFieldKey = $order(pObjArray(tFieldKey))
		Quit:tFieldKey=""
		Set tObjData = $get(pObjArray(tFieldKey,"object"))
		Set tObject = $listget(tObjData)
		If tObject '= "" {
			Set tDatatype = $select($listget(tObjData, 2): tPackagePrefix, 1: pTopObjectName)_ "."_tObject
			If '$data(pFound(tObject)) {
				Set pFound(tObject) = 0
			}
		}
		ElseIf 'pShowTopFields {
			Continue
		}
		Else {
			Set tDatatype = $get(pObjArray(tFieldKey,"datatype"),"%String")
		}
		Write !,?5,$$$Text("Field")_": ",$get(pObjArray(tFieldKey))_$select($get(pObjArray(tFieldKey,"repeating")): "()", 1: "")
		If pDisplayDetails {
			Set tWidth = +$get(pObjArray(tFieldKey,"width"))
			Set tIndex = $get(pObjArray(tFieldKey,"index"))
			If tIndex'="" Set tIndex = "; " _ $case(tIndex,1:"Indexed","bitmap":"Bitmap Index","idkey":"IdKey Index")
			Set tRequired = +$get(pObjArray(tFieldKey,"required"))
			Set tSqlCol = +$get(pObjArray(tFieldKey,"sqlCol"))
			Write "  [ Type = ", tDatatype, $select(tWidth: "; "_$$$Text("Width")_" = "_tWidth, 1: "")
			Write $select(tIndex'="": tIndex, 1: ""),$select(tRequired: "; "_$$$Text("Required"), 1: "")
			Write $select(tSqlCol: "; SqlColumn = "_tSqlCol, 1:""), " ]"
		}
	}
	Quit
}

/// Helper method to generate a class definition based on the supplied parameters.
ClassMethod generateClass(pClassname As %String, ByRef pObjStructure As %String, pSchema As %String, pClassType As %Integer, pDisplay As %Integer = 1, pTopStructure As %Integer = 0, pOverwriteBehaviour As %Integer = 2, pIncludeTopFields As %Boolean = 1, pBaseObject As %String = "", Output pGenerated As %Boolean, pComplexBatch As %Integer = 0, pKeepStorage As %Boolean = 1, pAnnotation As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Kill pGenerated
	Kill tOldStorage
	Set pGenerated = 0
	If ##class(%Dictionary.ClassDefinition).%ExistsId(pClassname) {
		If (pKeepStorage) {
			Merge tOldStorage = ^oddDEF(pClassname,$$$cCLASSstorage)
		}
		Set tSC = ..checkExistingClass(pClassname,.tRegenerate,pOverwriteBehaviour,pDisplay)
		If $$$ISERR(tSC) || ('tRegenerate) Quit tSC
	}
	Set tDef = ##class(%Dictionary.ClassDefinition).%New(pClassname)
	If '$IsObject(tDef) Quit $$$ADDSC($g(%objlasterror,1), $$$ERROR($$$CannotCreateObject, "%Dictionary.ClassDefinition"))
	Set tDef.ProcedureBlock = 1
	Set tDef.Super = $case(pClassType, 1:$select(pComplexBatch: "EnsLib.RecordMap.ComplexChild", 1: "%Persistent"), 2:"%RegisteredObject", :"%SerialObject")_",%XML.Adaptor"_$select(pTopStructure:",Ens.Request,EnsLib.RecordMap.Base",1:"")
	Set tDef.Description=..#GENERATEDADVISORY
	//Set tDef.GeneratedBy = pSchema ; allow normal compilation
	If (pAnnotation '= "") {
		Set tDef.Description = tDef.Description_pAnnotation
	}
	Do ..updateDescription(tDef, pSchema)
	Set tSequenceNumber = 0
	
	/// All records should be marked as generated
	Set tParm = ##class(%Dictionary.ParameterDefinition).%New()
	Set tParm.parent = tDef
	Set tParm.Name = $$$RecordMapGenerated
	Set tParm.Default = 1
	Set tParm.SequenceNumber = $$$nextSequenceNumber(tSequenceNumber)
	
	If pTopStructure {
		Set tParm2 = ##class(%Dictionary.ParameterDefinition).%New()
		Set tParm2.parent = tDef
		Set tParm2.Name = "INCLUDETOPFIELDS"
		Set tParm2.Default = pIncludeTopFields
		Set tParm2.SequenceNumber = $$$nextSequenceNumber(tSequenceNumber)
	}
	
	If (pTopStructure = 4) {
		Set tStorage = ##class(%Dictionary.StorageDefinition).%New()
		If '$IsObject(tStorage) Quit $$$ERROR($$$CannotCreateObject, "%Dictionary.StorageDefinition")
		Set tStorage.Name = "Default"
		Set tStorage.parent = tDef
		If $data(tOldStorage("Default")) {
			Merge tDefaultStorage = tOldStorage("Default")
			Kill tOldStorage("Default")

			Set tStorage.Type = $get(tDefaultStorage($$$cSDEFtype))
			Set tStorage.DefaultData = $get(tDefaultStorage($$$cSDEFdefaultdata))
			Set tStorage.DataLocation = $get(tDefaultStorage($$$cSDEFdatalocation))
			Set tStorage.IdLocation = $get(tDefaultStorage($$$cSDEFidlocation))
			Set tStorage.IndexLocation = $get(tDefaultStorage($$$cSDEFindexlocation))
			Set tStorage.StreamLocation = $get(tDefaultStorage($$$cSDEFstreamlocation))
			Set tStorage.ExtentSize = $get(tDefaultStorage($$$cSDEFextentsize))
			Set tStorageName = ""
			For {
				Set tStorageName = $order(tDefaultStorage($$$cSDEFdata,tStorageName))
				Quit:(tStorageName = "")
				Set tStorageData = ##class(%Dictionary.StorageDataDefinition).%New()
				Set tStorageMap(tStorageName) = tStorageData
				Set tStorageData.parent = tStorage
				Set tStorageData.Name = tStorageName
				Set tStorageData.Structure = $get(tDefaultStorage($$$cSDEFdata,tStorageName,$$$cSDEFDATAstructure))
				Set tStorageData.Subscript = $get(tDefaultStorage($$$cSDEFdata,tStorageName,$$$cSDEFDATAsubscript))
				Set tValPos = ""
				For {
					Set tValPos = $order(tDefaultStorage($$$cSDEFdata,tStorageName,$$$cSDEFDATAvalue,tValPos))
					Quit:(tValPos = "")
					Set tStorageValue = ##class(%Dictionary.StorageDataValueDefinition).%New()
					Set tStorageValue.parent = tStorageData
					Set tStorageValue.Name = tValPos
					Set tStorageValue.Value = $get(tDefaultStorage($$$cSDEFdata,tStorageName,$$$cSDEFDATAvalue,tValPos,$$$cSDEFDATAVALvalue))
				}
			}
		}
		Else {
			Set tStorage.Type = "%Storage.Persistent"
		}
	}
	
	Set tPropKey=""
	For {
		Set tPropKey = $order(pObjStructure(tPropKey)) 
		Quit:tPropKey=""
		Set tProp = ##class(%Dictionary.PropertyDefinition).%New()
		Set tProp.parent = tDef
		Set tProp.SequenceNumber = $$$nextSequenceNumber(tSequenceNumber)
		Set tProp.Name = $get(pObjStructure(tPropKey))
		Set tProp.Description = $get(pObjStructure(tPropKey,"annotation"))
		If ((tProp.Description'="")&&(tProp.Description'[$C(13,10))) Set tProp.Description = $replace(tProp.Description,$C(10),$C(13,10))
		Set tObjData = $get(pObjStructure(tPropKey,"object"))
		Set tObjectType = $listget(tObjData, 1)
		If tObjectType '= "" {
			If $listget(tObjData, 2) {
				Set tProp.Type = $piece(pBaseObject, ".", 1, $length(pBaseObject, ".")-1) _ "." _ tObjectType
			}
			Else {
				Set tProp.Type = pBaseObject _ "." _ tObjectType
			}
		}
		Else {
			Set tProp.Type = $get(pObjStructure(tPropKey,"datatype"),"%String")
		}
		Set tWidth = $get(pObjStructure(tPropKey,"width"))
		If $get(pObjStructure(tPropKey,"required")) Set tProp.Required=1
		If $get(pObjStructure(tPropKey,"repeating")) Set tProp.Collection = "list"
		Set tIndexType = $get(pObjStructure(tPropKey,"index"))
		If tIndexType '= "" {
			Set tIndex = ##class(%Dictionary.IndexDefinition).%New()
			Set tIndex.parent = tDef
			Set tIndex.Name = $get(pObjStructure(tPropKey))_"Idx"
			Set tIndex.Properties = tProp.Name
			If tIndexType = "bitmap" { Set tIndex.Type=tIndexType }
			ElseIf tIndexType="unique" { Set tIndex.Unique=1 }
			ElseIf tIndexType="idkey" { Set tIndex.IdKey=1 }
			Set tSC = tIndex.%Save()
			If $$$ISERR(tSC) Quit
		}
		
		If +tWidth {
			If tProp.Type="%String" {
				Do tProp.Parameters.SetAt(tWidth,"MAXLEN")
			}
			ElseIf tProp.Type="%Integer" {
				Do tProp.Parameters.SetAt((10**tWidth)-1,"MAXVAL")
			}
		}
		Set tPropParams = $get(pObjStructure(tPropKey,"params"))
		If (tPropParams '= "") {
			For k = 1:1:$length(tPropParams, ";") {
				Set tPair = $piece(tPropParams, ";", k)
				Set tParamName = $zstrip($piece(tPair, "=", 1), "<>W")
				Set tParamValue = $zstrip($piece(tPair, "=", 2), "<>W")
				If (tParamName = "MAXLEN") && (tParamValue = """""") {
					Do tProp.Parameters.SetAt("", tParamName)  // Fix PL120860
				}
				ElseIf (tParamName '= "") && (tParamValue '= "") {
					Do tProp.Parameters.SetAt(tParamValue, tParamName)
				}
			}
		}
		Set tSqlCol = $get(pObjStructure(tPropKey,"sqlCol"))
		If +tSqlCol { 
			Set tProp.SqlColumnNumber = +tSqlCol
		}
		// Individual node storage
		If (pTopStructure = 4) && (tObjectType '= "") {
			Set tDataName = tProp.Name _ "Node"
			If '$data(tStorageMap(tDataName),tData) {
				Set tData = ##class(%Dictionary.StorageDataDefinition).%New()
				Set tData.Name = tProp.Name_"Node"
			}
			Set tData.Attribute = tProp.Name
			Set tData.Structure = "node"
			Set tData.Subscript = """"_tData.Name_""""
			Set tData.parent = tStorage
			Set tSC = tData.%Save()
			If $$$ISERR(tSC) Quit
		}
		ElseIf (pTopStructure = 5)&&(tObjectType '= "") {
			Set tPersistentProps(tProp.Name) = tProp.Type
		}
		Set tSC = tProp.%Save()
		If $$$ISERR(tSC) Quit
	}
	If $$$ISERR(tSC) Quit tSC
	
	If ((pTopStructure = 5)&&($data(tPersistentProps)) || pComplexBatch) {
		Set tSC = ..addOnDelete(tDef, .tPersistentProps, tSequenceNumber, pComplexBatch)
		If $$$ISERR(tSC) Quit tSC
	}
	
	Set tSC = tDef.%Save()
	If $$$ISERR(tSC) Quit tSC

	If $data(tOldStorage) {
		Merge ^oddDEF(pClassname,$$$cCLASSstorage) = tOldStorage
	}

	Set pGenerated = 1
	Quit $$$OK
}

/// Helper method to generate an OnDelete trigger and %OnDelete() callback when using a
/// Persistent/Persistent/Serial structure.
ClassMethod addOnDelete(pDef As %Dictionary.ClassDefinition, ByRef pPersistentProps, pSequenceNumber As %Integer = 0, pComplexBatch As %Integer = 0) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Set tOnDelTrigger = ##class(%Dictionary.TriggerDefinition).%New()
	If '$IsObject(tOnDelTrigger) Quit $$$ERROR($$$CannotCreateObject,"%Dictionary.TriggerDefinition")
	Set tOnDelTrigger.parent = pDef
	Set tOnDelTrigger.Name = "OnDelete"
	Set tOnDelTrigger.Event = "DELETE"
	Set tOnDelTrigger.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
	
	Set tOnDelTrigger.Code = $c(9)_"Set %ok = ##class("_pDef.Name_").%OnDelete($$$oidForm({ID})) If $$$ISERR(%ok) Quit"_$c(13,10)
	
	Set tDoPropCleanup = $data(pPersistentProps)\10
	If tDoPropCleanup {
		Set tOnNewMeth = ##class(%Dictionary.MethodDefinition).%New()
		If '$IsObject(tOnNewMeth) Quit $$$ERROR($$$CannotCreateObject,"%Dictionary.MethodDefinition")
		Set tOnNewMeth.parent = pDef
		Set tOnNewMeth.Name = "%OnNew"
		Set tOnNewMeth.FormalSpec = "initvalue:%RawString"
		Set tOnNewMeth.Private = 1
		Set tOnNewMeth.ServerOnly = 1
		Set tOnNewMeth.ReturnType = "%Status"
		Set tOnNewMeth.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)
		
		Set tPropKey = ""
		Set tPropList = ""
		For {
			Set tPropKey = $order(pPersistentProps(tPropKey))
			Quit:tPropKey=""
			Set tPropList = tPropList_""","""_tPropKey
			Set tOnDelTrigger.Code = tOnDelTrigger.Code _$char(9)_"Set %ok = ##class("_$get(pPersistentProps(tPropKey))_").%DeleteId({"_tPropKey_"})"
										_$char(13,10,9)_"If $$$ISERR(%ok) Quit"_$c(13,10)
			$$$WriteCode(tOnNewMeth,$char(9)_"Set .."_tPropKey_" = ##class("_$get(pPersistentProps(tPropKey))_").%New()")
		}
		$$$WriteCode(tOnNewMeth,$char(9)_"Quit $$$OK")
		
		Set tOnDelMeth = ##class(%Dictionary.MethodDefinition).%New()
		If '$IsObject(tOnDelMeth) Quit $$$ERROR($$$CannotCreateObject,"%Dictionary.MethodDefinition")
		Set tOnDelMeth.parent = pDef
		Set tOnDelMeth.Name = "%OnDelete"
		Set tOnDelMeth.FormalSpec = "oid:%ObjectIdentity"
		Set tOnDelMeth.ClassMethod = 1
		Set tOnDelMeth.Private = 1
		Set tOnDelMeth.ServerOnly = 1
		Set tOnDelMeth.ReturnType = "%Status"
		Set tOnDelMeth.SequenceNumber = $$$nextSequenceNumber(pSequenceNumber)

		If pComplexBatch {
			$$$WriteCode(tOnDelMeth,$char(9)_"Set tStatus = ##super(oid)")
			$$$WriteCode(tOnDelMeth,$char(9)_"If $$$ISERR(tStatus) Quit tStatus")
		}
		$$$WriteCode(tOnDelMeth,$char(9)_"Set tObject = ..%Open(oid,,.tStatus)")
		$$$WriteCode(tOnDelMeth,$char(9)_"If $$$ISERR(tStatus) Quit tStatus")
		Set tPropList = $extract(tPropList, 3, *)
		If tPropList'="" {
			Set tPropList = tPropList_""""
			$$$WriteCode(tOnDelMeth,$char(9)_"For tPropName = "_tPropList_" {")
			$$$WriteCode(tOnDelMeth,$char(9,9)_"Set tCurrProp = $property(tObject, tPropName)")
			$$$WriteCode(tOnDelMeth,$char(9,9)_"If $IsObject(tCurrProp) Set tStatus = tCurrProp.%Delete(tCurrProp.%Oid())")
			$$$WriteCode(tOnDelMeth,$char(9,9)_"If $$$ISERR(tStatus) Quit")
			$$$WriteCode(tOnDelMeth,$char(9)_"}")
		}
		$$$WriteCode(tOnDelMeth,$c(9)_"Quit tStatus")
	}
	Quit tSC
}

/// Ensure the relationship between the Batch and Record objects exists, is indexed, and 
/// has OnDelete behaviour implemented to clean up records when the Batch is deleted.
ClassMethod addBatchRelationship(pBatchClass As %String, pRecordClass As %String, ByRef pGeneratedClasses As %String, pRecordMap As %String) As %Status [ Internal, Private ]
{
	Set tStatus = $$$OK
	Set tBatchName = $$$NormalizeClassname(pBatchClass)
	Set tBatchDef = ##class(%Dictionary.ClassDefinition).%OpenId(tBatchName,,.tStatus)
	If $system.Status.Equals($$$ERRORCODE($$$LoadObjectNotFound), tStatus) {
		Quit $$$ERROR($$$ClassDoesNotExist, tBatchName)
	}
	If $$$ISERR(tStatus) Quit tStatus
	
	// Process Record class first to get SQL table name
	Set tRecordTableName = $piece(pRecordClass, ".", $length(pRecordClass, "."))
	Set tRecordDef = ##class(%Dictionary.ClassDefinition).%OpenId(pRecordClass)
	If tRecordDef.SqlTableNameIsDefined() Set tRecordTableName = tRecordDef.SqlTableName

	If $$$defMemberKeyGet(pRecordClass,$$$cCLASSparameter,$$$RecordMapGenerated,$$$cPARAMdefault) {
		Set tManyProp = ##class(%Dictionary.PropertyDefinition).IDKEYOpen(pRecordClass, "%ParentBatch")
		If '$IsObject(tManyProp) {
			Set tManyProp = ##class(%Dictionary.PropertyDefinition).%New()
			Set tManyProp.Name = "%ParentBatch"
			Set tManyProp.parent = tRecordDef
		}
		Set tManyProp.Relationship = 1
		Set tManyProp.Cardinality = "one"
		Set tManyProp.Inverse = "Records"
		Set tManyProp.Type = tBatchName
		Set tManyIndex = ##class(%Dictionary.IndexDefinition).IDKEYOpen(pRecordClass, "%ParentBatchIdx")
		If '$IsObject(tManyIndex) {
			Set tManyIndex = ##class(%Dictionary.IndexDefinition).%New()
			Set tManyIndex.Name = "%ParentBatchIdx"
			Set tManyIndex.parent = tRecordDef
		}
		Set tManyIndex.Properties = "%ParentBatch"
		Set tStatus = tRecordDef.%Save()
		If $$$ISERR(tStatus) Quit tStatus
		$$$addGeneratedClass(pGeneratedClasses,pRecordClass)
	}

	If $IsObject(tBatchDef) {
		Set tDefGenerated = $$$defMemberKeyGet(tBatchName,$$$cCLASSparameter,$$$RecordMapGenerated,$$$cPARAMdefault)
		If $select(tDefGenerated '= "": tDefGenerated, 1: $$$comMemberKeyGet(tBatchName,$$$cCLASSparameter,$$$RecordMapGenerated,$$$cPARAMdefault)) {
			Set tSeqNumber = tBatchDef.Properties.Count()+tBatchDef.Parameters.Count()
			Set tOneProp = ##class(%Dictionary.PropertyDefinition).IDKEYOpen(tBatchDef.Name, "Records")
			If '$IsObject(tOneProp) {
				Set tOneProp = ##class(%Dictionary.PropertyDefinition).%New()
				Set tOneProp.Name = "Records"
				Set tOneProp.Relationship = 1
				Set tOneProp.Cardinality = "many"
				Set tOneProp.Inverse = "%ParentBatch"
				Set tOneProp.SequenceNumber = $$$nextSequenceNumber(tSeqNumber)
			}
			Set tOneProp.parent = tBatchDef ; force swizzle to ensure the change gets saved
			Set tOneProp.Type = pRecordClass
		
			// Add OnDelete trigger
			Set tOnDelTrigger = ##class(%Dictionary.TriggerDefinition).IDKEYOpen(tBatchName, "OnDelete")
			If '$IsObject(tOnDelTrigger) {
				Set tOnDelTrigger = ##class(%Dictionary.TriggerDefinition).%New()
				Set tOnDelTrigger.Name = "OnDelete"
				Set tOnDelTrigger.SequenceNumber = $$$nextSequenceNumber(tSeqNumber)
			}
			Set tOnDelTrigger.parent = tBatchDef
			Set tOnDelTrigger.Event = "DELETE"
			Set tOnDelTrigger.Code = $c(9)_"Set %ok = ..deleteRecords({ID})"_$c(13,10)

			Do ..updateDescription(tBatchDef, pRecordMap, 1)
			Set tStatus = tBatchDef.%Save()
			If $$$ISERR(tStatus) Quit tStatus
			$$$addGeneratedClass(pGeneratedClasses,tBatchName)
		}
	}
	// Throw error if Batch class definition doesn't exist...?

	Quit tStatus
}

/// Recursive method to iterate over Composite elements in model to generate object structure.
ClassMethod getCompositeObjects(pComposite As EnsLib.RecordMap.Model.Composite, pRec As EnsLib.RecordMap.Model.Record, ByRef pObjStruc, ByRef pCurrPath As %String = "", pGetImplicitProps As %Boolean, pIgnored As %Boolean = 0) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Set tPropKey = ""
	Set tIgnored = pComposite.ignored||pIgnored
	If tIgnored {
			Set tParseLoc = $name($$$localParseTree)_"("_pCurrPath_")"
			Set @tParseLoc@("ignored") = 1
	}
	For i=1:1:pComposite.SubElements.Count() {
		Set tProperty = pComposite.SubElements.GetNext(.tPropKey)
		If pRec.type = "fixedwidth" {
			Set tNextPath = pCurrPath
		}
		ElseIf pRec.type = "delimited" {
			Set tNextPath = pCurrPath _ "," _ i
		}
		If tProperty.%IsA("EnsLib.RecordMap.Model.Composite") {
			Set tSC = ..getCompositeObjects(tProperty, pRec, .pObjStruc, .tNextPath, pGetImplicitProps, tIgnored)
		}
		Else {
			Set tSC = ..addField(tProperty, pRec, .pObjStruc, pComposite.name, .tNextPath, pGetImplicitProps, tIgnored)
		}
		If $$$ISERR(tSC) Quit
		If pRec.type = "fixedwidth" Set pCurrPath = tNextPath	; return incremented values
	}
	
	Quit tSC
}

/// Method to add Field information to the object structure array.
ClassMethod addField(pField As EnsLib.RecordMap.Model.Field, pRecord As EnsLib.RecordMap.Model.Record, ByRef pObjStruc, pCurrCompName As %String, ByRef pCurrPath As %String, pGetImplicitProps As %Boolean, pIgnored As %Boolean = 0) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Set tObject = pField.GetObjectName()
	Set tHasTopPath = ($extract(pField.name, 1) = "$")
	Set tIgnored = pField.ignored || pIgnored
	If tObject = "" {
		If 'pGetImplicitProps { Quit tSC }
		Else { Set tObject = ..#DEFAULTSUBSCRIPT }
	}
	ElseIf '$data(pObjStruc("objdata", "path", tObject))&&'tIgnored {
		Set tObjLen = $length(tObject, ".")
		For i=1:1:tObjLen {
			Set tCurrObject = $piece(tObject, ".", 1, i)
			Set tGenName = tCurrObject
			Set tGenPath = tCurrObject
			If tHasTopPath {
				Set tGenName = $piece(tObject, ".", i)
				Set tGenPath = "$"_tGenName
			}
			
			If '$data(pObjStruc("objdata", "path", tCurrObject)) { // add to path map
				Set pObjStruc("objdata", "path", tCurrObject) = $listbuild(i, tHasTopPath, tGenName)
				If i = 1 {
					Set tNode = $increment(pObjStruc("objdata", "propcount", ..#DEFAULTSUBSCRIPT))
					Set pObjStruc("objorder", ..#DEFAULTSUBSCRIPT, tNode) = tCurrObject
					Set pObjStruc("objorder", ..#DEFAULTSUBSCRIPT, tNode, "object") = $listbuild(tGenName, tHasTopPath)
				}
				Else {
					Set tWrapperObject = $piece(tCurrObject, ".", 1, i-1)
					Set tLeafObject = $piece(tCurrObject, ".", i)
					Set tNode = $increment(pObjStruc("objdata", "propcount", tWrapperObject))
					Set pObjStruc("objorder", tWrapperObject, tNode) = tLeafObject
					Set pObjStruc("objorder", tWrapperObject, tNode, "object") = $listbuild(tGenName, tHasTopPath)
				}
			}
			
			If $data(pObjStruc("objdata", "genpath", tGenPath), tFoundPath)#2 {
				If tFoundPath '= tCurrObject {
					Set tSC = $$$ERROR($$$EnsRecordMapErrClassCollision, tFoundPath, tCurrObject, tGenPath)
					Quit
				}
			}
			Else {
				Set pObjStruc("objdata", "genpath", tGenPath) = tCurrObject
			}
		}
		If $$$ISERR(tSC) Quit tSC
	}
	
	Set tFieldSep = ..getLogicalChars(pRecord.fieldSeparator)
	Set tTrailing = ..getLogicalChars(pField.trailingData)
	
	If 'tIgnored {
		Set tNode = $increment(pObjStruc("objdata","propcount",tObject))
		Set pObjStruc("objorder",tObject,tNode) = pField.GetFieldName()
	}
	
	Set tParseLoc = $name($$$localParseTree)_"("_pCurrPath_")"
	Set @tParseLoc@("objproperty") = $translate(pField.name, "$", "")
	If (pField.datatype '= "") Set @tParseLoc@("datatype") = pField.datatype
	Set:tIgnored @tParseLoc@("ignored") = 1
	
	If pRecord.type = "fixedwidth" {
		Set:'tIgnored pObjStruc("objorder",tObject,tNode,"width") = pField.width
		Set @tParseLoc@("width") = pField.width
		If (tTrailing '= "") Set @tParseLoc@("trailingData") = tTrailing
		Set $piece(pCurrPath, ",", $length(pCurrPath,",")) = $piece(pCurrPath, ",", $length(pCurrPath,",")) + pField.width + $select(tTrailing = "": 0, 1: $length(tTrailing, ",")) + $select(tFieldSep = "": 0, 1: $length(tFieldSep, ","))
	}
	ElseIf pRecord.type = "delimited" {
		If pField.repeating {
			Set @tParseLoc@("repeating") = 1
			Set:'tIgnored pObjStruc("objorder",tObject,tNode,"repeating") = pField.repeating
		}
	}
	If 'tIgnored {
		If pField.required 			Set pObjStruc("objorder",tObject,tNode,"required") = pField.required
		If (pField.datatype '= "") 	Set pObjStruc("objorder",tObject,tNode,"datatype") = pField.datatype
		If (pField.index '= "")		Set pObjStruc("objorder",tObject,tNode,"index") = pField.index
		If (pField.params '= "")	Set pObjStruc("objorder",tObject,tNode,"params") = pField.params
		If (pField.sqlColumn '= "") Set pObjStruc("objorder",tObject,tNode,"sqlCol") = pField.sqlColumn
		If (pField.annotation '= "") Set pObjStruc("objorder",tObject,tNode,"annotation") = pField.annotation
	}

	Quit tSC
}

/// Get a $char-based representation of the supplied characters.
ClassMethod getLogicalChars(chars As %String) As %String [ Internal ]
{
	If chars="" Quit chars
	Set tChars = $zconvert(chars, "l")

	Set tXLen = $length(tChars,"\x")
	If tXLen = 1 {
		Set tChars = "$char("
		For i=1:1:$length(chars) {
			Set tChars = tChars _ $ascii($extract(chars, i)) _ ","
		}
	}
	Else {
		Set chars = tChars
		Set tChars = "$char("
		For i=2:1:tXLen { ; assume we start with \x
			Set tPiece = $piece(chars,"\x",i)
			If tPiece '= "" Set tChars = tChars _ $zhex(""_tPiece) _ ","
		}
	}
	Set tChars = $extract(tChars,1, *-1) _ ")"
	Quit tChars
}

}
