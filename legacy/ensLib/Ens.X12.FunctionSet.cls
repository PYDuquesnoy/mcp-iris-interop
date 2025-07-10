/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

/// Utility functions for creating X12 Documents
Class Ens.X12.FunctionSet Extends Ens.Rule.FunctionSet [ System = 4 ]
{

/// Make and return an X12 FuntionalGroup Document without GE segment<br>
/// The separators will be taken from the <PARAMETER>InterchangeParent</PARAMETER>. <br>
/// The Document Category will be taken from <PARAMETER>InterchangeParent</PARAMETER> unless specified in
/// optional <PARAMETER>Doctype</PARAMETER> <br>
/// The Document Name will be taken from <PARAMETER>Doctype</PARAMETER> if given
/// otherwise it will be FunctionalGroup <br>
/// The optional <PARAMETER>Doctype</PARAMETER> may specify just a document name and does not
/// need to include the Document category as that can be taken from the InterchangeParent. <br>
/// The new document will be set as a batch child of <PARAMETER>InterchangeParent</PARAMETER><br>
/// The document will have a TransactionSet place holder segment.<br>
/// If <PARAMETER>ForceNewPlaceHolderInParent</PARAMETER> is true (the default is false) then
/// a new GroupDocsRef place holder segment will be made in the <PARAMETER>InterchangeParent</PARAMETER><br>
/// If an Error is encountered it will be thrown.<br>
ClassMethod X12NewFunctionalGroup(InterchangeParent As EnsLib.EDI.X12.Document, DocType As %String = "", ForceNewPlaceHolderInParent As %Boolean = 0) As EnsLib.EDI.X12.Document [ Final ]
{
	#dim X12FunctionalGroup = ##class(EnsLib.EDI.X12.Document).%New()

	Set X12FunctionalGroup.Separators = InterchangeParent.Separators

	#dim docCategory, docName

	If $Length(DocType,":") < 2 {
		Set docCategory = InterchangeParent.DocTypeCategory
		Set docName = $Piece(DocType,":")
		If docName = "" {
			#; Find whether Group or FunctionalGroup
			#dim tSC = $$$OK
			Set docName = $Piece(##class(EnsLib.EDI.X12.Schema).ResolveSchemaTypeToDocType(docCategory,"Group",.tSC),":",2)
			$$$ThrowOnError(tSC)
		}
	} Else {
		Set docCategory = $Piece(DocType,":")
		Set docName = $Piece(DocType,":",2)
	}
	Do X12FunctionalGroup.PokeDocType(docCategory_":"_docName)

	/* Get parent id - this sets it in InterchangeParent if InterchangeParent not saved yet */
	Set X12FunctionalGroup.ParentId = InterchangeParent.getId()

	#dim tDataElementSeparator=$$$ELESEP(X12FunctionalGroup.Separators)

	/* Create blank GS segment */
	Set tGS=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(X12FunctionalGroup.Separators,1,3)_"GS"))
	$$$ThrowOnError(X12FunctionalGroup.AppendSegment(tGS))

	/* Initialize transaction set place holder segment. Set SegIndex to 2.*/
	#dim tTransactionSetsPlaceholder=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(X12FunctionalGroup.Separators,1,3)_"TransactionSetDocsRef"_tDataElementSeparator_2))
	$$$ThrowOnError(X12FunctionalGroup.AppendSegment(tTransactionSetsPlaceholder))

	/* Find InterchangeParent GroupDocsRef placeholder or create and add Functional Group*/
	#dim groupPlaceHolderIndex = ""
	#dim groupDocsRefPlaceHolderSegment As EnsLib.EDI.X12.Segment = $$$NULLOREF
	If 'ForceNewPlaceHolderInParent {
		Set groupDocsRefPlaceHolderSegment = InterchangeParent.FindSegment("GroupDocsRef", .groupPlaceHolderIndex)
	}

	/* If creating place holder segment add at end if no IEA or else insert before IEA */
	If (groupDocsRefPlaceHolderSegment = $$$NULLOREF) {
		#dim ieaSegmentId
		#dim ieaSegment = InterchangeParent.FindSegment("IEA",.ieaSegmentId)
		If ieaSegment '= $$$NULLOREF {
			/* will replace iea Segment with place holder then add back iea segment.  */
			Set groupPlaceHolderIndex = InterchangeParent.SegCount
		} Else {
			Set groupPlaceHolderIndex = InterchangeParent.SegCount+1
		}

		Set groupDocsRefPlaceHolderSegment=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(InterchangeParent.Separators,1,3)_"GroupDocsRef"_tDataElementSeparator_groupPlaceHolderIndex))

		If ieaSegment '= $$$NULLOREF {
			/* replace iea Segment with place holder then add back iea segment */
			$$$ThrowOnError(InterchangeParent.SetSegmentAt(groupDocsRefPlaceHolderSegment, ieaSegmentId))
			$$$ThrowOnError(InterchangeParent.AppendSegment(ieaSegment))
		} Else {
			$$$ThrowOnError(InterchangeParent.AppendSegment(groupDocsRefPlaceHolderSegment))
		}
	}

	Do InterchangeParent.AddChild(groupPlaceHolderIndex, X12FunctionalGroup)

	Return X12FunctionalGroup
}

