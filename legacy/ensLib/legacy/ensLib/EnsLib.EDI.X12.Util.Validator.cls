/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.Util.Validator [ Abstract, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Perform X12 document validation based on SNIP level criteria. </br>
/// This returns a %Status code indicating success or failure.  It also gathers the information needed for generating a reply or performing batch splitting. </br>
/// <param>pOriginalDocument</param> is the X12 document to be validated. </br>
/// <param>pSNIPLevel</param> is an %Integer indicating the level of validation to perform.  Supported levels are 1 and 2.
/// <param>pBatchErrorAction</param> is a %String indicating how the validator should behave upon encountering errors.  Permitted values are: </br>
/// 	"All" - Reject With All Errors : Reject the whole batch if any error is found in any document within it. Enumerate all errors found in the generated reply document.<br>
/// 	"Note" - Accept With Errors : Accept documents with errors, but do take note of all errors found.  This will always return OK but will include any errors in the generated reply document.<br>
/// 	"First" - Reject On First Error : Reject the whole batch when the first error is found in any document within it. Don't bother checking for more errors or parsing any further contents of the Interchange. <br>
/// 	"Indiv" - Reject Individual Errors : Reject only those documents within the Interchange that have errors. Parent documents won't fail validation unless all their children fail.</br>
/// <param>pSC</param> is an optional %Status result of attempting to parse the document stream.</br>
/// <param>pCleanupTempData</param> is an optional boolean indicator of whether this method will cleanup the temporary global used for storing validation data.
/// This defaults to true, but may be set to false in order to enable batch splitting or to avoid having to perform validation again in order to generate a reply document.
/// If this is set to false, the data can be cleaned up later by calling <method>CleanupValidationData</method>
ClassMethod PerformSNIPValidation(pOriginalDocument As EnsLib.EDI.X12.Document, pSNIPLevel As %Integer = 1, pBatchErrorAction As %String = "Indiv", pSC As %Status = {$$$OK}, pCleanupTempValData As %Boolean = 1) As %Status
{
	#dim tSC As %Status = $$$OK
	If "Interchange" = pOriginalDocument.Name {
		Set tSC = ..PerformSNIPInterchangeVal(pOriginalDocument, pSC, pSNIPLevel, pBatchErrorAction)
	} ElseIf "Group" = pOriginalDocument.Name {
		Set tSC = ..PerformSNIPGroupValidation(pOriginalDocument,, pSNIPLevel, pBatchErrorAction)
	} Else {
		Set tGSGreater = 1
		If pOriginalDocument.ParentId'="" {
			Set tGroup = ##class(EnsLib.EDI.X12.Document).%OpenId($P(pOriginalDocument.ParentId,":"))
			If $IsObject(tGroup) {
				Set tReleaseID = tGroup.GetValueAt("1:"_$$$GSVersionReleaseIndustryIdenti)
				Set tReplyType = ##class(EnsLib.EDI.X12.Document).DetermineReplyVersion(tReleaseID)
				#; AK5 will be IK5 instead if version >= 5010 and HIPAA standard transaction
				Set tGSGreater = (tReplyType>997)
			}
		}
		Set tSC = ..PerformSNIPTSValidation(pOriginalDocument, pSNIPLevel, tGSGreater, pBatchErrorAction)
	}
	If pCleanupTempValData {
		Do ..CleanupValidationData(pOriginalDocument.getId())
	} Else {
		Set $$$X12ValInfo(pOriginalDocument.getId(),"Validation") = $LB("SNIP",pSNIPLevel,pBatchErrorAction)
	}
	Quit tSC
}

/// <var>pDoc</var> is the X12 document to validate.
/// <var>pValSpec</var> is a string specifying types of Validation to perform <p>
/// Set to 1 to block documents that don't pass default validation. Default validation requires a DocType
/// and blocks messages with any other error encountered while mapping the document's 
/// sequence of segments using the X12 schema structure specified by the document's DocType. This is equivalent to 'dm'. <p/>
/// All flags relating to fields/components apply only if 's'/'c' also specified 
/// (eg. if set to 'dmslt' then the length and datatype of fields will be checked, but the length and datatype of components will not be) <p/>
/// 'd' - require DocType <br/>
/// 'm' - don't tolerate BuildMap segment mapping errors <br/>
/// 's' - enforce segment structures (number and repetition of fields) <br/>
/// 'c' - enforce composite structures (number of components) <br/>
/// 'r' - enforce required fields/components being present <br/>
/// 'u' - enforce non-use of fields/components marked 'Not Used' - Note this is not available when using a new-style only schema <br/>
/// 'l' - enforce field/component length restrictions <br/>
/// 't' - enforce correct datatypes used for field/component values <br/>
/// 'v' - enforce correct code table values used where specified in the schema - Note this is not available when using a new-style only schema <br/>
/// 'x' - enforce relational conditions where specified in the schema - Note this is not available when using a new-style only schema <br/>
/// 'n' - perform all validation available to new style schemas.  This is equivalent to 'dmscrlt' <br/>
/// 'a' - perform all available validation. This is equivalent to 'dmscrultv' <br/>
/// 'e' - continue validating after errors are encountered - specify this to scan the entire document and report all errors <br/> <p/>
/// <var>pValidateChildren</var> is a boolean indication of whether we should only validate at the current level (false) or validate any nested children (true). The default is true.
/// <var>pSetTempValData</var> is a boolean indication of whether to set the temporary data needed for generating reply documents and performing batch splitting. The default is false.
/// <var>pBatchErrorAction</var> is relevant only if pSetTempValData is true.
/// For batch splitting, this must have a value of 'Indiv'.  See the EnsLib.EDI.X12.Service.Standard property 'BatchErrorAction' for other options.
ClassMethod Validate(pDoc As EnsLib.EDI.X12.Document, pValSpec As %String = 1, pValidateChildren As %Boolean = 1, pSetTempValData As %Boolean = 0, pBatchErrorAction As %String = "Indiv") As %Status
{
	#; do validation - by default validate DocType, BuildMapStatus
	#dim tSC,tSC1 As %Status = $$$OK
	#dim tQuitOnError As %Boolean = 1
	#dim OldStyle As %Boolean = 0
	#dim i As %Integer
	#dim tSeg As EnsLib.EDI.X12.Segment
	#dim tChildDoc As EnsLib.EDI.X12.Document
	#dim DocType,tChildDocType As %String
	#dim tOriginalDocType As %String = ""
	#dim ex As %Exception.AbstractException
	
	Try {
		Set pValSpec=$zcvt(pValSpec,"L")
		Quit:$TR(pValSpec,"e","")="" ; if no flags or just 'e' quit
		Set:pValSpec["a" pValSpec=$REPLACE(pValSpec,"a","dmscrultvx")
		Set:pValSpec["n" pValSpec=$REPLACE(pValSpec,"n","dmscrlt")
		Set:pValSpec=1 pValSpec="dm"
		Set tQuitOnError = (pValSpec'["e")
		Set tOriginalDocType = pDoc.DocType
		
		// first test for DocType
		If ((pDoc.DocType="") && (pValSpec["d")) {
			Set tSC=$$$ERROR($$$EnsEDIX12MissingDocType)
			Quit:tQuitOnError
		}
		Quit:(pValSpec="d")
		
		// switch to using 'validation schema' if doing field/component level validation
		If ($TR(pValSpec, "sc")'=pValSpec)&&(pDoc.DocType'="") {
			Set DocType = pDoc.DocType
			Set:$E(DocType)="-" DocType=$E(DocType,2,*)
			If $D($$$vaVSchemaGbl($P(DocType,":"),$P(DocType,":",2))) {
				Do:($E(tOriginalDocType)'="-") pDoc.PokeDocType("-"_DocType)
				Set OldStyle = 1
			} ElseIf ($TR(pValSpec,"uvx")'=pValSpec) {
				If (pValSpec["u") {
					Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12CannotEnforceNonUse))
					Quit:tQuitOnError
				}
				If (pValSpec["v") {
					Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12CannotEnforceCodeTables))
					Quit:tQuitOnError
				}
				If (pValSpec["x") {
					Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12CannotEnforceTR3Rules))
					Quit:tQuitOnError
				}
			}
		}
		Set tSC1=pDoc.BuildMap('tQuitOnError)

		If (pValSpec["m")&&$$$ISERR(tSC1) {
			Set tSC=$$$ADDSC(tSC,tSC1) 
			Quit:tQuitOnError
		}
		
		If pValSpec["s" {
			If pDoc.DocType="" || $$$StatusEquals(tSC1,$$$EnsEDIErrMapDocType) {
				Set tSC=$$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CannotValidateNoDocType))
				Quit
			}
			For i=1:1:pDoc.SegCount {
				Set tSeg=pDoc.GetSegmentAt(i,.tSC1)
				If $$$ISERR(tSC1) {
					Set tSC=$$$ADDSC(tSC,tSC1) 
					Quit:tQuitOnError
					Continue // can't do anything with segment we can't get
				}
				If tSeg.Name [ "DocsRef" {
					If pValidateChildren {
						Set tChildDoc=$$$NULLOREF
						For {
							// Get child documents and validate them
							Set tChildDoc=pDoc.NextChild(tChildDoc,i)
							Quit:'$IsObject(tChildDoc)
							If ""=tChildDoc.DocType {
								Set tChildDocType = tChildDoc.resolveChildDocType()
								Do tChildDoc.PokeDocType(tChildDocType)
							}
							Set tSC1 = ..Validate(tChildDoc,pValSpec,pValidateChildren,pSetTempValData,pBatchErrorAction)
							If $$$ISERR(tSC1) {
								Set tSC=$$$ADDSC(tSC,tSC1) 
								Quit:tQuitOnError
							}
						}
						Quit:$$$ISERR(tSC)&&tQuitOnError
					}
					Continue // doesn't make sense to validate the DocsRef segment because this isn't a real part of the X12 document
				}
				If OldStyle=1 {
					Set tSC1=..DoValidateVSegment(tSeg,pValSpec,i,DocType,tQuitOnError)
				} Else {
					Set tSC1=..DoValidateNewSegment(tSeg,pValSpec,i,tQuitOnError)
				}
				If $$$ISERR(tSC1) {
					Set tSC=$$$ADDSC(tSC,tSC1) 
					Quit:tQuitOnError
				}
			}
		}
	} Catch ex {
		Set tSC = $S('tQuitOnError:$$$ADDSC(ex.AsStatus(),tSC),1:ex.AsStatus())
	}
	If ($IsObject(pDoc)&&$Case(tOriginalDocType,"":0,pDoc.DocType:0,:1)) {
		// Restore original DocType (this will be a difference of validation-schema vs. new-style)
		Do pDoc.PokeDocType(tOriginalDocType)
	}

	If pSetTempValData {
		If $$$ISERR(tSC) {
			Set $$$X12ValInfo(pDoc.getId(),"HasError") = 1
		}
		Set $$$X12ValInfo(pDoc.getId(),"Status") = tSC
		Set $$$X12ValInfo(pDoc.getId(),"Validation") = $LB("Flags",pValSpec)

		Set tSC = ..SetTmpGblForFlagValidation(pDoc,pBatchErrorAction,tSC)
	}
	Quit tSC
}

/// For X12 batch <param>pOriginalDoc</param> split the batch into two separate batches - one containing only children which pass validation and one containing only children which fail validation.
/// <param>ValidationType</param> can be either SNIP or Flags. <br>
/// <param>ValidationLevel</param> is either the SNIP level or the validation flags to use. <br>
/// If prior validation data exists, it must match the Type and Level specified. If SNIP validation, it must have been batch handling of 'Indiv' and if Flags validation, it must have 'e' in the ValSpec to ensure all errors are recorded.
/// If prior validation data exists and does not match, call <method>CleanupValidationData</method> first. <br>
/// <param>pReuseOriginalIfMutable</param> is an optional boolean indicator to modify the <param>pOriginalDoc</param> if its IsMutable property is false rather than creating a new X12 document object for the <param>pGoodBatch</param>.
/// If this is set to true and there are no errors, then the returned <param>pGoodBatch</param> will be <param>pOriginalDoc</param>.  If this is set to false and there are no errors, then the returned <param>pGoodBatch</param> will be a clone of the original. 
/// The default is false. <br>
/// <param>pSaveBadBatch</param> is an optional boolean indicator to create the <param>pBadBatch</param> object. If false, no new X12 document object will be created and the parameter will return a NULLOREF.
/// The default is true. <br>
/// <param>pCleanupTempData</param> is an optional boolean indicator of whether this method will cleanup the temporary global used for storing validation data.
/// This defaults to true, but may be set to false in order to avoid having to perform validation again in order to generate a reply document.
/// If this is set to false, the data can be cleaned up later by calling <method>CleanupValidationData</method>
ClassMethod SplitBatch(pOriginalDoc As EnsLib.EDI.X12.Document, Output pGoodBatch As EnsLib.EDI.X12.Document, Output pBadBatch As EnsLib.EDI.X12.Document, pValidationType As %String = "SNIP", pValidationLevel As %String = 1, pReuseOriginalIfMutable As %Boolean = 0, pSaveBadBatch As %Boolean = 1, pCleanupTempValData As %Boolean = 1) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tDocID As %Integer = pOriginalDoc.getId()
	#dim tIsReuse As %Boolean = 0
	#dim tHasTA1 As %Boolean = 0

	Set pBadBatch = $$$NULLOREF
	Set pGoodBatch = $$$NULLOREF
	If $Case(pValidationType,"SNIP":0,"Flags":0,:1) {
		Set tSC = $$$ERROR($$$EnsErrGeneral,"Unsupported validation type. Options are 'SNIP' or 'Flags'.")
		Quit tSC
	}

	// If our validation data stops on the first error, every document after that will falsely appear to have passed validation
	If ((pValidationType="Flags") && ($Translate(pValidationLevel,"1dm","")'="") && (pValidationLevel'["e")) {
		Set pValidationLevel = pValidationLevel_"e"
	}

	// If there is no current validation data, perform validation now.
	// If prior validation data exists, we won't risk overwriting it in case it is still in use (e.g. for generating a reply).
	If '$D($$$X12ValData(tDocID)) {
		If pValidationType = "SNIP" {
			Do ##class(EnsLib.EDI.X12.Util.Validator).PerformSNIPValidation(pOriginalDoc,pValidationLevel,"Indiv",,0)
		} ElseIf pValidationType = "Flags" {
			Do ##class(EnsLib.EDI.X12.Util.Validator).Validate(pOriginalDoc,pValidationLevel,1,1,"Indiv")
		}
	}

	// Check that the currently saved validation data matches the requested validation type and level.
	// If SNIP validation, it must have been batch handling of 'Indiv' and if Flags validation, it must have 'e' in the ValSpec to ensure all errors are recorded.
	If '$D($$$X12ValInfo(tDocID,"Validation"),tPriorValidation) || (tPriorValidation '= ($LB(pValidationType,pValidationLevel)_$Case(pValidationType,"SNIP":$LB("Indiv"),:""))) {
		Quit $$$ERROR($$$EnsErrGeneral,"The existing validation data does not allow for batch splitting. Clear this data using CleanupValidationData if it is no longer needed.")
	}

	If '$G($$$X12ValInfo(tDocID,"HasError"),0) {
		Set pGoodBatch = $Select(pReuseOriginalIfMutable:pOriginalDoc,1:pOriginalDoc.%ConstructClone(1))
		Quit tSC
	}

	Set tSeparators = pOriginalDoc.Separators
	Set tDataElementSeparator = $$$ELESEP(tSeparators)

	If pReuseOriginalIfMutable && pOriginalDoc.IsMutable {
		Set pGoodBatch = pOriginalDoc
		Set tIsReuse = 1
	} Else {
		Set pGoodBatch = ##class(EnsLib.EDI.X12.Document).%New($LB("",tSeparators))
		Set pGoodBatch.Source = pOriginalDoc.Source
		Do pGoodBatch.PokeDocType(pOriginalDoc.DocType)
		Set pGoodBatch.HandledIndividually = pOriginalDoc.HandledIndividually
	}
	If pSaveBadBatch {
		Set pBadBatch = ##class(EnsLib.EDI.X12.Document).%New($LB("",tSeparators))
		Set pBadBatch.Source = pOriginalDoc.Source
		Do pBadBatch.PokeDocType(pOriginalDoc.DocType)
		Set pBadBatch.HandledIndividually = pOriginalDoc.HandledIndividually
	}

	Set tISA = pOriginalDoc.GetSegmentAt(1,.tSC)	Quit:$$$ISERR(tSC) tSC
	Do:'tIsReuse pGoodBatch.AppendSegment(tISA)
	Do:pSaveBadBatch pBadBatch.AppendSegment(tISA)

	If pOriginalDoc.GetValueAt("2:0") = "TA1" {
		Set tTA1 = pOriginalDoc.GetSegmentAt(2,.tSC)	Quit:$$$ISERR(tSC) tSC
		Do:'tIsReuse pGoodBatch.AppendSegment(tTA1)
		Do:pSaveBadBatch pBadBatch.AppendSegment(tTA1)
		Set tHasTA1 = 1
	}

	If pOriginalDoc.ChildCount > 0 {
		Set tGroupPlaceholder = ##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(tSeparators,1,3)_"GroupDocsRef"_tDataElementSeparator_(2+tHasTA1)_tDataElementSeparator))
		Do:'tIsReuse pGoodBatch.AppendSegment(tGroupPlaceholder.%ConstructClone())
		Do:pSaveBadBatch pBadBatch.AppendSegment(tGroupPlaceholder)
		Set tBadBatchParent = $S(pSaveBadBatch: pBadBatch.getId()_":"_(2+tHasTA1), 1: "")

		Set tOriginalGroup = ""
		For i=1:1:pOriginalDoc.ChildCount {
			Set tOriginalGroup = pOriginalDoc.NextChild(tOriginalGroup)
			Set tCode = $$$X12ValInfo(tOriginalGroup.getId(),"Code")
			If tCode = $$$CodeAK9715Accepted {
				Do:'tIsReuse pGoodBatch.AddChild(pGoodBatch.SegCount,tOriginalGroup.%ConstructClone())
			} ElseIf tCode = $$$CodeAK9715Rejected {
				If tIsReuse {
					set tOriginalGroup.ParentId = tBadBatchParent
					set tSC = tOriginalGroup.%Save()
					Quit:$$$ISERR(tSC)
				} ElseIf pSaveBadBatch {
					Do pBadBatch.AddChild(pBadBatch.SegCount,tOriginalGroup.%ConstructClone())
				}
			} Else {
				If 'tIsReuse {
					Set tGoodGroup = ##class(EnsLib.EDI.X12.Document).%New($LB("",tSeparators))
					Do tGoodGroup.PokeDocType(tOriginalGroup.DocType)
					Set tGoodGroup.HandledIndividually = pOriginalDoc.HandledIndividually
				}
				If pSaveBadBatch {
					Set tBadGroup = ##class(EnsLib.EDI.X12.Document).%New($LB("",tSeparators))
					Do tBadGroup.PokeDocType(tOriginalGroup.DocType)
					Set tBadGroup.HandledIndividually = pOriginalDoc.HandledIndividually
				}

				Set tGS = tOriginalGroup.GetSegmentAt(1,.tSC)	Quit:$$$ISERR(tSC)
				Set tTSPlaceholder = ##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(tSeparators,1,3)_"TransactionSetDocsRef"_tDataElementSeparator_2_tDataElementSeparator))
				If 'tIsReuse {
					Do tGoodGroup.AppendSegment(tGS)
					Do tGoodGroup.AppendSegment(tTSPlaceholder.%ConstructClone())
				}
				If pSaveBadBatch {
					Do tBadGroup.AppendSegment(tGS)
					Do tBadGroup.AppendSegment(tTSPlaceholder)
				}
				Set tBadGroupParentID = $S(pSaveBadBatch:tBadGroup.getId()_":2",1:"")
				

				Set tTS = ""
				For j=1:1:tOriginalGroup.ChildCount {
					Set tTS = tOriginalGroup.NextChild(tTS)
					Set tCode = $$$X12ValInfo(tTS.getId(),"Code")
					If tCode = $$$CodeAK5717Accepted {
						Do:'tIsReuse tGoodGroup.AddChild(2,tTS.%ConstructClone())
					} Else {
						If tIsReuse {
							Set tTS.ParentId = tBadGroupParentID
							Set tSC = tTS.%Save()
							Quit:$$$ISERR(tSC)
						} ElseIf pSaveBadBatch {
							Do tBadGroup.AddChild(2,tTS.%ConstructClone())
						}
					}
				}
				Quit:$$$ISERR(tSC)

				If tIsReuse {
					Do tOriginalGroup.SetValueAt(tOriginalGroup.ChildCount,"TransactionSetDocsRef:"_$$$REFSEGFLDCOUNT)
					Do tOriginalGroup.SetValueAt(tOriginalGroup.ChildCount,"GE:"_$$$GENumberofTransactionSetsInclu)
					Set tSC = tOriginalGroup.%Save()
					Quit:$$$ISERR(tSC)
				} Else {
					Do tGoodGroup.AddEndSegment()
					Do pGoodBatch.AddChild(pGoodBatch.SegCount,tGoodGroup)
				}
				If pSaveBadBatch {
					Do tBadGroup.AddEndSegment()
					Do pBadBatch.AddChild(pBadBatch.SegCount,tBadGroup)
				}
			}
		}
		Quit:$$$ISERR(tSC) tSC
	}

	If tIsReuse {
		Do pOriginalDoc.SetValueAt(pOriginalDoc.ChildCount,"GroupDocsRef:"_$$$REFSEGFLDCOUNT)
		Do pOriginalDoc.SetValueAt(pOriginalDoc.ChildCount,"IEA:"_$$$IEANumberofIncludedFunctionalGr)
		Set tSC = $$$ADDSC(tSC,pOriginalDoc.%Save())
	} Else {
		Do pGoodBatch.AddEndSegment()
		Set tSC = $$$ADDSC(tSC,pGoodBatch.%Save())
	}
	If pGoodBatch.ChildCount = 0 {
		Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(pGoodBatch.%Id()))
		Set pGoodBatch = $$$NULLOREF
	}
	If pSaveBadBatch {
		If pBadBatch.ChildCount = 0 {
			Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(pBadBatch.%Id()))
			Set pBadBatch = $$$NULLOREF
		} Else {
			Do pBadBatch.AddEndSegment()
			Set tSC = $$$ADDSC(tSC,pBadBatch.%Save())
		}
	}

	If pCleanupTempValData {
		// If requested, cleanup ^IRIS.Temp global now that we no longer need it
		Do ..CleanupValidationData(pOriginalDoc.getId())
	}

	Quit tSC
}

