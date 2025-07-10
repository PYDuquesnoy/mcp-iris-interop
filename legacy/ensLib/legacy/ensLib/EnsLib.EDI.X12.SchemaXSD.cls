/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.SchemaXSD Extends %XML.SAX.ContentHandler [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// slot for remembering categories encountered in schema xml file
Property lastFileCategory As %String;

/// slot for remembering forced category name
Property forceCategory As %String;

/// Error encountered inside xml import handler
Property Error As %Status [ InitialExpression = {$$$OK} ];

/// Filename for use in constructing xml handler error messages
Property Filename As %String;

Property ForceOld As %Boolean [ InitialExpression = 0 ];

/// Array for disambiguation of names for fields w/in a segment
Property %propNames As %String [ MultiDimensional ];

/// Array for disambiguation of names for components w/in a field
Property %compNames As %String [ MultiDimensional ];

Property inSequence As %Boolean [ InitialExpression = 0 ];

Property inDoc As %Boolean [ InitialExpression = 0 ];

Property TriggerSegs As array Of %String;

Property FieldData As array Of %String;

Property CompData As array Of %String;

Property CTValue As %String;

Property category;

Property ImplGuide As %String;

Property elementtype;

Property elementname;

Property position As %Integer;

Property compPosition As %Integer;

Property EnsLibRO As %Boolean [ InitialExpression = {..IsEnsLibRO()}, Private, ReadOnly ];

Method IsEnsLibRO() As %Boolean
{
	#dim tStartNamespace As %String = $namespace
	#dim tRO As %Boolean = 1
	
	Try {
		Set $namespace = "%SYS"
		Set tSC = ##class(Config.Databases).Get("ENSLIB",.tProps)	Quit:$$$ISERR(tSC)
		Set tDir = tProps("Directory")	Quit:""=tDir
		Set tDBObj = ##class(SYS.Database).%OpenId(tDir)	Quit:'$IsObject(tDBObj)
		Set tRO = tDBObj.ReadOnly 
	} Catch {}
	Set $namespace = tStartNamespace
	Quit tRO
}

ClassMethod Import(pFile As %String, pForceCategory As %String = "", pForceOld As %Boolean = 0, Output pCategoryImported As %String) As %Status
{
	Set handler=..%New()
	Set handler.forceCategory=$G(pForceCategory)
	Set handler.ForceOld = ''pForceOld
	Set pCategoryImported=""
	If '$IsObject(pFile) {
		Set handler.Filename=pFile
		Quit:'##class(%File).Exists(pFile) $$$ERROR($$$FileDoesNotExist,pFile)
		Set sc=##class(%XML.SAX.Parser).ParseFile(pFile,handler)  quit:$$$ISERR(sc) sc
	} Else {
		Set handler.Filename=$S(""'=pForceCategory:pForceCategory_".X12", ""'=$G(pCategoryImported):pCategoryImported_".X12", 1:pFile)
		Set sc=##class(%XML.SAX.Parser).ParseStream(pFile,handler)  quit:$$$ISERR(sc) sc
	}
	Set pCategoryImported=handler.lastFileCategory
	Quit handler.Error
}

Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List) [ Internal ]
{
	For i=0:1:$LL(attrs)\5-1 set attribs($li(attrs,i*5+2))=$li(attrs,i*5+5)
	If localname="schema" {
		Kill $$$XSDSchemaImportPPG
		Kill $$$XSDDescImportPPG
		Set ..elementtype = "category"
		Set nsp=$G(attribs("targetNamespace"))
		If ($E(nsp,1,7)="http://") || ($E(nsp,1,8)="https://") {
			Set tCat = $Replace($P(nsp,"/",*-2,*),"/"," ")
			Set tName = ""
		} Else {
			Set tCat = $Replace($P(nsp,":",4,6),":"," ")
			Set tName = ..AddSpacesToCamelCase($P(nsp,":",7))
		}
		Set ..category=$S(""'=..forceCategory:..forceCategory, 1:$Replace(tCat," ","_"))
		Set ..ImplGuide = ""
		Set tVersion = $G(attribs("version"))
		Set $$$XSDSchemaImportPPG = "X|"_tVersion_"|"_tCat_"|"_tName_"|X12"
	} Elseif localname = "element" {
		Set tName = $G(attribs("name"))
		If $P(tName,"_")="X12" {
			#; DocType
			If (..MatchesMainDocType(tName) && (""=..forceCategory)) {
				Set tCat = $ZCVT($P(tName,"_",2),"U")
				Set tMainDocType = $P($P($$$XSDSchemaImportPPG,"|",3)," ",*)
				If +tMainDocType'=0 {
					Set tRevision = $P(tMainDocType,+tMainDocType,2,*)
					Set tMainDocType = +tMainDocType
				} Else {
					Set tRevision = ""
				}
				Set ..ImplGuide = "X"_+$P(tCat,"X",2)_tRevision
				Set:(""=..forceCategory) ..category = tMainDocType_"_"_$P(tCat,"X")_"X"_+$P(tCat,"X",2)_tRevision
			} Elseif ..category="" {
				Set ..category = tName
			}
			Set ..elementtype = "DS"
			Set ..elementname = tName
			Set ..position = 0
			Set ..inSequence = 0
		} Elseif $P(tName,"_")="Loop" {
			Set ..elementtype = "Loop"
			Set ..elementname = tName
			Set ..position = 0
		} Elseif ""=tName {
			If $Case(..elementtype,"DS":1,"Loop":1,:0) {
				Set tSegOrLoop = $G(attribs("ref"))
				Set ..position = ..position + 1
				Set tRepCount = $G(attribs("maxOccurs"),1)
				Set $$$XSDSchemaImportPPG("m",tSegOrLoop,"RepCount")=$Select(tRepCount'=+tRepCount:">1",1:tRepCount)
				Set $$$XSDSchemaImportPPG("array",..elementname,..position,"type")="SS:"_..category_"::"_tSegOrLoop
				Set $$$XSDSchemaImportPPG("array",..elementname,..position,"name") = tSegOrLoop
				Set:+$G(attribs("minOccurs"),1)=0 $$$XSDSchemaImportPPG("array",..elementname,..position,"opt")=1 // optional
			}
		} Else {
			If ..elementtype = "" {
				Set ..elementtype = "SS"
				Set ..elementname = tName
				Set ..position = 0
				Kill ..%propNames
			} Elseif ..elementtype = "SS" {
				Set tSeg = $P(..elementname,"_")
				Set ..position = +$E($P(tName,"_"),$L(tSeg)+1,*)
				Set ..elementtype = "Field"
				Set tDesc = $P($Replace(tName,"__","_"),"_",2)
				Do ..FieldData.Clear()
				Do ..FieldData.SetAt(tDesc,"Name")
				Do ..FieldData.SetAt(+$G(attribs("maxOccurs"),1),"RepCount")
				Set tRequired = $S($G(attribs("minOccurs"),1)=0:"O",1:"M")
				Do ..FieldData.SetAt(tRequired,"Required")
				Do ..FieldData.SetAt(tRequired,"StdReq")
				Do ..FieldData.SetAt(1,"MinLength") // in case not explicitly set later
			} Elseif ..elementtype = "CS" {
				Set ..compPosition = +$P(tName,"_",2)
				Set tDesc = $P(tName,"_",3)
				Do ..CompData.Clear()
				Do ..CompData.SetAt(tDesc,"Name")
				Do ..CompData.SetAt(+$G(attribs("maxOccurs"),1),"RepCount")
				Set tRequired = $S($G(attribs("minOccurs"),1)=0:"O",1:"M")
				Do ..CompData.SetAt(tRequired,"Required")
				Do ..CompData.SetAt(tRequired,"StdReq")
				Do ..CompData.SetAt(1,"MinLength") // in case not explicitly set later
			}
		}
	} Elseif localname="sequence" {
		Set ..inSequence = 1
	} Elseif localname="documentation" {
		Set ..inDoc = 1
	} Elseif localname = "complexType" {
		If ..elementtype = "Field" {
			Set tDesc = ..FieldData.GetAt("Name")
			Set tCompName = ..ComponentLookup(tDesc)
			Do ..FieldData.SetAt(tCompName,"DataType")
			Set ..elementtype = "CS"
			Kill ..%compNames
		}
	} Elseif localname = "STD_Info" {
		If ..elementtype = "Field" {
			Set tNum = $G(attribs("Number"))
			Set:0=tNum tNum = ""
			Do ..FieldData.SetAt(tNum,"Number")
			If (""'=tNum) {
				If $D($$$vaVSchemaDescGbl("X","X12","ELEM",tNum),tDesc) {
					Do ..FieldData.SetAt(tDesc,"Name")
				} Else {
					Set tDesc = $zstrip($G(attribs("Name")),"<>WC")
					If ""=tDesc {
						Do:(""=..FieldData.GetAt("Name")) ..FieldData.SetAt("item"_tNum,"Name")
					} Else {
						Do ..FieldData.SetAt(tDesc,"Name")
						Set:'..EnsLibRO $$$XSDDescImportPPG("X","X12","ELEM",tNum) = ..AddSpacesToCamelCase(tDesc)
					}
				}
			} Else {
				Set tDesc = $zstrip($G(attribs("Name")),"<>WC")
				Do:""'=tDesc ..FieldData.SetAt(tDesc,"Name")
			}
			Set tDataType = $zstrip($G(attribs("DataType")),"<>W")
			Set:""'=tDataType tDataType = "("_tDataType_")"
			Do ..FieldData.SetAt(tDataType,"DataType")
			If $G(attribs("MaximumLength"))'="" {
				Do ..FieldData.SetAt(+attribs("MaximumLength"),"MaxLength")
			}
		} Elseif ..elementtype = "CS" {
			Set tNum = $G(attribs("Number"))
			Set:0=tNum tNum = ""
			Do ..CompData.SetAt(tNum,"Number")
			If (""'=tNum) {
				If $D($$$vaVSchemaDescGbl("X","X12","ELEM",tNum),tDesc) {
					Do ..CompData.SetAt(tDesc,"Name")
				} Else {
					Set tDesc = $zstrip($G(attribs("Name")),"<>WC")
					If ""=tDesc {
						Do:(""=..CompData.GetAt("Name")) ..CompData.SetAt("item"_tNum,"Name")
					} Else {
						Do ..CompData.SetAt(tDesc,"Name")
						Set:'..EnsLibRO $$$XSDDescImportPPG("X","X12","ELEM",tNum) = ..AddSpacesToCamelCase(tDesc)
					}
				}
			} Else {
				Set tDesc = $zstrip($G(attribs("Name")),"<>WC")
				Do:""'=tDesc ..CompData.SetAt(tDesc,"Name")
			}
			Set tDataType = $zstrip($G(attribs("DataType")),"<>W")
			Set:""'=tDataType tDataType = "("_tDataType_")"
			Do ..CompData.SetAt(tDataType,"DataType")
			If $G(attribs("MaximumLength"))'="" {
				Do ..CompData.SetAt(+attribs("MaximumLength"),"MaxLength")
			}
		}
	} Elseif localname = "TR3_Info" {
		If $G(attribs("Used"))="No" {
			If ..elementtype = "Field" {
				Do ..FieldData.SetAt(".","Required")
			} ElseIf ..elementtype = "CS" {
				Do ..CompData.SetAt(".","Required")
			}
		}

	} Elseif localname = "minLength" {
		If ..elementtype = "Field" {
			Do ..FieldData.SetAt(+$G(attribs("value")),"MinLength")
		} ElseIf ..elementtype = "CS" {
			Do ..CompData.SetAt(+$G(attribs("value")),"MinLength")
		}
	} Elseif localname = "maxLength" {
		If ..elementtype = "Field" {
			If ..FieldData.GetAt("MaxLength")="" {
				Do ..FieldData.SetAt(+$G(attribs("value")),"MaxLength")
			}
		} ElseIf ..elementtype = "CS" {
			If ..CompData.GetAt("MaxLength")="" {
				Do ..CompData.SetAt(+$G(attribs("value")),"MaxLength")
			}
		}
	} Elseif localname = "enumeration" {
		Set ..CTValue = $G(attribs("value"))
		If ..elementtype = "Field" {
			Set tNum = ..FieldData.GetAt("Number")
			Set $$$XSDSchemaImportPPG("c",tNum,"e",..elementname,..position,..CTValue)=""
			If $Case(tNum,98:1,735:1,:(..position=1)) {
				Set tTriggerName = ..TriggerSegs.GetAt(..elementname)
				If ((tTriggerName'="") && ($P($P(tTriggerName,"!",2),"=")=..position)) {
					Set tTriggerName = tTriggerName_"="_..CTValue
				} Else {
					Set tTriggerName = $P(..elementname,"_")_"!"_..position_"="_..CTValue
				}
				Do ..TriggerSegs.SetAt(tTriggerName,..elementname)
			}
		} Elseif ..elementtype = "CS" {
			Set tNum = ..CompData.GetAt("Number")
			Set $$$XSDSchemaImportPPG("c",tNum,"c",..elementname,..position,..compPosition,..CTValue)=""
			If ((..position=1) && (..compPosition=1)) {
				Set tTriggerName = ..TriggerSegs.GetAt(..elementname)
				If ((tTriggerName'="") && ($P($P(tTriggerName,"!",2),"=")="1.1")) {
					Set tTriggerName = tTriggerName_"="_..CTValue
				} Else {
					Set tTriggerName = $P(..elementname,"_")_"!1.1="_..CTValue
				}
				Do ..TriggerSegs.SetAt(tTriggerName,..elementname)
			}
		}
	}
	quit
}

Method MatchesMainDocType(pDocType As %String) As %Boolean [ Internal ]
{
	#dim tMatches As %Boolean = 0
	#dim tMainDocType = $P($P($$$XSDSchemaImportPPG,"|",3)," ",*)
	#dim tDocType = $P(pDocType,"_",*)
	If 0'=+tMainDocType {
		Set tMatches = (+tMainDocType = +tDocType)
	} Else {
		Set tMatches = (tMainDocType = tDocType)
	}
	Quit tMatches
}

