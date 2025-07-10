/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <transform> element lets you invoke a data transformation class from within a business process.
Class Ens.BPL.Transform Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<transform class="Demo.Transform" source="request" target="context.tranformed"/>
}

/// The class name of the data transform
Property Class As %String;

/// The name of the source object
Property Source As %String;

/// The name of the target object
Property Target As %String;

/// The name of the auxiliary value passed to the Transform() method
Property Aux As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	Set tClass=..Class
	Set tClass=$s($e(tClass)="@":$e(tClass,2,$l(tClass)),1:""""_tClass_"""")
	Set tAux=..Aux  Set:""=tAux tAux=""""""
	Do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
			
		$$$EnterActivity($$$ActivityTransform,$$$SubActivityMain)
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set iscTemp=" _ $S(..isProperty(..Target):..Target, 1:"$G("_..Target_")"))
			$$$GC(" Set status=$classmethod("_tClass_",""Transform"","_..Source_",.iscTemp,"_tAux_")")
			$$$GC(" If $$$ISERR(status) Quit")
			$$$GC(" Set "_..Target_"=iscTemp")
		} Else {
			#; TODO: CacheBasic does not support dispatching with classname in a variable
			$$$GC("   iscTemp="_..Target)
			$$$GC("   status="""_..Class_""".Transform("_..Source_",iscTemp,"_tAux_")")
			$$$GC("   If System.Status.IsError(status) Then Exit Do")
			$$$GC("   "_..Target_"=iscTemp")
		}
		$$$LeaveActivity($$$ActivityTransform,$$$SubActivityMain)
	} While (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<transform ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("class="_$$$EA(..Class)_"source="_$$$EA(..Source)_"target="_$$$EA(..Target)_$Case(..Aux,"":"","""""":"",:"aux="_$$$EA(..Aux)))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</transform>")
		} else {
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
		If ..Class="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"class",..DisplayName()))
		}
		#; Must know the value, empty string shall be expressed as """"""
		If ..Source="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"source",..DisplayName()))
		}
		#; Key initial expression is """""""
		If ..Target="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"target",..DisplayName()))
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
	Quit "Transform"
}

/// determine at compile time if a string represents a property name for the purpose of: </br>
/// - not applying $G() to avoid a syntax error </br>
/// - applying conditional %ConstructClone() in DTL if a source object property </br>
/// - applying conditional %New() in DTL if a target object property
ClassMethod isProperty(pVarName As %String, Output nDots As %Integer, Output pIsTrailingArray As %Integer) As %Boolean
{
	Set numd=$L(pVarName,".")
	#; loop over dot pieces
	Set (ng,qc,nDots,pIsTrailingArray)=0
	Quit:numd<2 0
	For d=1:1:numd {
		Set dp=$p(pVarName,".",d)
		#; check for parenthesis if not already inside quotes
		If (qc#2=0) && ("(" = $extract(dp,1)) { ;could be trailing array
			#; Check for balanced parens
			Set parenDepth = 0
			Set trailString = $P(pVarName,".",d,*)
			While (trailString '= "") {
				Set openPos = $find(trailString,"(")
				Set closePos = $find(trailString,")")
				Set quotePos = $find(trailString,"""")
				If (openPos && closePos) {
					If quotePos && (quotePos < openPos) && (quotePos < closePos) {
						#; Check for balanced quotes and skip over anything in quotes
						If $L(trailString,"""") >= 3 {
							Set trailString = $P(trailString,"""",3,*)
						} Else { ;Unbalanced quotes
							Set ng = 1
							Quit
						}
					} ElseIf (openPos < closePos) {
						Set parenDepth = parenDepth + 1
						Set trailString = $E(trailString,openPos,*)
					} Else {
						Set parenDepth = parenDepth - 1
						Set trailString = $E(trailString,closePos,*)
					}
				}
				ElseIf (openPos) {
					If quotePos && (quotePos < openPos) {
						#; Check for balanced quotes and skip over anything in quotes
						If $L(trailString,"""") >= 3 {
							Set trailString = $P(trailString,"""",3,*)
						} Else { ;Unbalanced quotes
							Set ng = 1
							Quit
						}
					} Else {
						Set parenDepth = parenDepth + 1
						Set trailString = $E(trailString,openPos,*)
					}
				} ElseIf (closePos) {
					If quotePos && (quotePos < closePos) {
						#; Check for balanced quotes and skip over anything in quotes
						If $L(trailString,"""") >= 3 {
							Set trailString = $P(trailString,"""",3,*)
						} Else { ;Unbalanced quotes
							Set ng = 1
							Quit
						}
					} Else {
						Set parenDepth = parenDepth - 1
						Set trailString = $E(trailString,closePos,*)
					}
				} Else {
					Quit
				}
				Quit:parenDepth=0
			}
			If parenDepth { ;parens not balanced
				Set ng = 1
				Quit
			}
			Set d = d + $l($P(pVarName,".",d,*),".") - $l(trailString,".") ;skip over dot pieces that were inside parens
			If ((trailString = "") && (parenDepth = 0)) {
				Set (pIsTrailingArray,ng) = 1
				Quit
			}
			If "."'=$E(trailString) {
				#; Text between dots is more than what's enclosed by the parens
				Set ng = 1
				Quit
			}
		} Else {
			#; Loop over quote pieces
			Set numq=$L(dp,"""") , qc=qc-1
			For q=1:1:numq {
				Set qp=$p(dp,"""",q), qc=qc+1
				If qc#2=0 {
					#; Abort if fragment contains non-identifier characters outside quotes
					If ($E(qp,2,*)["%") || (qp'=$TR(qp,"^+-='_*/\#$&|,![]{}()")) {
						Set ng = 1
						Quit
					}
				}
			}
		}
		Quit:ng
		Set:(qc#2=0)&&(d<numd) nDots=nDots+1
	}
	Quit:ng 0 ; "no good" (maybe just not a simple property)
	Quit:qc#2 0 ; unbalanced quotes
	Quit (nDots>0) ; found dot not quoted
}

}