/// For X12 Group <param>pOriginalDoc</param> split the Group into two separate Groups - one containing only Transaction Sets which pass validation and one containing only Transaction Sets which fail validation.
/// <param>ValidationType</param> can be either SNIP or Flags. <br>
/// <param>ValidationLevel</param> is either the SNIP level or the validation flags to use. <br>
/// If prior validation data exists, it must match the Type and Level specified. If SNIP validation, it must have been batch handling of 'Indiv' and if Flags validation, it must have 'e' in the ValSpec to ensure all errors are recorded.
/// If prior validation data exists and does not match, call <method>CleanupValidationData</method> first. <br>
/// <param>pReuseOriginalIfMutable</param> is an optional boolean indicator to modify the <param>pOriginalDoc</param> if its IsMutable property is false rather than creating a new X12 document object for the <param>pGoodGroup</param>
/// The default is false. <br>
/// <param>pSaveBadGroup</param> is an optional boolean indicator to create the <param>pBadGroup</param> object. If false, no new X12 document object will be created and the parameter will return a NULLOREF.
/// The default is true. <br>
/// <param>pCleanupTempData</param> is an optional boolean indicator of whether this method will cleanup the temporary global used for storing validation data.
/// This defaults to true, but may be set to false in order to avoid having to perform validation again in order to generate a reply document.
/// If this is set to false, the data can be cleaned up later by calling <method>CleanupValidationData</method>
ClassMethod SplitGroup(pOriginalDoc As EnsLib.EDI.X12.Document, Output pGoodGroup As EnsLib.EDI.X12.Document, Output pBadGroup As EnsLib.EDI.X12.Document, pValidationType As %String = "SNIP", pValidationLevel As %String = 1, pReuseOriginalIfMutable As %Boolean = 0, pSaveBadGroup As %Boolean = 1, pCleanupTempValData As %Boolean = 1) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tDocID As %Integer = pOriginalDoc.getId()
	#dim tIsReuse As %Boolean = 0
	#dim tBadParentID As %String = ""

	Set pBadGroup = $$$NULLOREF
	Set pGoodGroup = $$$NULLOREF
	If $Case(pValidationType,"SNIP":0,"Flags":0,:1) {
		Set tSC = $$$ERROR($$$EnsErrGeneral,"Unsupported validation type. Options are 'SNIP' or 'Flags'.")
		Quit tSC
	}
	// If our validation data stops on the first error, every document after that will falsely appear to have passed validation
	If ((pValidationType="Flags") && ($Translate(pValidationLevel,"1dm","")'="") && (pValidationLevel'["e")) {
		Set pValidationLevel = pValidationLevel_"e"
	}

	// If there is no current validation data, perform validation now.
	// If prior validation data exists, we won't risk overwriting it in case it is still in use (e.g. for generating a reply).
	If '$D($$$X12ValData(tDocID)) {
		If pValidationType = "SNIP" {
			Do ##class(EnsLib.EDI.X12.Util.Validator).PerformSNIPValidation(pOriginalDoc,pValidationLevel,"Indiv",,0)
		} ElseIf pValidationType = "Flags" {
			Do ##class(EnsLib.EDI.X12.Util.Validator).Validate(pOriginalDoc,pValidationLevel,1,1,"Indiv")
		}
	}

	// Check that the currently saved validation data matches the requested validation type and level.
	// If SNIP validation, it must have been batch handling of 'Indiv' and if Flags validation, it must have 'e' in the ValSpec to ensure all errors are recorded.
	If '$D($$$X12ValInfo(tDocID,"Validation"),tPriorValidation) || (tPriorValidation '= ($LB(pValidationType,pValidationLevel)_$Case(pValidationType,"SNIP":$LB("Indiv"),:""))) {
		Quit $$$ERROR($$$EnsErrGeneral,"The existing validation data does not allow for Group splitting. Clear this data using CleanupValidationData if it is no longer needed.")
	}

	If '$G($$$X12ValInfo(tDocID,"HasError"),0) {
		Set pGoodGroup= pOriginalDoc
		Quit tSC
	}

	Set tSeparators = pOriginalDoc.Separators
	Set tDataElementSeparator = $$$ELESEP(tSeparators)

	If pReuseOriginalIfMutable && pOriginalDoc.IsMutable {
		Set pGoodGroup = pOriginalDoc
		Set tIsReuse = 1
	} Else {
		Set pGoodGroup = ##class(EnsLib.EDI.X12.Document).%New($LB("",tSeparators))
		Set pGoodGroup.Source = pOriginalDoc.Source
		Do pGoodGroup.PokeDocType(pOriginalDoc.DocType)
		Set pGoodGroup.HandledIndividually = pOriginalDoc.HandledIndividually
	}
	If pSaveBadGroup {
		Set pBadGroup = ##class(EnsLib.EDI.X12.Document).%New($LB("",tSeparators))
		Set pBadGroup.Source = pOriginalDoc.Source
		Do pBadGroup.PokeDocType(pOriginalDoc.DocType)
		Set pBadGroup.HandledIndividually = pOriginalDoc.HandledIndividually
		Set tBadParentID = pBadGroup.getId()_":"_2
	}

	Set tGS = pOriginalDoc.GetSegmentAt(1,.tSC)	Quit:$$$ISERR(tSC)
	Set tTSPlaceholder = ##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(tSeparators,1,3)_"TransactionSetDocsRef"_tDataElementSeparator_2_tDataElementSeparator))
	If 'tIsReuse {
		Do pGoodGroup.AppendSegment(tGS)
		Do pGoodGroup.AppendSegment(tTSPlaceholder.%ConstructClone())
	}
	If pSaveBadGroup {
		Do pBadGroup.AppendSegment(tGS)
		Do pBadGroup.AppendSegment(tTSPlaceholder)
	}

	Set tTS = ""
	For j=1:1:pOriginalDoc.ChildCount {
		Set tTS = pOriginalDoc.NextChild(tTS)
		Set tCode = $$$X12ValInfo(tTS.getId(),"Code")
		If tCode = $$$CodeAK5717Accepted {
			Do:'tIsReuse pGoodGroup.AddChild(2,tTS.%ConstructClone())
		} Else {
			If tIsReuse {
				Set tTS.ParentId = tBadParentID
				Set tSC = tTS.%Save()
				Quit:$$$ISERR(tSC)
			} ElseIf pSaveBadGroup {
				Do pBadGroup.AddChild(2,tTS.%ConstructClone())
			}
		}
	}
	Quit:$$$ISERR(tSC)

	If tIsReuse {
		Do pOriginalDoc.SetValueAt(pOriginalDoc.ChildCount,"TransactionSetDocsRef:"_$$$REFSEGFLDCOUNT)
		Do pOriginalDoc.SetValueAt(pOriginalDoc.ChildCount,"GE:"_$$$GENumberofTransactionSetsInclu)
		Set tSC = pOriginalDoc.%Save()
		Quit:$$$ISERR(tSC)
	} Else {
		Do pGoodGroup.AddEndSegment()
		Set tSC = $$$ADDSC(tSC,pGoodGroup.%Save())

	}
	If pGoodGroup.ChildCount = 0 {
		Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(pGoodGroup.%Id()))
		Set pGoodGroup = $$$NULLOREF
	}

	If pSaveBadGroup {
		If pBadGroup.ChildCount = 0 {
			Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(pBadGroup.%Id()))
			Set pBadGroup = $$$NULLOREF
		} Else {
			Do pBadGroup.AddEndSegment()
			Set tSC = $$$ADDSC(tSC,pBadGroup.%Save())
		}
	}

	If pCleanupTempValData {
		// If requested, cleanup ^IRIS.Temp global now that we no longer need it
		Do ..CleanupValidationData(pOriginalDoc.getId())
	}

	Quit tSC
}

/// Construct the Reply Interchange containing a 999 or 997 Transaction Set based on validation against <param>pOriginalDoc</param> <br>
/// If prior validation data exists, it will be used.  Otherwise, this method will perform the validation specified in <param>Validation</param>
/// in type:level format, so SNIP 1 validation is 'SNIP:1' and dm Flag validation is 'Flags:dm' <br>
/// <param>pSC</param> represents any parsing errors in the original document <br> <p>
/// <param>pBatchReplyType</param> is string indicating what kind of batch reply should we construct for an Interchange batch we have received
/// Note that all the options here that relate to TA1 segments are used to force a TA1 segment to be generated, often as the only body segment of the reply interchange.
/// This is used to represent the presence or absence of errors in the whole inbound Interchange.  However if an error is found in the incoming
/// ISA or IEA that can only be reported in a TA1 segment, then a TA1 will be generated even if the configured setting does not force a TA1 to appear. <p>
/// - All : Generate a reply Interchange containing a reply notification for every TransactionSet in the Interchange we received <br>
/// - All+ISA14TA1 : Generate a reply Interchange containing a TA1 segment only if either a 1 appears in field ISA:14 of the ISA header segment or if there is an error at the Interchange level.  If no error at the Interchange level, then send a reply for each Transaction Set we received. </br>
/// - Errors : Generate a reply Interchange containing reply notifications only for TransactionSets in which errors are detected, or an empty Interchange if no error is found <br>
/// - OnlyIfErrors : Only if errors are found, generate a reply Interchange containing reply notifications only for TransactionSets in which errors are detected <br>
/// - Successes : Generate a reply Interchange containing reply notifications only for TransactionSets in which no errors are detected, or an empty Interchange if only errors are found <br>
/// <param>pForceTA1</param> is a boolean indicating whether to include a TA1 segment in the reply even if there are no Interchange-level errors <p>
/// <param>pBatchErrorAction</param> is a string indicating what to do when detecting a validation error in a batch Interchange document: <br>
/// - Reject With All Errors : Reject the whole batch if any error is found in any document within it. Enumerate all errors found if BatchReplyType allows for reporting them. This will prevent forwarding any documents in a batch until all have been read and validated.<br>
/// - Accept With Errors : Accept documents with errors, but do take note of all errors found if BatchReplyType allows for reporting them. This will prevent forwarding any documents in a batch until all have been read and validated.<br>
/// - Reject On First Error : Reject the whole batch when the first error is found in any document within it. Don't bother checking for more errors or parsing any further contents of the Interchange. This will prevent forwarding any documents in a batch until all have been read and validated. <br>
/// - Reject Individual Errors : Reject only those documents within the Interchange that have errors. Forward each acceptable child document to the target config item(s) as soon as it has been read and validated. <p>
/// <param>pLocalApplicationID</param> is colon-separated Local ID:Qualifier codes representing this (receiving) facility and application <br>
/// These are used in constructing reply document headers.<br>
/// The '@' symbol represents using the corresponding field from the incoming message.<br>
/// If your ID must contain a literal @ symbol, escape it with backslash: '\@' <p>
/// <param>pAddNackErrText</param> is a boolean indicating whether to add error status text as an extra field in the AK5, AK9, and TA1 segments. This is not part of the X12 standard.
ClassMethod ConstructBatchReply(pOriginalDoc As EnsLib.EDI.X12.Document, ByRef pSC As %Status, pBatchReplyType As %String = "All", pForceTA1 As %Boolean = 0, pBatchErrorAction As %String = "Indiv", pValidation As %String = "SNIP:1", pLocalApplicationID As %String = "@:@", pAddNackErrText As %Boolean = 0, pCleanupTempValData As %Boolean = 1) As EnsLib.EDI.X12.Document
{
	#dim tDoc As EnsLib.EDI.X12.Document
	#dim tSeg As EnsLib.EDI.X12.Segment
	#dim tOriginalDocID = pOriginalDoc.getId()
	#dim tEncounteredFirstErr As %Boolean = 0
	#dim tCategory As %String = pOriginalDoc.DocTypeCategory
	#dim tValMode = $P(pValidation,":")
	#dim tValLevel = $P(pValidation,":",2)
	#dim tHasTA1 As %Boolean = pForceTA1
	Set pBatchReplyType = $Case(pBatchReplyType,"All+ISA14TA1":"AllI14TA1","Errors":"Errs","OnlyIfErrors":"OnlyErrs","Successes":"Succ",:pBatchReplyType)

	Set tReplyDoc = ..ConstructReplyEnvelope(pOriginalDoc,.pSC,.tHasTA1,pAddNackErrText,pLocalApplicationID,,.tReplyIEA,.tInterchangeErr)	Quit:$$$ISERR(pSC) $$$NULLOREF
	#; No 997/999 if Interchange-level error and have selected one of these settings
	Set tIncludeReplyBody = $S(tInterchangeErr && ((pBatchReplyType="AllI14TA1") || (pBatchErrorAction="First")) : 0, 1:1)

	Set tUseChildGbl = $D($$$X12ValInfo(tOriginalDocID,"Children"))
	If tIncludeReplyBody && (tUseChildGbl || (pOriginalDoc.ChildCount > 0)) {
		Set tDataElementSeparator=$E(pOriginalDoc.Separators,1)
		Set tGrpPlacehldr=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(pOriginalDoc.Separators,1,3)_"GroupDocsRef"_tDataElementSeparator_(2+(tHasTA1))_tDataElementSeparator))
		Do:$IsObject(tGrpPlacehldr) tReplyDoc.AppendSegment(tGrpPlacehldr)
		
		#; Create Group document as child to reply Interchange
		Set tReplyGroup =##class(EnsLib.EDI.X12.Document).%New($LB("",$E(pOriginalDoc.Separators,1,3)_pOriginalDoc.SegmentTerminator))
		Set:""'=tCategory tSC=tReplyGroup.PokeDocType(tCategory_":Group")
		Set tReplyGS=pOriginalDoc.New997OuterGroupSegs(pOriginalDoc.GetSegmentAt(1),pLocalApplicationID,,,.tReplyGE,.pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
		If $IsObject(tReplyGS) {
			#; Adjust Reply GS08 if will be replying with a 999
			Set tGrp=$$$NULLOREF		
			#; Start by finding first Group from the original
			If tUseChildGbl {
				Set tGrpID = ""
				For {
					Set tGrpID = $O($$$X12ChildDoc(tOriginalDocID,tGrpID))	Quit:""=tGrpID
					Set tGrp = ##class(EnsLib.EDI.X12.Document).%OpenId(tGrpID)	Quit:'$IsObject(tGrp)
					Set tGS=tGrp.GetSegmentAt(1)	Continue:tGS.Name'="GS"
					Quit
				}
			} Else {
				For {
					Set tGrp=pOriginalDoc.NextChild(tGrp)  Quit:'$IsObject(tGrp)
					Set tGS=tGrp.GetSegmentAt(1)  Continue:tGS.Name'="GS"
					Set tGrpID = tGrp.getId()
					Quit
				}
			}
			If $IsObject(tGrp)&&$IsObject(tGS) {
				#; 997 will be 999 instead if version >= 5010 and HIPAA standard transaction
				Set tReplyVersion = ##class(EnsLib.EDI.X12.Document).DetermineReplyVersion(tGS.GetValueAt($$$GSVersionReleaseIndustryIdenti))
				Set tVersion = $E(tGS.GetValueAt($$$GSVersionReleaseIndustryIdenti),1,5)
				If tReplyVersion=999 {
					Set tImplementationRef = $Case(tVersion,"00602":$$$999ImplementationRef6020,:$$$999ImplementationRef5010)
					Set tSC=tReplyGS.SetValueAt(tImplementationRef,$$$GSVersionReleaseIndustryIdenti)  Quit:$$$ISERR(tSC) $$$NULLOREF
				}
				#; Also make sure that ISA12 value matches up with Version Number from GS08
				Set tSC=tReplyDoc.SetValueAt(tVersion,"1:"_$$$ISAInterchangeControlVersionNum)	Quit:$$$ISERR(tSC) $$$NULLOREF
			}
			Do tReplyGroup.AppendSegment(tReplyGS)
		}
		Set tTSPlacehldr=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(pOriginalDoc.Separators,1,3)_"TransactionSetDocsRef"_tDataElementSeparator_2_tDataElementSeparator))
		Do:$IsObject(tTSPlacehldr) tReplyGroup.AppendSegment(tTSPlacehldr)
		
		Set tNumGrps=0
		While $IsObject(tGrp) && ('tEncounteredFirstErr || (pBatchErrorAction'="First")) {
			#; TODO: Parse tReplyGrp to figure out how to add it to the reply (we don't know what type of object it is)
			Set tReplyGrp=$G($$$X12ValInfo(tGrpID,"ID"))
			Set tGS=tGrp.GetSegmentAt(1)
			If tGS.Name'="GS" {
				If tUseChildGbl {
					Set tGrpID = $O($$$X12ChildDoc(tOriginalDocID,tGrpID))
					If tGrpID'="" {
						Set tGrp = ##class(EnsLib.EDI.X12.Document).%OpenId(tGrpID)
					} Else {
						Set tGrp=$$$NULLOREF
					}
				} Else {
					Set tGrp=pOriginalDoc.NextChild(tGrp)
					Set tGrpID = tGrp.getId()
				}
				Continue
			}
			Set tGE=tGrp.GetSegmentAt(tGrp.SegCount)
			Set tSCgrp=$G($$$X12ValInfo(tGrpID,"Status"),$$$OK)
			Set tSCgrp=$$$ADDSC(tSCgrp,$G($$$X12ValInfo(tGrpID,"SendErr"),$$$OK))
			#; Create Transaction Set as child to Group in reply Interchange
			Set tReplyTS = ##class(EnsLib.EDI.X12.Document).%New($LB("",$E(pOriginalDoc.Separators,1,3)_pOriginalDoc.SegmentTerminator))
			Set tReplyST=pOriginalDoc.NewGroupReply997Segs(tGS,$Select($IsObject(tGE)&&(tGE.Name="GE"):tGE,1:$$$NULLOREF),##class(EnsLib.EDI.X12.Validator).Get997GroupCodes(tSCgrp),.tReplyAK1,.tReplyAK9,.tReplySE,.pSC)  Quit:$$$ISERR(pSC)
			If "SNIP"=tValMode {
				If '$D($$$X12ValInfo(tGrpID,"AK9")) {
					Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).PerformSNIPGroupValidation(tGrp,,tValLevel,pBatchErrorAction)
					Set $$$X12ChildDoc(tOriginalDocID,tGrpID) = tGrp.Name
				}
				Set tReplyAK9String = $G($$$X12ValInfo(tGrpID,"AK9"))
				If ""'=tReplyAK9String {
					Set tReplyAK9 = ##class(EnsLib.EDI.X12.Segment).%New($LB(,,,tReplyAK9String))
				}
			}
			Set:($IsObject(tReplyAK9) && (""'=tReplyAK9.GetValueAt($$$AK9FunctionalGroupSyntaxErrorCo))) tEncounteredFirstErr = 1
			#; 997 will be 999 instead if version >= 5010 and HIPAA standard transaction
			Set tReplyType = ##class(EnsLib.EDI.X12.Document).DetermineReplyVersion(tGS.GetValueAt($$$GSVersionReleaseIndustryIdenti))
			#; AK5 will be IK5 instead if version >= 5010 and HIPAA standard transaction
			Set tGSGreater = (tReplyType>997)
			Set:""'=tCategory tSC=tReplyTS.PokeDocType(tCategory_":"_tReplyType)
			Do:$IsObject(tReplyST) tReplyTS.AppendSegment(tReplyST)
			Do:$IsObject(tReplyAK1) tReplyTS.AppendSegment(tReplyAK1)
			Set (tOrigDocs,tNumDocs,tNumAccepted)=0
			#; Loop over source documents and get the status for each
			Set tDoc=$$$NULLOREF,tNumDocs=0,tNumSegs=4
			If ('tEncounteredFirstErr || ("First"'=pBatchErrorAction)) {
				Set tDocID = ""
				Set tUseGrpChildGbl = $D($$$X12ValInfo(tGrpID,"Children"))
				For {
					If tUseGrpChildGbl {
						Set tDocID = $O($$$X12ChildDoc(tGrpID,tDocID))	Quit:""=tDocID
						If tValMode'="SNIP" {
							#; need to fetch ST Segment for call to EnsLib.EDI.X12.Document::NewDocumentReply997Segs()
							Set tDoc = ##class(EnsLib.EDI.X12.Document).%OpenId(tDocID)	Continue:'$IsObject(tDoc)
						}
					} Else {
						Set tDoc=tGrp.NextChild(tDoc)  Quit:'$IsObject(tDoc)
						Set tDocID = tDoc.getId()
					}
					If tValMode="SNIP" {
						If '($D($$$X12ValInfo(tDocID,"Code"),tCode)#2)&&$IsObject(tDoc) {
							Do ##class(EnsLib.EDI.X12.Util.Validator).PerformSNIPTSValidation(tDoc,tValLevel,tGSGreater,pBatchErrorAction)
							Set $$$X12ChildDoc(tGrpID,tDocID) = tDoc.Name
						}
						Set tCode = $G($$$X12ValInfo(tDocID,"Code"))
						If $Case(pBatchReplyType,"Succ":("A"=tCode),"Errs":$Case(tCode,"R":1,"E":1,:0),"OnlyErrs":$Case(tCode,"R":1,"E":1,:0),:1) {
							Set tSegNum = ""
							For {
								Set tSegNum = $O($$$X12ReplySeg(tDocID,tSegNum),1,tSegString) Quit:""=tSegNum
								If ""'=tSegString {
									Set tSeg = ##class(EnsLib.EDI.X12.Segment).%New($LB(,,,tSegString))
									Do tReplyTS.AppendSegment(tSeg)
									Set tNumSegs = tNumSegs + 1
								}
							}
						}
						Set:(tCode'="A") tEncounteredFirstErr = 1
						Quit:(tEncounteredFirstErr && ("First"=pBatchErrorAction))

					} Else {
						If ('tEncounteredFirstErr || ("First"'=pBatchErrorAction)) {
							Set tSCdoc=$G($$$X12ValInfo(tDocID,"Status"),$$$OK)
							Set:$$$ISERR(tSCdoc) tEncounteredFirstErr = 1
							Set tST = tDoc.GetSegmentAt(1)
							If tST.Name'="ST" {
								#; create a temp segment to use in making the AK2
								Set tST = ##class(EnsLib.EDI.X12.Segment).%New($LB(,,,pOriginalDoc.Separators_"ST"_pOriginalDoc.ElementSeparator_+tDoc.DocTypeName))
							}

							If $Case(pBatchReplyType,"Succ":$$$ISOK(tSCdoc),"Errs":$$$ISERR(tSCdoc),"OnlyErrs":$$$ISERR(tSCdoc),:1) {
								Set tReplyAK2=pOriginalDoc.NewDocumentReply997Segs(tST,##class(EnsLib.EDI.X12.Validator).Get997Codes(tSCdoc),.tReplyAK5,.pSC,tGSGreater,(pBatchErrorAction'="Note"))  Quit:$$$ISERR(pSC)
								Do:$IsObject(tReplyAK2) tReplyTS.AppendSegment(tReplyAK2)
								#; AK3/AK4 / IK3/CTX/[IK4/CTX] optional
								Do:$$$ISERR(tSCdoc)&&pAddNackErrText tReplyAK5.SetValueAt($$$StatusDisplayString(tSCdoc),$$$AK5TransactionSetErrorText)
								
								Do:$IsObject(tReplyAK5) tReplyTS.AppendSegment(tReplyAK5)
								Set tNumSegs=tNumSegs+2
							}
							Set:($$$ISOK(tSCdoc)||(pBatchErrorAction="Note")) tNumAccepted=tNumAccepted+1
							Set tOrigDocs = tOrigDocs + 1
						} Else {
							Quit
						}
						Set tNumDocs = tNumDocs + 1
					}
				}
			}
			If "SNIP"'=tValMode {
				Set tSCgrp=$G($$$X12ValInfo(tGrpID,"Status"),$$$OK)
				#; fill in AK9: $$$AK9NumberofTransactionSetsInclu = 2, $$$AK9NumberofReceivedTransactionS = 3, $$$AK9NumberofAcceptedTransactionS = 4
				If $IsObject(tReplyAK9) {
					If tNumAccepted<tOrigDocs {
						If (0=tNumAccepted) || $Case(pBatchErrorAction,"All":1,"First":1,:0) {
							Do tReplyAK9.SetValueAt("R",$$$AK9FunctionalGroupAcknowledgeCo)
						} Else {
							Do tReplyAK9.SetValueAt("P",$$$AK9FunctionalGroupAcknowledgeCo)
						}
					} ElseIf $D($$$X12ValInfo(tGrpID,"Code"),tAK9Code) {
						Do tReplyAK9.SetValueAt(tAK9Code,$$$AK9FunctionalGroupAcknowledgeCo)
					}
					Do tReplyAK9.SetValueAt(tNumDocs,$$$AK9NumberofTransactionSetsInclu)
					Do tReplyAK9.SetValueAt(tOrigDocs,$$$AK9NumberofReceivedTransactionS)
					Do tReplyAK9.SetValueAt(tNumAccepted,$$$AK9NumberofAcceptedTransactionS)
					Do:$$$ISERR(tSCgrp)&&pAddNackErrText tReplyAK9.SetValueAt($$$StatusDisplayString(tSCgrp),$$$AK9FunctionalGroupErrorText)
				}
			}
			Do:$IsObject(tReplyAK9) tReplyTS.AppendSegment(tReplyAK9)
			Do:$IsObject(tReplySE) tReplySE.SetValueAt(tNumSegs,$$$SENumberofIncludedSegments), tReplyTS.AppendSegment(tReplySE)
			Set tSC=tReplyGroup.AddChild(2,tReplyTS)
			Set tNumGrps=tNumGrps+1
			
			If tUseChildGbl {
				Set tGrpID = $O($$$X12ChildDoc(tOriginalDocID,tGrpID))
				If tGrpID'="" {
					Set tGrp = ##class(EnsLib.EDI.X12.Document).%OpenId(tGrpID)
				} Else {
					Set tGrp=$$$NULLOREF
				}
			} Else {
				Set tGrp=pOriginalDoc.NextChild(tGrp)
				Set:$IsObject(tGrp) tGrpID = tGrp.getId()
			}
		}
		Do:$IsObject(tReplyGE) tReplyGE.SetValueAt(tNumGrps,$$$GENumberofTransactionSetsInclu), tReplyGroup.AppendSegment(tReplyGE)

		Set tSC=tReplyDoc.AddChild((2+(tHasTA1)),tReplyGroup)
		Set:$$$ISERR(tSC) pSC = $$$ADDSC(pSC,tSC)
	}
	If $IsObject(tReplyIEA) {
		Do tReplyIEA.SetValueAt($IsObject($G(tReplyGroup)),$$$IEANumberofIncludedFunctionalGr)
		Do tReplyDoc.AppendSegment(tReplyIEA)
	}
	If pCleanupTempValData {
		// If requested, cleanup ^IRIS.Temp global now that we no longer need it
		Do ..CleanupValidationData(pOriginalDoc.getId())
	}
	Quit tReplyDoc
}