Method AddSpacesToCamelCase(pDesc As %String) As %String [ Internal ]
{
	#dim tResult,tChar As %String = ""
	#dim i As %Integer
	Set pDesc = $zstrip(pDesc,"<>WC")
	
	If (pDesc'[" ")&&($zcvt(pDesc,"l")'=pDesc) {
		For i=1:1:$L(pDesc) {
			Set tChar = $E(pDesc,i)
			If (tChar ? 1U) && (tResult'="") {
				Set tResult = tResult_" "_tChar
			} Else {
				Set tResult = tResult_tChar
			}
		}
	} Else {
		Set tResult = pDesc
	}
	Quit tResult
}

Method ComponentLookup(pDesc As %String) As %String [ Internal ]
{
	#dim tName As %String = pDesc
	#dim tFullDesc = ..AddSpacesToCamelCase(pDesc)
	#dim tComp,tCompDesc As %String = ""
	For {
		Set tComp = $O($$$vaVSchemaDescGbl("X","X12","COMP",tComp),1,tCompDesc)	Quit:""=tComp
		If $zcvt(tCompDesc,"L")=$zcvt(tFullDesc,"L") {
			Set tName = tComp
			Quit
		}
	}
	Quit tName
}

Method characters(chars As %Library.String, length As %Library.Integer) [ Internal ]
{
	If ..inDoc {
		Set tValue = $zstrip($E(chars,1,length),"<>WC")
		If ..elementtype = "category" {
			Set:""=$G($$$XSDDescImportPPG) $$$XSDDescImportPPG = $Select(tValue["-":$zstrip($P(tValue,"-",*),"<>WC"),1:tValue)
		} ElseIf ..elementtype = "DS" {
			Set $$$XSDDescImportPPG(..elementname)=tValue
		} ElseIf ..elementtype = "SS" {
			Set:'..EnsLibRO&&'$D($$$vaVSchemaDescGbl("X","X12","SEG",$P(..elementname,"_"))) $$$XSDDescImportPPG("X","X12","SEG",$P(..elementname,"_"))=tValue
		} ElseIf ..elementtype = "Field" {
			If ..CTValue '= "" {
				Set:'..EnsLibRO&&'$D($$$vaVSchemaDescGbl("X","X12","CODES",..FieldData.GetAt("Number"),..CTValue)) $$$XSDDescImportPPG("X","X12","CODES",..FieldData.GetAt("Number"),..CTValue) = tValue
			} Else {
				Set $$$XSDDescImportPPG("SS",$P(..elementname,"_"),..position,"alt") = tValue
			}
		} ElseIf ..elementtype = "CS" {
			If ..CTValue '= "" {
				Set:'..EnsLibRO&&'$D($$$vaVSchemaDescGbl("X","X12","CODES",..CompData.GetAt("Number"),..CTValue)) $$$XSDDescImportPPG("X","X12","CODES",..CompData.GetAt("Number"),..CTValue) = tValue
			} Else {
				Set $$$XSDDescImportPPG("CS",..FieldData.GetAt("DataType"),..compPosition,"alt") = tValue
			}
		}
	}
}

