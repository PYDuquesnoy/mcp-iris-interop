/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This is the SEF Compiler. For each transaction set defined in the SEF file, a parser will be generated that can import and validate
/// documents which conform to that transaction set specification
Class EnsLib.EDI.SEF.Compiler Extends EnsLib.EDI.SEF.MaskNavigator [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the key derived from parsing a document
Property DocKey As %String;

/// This holds the current set name
Property SetName As %String;

/// This holds the current structure index
Property StructureIndex As %Integer [ InitialExpression = 0 ];

/// This holds the CompositeOrdinalModifier stack
Property CompositeModifierStack As EnsLib.EDI.SEF.Util.Stack;

/// This holds the SegmentOrdinalModifier stack
Property SegmentModifierStack As EnsLib.EDI.SEF.Util.Stack;

/// This holds the LoopStack for map resolution
Property LoopStack As EnsLib.EDI.SEF.Util.Stack;

/// This holds the State for map resolution
Property State As %String [ MultiDimensional ];

Property CatOnly As %Boolean;

/// Load a set of SEF files. Give just the filename (without the .SEF extension) if in the standard location, otherwise the full path with ".SEF".
ClassMethod Import(pFiles As %String, pFamily As %String = "X12", Output pCategoryImported As %String, Output pValidationErrors As %String, pUseOld As %Boolean) As %Status
{

	Set tSC=$$$OK, pCategoryImported=""

	#; Create an instance of the compiler
	Set tCompiler=..%New()

	Set tPath=""
	For tI=1:1:$Length(pFiles,",") { Set tFile=$Piece(pFiles,",",tI)  Continue:""=tFile
		Set tNewPath=##class(%File).GetDirectory(tFile)
		Set tFilename=$S(""'=tNewPath:"", 1:##class(%File).NormalizeDirectory(tPath))_tFile
		Set:""'=tNewPath tPath=tNewPath
		Set tSC=tCompiler.Compile(tFilename,pFamily,.tDocKey,.pValidationErrors,.pUseOld) If $$$ISERR(tSC) Quit
		Set pCategoryImported=pCategoryImported_","_tDocKey
	}
	// Remove leading comma
	Set $Extract(pCategoryImported)=""
	Quit tSC
}

/// This retrieves the import category from a file without further compilation
ClassMethod GetImportCategory(pFilename As %String) As %String
{
	Set tImporter=##class(EnsLib.EDI.SEF.Importer).%New()
	Set tSC=tImporter.Import(pFilename,.tDocKey,1) 
	If $$$ISERR(tSC) Set tDocKey=""
	Quit tDocKey
}

/// This adds a descriptor to the master descriptor for a particular Doc/Set
Method AddDescriptor(pType As %String, pDescriptor As %String, Output pDescriptorIndex As %Integer)
{
	If ((pType="t")||(pType="s")||(pType="lb")||(pType="le")) {
	
		#; Segment, LoopBegin, LoopEnd
		Set ..StructureIndex=..StructureIndex+1
		Set $$$vaSchemaGbl(..DocKey,..SetName,"m",..StructureIndex)=pType_"|"_pDescriptor
		If pType="s" {
			#; Create Ordinal back pointer
			Set $$$vaSchemaGbl(..DocKey,..SetName,"o",$Piece(pDescriptor,"|",2))=..StructureIndex
		}
	} elseif ((pType="e")||(pType="cb")||(pType="ce")) {
		
		#; Element, CompositeBegin,CompositeEnd
		Set tNewIndex=$Increment(^IRIS.Temp.EnsEDI.SEF(..DocKey,..SetName,"s",..StructureIndex,"i"))
		Set ^IRIS.Temp.EnsEDI.SEF(..DocKey,..SetName,"s",..StructureIndex,"i",tNewIndex)=pType_"|"_pDescriptor
		
	} elseif (pType="r") {
		
		#; Rule
		Set tNewIndex=$Increment(^IRIS.Temp.EnsEDI.SEF(..DocKey,..SetName,"s",..StructureIndex,"r"))
		Set ^IRIS.Temp.EnsEDI.SEF(..DocKey,..SetName,"s",..StructureIndex,"r",tNewIndex)=pType_"|"_pDescriptor
		
	} else {
		$$$ASSERTNOLOG("0:Unrecognized Type")
	}
	Set pDescriptorIndex=..StructureIndex
}

Method UpdateDescriptor(pIndex As %Integer, pPieceNumber As %Integer, pValue As %String)
{
	Set $Piece($$$vaSchemaGbl(..DocKey,..SetName,"m",pIndex),"|",pPieceNumber)=pValue
}

/// This method imports the specified SEF file, parsing and generating descriptors which are used to drive the SEF Parser.
Method Compile(pFilename As %String, pFamily As %String, Output pCategory As %String, Output pValidationErrors As %String, pUseOld As %Boolean) As %Status
{
	#Dim tDocument As EnsLib.EDI.SEF.Document

	Set $ZT="Trap",tSC=$$$OK
	do {
		Set:pFamily="" pFamily="EDIFACT"
		Set tSC=..ParseDocument(pFilename, pFamily, .pCategory,.tDocument)  Quit:$$$ISERR(tSC)

		$$$ASSERTNOLOG($IsObject(tDocument))

		Set tValidateStatus=$$$OK

		#; Validate the document for internal consistency
		Set tSC=tDocument.Validate(.tValidateStatus)
		If $$$ISERR(tSC) Quit

		Kill pValidationErrors Set pValidationErrors=0
		Do $System.Status.DecomposeStatus(tValidateStatus,.pValidationErrors)
		If pValidationErrors>0 {
			Set tSC=$$$ERROR($$$GeneralError,"Document Validation Failed")
			Quit
		}

		#; Document is valid, initialize the compiler
		Set tSC=..Initialize()  Quit:$$$ISERR(tSC)

		#; Now generate the descriptors for the sets in the document
		Set tSC=tDocument.GenerateDescriptor($this)  Quit:$$$ISERR(tSC)

		Set tAgency=tDocument.Agency,tRef=tDocument.Ref

		#; Generate the ordinal maps for data access
		Set tSetName="" For { Set tSetName=$O($$$vaSchemaGbl(pCategory,tSetName))  Quit:""=tSetName
			Set (tCompOrd,tCompReq)=""
			Set tSegOrd="" For { Set tSegOrd=$O($$$vaSchemaGbl(pCategory,tSetName,"o",tSegOrd),1,tStructIndex)  Quit:""=tSegOrd

				#; Only tally names within a segment
				Kill tNames
				Set tItem="" For { Set tItem=$O(^IRIS.Temp.EnsEDI.SEF(pCategory,tSetName,"s",tStructIndex,"i",tItem),1,tItemInfo)  Quit:""=tItem

					If $Extract(tItemInfo)="e" {
						Set tItemOrd=$Piece(tItemInfo,"|",3),tItemName=$Piece(tItemInfo,"|",2)
						Set tItemDesc=..CreateShortName($Get($$$vaSchemaDescGbl(tAgency,tRef,"ELEM",tItemName),$S(tItemName=+tItemName&&(pFamily="X12"):"item",1:"")_tItemName))

						If tCompOrd'="" {
							If $Increment(tNames("C",tItemDesc))>1 Set tItemDesc=tItemDesc_tNames("C",tItemDesc)

 ;//("e",2|"_..ID_"3|"_tOrdinal_"4|"_tUsrReq_"5|"_tStdReq_"6|"_tActReq_"7|"_..Type_"8|"_tMinLength_"9|"_tMaxLength_"10|"_tRepeatCount_"11|"_tMaskString
							Set $$$vaSchemaGbl(pCategory,tSetName,"o",tSegOrd,tCompOrd,tItemOrd)="E|"_tItemName_"|"_$Piece(tItemInfo,"|",6,10)_"|"_tItemDesc_"|"_$Piece(tItemInfo,"|",5)

							#; If the item can repeat, then indicate so
							If $Piece(tItemInfo,"|",10)>1 Set tCompName=tCompName_"()"

							Set $$$vaSchemaGbl(pCategory,tSetName,"n",tSegOrd,tCompName,tItemDesc)=tCompOrd_"|"_tItemOrd
						} Else {
							Set:$Increment(tNames("S",tItemDesc))>1 tItemDesc=tItemDesc_tNames("S",tItemDesc)

							#; Pick out value for Hierarchical Level Code
							If tItemName=735 && $D($$$vaSchemaGbl(pCategory,tSetName,"c",tItemName,"l",tSegOrd,tItemOrd),tC) {
								Set (tHLC,tHLCval)=""  For { Set tHLCval=$O($$$vaSchemaGbl(pCategory,tSetName,"c",735,"c",tC,tHLCval))  Quit:""=tHLCval
									Set tHLC=tHLC_"="_tHLCval
								} Set $E(tHLC)=""
								$$$ASSERTNOLOG(tHLC'="")
								#; Back patch the segment index ; not used for new X12 schemas, only for old SEF style X12
								Set $Piece($$$vaSchemaGbl(pCategory,tSetName,"m",tStructIndex),"|",9)=tHLC
							}
							Set $$$vaSchemaGbl(pCategory,tSetName,"o",tSegOrd,tItemOrd)="E|"_tItemName_"|"_$Piece(tItemInfo,"|",6,10)_"|"_tItemDesc_"|"_$Piece(tItemInfo,"|",5)

							If $Piece(tItemInfo,"|",10)>1 Set tItemDesc=tItemDesc_"()"

							Set $$$vaSchemaGbl(pCategory,tSetName,"n",tSegOrd,tItemDesc)=tItemOrd
						}
					} ElseIf $Extract(tItemInfo,1,2)="cb" {
		//Do pCompiler.AddDescriptor("cb",..Name_"|"_tRequirement_"|"_tOrdinal_"|"_..Parent.StdRequirement_"|"_..Parent.RepeatCount)
		/*Set tEleID=$P(tEleAttrs,"|",2), tActReq=$P(tEleAttrs,"|",3), tType=$P(tEleAttrs,"|",4)
		Set tMinLen=$P(tEleAttrs,"|",5), tMaxLen=$P(tEleAttrs,"|",6), tMaxUse=$P(tEleAttrs,"|",7)
		Set tName=$P(tEleAttrs,"|",8)
		Set tCodeIndex=$P(tEleAttrs,"|",9)*/

						Set tCompOrd=$Piece(tItemInfo,"|",4),tItemName=$Piece(tItemInfo,"|",2),tCompReq=$Piece(tItemInfo,"|",3),tComRepeat=$Piece(tItemInfo,"|",4),tStdReq=$Piece(tItemInfo,"|",5),tStdRpt=$Piece(tItemInfo,"|",6)
						Set tItemDesc=..CreateShortName($Get($$$vaSchemaDescGbl(tAgency,tRef,"COMP",tItemName),tItemName))
						If $Increment(tNames("S",tItemDesc))>1 Set tItemDesc=tItemDesc_tNames("S",tItemDesc)
						Set $$$vaSchemaGbl(pCategory,tSetName,"o",tSegOrd,tCompOrd)="C|"_tItemName_"|"_tCompReq_"|"_tItemName_"|"_tStdReq_"|"_tStdRpt_"|"_tComRepeat_"|"_tItemDesc

						Set tCompName=tItemDesc

					} ElseIf $Extract(tItemInfo,1,2)="ce" {
						Set (tCompOrd,tCompReq,tComRepeat,CompName)="" Kill tNames("C")
					}
				}
			}
		}
		#; Create the rule cross-index
		Set tSetName="" For { Set tSetName=$O($$$vaSchemaGbl(pCategory,tSetName))  Quit:""=tSetName
			Set (tCompOrd,tCompReq)=""
			Set tSegOrd="" For { Set tSegOrd=$O($$$vaSchemaGbl(pCategory,tSetName,"o",tSegOrd),1,tStructIndex)  Quit:""=tSegOrd
				Set tItem="" For { Set tItem=$O(^IRIS.Temp.EnsEDI.SEF(pCategory,tSetName,"s",tStructIndex,"r",tItem),1,tRule) Quit:""=tItem
					Set $$$vaSchemaGbl(pCategory,tSetName,"r",tSegOrd,tItem)=tRule
				}
			}
		}

		#; Remove the now-redundant "s" node; store static maps
		Set tSetName="" For { Set tSetName=$O($$$vaSchemaGbl(pCategory,tSetName)) Quit:""=tSetName
			Kill ..State, ^IRIS.Temp.EnsEDI.SEF(pCategory,tSetName,"s")
			Set tSC1=..buildSchemaMap(pCategory,tSetName)  Set:$$$ISERR(tSC) tSC=$$$ADDSC(tSC,tSC1)
		}
		Do ##class(EnsLib.EDI.SEF.Schema).BuildCategoryMaps(pCategory)
		Do:(pFamily="X12") ##class(EnsLib.EDI.SEF.Schema).MergeToX12(pCategory,.pUseOld)
		Merge $$$vaSchemaGbl(pCategory,":SEF")=^IRIS.Temp.SEF(pCategory)  Kill ^IRIS.Temp.SEF(pCategory)
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Put Compiler into the initial state, ready to generate set descriptors
Method Initialize() As %Status
{
	Set ..SetName=""
	Kill $$$vaSchemaGbl(..DocKey)

	Set ..SegmentModifierStack=##class(EnsLib.EDI.SEF.Util.Stack).%New()
	$$$ASSERTNOLOG($IsObject(..SegmentModifierStack))

	Set ..CompositeModifierStack=##class(EnsLib.EDI.SEF.Util.Stack).%New()
	$$$ASSERTNOLOG($IsObject(..CompositeModifierStack))

	Set ..LoopStack=##class(EnsLib.EDI.SEF.Util.Stack).%New()
	$$$ASSERTNOLOG($IsObject(..LoopStack))

	Quit $$$OK
}

Method ParseDocument(pFilename As %String, pFamily As %String, Output pCategory As %String, Output pDocument As EnsLib.EDI.SEF.Document) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Import the raw data and derive transaction set name
		Set tImporter=##class(EnsLib.EDI.SEF.Importer).%New()
		Set tSC=tImporter.Import(pFilename,.pCategory)  Quit:$$$ISERR(tSC)

		$$$ASSERTNOLOG(pCategory'="")
		Set ..DocKey=pCategory

		#; Parse the raw data from the SEF global
		Set tParser=##class(EnsLib.EDI.SEF.Parser).%New()
		Set tSC=tParser.ParseDocument(pCategory,pFamily,.pDocument)

		//Kill ^IRIS.Temp.SEF(pCategory)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Returns the Schema structure, showing sequence and hierarchy of segments
Method buildSchemaMap(pDocTypeCategory As %String, pDocTypeName As %String) As %Status
{
	Set tSC=$$$OK
	do {
		#; Must know category
		If '$Data($$$vaSchemaGbl(pDocTypeCategory)) Set tSC=$$$ERROR($$$EnsEDIUnknownCategoryName,pDocTypeCategory) Quit
		
		#; and name to resolve schema
		If '$Data($$$vaSchemaGbl(pDocTypeCategory,pDocTypeName)) Set tSC=$$$ERROR($$$EnsEDIUnknownDocumentTypeName) Quit
		
		#; Establish a collation index, set up stack
		Set tCollateIndex=0
		
		Set tStructIndex="" For { Set tStructIndex=$O($$$vaSchemaGbl(pDocTypeCategory,pDocTypeName,"m",tStructIndex),1,tStructure)  Quit:""=tStructIndex
			Set tType=$Piece(tStructure,"|")
			If tType="t" {
				#; Loops cannot span tables
				Do ..LoopStack.Clear(),..LoopStack.Push(0)
			} elseif tType="lb" {
				#; Increment collating index
				Set tCollateIndex=tCollateIndex+1

				If '$Data(..State(tType,tStructIndex)) {
					#; First time we have seen this loop begin, initialize
					Do ..InitState(tStructIndex,tType,tStructure)
						
					Set ..State(tType,tStructIndex,"c")=tCollateIndex
				}
				#; Push this loop index on the stack
				Do ..LoopStack.Push(tStructIndex)
			} elseif tType="le" {
				Do ..LoopStack.Pop()
			} elseif tType="s" {
				#; Increment collating index
				Set tCollateIndex=tCollateIndex+1

				If '$Data(..State(tType,tStructIndex)) {
					#; First time we have seen this segment, initialize
					Do ..InitState(tStructIndex,tType,tStructure)
				}
				#; Build Location and Collation Strings
				Set (tLocation,tCollation)=""
				For tI=2:1:..LoopStack.CurrentIndex {
					Set tIndex=..LoopStack.Items(tI)
					
					If ..State("lb",tIndex,"m")>1 {
						#; If is a collection then add subscripts
						Set tName=..State("lb",tIndex,"n")_"().",tPlaceHolder=",*,"
					} else {
						Set tName=..State("lb",tIndex,"n")_".",tPlaceHolder=","
					}
					Set tLocation=tLocation_tName,tCollation=tCollation_$$$NUM(..State("lb",tIndex,"c"),5)_tPlaceHolder
				}
				#; Update the MAP
				Set tLocation=tLocation_..State(tType,tStructIndex,"n")_"-"_..State(tType,tStructIndex,"o")
				If ..State(tType,tStructIndex,"m")>1 {
					Set $$$vaSchemaGbl(pDocTypeCategory,pDocTypeName,"map",tLocation)=">"_tCollation_$$$NUM(tCollateIndex,5)_",*|"_..State(tType,tStructIndex,"n")_"-"_..State(tType,tStructIndex,"o")
				} else {
					Set $$$vaSchemaGbl(pDocTypeCategory,pDocTypeName,"map",tLocation)=">"_tCollation_$$$NUM(tCollateIndex,5)_"|"_..State(tType,tStructIndex,"n")_"-"_..State(tType,tStructIndex,"o")
				}
			}
		}
	} while (0)
	
	Quit tSC
}

/// Given structure index, structure type and structure, intialize state
Method InitState(pIndex As %Integer, pType As %String, pStructure As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set ..State(pType,pIndex,"c")=0
		Set ..State(pType,pIndex,"n")=$Piece(pStructure,"|",2)
			
		 #; Initialize the counts,requirements and repeats
		 If pType="s" {
			Set ..State(pType,pIndex,"o")=$Piece(pStructure,"|",3)
			Set ..State(pType,pIndex,"r")=$Piece(pStructure,"|",7)
			Set ..State(pType,pIndex,"m")=$Case($Piece(pStructure,"|",8),">1":999999,:$Piece(pStructure,"|",8))
			Set ..State(pType,pIndex,"h")=$Piece(pStructure,"|",9)
		} elseif pType="lb" {
			Set ..State(pType,pIndex,"r")=$Piece(pStructure,"|",4)
			Set ..State(pType,pIndex,"m")=$Case($Piece(pStructure,"|",5),">1":999999,:$Piece(pStructure,"|",5))
		} else {
			Set ..State(pType,pIndex,"r")=""
			Set ..State(pType,pIndex,"m")=""
		}

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Given a element/composite description, generate an short-form name
ClassMethod CreateShortName(pDesc As %String) As %String
{
	Set:pDesc["Reference Identification" pDesc=$P(pDesc,"Reference Identification")_"RefId"_$P(pDesc,"Reference Identification",2) ; These names are not unique in the first 31-3 characters
	Set tName=$e($tr(pDesc," |/-'_?&.()+#*,':;<>[]"""_$c(146,147,148,150,180)),1,31-3)
	$$$ASSERTNOLOG(""'=tName)
	Quit tName
}

}