/// Kill off validation data for the batch if there is any.
ClassMethod CleanupValidationData(pDocID As %Integer)
{
	Quit:""=pDocID

	Set tChild = ""
	For {
		Set tChild = $O($$$X12ChildDoc(pDocID,tChild)) Quit:""=tChild
		Set tGrandchild = ""
		For {
			Set tGrandchild = $O($$$X12ChildDoc(tChild,tGrandchild)) Quit:""=tGrandchild
			Kill $$$X12ValData(tGrandchild)
		}
		Kill $$$X12ValData(tChild)
	}
	Kill $$$X12ValData(pDocID)
}

/// Construct just the Interchange-level segments that are part of the reply to <param>pOriginalDoc</param>
ClassMethod ConstructReplyEnvelope(pOriginalDoc As EnsLib.EDI.X12.Document, ByRef pSC As %Status, ByRef pHasTA1 As %Boolean = 0, pAddNackErrText As %Boolean = 0, pLocalApplicationID As %String = "@:@", pCleanupTempValData As %Boolean = 0, Output pReplyIEA As EnsLib.EDI.X12.Segment, Output pInterchangeErr As %Boolean) As EnsLib.EDI.X12.Document [ Internal ]
{
	#dim tOriginalDocID = pOriginalDoc.getId()
	
	Set tSC=$G(pSC,$$$OK), pSC=$$$OK, pInterchangeErr = 0
	Set tReplyDoc=pOriginalDoc.%New($LB("",$E(pOriginalDoc.Separators,1,3)_pOriginalDoc.SegmentTerminator))
	If '$IsObject(tReplyDoc) Set pSC=$$$ERROR($$$EnsEDIX12ErrGeneral,"Failed to instantiate reply document for doc "_tOriginalDocID_"; status = "_$G(%objlasterror,$$$OK))  Quit $$$NULLOREF
	Set tReplyDoc.OriginalDocId=tOriginalDocID
	Set tCategory = pOriginalDoc.DocTypeCategory
	Do:""'=tCategory tReplyDoc.PokeDocType(tCategory_":Interchange")
	Set tISA=pOriginalDoc.GetSegmentAt(1)
	Set tReplyISA=pOriginalDoc.NewReplyHeaderSegs(tISA,pLocalApplicationID,.pReplyIEA,.pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
	Do:$IsObject(tReplyISA) tReplyDoc.AppendSegment(tReplyISA)

	If '$D($$$X12ValInfo(tOriginalDocID,"TA1"),tTA1String) {
		Set tTA1Code=##class(EnsLib.EDI.X12.Validator).GetTA1Code(tSC)
		Set tTA1=pOriginalDoc.NewReplyTA1Seg(tISA, tTA1Code, .pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
	} Else {
		Set tTA1 = ##class(EnsLib.EDI.X12.Segment).%New($LB(,,,tTA1String))
	}
	If $IsObject(tTA1) {
		Do:pAddNackErrText&&$$$ISERR(tSC) tTA1.SetValueAt($$$StatusDisplayString(tSC),$$$TA1InterchangeErrorText)
		#; Always include TA1 if Interchange-level error
		If $Case(tTA1.GetValueAt($$$TA1InterchangeNoteCode),"":0,$$$CodeTA1I18NoError:0,$$$CodeTA1I18InvalidContent:0,"999":0,:1) {
			Set pHasTA1 = 1
			Set pInterchangeErr = 1
		}
		If pHasTA1 { 
			Set pSC = tReplyDoc.AppendSegment(tTA1)
		}
	}

	If pCleanupTempValData {
		// If requested, cleanup ^IRIS.Temp global now that we no longer need it
		Do ..CleanupValidationData(pOriginalDoc.getId())
	}

	Quit tReplyDoc
}

ClassMethod SetTmpGblForFlagValidation(pDoc As EnsLib.EDI.X12.Document, pBatchErrorAction As %String = "Indiv", pValStatus As %Status) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tDocID As %Integer = pDoc.getId()

	If (pDoc.ParentId'="") {
		If $G($$$X12ValInfo(tDocID,"HasError"),0) {
			#; If child of pDoc has a validation error, and pDoc has a parent, take note of it in the parent
			Set $$$X12ValInfo($P(pDoc.ParentId,":"),"HasError")=1
		}
		#; Remember that this child document exists to make it easier to construct ACK or split the batch
		Set $$$X12ChildDoc($P(pDoc.ParentId,":"),tDocID)=pDoc.Name
	}
	If $$$ISERR(pValStatus) {
		Set $$$X12ValInfo(tDocID,"Code")= $Case(pBatchErrorAction,"Note":"E", :"R")
		If (pDoc.ParentId'="") {
			#; Note for the parent document that at least one of its children has a validation error
			Set $$$X12ValInfo($P(pDoc.ParentId,":"),"HasError")=1
		}
		If (pBatchErrorAction'="Note") {
			Set tSC = $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Document %1 was rejected due to validation failure: %2"),tDocID,$System.Status.GetErrorText(pValStatus)))
		} Else {
			Set tSC = $$$OK
		}
		Set $$$X12ValInfo(tDocID,"Status")= pValStatus
	} Else {
		If '$D($$$X12ValInfo(tDocID,"Code")) {
			Set $$$X12ValInfo(tDocID,"Code") = "A"
		}
		If '$D($$$X12ValInfo(tDocID,"Status")) {
			Set $$$X12ValInfo(tDocID,"Status") = $$$OK
		}
		If pDoc.ChildCount > 0 {
			If (pBatchErrorAction'="Indiv") {
				Set tChild=""
				For {
					Set tChild = $O($$$X12ChildDoc(tDocID,tChild),1,tName)	Quit:""=tChild
					Set tCode=$G($$$X12ValInfo(tChild,"Code"))
					If tCode="R" {
						Set $$$X12ValInfo(tDocID,"Code")=tCode
						Set tSC = $$$ERROR($$$EnsEDIX12ChildFailedValidation,tDocID,tName,tChild)
						Set $$$X12ValInfo(tDocID,"Status")=tSC
						#; Note that there was a validation error in a child of pDoc
						Set $$$X12ValInfo(tDocID,"HasError")=1
						Quit
					} ElseIf tCode="E" {
						Set $$$X12ValInfo(tDocID,"Code")=tCode
						#; Note that there was a validation error in a child of pDoc
						Set $$$X12ValInfo(tDocID,"HasError")=1
						Quit
					}
				}
			} Else {
				Set tErrCount = 0
				Set tChild = ""
				For {
					Set tChild = $O($$$X12ChildDoc(tDocID,tChild))	Quit:""=tChild
					Set tCode=$G($$$X12ValInfo(tChild,"Code"))
					If tCode="R" {
						Do $I(tErrCount)
					}
				}
				If pDoc.ChildCount = tErrCount {
					#; All child documents were rejected
					Set $$$X12ValInfo(tDocID,"Code") = "R"
					Set tSC = $$$ERROR($$$EnsEDIX12AllChildrenFailedValidation,tDocID)
					Set $$$X12ValInfo(tDocID,"Status") = tSC
				}  ElseIf (tErrCount > 0) {
					#; Some child document was rejected, but not all
					Set $$$X12ValInfo(tDocID,"Code") = "P"
					Set $$$X12ValInfo(tDocID,"HasError") = 1
				}
			}
		}
	}
	Quit tSC
}