/// Make and return an X12 Transaction Set Document without SE segment<br>
/// The separators will be taken from the <PARAMETER>GroupParent</PARAMETER>. <br>
/// The Document Category will be taken from <PARAMETER>GroupParent</PARAMETER> unless specified in
/// <PARAMETER>Doctype</PARAMETER> <br>
/// The Document Name will be taken from <PARAMETER>Doctype</PARAMETER><br>
/// The <PARAMETER>Doctype</PARAMETER> may specify just a document name and does not
/// need to include the Document category as that can be taken from the GroupParent. <br>
/// The new document will be set as a batch child of <PARAMETER>GroupParent</PARAMETER><br>
/// If <PARAMETER>ForceNewPlaceHolderInParent</PARAMETER> is true (the default is false) then
/// a new TransactionSetDocsRef place holder segment will be made in the <PARAMETER>GroupParent</PARAMETER><br>
/// If an Error is encountered it will be thrown.<br>
ClassMethod X12NewTransactionSet(GroupParent As EnsLib.EDI.X12.Document, DocType As %String = "", ForceNewPlaceHolderInParent As %Boolean = 0) As EnsLib.EDI.X12.Document [ Final ]
{
	#dim X12TransactionSet = ##class(EnsLib.EDI.X12.Document).%New()

	Set X12TransactionSet.Separators = GroupParent.Separators

	#dim docCategory, docName

	If $Length(DocType,":") < 2 {
		Set docCategory = GroupParent.DocTypeCategory
		Set docName = $Piece(DocType,":")
	} Else {
		Set docCategory = $Piece(DocType,":")
		Set docName = $Piece(DocType,":",2)
	}
	Do X12TransactionSet.PokeDocType(docCategory_":"_docName)

	/* Get parent id - this sets it in target if target not saved yet */
	Set X12TransactionSet.ParentId = GroupParent.getId()

	#dim tDataElementSeparator=$$$ELESEP(X12TransactionSet.Separators)

	/* Find target TransactionSetDocsRef placeholder or create and add TransactionSet */
	#dim transactionSetPlaceHolderIndex = ""
	#dim transactionSetDocsRefPlaceHolderSegment As EnsLib.EDI.X12.Segment = $$$NULLOREF
	If 'ForceNewPlaceHolderInParent {
		Set transactionSetDocsRefPlaceHolderSegment = GroupParent.FindSegment("TransactionSetDocsRef", .transactionSetPlaceHolderIndex)
	}
	/* If creating place holder segment add at end if no GE or else insert before GE */
	If (transactionSetDocsRefPlaceHolderSegment = $$$NULLOREF) {
		#dim geSegmentId
		#dim geSegment = GroupParent.FindSegment("GE",.geSegmentId)
		Set transactionSetDocsRefPlaceHolderSegment=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(GroupParent.Separators,1,3)_"TransactionSetDocsRef"_tDataElementSeparator_2))
		If geSegment '= $$$NULLOREF {
			/* replace ge Segment with place holder then add back ge segment */
			$$$ThrowOnError(GroupParent.SetSegmentAt(transactionSetDocsRefPlaceHolderSegment, geSegmentId))
			Set transactionSetPlaceHolderIndex = GroupParent.SegCount
			$$$ThrowOnError(GroupParent.AppendSegment(geSegment))
		} Else {
			$$$ThrowOnError(GroupParent.AppendSegment(transactionSetDocsRefPlaceHolderSegment))
			Set transactionSetPlaceHolderIndex = GroupParent.SegCount
		}
	}

	Do GroupParent.AddChild(transactionSetPlaceHolderIndex, X12TransactionSet)

	Return X12TransactionSet
}

