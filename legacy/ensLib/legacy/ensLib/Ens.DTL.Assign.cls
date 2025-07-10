/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The syntax specifies a target object and an expression that will be 
/// assigned to it:-
/// 
/// <assign property="name" value="expression" />
/// 
/// Assignments can specify the 'action' attribute which determines how the assignment
/// is performed. Legal values for the 'action' attribute are:- Append,Clear, Insert,Remove and Set.
/// If this attribute is not specified, the default value is 'Set'. Append,Clear, Insert and Remove
/// are only applicable when the object being accessed is a collection of type 'list' or 'array'.
/// Depending upon the type of assignment, an additional attribute 'key' may be required. Here is a
/// table which determines which attributes are required to effect a particular type of assignment.
/// 
/// Property Type    Assignment Action  Key Required  Result
/// -------------    ---------------    ------------  ------
/// Non-collection   Set                No            Property is set to new value
/// Array            Clear              No            Array is cleared
/// Array            Remove             Yes           Element at Key is removed
/// Array            Set                Yes           Element at Key is set to new value
/// List             Append             No            Element is added to the end of the list
/// List             Clear              No            List is cleared
/// List             Insert             Yes           Element is inserted at position determined by Key
/// List             Remove             Yes           Element at Key is removed
/// List             Set                Yes           Element at Key is replaced
Class Ens.DTL.Assign Extends Ens.DTL.Action [ ClassType = "", CompileAfter = Ens.DTL.Transform, ProcedureBlock, System = 3 ]
{

/// 'property' and 'value' attributes are both required
XData Example
{
<assign property="output.Location" value="input.Location"/>
}

Parameter TAGNAME = "assign";

/// This holds the name of the target
Property Property As %String;

/// This holds the value to assign to the property
Property Value As %String;

/// This holds the type of the assignment
Property Action As %String [ InitialExpression = "set" ];

/// This holds the key ( optional ) used for certain types of assignment operations
/// on properties which are collections  (array or list)
Property Key As %String [ InitialExpression = """""" ];

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tLanguage=$$$sysLangFromDTL(pCompiler.Language)
		Set tValue = ..Value

		Set tValGetCode = ##class(Ens.VDoc.Utils).GetGetCode(..Value,tLanguage,1)
		Set tPropGetCode = ##class(Ens.VDoc.Utils).GetGetCode(..Property,tLanguage)
		Set tTargetIsVDoc = ##class(Ens.VDoc.Utils).IsVirtualDocument(pCompiler.Transform.TargetClass)

		Set usePython = (($$$python= ..LanguageOverride ) || (..LanguageOverride="" && (pCompiler.Language = $$$python)))
		Set createCloneIfPython = 0
		If usePython {
				If ##class(Ens.VDoc.Utils).isSingleVirtualProperty(tValue) || (..Action = "remove") || (..Action = "clear")  {
					Set usePython = 0
					// basically the value doesn't need to be handled in any special manner (or value doesn't exist) and the 
					// property can never be a python expression...
				} Else {
					Do ##class(Ens.DTL.Compiler).vDocsToPythonArgs(tValue,.args,.fullcode,.rep)

					If args Do pCompiler.Implementation.WriteLine(" ; ===== Start of args for python Assign Block ")
					For counter = args:-1:1 {
						Set codeLine = "Set arg"_counter_" = "_args(counter)
						Set codeLine = ##class(Ens.DTL.Transform).decoratePropString(codeLine)
						Set codeLine = ##class(Ens.VDoc.Utils).GetGetCode(codeLine,tLanguage,1)
						Do %code.WriteLine(" "_codeLine)
						If (codeLine [ "tSCGet") {
							$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
						}
					}	
					Set rep = ##class(Ens.DTL.Transform).decoratePropString(rep)
					Set customVariablesArray = ##class(Ens.DTL.Compiler).parsePyExpression(rep)
					Set newArgs = ##class(%ListOfDataTypes).%New()
					Set currArg=""
					For  {
						Set value=customVariablesArray.GetNext(.currArg)  
						Quit:currArg="" 
						If $DATA(pCompiler.ContextCustomVariables(currArg)) {
							// newArgs will have the arguments at the intersection of customVariablesArray and pCompiler.ContextCustomVariables. This is important to account
							// for duplicates as well as stray argument names that might either be generated in ##class(Ens.DTL.Compiler).parsePyExpression() or pCompiler.ContextCustomVariables(). 
							Do newArgs.Insert(currArg)
						}
					}

					Set tValue = pCompiler.GeneratePyExec(rep,"DTLShape:Assign:",,1, pCompiler, args , newArgs)
					Kill args, newArgs, customVariablesArray

					If ..Value="source"||##class(Ens.BPL.Transform).isProperty(..Value,,.tValTrailingArray)||tValTrailingArray {
						Set createCloneIfPython = 1
					}
				}
         }

		// identifies newly created variables to be stored in the context of the Compiler. This is then 
		// used to parse arguments required by a python expression in an "assign" action
		If (tPropGetCode = ..Property) { Set pCompiler.ContextCustomVariables(tPropGetCode) = "" }

		#; If target is a VDoc or the property contains VDoc syntax
		If tTargetIsVDoc || (..Property '= tPropGetCode) {
			Set tSame=0
			If tTargetIsVDoc {
				Try {
					Set tSame= ($CLASSMETHOD(pCompiler.Transform.TargetClass,"%Extends",pCompiler.Transform.SourceClass)
						 || $CLASSMETHOD(pCompiler.Transform.SourceClass,"%Extends",pCompiler.Transform.TargetClass))
				}
				Catch { Set tSame = 0 }
			}
			#; If tValue contains ".(" and the source isn't a VDoc or doesn't contain VDoc syntax, resolve any collection syntax
			If (tValue [ ".(") && (('##class(Ens.VDoc.Utils).IsVirtualDocument(pCompiler.Transform.SourceClass)) || (tValue = tValGetCode)) {
				Set tValue = ##class(Ens.DTL.Transform).decoratePropString(tValue)
			}
			Set tSC=##class(Ens.VDoc.Utils).GetSetCode(.tCode,.tComplete,..Property, tValue,..Action,..Key,tLanguage,tSame,1)  Quit:$$$ISERR(tSC) 
			If (tComplete) {
				Set tCode = $ZSTRIP(tCode,"<W")
				$$$PCIndent(pCompiler.Indent,tCode)
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSC1","tSCTrans"))
				Quit
			}
		}

		Set ..Property = tPropGetCode
		Set tValue = $SELECT(..Value = tValue: tValGetCode, 1: ##class(Ens.VDoc.Utils).GetGetCode(tValue,tLanguage,1))

		Set tPropString=..Property
		Set tPropTrailArray = 0
		Set tPropIsProp = ##class(Ens.BPL.Transform).isProperty(tPropString,.nDots,.tPropTrailArray)

		If tValue="source"||##class(Ens.BPL.Transform).isProperty(tValue,,.tValTrailingArray)||tValTrailingArray||createCloneIfPython {
			#; Ensure we handle object collection syntax correctly
			Set tValue = ##class(Ens.DTL.Transform).decoratePropString(tValue)
			#; If target an intermediate temporary variable, we will share the object reference - checking to make sure it is not
			
			If tPropString="target"||tPropIsProp||tPropTrailArray||(..Key'="""""") {
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,"Set tIgnore = 0")
					$$$PCIndent(pCompiler.Indent,"Try { Set zVALz="_tValue_", zVALz=$S($IsObject(zVALz):zVALz.%ConstructClone(), 1:zVALz) }")
					$$$PCIndent(pCompiler.Indent,"Catch ex { If (..#IGNOREMISSINGSOURCE&&($$$StatusText(ex.AsStatus())[""<INVALID OREF>"")) { Set tIgnore=1 } Else { Set tSC=ex.AsStatus() } }")
					$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
				} Else {
					$$$PCIndent(pCompiler.Indent,"tIgnore = 0")
					$$$PCIndent(pCompiler.Indent,"Try")
					Do pCompiler.AddIndent()
					$$$PCIndent(pCompiler.Indent,"zVALz="_tValue)
					Do pCompiler.RemoveIndent()
					$$$PCIndent(pCompiler.Indent,"Catch ex")
					Do pCompiler.AddIndent()
					$$$PCIndent(pCompiler.Indent,"If ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or (0=InStr(System.Status.GetOneStatusText(ex.AsStatus()),""<INVALID OREF>""))) Then")
					Do pCompiler.AddIndent()
					$$$PCIndent(pCompiler.Indent,"tSC=ex.AsStatus() : Exit Do")
					Do pCompiler.RemoveIndent()
					$$$PCIndent(pCompiler.Indent,"Else")
					Do pCompiler.AddIndent()
					$$$PCIndent(pCompiler.Indent,"tIgnore = 1")
					Do pCompiler.RemoveIndent()
					$$$PCIndent(pCompiler.Indent,"End If")
					Do pCompiler.RemoveIndent()
					$$$PCIndent(pCompiler.Indent,"End Try")
					$$$PCIndent(pCompiler.Indent,"If IsObject(zVALz) Then zVALz=zVALz.%ConstructClone()")
				}
				Set tValue="zVALz"
				Set tIsZVALz = 1
			}
		}

		#; Ensure we handle object collection syntax correctly
		If tValue[".(" {
			Set tValue = ##class(Ens.DTL.Transform).decoratePropString(tValue)
		}

		If tPropString'="target"&&tPropIsProp&&(nDots>1) {
			If tLanguage=$$$objectscript {
				$$$PCIndent(pCompiler.Indent,"Do ..instantiateProps("_$P(tPropString,".")_","_$$$QuoteName(tPropString)_##class(Ens.DTL.Transform).getPropsArgs(tPropString)_")")
			} Else {
				$$$PCIndent(pCompiler.Indent,"Me.instantiateProps("_$P(tPropString,".")_","_$$$QuoteName(tPropString)_##class(Ens.DTL.Transform).getPropsArgs(tPropString)_")")
			}
			Set tPropString=##class(Ens.DTL.Transform).decoratePropString(tPropString)
		}

		If ..Action="set" {
			If ..Key="""""" {
				If tPropTrailArray && (tPropString = ..Property) {
					#; We need to handle the case where we still need to process collection syntax
					Set tLastPiece = $piece(tPropString,".",$length(tPropString,"."))
					Set tArrayPiece = $piece(tPropString,".",1,$length(tPropString,".")-1)
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
						$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If 'tIgnore",1:"Try")_" { Set tSC="_tArrayPiece_"."_tSetCmd_"("_tValue_tSetArg_") }")
						If '$G(tIsZVALz,0) {
							$$$PCIndent(pCompiler.Indent,"Catch ex { If (..#IGNOREMISSINGSOURCE&&($$$StatusText(ex.AsStatus())[""<INVALID OREF>"")) { Set tSC = $$$OK } Else { Set tSC=ex.AsStatus() } }")
						}
						$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
					}
					Else {
						$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If (Not tIgnore) Then",1:"Try")_" tSC="_tArrayPiece_"."_tSetCmd_"("_tValue_tSetArg_")")
						If '$G(tIsZVALz,0) {
							$$$PCIndent(pCompiler.Indent,"Catch ex")
							Do pCompiler.AddIndent()
							$$$PCIndent(pCompiler.Indent,"If ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or (0=InStr(System.Status.GetOneStatusText(ex.AsStatus()),""<INVALID OREF>""))) Then tSC=ex.AsStatus()")
							Do pCompiler.RemoveIndent()
							$$$PCIndent(pCompiler.Indent,"End Try")
						}
						$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Exit Do")
					}
				}
				Else {
					#; Assume a non-collection assignment
					If tLanguage=$$$objectscript {
						$$$PCIndent(pCompiler.Indent,$Select($G(tIsZVALz):"If 'tIgnore",1:"Try")_" { Set "_tPropString_"="_tValue_" }")
						If '$G(tIsZVALz,0) {
							$$$PCIndent(pCompiler.Indent,"Catch ex { If (..#IGNOREMISSINGSOURCE&&($$$StatusText(ex.AsStatus())[""<INVALID OREF>"")) { Set tSC = $$$OK } Else { Set tSC=ex.AsStatus() } }")
							$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
						}
					} Else {
						$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If (Not tIgnore) Then ",1:"Try ")_tPropString_"="_tValue)
						If '$G(tIsZVALz,0) {
							$$$PCIndent(pCompiler.Indent,"Catch ex")
							Do pCompiler.AddIndent()
							$$$PCIndent(pCompiler.Indent,"If ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or (0=InStr(System.Status.GetOneStatusText(ex.AsStatus()),""<INVALID OREF>""))) Then")
							Do pCompiler.AddIndent()
							$$$PCIndent(pCompiler.Indent,"tSC=ex.AsStatus() : Exit Do")
							Do pCompiler.RemoveIndent()
							$$$PCIndent(pCompiler.Indent,"End If")
							Do pCompiler.RemoveIndent()
							$$$PCIndent(pCompiler.Indent,"End Try")
						}
					}
				}
			} Else {
				#; Collection
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If 'tIgnore",1:"Try")_" { Set tSC="_tPropString_".SetAt("_tValue_","_..Key_") }")
					If '$G(tIsZVALz,0) {
						$$$PCIndent(pCompiler.Indent,"Catch ex { If (..#IGNOREMISSINGSOURCE&&($$$StatusText(ex.AsStatus())[""<INVALID OREF>"")) { Set tSC = $$$OK } Else { Set tSC=ex.AsStatus() } }")
					}
					$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
				} Else {
					$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If (Not tIgnore) Then",1:"Try")_" tSC="_tPropString_".SetAt("_tValue_","_..Key_")")
					If '$G(tIsZVALz,0) {
						$$$PCIndent(pCompiler.Indent,"Catch ex")
						Do pCompiler.AddIndent()
						$$$PCIndent(pCompiler.Indent,"If ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or (0=InStr(System.Status.GetOneStatusText(ex.AsStatus()),""<INVALID OREF>""))) Then tSC=ex.AsStatus()")
						Do pCompiler.RemoveIndent()
						$$$PCIndent(pCompiler.Indent,"End Try")
					}
					$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Exit Do")
				}
			}
		} ElseIf ..Action="insert" {
			If ..Key="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithInsert)
			} Else {
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If 'tIgnore",1:"Try")_" { Set tSC="_tPropString_".InsertAt("_tValue_","_..Key_") }")
					If '$G(tIsZVALz,0) {
						$$$PCIndent(pCompiler.Indent,"Catch ex { If (..#IGNOREMISSINGSOURCE&&($$$StatusText(ex.AsStatus())[""<INVALID OREF>"")) { Set tSC = $$$OK } Else { Set tSC=ex.AsStatus() } }")
					}
					$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
				} Else {
					$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If (Not tIgnore) Then",1:"Try")_" tSC="_tPropString_".InsertAt("_tValue_","_..Key_")")
					If '$G(tIsZVALz,0) {
						$$$PCIndent(pCompiler.Indent,"Catch ex")
						Do pCompiler.AddIndent()
						$$$PCIndent(pCompiler.Indent,"If ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or (0=InStr(System.Status.GetOneStatusText(ex.AsStatus()),""<INVALID OREF>""))) Then tSC=ex.AsStatus()")
						Do pCompiler.RemoveIndent()
						$$$PCIndent(pCompiler.Indent,"End Try")
					}
					$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Exit Do")
				}
			}
			
		} ElseIf ..Action="append" {
			If ..Key'="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithAppend)
			} Else {
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If 'tIgnore",1:"Try")_" { Set tSC="_tPropString_".Insert("_tValue_") }")
					If '$G(tIsZVALz,0) {
						$$$PCIndent(pCompiler.Indent,"Catch ex { If (..#IGNOREMISSINGSOURCE&&($$$StatusText(ex.AsStatus())[""<INVALID OREF>"")) { Set tSC = $$$OK } Else { Set tSC=ex.AsStatus() } }")
					}		
					$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
				} Else {
					$$$PCIndent(pCompiler.Indent,$S($G(tIsZVALz):"If (Not tIgnore) Then",1:"Try")_" tSC="_tPropString_".Insert("_tValue_")")
					If '$G(tIsZVALz,0) {
						$$$PCIndent(pCompiler.Indent,"Catch ex")
						Do pCompiler.AddIndent()
						$$$PCIndent(pCompiler.Indent,"If ((Not Me.%GetParameter(""IGNOREMISSINGSOURCE"")) Or (0=InStr(System.Status.GetOneStatusText(ex.AsStatus()),""<INVALID OREF>""))) Then tSC=ex.AsStatus()")
						Do pCompiler.RemoveIndent()
						$$$PCIndent(pCompiler.Indent,"End Try")
					}
					$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Exit Do")
				}
			}
		} ElseIf ..Action="remove" {
			If ..Key="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithRemove)
			} Else {
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,"Do "_tPropString_".RemoveAt("_..Key_")")
				} Else {
					$$$PCIndent(pCompiler.Indent,""_tPropString_".RemoveAt("_..Key_")")
				}
			}
			
		} ElseIf ..Action="clear" {
			If ..Key'="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithClear)
				Quit
			} Else {
				If tLanguage=$$$objectscript {
					$$$PCIndent(pCompiler.Indent,"Set tSC="_tPropString_".Clear()")
					$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSC) Quit")
				} Else {
					$$$PCIndent(pCompiler.Indent,"tSC="_tPropString_".Clear()")
					$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSC) Then Exit Do")
				}
			}
		} Else {
			$$$ASSERT("0:No Default DTL Assign Action")
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
		Do pStream.Write("<assign ")
		Do pStream.Write("value="_$$$EA(..Value))
		Do pStream.Write("property="_$$$EA(..Property))
		Do pStream.Write("action="_$$$EA(..Action))

		If ..LanguageOverride'="" Do pStream.Write(" languageOverride="_$$$EA(..LanguageOverride))

		If ..Key'="""""" Do pStream.Write("key="_$$$EA(..Key))
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
						..Property _ ..#SDELIM _ 
						..Action _ ..#SDELIM _ 
						$S(..Key'="""""":..Key,1:"")  _ ..#SDELIM _ 
						$ZCVT(..Value,"I","HTML") _ $C(1))
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	
	Set ..Property = $P(pState,..#SDELIM,2)
	Set ..Action = $P(pState,..#SDELIM,3)
	Set ..Key = $P(pState,..#SDELIM,4)
	If (..Key = "") {
		#; handle missing key
		Set ..Key = """"""
	}
	Set ..Value = $P(pState,..#SDELIM,5,99999)
	Quit $$$OK
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	Set tSC=$$$OK
	Try {
		#; Must know the property we want to assign to
		If ..Property="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"property",..DisplayName()))
		}
		#; Must know the value, empty string shall be expressed as """"""
		If ..Value="" {
			If "|append|insert|set|"[("|"_..Action_"|") {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"value",..DisplayName()))
				Set pContext.IsFatal=1
			}
		}
		#; Key initial expression is """""""
		If ..Key="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"key",..DisplayName()))
		}
		
		#; Action initial expression is "set"
		If "|append|clear|insert|remove|set|"'[("|"_..Action_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLEnumeration,"action","append,clear,insert,remove,set",..DisplayName()))
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
	Quit "Assign"
}

}