ClassMethod DoValidateVSegment(pSeg As EnsLib.EDI.X12.Segment, pValSpec As %String, pSegNum As %Integer, pDocumentDocType, pQuitOnError As %Boolean = 1) As %Status [ Internal ]
{
	#dim tSC, tSC2 As %Status = $$$OK
	#dim tCategory, tDocType, tInfo, tFieldDat, tRequired, tDatatype As %String
	#dim tOrdinal, tSegCount, tFieldNum, tNumReps, tMaxUse, tMinLen, tFieldLen, tMaxLen, tCompNum As %Integer
	#dim tHasData, tIsValid As %Boolean
	#dim ex As %Exception.AbstractException
	
	Try {

		If (pSeg.DocTypeName = "") {
			Set tSC = $$$ERROR($$$EnsEDIX12CannotValidateNoSegName,pSegNum)
			Quit
		}
		If (pDocumentDocType = "") {
			Set tSC = $$$ERROR($$$EnsEDIX12CannotValidateNoCategory,pSegNum,pSeg.Name)
			Quit
		}
		
		Set tCategory = $P(pDocumentDocType,":",1)
		Set tDocType = $P(pDocumentDocType,":",2)
		Set tOrdinal = $P(pSeg.DocTypeName,"-",2)
		If '$Data($$$vaVSchemaGbl(tCategory,tDocType,"o",tOrdinal)) {
			Set tSC = $$$ERROR($$$EnsEDIX12CannotRetrieveSchema,pSegNum,pSeg.Name)
			Quit
		}

		Set tSegCount = pSeg.Count ; avoid repeated calls to CountGet()
		If (tSegCount > $O($$$vaVSchemaGbl(tCategory,tDocType,"o",tOrdinal,""),-1)) {
			Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12SegmentStructureError,pSegNum,pSeg.Name,pDocumentDocType_":"_pSeg.DocTypeName))
			Quit:pQuitOnError ; stop looking at the segment if not continuing after error
		}
		
		If pValSpec["x" {
			Set tSCTR3 = ..CheckTR3Rules(pDocumentDocType,pSeg,tOrdinal,pSegNum,,pQuitOnError,1)
			If $$$ISERR(tSCTR3) {
				Set tSC = $$$ADDSC(tSC,tSCTR3)
				Quit:pQuitOnError ; stop looking at the segment if not continuing after error
			}
		}

		Set tFieldNum = ""
		For {
			Set tFieldNum = $O($$$vaVSchemaGbl(tCategory,tDocType,"o",tOrdinal,tFieldNum),1,tInfo)
			Quit:(tFieldNum="")||(tFieldNum > tSegCount)

			Set tFieldDat = pSeg.GetValueAt(tFieldNum, pSeg.Separators, .tSC2)
			If ($$$ISERR(tSC2)) {
				Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CannotRetrieveValue,tFieldNum,pSegNum,pSeg.Name,$System.Status.GetErrorText(tSC2)))
				Quit:pQuitOnError
				Continue ; can only continue with this field if no error in getting it
			}
			
			If (pSeg.Name="ISA")&&$Case(tFieldNum,11:1,16:1,:0) {
				If tFieldNum=11 {
					Set tNumReps = 1
					Set tHasData = (tFieldDat '= "")
				} Else {
					Set tNumReps = $Length(tFieldDat,pSeg.RS)
					Set tHasData = ($Translate(tFieldDat, pSeg.RS,"") '= "")
				}
			} Else {
				Set tNumReps = $Length(tFieldDat,pSeg.RS)
				Set tHasData = ($tr(tFieldDat, pSeg.Separators, "") '= "") ; is anything left after removing separators?
			}
			
			Set tMaxUse = $S($E(tInfo)="E":$P(tInfo,"|",7),1:$P(tInfo,"|",6))
			If ((tNumReps > tMaxUse)&&(tMaxUse'="")) {
				If tMaxUse=1 {
					Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12ForbiddenRepetition,pSegNum,pSeg.Name,tFieldNum,pDocumentDocType_":"_pSeg.DocTypeName))
				} Else {
					Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12ExcessRepetition,pSegNum,pSeg.Name,tFieldNum,tMaxUse,pDocumentDocType_":"_pSeg.DocTypeName))
				}
				Quit:pQuitOnError
			}

			If (pValSpec["r")||(pValSpec["u") {
				Set tRequired = $P(tInfo,"|",3)
				If ((pValSpec["r") && ('tHasData) && (tRequired = "M")) {
					Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredFieldMissing,pSegNum,pSeg.Name,tFieldNum,pDocumentDocType_":"_pSeg.DocTypeName))
					Quit:pQuitOnError
				} ElseIf ((pValSpec["u") && tHasData && (tRequired=".")) {
					Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldIndustryUsageError,pSegNum,pSeg.Name,tFieldNum,pDocumentDocType_":"_pSeg.DocTypeName))
					Quit:pQuitOnError
				}
			}
			
			Continue:'tHasData||($Translate(pValSpec,"ltvc")=pValSpec) ;# don't do any more work if not interested in length, datatypes, code tables, or composite structures
			
			If ($E(tInfo)="E") {
				
				If (tNumReps > 1) {
					// if care about length, do preliminary testing that applies to entire field
					If (pValSpec["l") {
						Set tDatatype = $P(tInfo,"|",4)
						Set tMinLen = $P(tInfo,"|",5)
						Set tFieldLen = $length(tFieldDat)
						Set:(("-"=$E(tFieldDat,1))&&((tDatatype ?1"N".N))) tFieldLen = (tFieldLen-1) ;# optional - sign not counted in length
						Set:(tDatatype="R") tFieldLen = $L($TR(tFieldDat,"-.")) ;# sign and decimal not counted in length
			
						If (tFieldLen < tMinLen) { ; under min length
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMin,pSegNum,pSeg.Name,tFieldNum,tMinLen,pDocumentDocType_":"_pSeg.DocTypeName))
							Quit:pQuitOnError
						}
					}
					For tRep=1:1:tNumReps {
						Set tValue = $P(tFieldDat,pSeg.RS, tRep)
						Set tIsValid = ..ValidateVElement(tValue,pValSpec,tInfo,pQuitOnError,pDocumentDocType,tOrdinal_":"_tFieldNum,.tErrors)
						If 'tIsValid {
							If $D(tErrors("MinLen"),tMinLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMinRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tMinLen,pDocumentDocType_":"_pSeg.DocTypeName))
							}
							If $D(tErrors("MaxLen"),tMaxLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMaxRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tMaxLen,pDocumentDocType_":"_pSeg.DocTypeName))
							}
							If $D(tErrors("Datatype"),tDatatype)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldDatatypeValRepeating,tDatatype,pSegNum,pSeg.DocTypeName,tFieldNum,tRep))
							}
							If $D(tErrors("CodeTable"))#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12InvalidFieldValRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep))
							}
						}
						Quit:$$$ISERR(tSC)&&pQuitOnError
					}		
						
				} Else { ; no reps
					If ($P(tInfo,"|",4)="B") {
						// for binary datatype, actual length is specified by the immediately preceding data element (B.1.1.3.1.7 of Implementation Guide)
						Set tMaxLen = pSeg.GetValueAt(tFieldNum-1, pSeg.Separators)
						Set tInfo = $P(tInfo,"|",1,5)_"|"_tMaxLen_"|"_$P(tInfo,"|",7,*)
					}
					Set tIsValid = ..ValidateVElement(tFieldDat,pValSpec,tInfo,pQuitOnError,pDocumentDocType,tOrdinal_":"_tFieldNum,.tErrors)
					If 'tIsValid {
						If $D(tErrors("MinLen"),tMinLen)#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMin,pSegNum,pSeg.Name,tFieldNum,tMinLen,pDocumentDocType_":"_pSeg.DocTypeName))
						}
						If $D(tErrors("MaxLen"),tMaxLen)#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMax,pSegNum,pSeg.Name,tFieldNum,tMaxLen,pDocumentDocType_":"_pSeg.DocTypeName))
						}
						If $D(tErrors("Datatype"),tDatatype)#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldDatatypeVal,tDatatype,pSegNum,pSeg.DocTypeName,tFieldNum))
						}
						If $D(tErrors("CodeTable"))#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12InvalidFieldVal,pSegNum,pSeg.DocTypeName,tFieldNum))
						}
					}
				}						
			}
			// Test the composite structure
			If (($E(tInfo)="C") && (pValSpec["c")) {
				Set tItemName = $P(tInfo,"|",2)
				If tNumReps > 1 {
					For tRep=1:1:tNumReps {
						Set tValue = $P(tFieldDat,pSeg.RS, tRep)
						Set tIsValid = ..ValidateVComposite(tValue,pSeg.CS,pValSpec,tInfo,pQuitOnError,pDocumentDocType,tOrdinal_":"_tFieldNum,.tErrors)
						If 'tIsValid {
							If $D(tErrors(0,"Structure"))#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompositeStructureErrRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tItemName))
							}
							Set tCompNum = 0
							For {
								Set tCompNum = $O(tErrors(tCompNum))  Quit:tCompNum=""
								If $D(tErrors(tCompNum,"Required"))#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredCompMissingRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tCompNum,tItemName))
								}
								If $D(tErrors(tCompNum,"Usage"))#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompIndustryUsageErrRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tCompNum,tItemName))
								}
								If $D(tErrors(tCompNum,"MinLen"),tMinLen)#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMinRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tCompNum,tMinLen,tItemName))
								}
								If $D(tErrors(tCompNum,"MaxLen"),tMaxLen)#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMaxRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tCompNum,tMaxLen,tItemName))
								}
								If $D(tErrors(tCompNum,"Datatype"),tDatatype)#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompDatatypeValRepeating,tDatatype,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tCompNum))
								}
								If $D(tErrors(tCompNum,"CodeTable"))#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12InvalidCompValRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tCompNum))
								}
								If $D(tErrors(tCompNum,"Exclusion"),tErrVal)#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompExclusionCondViolatedRepeating,pSegNum,pSeg.DocTypeName,tFieldNum,tRep,tCompNum,tErrVal))
								}
								If $D(tErrors(tCompNum,"Missing"))#2 {
									Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ConditionalReqCompMissingRepeating,tCompNum,pSegNum,pSeg.DocTypeName,tFieldNum,tRep))
								}
							}
						}
						Quit:$$$ISERR(tSC)&&pQuitOnError
					}
				} Else {
					Set tIsValid = ..ValidateVComposite(tFieldDat,pSeg.CS,pValSpec,pQuitOnError,pDocumentDocType,tOrdinal_":"_tFieldNum,.tErrors)
					If 'tIsValid {
						If $D(tErrors(0,"Structure"))#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompositeStructureErr,pSegNum,pSeg.DocTypeName,tFieldNum,tItemName))
						}
						Set tCompNum = 0
						For {
							Set tCompNum = $O(tErrors(tCompNum))  Quit:tCompNum=""
							If $D(tErrors(tCompNum,"Required"))#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredCompMissing,pSegNum,pSeg.DocTypeName,tFieldNum,tCompNum,tItemName))
							}
							If $D(tErrors(tCompNum,"Usage"))#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompIndustryUsageErr,pSegNum,pSeg.DocTypeName,tFieldNum,tCompNum,tItemName))
							}
							If $D(tErrors(tCompNum,"MinLen"),tMinLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMin,pSegNum,pSeg.DocTypeName,tFieldNum,tCompNum,tMinLen,tItemName))
							}
							If $D(tErrors(tCompNum,"MaxLen"),tMaxLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMax,pSegNum,pSeg.DocTypeName,tFieldNum,tCompNum,tMaxLen,tItemName))
							}
							If $D(tErrors(tCompNum,"Datatype"),tDatatype)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompDatatypeVal,tDatatype,pSegNum,pSeg.DocTypeName,tFieldNum,tCompNum))
							}
							If $D(tErrors(tCompNum,"CodeTable"))#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12InvalidCompVal,pSegNum,pSeg.DocTypeName,tFieldNum,tCompNum))
							}
							If $D(tErrors(tCompNum,"Exclusion"),tErrVal)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompExclusionCondViolated,pSegNum,pSeg.DocTypeName,tFieldNum,tCompNum,tErrVal))
							}
							If $D(tErrors(tCompNum,"Missing"))#2 {
								Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ConditionalRequiredCompMissing,tCompNum,pSegNum,pSeg.DocTypeName,tFieldNum))
							}
						}
					}
				}
			}
			Quit:($$$ISERR(tSC) && pQuitOnError)
		}
		Quit:($$$ISERR(tSC) && pQuitOnError) ; quit with error if there is one and not continuing after error
		If ((tFieldNum'="") && (pValSpec["r")) { ; fewer fields in message than in schema and we care about required fields
			If "M"=$P(tInfo,"|",3) { ; required field
				set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredFieldMissing,pSegNum,pSeg.Name,tFieldNum,pDocumentDocType_":"_pSeg.DocTypeName))
				Quit:pQuitOnError
			}
			For {
				Set tFieldNum = $O($$$vaVSchemaGbl(tCategory,tDocType,"o",tOrdinal,tFieldNum),1,tInfo)
				Quit:""=tFieldNum
				If "M"=$P(tInfo,"|",3) {
					set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredFieldMissing,pSegNum,pSeg.Name,tFieldNum,pDocumentDocType_":"_pSeg.DocTypeName))
					Quit:pQuitOnError
				}
			}
		}
	} Catch ex {
		Set tSC = $S('pQuitOnError:$$$ADDSC(ex.AsStatus(),tSC),1:ex.AsStatus())
	}
	Quit tSC
}

ClassMethod ValidateVComposite(pValue, pSep, pValSpec, pQuitOnError, pDocType, pOrdinal, pErrors) As %Boolean [ Internal ]
{
	#dim tIsOkay,tIsOkayElem As %Boolean = 1
	#dim tCompCount,tCompNum As %Integer
	#dim tHasData As %Boolean
	#dim tInfo,tCompDat,tRequired As %String
	Kill pErrors
	
	Do {
		
		Set tCompCount = $L(pValue,pSep)
		#; first check don't have too many components
		If (tCompCount > $O($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",$P(pOrdinal,":"),$P(pOrdinal,":",2),""),-1)) {
			Set tIsOkay=0
			Set pErrors(0,"Structure")=""
			Quit:pQuitOnError ; stop looking at the field if not continuing after error
		}
		If pValSpec["x" {
			Set tCompInfo = $$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",$P(pOrdinal,":"),$P(pOrdinal,":",2))
			Set tCompName = $P(tCompInfo,"|",2)
			Set tIsOkay = '..CheckCompTR3Rules(pDocType,pValue,pSep,$P(pOrdinal,":"),tCompName,.pErrors,pQuitOnError)
			Quit:('tIsOkay && pQuitOnError)
		}
		Set tCompNum = ""
		For {
			Set tCompNum = $O($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",$P(pOrdinal,":"),$P(pOrdinal,":",2),tCompNum),1,tInfo)
			Quit:((tCompNum="")||(tCompNum>tCompCount))
			Set tCompDat = $P(pValue,pSep,tCompNum)
			
			Set tHasData = (tCompDat'= "")
			If (pValSpec["r")||(pValSpec["u") {
				Set tRequired = $P(tInfo,"|",3)
				If ((pValSpec["r") && ('tHasData) && (tRequired = "M")) {
					Set tIsOkay = 0
					Set pErrors(tCompNum,"Required")=""
					Quit:pQuitOnError
				} ElseIf ((pValSpec["u") && tHasData && (tRequired=".")) {
					Set tIsOkay = 0
					Set pErrors(tCompNum,"Usage")=""
					Quit:pQuitOnError
				}
			}
		
			Continue:'tHasData||($Translate(pValSpec,"ltv")=pValSpec) ;# don't do any more work if not interested in length, datatypes, code tables
			Set tIsOkayElem = ..ValidateVElement(tCompDat,pValSpec,tInfo,pQuitOnError,pDocType,pOrdinal_":"_tCompNum,.tErrors)
			Set tIsOkay = (tIsOkay && tIsOkayElem)
			Merge pErrors(tCompNum) = tErrors
			Quit:('tIsOkay && pQuitOnError)
		}
			
		If ((tCompNum'="") && (pValSpec["r")) { ; fewer components in message than in schema and we care about required fields
			If "M"=$P(tInfo,"|",3) { ; required field
				Set tIsOkay = 0
				Set pErrors(tCompNum,"Required")=""
				Quit:pQuitOnError
			}
			For {
				Set tCompNum = $O($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",$P(pOrdinal,":"),$P(pOrdinal,":",2),tCompNum),1,tInfo)
				Quit:""=tCompNum
				If "M"=$P(tInfo,"|",3) {
					Set tIsOkay = 0
					Set pErrors(tCompNum,"Required")=""
					Quit:pQuitOnError
				}
			}
		}

	} While 0
	
	Quit tIsOkay
}

ClassMethod ValidateVElement(pValue, pValSpec, pInfo, pQuitOnError, pDocType, pOrdinal, pErrors) As %Boolean [ Internal ]
{
	#dim tIsOkay As %Boolean = 1
	#dim tDatatype,tItemName As %String
	#dim tMinLen, tMaxLen,tLength, tCodeIndex As %String
	#dim tMatches As %Boolean
	Kill pErrors
	
	Do {
					
		Set tDatatype = $P(pInfo,"|",4)
		// if care about length, do preliminary testing that applies to entire field whether repeating or not
		If (pValSpec["l") {
			Set tMinLen = $P(pInfo,"|",5)
			Set tMaxLen = $P(pInfo,"|",6)
			Set tLength = $length(pValue)
			Set:(("-"=$E(pValue,1))&&((tDatatype ?1"N".N))) tLength = (tLength-1) ;# optional - sign not counted in length
			Set:(tDatatype="R") tLength = $L($TR(pValue,"-.")) ;# sign and decimal not counted in length
	
			If (tLength < tMinLen) { ; under min length
				Set tIsOkay = 0
				Set pErrors("MinLen") = tMinLen
				Quit:pQuitOnError
			} ElseIf ((tLength > tMaxLen)&&(tMaxLen'="")) { ; over the length restriction
				Set tIsOkay = 0
				Set pErrors("MaxLen") = tMaxLen
				Quit:pQuitOnError
			}
		}
		#; datatype test
		If (pValSpec["t")&&'$Case($P(pInfo,"|",2),"I02":1,"I04":1,:0) {
			Set tMatches = ..CheckDatatype(pValue,tDatatype)
			If 'tMatches {
				Set tIsOkay = 0
				Set pErrors("Datatype") = tDatatype
				Quit:pQuitOnError
			}
		}
		#; code table tests
		If ((pValSpec["v") || ((pValSpec["t") && (tDatatype="ID"))) {
			Set tItemName = $P(pInfo,"|",2)
			If $L(pOrdinal,":")>2 {
				Set tCodeIndex = $G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"c",tItemName,"l",$P(pOrdinal,":"),$P(pOrdinal,":",2),$P(pOrdinal,":",3))) // get the index for fetching values if defined
			} Else {
				Set tCodeIndex = $G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"c",tItemName,"l",$P(pOrdinal,":"),$P(pOrdinal,":",2))) // get the index for fetching values if defined
			}
			If ""'=tCodeIndex {
				#; test to see if value is among those allowed for this element
				If '$D($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"c",tItemName,"c",tCodeIndex,pValue)) {
					Set tIsOkay = 0
					Set pErrors("CodeTable")=""
					Quit:pQuitOnError
				}
			}
		}
	} While 0
	
	Quit tIsOkay
}

ClassMethod DoValidateNewSegment(pSeg As EnsLib.EDI.X12.Segment, pValSpec As %String, pSegNum As %Integer, pQuitOnError As %Boolean = 1) As %Status [ Internal ]
{
	#dim tSC, tSC2 As %Status = $$$OK
	#dim tCategory, tDocType, tInfo, tFieldDat, tRequired, tDatatype As %String
	#dim tSegCount, tFieldNum, tNumReps, tMaxUse, tMinLen, tFieldLen, tMaxLen, tCompNum As %Integer
	#dim tSegFound, tHasData, tIsValid As %Boolean
	#dim ex As %Exception.AbstractException
	
	Try {

		If (pSeg.Name = "") {
			Set tSC = $$$ERROR($$$EnsEDIX12CannotValidateNoSegName,pSegNum)
			Quit
		}
		If (pSeg.DocTypeCategory = "") {
			Set tSC = $$$ERROR($$$EnsEDIX12CannotValidateNoCategory,pSegNum,pSeg.Name)
			Quit
		}
		
		Set tCategory = pSeg.DocTypeCategory
		Set tDocType = pSeg.Name
		Set tSegFound = 0
		For {
			If $D($$$vaSchemaGbl(tCategory,"SS",tDocType),tSegData)#2 {
				Set tSegFound = 1
				Quit
			} ElseIf '$D($$$vaSchemaGbl(tCategory,"base"),tCategory) {
				Quit
			}
		}
		If 'tSegFound {
			Set tSC = $$$ERROR($$$EnsEDIX12CannotRetrieveSchema,pSegNum,pSeg.Name)
			Quit
		}

		Set tSegCount = pSeg.Count ; avoid repeated calls to CountGet()
		If (tSegCount > $ListLength(tSegData)) {
			Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12SegmentStructureError,pSegNum,pSeg.Name,pSeg.DocType))
			Quit:pQuitOnError ; stop looking at the segment if not continuing after error
		}

		Set tFieldNum = ""
		For tFieldNum=1:1:$ListLength(tSegData) {
			Quit:(tFieldNum > tSegCount)
			Set tInfo = $LG(tSegData,tFieldNum)

			Set tFieldDat = pSeg.GetValueAt(tFieldNum, pSeg.Separators, .tSC2)
			If ($$$ISERR(tSC2)) {
				Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CannotRetrieveValue,tFieldNum,pSegNum,pSeg.Name,$System.Status.GetErrorText(tSC2)))
				Quit:pQuitOnError
				Continue ; can only continue with this field if no error in getting it
			}
			
			If (pSeg.Name="ISA")&&$Case(tFieldNum,11:1,16:1,:0) {
				If tFieldNum=11 {
					Set tNumReps = 1
					Set tHasData = (tFieldDat '= "")
				} Else {
					Set tNumReps = $Length(tFieldDat,pSeg.RS)
					Set tHasData = ($Translate(tFieldDat, pSeg.RS,"") '= "")
				}
			} Else {
				Set tNumReps = $Length(tFieldDat,pSeg.RS)
				Set tHasData = ($tr(tFieldDat, pSeg.Separators, "") '= "") ; is anything left after removing separators?
			}
			
			Set tMaxUse = $LG(tInfo,3)
			If ((tNumReps > tMaxUse) && (tMaxUse'="")) {
				If tMaxUse=1 {
					Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12ForbiddenRepetition,pSegNum,pSeg.Name,tFieldNum,pSeg.DocType))
				} Else {
					Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12ExcessRepetition,pSegNum,pSeg.Name,tFieldNum,tMaxUse,pSeg.DocType))
				}
				Quit:pQuitOnError
			}

			If (pValSpec["r") {
				Set tRequired = $LG(tInfo,5)
				If (('tHasData) && (tRequired = "M")) {
					Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredFieldMissing,pSegNum,pSeg.Name,tFieldNum,pSeg.DocType))
					Quit:pQuitOnError
				}
			}
			
			Continue:'tHasData||($Translate(pValSpec,"ltc")=pValSpec) ;# don't do any more work if not interested in length, datatypes, or composite structures
			
			Set tDatatype = $LG(tInfo,1)
			
			If (tDatatype'[":") {
				// Simple element - not composite
				Set tDatatype = $E(tDatatype,2,*-1)
				If (tNumReps > 1) {
					// if care about length, do preliminary testing that applies to entire field
					If (pValSpec["l") {
						Set tMinLen = $LG(tInfo,2)
						Set tFieldLen = $length(tFieldDat)
						Set:(("-"=$E(tFieldDat,1))&&((tDatatype ?1"N".N))) tFieldLen = (tFieldLen-1) ;# optional - sign not counted in length
						Set:(tDatatype="R") tFieldLen = $L($TR(tFieldDat,"-.")) ;# sign and decimal not counted in length
			
						If (tFieldLen < tMinLen) { ; under min length
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMin,pSegNum,pSeg.Name,tFieldNum,tMinLen,pSeg.DocType))
							Quit:pQuitOnError
						}
					}
					For tRep=1:1:tNumReps {
						Set tValue = $P(tFieldDat,pSeg.RS, tRep)
						Set tIsValid = ..ValidateNewElement(tValue,pValSpec,tInfo,pQuitOnError,.tErrors)
						If 'tIsValid {
							If $D(tErrors("MinLen"),tMinLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMinRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tMinLen,pSeg.DocType))
							}
							If $D(tErrors("MaxLen"),tMaxLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMaxRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tMaxLen,pSeg.DocType))
							}
							If $D(tErrors("Datatype"),tDatatype)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldDatatypeValRepeating,tDatatype,pSegNum,pSeg.Name,tFieldNum,tRep))
							}
						}
						Quit:$$$ISERR(tSC)&&pQuitOnError
					}		
						
				} Else { ; no reps
					If (tDatatype="B") {
						// for binary datatype, actual length is specified by the immediately preceding data element (B.1.1.3.1.7 of Implementation Guide)
						Set $List(tInfo,4) = pSeg.GetValueAt(tFieldNum-1, pSeg.Separators)
					}
					If (pSeg.Name="ISA")&&$Case(tFieldNum,2:1,4:1,:0) {
						// For ISA02 and ISA04 avoid performing DataType validation because all spaces is allowed for these elements even though not allowed for AN (string) datatype
						Set $List(tInfo,1)=""
					}
					Set tIsValid = ..ValidateNewElement(tFieldDat,pValSpec,tInfo,pQuitOnError,.tErrors)
					If 'tIsValid {
						If $D(tErrors("MinLen"),tMinLen)#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMin,pSegNum,pSeg.Name,tFieldNum,tMinLen,pSeg.DocType))
						}
						If $D(tErrors("MaxLen"),tMaxLen)#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldSizeMax,pSegNum,pSeg.Name,tFieldNum,tMaxLen,pSeg.DocType))
						}
						If $D(tErrors("Datatype"),tDatatype)#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12FieldDatatypeVal,tDatatype,pSegNum,pSeg.Name,tFieldNum))
						}
					}
				}						
			} Elseif (pValSpec["c") {
				
				Set tItemName = tDatatype
				If '$D($$$vaSchemaGbl($P(tItemName,":"),"CS",$P(tItemName,":",2)),tCompStruct) {
					Set tSC = $$$ERROR($$$EnsEDIX12CannotRetrieveSchema,tDatatype,pSegNum,pSeg.Name,tFieldNum)
					Quit
				}
				// Test the composite structure
				If tNumReps > 1 {
					For tRep=1:1:tNumReps {
						Set tValue = $P(tFieldDat,pSeg.RS, tRep)
						Set tIsValid = ..ValidateNewComposite(tValue,pSeg.CS,pValSpec,tInfo,pQuitOnError,tCompStruct,.tErrors)
						If 'tIsValid {
							If $D(tErrors(0,"Structure"))#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompositeStructureErrRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tItemName))
							}
							Set tCompNum = 0
							For {
								Set tCompNum = $O(tErrors(tCompNum))  Quit:tCompNum=""
								If $D(tErrors(tCompNum,"Required"))#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredCompMissingRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tCompNum,tItemName))
								}
								If $D(tErrors(tCompNum,"MinLen"),tMinLen)#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMinRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tCompNum,tMinLen,tItemName))
								}
								If $D(tErrors(tCompNum,"MaxLen"),tMaxLen)#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMaxRepeating,pSegNum,pSeg.Name,tFieldNum,tRep,tCompNum,tMaxLen,tItemName))
								}
								If $D(tErrors(tCompNum,"Datatype"),tDatatype)#2 {
									Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompDatatypeValRepeating,tDatatype,pSegNum,pSeg.Name,tFieldNum,tRep,tCompNum))
								}
							}
						}
						Quit:$$$ISERR(tSC)&&pQuitOnError
					}
				} Else {
					Set tIsValid = ..ValidateNewComposite(tFieldDat,pSeg.CS,pValSpec,pQuitOnError,tCompStruct,.tErrors)
					If 'tIsValid {
						If $D(tErrors(0,"Structure"))#2 {
							Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompositeStructureErr,pSegNum,pSeg.Name,tFieldNum,tItemName))
						}
						Set tCompNum = 0
						For {
							Set tCompNum = $O(tErrors(tCompNum))  Quit:tCompNum=""
							If $D(tErrors(tCompNum,"Required"))#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12RequiredCompMissing,pSegNum,pSeg.Name,tFieldNum,tCompNum,tItemName))
							}
							If $D(tErrors(tCompNum,"MinLen"),tMinLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMin,pSegNum,pSeg.Name,tFieldNum,tCompNum,tMinLen,tItemName))
							}
							If $D(tErrors(tCompNum,"MaxLen"),tMaxLen)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompSizeMax,pSegNum,pSeg.Name,tFieldNum,tCompNum,tMaxLen,tItemName))
							}
							If $D(tErrors(tCompNum,"Datatype"),tDatatype)#2 {
								Set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsEDIX12CompDatatypeVal,tDatatype,pSegNum,pSeg.Name,tFieldNum,tCompNum))
							}

						}
					}
				}
			}
			Quit:($$$ISERR(tSC) && pQuitOnError)
		}
		Quit:($$$ISERR(tSC) && pQuitOnError) ; quit with error if there is one and not continuing after error
		If ((tSegCount<$LL(tSegData)) && (pValSpec["r")) { ; fewer fields in message than in schema and we care about required fields
			Set tInfo = $LG(tSegData,tFieldNum)
			If "M"=$LG(tInfo,5) { ; required field
				set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsErrGeneral, $$$FormatText($$$Text("Required field missing in segment %1: %2.  Missing field %3 which is required in segment structure %4."),pSegNum,pSeg.Name,tFieldNum,pSeg.DocType)))
				Quit:pQuitOnError
			}
			For {
				Quit:$I(tFieldNum)>$LL(tSegData)
				Set tInfo = $LG(tSegData,tFieldNum)
				If "M"=$L(tInfo,5) {
					set tSC = $$$ADDSC(tSC, $$$ERROR($$$EnsErrGeneral, $$$FormatText($$$Text("Required field missing in segment %1: %2.  Missing field %3 which is required in segment structure %4."),pSegNum,pSeg.Name,tFieldNum,pSeg.DocType)))
					Quit:pQuitOnError
				}
			}
		}
	} Catch ex {
		Set tSC = $S('pQuitOnError:$$$ADDSC(ex.AsStatus(),tSC),1:ex.AsStatus())
	}
	Quit tSC
}