/// For the <PARAMETER>X12Document</PARAMETER> the appropriate Trailer segment will be
/// created if it does not exist and the count and control fields assigned based
/// on the contents of the <PARAMETER>X12Document</PARAMETER>.<br>
/// If the optional <PARAMETER>Save</PARAMETER> is true (the default is false) then 
/// the <PARAMETER>X12Document</PARAMETER> will be saved. <br>
/// The method returns the empty string allowing the unloading of an object via assignment. <br>
/// If an Error is encountered it will be thrown.<br>
ClassMethod X12CompleteTrailerAndReturnClear(X12Document As EnsLib.EDI.X12.Document, Save As %Boolean = 0) As %String
{
	#dim tDataElementSeparator=$$$ELESEP(X12Document.Separators)
	#dim i

	If "Interchange"=X12Document.Name {

		#dim tNumGroups=X12Document.ChildCount
		#dim ieaSegment = X12Document.FindSegment("IEA")
		If ieaSegment '= $$$NULLOREF {
			/* Ensure the IEA group count and control number correct - requires mutable*/
			If (ieaSegment.IsMutable) {
				$$$ThrowOnError(ieaSegment.SetValueAt(tNumGroups,1))
				$$$ThrowOnError(ieaSegment.SetValueAt(X12Document.GetValueAt("1:13"),2))
			}
		} Else {
			Set tIEA=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(X12Document.Separators,1,3)_"IEA"_tDataElementSeparator_tNumGroups_tDataElementSeparator_X12Document.GetValueAt("1:13")))
			$$$ThrowOnError(X12Document.AppendSegment(tIEA))
		}

	} ElseIf ("Group"=X12Document.Name) {

		#dim tNumSets=X12Document.ChildCount
		#dim geSegment = X12Document.FindSegment("GE")
		If geSegment '= $$$NULLOREF {
			/* Ensure the GE transaction count and control number correct - requires mutable*/
			If (geSegment.IsMutable) {
				$$$ThrowOnError(geSegment.SetValueAt(tNumSets,1))
				$$$ThrowOnError(geSegment.SetValueAt(X12Document.GetValueAt("1:6"),2))
			}
		} Else {
			Set tGE=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(X12Document.Separators,1,3)_"GE"_tDataElementSeparator_tNumSets_tDataElementSeparator_X12Document.GetValueAt("1:6")))
			$$$ThrowOnError(X12Document.AppendSegment(tGE))
		}

	} Else {

		#dim seSegment = X12Document.FindSegment("SE")
		If seSegment '= $$$NULLOREF {
			/* Ensure SE segment count and control number correct - requires segment to be mutable*/
			If (seSegment.IsMutable) {
				$$$ThrowOnError(seSegment.SetValueAt((X12Document.SegCount),1))
				$$$ThrowOnError(seSegment.SetValueAt(X12Document.GetValueAt("1:2"),2))
			}
		} Else {
			Set tSE=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(X12Document.Separators,1,3)_"SE"_tDataElementSeparator_(X12Document.SegCount+1)_tDataElementSeparator_X12Document.GetValueAt("1:2")))
			$$$ThrowOnError(X12Document.AppendSegment(tSE))
		}
	}

	If Save $$$ThrowOnError(X12Document.%Save())

	Return $$$NULLOREF
}

