/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsErrors

/// The syntax specifies a target property and an expression that will be 
/// assigned to it:-
/// 
/// <assign property="name" value="expression" />
/// 
/// Assignments ALWAYS have accessible to them certain intrinsic objects which are part
/// of the execution environment. These are the context, process, request,response, status, 
/// synctimedout, synchronizedresponses etc. as well as other objects
/// which refer to the corresponding properties in the business process object. When an
/// assignment is performed in the context of a call (defined by the <call> tag in BPL), the
/// callrequest and callresponse object refer to the CURRENT request or response.
/// 
/// Note: when in a <request> tag, the callresponse object is undefined, when in a <response> tag, the
/// callrequest object is undefined
/// 
/// Assignments can also specify the 'action' attribute which determines how the assignment
/// is performed. Legal values for the 'action' attribute are:- Append,Clear, Insert,Remove and Set.
/// If this attribute is not specified, the default value is 'Set'. Append,Clear, Insert and Remove
/// are only applicable when the property being accessed is a collection of type 'list' or 'array'.
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
Class Ens.BPL.Assign Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// 'property' and 'value' attributes are both required
XData Example
{
<assign property="callrequest.Location" value="request.Location"/>
}

/// This holds the name of the target object
Property Property As %String;

/// This holds the value to assign to the property
Property Value As %String;

/// This holds the type of the assignment
Property Action As %String [ InitialExpression = "set" ];

/// This holds the ( optional ) key  used for certain types of assignment operations
/// on properties which are collections  (array or list)
Property Key As %String [ InitialExpression = """""" ];