ClassMethod ValidateNewComposite(pValue, pSep, pValSpec, pQuitOnError, pStructure, pErrors) As %Boolean [ Internal ]
{
	#dim tIsOkay,tIsOkayElem As %Boolean = 1
	#dim tCompCount,tCompNum As %Integer
	#dim tHasData As %Boolean
	#dim tInfo,tCompDat,tRequired As %String
	Kill pErrors
	
	Do {
		
		Set tCompCount = $L(pValue,pSep)
		#; first check don't have too many components
		If (tCompCount > $LL(pStructure)) {
			Set tIsOkay=0
			Set pErrors(0,"Structure")=""
			Quit:pQuitOnError ; stop looking at the field if not continuing after error
		}
		Set tCompNum = ""
		For tCompNum=1:1:$LL(pStructure) {
			Quit:(tCompNum>tCompCount)
			Set tInfo = $LG(pStructure,tCompNum)
			Set tCompDat = $P(pValue,pSep,tCompNum)
			
			Set tHasData = (tCompDat'= "")
			If (pValSpec["r") {
				Set tRequired = $LG(tInfo,5)
				If (('tHasData) && (tRequired = "M")) {
					Set tIsOkay = 0
					Set pErrors(tCompNum,"Required")=""
					Quit:pQuitOnError
				} 
			}
		
			Continue:'tHasData||($Translate(pValSpec,"ltv")=pValSpec) ;# don't do any more work if not interested in length, datatypes, code tables
			Set tIsOkayElem = ..ValidateNewElement(tCompDat,pValSpec,tInfo,pQuitOnError,.tErrors)
			Set tIsOkay = (tIsOkay && tIsOkayElem)
			Merge pErrors(tCompNum) = tErrors
			Quit:('tIsOkay && pQuitOnError)
		}
			
		If ((tCompCount<$LL(pStructure)) && (pValSpec["r")) { ; fewer components in message than in schema and we care about required fields
			Set tInfo = $LG(pStructure,tCompNum)
			If "M"=$LG(tInfo,5) { ; required field
				Set tIsOkay = 0
				Set pErrors(tCompNum,"Required")=""
				Quit:pQuitOnError
			}
			For {
				Quit:$I(tCompNum)>$LL(pStructure)
				Set tInfo = $LG(pStructure,tCompNum)
				If "M"=$LG(tInfo,5) {
					Set tIsOkay = 0
					Set pErrors(tCompNum,"Required")=""
					Quit:pQuitOnError
				}
			}
		}

	} While 0
	
	Quit tIsOkay
}

ClassMethod ValidateNewElement(pValue, pValSpec, pInfo, pQuitOnError, pErrors) As %Boolean [ Internal ]
{
	#dim tIsOkay As %Boolean = 1
	#dim tDatatype As %String
	#dim tMinLen, tMaxLen, tLength As %Integer
	#dim tMatches As %Boolean
	Kill pErrors
	
	Do {
					
		Set tDatatype = $E($LG(pInfo,1),2,*-1)
		// if care about length, do preliminary testing that applies to entire field whether repeating or not
		If (pValSpec["l") {
			Set tMinLen = $LG(pInfo,2)
			Set tMaxLen = $LG(pInfo,4)
			Set tLength = $length(pValue)
			Set:(("-"=$E(pValue,1))&&((tDatatype ?1"N".N))) tLength = (tLength-1) ;# optional - sign not counted in length
			Set:(tDatatype="R") tLength = $L($TR(pValue,"-.")) ;# sign and decimal not counted in length
	
			If (tLength < tMinLen) { ; under min length
				Set tIsOkay = 0
				Set pErrors("MinLen") = tMinLen
				Quit:pQuitOnError
			} ElseIf ((tLength > tMaxLen)&&(tMaxLen'="")) { ; over the length restriction
				Set tIsOkay = 0
				Set pErrors("MaxLen") = tMaxLen
				Quit:pQuitOnError
			}
		}
		#; datatype test
		If (pValSpec["t") {
			Set tMatches = ..CheckDatatype(pValue,tDatatype)
			If 'tMatches {
				Set tIsOkay = 0
				Set pErrors("Datatype") = tDatatype
				Quit:pQuitOnError
			}
		}
	} While 0
	
	Quit tIsOkay
}

ClassMethod CheckDatatype(pValue, pDatatype) As %Boolean [ Internal ]
{
	#dim tMatches As %Boolean = 1
	#dim tMonth As %Integer
	
	If pDatatype = "R" {
		// Decimal
		#; "numeric values that have a varying number of decimal positions"
		Set tMatches = (pValue ? 0.1"-"0.N0.1".".N)
	} ElseIf pDatatype = "ID" {
		// Identifier
		#; "An identified data element always contains a value from a predefined list of codes"
		#; will need to code table check - don't yet know if it meets criteria
		Set tMatches = 1 ; we don't yet have evidence to the contrary
	} ElseIf pDatatype = "AN" {
		// String
		#; "... must contains at least on non-space character"
		Set tMatches = ($L($TR(pValue," ")) > 0)
	} ElseIf pDatatype = "DT" {
		// Date
		#; YYMMDD or CCYYMMDD
		If $zstrip(pValue,"*N")'="" {
			Set tMatches = 0
		} Else {
			Set tMonth = $E(pValue,*-3,*-2)
			If (tMonth < 1) || (tMonth > 12) {
				Set tMatches = 0
			} ElseIf (($E(pValue,*-1,*) < 1) || ($E(pValue,*-1,*)>$Case(tMonth,2:29,4:30,6:30,9:30,11:30,:31))) {
				Set tMatches = 0
			}
		}
	} ElseIf pDatatype = "TM" {
		// Time
		#; HHMMSSd...d
		If $zstrip(pValue,"*N")'="" {
			Set tMatches = 0
		} ElseIf (($E(pValue,1,2) < 0) || ($E(pValue,1,2) > 23)) {
			Set tMatches = 0
		} ElseIf (($L(pValue) > 2) && ($E(pValue,3,4) < 0) || ($E(pValue,3,4) > 59)) {
			Set tMatches = 0
		} ElseIf (($L(pValue) > 4) && ($E(pValue,5,6) < 0) || ($E(pValue,5,6) > 59)) {
			Set tMatches = 0
		}
	} ElseIf pDatatype = "B" {
	} ElseIf pDatatype ? 1"N".N {
		// Numeric
		#; "A numeric data element is represented by one or more digits with an optional leading sign... The plus sign must not be transmitted"
		Set tMatches = (pValue ? 0.1"-"1.N)
	}
	Quit tMatches
}

ClassMethod PerformSNIPInterchangeVal(pOriginalDoc As EnsLib.EDI.X12.Document, pSC As %Status = {$$$OK}, pSNIPLevel As %Integer = 1, pBatchErrorAction As %String = "Indiv") As %Status [ Internal ]
{
	#dim tSC,tStatus As %Status = $$$OK
	#dim tTA105Code As %String = $$$CodeTA1I18NoError
	#dim tHasGroupErrors,tSkipChildren As %Boolean = 0
	#dim tNumAccepted As %Integer = 0
	#dim tNumGroups As %Integer = 0
	#dim tOriginalDocID As %Integer = pOriginalDoc.getId()
	Try {
		Set tTA105Code = ##class(EnsLib.EDI.X12.Validator).GetTA1Code(pSC,pOriginalDoc)
		Set:(tTA105Code="999") tTA105Code = $$$CodeTA1I18NoError
		Set tTA1=pOriginalDoc.NewReplyTA1Seg(pOriginalDoc.GetSegmentAt(1), tTA105Code, .tSC, ("Note"'=pBatchErrorAction))
		If $IsObject(tTA1) {
			Set $$$X12ValInfo(tOriginalDocID,"TA1")=$E(pOriginalDoc.Separators,1,3)_$E(tTA1.OutputToString(),1,*-1)
			If pOriginalDoc.DocType="" {
				Set:("Note"'=pBatchErrorAction) $$$X12ValInfo(tOriginalDocID,"HasError")=1
				$$$ThrowStatus($$$ERROR($$$EnsEDIX12CannotValidateNoDocType))
			}
			If $$$CodeTA1I17Rejected=tTA1.GetValueAt($$$TA1InterchangeAcknowledgmentCod) {
				Set $$$X12ValInfo(tOriginalDocID,"HasError")=1
				Set:("First"=pBatchErrorAction) tSkipChildren = 1
			}
		}

		If 'tSkipChildren {
			#; Loop over source documents and get the status for each
			Set tDoc=$$$NULLOREF
			For {
				Set tDoc=pOriginalDoc.NextChild(tDoc)  Quit:'$IsObject(tDoc)
				Continue:tDoc.Name'="Group"
				Set tNumGroups = $I(tNumGroups)
				Set tDocID = tDoc.getId()
				If '$D($$$X12ValInfo(tDocID,"Status"),tSCgroup) {
					If $$$ISERR(..PerformSNIPGroupValidation(tDoc,.tHasGroupErrors,pSNIPLevel,pBatchErrorAction)) {
						Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Attempted SNIP validation of child document %1 failed"),tDocID)))
						#; Add error code 024 if there is an error at the Functional Group level
						If tHasGroupErrors&&$IsObject(tTA1)&&(tTA105Code=$$$CodeTA1I18NoError) {
							Set $P($$$X12ValInfo(tOriginalDocID,"TA1"),pOriginalDoc.ElementSeparator,($$$TA1InterchangeNoteCode + 2)) = $$$CodeTA1I18InvalidContent
							Set $P($$$X12ValInfo(tOriginalDocID,"TA1"),pOriginalDoc.ElementSeparator,($$$TA1InterchangeAcknowledgmentCod + 2)) = $Case(pBatchErrorAction,"Note": $$$CodeTA1I17AcceptedButErrorsNoted, : $$$CodeTA1I17Rejected)
							#; Must set tTA105Code here so that we will set the right return code
							Set tTA105Code = $$$CodeTA1I18InvalidContent
						}
						#; Note that there was a validation error within this batch even if Interchange itself not rejected
						Set $$$X12ValInfo(tOriginalDocID,"HasError")=1
					}
					Set tSCgroup = $G($$$X12ValInfo(tDocID,"Status"))
				} ElseIf $$$ISERR(tSCgroup)&&$IsObject(tTA1)&&(tTA105Code=$$$CodeTA1I18NoError) {
					#; Function Group Sytax Error Codes only included if error is at Functional Group level - we don't need to add TS errors to the TA1
					If ""'=$P($G($$$X12ValInfo(tDocID,"AK9")),pOriginalDoc.ElementSeparator,2+$$$AK9FunctionalGroupSyntaxErrorCo,*) {
						Set $P($$$X12ValInfo(tOriginalDocID,"TA1"),pOriginalDoc.ElementSeparator,($$$TA1InterchangeNoteCode + 2)) = $$$CodeTA1I18InvalidContent
						Set $P($$$X12ValInfo(tOriginalDocID,"TA1"),pOriginalDoc.ElementSeparator,($$$TA1InterchangeAcknowledgmentCod + 2)) = $Case(pBatchErrorAction,"Note": $$$CodeTA1I17AcceptedButErrorsNoted, : $$$CodeTA1I17Rejected)
						#; Must set tTA105Code here so that we will set the right return code
						Set tTA105Code = $$$CodeTA1I18InvalidContent
					}
					#; Note that there was a validation error within this batch even if Interchange itself not rejected
					Set $$$X12ValInfo(tOriginalDocID,"HasError")=1
				}
				If $G($$$X12ValInfo(tDocID,"HasError"),0) {
					#; Group not errored, but Transaction Set within the group is - pass this along to the Interchange
					Set $$$X12ValInfo(tOriginalDocID,"HasError")=1
				}
				
				#; Remember that this child document existed so we can report about it in the ACK message
				Set $$$X12ChildDoc(tOriginalDocID,tDocID)=tDoc.Name

				If $$$ISERR(tSCgroup) {
					If $Case(pBatchErrorAction,"First":1,"All":1,:0){
						#; Must set tTA105Code here so that we will set the right return code
						Set tTA105Code = $$$CodeTA1I18InvalidContent
					}
					Quit:("First"=pBatchErrorAction)
				} Else {
					Set tNumAccepted = $I(tNumAccepted)
				}
			}
			If ("Indiv"=pBatchErrorAction) {
				Set tErrCount = 0
				Set tChild = ""
				For {
					Set tChild = $O($$$X12ChildDoc(tOriginalDocID,tChild))	Quit:""=tChild
					Set tCode=$G($$$X12ValInfo(tChild,"Code"))
					If tCode="R" {
						Do $I(tErrCount)
					}
				}
				If pOriginalDoc.ChildCount = tErrCount {
					#; All child documents were rejected
					Set tSC = $$$ERROR($$$EnsEDIX12AllChildrenFailedValidation,tOriginalDocID)
				}
			}
		}
		Set:$$$ISERR(tSC) tSC = $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Attempted SNIP validation of document %1 failed due to error '%2'"),tOriginalDocID,$System.Status.GetErrorText(tSC)))
		Set tStatus = tSC
		If (($$$CodeTA1I18NoError=tTA105Code)) {
			Set tReplyCode = $$$CodeTA1I17Accepted
		} ElseIf ("Note"=pBatchErrorAction)&&$$$ISOK(tSC)&&tNumAccepted {
			Set tReplyCode = $$$CodeTA1I17AcceptedButErrorsNoted
		} ElseIf ($$$CodeTA1I18InvalidContent=tTA105Code) {
			Set tReplyCode = $$$CodeTA1I17Accepted
			Set:'$$$ISERR(tStatus) tStatus = $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Document %1 failed SNIP validation due to validation failure(s) of child document(s)"),tOriginalDocID))
		} Else {
			Set tReplyCode = $$$CodeTA1I17Rejected
			Set:'$$$ISERR(tStatus) tStatus = $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Document %1 failed SNIP validation"),tOriginalDocID))
		}
		Set $$$X12ValInfo(tOriginalDocID,"Code")=tReplyCode

	} Catch ex {
		Set tSC = $$$ADDSC(tSC,ex.AsStatus())
		Set tStatus = $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Attempted SNIP validation of document %1 failed due to error '%2'"),tOriginalDocID,$System.Status.GetErrorText(tSC)))		
	}

	Set $$$X12ValInfo(tOriginalDocID,"Status")=tStatus
	Quit tStatus
}

ClassMethod PerformSNIPGroupValidation(pOriginalDoc As EnsLib.EDI.X12.Document, ByRef pHasGroupErrs As %Boolean = 0, pSNIPLevel As %Integer = 1, pBatchErrorAction As %String = "Indiv") As %Status [ Internal ]
{
	Try {
		#dim tSC,tStatus As %Status = $$$OK
		#dim tAK9ErrCodes,tTSCode,tReplyAK9 As %String = ""
		#dim tAK9Code As %String = $$$CodeAK9715Accepted
		#dim tST = pOriginalDoc.GetSegmentAt(1)
		#dim tDocID = pOriginalDoc.getId()
		#dim tOrigDocs, tNumAccepted, tErrCount As %Integer = 0
		#dim tNumDocs As %Integer = pOriginalDoc.ChildCount
		#dim tDoc As EnsLib.EDI.X12.Document
		#dim tEleSep = pOriginalDoc.ElementSeparator
		#dim tReplyCode As %String = ""
		
		Set tAK9ErrCodes = ##class(EnsLib.EDI.X12.Validator).Get997GroupCodes(,pOriginalDoc)
		Set pHasGroupErrs = (""'=tAK9ErrCodes)

		If ""=pOriginalDoc.DocType {
			Do pOriginalDoc.PokeDocType(pOriginalDoc.resolveChildDocType())
		}
		Set $P(tReplyAK9,tEleSep,$$$AK9NumberofReceivedTransactionS) = pOriginalDoc.GetValueAt("GE:"_$$$GENumberofTransactionSetsInclu)
		#; Populate Error Code fields if there are errors to report
		For i=1:1:5 {
			Set tOneCode=$ZStrip($P(tAK9ErrCodes,",",i),"<>W")
			#; Field 5 only included if Field 1 = E or R
			#; Fields 6-9 only included if Field 1 = E or R, previous field used, and there are (additional) error codes to report
			Continue:$Case(tOneCode,"":1,0:1,"00":1,$$$CodeTA1I18NoError:1,:0)
			Set $P(tReplyAK9,tEleSep,$$$AK9FunctionalGroupSyntaxErrorCo+tErrCount) = tOneCode
			Set tErrCount = $I(tErrCount)
		}
		If 'tErrCount || ("First"'=pBatchErrorAction) {
		
			Set tReplyType = ##class(EnsLib.EDI.X12.Document).DetermineReplyVersion(pOriginalDoc.GetValueAt("GS:"_$$$GSVersionReleaseIndustryIdenti))
			#; AK5 will be IK5 instead if version >= 5010 and HIPAA standard transaction
			Set tGSGreater = (tReplyType>997)
			
			#; Loop over source documents and get the status for each
			Set tDoc=$$$NULLOREF
			For {
				Set tDoc=pOriginalDoc.NextChild(tDoc)  Quit:'$IsObject(tDoc)
				Set tTSid = tDoc.getId()
				If '$D($$$X12ValInfo(tTSid,"Status")) {
					If $$$ISERR(..PerformSNIPTSValidation(tDoc,pSNIPLevel,tGSGreater,pBatchErrorAction)) {
						Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Attempted SNIP validation of child document %1 failed"),tTSid)))
					}
				}
				Set tTSCode = $G($$$X12ValInfo(tTSid,"Code"))
				If $Case(tTSCode,$$$CodeAK5717Rejected:1,$$$CodeAK5717AcceptedButErrorsNoted:1,:0) {
					#; Note that there was a validation error within this batch even if the Group itself was not rejected
					Set $$$X12ValInfo(tDocID,"HasError")=1
					If pOriginalDoc.ParentId'="" {
						Set $$$X12ValInfo($P(pOriginalDoc.ParentId,":"),"HasError")=1
						Set $$$X12ChildDoc($P(pOriginalDoc.ParentId,":"),tDocID) = pOriginalDoc.Name
					}
				}
				#; Remember that this child document existed so we can report about it in the ACK message
				Set $$$X12ChildDoc(tDocID,tTSid)=tDoc.Name
				Set tOrigDocs=tOrigDocs+1
				Set:$Case(tTSCode,$$$CodeAK5717Accepted:1,$$$CodeAK5717AcceptedButErrorsNoted:1,:0) tNumAccepted=tNumAccepted+1
				Set:(tTSCode=$$$CodeAK5717AcceptedButErrorsNoted) tAK9Code = $$$CodeAK9715AcceptedButErrorsNoted
				Quit:("First"=pBatchErrorAction)&&($$$CodeAK5717Rejected=tTSCode)
			}

			#; Set the appropriate Functional Group Acknowledgement Code based on Transaction Set results
			If tNumAccepted<tOrigDocs {
				If (0=tNumAccepted) || $Case(pBatchErrorAction,"All":1,"First":1,:0) {
					Set tAK9Code = $$$CodeAK9715Rejected
				} Else {
					Set tAK9Code = $$$CodeAK9715PartiallyAccepted
				}
			}
		}
		#; fill in AK9: $$$AK9FunctionalGroupAcknowledgeCo = 1, $$$AK9NumberofTransactionSetsInclu = 2, $$$AK9NumberofReceivedTransactionS = 3, $$$AK9NumberofAcceptedTransactionS = 4
		Set:""'=tAK9ErrCodes tAK9Code = $S("Note"=pBatchErrorAction:$$$CodeAK9715AcceptedButErrorsNoted ,1:$$$CodeAK9715Rejected)
		Set $P(tReplyAK9,tEleSep,$$$AK9FunctionalGroupAcknowledgeCo)=tAK9Code
		Set $P(tReplyAK9,tEleSep,$$$AK9NumberofTransactionSetsInclu)=tNumDocs
		Set $P(tReplyAK9,tEleSep,$$$AK9NumberofReceivedTransactionS)=tOrigDocs
		Set $P(tReplyAK9,tEleSep,$$$AK9NumberofAcceptedTransactionS)=tNumAccepted
		Set $$$X12ValInfo(tDocID,"AK9")=$E(pOriginalDoc.Separators,1,3)_"AK9"_tEleSep_tReplyAK9
	} Catch ex {
		Set tSC = $$$ADDSC(tSC,ex.AsStatus())
	}
	Set:$$$ISERR(tSC) tSC = $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Attempted SNIP validation of document %1 failed due to error '%2'"),tDocID,$System.Status.GetErrorText(tSC)))
	Set tStatus = tSC
	If (tNumAccepted = tOrigDocs) && (""=tAK9ErrCodes) {
		Set tReplyCode = $$$CodeAK9715Accepted
	} ElseIf "Note"=pBatchErrorAction {
		Set tReplyCode = $$$CodeAK9715AcceptedButErrorsNoted
	} ElseIf ("Indiv"=pBatchErrorAction)&&(""=tAK9ErrCodes)&&(tNumAccepted>0) {
		Set tReplyCode = $$$CodeAK9715PartiallyAccepted
	} Else {
		Set tReplyCode = $$$CodeAK9715Rejected
		Set tStatus = $$$ADDSC(tStatus,$$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Document %1 failed SNIP validation"),tDocID)))
	}
	Set tHasError = (tReplyCode '= $$$CodeAK9715Accepted)
	Set $$$X12ValInfo(tDocID,"HasError")=tHasError
	If pOriginalDoc.ParentId'="" {
		Set:tHasError $$$X12ValInfo($P(pOriginalDoc.ParentId,":"),"HasError")=1
		Set $$$X12ChildDoc($P(pOriginalDoc.ParentId,":"),tDocID) = pOriginalDoc.Name
	}
	Set $$$X12ValInfo(tDocID,"Code")=tReplyCode
	Set $$$X12ValInfo(tDocID,"Status")=tStatus
	Quit tStatus
}

ClassMethod PerformSNIPTSValidation(pOriginalDoc As EnsLib.EDI.X12.Document, pSNIPLevel As %Integer = 1, pGSGreater As %Boolean = 1, pBatchErrorAction As %String = "Indiv") As %Status [ Internal ]
{
	#dim tSC,tStatus As %Status = $$$OK
	#dim tSegCount,tOneSegCode, tErrCount As %Integer = 0
	#dim tAK5Codes, tReplyCode As %String = ""
	#dim tHasSegErrors As %Boolean = 0
	#dim tCompSep = pOriginalDoc.ComponentSeparator
	#dim tEleSep = pOriginalDoc.ElementSeparator
	#dim tSeparators = $E(pOriginalDoc.Separators,1,3)
	
	Try {
		#dim tST As EnsLib.EDI.X12.Segment = pOriginalDoc.GetSegmentAt(1)
		#dim tDocID As %Integer = pOriginalDoc.getId()
		#dim tOriginalSegCount As %Integer = pOriginalDoc.SegCount
		#dim tReplyAK2, tReplyAK5 As EnsLib.EDI.X12.Segment
		If ""=pOriginalDoc.DocType {
			Do pOriginalDoc.PokeDocType(pOriginalDoc.resolveChildDocType())
		}
		#dim tTSDocType As %String = $Case($E(pOriginalDoc.DocType),"+":$E(pOriginalDoc.DocType,2,*),"-":$E(pOriginalDoc.DocType,2,*),:pOriginalDoc.DocType)

		Set tAK5Codes = ..GetTransactionSetErrorCodes(pOriginalDoc,pSNIPLevel,.tSegErrs,pBatchErrorAction)
		
		If tST.Name="ST" {
			Set tReplyAK2=##class(EnsLib.EDI.X12.Document).NewDocumentReply997Segs(tST,tAK5Codes,.tReplyAK5,.tSC,pGSGreater,("Note"'=pBatchErrorAction))
			Set:$IsObject(tReplyAK2) $$$X12ReplySeg(tDocID,$I(tSegCount)) = tSeparators_$E(tReplyAK2.OutputToString(),1,*-1)
			
			If tTSDocType'="" {
				Set tSegIndex = 0
				For {
					Set tSegIndex = $I(tSegIndex)
					If (tSegIndex > tOriginalSegCount) {
						If '$D(tSegErrs(tSegIndex)) {
							Set tSegIndex = $O(tSegErrs(tSegIndex))
							Quit:""=tSegIndex
						}
					} Else {
						Set tSeg = pOriginalDoc.GetSegmentAt(tSegIndex,.tSC)
						Quit:'$IsObject(tSeg)
					}
					Set tSegPath = pOriginalDoc.GetSegmentPath(tSegIndex,.tSCPath)
					If $$$ISERR(tSCPath) {
						#; there was a BuildMap issue with this segment, so we can't find the path, but we can still check for errors within the segment
						Set tLoop = ""
					} Else {					
						#; Find which loop segment is in
						If pOriginalDoc.useValSchema {
							Set tLoop = $Select($L(tSegPath,".")>1:$E($P(tSegPath,".",*-1),1,4),1:"")
						} Else {
							Set tLoop = $Select(tSegPath["loop":$E($P($P(tSegPath,"loop",*),"."),1,4),1:"")
						}
					}
		
					Set tDataElemErrs = 0
					Set tOneSegCode = 0
					#; Check to see if we found segment-level errors for this segment during the BuildMap
					If $D(tSegErrs(tSegIndex))="10" {
						Set tErrCount = +$O(tSegErrs(tSegIndex,""))
						Set:0'=tErrCount tOneSegCode = +$O(tSegErrs(tSegIndex,tErrCount,""),1,tSegName)
						If $L(tSegName,".")=2 {
							Set tLoop = $P(tSegName,".",1)
							Set tSegName = $P(tSegName,".",2)
						} Else {
							Set tLoop = ""
						}
						Set tSegLocData = tSegName_tEleSep_tSegIndex_tEleSep_tLoop
					} Else {
						Set tSegLocData = tSeg.Name_tEleSep_tSegIndex_tEleSep_tLoop
						Kill tDataElemErrs
						Set tOneSegCode = ..GetSegmentErrors(tSeg,pSNIPLevel,tTSDocType,pGSGreater,.tDataElemErrs)
						#; Don't want to report unrecognized segment as unexpected too, but do want to record when a known segment isn't expected
						If $$$ISERR(tSCPath) && (tOneSegCode'=$$$CodeAK3720UnrecognizedSegmentID) {
							Set tIK3String = tSeparators_$S(pGSGreater:"IK3",1:"AK3")_tEleSep_tSegLocData_tEleSep_$$$CodeAK3720UnexpectedSegment
							Set $$$X12ReplySeg(tDocID,$I(tSegCount)) = tIK3String
						}
					}
					While (tOneSegCode'=0) {
						If 'tHasSegErrors {
							Set tHasSegErrors = 1
						}
						Set tIK3String = tSeparators_$S(pGSGreater:"IK3",1:"AK3")_tEleSep_tSegLocData_tEleSep_tOneSegCode
						Set $$$X12ReplySeg(tDocID,$I(tSegCount)) = tIK3String
						If pGSGreater {
							Set tSegInBU = 0
							#; Check if segment in Business Unit
							Set ttStrippedPath = $Replace(tSegPath,"loop","")
							Set tStrippedPath = $P(ttStrippedPath,")",*)
							If ttStrippedPath[")" {
								For l=($L(ttStrippedPath,")")-1):-1:1 {
									Set tStrippedPath = $P($P(ttStrippedPath,")",l),"(")_"()"_tStrippedPath
								}
							}
							For l=($L(tStrippedPath,".")-1):-1:1 {
								If $D($$$vaVSchemaGbl($P(tTSDocType,":"),$P(tTSDocType,":",2),"bu",$P(tStrippedPath,".",1,l)),tContext)#2 {
									If pOriginalDoc.useValSchema {
										Set tBUVal = pOriginalDoc.GetValueAt($P(tSegPath,".",1,l)_"."_$P(tContext,"|",1)_"-"_$P(tContext,"|",3)_":"_$P(tContext,"|",2))
									} Else {
										Set tBUVal = pOriginalDoc.GetValueAt($P(tSegPath,".",1,l)_"."_$P(tContext,"|",1)_":"_$P(tContext,"|",2))
									}
									Set tBUName = $P(tContext,"|",4)
									Set tSegInBU = 1
									Quit
								}
							}
							If 'tSegInBU && $D($$$vaVSchemaGbl($P(tTSDocType,":"),$P(tTSDocType,":",2),"bu","-"),tContext)#2 {
								If pOriginalDoc.useValSchema {
									Set tBUVal = pOriginalDoc.GetValueAt($P(tContext,"|",1)_"-"_$P(tContext,"|",3)_":"_$P(tContext,"|",2))
								} Else {
									Set tBUVal = pOriginalDoc.GetValueAt($P(tContext,"|",1)_":"_$P(tContext,"|",2))
								}
								Set tBUName = $P(tContext,"|",4)
								Set tSegInBU = 1
							}
							If tSegInBU && (tBUVal'="") {
								Set tCTXString = tSeparators_"CTX"_tEleSep_tBUName_tCompSep_tBUVal
								Set $$$X12ReplySeg(tDocID,$I(tSegCount)) = tCTXString
							}
						}
						
						Set tIK4Count = +tDataElemErrs
						For i4=1:1:tIK4Count {
							Set tIK4Data = tDataElemErrs(i4)
							Set tIK4String = tSeparators_$S(pGSGreater:"IK4",1:"AK4")_tEleSep_$LG(tIK4Data,1)_tEleSep_$LG(tIK4Data,2)_$Select($LL(tIK4Data)>2:tEleSep_$LG(tIK4Data,3),1:"")
							Set $$$X12ReplySeg(tDocID,$I(tSegCount)) = tIK4String
							#; If constructing a 999 and code is 2 or 10, then create CTX segment
							If pGSGreater&&$Case(+$LG(tIK4Data,2),$$$CodeAK4723ConditionalRequiredDataElementMissing:1,$$$CodeAK4723ExclusionConditionViolated:1,:0) {
								Set tCTXString = tSeparators_"CTX"_tEleSep_"SITUATIONAL TRIGGER"_tEleSep_tSegLocData_tEleSep_$LG(tIK4Data,1)
								Set $$$X12ReplySeg(tDocID,$I(tSegCount)) = tCTXString
							}
						}
						#; Retrieve next segment-level error code if found in BuildMap
						#; Otherwise, we will have already captured everything at this point
						If ($D(tSegErrs(tSegIndex))="10")&&(tErrCount'=0) {
							Set tErrCount = +$O(tSegErrs(tSegIndex,tErrCount))
							If (0=tErrCount) {
								If (tOneSegCode'=1) {
									Set tSegLocData = tSeg.Name_tEleSep_tSegIndex_tEleSep_tLoop
									Kill tDataElemErrs
									Set tOneSegCode = ..GetSegmentErrors(tSeg,pSNIPLevel,tTSDocType,pGSGreater,.tDataElemErrs)
								} Else {
									Set tOneSegCode = 0
								}
							} Else {
								Set tOneSegCode = +$O(tSegErrs(tSegIndex,tErrCount,""),1,tSegName)
								If $L(tSegName,".")=2 {
									Set tLoop = $P(tSegName,".",1)
									Set tSegName = $P(tSegName,".",2)
								} Else {
									Set tLoop = ""
								}
								Set tSegLocData = tSegName_tEleSep_tSegIndex_tEleSep_tLoop
							}
						} Else {
							Set tOneSegCode = 0
						}	
					}
				}
				If tHasSegErrors&&(tAK5Codes'[$$$CodeAK5718OneOrMoreSegmentsInError)&&($L(tAK5Codes,",")<5) {
					Do tReplyAK5.SetValueAt($S("Note"=pBatchErrorAction:$$$CodeAK5717AcceptedButErrorsNoted,1:$$$CodeAK5717Rejected),1)
					Do tReplyAK5.SetValueAt($$$CodeAK5718OneOrMoreSegmentsInError,2+$S(""=tAK5Codes:0,1:$L(tAK5Codes,",")))
				}
			}
		} Else {
			#; create a temp segment to use in making the AK2
			Set tSeg = ##class(EnsLib.EDI.X12.Segment).%New($LB(,,,pOriginalDoc.Separators_"ST"_pOriginalDoc.ElementSeparator_+pOriginalDoc.DocTypeName))
			Set tReplyAK2=##class(EnsLib.EDI.X12.Document).NewDocumentReply997Segs(tSeg,tAK5Codes,.tReplyAK5,.tSC,pGSGreater,("Note"'=pBatchErrorAction))
			Set:$IsObject(tReplyAK2) $$$X12ReplySeg(tDocID,$I(tSegCount)) = tSeparators_$E(tReplyAK2.OutputToString(),1,*-1)
			#; Report the missing ST as an IK3/AK3 error
			Set tIK3String = tSeparators_$S(pGSGreater:"IK3",1:"AK3")_tEleSep_"ST"_tEleSep_"1"_tEleSep_tEleSep_$$$CodeAK3720MandatorySegmentMissing
			Set $$$X12ReplySeg(tDocID,$I(tSegCount)) = tIK3String			
			Do tReplyAK5.SetValueAt($$$CodeAK5718OneOrMoreSegmentsInError,2+$L(tAK5Codes,","))
		}
		Set:$IsObject(tReplyAK5) $$$X12ReplySeg(tDocID,$I(tSegCount)) = tSeparators_$E(tReplyAK5.OutputToString(),1,*-1)
		If tTSDocType'=pOriginalDoc.DocType {
			Do pOriginalDoc.PokeDocType(tTSDocType)
			Do pOriginalDoc.BuildMap(1)
		}

	} Catch ex {
		Set tSC = $$$ADDSC(tSC,ex.AsStatus())
	}
	Set:$$$ISERR(tSC) tSC = $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Attempted SNIP validation of document %1 failed due to error '%2'"),tDocID,$System.Status.GetErrorText(tSC)))
	Set tStatus = tSC
	If ((""=tAK5Codes) && 'tHasSegErrors) {
		Set tReplyCode = $$$CodeAK5717Accepted
	} ElseIf "Note"=pBatchErrorAction {
		Set tReplyCode = $$$CodeAK5717AcceptedButErrorsNoted
	} Else {
		Set tReplyCode = $$$CodeAK5717Rejected
		Set tStatus = $$$ADDSC(tStatus,$$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Document %1 failed SNIP validation"),tDocID)))
	}
	Set tHasError = (tReplyCode '= $$$CodeAK5717Accepted)
	Set $$$X12ValInfo(tDocID,"HasError") = tHasError
	For i=1:1:$LL(pOriginalDoc.ParentIds) {
		Set:tHasError $$$X12ValInfo($P($LG(pOriginalDoc.ParentIds,i),":"),"HasError") = 1
		If i=1 {
			Set $$$X12ChildDoc($P($LG(pOriginalDoc.ParentIds,i),":"),tDocID)=pOriginalDoc.Name
		} Else {
			Set $$$X12ChildDoc($P($LG(pOriginalDoc.ParentIds,i),":"),$P($LG(pOriginalDoc.ParentIds,i-1),":"))=""
		}
	}
	Set $$$X12ValInfo(tDocID,"Code")=tReplyCode
	Set $$$X12ValInfo(tDocID,"Status")=tStatus
	Quit tStatus
}

ClassMethod GetTransactionSetErrorCodes(pTransactionSet As EnsLib.EDI.X12.Document, pSNIPLevel As %Integer, ByRef pIK3Errs, pBatchErrorAction As %String = "Indiv") As %String
{
	#dim tCodes As %String = ""
	#; Evaluate possible Transaction Set errors to determine AK502 value
	If pTransactionSet.GetValueAt("1:0")'="ST" {
		Set pIK3Errs(1,1,$$$CodeAK3720MandatorySegmentMissing) = "ST"
		Quit $$$CodeAK5718MissingOrInvalidTransactionSetIdentifier_","_$$$CodeAK5718MissingOrInvalidTransactionSetControlNumber
	} ElseIf ""=pTransactionSet.GetValueAt("1:"_$$$STTransactionSetIdentifierCode) {
		#; Missing or Invalid Transaction Identifier
		Set tCodes = tCodes_","_$$$CodeAK5718MissingOrInvalidTransactionSetIdentifier
	} Else {
		Set tDocType = pTransactionSet.resolveChildDocType()
		Set:$Case($E(tDocType),"-":1,"+":1,:0) tDocType=$E(tDocType,2,*)
		If (tDocType="")||($P(tDocType,":",2)="") {
			#; Transaction Set Not Supported
			Set tCodes=tCodes_","_$$$CodeAK5718TransactionSetNotSupported
		} Else {
			Set tCategory = $P(tDocType,":")
			If (pSNIPLevel > 1) {
				Do pTransactionSet.PokeDocType("-"_tDocType)
			} ElseIf ($D($$$vaVSchemaGbl(tCategory))&&$G($$$vaSchemaGbl(tCategory,"useOld"))) {
				Do pTransactionSet.PokeDocType("+"_tDocType)
			}
			Set tSC = pTransactionSet.BuildMap((pBatchErrorAction'="First"),1)
			#; BuildMap errors are IK3 errors
			If $$$ISERR(tSC) {
				Do $System.Status.DecomposeStatus(tSC,.tErrList)
				#; For each error, determine which error code and find the segment name and location for reporting in the IK3
				For e=1:1:+$G(tErrList) {
					Set tCode = $G(tErrList(e,"code"))
					Set tIK3Code=""
					If (tCode="<EnsEDI>ErrMapSegUnrecog") {
						Set tSeg = $G(tErrList(e,"param",1))
						Set tLocation = 1 + $G(tErrList(e,"param",2)) ; location reported in error was %seglastmatch, which is the one before the error
						#; Test to see whether we recognize this segment name
						Set tSegFound = 0
						Set tCategory = $P(tDocType,":")
						For {
							If $D($$$vaSchemaGbl(tCategory,"SS",tSeg))#2 {
								Set tSegFound = 1
								Quit
							} ElseIf '$D($$$vaSchemaGbl(tCategory,"base"),tCategory) {
								Quit
							}
						}
						If 'tSegFound {
							#; Unrecognized Segment ID
							Set tIK3Code = $$$CodeAK3720UnrecognizedSegmentID
						} Else {
							#; Unexpected segment
							Set tIK3Code = $$$CodeAK3720UnexpectedSegment
						}
					} ElseIf (tCode = "<EnsEDI>ErrMapSegCount") {
						#; ErrMapSegCount has extra parameter for repeat count as its first parameter, segment name and location are parameters 2 and 3
						Set tSeg = $G(tErrList(e,"param",2))
						#; Required Segment Missing
						Set tLocation = +$G(tErrList(e,"param",3))
						Set tIK3Code = $$$CodeAK3720MandatorySegmentMissing
					} ElseIf (tCode = "<EnsEDI>ErrMapRequired") || (tCode = "<EnsEDI>ErrMapRequiredUnion") {
						Set tSeg = $G(tErrList(e,"param",1))
						#; Missing SE will be reported in AK5
						Continue:($P(tSeg,"-")="SE")&&(pTransactionSet.GetValueAt(pTransactionSet.SegCount_":0")'="SE")
						Set tLocation = +$G(tErrList(e,"param",2))
						#; Required Segment Missing
						Set tIK3Code = $$$CodeAK3720MandatorySegmentMissing
					}
					#; Else not an error for which we have a specific IK3 code
					If ""'=tIK3Code {
						Set tSegName = $P($P($P($P(tSeg,".",*),"!"),"-"),"(")	; get just the name and no ordinal, keyfield, or repetition info
						Set tLoop = $S($L(tSeg,".")>1:+$P($P(tSeg,".",*-1),"loop",*)_".",1:"")
						Set pIK3Errs(tLocation,e,tIK3Code) = tLoop_tSegName ; include loop number if segment is in one
					}
					Set:tCodes'[(","_$$$CodeAK5718OneOrMoreSegmentsInError) tCodes = tCodes_","_$$$CodeAK5718OneOrMoreSegmentsInError
				}
			}
		}
	}

	Set tTSControlNum = pTransactionSet.GetValueAt("1:"_$$$STTransactionSetControlNumber)
	If (""=tTSControlNum) {
		#; Missing or Invalid Transaction Set Control Number
		Set tCodes = tCodes_","_$$$CodeAK5718MissingOrInvalidTransactionSetControlNumber
	}
	
	Set tSE = pTransactionSet.GetSegmentAt(pTransactionSet.SegCount,.tSC)
	If ($IsObject(tSE) && (tSE.Name="SE")) {
		#; Number of included segments doesn't match actual count
		Set:tSE.GetValueAt($$$SENumberofIncludedSegments)'=pTransactionSet.SegCount tCodes = tCodes_","_$$$CodeAK5718NumberOfIncludedSegmentsMismatch
		If $Case(tTSControlNum,"":0,tSE.GetValueAt($$$SETransactionSetControlNumber):0,:1) {
			#; control number mismatch
			Set tCodes = tCodes_","_$$$CodeAK5718TransactionSetControlNumberMismatch
		}
	} Else {
		#; Transaction Set Trailer Missing
		Set tCodes = tCodes_","_$$$CodeAK5718TransactionSetTrailerMissing
	}
	
	Quit $E(tCodes,2,*)
}