/// The <PARAMETER>X12Document</PARAMETER> will be saved<br>
/// The method returns the empty string allowing the unloading of an object via assignment. <br>
/// If an Error is encountered it will be thrown.<br>
ClassMethod X12SaveDocumentAndReturnClear(X12Document As EnsLib.EDI.X12.Document) As %String
{
	$$$ThrowOnError(X12Document.%Save())
	Return $$$NULLOREF
}

/// Perform validation on <param>X12Document</param> and return true if the document passes validation or false if it fails validation.
/// The <param>X12Document</param> must have a Document Type set first in order to perform validation.
/// <param>ValidationType</param> can be either SNIP or Flags. <br>
/// <param>ValidationLevel</param> is either the SNIP level or the validation flags to use. <br>
ClassMethod X12ValidateDocument(X12Document As EnsLib.EDI.X12.Document, ValidationType As %String = "SNIP", ValidationLevel As %String = 1) As %Boolean
{
	If (""=X12Document.DocTypeCategory) {
		$$$ThrowStatus($$$ERROR($$$EnsEDIX12CannotValidateNoDocType))
	}
	#dim tSC As %Status = $$$OK
	If ValidationType = "SNIP" {
		Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).PerformSNIPValidation(X12Document,ValidationLevel,"First")
	} ElseIf ValidationType = "Flags" {
		Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).Validate(X12Document,ValidationLevel)
	} Else {
		Throw $$$ERROR($$$EnsErrGeneral, "ValidationType must be either 'SNIP' or 'Flags'")
	}

	Return $$$ISOK(tSC)
}

