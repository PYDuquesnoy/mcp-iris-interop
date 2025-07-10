/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.DTL.ForEach Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// 'property' and 'value' attributes are both required
XData Example
{
<foreach key="K1" property="source.IN1grp()">
<assign property="target.IN1grp(K1).IN1" value="source.IN1grp(K1).IN1"/>
</foreach>
}

Parameter TAGNAME = "foreach";

/// This holds the name of the property
Property Property As %String;

/// This holds the key to use for iteration of the property
Property Key As %String;

/// Unload from memory the property for the specific key at the end of each loop
Property Unload As %Boolean [ InitialExpression = 0 ];

///  This holds the Activity list which represents the loop body
Property Actions As Ens.DTL.ActionList;

Method %OnNew(initvalue) As %Status
{
	Set ..Actions=##class(Ens.DTL.ActionList).%New()
	Quit $$$OK
}

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	#dim tSC=$$$OK
	Try {
		#dim tPropertyTransformClass
		If ($piece(..Property,".") = "source") {
			Set tPropertyTransformClass = pCompiler.Transform.SourceClass
		} Else {
			Set tPropertyTransformClass = pCompiler.Transform.TargetClass
		}
		#dim tKey = ..Key
		#dim tProperty = ..PropertyNameToNameInCode(tPropertyTransformClass)
		#dim tLanguage=$$$sysLangFromDTL(pCompiler.Language)
		#dim tCode, tComplete
	
		Set pCompiler.ForEachKeys(..Key) = "" 

		Set tSC=##class(Ens.VDoc.Utils).GetNextCode(.tCode,.tComplete,tProperty,tKey,tLanguage,"tSC1") If $$$ISERR(tSC) Quit

		If ( 'tComplete ) {
			if tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set "_tKey_"="""",tSC=$$$OK")
				$$$PCIndent(pCompiler.Indent,"For {")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,"Set "_tKey_"="_tProperty_".Next("_tKey_")")
				$$$PCIndent(pCompiler.Indent,"Quit:"_tKey_"=""""")
				Set tSC=..Actions.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
				If ..Unload {
					Set tSC=..generateUnloadCode(pCompiler,tProperty,tKey,"UnSwizzle") If $$$ISERR(tSC) Quit
				}
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"}")
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
			} else {
				$$$PCIndent(pCompiler.Indent,tKey_" = """" : tSC = System.Status.OK()")
				$$$PCIndent(pCompiler.Indent,"do")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,tKey_"="_tProperty_".Next("_tKey_") : If "_tKey_"="""" then exit do")
				Set tSC=..Actions.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"loop")
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Goto Exit")
			}
		} ElseIf ($e($p(tProperty,".",*),*+1-$l("DocsRef}"),*) = "DocsRef}") || ($p($p(tProperty,".",*),"DocsRef-",2,*) ? 1.N1"}") {
			#dim f=$f(tProperty,"{")
			#dim path=$e(tProperty,f,*-1)
			#dim tPropPrePathInclLastDot = $e(tProperty,1,f-2)
			#dim tChildPointerArray = ..extractPossibleChildPointer(.tPropPrePathInclLastDot, tKey)

			#dim tSegIndex
			if tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set tSC ="_tPropPrePathInclLastDot_"BuildMap()")
				Set tSegIndex=tPropPrePathInclLastDot_"GetSegmentIndex("_##class(Ens.VDoc.Utils).quoteDocumentPath(path)_",.tSC1)"
				$$$PCIndent(pCompiler.Indent,"Set "_tKey_"=$$$NULLOREF,tSC=$$$OK")
				$$$PCIndent(pCompiler.Indent,"For {")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,"Set tSC1=$$$OK, "_tKey_"="_tPropPrePathInclLastDot_"NextChild("_tKey_","_tSegIndex_")")
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC1) { Set:('..#IGNOREMISSINGSOURCE||(($$$StatusText(tSC1)'[""No segment found"")&&($$$StatusText(tSC1)'[""is not an element, instead this node""))) tSCTrans=$$$ADDSC(tSCTrans,tSC1)  Set tSC1=$$$OK }")
				$$$PCIndent(pCompiler.Indent,"Quit:'$IsObject("_tKey_")")
				If tChildPointerArray'="" {
					$$$PCIndent(pCompiler.Indent,"Set "_tPropPrePathInclLastDot_tChildPointerArray_"="_tKey)
				}
				$$$PCIndent(pCompiler.Indent,"If """"="_tKey_".DocType {")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,"Set tDocType = "_tKey_".resolveChildDocType()")
				$$$PCIndent(pCompiler.Indent,"Set tSC ="_tKey_".PokeDocType(tDocType)")
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"}")
				Set tSC=..Actions.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
				If tChildPointerArray'="" && ..Unload {
					Set tSC=..generateUnloadCode(pCompiler,(tPropPrePathInclLastDot_tChildPointerArray),"","NULLOREF") If $$$ISERR(tSC) Quit
				}
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"}")
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
			} else {
				$$$PCIndent(pCompiler.Indent,tKey_" = """" : tSC = System.Status.OK()")
				$$$PCIndent(pCompiler.Indent,"tSC ="_tPropPrePathInclLastDot_"BuildMap()")
				#; Basic quoting
				Set tSegIndex=tPropPrePathInclLastDot_"GetSegmentIndex("_##class(Ens.VDoc.Utils).quoteDocumentPath(path,1)_",tSC1)"
				$$$PCIndent(pCompiler.Indent,"do")
				Do pCompiler.AddIndent()

				$$$PCIndent(pCompiler.Indent,"tSC1 = System.Status.OK : "_tKey_"="_tPropPrePathInclLastDot_"NextChild("_tKey_","_tSegIndex_")")
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC1) And ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or ((0=InStr(System.Status.GetOneStatusText(tSC1),""No segment found"")) And (0=InStr(System.Status.GetOneStatusText(tSC1),""is not an element, instead this node"")))) Then tSCTrans=System.Status.AppendStatus(tSCTrans,tSC1) : End If : tSC1=System.Status.OK()")				
				$$$PCIndent(pCompiler.Indent, "If "_tKey_"="""" then exit do")
				If tChildPointerArray'="" {
					$$$PCIndent(pCompiler.Indent,tPropPrePathInclLastDot_tChildPointerArray_"="_tKey)
				}
				$$$PCIndent(pCompiler.Indent,"If """"="_tKey_".DocType Then")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,"tDocType = "_tKey_".resolveChildDocType()")
				$$$PCIndent(pCompiler.Indent,"tSC ="_tKey_".PokeDocType(tDocType)")
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"End If")
				Set tSC=..Actions.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"loop")
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Goto Exit")
			}
		} Else {
			set f=$f(tProperty,"{")
			#dim tPath = ##class(Ens.VDoc.Utils).quoteDocumentPath($E(tProperty,f,*-1))
			#dim tObj=$e(tProperty,1,f-2)
			#dim tPathIsRepeatingField = ((tPath[":")||$classmethod(tPropertyTransformClass,"%Extends","EnsLib.EDI.Segment"))
			if tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set "_tKey_"="""",tSC=$$$OK")
				If tPathIsRepeatingField {
					$$$PCIndent(pCompiler.Indent,"If ("_tObj_"GetValueAt("_tPath_")'="""")||('..#TREATEMPTYREPEATINGFIELDASNULL) {")
					Do pCompiler.AddIndent()
				}
				$$$PCIndent(pCompiler.Indent,"For {")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,"Set tSC1=$$$OK, "_tKey_"="_tCode)
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC1) { Set:('..#IGNOREMISSINGSOURCE||(($$$StatusText(tSC1)'[""No segment found"")&&($$$StatusText(tSC1)'[""is not an element, instead this node""))) tSCTrans=$$$ADDSC(tSCTrans,tSC1)  Set tSC1=$$$OK }")
				$$$PCIndent(pCompiler.Indent,"Quit:"_tKey_"=""""")
				Set tSC=..Actions.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
				If ..Unload && 'tPathIsRepeatingField {
					Set tSC=..generateUnloadCode(pCompiler,tPath,tKey,"commitCollectionOpenSegments") If $$$ISERR(tSC) Quit
				}
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"}")
				If tPathIsRepeatingField {
					Do pCompiler.RemoveIndent()
					$$$PCIndent(pCompiler.Indent,"}")
				}
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
			} else {
				$$$PCIndent(pCompiler.Indent,tKey_" = """" : tSC = System.Status.OK() : tSC1 = System.Status.OK()")
				If tPathIsRepeatingField {
					$$$PCIndent(pCompiler.Indent,"If (("_tObj_"GetValueAt("_tPath_")<>"""") Or (Not Me.%GetParameter(""TREATEMPTYREPEATINGFIELDASNULL""))) Then")
					Do pCompiler.AddIndent()
				}
				$$$PCIndent(pCompiler.Indent,"do")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,"tSC1 = System.Status.OK : "_tKey_"="_tCode)
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC1) And ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or ((0=InStr(System.Status.GetOneStatusText(tSC1),""No segment found"")) And (0=InStr(System.Status.GetOneStatusText(tSC1),""is not an element, instead this node"")))) Then tSCTrans=System.Status.AppendStatus(tSCTrans,tSC1) : End If : tSC1=System.Status.OK()")				
				$$$PCIndent(pCompiler.Indent,"If "_tKey_"="""" Then exit do")
				Set tSC=..Actions.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"loop")
				If tPathIsRepeatingField {
					Do pCompiler.RemoveIndent()
					$$$PCIndent(pCompiler.Indent,"End If")
				}
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Goto Exit")
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	Set tSC=$$$OK
	Try {
		
		Do pStream.Write("<foreach ")
		
		Do pStream.Write("property="_$$$EA(..Property)_"key="_$$$EA(..Key))
		#; studioSave in DTLEditor sends unload="false" or "true"
		If ..Unload ||(..Unload="true") Do pStream.Write("unload="_$$$EA(1))
		If ..Disabled Do pStream.Write("disabled="_$$$EA(1))

		If '..Expanded Do ..WriteExpandedAttribute(pStream)

		If ..Annotation'=""||(..Actions.Count()) {
			
			Do pStream.WriteLine(">")
			Do ..WriteAnnotationXML(pStream,0)
						
			Set tSC=..Actions.GenerateXML(pStream,language)
			If $$$ISERR(tSC) Quit
			
			Do pStream.WriteLine("</foreach>")
			
		} else {
			Do pStream.WriteLine("/>")
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Serialize this transform for use by DTL editor
Method Serialize(pStream As %CharacterStream) As %Status
{
	Quit $$$OK
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	Quit $$$OK
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	Set tSC=$$$OK
	Try {
		#; Must know the property we want to iterate
		If ..Property="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"property",..DisplayName()))
		}
		
		#; Must know the key
		If ..Key="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"key",..DisplayName()))
		}
		
		#; Delegate to the activities
		Set tSC=..Actions.Validate(.pStatus,pContext)
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "ForEach"
}

/// Take the <PROPERTY>Property</PROPERTY> and translate as necessary
/// for use in generated code. <br>
/// Also pass back transform class - whether source or target
Method PropertyNameToNameInCode(pPropertyTransformClass As %String) As %String [ Internal ]
{
	#dim tProperty = ..Property

	/*	X12 Batch pseudo property names from VDoc 
		FunctionalGroups() and TransactionSets are pseudo names
		that action as pointers to child documents
		.FunctionalGroups() - need to add .{GroupDocsRef}
		.TransactionSets() need to add .{TransactionSetDocsRef}
	*/
	If (pPropertyTransformClass = "EnsLib.EDI.X12.Document") {
		#dim tLastPropPiece = $p(tProperty,".",*)
		If (tLastPropPiece["FunctionalGroups()") {
			Set tProperty =  tProperty _".{GroupDocsRef}"
		} ElseIf (tLastPropPiece["TransactionSets()") {
			Set tProperty =  tProperty _".{TransactionSetDocsRef}"
		}
	}

	#; Remove trailing .()
	If ($E(tProperty,*) = ")") {
		Set tProperty=$P(tProperty,"(",1,*-1)
		If ($E(tProperty,*) = ".") Set tProperty = $E(tProperty,1,*-1)
	}

	#; insert GetAt
	Set tProperty = $Replace(tProperty,".(",".GetAt(")

	Return tProperty
}

/// Internal method to remove any pseudo child point property
Method extractPossibleChildPointer(ByRef pPropPrePathInclLastDot As %String, pKey As %String) As %String [ Internal ]
{
	#dim tDotLength = $Length(pPropPrePathInclLastDot,".")
	#dim tChildPointerArray = $Piece(pPropPrePathInclLastDot,".",(tDotLength-1))

	If (tChildPointerArray["FunctionalGroups(")||(tChildPointerArray["TransactionSets"){

		#; Remove childPointerArray from property - leave trailing .
		Set pPropPrePathInclLastDot = $e(pPropPrePathInclLastDot,1,*-($Length(tChildPointerArray)+1))
		#; insert key in expected last () - do after prior statement
		Set tChildPointerArray = $Replace(tChildPointerArray,"()",("("_pKey_")"))

	} Else {

		Set tChildPointerArray = ""

	}

	Return tChildPointerArray
}

Method generateUnloadCode(pCompiler As Ens.DTL.Compiler, pProperty As %String, pKey As %String, pTypeOfUnload As %String) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		If $$$sysLangFromDTL(pCompiler.Language)'=$$$objectscript Quit

		#dim tPropertyTransformClass,tPropertyRootObject
		If ($piece(..Property,".") = "source") {
			Set tPropertyTransformClass = pCompiler.Transform.SourceClass
			Set tPropertyRootObject = "source"
		} Else {
			Set tPropertyTransformClass = pCompiler.Transform.TargetClass
			Set tPropertyRootObject = "target"
		}

		If (pTypeOfUnload="UnSwizzle") {

			If ..propertyCanUnSwizzle(pProperty,tPropertyTransformClass) {$$$PCIndent(pCompiler.Indent,"Do "_pProperty_".%UnSwizzleAt("_pKey_")")}

		} ElseIf (pTypeOfUnload = "NULLOREF") {

			$$$PCIndent(pCompiler.Indent,"Set "_pProperty_"=$$$NULLOREF")

		} ElseIf (pTypeOfUnload = "commitCollectionOpenSegments") {

			If $classmethod(tPropertyTransformClass,"%Extends","EnsLib.HL7.Message")||
					 	$classmethod(tPropertyTransformClass,"%Extends","EnsLib.EDI.X12.Document")||
					 	$classmethod(tPropertyTransformClass,"%Extends","EnsLib.EDI.EDIFACT.Document")||
					 	$classmethod(tPropertyTransformClass,"%Extends","EnsLib.EDI.ASTM.Document") {

				#dim collectionPath = pProperty
				If $Extract(collectionPath,*-2,*)=("()"_$C(34)) Set collectionPath = $E(collectionPath,1,*-2)_$C(34)_"_"_pKey_"_"_$c(34)_")"_$C(34)

				#; X12 object may be pointed to by the pseudo property of source.FunctionalGroups(key1).TransactionSets(key2)
				If $classmethod(tPropertyTransformClass,"%Extends","EnsLib.EDI.X12.Document") {
					If ((..Property [ ".TransactionSets(")||(..Property [ ".FunctionalGroups(")) && (..Property [ ".{") {
						Set tPropertyRootObject = $Piece(..Property,".{")
					}
				}

				$$$PCIndent(pCompiler.Indent,"Do "_tPropertyRootObject_".commitCollectionOpenSegments("_collectionPath_")")

			}

		}

	} Catch ex {

		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// internal method to check if property supports %UnSwizzleAt()
Method propertyCanUnSwizzle(pProperty As %String, pClass As %String) As %Boolean [ Internal ]
{
	#dim isCollection = 0
	Try {
		#dim tPropertyLength = $Length(pProperty,".")
		#dim tPieceCount

		#dim tParentClass = pClass
		#dim tSingleProperty
		#dim tSinglePropertyClass = ""

		For tPieceCount = 2:1:tPropertyLength {
			Set tSingleProperty = $Piece(pProperty,".",tPieceCount)
			Set tSinglePropertyClass = $$$comMemberKeyGet(tParentClass,$$$cCLASSproperty,tSingleProperty,$$$cPROPtype)
			If tPieceCount<tPropertyLength {
				Set tParentClass = tSinglePropertyClass
			}
		}

		If (tSinglePropertyClass'="") &&($$$comClassKeyGet(tSinglePropertyClass,$$$cCLASSclasstype)'="datatype") {

			#dim collectionType = $$$comMemberKeyGet(tParentClass,$$$cCLASSproperty,tSingleProperty,$$$cPROPcollection)

			If (collectionType="list")||(collectionType="array") {
				Set isCollection = 1
			}

		}

	} Catch {}
	Return isCollection
}

}