ClassMethod GetSegmentErrors(pSegment As EnsLib.EDI.X12.Segment, pSNIPLevel As %Integer, pDocType As %String = "", pGSGreater As %Boolean = 1, ByRef pDataElemErrs) As %Integer
{
	#dim tIK304 As %Integer = 0
	#dim tOrdinal As %Integer = +$P(pSegment.DocTypeName,"-",*)
	#dim tElemCount,tReps,tMinLen,tMaxLen,tLength,tFieldNum As %Integer
	#dim tMatches As %Boolean
	#dim tDTFormat,tOldData,tOldCompData As %String = ""
	#dim tCompSep As %String = pSegment.CS
	#dim tEleSep As %String = pSegment.ES
	#; this captures whether we both are doing SNIP 2 and have the info we need for thorough SNIP 2 validation
	#; if there were BuildMap errors, then we'll have to go off only what we know from the new-style schema structure
	#dim UseHigherSNIPLevel = (tOrdinal>0) && (pSNIPLevel > 1) 
	
	Do {
		#dim tCategory As %String = $P(pDocType,":")
		#dim tSegFound As %Boolean = 0
		Set:'$D(pDataElemErrs) pDataElemErrs = 0
		If tCategory'="" {
			For {
				If $D($$$vaSchemaGbl(tCategory,"SS",pSegment.Name),tSegData)#2 {
					Set tSegFound = 1
					Quit
				} ElseIf '$D($$$vaSchemaGbl(tCategory,"base"),tCategory) {
					Quit
				}
			}
		}
		If 'tSegFound {
			Set tIK304 = $$$CodeAK3720UnrecognizedSegmentID
			Quit
		}

		Set tElemCount = pSegment.Count ; avoid repeated calls to CountGet()
		For tFieldNum=1:1:tElemCount {
			Quit:tFieldNum>$LL(tSegData)
			Set tValue = pSegment.GetValueAt(tFieldNum)
			Set tElemData = $LG(tSegData,tFieldNum)
			Set:UseHigherSNIPLevel tOldData = $G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",tOrdinal,tFieldNum))
			If tValue'="" {
				Set tComposite = ($LG(tElemData,1)[":")
				If tComposite {
					Set tCompCat = $P($LG(tElemData,1),":")
					Set tCompData = $G($$$vaSchemaGbl($S(tCompCat'="":tCompCat,1:tCategory),"CS",$P($LG(tElemData,1),":",2)))
				}
				Set tReps = $L(tValue,pSegment.RS)
				For r=1:1:tReps {
					Set tOneRep = $P(tValue,pSegment.RS,r)
					If tComposite {
						Set tComponents = $L(tOneRep,pSegment.CS)
						For c=1:1:tComponents {
							Set tOneCompVal = $P(tOneRep,pSegment.CS,c)
							Set tPosition = tFieldNum_tCompSep_c_$S(tReps=1:"",1:tCompSep_r)
							Set:UseHigherSNIPLevel tOldCompData = $G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",tOrdinal,tFieldNum,c))
							If (c > $LL(tCompData)) {
								#; Too many components
								Set pDataElemErrs($I(pDataElemErrs))=$LB(tPosition_tEleSep,$$$CodeAK4723TooManyComponents,tOneCompVal)
							} ElseIf ""'=tOneCompVal {
								Set tElemRefNum = ..ValidateOneDataElem(tOneCompVal,tPosition,$LG(tCompData,c),tOldCompData,tDTFormat,UseHigherSNIPLevel,.tIK304,.pDataElemErrs,tEleSep)
								If UseHigherSNIPLevel && $D($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"c",tElemRefNum,"l",tOrdinal,tFieldNum,c),tKey) && '($D($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"c",tElemRefNum,"c",tKey,tOneCompVal))#2) {
									#; Invalid Code Value
									Set pDataElemErrs($I(pDataElemErrs))=$LB(tPosition_tEleSep_tElemRefNum,$$$CodeAK4723InvalidCodeValue,tOneCompVal)
									Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
								}
								Set:(tElemRefNum=1250) tDTFormat = tOneCompVal
							} ElseIf (pSNIPLevel > 1) {
								If (tOrdinal>0) {
									If ("M"=$P(tOldCompData,"|",3)) {
										#; Required Data Element Missing
										Set pDataElemErrs($I(pDataElemErrs))=$LB(tPosition_tEleSep_$P(tOldCompData,"|",2),$$$CodeAK4723MandatoryDataElementMissing)
										Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
									}
								} ElseIf ($LG($LG(tCompData,c),5) = "M") {
									#; If BuildMap failed, don't know ordinal, so use info we do have from new-style schema
									Set pDataElemErrs($I(pDataElemErrs))=$LB(tPosition_tEleSep_$LG($LG(tCompData,c),6),$$$CodeAK4723MandatoryDataElementMissing)
									Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
								}
							}
						}
					} Else {
						Set tPosition = $S(tReps=1:tFieldNum,1:tFieldNum_tCompSep_tCompSep_r)
						Set:tOneRep'="" tElemRefNum=..ValidateOneDataElem(tOneRep,tPosition,tElemData,tOldData,tDTFormat,UseHigherSNIPLevel,.tIK304,.pDataElemErrs,tEleSep)
						If UseHigherSNIPLevel && $D($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"c",tElemRefNum,"l",tOrdinal,tFieldNum),tKey) && '($D($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"c",tElemRefNum,"c",tKey,tOneRep))#2) {
							#; Invalid Code Value
							Set pDataElemErrs($I(pDataElemErrs))=$LB(tPosition_tEleSep_tElemRefNum,$$$CodeAK4723InvalidCodeValue,tOneRep)
							Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
						}
						Set:(tElemRefNum=1250) tDTFormat = tOneRep

					}
				}
			} ElseIf (pSNIPLevel > 1) {
				If (tOrdinal > 0) {
					If ("M"=$P(tOldData,"|",3)) {
						#; Required Data Element Missing
						Set pDataElemErrs($I(pDataElemErrs))=$LB(tFieldNum_tEleSep_$P(tOldData,"|",2),$$$CodeAK4723MandatoryDataElementMissing)
						Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
					}
				} Else {
					#; If BuildMap failed, don't know ordinal, so use info we do have from new-style schema
					If $LG(tElemData,5) = "M" {
						#; Required Data Element Missing
						Set pDataElemErrs($I(pDataElemErrs))=$LB(tFieldNum_tEleSep_$LG(tElemData,6),$$$CodeAK4723MandatoryDataElementMissing)
						Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
					}
				}

			}
		}
		
		If (tElemCount > $ListLength(tSegData)) {
			For tExtraElem = $ListLength(tSegData)+1:1:tElemCount {
				#; Too Many Data Elements
				Set pDataElemErrs($I(pDataElemErrs))=$LB(tExtraElem_tEleSep,$$$CodeAK4723TooManyDataElements,pSegment.GetValueAt(tExtraElem))
			}
			Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
		}
		
		If (pSNIPLevel > 1) {
			If tOrdinal > 0 {
				#; Use data specific to this occurrence of the segment if it is available
				While $I(tFieldNum) <= $LL(tSegData) {
					#; Loop through any missing trailing fields to see if they are mandatory
					Set tOldData = $G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",tOrdinal,tFieldNum))
					If ("M"=$P(tOldData,"|",3)) {
						#; Required Data Element Missing
						Set pDataElemErrs($I(pDataElemErrs))=$LB(tFieldNum_tEleSep_$P(tOldData,"|",2),$$$CodeAK4723MandatoryDataElementMissing)
						Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
					}
				}
				#; Only have Situational Rule data if using Validation schema and know the ordinal, so we test for it here, but can't test for it if this segment hasn't been mapped properly
				Set tSCRule = ..CheckTR3Rules(pDocType,pSegment,tOrdinal,"",.pDataElemErrs,0,0)
				If $$$ISERR(tSCRule) {
					Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
				} 

			} Else {
				#; If BuildMap failed, don't know ordinal, so use info we do have from new-style schema
				While $I(tFieldNum) <= $LL(tSegData) {
					#; Loop through any missing trailing fields to see if they are mandatory
					If $LG($LG(tSegData,tFieldNum),5) = "M" {
						#; Required Data Element Missing
						Set pDataElemErrs($I(pDataElemErrs))=$LB(tFieldNum_tEleSep_$LG($LG(tSegData,tFieldNum),6),$$$CodeAK4723MandatoryDataElementMissing)
						Set tIK304 = $$$CodeAK3720SegmentHasDataElementErrors
					}
				}
			}
		}
	} While 0
	Quit tIK304
}