/// For X12 batch <param>X12Document</param>, return a new batch containing only those child documents which fail validation
/// as determined by the <param>ValidationType</param> and <param>ValidationLevel</param> specified.
/// The <param>X12Document</param> must have a Document Type set first in order to perform validation.
/// <param>ValidationType</param> can be either SNIP or Flags. <br>
/// <param>ValidationLevel</param> is either the SNIP level or the validation flags to use. <br>
ClassMethod X12BatchErrors(X12Document As EnsLib.EDI.X12.Document, ValidationType As %String = "SNIP", ValidationLevel As %String = 1) As EnsLib.EDI.X12.Document
{
	If (""=X12Document.DocTypeCategory) {
		$$$ThrowStatus($$$ERROR($$$EnsEDIX12CannotValidateNoDocType))
	}
	If X12Document.Name = "Interchange" {
		$$$ThrowOnError(##class(EnsLib.EDI.X12.Util.Validator).SplitBatch(X12Document,.tSuccesses,.tErrors,ValidationType,ValidationLevel))
	} ElseIf $Case(X12Document.Name,"Group":1,"FunctionalGroup":1,:0) {
		$$$ThrowOnError(##class(EnsLib.EDI.X12.Util.Validator).SplitGroup(X12Document,.tSuccesses,.tErrors,ValidationType,ValidationLevel))
	}
	If $IsObject($G(tSuccesses)) && ##class(EnsLib.EDI.X12.Document).%ExistsId(tSuccesses.getId()) {
		Do ##class(EnsLib.EDI.X12.Document).%DeleteId(tSuccesses.getId())
	}
	Return tErrors
}

/// For X12 batch <param>X12Document</param>, return a new batch containing only those child documents which pass validation
/// as determined by the <param>ValidationType</param> and <param>ValidationLevel</param> specified.
/// The <param>X12Document</param> must have a Document Type set first in order to perform validation.
/// <param>ValidationType</param> can be either SNIP or Flags. <br>
/// <param>ValidationLevel</param> is either the SNIP level or the validation flags to use. <br>
ClassMethod X12BatchSuccesses(X12Document As EnsLib.EDI.X12.Document, ValidationType As %String = "SNIP", ValidationLevel As %String = 1) As EnsLib.EDI.X12.Document
{
	If (""=X12Document.DocTypeCategory) {
		$$$ThrowStatus($$$ERROR($$$EnsEDIX12CannotValidateNoDocType))
	}
	If X12Document.Name = "Interchange" {
		$$$ThrowOnError(##class(EnsLib.EDI.X12.Util.Validator).SplitBatch(X12Document,.tSuccesses,,ValidationType,ValidationLevel,,0))
	} ElseIf $Case(X12Document.Name,"Group":1,"FunctionalGroup":1,:0) {
		$$$ThrowOnError(##class(EnsLib.EDI.X12.Util.Validator).SplitGroup(X12Document,.tSuccesses,,ValidationType,ValidationLevel,,0))
	}
	Return tSuccesses
}

/// Construct the Reply Interchange containing a 999 or 997 Transaction Set based on validation against <param>pOriginalDoc</param> <br>
/// The <param>X12Document</param> must have a Document Type set first in order to perform validation.
/// <param>BatchReplyType</param> is string indicating what kind of batch reply should we construct for an Interchange batch we have received
/// Note that all the options here that relate to TA1 segments are used to force a TA1 segment to be generated, often as the only body segment of the reply interchange.
/// This is used to represent the presence or absence of errors in the whole inbound Interchange.  However if an error is found in the incoming
/// ISA or IEA that can only be reported in a TA1 segment, then a TA1 will be generated even if the configured setting does not force a TA1 to appear. <p>
/// - All : Generate a reply Interchange containing a reply notification for every TransactionSet in the Interchange we received <br>
/// - All+TA1 : Generate a reply Interchange containing a TA1 segment that indicates acceptance or error status for the whole Interchange, and a reply notification for every TransactionSet in the Interchange we received <br>
/// - All+ISA14TA1 : Generate a reply Interchange containing a TA1 segment only if either a 1 appears in field ISA:14 of the ISA header segment or if there is an error at the Interchange level.  If no error at the Interchange level, then send a reply for each Transaction Set we received. </br>
/// - Errors : Generate a reply Interchange containing reply notifications only for TransactionSets in which errors are detected, or an empty Interchange if no error is found <br>
/// - OnlyIfErrors : Only if errors are found, generate a reply Interchange containing reply notifications only for TransactionSets in which errors are detected <br>
/// - Successes : Generate a reply Interchange containing reply notifications only for TransactionSets in which no errors are detected, or an empty Interchange if only errors are found <br>
/// - TA1 : Generate a reply Interchange containing only a TA1 segment that indicates acceptance or error status for the whole Interchange we received <br>
/// - OnlyIfErrorTA1 : Only if errors are found, generate a reply Interchange containing only a TA1 segment that indicates error status for the whole Interchange we received <br>
/// - ISA14-TA1 : Generate a reply Interchange containing only a TA1 segment if a 1 appears in field ISA:14 of the ISA header segment of the incoming Interchange; otherwise return nothing. <br>
/// - ISA14-OnlyIfErrorTA1 : Only if errors are found and field ISA:14 of the incoming ISA header segment is set to 1, generate a reply Interchange containing only an error TA1 segment; otherwise return nothing. <br>
/// <param>ValidationType</param> can be either SNIP or Flags. <br>
/// <param>ValidationLevel</param> is either the SNIP level or the validation flags to use. <br>
/// <param>BatchErrorAction</param> is a string indicating what to do when detecting a validation error in a batch Interchange document: <br>
/// - Reject With All Errors : Reject the whole batch if any error is found in any document within it. Enumerate all errors found if BatchReplyType allows for reporting them. This will prevent forwarding any documents in a batch until all have been read and validated.<br>
/// - Accept With Errors : Accept documents with errors, but do take note of all errors found if BatchReplyType allows for reporting them. This will prevent forwarding any documents in a batch until all have been read and validated.<br>
/// - Reject On First Error : Reject the whole batch when the first error is found in any document within it. Don't bother checking for more errors or parsing any further contents of the Interchange. This will prevent forwarding any documents in a batch until all have been read and validated. <br>
/// - Reject Individual Errors : Reject only those documents within the Interchange that have errors. Forward each acceptable child document to the target config item(s) as soon as it has been read and validated. <p>
/// <param>LocalApplicationID</param> is colon-separated Local ID:Qualifier codes representing this (receiving) facility and application <br>
/// These are used in constructing reply document headers.<br>
/// The '@' symbol represents using the corresponding field from the incoming message.<br>
/// If your ID must contain a literal @ symbol, escape it with backslash: '\@' <p>
ClassMethod X12BatchReply(X12Document As EnsLib.EDI.X12.Document, BatchReplyType As %String = "All", ValidationType As %String = "SNIP", ValidationLevel As %String = 1, BatchErrorAction As %String = "All", LocalApplicationID As %String = "@:@") As EnsLib.EDI.X12.Document
{
	#dim tSC As %Status = $$$OK

	If ((""'=X12Document.ParentId) || ("ISA"'=X12Document.GetValueAt("1:0"))) {
		Throw $$$ERROR($$$EnsErrGeneral, "Reply documents can only be generated for X12 batches")
	}

	If (""=X12Document.DocTypeCategory) {
		$$$ThrowStatus($$$ERROR($$$EnsEDIX12CannotValidateNoDocType))
	}

	Set BatchReplyType = $Case(BatchReplyType,"All+TA1":"AllTA1","All+ISA14TA1":"AllI14TA1","Errors":"Errs","OnlyIfErrors":"OnlyErrs","Successes":"Succ","OnlyIfErrorTA1":"ErrTA1","ISA14-TA1":"I14","ISA14-OnlyIfErrorTA1":"I14Err", :BatchReplyType)

	Set tForceTA1=$Case(BatchReplyType, "AllTA1":1, "TA1":1, "ErrTA1":1, "AllI14TA1":-1, "I14":-1, "I14Err":-1, :0)
	If tForceTA1 = -1 {
		Set tForceTA1 = X12Document.GetValueAt("1:14")
	}

	If ValidationType = "SNIP" {
		Do ##class(EnsLib.EDI.X12.Util.Validator).PerformSNIPValidation(X12Document,ValidationLevel,BatchErrorAction,,0)
	} ElseIf ValidationType = "Flags" {
		Do ##class(EnsLib.EDI.X12.Util.Validator).Validate(X12Document,ValidationLevel,1,1,BatchErrorAction)
	} Else {
		Throw $$$ERROR($$$EnsErrGeneral, "ValidationType must be either 'SNIP' or 'Flags'")
	}

	#; "HasError" subscript used for tracking batches in which envelope passed, but some Transaction Set had a validation error
	Set tHasError = $G($$$X12ValInfo(X12Document.getId(),"HasError"),0)
	
	If $Case(BatchReplyType,"All":1,"AllTA1":1,"AllI14TA1":1,"Errs":1,"OnlyErrs":tHasError,"Succ":1,:0) {
		Set tReplyDoc = ##class(EnsLib.EDI.X12.Util.Validator).ConstructBatchReply(X12Document,.tSC,BatchReplyType,tForceTA1,BatchErrorAction,ValidationType_":"_ValidationLevel,LocalApplicationID)
	} ElseIf $Case(BatchReplyType,"TA1":1,"I14":tForceTA1,"I14Err":tForceTA1&&tHasError,"ErrTA1":tHasError,:0){
		Set tReply = ##class(EnsLib.EDI.X12.Util.Validator).ConstructReplyEnvelope(X12Document,.tSC,,,LocalApplicationID,1,.tReplyIEA)
		If $IsObject(tReplyDoc)&&$IsObject(tReplyIEA) {
			Do tReplyDoc.AppendSegment(tReplyIEA)
		}
	} Else {
		Set tReplyDoc = $$$NULLOREF
	}
	$$$ThrowOnError(tSC)
	Return tReplyDoc
}

}