ClassMethod fieldDescToName(desc, elem, piece) As %String [ Internal ]
{
	Quit ##class(EnsLib.EDI.SEF.Compiler).CreateShortName(desc) ;$ZStrip($ZCVT($TR(desc,"/'"_$C(8217)," "),"W"),"*P")
}

ClassMethod compositeDescToName(desc, elem, piece) As %String [ Internal ]
{
	Quit ##class(EnsLib.EDI.SEF.Compiler).CreateShortName(desc) ; $ZStrip($ZCVT($TR(desc,"/'"_$C(8217)," "),"W"),"*P")
}

Method BuildArrayForLoop(pLoopName As %String, pDocType As %String, ByRef pOrdinal As %Integer = 0, ByRef pSegsRef, ByRef pArray, ByRef mCount As %Integer, ByRef pTable As %Integer) [ Internal ]
{
	Set tCount = $$$XSDSchemaImportPPG("array",pLoopName)
	Set:(tCount>0) pArray = tCount
	Set tPrevName = ""
	For i=1:1:tCount {
		Set tFullName = $$$XSDSchemaImportPPG("array",pLoopName,i,"name")
		Set tRepCount = $$$XSDSchemaImportPPG("m",tFullName,"RepCount")
		Set tRepeating = $Case(tRepCount,0:0,1:0,:1)
		If $Case($ZCVT($P(tFullName,"_"),"L"),"loop":1,"x12":1,:0) {
			If (i>2) {
				If ($P(tPrevName,"_")'="loop") {
					Set tPrevName = pArray(i-1,"name")
					If ((tPrevName["!") && ($P(tPrevName,"!")'="HL")) {
						Set tPrevName = $P(tPrevName,"!")_"-"_$P(tPrevName,"-",2)
						Set pArray(i-1,"name") = tPrevName
						Set $P(pArray(i-1,"type"),":",*) = tPrevName
						Set tMCount = $$$vaVSchemaGbl(..category,pDocType,"o",$P($P(tPrevName,"-",2),"("))
						Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount),"|",1,*-1)

					}
				} ElseIf +$P(tPrevName,"_",2) '= +$P(tFullName,"_",2) {
					Set tPrevName = $G(pArray(i-1,1,"name"))
					If (tPrevName["!") && ($P(tPrevName,"!")'="HL") {
						Set tPrevName = $P(tPrevName,"!")_"-"_$P(tPrevName,"-",2)
						Set pArray(i-1,1,"name") = tPrevName
						Set $P(pArray(i-1,1,"type"),":",*) = tPrevName
						Set tMCount = $$$vaVSchemaGbl(..category,pDocType,"o",$P($P(tPrevName,"-",2),"("))
						Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount),"|",1,*-1)
					}
				}
			}
			Kill tSubArray
			Set tName = $P(tFullName,"_",2)
			If $ZCVT($P(tFullName,"_"),"L")= "x12" {
				If $Case($ZCVT(tName,"L"),"group":1,"functionalgroup":1,"transactionset":1,:0) {
					#; Add DocsRef segment instead
					If $ZCVT(tName,"L")="transactionset" {
						Set tName = "TransactionSetDocsRef-"_$I(pOrdinal)
					} Else {
						Set tName = "GroupDocsRef-"_$I(pOrdinal)
					}
					Set pArray(i,"name")= tName
					Set pArray(i,"type")="SS:"_..category_":"_pDocType_":"_tName
					Set pArray(i,"opt")=1
					Set tM = "s|"_$P(tName,"-")_"|"_pOrdinal_"|N/A||O|O|1"
					Set $$$vaVSchemaGbl(..category,pDocType,"m",$I(mCount))=tM
					Set $$$vaVSchemaGbl(..category,pDocType,"o",pOrdinal)=mCount
					Set $$$vaVSchemaGbl(..category,pDocType,"o",pOrdinal,1)="E|"_$E(tName)_"01|M|N0|1|3|1|SegIndex|M"
					Set $$$vaVSchemaGbl(..category,pDocType,"o",pOrdinal,2)="E|"_$E(tName)_"02|M|N0|1|3|1|ChildCount|M"
					Set $$$vaVSchemaGbl(..category,pDocType,"n",pOrdinal,"SegIndex")=1
					Set $$$vaVSchemaGbl(..category,pDocType,"n",pOrdinal,"ChildCount")=2
					Set pSegsRef(tFullName) = $S($D(pSegsRef(tFullName),tCurrVal):tCurrVal_",",1:"")_pDocType_":"_pOrdinal
					Continue
				}
				Set $$$vaVSchemaGbl(..category,pDocType,"m",$I(mCount))="t|"_$I(tTable)
			}
			Set tM = "lb|"_tName_"||"_$S($G($$$XSDSchemaImportPPG("array",pLoopName,i,"opt")):"O|",1:"M|")_tRepCount_"|"
			Set tMCount = $I(mCount)
			Do ..BuildArrayForLoop(tFullName,pDocType,.pOrdinal,.pSegsRef,.tSubArray,.mCount)
			If (i=tCount) {
				Set tSeg = $G(tSubArray(1,"name"))
				If (tSeg["!") && ($P(tSeg,"!")'="HL") {
					Set tSeg = $P(tSeg,"!")_"-"_$P(tSeg,"-",2)
					Set tSubArray(1,"name") = tSeg
					Set $P(tSubArray(1,"type"),":",*) = tSeg
					Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount+1) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount+1),"|",1,*-1)
				}
			}
			Set tM = tM_"|"_$P($P($G(tSubArray(1,"name")),"-"),"!")_"|"_($I(mCount)+1)
			Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = tM
			Set $$$vaVSchemaGbl(..category,pDocType,"m",mCount)="le|"_tName_"|"_tMCount
			Merge pArray(i)=tSubArray
			Set pArray(i,"name") = tName_$S(tRepeating:"()",1:"")
			Set pArray(i,"type")="SS:"_..category_":"_pDocType_":"_$Replace(tFullName,"_","-")_$S(tRepeating:"()",1:"")
			Set:$G($$$XSDSchemaImportPPG("array",pLoopName,i,"opt")) pArray(i,"opt")=1
			Set tPrevName = $zcvt(tFullName,"L")
		} Else {
			If (i>2) && (tPrevName'=$P(tFullName,"_")) {
				If ($P(tPrevName,"_")'="loop") {
					Set tPrevName = pArray(i-1,"name")
					If tPrevName["!" {
						Set tPrevName = $P($P(tPrevName,"!"),"-")_"-"_$P(tPrevName,"-",2)
						Set pArray(i-1,"name") = tPrevName
						Set $P(pArray(i-1,"type"),":",*) = tPrevName
						Set $$$vaVSchemaGbl(..category,pDocType,"m",mCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",mCount),"|",1,*-1)
					}
				} Else {
					Set tPrevName = $G(pArray(i-1,1,"name"))
					If (tPrevName["!") && ($P(tPrevName,"!")'="HL") {
						Set tOrdinal = $P(tPrevName,"-",2)
						Set tPrevName = $P(tPrevName,"!")_"-"_tOrdinal
						Set pArray(i-1,1,"name") = tPrevName
						Set $P(pArray(i-1,1,"type"),":",*) = tPrevName
						Set tMCount = $$$vaVSchemaGbl(..category,pDocType,"o",$P(tOrdinal,"("))
						Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount),"|",1,*-1)
					}
				}
			}
			Set tTriggerSeg = $Select((i<tCount) || (tCount=1):..TriggerSegs.GetAt(tFullName),1:"")
			Set tName = $S(""'=tTriggerSeg:tTriggerSeg,1:$P(tFullName,"_"))_"-"_$I(pOrdinal)_$S(tRepeating:"()",1:"")
			Set pArray(i,"name")= tName
			Set pArray(i,"type")="SS:"_..category_":"_pDocType_":"_tName
			Set:$G($$$XSDSchemaImportPPG("array",pLoopName,i,"opt")) pArray(i,"opt")=1
			Set pSegsRef(tFullName) = $S($D(pSegsRef(tFullName),tCurrVal):tCurrVal_",",1:"")_pDocType_":"_pOrdinal
			Set tM = "s|"_$P($P(tName,"-"),"!")_"|"_pOrdinal_"|N/A||"_$S($G($$$XSDSchemaImportPPG("array",pLoopName,i,"opt")):"O|O|",1:"M|M|")_tRepCount
			Set:""'=tTriggerSeg tM = tM_"|"_$P(tTriggerSeg,"=",*)
			Set $$$vaVSchemaGbl(..category,pDocType,"m",$I(mCount))=tM
			Set $$$vaVSchemaGbl(..category,pDocType,"o",pOrdinal)=mCount
			Set tPrevName = $P(tFullName,"_")
		}
	}
}