ClassMethod ValidateOneDataElem(pValue As %String, pElemPosition As %Integer, pElemData, pOldData As %Integer, pDTFormat As %String = "", pSNIPGreater As %Boolean = 0, ByRef pIK304 As %Integer = 0, ByRef pDataElemErrs As %Integer = 0, pEleSep As %String = {$$$X12DefElementSeparator}) As %String
{
	If pValue'="" {
		
		Set tMinLen = $LG(pElemData,2)
		Set tMaxLen = $LG(pElemData,4)
		Set tDatatype = $LG(pElemData,1)
		Set:tDatatype'[":" tDatatype = $E(tDatatype,2,*-1)
		Set tElemRefNum = $LG(pElemData,6)

		Set tLength = $L(pValue)
		#; optional - sign not counted in length
		Set:(("-"=$E(pValue,1))&&((tDatatype ?1"N".N) || (tDatatype = "R"))) tLength = (tLength-1)
		Set:((tDatatype="R") && (pValue[".")) tLength = (tLength-1)
		If (tLength < tMinLen) {
			#; Data Element Too Short
			Set pDataElemErrs($I(pDataElemErrs))=$LB(pElemPosition_pEleSep_tElemRefNum,$$$CodeAK4723DataElementTooShort,pValue)
			Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
		} ElseIf (tMaxLen && (tLength > tMaxLen)) {
			#; Data Element Too Long
			Set pDataElemErrs($I(pDataElemErrs))=$LB(pElemPosition_pEleSep_tElemRefNum,$$$CodeAK4723DataElementTooLong,pValue)
			Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
		}
		If tDatatype = "R" {
			#; "numeric values that have a varying number of decimal positions"
			If '(pValue ? 0.1"-"0.N0.1".".N) {
				#; Invalid numerical value - no specific IK403 element error code
				Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
			}
			
		} ElseIf tDatatype = "DT" {
			#; Date - YYMMDD or CCYYMMDD
			Set tMatches = 1
			If $zstrip(pValue,"*N")'="" {
				Set tMatches = 0
			} Else {
				Set tMonth = $E(pValue,*-3,*-2)
				If (tMonth < 1) || (tMonth > 12) {
					Set tMatches = 0
				} ElseIf (($E(pValue,*-1,*) < 1) || ($E(pValue,*-1,*)>$Case(tMonth,2:29,4:30,6:30,9:30,11:30,:31))) {
					Set tMatches = 0
				}
			}
			If 'tMatches {
				#; Invalid Date
				Set pDataElemErrs($I(pDataElemErrs))=$LB(pElemPosition_pEleSep_tElemRefNum,$$$CodeAK4723InvalidDate,pValue)
				Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
			}
		} ElseIf tDatatype = "TM" {
			#; Time - HHMMSSd...d
			Set tMatches = 1
			If $zstrip(pValue,"*N")'="" {
				Set tMatches = 0
			} ElseIf (($E(pValue,1,2) < 0) || ($E(pValue,1,2) > 23)) {
				Set tMatches = 0
			} ElseIf (($L(pValue) > 2) && ($E(pValue,3,4) < 0) || ($E(pValue,3,4) > 59)) {
				Set tMatches = 0
			} ElseIf (($L(pValue) > 4) && ($E(pValue,5,6) < 0) || ($E(pValue,5,6) > 59)) {
				Set tMatches = 0
			}
			If 'tMatches {
				#; Invalid Time
				Set pDataElemErrs($I(pDataElemErrs))=$LB(pElemPosition_pEleSep_tElemRefNum,$$$CodeAK4723InvalidTime,pValue)
				Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
			}
		} ElseIf tDatatype ? 1"N".N {
			#; Numeric - "A numeric data element is represented by one or more digits with an optional leading sign... The plus sign must not be transmitted"
			If '(pValue ? 0.1"-"1.N) {
				Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
			}
		} ElseIf (tElemRefNum=1251)&&(pDTFormat'="") {
			Set tCode = ..ValidateDateTime(pValue,pDTFormat)
			If tCode {
				#; Invalid Date or Time
				Set pDataElemErrs($I(pDataElemErrs))=$LB(pElemPosition_pEleSep_tElemRefNum,tCode,pValue)
				Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
			}
		}
		If pSNIPGreater {
			If (("."=$P(pOldData,"|",3)) || (""=pOldData)) {
				#; Implementation "Not Used" Data Element Present
				Set pDataElemErrs($I(pDataElemErrs))=$LB(pElemPosition_pEleSep_tElemRefNum,$$$CodeAK4723ImplementationNotUsedDataElementPresent,pValue)
				Set pIK304 = $$$CodeAK3720SegmentHasDataElementErrors
			}
		}
	}
	
	Quit tElemRefNum
}

