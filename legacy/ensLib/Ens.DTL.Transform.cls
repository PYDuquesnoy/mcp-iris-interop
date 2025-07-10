/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents the data transform specification. It is the root
/// node of the parse tree derived from the XDATA DTL Specification defined
/// in the DataTransformation class
Class Ens.DTL.Transform Extends (Ens.DTL.Action, Ens.Util.PortalModelBase) [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the language of the class
Property Language As %String [ InitialExpression = {$$$objectscript} ];

/// This holds the type of the source object
Property SourceClass As %String(MAXLEN = 128) [ Required ];

/// This holds the type of the target object
Property TargetClass As %String(MAXLEN = 128) [ Required ];

/// This determines how the new target object should be created.
Property Create As %String(MAXLEN = 20, VALUELIST = ",new,copy,existing") [ InitialExpression = "new", Required ];

/// This holds the optional document type of the source object
Property SourceDocType As %String(MAXLEN = 128);

/// This holds the optional document type of the target object
Property TargetDocType As %String(MAXLEN = 128);

Property pyFromImport As %VarString;

/// This holds the value of the REPORTERRORS parameter so it can be edited in the UI
Property ReportErrors As %String [ InitialExpression = 1 ];

/// This holds the value of the IGNOREMISSINGSOURCE parameter so it can be edited in the UI
Property IgnoreMissingSource As %String [ InitialExpression = 1 ];

/// This holds the value of the TREATEMPTYREPEATINGFIELDASNULL parameter so it can be edited in the UI
Property TreatEmptyAsNull As %Boolean [ InitialExpression = 0 ];

/// This holds the value of the GENERATEEMPTYSEGMENTS parameter so it can be edited in the UI
Property GenerateEmptySegments As %String [ InitialExpression = 0 ];

/// This holds the actions to be performed on the arguments
Property Actions As Ens.DTL.ActionList;

/// Disabled can not be set for a transform.
Method DisabledSet(pVal As %Boolean) As %Status [ CodeMode = expression ]
{
$$$OK
}

Method ExpandedSet(pVal As %Boolean) As %Status [ CodeMode = expression ]
{
$$$OK
}

/// Expanded can not be set for a transform.
Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap", tSC=$$$OK
	Do {
		Do pStream.Write("<transform sourceClass="_$$$EA(..SourceClass)_"targetClass="_$$$EA(..TargetClass))

		If (..SourceDocType '= "") {
			Do pStream.Write("sourceDocType="_$$$EA(..SourceDocType))
		}
		If (..TargetDocType '= "") {
			Do pStream.Write("targetDocType="_$$$EA(..TargetDocType))
		}
		If (..Create '= "") {
			Do pStream.Write("create="_$$$EA(..Create))
		}
		Do pStream.WriteLine("language="_$$$EA(..Language)_">")

		If ..Annotation'="" {
			Do pStream.Write("<annotation>")
			Do pStream.Write($ZCVT(..Annotation,"O","HTML"))
			Do pStream.WriteLine("</annotation>")
		}

		If ..pyFromImport'="" {
			Do pStream.Write("<pyFromImport>")
			Do pStream.Write($ZCVT(..pyFromImport,"O","HTML"))
			Do pStream.WriteLine("</pyFromImport>")
		}

		Set tSC=..Actions.GenerateXML(pStream, ..Language )
		If $$$ISERR(tSC) Quit

		Do pStream.WriteLine("</transform>")

	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="", tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC=$$$OK
	#dim tSourceDocType, tTargetDocType
	Try {
		try {
			Set tExtends=$classmethod(..SourceClass,"%Extends","%RegisteredObject")
		} catch {
			Set tSC=$$$ERROR($$$GeneralError,"Error with source class '"_..SourceClass_"': "_$ZE)
		} Quit:$$$ISERR(tSC)
		try {
			Set tExtends=$classmethod(..TargetClass,"%Extends","%RegisteredObject")
		} catch {
			Set tSC=$$$ERROR($$$GeneralError,"Error with target class '"_..TargetClass_"': "_$ZE)
		} Quit:$$$ISERR(tSC)

		Set tSourceIsVDoc = ##class(Ens.VDoc.Utils).IsVirtualDocument(..SourceClass)
		Set tTargetIsVDoc = ##class(Ens.VDoc.Utils).IsVirtualDocument(..TargetClass)

		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(..Language)

		If tLanguage=$$$objectscript {
			$$$PCIndent(pCompiler.Indent,"Set (tSC,tSCTrans,tSCGet)=$$$OK,$ZE=""""")
			$$$PCIndent(pCompiler.Indent,"Try {")
			Do pCompiler.AddIndent()

			#; Test for source object exists
			If (..Create = "copy") {
				$$$PCIndent(pCompiler.Indent,"If '$IsObject(source) Set tSC=$$$ERROR($$$GeneralError,""No source object"") Quit")
			}
			// If no doc type on incoming source object, set doc type for source equal to the transform's declared source DocType
			If tSourceIsVDoc && (""'=..SourceDocType) {
				Set tSourceDocType = ..primaryDocType(..SourceDocType)
				$$$PCIndent(pCompiler.Indent,"Set:""""=source.DocType tBlankSrc=1, source.DocType="""_tSourceDocType_"""")
			}
			// create target object
			If (..Create = "copy") {
				If '$classmethod(..SourceClass,"%Extends",..TargetClass) Set tSC=$$$ERROR($$$GeneralError,"Target class '"_..TargetClass_"' of cannot be created by copying a source object of class "_..SourceClass) Quit
				$$$PCIndent(pCompiler.Indent,"Set target = source.%ConstructClone(1)")
				$$$PCIndent(pCompiler.Indent,"If '$IsObject(target) Set tSC=%objlasterror Quit")
			} ElseIf (..Create = "new") {
				$$$PCIndent(pCompiler.Indent,"Set target = ##class("_..TargetClass_").%New()")
				$$$PCIndent(pCompiler.Indent,"If '$IsObject(target) Set tSC=%objlasterror Quit")
			} Else {
				$$$PCIndent(pCompiler.Indent,"If '$IsObject($G(target)) Set tSC=$$$ERROR($$$GeneralError,""No existing target object"") Quit")
				$$$PCIndent(pCompiler.Indent,"If 'target.%Extends("""_..TargetClass_""") Set tSC=$$$ERROR($$$GeneralError,""Class '"_..TargetClass_"' of existing target object is not derived from declared target class "_..TargetClass_""") Quit")
			}
			$$$PCIndent(pCompiler.Indent,"$$$catTRACE(""xform"",""transform from source ""_source_$S(source.%Extends(""%Persistent""):""/""_source.%Id(),1:"""")_"" to target ""_target_$S(target.%Extends(""%Persistent""):""/""_target.%Id(),1:"""")_"""")")

			// Set DocType for target
			If (tTargetIsVDoc) {
				Set tTargetDocType = ..primaryDocType(..TargetDocType)
				If (..Create = "existing") {
					$$$PCIndent(pCompiler.Indent,"Set:""""=target.DocType target.DocType = """_tTargetDocType_"""")
				} ElseIf (..Create = "new") {
					$$$PCIndent(pCompiler.Indent,"Do target.PokeDocType("""_tTargetDocType_""")")
					If $classmethod(..TargetClass,"%Extends","EnsLib.EDI.Segment") {
						$$$PCIndent(pCompiler.Indent,"Do target.SetValueAt($P(target.DocTypeName,""-""),0)")
					}
				} Else {
					$$$PCIndent(pCompiler.Indent,"Set target.DocType = """_tTargetDocType_"""")
				}
				// Set separators for target document if EDI document of same type as source document
				If tSourceIsVDoc && (..Create'="copy")
				 && ($classmethod(..SourceClass,"%Extends","EnsLib.EDI.Segmented")
				  || $classmethod(..SourceClass,"%Extends","EnsLib.EDI.Segment"))
				 && ($classmethod(..TargetClass,"%Extends",..SourceClass)
				  || $classmethod(..SourceClass,"%Extends",..TargetClass)) {
					$$$PCIndent(pCompiler.Indent,"Set target.Separators = source.Separators ; make sure multi-field assigns work properly by default")
				}
			}
		} Else { ; ..Language=$$$basic
			$$$PCIndent(pCompiler.Indent,"On Error Goto Trap : tSC=System.Status.OK() : tSCTrans=System.Status.OK() : tSCGet=System.Status.OK() : Do")
			Do pCompiler.AddIndent()

			If (..Create = "copy") {
				$$$PCIndent(pCompiler.Indent,"If Not IsObject(source) Then tSC=System.Status.Error(5001,""No source object"") : Exit Do")
			}
			// If no doc type on incoming source object, set doc type for source equal to the transform's declared source DocType
			If tSourceIsVDoc && (""'=..SourceDocType) {
				Set tSourceDocType = ..primaryDocType(..SourceDocType)
				$$$PCIndent(pCompiler.Indent,"If (source.DocType = """") Then tBlankSrc=1 : source.DocType="""_tSourceDocType_""" Else tBlankSrc=0")
			}
			// create target object
			If (..Create = "copy") {
				If '$classmethod(..SourceClass,"%Extends",..TargetClass) Set tSC=$$$ERROR($$$GeneralError,"Target class '"_..TargetClass_"' of cannot be created by copying a source object of class "_..SourceClass) Quit
				$$$PCIndent(pCompiler.Indent,"target = source.%ConstructClone(1)")
				$$$PCIndent(pCompiler.Indent,"If Not IsObject(target) Then tSC=%objlasterror : Exit Do")
			} ElseIf (..Create = "new") {
				$$$PCIndent(pCompiler.Indent,"target="""_..TargetClass_""".%New()")
				$$$PCIndent(pCompiler.Indent,"If Not IsObject(target) Then tSC=%objlasterror : Exit Do")
			} Else {
				$$$PCIndent(pCompiler.Indent,"If Not IsObject(target) Then tSC=System.Status.Error(5001,""No existing target object"") : Exit Do")
				$$$PCIndent(pCompiler.Indent,"If Not target.%Extends("""_..TargetClass_""") Then tSC=System.Status.Error(5001,""Class "_..TargetClass_" of existing target object is not derived from declared target class "_..TargetClass_""") : Exit Do")
			}
			// Set DocType for target
			If (tTargetIsVDoc) {
				Set tTargetDocType = ..primaryDocType(..TargetDocType)
				If (..Create = "existing") {
					$$$PCIndent(pCompiler.Indent,"If target.DocType="""" Then target.DocType = """_tTargetDocType_"""")
				} ElseIf (..Create = "new") {
					$$$PCIndent(pCompiler.Indent,"target.PokeDocType("""_tTargetDocType_""")")
					If $classmethod(..TargetClass,"%Extends","EnsLib.EDI.Segment") {
						$$$PCIndent(pCompiler.Indent,"target.SetValueAt(Piece(target.DocTypeName,""-""),0)")
					}
				} Else {
					$$$PCIndent(pCompiler.Indent,"target.DocType = """_tTargetDocType_"""")
				}
				// Set separators for target if EDI document
				If tSourceIsVDoc && (..Create'="copy")
				 && ($classmethod(..SourceClass,"%Extends","EnsLib.EDI.Segmented")
				  || $classmethod(..SourceClass,"%Extends","EnsLib.EDI.Segment"))
				 && ($classmethod(..TargetClass,"%Extends",..SourceClass)
				  || $classmethod(..SourceClass,"%Extends",..TargetClass)) {
					$$$PCIndent(pCompiler.Indent,"target.Separators = source.Separators  ' make sure multi-field assigns work properly by default")
				}
			}
		}
		Set tSC=..Actions.GenerateCode(pCompiler)
		Quit:$$$ISERR(tSC)

		If tLanguage=$$$objectscript {
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,"} Catch thrownErr {")
			Do pCompiler.AddIndent()
			$$$PCIndent(pCompiler.Indent,"If $ZE="""" {")
			Do pCompiler.AddIndent()
			$$$PCIndent(pCompiler.Indent,"Set tSC=thrownErr.AsStatus()")
			$$$PCIndent(pCompiler.Indent,"$$$LOGSTATUS(tSC)")
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,"} Else {")
			Do pCompiler.AddIndent()
			$$$PCIndent(pCompiler.Indent,"Set tSC=$$$EnsSystemError")
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,"}")
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,"}")
			If $$$GetClassParameter(%compiledclass.Name,"REPORTERRORS") {
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSCTrans) $$$LOGSTATUS(tSCTrans)  Quit:$$$ISOK(tSC) tSCTrans")
			} Else {
				$$$PCIndent(pCompiler.Indent,"If $$$ISERR(tSCTrans) $$$catTRACE(""xform"",""Transform error: ""_$$$StatusDisplayString(tSCTrans))")
			}
			If tSourceIsVDoc && (""'=..SourceDocType) {
				$$$PCIndent(pCompiler.Indent,"Set:$G(tBlankSrc) source.DocType=""""")
			}
			$$$PCIndent(pCompiler.Indent,"Quit tSC")
		} Else {
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,"Loop While 0")
			If tSourceIsVDoc && (""'=..SourceDocType) {
				$$$PCIndent(pCompiler.Indent,"Exit: If tBlankSrc Then source.DocType=""""")
			} Else {
				$$$PCIndent(pCompiler.Indent,"Exit:")
			}
			Do pCompiler.AddIndent()
			If $$$GetClassParameter(%compiledclass.Name,"REPORTERRORS") {
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSCTrans) Then")
				Do pCompiler.AddIndent()
				$$$PCIndent(pCompiler.Indent,"""Ens.Util.Log"".LogStatus("""_pCompiler.ClassName_""",""Transform"",tSCTrans)")
				$$$PCIndent(pCompiler.Indent,"If (Not System.Status.IsError(tSC)) Then Return tSCTrans")
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"End If")
			} Else {
				$$$PCIndent(pCompiler.Indent,"If System.Status.IsError(tSCTrans) Then ""Ens.Util.Trace"".WriteTrace(""xform"","""_pCompiler.ClassName_""",""Transform"",""Transform error: ""&System.Status.GetErrorText(tSCTrans,""basic""))")
			}

			$$$PCIndent(pCompiler.Indent,"Return tSC")
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,"Trap: On Error Goto 0 : tSC=""Ens.Util.Error"".EnsSystemError("""_pCompiler.ClassName_""",""Transform"") : Goto Exit")
		}

		#; Fix up the language keyword for the method implementation
		If tLanguage=$$$objectscript {
			Set pCompiler.Implementation.Language=$$$cCLASSLANGUAGEOBJECTSCRIPT
		} Else {
			Set pCompiler.Implementation.Language=$$$cCLASSLANGUAGEBASIC
		}
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Serialize this transform for use by DTL editor
Method Serialize(pStream As %CharacterStream) As %Status
{
	Do pStream.Write(..%ClassName() _ ..#SDELIM _ 
						..Language _ ..#SDELIM _ 
						..SourceClass _ ..#SDELIM _
						..TargetClass)

	// be clever about SourceType and TargetType to keep older Studios compatible
	If ((..SourceDocType'="") || (..TargetDocType'="")) {
		Do pStream.Write(..#SDELIM _
						..SourceDocType _ ..#SDELIM _
						..TargetDocType)
	}
	Do pStream.Write($C(1))

	For i = 1:1:..Actions.Count() {
		Do ..Actions.GetAt(i).Serialize(pStream)
	}

	Quit $$$OK
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	Set ..Language = $P(pState,..#SDELIM,2)
	Set ..SourceClass = $P(pState,..#SDELIM,3)
	Set ..TargetClass = $P(pState,..#SDELIM,4)
	Set ..SourceDocType = $P(pState,..#SDELIM,5)
	Set ..TargetDocType = $P(pState,..#SDELIM,6)
	Quit $$$OK
}

/// add implicit GetAt() / GetPrevious() names explicitly to match what instantiateProps() supports.
ClassMethod decoratePropString(pVarName As %String) As %String
{
	Set numd=$L(pVarName,".")  Quit:numd<2 pVarName
	#; variable names:d= dot piece index, dp= dot piece, q= quote piece index, qp= quote piece, qc= quote count, pp= parens piece, pc= parens count, pd= parens dot
	Set (dot,qc,pc,ppDotStart)=0, (pp,tNew)=""
	#; Used to record which .( are in quotes and ought not to be expanded.
	#dim dotParenInQuotes = 0
	#; loop over dot pieces
	For d=1:1:numd { Set dp=$P(pVarName,".",d)
		#; loop over quote pieces
		Set numq=$L(dp,""""), qc=qc-1
		For q=1:1:numq { Set qp=$P(dp,"""",q)  Set qc=qc+1
			Set addQP=1
			If qc#2=0 {
				#; quit if last piece
				If d=numd&&(q=numq)&&($E(qp)'="(") {
					Set qc=-2
					If ppDotStart&&$L(pp)&&$L(tNew) Set pp="."_pp
					Set tNew=tNew_pp_$S(d>1&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
					Quit
				}
				If qp'=$TR(qp,"()") {
					#; has parens; balance them
					Set:'pc pd=d
					Set pcInner = ($L(qp)-$L($TR(qp,"(")))-($L(qp)-$L($TR(qp,")")))
					Set pc=pc+pcInner
					If pc<0 { Set qc=-1, tNew=""  Quit }
					If ('pc)||(('pcInner)) {
						Set addQP=0
						If pp="" Set ppDotStart=(q=1)
						If pc { ; inner braces balanced
							Set tFunc=$P(qp,"("), tArgs=$E(qp,$L(tFunc)+1,*)
							Set tStart=pp_$S(d>pd&&(q=1):".",1:"")_$S(q>1:"""",1:"")
						}
						Else {
							Set pp=pp_$S(d>pd&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
							Set tFunc=$P(pp,"("), tArgs=$E(pp,$L(tFunc)+1,*)
							Set tStart=""
						}
						If ""=tFunc||("Append()"=pp) {
							Set tFunc=$Case(tArgs,"()":"Append","(-)":"GetPrevious("""")",:"GetAt")
							If "(-)"=tArgs Set tArgs=""
							If ("Append"=tFunc)&&("()"=tArgs) Set tFunc="GetPrevious",tArgs="("""")"
						}
						Set pp=tStart_tFunc_tArgs
						If 'pc {
							If ppDotStart&&$L(tNew)&&$L(pp) Set pp="."_pp
							Set tNew=tNew_pp
							Set (pp,qp)=""
						}
					}
				}
			} Else {
				#; Record those .( we identify as being in quotes based on dot position
				If (q=1) && ($E(qp)="(") {
					Set dotParenInQuotes(d)=""
					If $I(dotParenInQuotes) {}
				}
			}
			If addQP { ; we still need to add qp
				If pc { 
					If pp="" Set ppDotStart=(q=1)
					Set pp=pp_$S(d>pd&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
				}
				Else { Set tNew=tNew_$S(d>1&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp }
			}
		}
		Quit:qc<0
	}
	Quit:qc<0&&'$L(tNew) pVarName ; not a simple property
	Quit:qc>0&&(qc#2) pVarName ; unbalanced quotes

	#; Check again for any shortened .( not in quotes that might not have been expanded
	If (tNew[".(") && ((dotParenInQuotes)'=($L(tNew,".(")-1)){
		Quit ..redecoratePropString(tNew,.dotParenInQuotes)
	}
	Quit tNew
}

/// Add implicit GetAt() / GetPrevious() names explicitly where implicit not in quotes.
/// Called by decoratePropString
ClassMethod redecoratePropString(pValueString As %String, ByRef pDotParenInQuotes) As %String [ Internal ]
{
	#dim tRedecoratedValueString As %String = ""

	If '$D(pDotParenInQuotes)#2 {

		#; We can do global replace
		Set tRedecoratedValueString = $Replace(pValueString,".(-)",".GetPrevious("""")")
		Set tRedecoratedValueString = $Replace(tRedecoratedValueString,".(",".GetAt(")

	} Else {
		#; Need to replace those .( not in quotes
		/*
			Example:
			tNew = ..Pad(source.Observations.GetAt(k1).Results.(k2),20)_target.Observations.GetAt(k1).Results.GetAt(k2).Schluessel_"_.("_##class(v4hProduction.HL7.Transformations.UserDefinedFunctions).HL7Unescape(source.GetValueAt("PIDgrpgrp("_(1)_").ORCgrp("_(k1)_").SPMgrp("_(1)_").SPM:SpecimenType.Identifier"),source)_")" 
			What Ought to be = ..Pad(source.Observations.GetAt(k1).Results.GetAt(k2),20)_target.Observations.GetAt(k1).Results.GetAt(k2).Schluessel_"_.("_##class(v4hProduction.HL7.Transformations.UserDefinedFunctions).HL7Unescape(source.GetValueAt("PIDgrpgrp("_(1)_").ORCgrp("_(k1)_").SPMgrp("_(1)_").SPM:SpecimenType.Identifier"),source)_")"
			Which ones we need to skip:
				dotParenInQuotes=1
				dotParenInQuotes(13)=""
		*/
		#dim d,dp,numd
		Set numd=$L(pValueString,".")
		#; loop over dot pieces looking for ( as start but skipping those in dotParenInQuotes
		For d=1:1:numd {
			Set dp=$P(pValueString,".",d)
			
			If $Data(pDotParenInQuotes(d))#2 {
				#; This .( is in quotes so don't expand
				Set tRedecoratedValueString=tRedecoratedValueString_dp_$S((d'=numd):".",1:"")
				Continue
			}
			If $E(dp,1,3)="(-)" {
				Set tRedecoratedValueString=tRedecoratedValueString_"GetPrevious("""")"_$E(dp,4,*)_$S((d'=numd):".",1:"")
			} ElseIf $E(dp)="(" {
				Set tRedecoratedValueString=tRedecoratedValueString_"GetAt("_$E(dp,2,*)_$S((d'=numd):".",1:"")
			} Else {
				Set tRedecoratedValueString=tRedecoratedValueString_dp_$S((d'=numd):".",1:"")
			}
		}
	}

	Quit tRedecoratedValueString
}

/// Returns a string representing a code-generated list of arguments to GetAt() invocations in the pVarName string passed to instantiateProps().
ClassMethod getPropsArgs(pVarName As %String) As %String
{
	Set numd=$L(pVarName,".")  Quit:numd<2 1
	#; loop over dot pieces
	Set (dot,qc,pc,tLevel,iArg)=0, (pp,str)=""
	#; variable names:d= dot piece index, dp= dot piece, q= quote piece index, qp= quote piece, qc= quote count, pp= parens piece, pc= parens count, pd= parens dot
	For d=1:1:numd { Set dp=$P(pVarName,".",d)
		#; loop over quote pieces
		Set numq=$L(dp,""""), qc=qc-1
		For q=1:1:numq { Set qp=$P(dp,"""",q)  Set qc=qc+1
			If qc#2=0 {
				#; if not inside quotes, abort if fragment contains non-identifier or non-array characters
				//If $E(qp,2,$L(qp))["%" || (qp'=$TR(qp,"^+-='_*/\#$&|,![]{}")) Set qc=-1  Quit
				#; quit if last piece
				If d=numd&&(q=numq) Set qc=-2  Quit
				If qp'=$TR(qp,"()") {
					#; has parens; balance them
					Set:'pc pd=d
					Set pc=pc+($L(qp)-$L($TR(qp,"(")))-($L(qp)-$L($TR(qp,")")))
					If pc<0 { Set qc=-1  Quit }
					If 'pc {
						Set pp=pp_$S(d>pd&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
						Set tFunc=$P(pp,"("), tArgs=$E(pp,$L(tFunc)+1,*)
						Set:$Case(tArgs,"()":0, "(-)":0, :1) str=str_","_tArgs
						Set pp=""
					} Else {
						Set pp=pp_$S(d>1&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
					}
				} Else {
					Set:pc pp=pp_$S(d>1&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
				}
			} Else {
				Set:pc pp=pp_$S(d>pd&&(q=1):".",1:"")_$S(q>1:"""",1:"")_qp
			}
		}
		Quit:qc<0
		Set:qc#2=0&&(d<numd) dot=1
	}
	Quit:qc#2 "" ; unbalanced quotes -or- not a simple property
	Quit str ; found dot not quoted
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	Set $ZT="Trap", tSC=$$$OK
	Do {
		#; Must know the property we want to assign to
		If ..SourceClass="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"SourceClass",..DisplayName()))

			#; Its a fatal error not to know the class name
			Set pContext.IsFatal=1
		}
		#; Must know the value, empty string shall be expressed as """"""
		If ..TargetClass="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"TargetClass",..DisplayName()))

			#; Its a fatal error not to know the class name
			Set pContext.IsFatal=1
		}

		If pContext.IsFatal=1 Quit
		
		Set tSC=..Actions.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit

	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="", tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "Transform"
}

/// Internal method to return DocType if child doc names also specified.
Method primaryDocType(docType As %String) As %String
{
	Return $Piece(docType,":",1,2)
}

}