Method ConstructArrayForDocType(pFullDocType As %String, pDocType As %String, ByRef pSegsRef) [ Internal ]
{
	#dim tOrdinal,mCount,tTable As %Integer = 0
	#dim tCount As %Integer = +$G($$$XSDSchemaImportPPG("array",pFullDocType))
	#dim tFullName,tM,tTriggerSeg,tName,tPrevName As %String = ""
	#dim tRepCount,tMCount As %Integer
	#dim tRepeating As %Boolean

	Set $$$vaVSchemaGbl(..category,pDocType,"m",$I(mCount))="t|"_$I(tTable)
	Set $$$vaVSchemaGbl(..category,pDocType,"array")=tCount
	For i=1:1:tCount {
		Set tFullName = $G($$$XSDSchemaImportPPG("array",pFullDocType,i,"name"))
		Set tRepCount = $G($$$XSDSchemaImportPPG("m",tFullName,"RepCount"))
		Set tRepeating = $Case(tRepCount,0:0,1:0,:1)
		If $Case($ZCVT($P(tFullName,"_"),"L"),"loop":1,"x12":1,:0) {
			#; Remove indicators for triggers segments if last item wasn't a loop of this same name
			If (i>1) {
				If ($P(tPrevName,"_")'="loop") {
					Set tPrevName = $$$vaVSchemaGbl(..category,pDocType,"array",i-1,"name")
					If ((tPrevName["!") && ($P(tPrevName,"!")'="HL")) {
						Set tPrevName = $P(tPrevName,"!")_"-"_$P(tPrevName,"-",2)
						Set $$$vaVSchemaGbl(..category,pDocType,"array",i-1,"name") = tPrevName
						Set $P($$$vaVSchemaGbl(..category,pDocType,"array",i-1,"type"),":",*) = tPrevName
						Set tMCount = $$$vaVSchemaGbl(..category,pDocType,"o",$P($P(tPrevName,"-",2),"("))
						Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount),"|",1,*-1)
					}
				} ElseIf +$P(tPrevName,"_",2) '= +$P(tFullName,"_",2) {
					Set tPrevName = $G($$$vaVSchemaGbl(..category,pDocType,"array",i-1,1,"name"))
					If (tPrevName["!") && ($P(tPrevName,"!")'="HL") {
						Set tPrevName = $P(tPrevName,"!")_"-"_$P(tPrevName,"-",2)
						Set $$$vaVSchemaGbl(..category,pDocType,"array",i-1,1,"name") = tPrevName
						Set $P($$$vaVSchemaGbl(..category,pDocType,"array",i-1,1,"type"),":",*) = tPrevName
						Set tMCount = $$$vaVSchemaGbl(..category,pDocType,"o",$P($P(tPrevName,"-",2),"("))
						Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount),"|",1,*-1)
					}
				}
			}
			Kill tSubArray
			Set tName = $P(tFullName,"_",2)
			If $ZCVT($P(tFullName,"_"),"L")= "x12" {
				If $Case($ZCVT(tName,"L"),"group":1,"functionalgroup":1,"transactionset":1,:0) {
					#; Add DocsRef segment instead
					If $ZCVT(tName,"L")="transactionset" {
						Set tName = "TransactionSetDocsRef-"_$I(tOrdinal)
					} Else {
						Set tName = "GroupDocsRef-"_$I(tOrdinal)
					}
					Set $$$vaVSchemaGbl(..category,pDocType,"array",i,"name")= tName
					Set $$$vaVSchemaGbl(..category,pDocType,"array",i,"type")="SS:"_..category_":"_pDocType_":"_tName
					Set $$$vaVSchemaGbl(..category,pDocType,"array",i,"opt")=1
					Set tM = "s|"_$P(tName,"-")_"|"_tOrdinal_"|N/A||O|O|1"
					Set $$$vaVSchemaGbl(..category,pDocType,"m",$I(mCount))=tM
					Set $$$vaVSchemaGbl(..category,pDocType,"o",tOrdinal)=mCount
					Set $$$vaVSchemaGbl(..category,pDocType,"o",tOrdinal,1)="E|"_$E(tName)_"01|M|N0|1|3|1|SegIndex|M"
					Set $$$vaVSchemaGbl(..category,pDocType,"o",tOrdinal,2)="E|"_$E(tName)_"02|M|N0|1|3|1|ChildCount|M"
					Set $$$vaVSchemaGbl(..category,pDocType,"n",tOrdinal,"SegIndex")=1
					Set $$$vaVSchemaGbl(..category,pDocType,"n",tOrdinal,"ChildCount")=2
					Set pSegsRef(tFullName) = $S($D(pSegsRef(tFullName),tCurrVal):tCurrVal_",",1:"")_pDocType_":"_tOrdinal
					Continue
				}
				Set $$$vaVSchemaGbl(..category,pDocType,"m",$I(mCount))="t|"_$I(tTable)
			}
			Set tM = "lb|"_tName_"||"_$S($G($$$XSDSchemaImportPPG("array",pFullDocType,i,"opt")):"O|",1:"M|")_tRepCount_"|"
			Set tMCount = $I(mCount)
			Do ..BuildArrayForLoop(tFullName,pDocType,.tOrdinal,.pSegsRef,.tSubArray,.mCount,.tTable)
			#; If this is the last loop at this level, then no trigger segment is needed for it
			If (i=tCount) {
				Set tSeg = $G(tSubArray(1,"name"))
				If (tSeg["!") && ($P(tSeg,"!")'="HL") {
					Set tSeg = $P(tSeg,"!")_"-"_$P(tSeg,"-",2)
					Set tSubArray(1,"name") = tSeg
					Set $P(tSubArray(1,"type"),":",*) = tSeg
					Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount+1) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount+1),"|",1,*-1)
				}
			}
			Set tM = tM_"|"_$P($P($G(tSubArray(1,"name")),"-"),"!")_"|"_($I(mCount)+1)
			Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = tM
			Set $$$vaVSchemaGbl(..category,pDocType,"m",mCount)="le|"_tName_"|"_tMCount
			Merge $$$vaVSchemaGbl(..category,pDocType,"array",i)=tSubArray
			Set $$$vaVSchemaGbl(..category,pDocType,"array",i,"name") = tName_$S(tRepeating:"()",1:"")
			Set $$$vaVSchemaGbl(..category,pDocType,"array",i,"type")="SS:"_..category_":"_pDocType_":"_$Replace(tFullName,"_","-")_$S(tRepeating:"()",1:"")
			Set:$G($$$XSDSchemaImportPPG("array",pFullDocType,i,"opt")) $$$vaVSchemaGbl(..category,pDocType,"array",i,"opt")=1
			Set tPrevName = $zcvt(tFullName,"L")
		} Else {
			If (i>2) && (tPrevName'=$P(tFullName,"_")) {
				If ($P(tPrevName,"_")'="loop") {
					Set tPrevName = $$$vaVSchemaGbl(..category,pDocType,"array",i-1,"name")
					If tPrevName["!" {
						Set tPrevName = $P(tPrevName,"!")_"-"_$P(tPrevName,"-",2)
						Set $$$vaVSchemaGbl(..category,pDocType,"array",i-1,"name") = tPrevName
						Set $P($$$vaVSchemaGbl(..category,pDocType,"array",i-1,"type"),":",*) = tPrevName
						Set $$$vaVSchemaGbl(..category,pDocType,"m",mCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",mCount),"|",1,*-1)
					}
				} Else {
					Set tPrevName = $G($$$vaVSchemaGbl(..category,pDocType,"array",i-1,1,"name"))
					If (tPrevName["!") && ($P(tPrevName,"!")'="HL") {
						Set tPrevName = $P(tPrevName,"!")_"-"_$P(tPrevName,"-",2)
						Set $$$vaVSchemaGbl(..category,pDocType,"array",i-1,1,"name") = tPrevName
						Set $P($$$vaVSchemaGbl(..category,pDocType,"array",i-1,1,"type"),":",*) = tPrevName 
						Set tMCount = $$$vaVSchemaGbl(..category,pDocType,"o",$P($P(tPrevName,"-",2),"("))
						Set $$$vaVSchemaGbl(..category,pDocType,"m",tMCount) = $P($$$vaVSchemaGbl(..category,pDocType,"m",tMCount),"|",1,*-1)
					}
				}
			}
			Set tTriggerSeg = $Select((i>1) && (i<tCount):..TriggerSegs.GetAt(tFullName),1:"")
			Set tName = $S(""'=tTriggerSeg:tTriggerSeg,1:$P(tFullName,"_"))_"-"_$I(tOrdinal)_$S(tRepeating:"()",1:"")
			Set $$$vaVSchemaGbl(..category,pDocType,"array",i,"name")= tName
			Set $$$vaVSchemaGbl(..category,pDocType,"array",i,"type")="SS:"_..category_":"_pDocType_":"_tName
			Set:$G($$$XSDSchemaImportPPG("array",pFullDocType,i,"opt")) $$$vaVSchemaGbl(..category,pDocType,"array",i,"opt")=1
			#; Keep track of which ordinals correspond with which full names
			Set pSegsRef(tFullName) = $S($D(pSegsRef(tFullName),tCurrVal):tCurrVal_",",1:"")_pDocType_":"_tOrdinal
			Set tM = "s|"_$P($P(tName,"-"),"!")_"|"_tOrdinal_"|N/A||"_$S($G($$$XSDSchemaImportPPG("array",pFullDocType,i,"opt")):"O|O|",1:"M|M|")_tRepCount
			Set:""'=tTriggerSeg tM = tM_"|"_$P(tTriggerSeg,"=",*)
			Set $$$vaVSchemaGbl(..category,pDocType,"m",$I(mCount))=tM
			Set $$$vaVSchemaGbl(..category,pDocType,"o",tOrdinal)=mCount
			Set tPrevName = $P(tFullName,"_")
		}	
	}
}

Method AddFunctionalGroup() [ Internal ]
{
	Set tArray = ""
	Set tArray("m",1) = "t|1"
	Set tArray("array") = 3
	
	#; Add GS segment
	Set tArray("array",1,"name") = "GS-1"
	Set tArray("array",1,"type")="SS:"_..category_":FunctionalGroup:GS-1"
	Set tArray("m",2)="s|GS|1|N/A||M|M|1"
	Set tArray("o",1)=2
	Set tArray("o",1,1)="E|479|M|ID|2|2|1|FunctionalIdentifierCode|M"
	Set tArray("o",1,2)="E|142|M|AN|2|15|1|ApplicationSendersCode|M"
	Set tArray("o",1,3)="E|124|M|AN|2|15|1|ApplicationReceiversCode|M"
	Set tArray("o",1,4)="E|373|M|DT|8|8|1|Date|M"
	Set tArray("o",1,5)="E|337|M|TM|4|8|1|Time|M"
	Set tArray("o",1,6)="E|28|M|N0|1|9|1|GroupControlNumber|M"
	Set tArray("o",1,7)="E|455|M|ID|1|2|1|ResponsibleAgencyCode|M"
	Set tArray("o",1,8)="E|480|M|AN|1|12|1|VersionReleaseIndustryIdenti|M"
	
	Set tArray("n","FunctionalIdentifierCode")=1
	Set tArray("n","ApplicationSendersCode")=2
	Set tArray("n","ApplicationReceiversCode")=3
	Set tArray("n","Date")=4
	Set tArray("n","Time")=5
	Set tArray("n","GroupControlNumber")=6
	Set tArray("n","ResponsibleAgencyCode")=7
	Set tArray("n","VersionReleaseIndustryIdenti")=8

	#; Add DocsRef segment
	Set tArray("array",2,"name") = "TransactionSetDocsRef-2"
	Set tArray("array",2,"type")="SS:"_..category_":FunctionalGroup:TransactionSetDocsRef-2"
	Set tArray("array",2,"opt")=1
	Set tArray("m",3)="s|TransactionSetDocsRef|2|N/A||O|O|1"
	Set tArray("o",2)=3
	Set tArray("o",2,1)="E|T01|M|N0|1|3|1|SegIndex|M"
	Set tArray("o",2,2)="E|T02|M|N0|1|3|1|ChildCount|M"
	Set tArray("n",2,"SegIndex")=1
	Set tArray("n",2,"ChildCount")=2
	
	#; Add GE segment
	Set tArray("array",3,"name") = "GE-3"
	Set tArray("array",3,"type")="SS:"_..category_":FunctionalGroup:GE-3"
	Set tArray("m",4)="s|GE|3|N/A||M|M|1"
	Set tArray("o",3)=4
	Set tArray("o",3,1)="E|97|M|N0|1|6|1|NumberofTransactionSetsInclu|M"
	Set tArray("o",3,2)="E|28|M|N0|1|9|1|GroupControlNumber|M"
	Set tArray("n",3,"NumberofTransactionSetsInclu")=1
	Set tArray("n",3,"GroupControlNumber")=2
	
	Merge $$$vaVSchemaGbl(..category,"FunctionalGroup")=tArray
}

Method AddInterchange() [ Internal ]
{
	Set tArray = ""
	Set tArray("m",1) = "t|1"
	Set tArray("array") = 4
	
	#; Add ISA segment
	Set tArray("array",1,"name") = "ISA-1"
	Set tArray("array",1,"type") = "SS:"_..category_":Interchange:ISA-1"
	Set tArray("m",2)="s|ISA|1|N/A||M|M|1"
	Set tArray("o",1)=2
	Set tArray("o",1,1)="E|I01|M|ID|2|2|1|AuthorizationInformationQual|M"
	Set tArray("o",1,2)="E|I02|M|AN|10|10|1|AuthorizationInformation|M"
	Set tArray("o",1,3)="E|I03|M|ID|2|2|1|SecurityInformationQualifier|M"
	Set tArray("o",1,4)="E|I04|M|AN|10|10|1|SecurityInformation|M"
	Set tArray("o",1,5)="E|I05|M|ID|2|2|1|InterchangeIDQualifier|M"
	Set tArray("o",1,6)="E|I06|M|AN|15|15|1|InterchangeSenderID|M"
	Set tArray("o",1,7)="E|I05|M|ID|2|2|1|InterchangeIDQualifier2|M"
	Set tArray("o",1,8)="E|I07|M|AN|15|15|1|InterchangeReceiverID|M"
	Set tArray("o",1,9)="E|I08|M|DT|6|6|1|InterchangeDate|M"
	Set tArray("o",1,10)="E|I09|M|TM|4|4|1|InterchangeTime|M"
	Set tArray("o",1,11)="E|I65|M||1|1|1|RepetitionSeparator|M"
	Set tArray("o",1,12)="E|I11|M|ID|5|5|1|InterchangeControlVersionNum|M"
	Set tArray("o",1,13)="E|I12|M|N0|9|9|1|InterchangeControlNumber|M"
	Set tArray("o",1,14)="E|I13|M|ID|1|1|1|AcknowledgmentRequested|M"
	Set tArray("o",1,15)="E|I14|M|ID|1|1|1|UsageIndicator|M"
	Set tArray("o",1,16)="E|I15|M||1|1|1|ComponentElementSeparator|M"
	
	Set tArray("n","AuthorizationInformationQual")=1
	Set tArray("n","AuthorizationInformation")=2
	Set tArray("n","SecurityInformationQualifier")=3
	Set tArray("n","SecurityInformation")=4
	Set tArray("n","InterchangeIDQualifier")=5
	Set tArray("n","InterchangeSenderID")=6
	Set tArray("n","InterchangeIDQualifier2")=7
	Set tArray("n","InterchangeReceiverID")=8
	Set tArray("n","InterchangeDate")=9
	Set tArray("n","InterchangeTime")=10
	Set tArray("n","RepetitionSeparator")=11
	Set tArray("n","InterchangeControlVersionNum")=12
	Set tArray("n","InterchangeControlNumber")=13
	Set tArray("n","AcknowledgmentRequested")=14
	Set tArray("n","UsageIndicator")=15
	Set tArray("n","ComponentElementSeparator")=16
	
	#; TA1 segment
	Set tArray("array",2,"name") = "TA1-2"
	Set tArray("array",2,"type")="SS:"_..category_":Interchange:TA1-2"
	Set tArray("array",2,"opt")=1
	Set tArray("m",3)="s|TA1|2|N/A|O|O|1"
	Set tArray("o",2)=3
	Set tArray("o",2,1)="E|I12|M|N0|9|9|1|InterchangeControlNumber|M"
	Set tArray("o",2,2)="E|I08|M|DT|6|6|1|InterchangeDate|M"
	Set tArray("o",2,3)="E|I09|M|TM|4|4|1|InterchangeTime|M"
	Set tArray("o",2,4)="E|I17|M|ID|1|1|1|InterchangeAcknowledgmentCod|M"
	Set tArray("o",2,5)="E|I18|M|ID|1|3|1|InterchangeNoteCode|M"
	
	Set tArray("n","InterchangeControlNumber")=1
	Set tArray("n","InterchangeDate")=2
	Set tArray("n","InterchangeTime")=3
	Set tArray("n","InterchangeAcknowledgmentCod")=4
	Set tArray("n","InterchangeNoteCode")=5
	
	#; Add DocsRef segment
	Set tArray("array",3,"name") = "GroupDocsRef-3"
	Set tArray("array",3,"type")="SS:"_..category_":Interchange:GroupDocsRef-3"
	Set tArray("array",3,"opt")=1
	Set tArray("m",4)="s|GroupDocsRef|3|N/A||O|O|1"
	Set tArray("o",3)=4
	Set tArray("o",3,1)="E|G01|M|N0|1|3|1|SegIndex|M"
	Set tArray("o",3,2)="E|G02|M|N0|1|3|1|ChildCount|M"
	Set tArray("n",3,"SegIndex")=1
	Set tArray("n",3,"ChildCount")=2
	
	#; Add IEA segment
	Set tArray("array",4,"name") = "IEA-4"
	Set tArray("array",4,"type")="SS:"_..category_":Interchange:IEA-4"
	Set tArray("m",5)="s|IEA|4|N/A||M|M|1"
	Set tArray("o",4)=5
	Set tArray("o",4,1)="E|I16|M|N0|1|5|1|NumberofIncludedFunctionalGr|M"
	Set tArray("o",4,2)="E|I12|M|N0|9|9|1|InterchangeControlNumber|M"
	
	Merge $$$vaVSchemaGbl(..category,"Interchange")=tArray
}

Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String) [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Do {
		Try {
			If localname="schema" {
				#; First clear global for this category if previously imported
				Kill $$$vaVSchemaGbl(..category)
				Kill $$$vaVSchemaDescGbl(..category)
				
				Set tX = $$$XSDSchemaImportPPG
				Set tMainDocType = $P($P(tX,"|",3)," ",*)
				If +tMainDocType'=0 {
					Set tRevision = $P(tMainDocType,+tMainDocType,2,*)
					Set tMainDocType = +tMainDocType
				} Else {
					Set tRevision = ""
					Set tMainDocType = ""
				}
				Set $P(tX,"|",3) = $P($P(tX,"|",3)," ",1,2)_" "_$E(..ImplGuide,2,*)

				Set $$$vaVSchemaGbl(..category) = tX
				Set tCtrlVersionNum = $P(tX,"|",2)
				Set:(tCtrlVersionNum'?.N) tCtrlVersionNum=""			
				
				Set tSegsRef = ""
				Set tFullDocType = ""
				Set tSkipList = ","
				For {
					Set tFullDocType = $O($$$XSDSchemaImportPPG("array",tFullDocType),1,tCount)	Quit:tFullDocType=""
					Continue:("X12"'=$zcvt($P(tFullDocType,"_"),"U"))||(tCount < 1)||(tSkipList[(","_tFullDocType_","))
					
					Set tDocType = $P(tFullDocType,"_",*)
					Set:+tDocType'=0 tDocType = +tDocType
	
					If ..MatchesMainDocType(tFullDocType){
						Set $$$vaVSchemaGbl(..category,tDocType) = tX_"*"_..category
						Set:$D($$$XSDDescImportPPG(tFullDocType),tDesc)#2 $$$vaVSchemaGbl(..category,tDocType,"desc") = tDesc
					} Else {
						Set tDesc = $G($$$XSDDescImportPPG(tFullDocType))
						Set $$$vaVSchemaGbl(..category,tDocType) = $P(tX,"|",1,3)_"|"_tDesc_"|"_$P(tX,"|",5,*)_"*"_tDocType_$Select(tCtrlVersionNum'="":"_"_tCtrlVersionNum,1:"")
					}
					
					If (tCount = 1) && ($D($$$XSDSchemaImportPPG("array",tFullDocType,1,"name"),tFullNameToUse)#2) && ("X12"=$zcvt($P(tFullDocType,"_"),"U")) {
						#; If only one reference for this DocType, then pull in data for that reference instead of creating two DocTypes with all the same info
						#; This is most likely to be the case when the XSD file includes the envelope information 
						If $Case(tFullNameToUse,"X12_Interchange":1,"X12_FunctionalGroup":1,"X12_TransactionSet":1,:0) && $D($$$XSDSchemaImportPPG("array","X12_TransactionSet")) {
							Set tFullNameToUse = "X12_TransactionSet"
						}
						#; put together 'array' global node for this DocType using information from the referenced DocType
						Do ..ConstructArrayForDocType(tFullNameToUse,tDocType,.tSegsRef)
						#; don't want to duplicate data by also pulling in the contained DocType separately
						Set tSkipList = tSkipList_tFullNameToUse_","
					} Else {
						#; put together 'array' global node for this DocType
						Do ..ConstructArrayForDocType(tFullDocType,tDocType,.tSegsRef)
					}
				}
				#; Kill duplicate data from DocType contained in other DocType if any
				Set tSkipDT = ""
				For i=2:1:$L(tSkipDT,",") {
					Set tSkipDT = $P(tSkipList,",",i)
					Kill $$$vaVSchemaGbl(..category,$P(tSkipDT,"_",2,*))
				}
				
				#; set codes global nodes now that we have assigned ordinals for the segments
				Set tElem = ""
				For {
					Set tElem = $O($$$XSDSchemaImportPPG("c",tElem))	Quit:""=tElem
					Set tCount = 0
					Set tSeg = ""
					For {
						Set tSeg = $O($$$XSDSchemaImportPPG("c",tElem,"e",tSeg))	Quit:""=tSeg
						Set tPos = ""
						For {
							Set tPos = $O($$$XSDSchemaImportPPG("c",tElem,"e",tSeg,tPos))	Quit:""=tPos
							Set tOrdinals = $G(tSegsRef(tSeg))
							Continue:""=tOrdinals
							#; Should usually be just one ordinal corresponding to seg name, but if loop repeated, could be multiple
							For i=1:1:$L(tOrdinals,",") {
								Set tOneRef = $P(tOrdinals,",",i)
								Set $$$vaVSchemaGbl(..category,$P(tOneRef,":"),"c",tElem,"l",$P(tOneRef,":",2),tPos)=$I(tCount)
								Merge $$$vaVSchemaGbl(..category,$P(tOneRef,":"),"c",tElem,"c",tCount)=$$$XSDSchemaImportPPG("c",tElem,"e",tSeg,tPos)
							}
						}
					}
					For {
						Set tSeg = $O($$$XSDSchemaImportPPG("c",tElem,"c",tSeg))	Quit:""=tSeg
						Set tPos = ""
						For {
							Set tPos = $O($$$XSDSchemaImportPPG("c",tElem,"c",tSeg,tPos))	Quit:""=tPos
							Set tCompPos = ""
							For {
								Set tCompPos = $O($$$XSDSchemaImportPPG("c",tElem,"c",tSeg,tPos,tCompPos))	Quit:""=tCompPos
								Set tOrdinals = $G(tSegsRef(tSeg))
								Continue:""=tOrdinals
								For i=1:1:$L(tOrdinals,",") {
									Set tOneRef = $P(tOrdinals,",",i)
									Set $$$vaVSchemaGbl(..category,$P(tOneRef,":"),"c",tElem,"l",$P(tOneRef,":",2),tPos,tCompPos)=$I(tCount)
									Merge $$$vaVSchemaGbl(..category,$P(tOneRef,":"),"c",tElem,"c",tCount)=$$$XSDSchemaImportPPG("c",tElem,"c",tSeg,tPos,tCompPos)
								}
							}
						}
					}
				}
				
				#; merge over 'n' global node for names now that we have assigned ordinals for the segments
				Set tSeg = ""
				For {
					Set tSeg = $O($$$XSDSchemaImportPPG("n",tSeg))	Quit:""=tSeg
					Set tOrdinals = $G(tSegsRef(tSeg))
					Continue:""=tOrdinals
					For i=1:1:$L(tOrdinals,",") {
						Set tOneRef = $P(tOrdinals,",",i)
						Merge $$$vaVSchemaGbl(..category,$P(tOneRef,":"),"n",$P(tOneRef,":",2)) = $$$XSDSchemaImportPPG("n",tSeg)
					}
				}
				
				#; merge over 'o' global node describing elements and composite structures now that we have assigned ordinals for the segments
				For {
					Set tSeg = $O($$$XSDSchemaImportPPG("o",tSeg))	Quit:""=tSeg
					Set tOrdinals = $G(tSegsRef(tSeg))
					Continue:""=tOrdinals
					For i=1:1:$L(tOrdinals,",") {
						Set tOneRef = $P(tOrdinals,",",i)
						Merge $$$vaVSchemaGbl(..category,$P(tOneRef,":"),"o",$P(tOneRef,":",2)) = $$$XSDSchemaImportPPG("o",tSeg)
					}
				}
				
				If '..EnsLibRO {					
					#; merge over descriptions if ENSLIB isn't read-only (probably only beneficial internally)
					Merge $$$vaVSchemaDescGbl("X","X12") = $$$XSDDescImportPPG("X","X12")
					
					#; Code table name is same as that of the element it is used for.  Set this value if haven't already
					Set tCTNum = ""
					For {
						Set tCTNum = $O($$$XSDSchemaImportPPG("c",tCTNum))	Quit:""=tCTNum
						Set:'$D($$$vaVSchemaDescGbl("X","X12","CODES",tCTNum)) $$$vaVSchemaDescGbl("X","X12","CODES",tCTNum)=$G($$$vaVSchemaDescGbl("X","X12","ELEM",tCTNum))
					}
					
					#; create "HL" global nodes in Description global
					Set tSC = ##class(EnsLib.EDI.SEF.Util.X12DataImporter).GenerateBHT()
					Quit:$$$ISERR(tSC)
				}
				
				#; Add Interchange and FunctionalGroup if missing
				If '$D($$$vaVSchemaGbl(..category,"Interchange")) {
					Do ..AddInterchange()
					Set $$$vaVSchemaGbl(..category,"Interchange") = $P(tX,"|",1,3)_"|Interchange outer batch document containing zero or more Group batch documents|"_$P(tX,"|",5,*)_"*Interchange"_$Select(tCtrlVersionNum'="":"_"_tCtrlVersionNum,1:"")
				}
				If '$D($$$vaVSchemaGbl(..category,"FunctionalGroup"))&&'$D($$$vaVSchemaGbl(..category,"Group")) {
					Do ..AddFunctionalGroup()
					Set $$$vaVSchemaGbl(..category,"FunctionalGroup") = $P(tX,"|",1,3)_"|Group batch document containing TransactionSet documents of a given type|"_$P(tX,"|",5,*)_"*FunctionalGroup"_$Select(tCtrlVersionNum'="":"_"_tCtrlVersionNum,1:"")
				}
								
				#; create "map" global nodes
				Set tDocType = ""
				For {
					Set tDocType = $O($$$vaVSchemaGbl(..category,tDocType))	Quit:""=tDocType
					Set tContentArrayName=$Name($$$vaVSchemaGbl(..category,tDocType,"array"))
					Kill tSchemaPathMap
					Do ##class(EnsLib.EDI.SEF.Schema).buildDocStructureMapLoop(tContentArrayName,.tSchemaPathMap,"","=",..category,tDocType)
					Set index=$O(@tContentArrayName@(""),-1)
					Set tSchemaPathMap("leftoversegs()")="="_(+index+1)_",*|:Any"
					Merge $$$vaVSchemaGbl(..category,tDocType,"map")=tSchemaPathMap

				}
				
				Set tSC = ##class(EnsLib.EDI.SEF.Schema).MergeToX12(..category,..ForceOld)
				Quit:$$$ISERR(tSC)
				
				#; Set Implementation Guide and Verbose Description for main DocType if available
				Set:(""'=..ImplGuide) $$$vaSchemaDescGbl(..category,"DS",tMainDocType,"alt")=..ImplGuide
				Set tFullDocType = ""
				For {
					Set tFullDocType = $O($$$XSDDescImportPPG(tFullDocType))	Quit:""=tFullDocType
					If ..MatchesMainDocType(tFullDocType) {
						Set:($D($$$XSDDescImportPPG(tFullDocType),tVerbose)#2) $$$vaSchemaDescGbl(..category,"DS",tMainDocType,"verbose")=tVerbose
						Quit
					}
				}
				
				#; pull in the alternate descriptions
				Merge $$$vaSchemaDescGbl(..category,"SS") = $$$XSDDescImportPPG("SS")
				Merge $$$vaSchemaDescGbl(..category,"CS") = $$$XSDDescImportPPG("CS")
				
				#; manually set descriptions for TransactionSetDocsRef and GroupDocsRef segments
				Set $$$vaSchemaDescGbl(..category,"SS","TransactionSetDocsRef") = "Placeholder segment representing one or more Transaction Set documents in a Group batch document"
				Set $$$vaSchemaDescGbl(..category,"SS","TransactionSetDocsRef",1,"alt") = "Position within the Group batch shell document where this placeholder segment resides"
				Set $$$vaSchemaDescGbl(..category,"SS","TransactionSetDocsRef",2,"alt") = "Number of child Transaction Set documents embedded within the Group batch shell document at this placeholder position"
				Set $$$vaSchemaDescGbl(..category,"SS","GroupDocsRef")="Placeholder segment representing one or more Group batch documents in an outer Interchange batch document"
				Set $$$vaSchemaDescGbl(..category,"SS","GroupDocsRef",1,"alt") = "Position within the Interchange batch shell document where this placeholder segment resides"
				Set $$$vaSchemaDescGbl(..category,"SS","GroupDocsRef",2,"alt") = "Number of child Group documents embedded within the Interchange batch shell document at this placeholder position"
				
				set ..lastFileCategory=..category
				set ..category=""
				Kill $$$XSDSchemaImportPPG
				Kill $$$XSDDescImportPPG
			}
			If localname="sequence" {
				Set ..inSequence = 0
				If $Case(..elementtype,"DS":1,"Loop":1,:0) {
					Set $$$XSDSchemaImportPPG("array",..elementname)=..position
				}
			} Elseif localname = "enumeration" {
				Set ..CTValue = ""
			} Elseif localname = "complexType" {
				If ..elementtype = "CS" {
					Set ..elementtype = "Field"
				}
			} Elseif localname="element" {
				If ..elementtype = "Field" {
					Set ..elementtype = "SS"
					Set tDesc = ..FieldData.GetAt("Name")
					If tDesc="" {
						#; if tDesc="", that means there is no item number, all we do have is the position
						Set tDesc = "Field"_..position
					}
					Set tPropName=..fieldDescToName(tDesc,..elementname,..position)
					Set:$I(..%propNames(tPropName))>1 tPropName=tPropName_..%propNames(tPropName)
					Set tDT = ..FieldData.GetAt("DataType")
					If ("C"'=$E(tDT)) {
						#; Element - E|itemName|Required|Type|MinLen|MaxLen|RepCount|Desc|StdReq
						Set $$$XSDSchemaImportPPG("o",..elementname,..position) = "E|"_..FieldData.GetAt("Number")_"|"_..FieldData.GetAt("Required")_"|"_$E(tDT,2,*-1)_"|"_..FieldData.GetAt("MinLength")_"|"_..FieldData.GetAt("MaxLength")_"|"_..FieldData.GetAt("RepCount")_"|"_tPropName_"|"_..FieldData.GetAt("StdReq")
						If ""'=..FieldData.GetAt("Name") {
							Merge $$$XSDSchemaImportPPG("n",..elementname,tPropName) = $$$XSDSchemaImportPPG("n",..elementname,..FieldData.GetAt("Name"))
							Kill $$$XSDSchemaImportPPG("n",..elementname,..FieldData.GetAt("Name"))
						}
						Set $$$XSDSchemaImportPPG("n",..elementname,tPropName)=..position
					} Else {
						#; Composite - C|itemName|Required|itemName|StdReq|StdRep|ComRepeat|Desc
						Set $$$XSDSchemaImportPPG("o",..elementname,..position) = "C|"_tDT_"|"_..FieldData.GetAt("Required")_"|"_tDT_"|"_..FieldData.GetAt("StdReq")_"|"_..FieldData.GetAt("RepCount")_"|"_..position_"|"_tPropName
					}
				} ElseIf ..elementtype = "CS" {
					Set tDesc = ..CompData.GetAt("Name")
					If tDesc="" {
						#; if tDesc="", that means there is no item number, all we do have is the position
						Set tDesc = "Component"_..compPosition
					}
					Set tPropName=..compositeDescToName(tDesc,..FieldData.GetAt("Name"),..position)
					Set:$I(..%compNames(tPropName))>1 tPropName=tPropName_..%compNames(tPropName)
					#; Element - E|itemName|Required|Type|MinLen|MaxLen|RepCount|Desc|StdReq
					Set tDT = $E(..CompData.GetAt("DataType"),2,*-1)
					Set $$$XSDSchemaImportPPG("o",..elementname,..position,..compPosition) = "E|"_..CompData.GetAt("Number")_"|"_..CompData.GetAt("Required")_"|"_tDT_"|"_..CompData.GetAt("MinLength")_"|"_..CompData.GetAt("MaxLength")_"|"_..CompData.GetAt("RepCount")_"|"_tPropName_"|"_..CompData.GetAt("StdReq")
					Set $$$XSDSchemaImportPPG("n",..elementname,..FieldData.GetAt("Name"),tPropName)=..position_"|"_..compPosition
				} ElseIf '..inSequence {
					Set ..elementtype=""
					Set ..elementname=""
				}
			} Elseif localname="documentation" {
				Set ..inDoc = 0
			}
		} Catch ex {
			Set tSC = ex.AsStatus()
		}
	} While 0
	
	If $$$ISERR(tSC) {		
		Set ..Error = tSC
	}

	Quit
}

}
