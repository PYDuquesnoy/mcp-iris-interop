/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.MapValues Extends (AbstractExpression, %DeepSee.PMML.Definition.extendableNode) [ System = 3 ]
{

Property mapMissingTo As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property defaultValue As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property outputColumn As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property dataType As %DeepSee.PMML.Datatype.DataType(XMLPROJECTION = "ATTRIBUTE");

Property FieldColumnPairs As list Of FieldColumnPair(XMLNAME = "FieldColumnPair", XMLPROJECTION = "ELEMENT");

Property TableIdentifier As TableIdentifier(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:..FieldColumnPairs.Count() {
			set tPair = ..FieldColumnPairs.GetAt(i)
			
			if '$d(pDictionary("fields", tPair.field)) && '$$$DUMMYFIELD(tPair.field) {
				set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_tPair.field_"'")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetComputeCode(Output pInline As %Boolean = 0, pOverrideSource As %String = "", pThis As %String = ".", pArrayFormat As %Boolean = 0) As %String
{
	#define WriteLine(%s) set tCode = $s(tCode="":$c(9), 1:tCode_$c(13,10,9)) _ %s
	
	if ..TableIdentifier.%IsA("%DeepSee.PMML.Definition.Util.TableLocator") {
		
		// TODO
		quit "	// <TableLocator> is currently not implemented" 
		
	} else {
		
		set pInline = 0, tCode = ""
		set tQuote = (..dataType="string") || (..dataType="")
		
		if (pOverrideSource="") {
			if (..mapMissingTo="") {
				set tMissingValue = "set tValue = """", tStatus = ""missing"""
			} else {
				set tMissingvalue = "set tValue = "_$s(tQuote:$$$QUOTE(..mapMissingTo), 1:..mapMissingTo)
			}
			
			set tIndexCols = "", tIndexFields = "", tIndexCount = ..FieldColumnPairs.Count()
			for i = 1:1:tIndexCount {
				set tIndexCols = tIndexCols _ $lb(..FieldColumnPairs.GetAt(i).column)
				set tField = ..FieldColumnPairs.GetAt(i).field
				if i=1 {
					if pArrayFormat {
						$$$WriteLine("if '$d("_pThis_"("_$$$QUOTE(tField)_")) { "_tMissingValue_" } ")
					} else {
						$$$WriteLine("if "_pThis_".%IsMissing("""_tField_""") { "_tMissingValue_" } ")
					}
				} else {
					if pArrayFormat {
						$$$WriteLine("elseif '$d("_pThis_"("_$$$QUOTE(tField)_")) { "_tMissingValue_" } ")
					} else {
						$$$WriteLine("elseif "_pThis_".%IsMissing("""_tField_""") { "_tMissingValue_" } ")
					}
				}

				// BDB840 - track input datatype
				set tFieldDT(i) = $g(%PMML("Fields",$$$PROPERTYNAME(tField),"datatype"))

				if pArrayFormat {
					set tIndexFields = $s(tIndexFields="":"", 1:tIndexFields _ ",") _ "$s("_pThis_"("_$$$QUOTE(tField)_")="""":$c(0), 1:"_$s((tFieldDT(i)="")||(tFieldDT(i)="string"):"",1:"+")_pThis_"("_$$$QUOTE(tField)_"))"
				} else {
					set tIndexFields = $s(tIndexFields="":"", 1:tIndexFields _ ",") _ "$s("_pThis_"."_$$$PROPERTYNAME(tField)_"="""":$c(0), 1:"_$s((tFieldDT(i)="")||(tFieldDT(i)="string"):"",1:"+")_pThis_"."_$$$PROPERTYNAME(tField)_")"
				}
			}
		
			$$$WriteLine("else {")
		} else {
			set tIndexCols = "", tIndexFields = "", tIndexCount = ..FieldColumnPairs.Count()
			for i = 1:1:tIndexCount {
				set tIndexCols = tIndexCols _ $lb(..FieldColumnPairs.GetAt(i).column)
				set tOverrideSourcePiece = $p(pOverrideSource,",",i)

				// BDB840 - track input datatype
				set tFieldDT(i) = $g(%PMML("Fields",$$$PROPERTYNAME(..FieldColumnPairs.GetAt(i).field),"datatype"))

				set tIndexFields = $s(tIndexFields="":"", 1:tIndexFields _ ",") _ "$s("_tOverrideSourcePiece_"="""":$c(0), 1:"_ $s((tFieldDT(i)="")||(tFieldDT(i)="string"):"", 1:"+") _ tOverrideSourcePiece _ ")"
			}
		}
		
		// this method has been verified as part of its %OnValidateObject()
		do ..TableIdentifier.%GetRows(.tRows)
		
		$$$WriteLine($c(9)_"set tStatus = ""valid""")
		
		for i = 1:1:tRows {
			set tIndex = ""
			for j = 1:1:tIndexCount {
				set tIndexValue = $g(tRows(i,$li(tIndexCols,j)))
				set tIndexValue = $s(tIndexValue="":$c(0), (tFieldDT(j)="")||(tFieldDT(j)="string"):$$$QUOTE(tIndexValue), 1:+tIndexValue)
				set tIndex = $s(tIndex="":"", 1:tIndex_",") _ tIndexValue
			}
			set tValue = $g(tRows(i,..outputColumn))
			if i=1 {
				$$$WriteLine($c(9)_"set tMap("_tIndex_") = "_$s(tQuote:$$$QUOTE(tValue), 1:tValue)_$s(i<tRows:",",1:""))
			} else {
				$$$WriteLine($c(9,9)_"tMap("_tIndex_") = "_$s(tQuote:$$$QUOTE(tValue), 1:tValue)_$s(i<tRows:",",1:""))
			}
		}
		
		if ..defaultValue="" {
			set tDefault = """"", tStatus = ""missing"""
		} else {
			set tDefault = $s(tQuote:$$$QUOTE(..defaultValue),1:..defaultValue)
		}
		$$$WriteLine($c(9)_"set:'$d(tMap("_tIndexFields_"),tValue) tValue = "_tDefault)
		
		if (pOverrideSource="") {
			$$$WriteLine("}")
		}
		
		quit tCode
	}
}

Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	for i = 1:1:..FieldColumnPairs.Count() {
		set pFields(..FieldColumnPairs.GetAt(i).field) = ""
	}
	quit $$$OK
}

}