/// Generate the code corresponding to this Activity
Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	Do {
		If ..Disabled Quit
		
		/// Default to emitting object when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Process.Language)
		/// Default override to Python if specified for Process.Language

		Set tActivityLanguageOverride = ..LanguageOverride
		If (tActivityLanguageOverride = "") {
			/// Examine if an assign for a BPL Request/Response within a Call and use that language override
			Try {
				If ..Parent.%IsA("Ens.BPL.Request") || ..Parent.%IsA("Ens.BPL.Response") {
					If ..Parent.Parent.%IsA("Ens.BPL.Call") Set tActivityLanguageOverride=$$$shapeOtherwiseProcessLanguage(..Parent.Parent.LanguageOverride,pCompiler.Process.Language)
				}
			} Catch { Set tActivityLanguageOverride = ""}
		}

		Set tLanguageOverride=$$$shapeOtherwiseProcessLanguage(tActivityLanguageOverride,pCompiler.Process.Language)
		
		$$$EnterActivity($$$ActivityAssign,$$$SubActivityMain)

		#; This activity supports the VDOC syntax
		// Allows for a litteral VDOC expression to be expanded, even if using Python Override
		// Assumes ".{" is not found in valid Python 
		Set tValue=..Value, tSC=##class(Ens.VDoc.Utils).GetSetCode(.tCode,.tComplete,..Property, tValue,..Action, ..Key, tLanguage, 0)  Quit:$$$ISERR(tSC) 
		If (tComplete) {
			$$$GC(tCode)
			Quit
		}
		Set ..Property = ##class(Ens.VDoc.Utils).GetGetCode(..Property,tLanguage)

		if tLanguageOverride=$$$python {
			// For Python expression, generates new Method on Thread that implements the expression
			// Set tValue to invocation signature "..SomeMethod(..., ...)
			set tValue=pCompiler.GeneratePyExec(..Value,"BPLShape:Assign:",tLanguage)
		} else {
			Set tValue=##class(Ens.VDoc.Utils).GetGetCode(tValue,tLanguage)
		}

		#; Test in anticipated order of frequency
		Set tPropString=..Property
		If $Case(..Action,"set":1,"insert":1,"append":1,:0) {
			If ##class(Ens.BPL.Transform).isProperty(tPropString,.nDots) {
				/* clone object values being assigned
				If ##class(Ens.BPL.Transform).isProperty(tValue) {
					If tLanguage=$$$objectscript {
						$$$GC(" Set zVALz="_tValue_", zVALz=$S($IsObject(zVALz):zVALz.%ConstructClone(), 1:zVALz)")
					} Else {
						$$$GC("   zVALz="_tValue_$C(13,10)_"    If IsObject(zVALz) Then zVALz=zVALz.%ConstructClone()")
					}
					Set tValue="zVALz"
				}
				*/
				If nDots>1 {
					If tLanguage=$$$objectscript {
						$$$GC(" Do ##class(Ens.DataTransform).instantiateProps("_$P(tPropString,".")_","""_tPropString_""""_##class(Ens.DTL.Transform).getPropsArgs(tPropString)_")")
					} Else {
						$$$GC(" ""Ens.DataTransform"".instantiateProps("_$P(tPropString,".")_","""_tPropString_""""_##class(Ens.DTL.Transform).getPropsArgs(tPropString)_")")
					}
					Set tPropString=##class(Ens.DTL.Transform).decoratePropString(tPropString)
				}
			}
		}
		If ..Action="set" { 
			If ..Key="""""" {
				#; Assume a non-collection assignment
				If tLanguage=$$$objectscript {	
					$$$GC(" Set status=$$$OK,"_tPropString_"="_tValue)
					$$$GC(" If $$$ISERR(status) Quit")
				} Else {
					$$$GC("   status=System.Status.OK() : "_tPropString_"="_tValue)
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
				} 
			} Else {
				#; Collection
				If tLanguage=$$$objectscript {
					$$$GC(" Set status="_tPropString_".SetAt("_tValue_","_..Key_")")
					$$$GC(" If $$$ISERR(status) Quit")
				} Else {
					$$$GC("   status="_tPropString_".SetAt("_tValue_","_..Key_")")
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
				}
			}
		} ElseIf ..Action="insert" {
			If ..Key="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithInsert)
			} Else {
				If tLanguage=$$$objectscript {
					$$$GC(" Set status="_tPropString_".InsertAt("_tValue_","_..Key_")")
					$$$GC(" If $$$ISERR(status) Quit")
				} Else {
					$$$GC("   status="_tPropString_".InsertAt("_tValue_","_..Key_")")
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
				}
			}
			
		} ElseIf ..Action="append" {
			If ..Key'="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithAppend)
			} Else {
				If tLanguage=$$$objectscript {
					$$$GC(" Set status="_tPropString_".Insert("_tValue_")")
					$$$GC(" If $$$ISERR(status) Quit")
				} Else {
					$$$GC("   status="_tPropString_".Insert("_tValue_")")
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
				}
			}
		} ElseIf ..Action="remove" {
			If ..Key="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithRemove)
			} Else {
				If tLanguage=$$$objectscript {
					$$$GC(" Do "_..Property_".RemoveAt("_..Key_")")
				} Else {
					$$$GC("   "_..Property_".RemoveAt("_..Key_")")
				}
			}
			
		} ElseIf ..Action="clear" {
			If ..Key'="""""" {
				Set tSC=$$$ERROR($$$EnsErrKeyWithClear)
				Quit
			} Else {
				If tLanguage=$$$objectscript {
					$$$GC(" Set status="_..Property_".Clear()")
					$$$GC(" If $$$ISERR(status) Quit")
				} Else {
					$$$GC("   status="_..Property_".Clear()")
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
				}
			}
		} Else {
			$$$ASSERT("0:No Default BPL Assign Action")
		}
		$$$LeaveActivity($$$ActivityAssign,$$$SubActivityMain)
	} While 0
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Generate the XML corresponding to this Activity definition
Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<assign ")
		
		If ..Name'="" Do pStream.Write("name="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..Name)_""" ")
		
		Do pStream.Write("property="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..Property)_""" ")
		Do pStream.Write("value="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..Value)_""" ")
		Do pStream.Write("action="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..Action)_""" ")
		Do pStream.Write("languageOverride="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..LanguageOverride)_""" ")
		If ..Key'="""""" Do pStream.Write("key="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..Key)_""" ")
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</assign>")
		} Else {
			Do pStream.WriteLine("/>")
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Must know the property we want to assign to
		If ..Property="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"property",..DisplayName()))
		}
		#; Must know the value, empty string shall be expressed as """"""
		If ..Value="" {
			If "|append|insert|set|"[("|"_..Action_"|") {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"value",..DisplayName()))
			}
		}
		#; Key initial expression is """""""
		If ..Key="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"key",..DisplayName()))
		}
		
		#; Action initial expression is "set"
		If "|append|clear|insert|remove|set|"'[("|"_..Action_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLEnumeration,"action","append,clear,insert,remove,set",..DisplayName()))
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	Quit "Assign"
}

}
