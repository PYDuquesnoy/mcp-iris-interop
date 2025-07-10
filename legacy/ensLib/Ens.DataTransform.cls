/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator Ensemble

/// This class provides the framework for encoding a series of operations which transform
/// a specified input type to a specfied output type
Class Ens.DataTransform Extends (%RegisteredObject, Ens.Util.FunctionSet) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

ClassMethod GetSourceType() As %String [ CodeMode = objectgenerator, GenerateAfter = Transform ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Find the first arg type of the Transform method for the current subclass
		Set tIndex = %compiledclass.Methods.FindObjectId(%class.Name_"||Transform")
		Set tFormalSpec = %compiledclass.Methods.GetAt(tIndex).FormalSpec
		Do %code.WriteLine(" Quit """_$P($P(tFormalSpec,",",1),":",2)_"""")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Return the virtual document type of the source document.
/// This is used by the Test Transform dialog to determine whether
/// the initial document should have a DocType assigned.
/// A return value of the empty string (i.e. "") indicates no DocType should be used.
ClassMethod GetSourceDocType() As %String
{
	Quit ""
}

ClassMethod GetTargetType(Output pCreate As %String) As %String [ CodeMode = objectgenerator, GenerateAfter = Transform ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Find the second arg type of the Transform method for the current subclass
		Set tIndex = %compiledclass.Methods.FindObjectId(%class.Name_"||Transform")
		Set tFormalSpec = %compiledclass.Methods.GetAt(tIndex).FormalSpec
		Do %code.WriteLine(" Set pCreate=""""")
		Do %code.WriteLine(" Quit """_$P($P(tFormalSpec,",",2),":",2)_"""")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Return the virtual document type of the target document.
/// This is used by the Test Transform dialog to determine whether
/// the document produced by the transform should have a DocType assigned.
/// A return value of the empty string (i.e. "") indicates no DocType should be used.
ClassMethod GetTargetDocType() As %String
{
	Quit ""
}

/* TransformMulti() removed - use multiple DTLs with create=existing option */
/// Transform an input object into an output object
ClassMethod Transform(source As %RegisteredObject, ByRef target As %RegisteredObject, ByRef aux) As %Status [ Abstract ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		$$$ASSERT("0:Subclass Responsibility")
		Set tSC = $$$EnsError($$$EnsErrNotImplemented,$$$CurrentClass,$$$CurrentMethod)
} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Instantiates intermediate objects, collections and collection elements on the pVarName path, but does not do collection elements at the final level. Use Action=insert for that.
/// Note: uses parallel construction to Ens.BPL.Transform.isProperty(); depends on pVarName having passed that test first.
/// See also Ens.DTL.Transform::getPropsArgs()
ClassMethod instantiateProps(pTopObj As %RegisteredObject, pVarName As %String, pVarArgs...) As %Boolean [ Internal ]
{
	Set numd=$L(pVarName,".")  Quit:numd<2 1
	// Shortcut for standard properties to see whether we can avoid work for previously swizzled properties
	If ('$data(pVarArgs)) && (pVarName=$TR(pVarName,"()")) && (numd > 2) {
		Set tSwizzled = 0
		Try {
			New %EnsTmpObj,%EnsIsObj
			Set %EnsTmpObj = pTopObj
			Set %EnsIsObj = 0
			Xecute "Set %EnsIsObj = $IsObject(%EnsTmpObj."_$P(pVarName,".",2,numd-1)_")"
			Set tSwizzled = $get(%EnsIsObj,0)
		}
		Catch {
			Set tSwizzled = 0
		}
		If tSwizzled Quit 1
	}
	#; loop over dot pieces
	Set $ZT="TrapIP", (dot,qc,pc,tLevel,iArgs)=0, pp=""
	#; variable names:d= dot piece index, dp= dot piece, q= quote piece index, qp= quote piece, qc= quote count, pp= parens piece, pc= parens count
	For d=1:1:numd { Set dp=$P(pVarName,".",d)
		#; remove delimited name if dot piece starts and ends with "
		If ($extract(dp,1) = """") && ($extract(dp,*) = """") Set dp = $extract(dp,2,*-1)
		#; loop over quote pieces
		Set numq=$L(dp,""""), qc=qc-1
		For q=1:1:numq { Set qp=$P(dp,"""",q)  Set qc=qc+1
			If qc#2=0 {
				#; quit if last piece
				If d=numd&&(q=numq) Set qc=-2  Quit
				If qp'=$TR(qp,"()") {
					#; has parens; balance them
					Set:'pc pd=d
					Set pc=pc+($L(qp)-$L($TR(qp,"(")))-($L(qp)-$L($TR(qp,")")))
					If pc<0 { Set qc=-1  Quit }
					ElseIf pc=0 {
						Set pp=pp_$S(d>pd&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
						new %val
						Set %val=tObj
						Set tFunc=$P(pp,"("), tArgs=$E(pp,$L(tFunc)+1,*)
						If ""=tFunc { Set tFunc=$Case(tArgs,"()":"Append","(-)":"GetPrevious("""")",:"GetAt")  Set:"GetAt"=tFunc iArgs=iArgs+1  Set pp=tFunc_$S("(-)"=tArgs:"", $D(pVarArgs(iArgs))#2:"("_pVarArgs(iArgs)_")", 1:tArgs) }
						ElseIf "()"'=tArgs { Set iArgs=iArgs+1  Set:$D(pVarArgs(iArgs))#2 pp=tFunc_"("_pVarArgs(iArgs)_")" }
						If "Append"'=tFunc { Xecute "Set %val=%val."_pp }
						Else { Set %val=$$$NULLOREF }
						If '$IsObject(%val) {
							#; note: No GetPrevious("") support here; it should have been Xecuted successfully already; if not it will trap out
							If $Case(tFunc,"GetAt":0, "Append":0, :1)  Set qc=-1  Quit ; Not a GetAt() or Append() collection accessor
							#; Get key and set new element at that key
							If "()"=tArgs { Set %val="" }
							Else {
								If $D(pVarArgs(iArgs))#2 { Set %val=pVarArgs(iArgs) }
								Else { Xecute "Set %val="_tArgs }
							}
							Set tElem=$classmethod(tObj.ElementType,"%New")
							If tObj.%Extends("%Collection.AbstractListOfObj") {
								Do $Case(tArgs,"()":tObj.Insert(tElem), :tObj.InsertAt(tElem,%val))
							} Else {
								Do tObj.SetAt(tElem,%val)
							}
							Set %val=tElem
						}
						Set tObj=%val  Kill %val
						Set pp=""
					}
				} ElseIf 'pc {
					If 0=tLevel { Set tObj=pTopObj }
					Else {
						Set tVal=$property(tObj,qp)
						Set:$$$NULLOREF=tVal tVal=$method(tObj,qp_"NewObject")
						Set tObj=tVal
					}
				}
				Set tLevel=tLevel+1
			}
			If pc { Set pp=pp_$S(d>pd&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp }
		}
		Quit:qc<0
		Set:qc#2=0&&(d<numd) dot=1
	}
	Quit:qc#2 0 ; unbalanced quotes -or- not a simple property
	Quit dot ; found dot not quoted
TrapIP
	Quit 0 ; exception - unable to instantiate all
}

}
