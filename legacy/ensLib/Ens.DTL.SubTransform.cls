/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The syntax specifies a data transformation class and the source and target objects to invoke it with
/// 
/// e.g.: <subtransform class="MySubTransform" targetObj="target.{PIDgrp(1).PID}" sourceObj="source.GetSegmentAt(2)" />
/// 
Class Ens.DTL.SubTransform Extends Ens.DTL.Action [ ClassType = "", CompileAfter = Ens.DTL.Transform, ProcedureBlock, System = 3 ]
{

XData Example
{
<subtransform class="MySubTransform" targetObj="target.{PIDgrp(1).PID}" sourceObj="source.GetSegmentAt(2)" />
}

Parameter XMLNAME = "subtransform";

Parameter TAGNAME = "subtransform";

/// The transform class to invoke
Property Class As %String;

/// The name of the target object
Property TargetObj As %String;

/// The name of the source object
Property SourceObj As %String;

/// The name of the auxiliary value passed to the Transform() method
Property Aux As %String;

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tLanguage=$$$sysLangFromDTL(pCompiler.Language)
		Set tClass=..Class
		Set tClass=$s($E(tClass)="@":$E(tClass,2,*),1:""""_tClass_"""")
		Set tAux=..Aux
		If (tAux = "") {
			Set tAux = """"""
		}
		Else {
			#; replace VDoc syntax
			Set tAux = ##class(Ens.VDoc.Utils).GetGetCode(tAux,tLanguage,1)
			#; correctly resolve collection syntax for non-VDoc references
			If (tAux [ ".(") {
				Set tAux = ##class(Ens.DTL.Transform).decoratePropString(tAux)
			}
		}
		
		// Get Target object - VProp or local object
		If tLanguage=$$$objectscript {
			$$$PCIndent(pCompiler.Indent,"Try {")
			Do pCompiler.AddIndent()
		} Else {
		}
		Set targIsVProp=##class(Ens.VDoc.Utils).isSingleVirtualProperty(..TargetObj,.tTargetObject,.tTargetVPath)
		If targIsVProp {
			Set tTargetIsXMLVDoc = ..objectExtends(tTargetObject,pCompiler.Transform.TargetClass,"EnsLib.EDI.XML.Document")
			Set tTargetGetCode = $select(tTargetIsXMLVDoc: ".GetSubDocumentAt(", 1: ".GetSegmentAt(")
			If tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set zTargOBJz="_tTargetObject_tTargetGetCode_##class(Ens.VDoc.Utils).quoteDocumentPath(tTargetVPath)_",.tSCTarg)")
			} Else {
				$$$PCIndent(pCompiler.Indent,"zTargOBJz="_tTargetObject_tTargetGetCode_##class(Ens.VDoc.Utils).quoteDocumentPath(tTargetVPath,1)_") : tSCTarg=System.Status.OK()")
			}
		} Else {
			Set tTargetObject = $Replace(..TargetObj,".(",".GetAt(")
			If tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set zTargOBJz="_tTargetObject_", tSCTarg=$$$OK")
			} Else {
				$$$PCIndent(pCompiler.Indent,"zTargOBJz="_tTargetObject_" : tSCTarg=System.Status.OK()")
			}
		}
		If tLanguage=$$$objectscript {
			Do pCompiler.RemoveIndent()
			/* Only error if not Invalid Oref. If SubTransform uses create='existing' it will report the error*/
			$$$PCIndent(pCompiler.Indent,"} CATCH errobj { Set zTargOBJz=$$$NULLOREF  Set:(errobj.Name'=""<INVALID OREF>"") tSCTarg=errobj.AsStatus() }")
		} Else {
		}
		// Get Source object - VProp or local object
		If ##class(Ens.VDoc.Utils).isSingleVirtualProperty(..SourceObj,.tSourceObject,.tSourceVPath) {
			Set tSourceIsXMLVDoc = ..objectExtends(tSourceObject,pCompiler.Transform.SourceClass,"EnsLib.EDI.XML.Document")
			Set tSourceGetCode = $select(tSourceIsXMLVDoc: ".GetSubDocumentAt(", 1: ".GetSegmentAt(")
			If tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set zSrcOBJz="_tSourceObject_tSourceGetCode_##class(Ens.VDoc.Utils).quoteDocumentPath(tSourceVPath)_",.tSC1)")
				$$$PCIndent(pCompiler.Indent,"Set:$$$ISERR(tSC1)&&'..#IGNOREMISSINGSOURCE tSCTrans=$$$ADDSC(tSCTrans,tSC1)")
			} Else {
				$$$PCIndent(pCompiler.Indent,"zSrcOBJz="_tSourceObject_tSourceGetCode_##class(Ens.VDoc.Utils).quoteDocumentPath(tSourceVPath,1)_") : tSC1=System.Status.OK()")
			}
		} Else {
			Set tSourceObject = $Replace(..SourceObj,".(",".GetAt(")
			If tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set zSrcOBJz="_tSourceObject_", tSC1=$$$OK")
			} Else {
				$$$PCIndent(pCompiler.Indent,"zSrcOBJz="_tSourceObject_": tSC1=System.Status.OK()")
			}
		}
		// Do the Transform
		If tLanguage=$$$objectscript {
			$$$PCIndent(pCompiler.Indent,"If '..#IGNOREMISSINGSOURCE||$IsObject(zSrcOBJz)  Set tSC1=$classmethod("_tClass_",""Transform"",zSrcOBJz,.zTargOBJz,"_tAux_")  If $$$ISERR(tSC1) { Set tSCTrans=$$$ADDSC(tSCTrans,tSC1)  Set tSC1=$$$OK }")
			$$$PCIndent(pCompiler.Indent,"If '$$$IsdefObject(zTargOBJz)&&'..#IGNOREMISSINGSOURCE { Set tSCTrans=$$$ADDSC(tSCTrans,tSCTarg) }  Set tSCTarg = $$$OK")
			If tAux["tSCGet" {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(pCompiler.Language,"tSCGet","tSCTrans"))
			}
			$$$PCIndent(pCompiler.Indent,"If $$$IsdefObject(zSrcOBJz)||'..#IGNOREMISSINGSOURCE {")
		} Else {
			#; TODO: CacheBasic does not support dispatching with classname in a variable
			$$$PCIndent(pCompiler.Indent,"If Not Me.%GetParameter(""IGNOREMISSINGSOURCE"") Or IsObject(zSrcOBJz) Then tSC1="""_..Class_""".Transform(zSrcOBJz,zTargOBJz,"_tAux_")")
			$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC1) Then tSCTrans=System.Status.AppendStatus(tSCTrans,tSC1) : tSC1=System.Status.OK()")
			$$$PCIndent(pCompiler.Indent,"If Not IsObject(zTargOBJz) And Not Me.%GetParameter(""IGNOREMISSINGSOURCE"") Then tSCTrans=System.Status.AppendStatus(tSCTrans,tSCTarg) : End If : tSCTarg=System.Status.OK()")
			If tAux["tSCGet" {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(pCompiler.Language,"tSCGet","tSCTrans"))
			}
			$$$PCIndent(pCompiler.Indent,"If zSrcOBJz Or Not Me.%GetParameter(""IGNOREMISSINGSOURCE"") Then")
		}
		Do pCompiler.AddIndent()
		// Set the transform result back into the target
		If targIsVProp {
			Set tTargetSetCode = $select(tTargetIsXMLVDoc: ".SetSubDocumentAt(", 1: ".SetSegmentAt(")
			If tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Set tSC1="_tTargetObject_tTargetSetCode_"zTargOBJz,"_##class(Ens.VDoc.Utils).quoteDocumentPath(tTargetVPath)_")")
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC1) { Set tSCTrans=$$$ADDSC(tSCTrans,tSC1)  Set tSC1=$$$OK }")
			} Else {
				$$$PCIndent(pCompiler.Indent,"tSC1="_tTargetObject_tTargetSetCode_"zTargOBJz,"_##class(Ens.VDoc.Utils).quoteDocumentPath(tTargetVPath,1)_")")
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC1) Then tSCTrans=System.Status.AppendStatus(tSCTrans,tSC1) : tSC1=System.Status.OK()")
			}
		} Else {
			// first instantiate the property branch down to the target object
			Set tTargetString = ##class(Ens.VDoc.Utils).GetGetCode(..TargetObj,tLanguage)
			Set tTargetTrailArray=0
			If (tTargetString'="target")
			 && ##class(Ens.BPL.Transform).isProperty(tTargetString,.nDots,.tTargetTrailArray)
			 && (nDots>1) {
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,"Do ..instantiateProps("_$P(tTargetObject,".")_","""_tTargetObject_""""_##class(Ens.DTL.Transform).getPropsArgs(tTargetObject)_")")
				} Else {
					$$$PCIndent(pCompiler.Indent,"Me.instantiateProps("_$P(tTargetObject,".")_","""_tTargetObject_""""_##class(Ens.DTL.Transform).getPropsArgs(tTargetObject)_")")
				}
				Set tTargetString=##class(Ens.DTL.Transform).decoratePropString(tTargetString)
			}
			If tTargetTrailArray && (tTargetString = ..TargetObj) {
				#; We still need to process collection syntax
				Set tLastPiece = $piece(tTargetString,".",$length(tTargetString,"."))
				Set tArrayPiece = $piece(tTargetString,".",1,$length(tTargetString,".")-1)
				Set tArrayPiece = ##class(Ens.DTL.Transform).decoratePropString(tArrayPiece)
				If tLastPiece = "()" {
					Set tSetCmd = "Insert"
					Set tSetArg = ""
				}
				Else {
					Set tSetCmd = "SetAt"
					If tLastPiece = "(-)" {
						Set tLastPiece = tArrayPiece_".Previous("""")"
					}
					Set tSetArg = ","_tLastPiece
				}
				If tLanguage = $$$objectscript {
					$$$PCIndent(pCompiler.Indent,"Set tSC="_tArrayPiece_"."_tSetCmd_"(zTargOBJz"_tSetArg_")")
					$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
				}
				Else {
					$$$PCIndent(pCompiler.Indent,"tSC="_tArrayPiece_"."_tSetCmd_"(zTargOBJz"_tSetArg_")")
					$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Exit Do")
				}
			}
			Else {
				#; Assume a non-collection assignment
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,"Set "_tTargetString_"=zTargOBJz")
				} Else {
					$$$PCIndent(pCompiler.Indent,tTargetString_"=zTargOBJz")
				}
			}
		}
		Do pCompiler.RemoveIndent()
		If tLanguage=$$$objectscript {
			$$$PCIndent(pCompiler.Indent,"}")
		} Else {
			$$$PCIndent(pCompiler.Indent,"End If")
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set tSC=$$$OK
	Try {
		Do pStream.Write("<subtransform ")
		Do pStream.Write("class="_$$$EA(..Class))
		Do pStream.Write("targetObj="_$$$EA(..TargetObj))
		Do pStream.Write("sourceObj="_$$$EA(..SourceObj))
		Do:$Case(..Aux,"":0,"""""":0,:1) pStream.Write("aux="_$$$EA(..Aux))
		If ..Disabled Do pStream.Write("disabled="_$$$EA(1))

		Do ..WriteAnnotationXML(pStream,1)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Serialize this transform for use by DTL editor
Method Serialize(pStream As %CharacterStream) As %Status
{
	Do pStream.Write(..%ClassName() _ ..#SDELIM _ 
						..Class _ ..#SDELIM _ 
						..TargetObj _ ..#SDELIM _ 
						..SourceObj _ $C(1))
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	Set ..Class = $P(pState,..#SDELIM,2)
	Set ..TargetObj = $P(pState,..#SDELIM,3)
	Set ..SourceObj = $P(pState,..#SDELIM,4,99999)
	Quit $$$OK
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	Set tSC=$$$OK
	Try {
		#; Must know the transform class
		If ..Class="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"transform class",..DisplayName()))
		}
		#; Must know the target object we want to assign to
		If ..TargetObj="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"target obj",..DisplayName()))
		}
		#; Must know the source object we want to start from
		If ..TargetObj="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"source obj",..DisplayName()))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit "Transform"
}

Method objectExtends(pObjectName As %String = "", pParentClassname As %String = "", pExtendsClass As %String = "") As %String [ Internal ]
{
	Set tExtends = 0, SQLCODE = 0
	Try {
		Set tParentClassname = pParentClassname
		If $L(pObjectName,".") > 1 {
			For tC = 2:1:$L(pObjectName,".") {
				Set tPropName = $Piece(pObjectName,".",tC)
				&sql(select type into :tType from %Dictionary.PropertyDefinition where name=:tPropName and parent =:tParentClassname)
				If SQLCODE Quit
				Set tParentClassname = tType 
			}
		}
		If 'SQLCODE Set tExtends = $classmethod(tParentClassname,"%Extends",pExtendsClass)
	} Catch {}
	Quit tExtends
}

}