/// Validate that date/time value <var>pValue</var> which is expected to follow format code <var>pFormat</var> 
/// Expected formats for each code are as follows: </br>
/// 'CC' = 'First Two Digits of Year Expressed in Format CCYY' </br>
/// 'CD' = 'Month and Year Expressed in Format MMMYYYY' </br>
/// 'CM' = 'Date in Format CCYYMM' </br>
/// 'CQ' = 'Date in Format CCYYQ' </br>
/// 'CY' = 'Year Expressed in Format CCYY' </br>
/// 'D6' = 'Date Expressed in Format YYMMDD' </br>
/// 'D8' = 'Date Expressed in Format CCYYMMDD' </br>
/// 'DA' = 'Range of Dates within a Single Month Expressed in Format DD-DD' </br>
/// 'DB' = 'Date Expressed in Format MMDDCCYY' </br>
/// 'DD' = 'Day of Month in Numeric Format' </br>
/// 'DT' = 'Date and Time Expressed in Format CCYYMMDDHHMM' </br>
/// 'DTS' = 'Range of Date and Time Expressed in Format CCYYMMDDHHMMSS-CCYYMMDDHHMMSS' </br>
/// 'EH' = 'Last Digit of Year and Julian Date Expressed in Format YDDD' </br>
/// 'KA' = 'Date Expressed in Format YYMMMDD' </br>
/// 'MD' = 'Month of Year and Day of Month Expressed in Format MMDD' </br>
/// 'MM' = 'Month of Year in Numeric Format' </br>
/// 'RD' = 'Range of Dates Expressed in Format MMDDCCYY-MMDDCCYY' </br>
/// 'RD2' = 'Range of Years Expressed in Format YY-YY' </br>
/// 'RD4' = 'Range of Years Expressed in Format CCYY-CCYY' </br>
/// 'RD5' = 'Range of Years and Months Expressed in Format CCYYMM-CCYYMM' </br>
/// 'RD6' = 'Range of Dates Expressed in Format YYMMDD-YYMMDD' </br>
/// 'RD8' = 'Range of Dates Expressed in Format CCYYMMDD-CCYYMMDD' </br>
/// 'RDM' = 'Range of Dates Expressed in Format YYMMDD-MMDD' </br>
/// 'RDT' = 'Range of Date and Time, Expressed in Format CCYYMMDDHHMM-CCYYMMDDHHMM' </br>
/// 'RMD' = 'Range of Months and Days Expressed in Format MMDD-MMDD' </br>
/// 'RMY' = 'Range of Years and Months Expressed in Format YYMM-YYMM' </br>
/// 'RTM' = 'Range of Time Expressed in Format HHMM-HHMM' </br>
/// 'RTS' = 'Date and Time Expressed in Format CCYYMMDDHHMMSS' </br>
/// 'TC' = 'Julian Date Expressed in Format DDD' </br>
/// 'TM' = 'Time Expressed in Format HHMM' </br>
/// 'TQ' = 'Date Expressed in Format MMYY' </br>
/// 'TR' = 'Date and Time Expressed in Format DDMMYYHHMM' </br>
/// 'TS' = 'Time Expressed in Format HHMMSS' </br>
/// 'TT' = 'Date Expressed in Format MMDDYY' </br>
/// 'TU' = 'Date Expressed in Format YYDDD' </br>
/// 'UN' = 'Unstructured' </br>
/// 'YM' = 'Year and Month Expressed in Format YYMM' </br>
/// 'YMM' = 'Range of Year and Months, Expressed in CCYYMMM-MMM Format' </br>
/// 'YY' = 'Last Two Digits of Year Expressed in Format CCYY' </br>
ClassMethod ValidateDateTime(pValue As %String, pFormat As %String) As %Integer
{
	#dim tErrCode as %Integer = 0 ; will be set to 8 for invalid date or 9 for invalid time
	#; variables for year, quarter, month, day, hours, minutes, and seconds
	#dim tYY,tYYYY,tY,tQ,tMM,tMMM,tDDD,tDD,tHH,tMin,tSS As %String = ""
	#dim tDash,tYY2,tYYYY2,tMM2,tDD2,tHH2,tMin2,tSS2 As %String = ""
	#dim tMatches As %Boolean = 0
	Do {
		If $Case(pFormat,"":1,"UN":1,:0) || (",CC,CD,CM,CQ,CY,D6,D8,DA,DB,DD,DT,DTS,EH,KA,MD,MM,RD,RD2,RD4,RD5,RD6,RD8,RDM,RDT,RMD,RMY,RTM,RTS,TC,TM,TQ,TR,TS,TT,TU,UN,YM,YMM,YY," '[ (","_pFormat_",")) {
			Set tMatches = 1
			Quit
		}
		#; quick check that, if doesn't include month in MMM format, then all numerical with possible range
		Quit:$Case(pFormat,"CD":0,"KA":0,"YMM":0,:1)&&(pValue'?.N0.1"-".N)
		
		#; First check length
		Set tLen = $L(pValue)
		Set tExpectedLen = $Case(pFormat,"CC":2,"CD":7,"CM":6,"CQ":5,"CY":4,"D6":6,"D8":8,"DA":5,"DB":8,"DD":2,"DT":12,"DTS":29,"EH":4,"KA":7,"MD":4,
		  "MM":2,"RD":17,"RD2":5,"RD4":9,"RD5":13,"RD6":13,"RD8":17,"RDM":11,"RDT":25,"RMD":9,"RMY":9,"RTM":9,"RTS":14,"TC":3,"TM":4,"TQ":4,"TR":10,
		  "TS":6,"TT":6,"TU":5,"YM":4,"YMM":11,"YY":2)
		Set tMatches = (tLen=tExpectedLen)
		Quit:'tMatches
		
		#; Year needs to be numerical
		Set tYYYY = $Case(pFormat,"CD":$E(pValue,4,7),"CM":$E(pValue,1,4),"CQ":$E(pValue,1,4),"D8":$E(pValue,1,4),"DB":$E(pValue,5,8),"DT":$E(pValue,1,4),"DTS":$E(pValue,1,4),"RD":$E(pValue,5,8),"RD4":$E(pValue,1,4),"RD5":$E(pValue,1,4),"RD8":$E(pValue,1,4),"RDT":$E(pValue,1,4),"RTS":$E(pValue,1,4),"YMM":$E(pValue,1,4),:"")
		Set tYYYY2 = $Case(pFormat,"DTS":$E(pValue,16,19),"RD":$E(pValue,14,17),"RD4":$E(pValue,6,9),"RD5":$E(pValue,8,11),"RD8":$E(pValue,10,13),"RDT":$E(pValue,14,17),:"")
		Set tYY = $Case(pFormat,"CC":pValue,"D6":$E(pValue,1,2),"KA":$E(pValue,1,2),"RD2":$E(pValue,1,2),"RD6":$E(pValue,1,2),"RDM":$E(1,2),"RMY":$E(pValue,1,2),"TQ":$E(pValue,3,4),"TR":$E(pValue,5,6),"TT":$E(pValue,5,6),"TU":$E(pValue,1,2),"YM":$E(pValue,1,2),"YY":pValue,:"")
		Set tYY2 = $Case(pFormat,"RD2":$E(pValue,4,5),"RD6":$E(pValue,8,9),"RMY":$E(pValue,6,7),:"")
		Set:pFormat="EH" tY = $E(pValue)
		Quit:(tYYYY_tYYYY2_tYY_tYY2_tY)'?.N
		
		#; Quarter
		Quit:(pFormat="CQ")&&("1234"'[$E(pValue,5))
		
		#; Numerical Month
		Set tMM = $Case(pFormat,"CM":$E(pValue,5,6),"D6":$E(pValue,3,4),"D8":$E(pValue,5,6),"DB":$E(pValue,1,2),"DT":$E(pValue,5,6),"DTS":$E(pValue,5,6),"MD":$E(pValue,1,2),"MM":pValue,"RD":$E(pValue,1,2),"RD5":$E(pValue,5,6),"RD6":$E(pValue,3,4),"RD8":$E(pValue,5,6),"RDM":$E(pValue,3,4),"RDT":$E(pValue,5,6),"RMD":$E(pValue,1,2),"RMY":$E(pValue,3,4),"RTS":$E(pValue,5,6),"TQ":$E(pValue,1,2),"TR":$E(pValue,3,4),"TT":$E(pValue,1,2),"YM":$E(pValue,3,4),:"")
		Set tMM2 = $Case(pFormat,"DTS":$E(pValue,20,21),"RD":$E(pValue,10,11),"RD5":$E(pValue,12,13),"RD6":$E(pValue,10,11),"RD8":$E(pValue,14,15),"RDM":$E(pValue,8,9),"RDT":$E(pValue,18-19),"RMD":$E(pValue,6,7),"RMY":$E(pValue,8,9),:"")
		Quit:(tMM'="")&&((tMM>12)||(tMM<1))
		Quit:(tMM2'="")&&((tMM2>12)||(tMM2<1))
		
		#; Alpha Month
		Set tMMM = $Case(pFormat,"CD":$E(pValue,1,3),"KA":$E(pValue,3,5),"YMM":$E(pValue,5,7),:"")
		Quit:$Case(tMMM,"":0,"JAN":0,"FEB":0,"MAR":0,"APR":0,"MAY":0,"JUN":0,"JUL":0,"AUG":0,"SEP":0,"OCT":0,"NOV":0,"DEC":0,:1)
		If pFormat="YMM" {
			If $Case($E(pValue,9,11),"JAN":0,"FEB":0,"MAR":0,"APR":0,"MAY":0,"JUN":0,"JUL":0,"AUG":0,"SEP":0,"OCT":0,"NOV":0,"DEC":0,:1) {
				Set tErrCode = $$$CodeAK4723InvalidDate
				Quit
			}
		}
		
		#; Day in DD format
		Set tDD = $Case(pFormat,"D6":$E(pValue,5,6),"D8":$E(pValue,7,8),"DA":$E(pValue,1,2),"DB":$E(pValue,3,4),"DD":pValue,"DT":$E(pValue,7,8),"DTS":$E(pValue,7,8),"KA":$E(pValue,6,7),"MD":$E(pValue,3,4),"RD":$E(pValue,3,4),"RD6":$E(pValue,5,6),"RD8":$E(pValue,7,8),"RDM":$E(pValue,5,6),"RDT":$E(pValue,7,8),"RMD":$E(pValue,3,4),"RTS":$E(pValue,7,8),"TR":$E(pValue,1,2),"TT":$E(pValue,3,4),:"")
		Set tDD2 = $Case(pFormat,"DA":$E(pValue,4,5),"DTS":$E(pValue,22,23),"RD":$E(pValue,12,13),"RD6":$E(pValue,12,13),"RD8":$E(pValue,16,17),"RDM":$E(pValue,10,11),"RDT":$E(pValue,20,21),"RMD":$E(pValue,8,9),:"")
		Quit:(tDD'="")&&((tDD>31)||(tDD<1))
		Quit:(tDD2'="")&&((tDD2>31)||(tDD2<1))
		
		#; Julian date
		Set tDDD = $Case(pFormat,"EH":$E(pValue,2,4),"TC":pValue,"TU":$E(pValue,3,5),:"")
		Quit:(tDDD'="")&&((tDDD>366)||(tDDD<1))
		
		#; Range
		Set tDash = $E(pValue,$Case(pFormat,"DA":3,"DTS":15,"RD":9,"RD2":3,"RD4":5,"RD5":7,"RD6":7,"RD8":9,"RDM":7,"RDT":13,"RMD":5,"RMY":5,"RTM":5,"YMM":8,:0))
		Quit:"-"'=tDash
		
		#; Hour
		Set tHH = $Case(pFormat,"DT":$E(pValue,9,10),"DTS":$E(pValue,9,10),"RDT":$E(pValue,9,10),"RTM":$E(pValue,1,2),"RTS":$E(pValue,9,10),"TM":$E(pValue,1,2),"TR":$E(pValue,7,8),"TS":$E(pValue,1,2),:"")
		Set tHH2 = $Case(pFormat,"DTS":$E(pValue,24,25),"RDT":$E(pValue,22,23),"RTM":$E(pValue,6,7),:"")
		If (""'=tHH) && ((tHH>24)||(tHH<0)) {
			Set tErrCode = $$$CodeAK4723InvalidTime
			Quit
		}
		If (""'=tHH2) && ((tHH2>24)||(tHH2<0)) {
			Set tErrCode = $$$CodeAK4723InvalidTime
			Quit
		}
		
		#; Minutes
		Set tMin = $Case(pFormat,"DT":$E(pValue,11,12),"DTS":$E(pValue,11,12),"RDT":$E(pValue,11,12),"RTM":$E(pValue,3,4),"RTS":$E(pValue,11,12),"TM":$E(pValue,3,4),"TR":$E(pValue,9,10),"TS":$E(pValue,3,4),:"")
		Set tMin2 = $Case(pFormat,"DTS":$E(pValue,26,27),"RDT":$E(pValue,24,25),"RTM":$E(pValue,8,9),:"")
		If (""'=tMin) && ((tMin>60)||(tMin<0)) {
			Set tErrCode = $$$CodeAK4723InvalidTime
			Quit
		}
		If (""'=tMin2) && ((tMin2>60)||(tMin2<0)) {
			Set tErrCode = $$$CodeAK4723InvalidTime
			Quit
		}
		
		#; Seconds
		Set tSS = $Case(pFormat,"DTS":$E(pValue,13,14),"RTS":$E(pValue,13,14),"TS":$E(pValue,5,6),:"")
		If (""'=tSS) && ((tSS>60)||(tSS<0)) {
			Set tErrCode = $$$CodeAK4723InvalidTime
			Quit
		}
		If pFormat="DTS" {
			Set tSS2 = $E(pValue,28,29)
			If (tSS2>60)||(tSS2<0) {
				Set tErrCode = $$$CodeAK4723InvalidTime
				Quit
			}
		}
		
		#; If haven't already quit, then value matched the pattern
		Set tMatches = 1
	} While 0
	
	#; If value wasn't a match and haven't specifically ID'd the problem as a time format issue, set an appropriate error code
	If 'tErrCode && 'tMatches {
		Set tErrCode = $Case(pFormat,"RTM":$$$CodeAK4723InvalidTime,"TM":$$$CodeAK4723InvalidTime,"TS":$$$CodeAK4723InvalidTime,:$$$CodeAK4723InvalidDate)
	}
	Quit tErrCode
}

/// Test a segment against any situational rules defined within that segment <p>
/// <var>pDocType</var> is the DocType of the document that this segment is in </br>
/// <var>pSegment</var> is the segment being evaluated </br>
/// <var>pOrdinal</var> is the ordinal at which this segment appears within the given DocType </br>
/// <var>pSegNum</var> is the position at which this segment appears within the document </br>
/// <var>pDataElemErrs</var> is an array describing any errors that are found.  This is used only for SNIP validation </br>
/// <var>pQuitOnError</var> is a boolean indicating whether we should stop processing once the first error has been found </br>
/// <var>pSegOnly</var> is a boolean indicating whether to only check for segment-level rules and skip over situational rules within the composite structures </br>
/// The returned status code message is used only for flag-style validation.
ClassMethod CheckTR3Rules(pDocType As %String, pSegment As EnsLib.EDI.X12.Segment, pOrdinal As %Integer, pSegNum As %Integer = "", ByRef pDataElemErrs = "", pQuitOnError As %Boolean = 1, pSegOnly As %Boolean = 0) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tEleSep As %String = pSegment.ES
	#dim tCompSep As %String = pSegment.CS
	#dim tRepSep As %String = pSegment.RS

	If 'pSegOnly {
		Set tErroredComps = ""
		Set tComposite=""
		For {
			Set tComposite = $O($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",pOrdinal,tComposite),1,tCompInfo) Quit:tComposite=""
			Continue:($P(tCompInfo,"|")'="C")||'$D($$$vaSchemaGbl($P(pDocType,":"),"RC",$P(tCompInfo,"|",2)))
			Set tEleVal = pSegment.GetValueAt(tComposite)
			#; No evaluating intra-component rules if the component is missing
			Continue:(""=tEleVal)
			Set tReps = $L(tEleVal,tRepSep)
			Set tRule = ""
			For {
				Set tRule = $O($$$vaSchemaGbl($P(pDocType,":"),"RC",$P(tCompInfo,"|",2),tRule))	Quit:""=tRule					
				For r=1:1:tReps {
					Set tRepVal = $P(tEleVal,tRepSep,r)
					Set tErroredComp = ..EvaluateOneRule(tRule,tRepVal,tCompSep,.tIsMissing,.tIsExclusion)
					If ((tErroredComp > 0) && '$D(tErroredComps(tComposite,r,tErroredComp))) {
						Set tErroredComps(tComposite,r,tErroredComp) = "" ; keep track of errored components so we don't report same field:rep:comp multiple times if multiple violations
						Set tPosition = tComposite_tCompSep_tErroredComp_$S(tReps=1:"",1:tCompSep_r)
						Set tOldData = $G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",pOrdinal,tComposite,tErroredComp))
						If tIsExclusion {
							#; Exclusion Condition Violated  10
							Set pDataElemErrs($I(pDataElemErrs))=$LB(tPosition_tEleSep_$P(tOldData,"|",2),$$$CodeAK4723ExclusionConditionViolated,$P(tRepVal,tCompSep,tErroredComp))
							If tReps > 1 {
								Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12CompExclusionCondViolatedRepeating,pSegNum,pSegment.DocTypeName,tComposite,r,tErroredComp,$P(tRepVal,tCompSep,tErroredComp)))
							} Else {
								Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12CompExclusionCondViolated,pSegNum,pSegment.DocTypeName,tComposite,tErroredComp,$P(tRepVal,tCompSep,tErroredComp)))
							}
							Quit:pQuitOnError
						} ElseIf tIsMissing {
							#; Conditional Required Data Element Missing
							Set pDataElemErrs($I(pDataElemErrs))=$LB(tPosition_tEleSep_$P(tOldData,"|",2),$$$CodeAK4723ConditionalRequiredDataElementMissing)
							If tReps > 1 {
								Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ConditionalReqCompMissingRepeating,tErroredComp,pSegNum,pSegment.DocTypeName,tComposite,r))
							} Else {
								Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ConditionalRequiredCompMissing,tErroredComp,pSegNum,pSegment.DocTypeName,tComposite))
							}
							Quit:pQuitOnError
						}
					}
				}
				Quit:(pQuitOnError && $$$ISERR(tSC))
			}
			Quit:(pQuitOnError && $$$ISERR(tSC))
		}
	}

	If ($D($$$vaSchemaGbl($P(pDocType,":"),"RC",pSegment.Name))&&('pQuitOnError||$$$ISOK(tSC))) {
		Set tSeen = ""
		Set tErroredElems = ""
		Set tRule = ""
		For {
			Set tRule = $O($$$vaSchemaGbl($P(pDocType,":"),"RC",pSegment.Name,tRule))	Quit:""=tRule
			Set tErroredElem = ..EvaluateOneRule(tRule,$P(pSegment.GetValueAt(""),tEleSep,2,*),tEleSep,.tIsMissing,.tIsExclusion)
			If (tErroredElem > 0) && '$D(tErroredElems(tErroredElem)) {
				Set tErroredElems(tErroredElem) = "" ; keep track of errored fields so we don't report same field multiple times
				Set tOldData = $G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2),"o",pOrdinal,tErroredElem))
				If tIsExclusion {
					#; Exclusion Condition Violated
					Set pDataElemErrs($I(pDataElemErrs))=$LB(tErroredElem_tEleSep_$P(tOldData,"|",2),$$$CodeAK4723ExclusionConditionViolated,pSegment.GetValueAt(tErroredElem))
					Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ExclusionConditionViolated,pSegNum,pSegment.DocTypeName,tErroredElem,pSegment.GetValueAt(tErroredElem)))
					Quit:pQuitOnError
				} ElseIf tIsMissing {
					#; Conditional Required Data Element Missing
					Set pDataElemErrs($I(pDataElemErrs))=$LB(tErroredElem_tEleSep_$P(tOldData,"|",2),$$$CodeAK4723ConditionalRequiredDataElementMissing)
					Set tSC = $$$ADDSC(tSC,$$$ERROR($$$EnsEDIX12ConditionalRequiredDataEleMissing,tErroredElem,pSegNum,pSegment.DocTypeName))
					Quit:pQuitOnError
				}
			}	
		}
	}

	Quit tSC
}

/// Test a component against any situational rules defined for that component. Returns a boolean indicating whether there are any errors<p>
/// <var>pDocType</var> is the DocType of the document that this segment is in </br>
/// <var>pCompVal</var> is the data value for the component within an X12 document </br>
/// <var>pSeparator</var> is the component separator for the document </br>
/// <var>pDummy</var> is not used - left in for compatibility </br>
/// <var>pCompName</var> is the name of the component </br>
/// <var>pErrors</var> is an array used for tracking any errors we do encounter
/// <var>pQuitOnError</var> is a boolean indicating whether we should stop processing after the first error we find
ClassMethod CheckCompTR3Rules(pDocType As %String, pCompVal, pSeparator, pDummy, pCompName As %String, ByRef pErrors, pQuitOnError As %Boolean = 1) As %Boolean [ Internal ]
{
	#dim tHasError As %Boolean=0
	#dim tErroredComp,r As %Integer
	#dim tRule,tRepVal As %String = ""
	#dim tIsMissing,tIsExclusion As %Boolean
	
	If $D($$$vaSchemaGbl($P(pDocType,":"),"RC",pCompName)) {
		For {
			Set tRule= $O($$$vaSchemaGbl($P(pDocType,":"),"RC",pCompName,tRule))	Quit:""=tRule
			Set tErroredComp = ..EvaluateOneRule(tRule,pCompVal,pSeparator,.tIsMissing,.tIsExclusion)
			If tErroredComp > 0 {
				Set tHasError = 1
				If tIsExclusion {
					#; Exclusion Condition Violated  10
					Set pErrors(tErroredComp,"Exclusion")=$P(pCompVal,pSeparator,tErroredComp)
					Quit:pQuitOnError
				} ElseIf tIsMissing {
					#; Conditional Required Data Element Missing
					Set pErrors(tErroredComp,"Missing")=""
					Quit:pQuitOnError
				}
			}
			Quit:pQuitOnError&&tHasError
		}
	}
	Quit tHasError
}

/// Test a segment or Composite Element against the intra-segment rules defined for that segment or composite <p>
/// <var>pRule</var> is the code for the rule, as found in the X12 Syntax </br>
/// <var>pValue</var> is the segment or element value and <var>pSeparator</var> is either the element or component separator, depending on which unit this rule applies to </br>
/// <var>pIsMissing</var> and <var>pExclusion</var> are booleans to indicate which type of rule violation, if any, we found </br>
/// The returned value as an integer indicating which element or component the rule violation was found in or 0 if no violation was found. </br>
ClassMethod EvaluateOneRule(pRule As %String, pValue As %String, pSeparator As %String, Output pIsMissing As %Boolean = 0, Output pExclusion As %Boolean = 0) As %Integer [ Internal ]
{
	#dim tErroredPiece As %Integer = 0
	Set pIsMissing = 0
	Set pExclusion = 0
	
	#dim tRuleType As %String
	#dim tRuleElems,tNumPresent As %Integer = 0
	#dim tEle,tStart,tMissingElem As %Integer
	#dim tIsMissing As %Boolean

	Set tRuleType = $E(pRule)
	For i=2:2:($L(pRule)-1) {
		Set tRuleElems($I(tRuleElems)) = +$E(pRule,i,i+1)
	}
	If tRuleType="P" {
		#; If X or Y present, all required
		For tEle=1:1:tRuleElems {
			If $P(pValue,pSeparator,tRuleElems(tEle))'="" {
				Set tNumPresent=tNumPresent+1
			} ElseIf $G(tMissingElem)="" {
				Set tMissingElem=+tRuleElems(tEle)
			}
		}
		If (tNumPresent>0) && (tNumPresent<tRuleElems) {
			Set pIsMissing = 1
			Set tErroredPiece = tMissingElem
		}
	} ElseIf tRuleType="C" {
		#; If X is present, then Y is required
		If tRuleElems=2 && ($P(pValue,pSeparator,tRuleElems(1))'="") && ($P(pValue,pSeparator,tRuleElems(2))="") {
			Set pIsMissing = 1
			Set tErroredPiece = +tRuleElems(2)
		}
	} ElseIf $Case(tRuleType,"L":1,"R":1,:0) {
		If tRuleType="L" {
			#; If X is present, then at least one of Y or Z required
			If (tRuleElems>=2) && ($P(pValue,pSeparator,tRuleElems(1))'="") {
				Set tStart=2
			} Else {
				Quit 0
			}
		} Else {
			#; At least one of X or Y is required
			Set tStart = 1
		}
		Set tIsMissing = 1
		For tEle=tStart:1:tRuleElems {
			If $P(pValue,pSeparator,tRuleElems(tEle))'="" {
				Set tIsMissing = 0
				Quit
			}
		}
		If tIsMissing {
			Set pIsMissing = 1
			Set tErroredPiece = +tRuleElems(tStart)
		}	
	} ElseIf tRuleType="E" {
		#; Only one of X or Y may be present
		For tEle=1:1:tRuleElems {
			If $P(pValue,pSeparator,tRuleElems(tEle))'="" {
				If $I(tNumPresent)>1 {
					Set pExclusion = 1
					Set tErroredPiece = +tRuleElems(tEle)
					Quit
				}
			}
		}
	}
	Quit tErroredPiece
}

}
