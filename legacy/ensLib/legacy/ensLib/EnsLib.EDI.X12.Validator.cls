/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

/// Error processor, more error defs, index not in errors, 
/// This is the X12 Interchange parser
Class EnsLib.EDI.X12.Validator Extends EnsLib.EDI.X12.Scanner [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter AllowedPunct As String = "!""&'()*+,-./:;?= %~@[]_{}\|<>^`#$";

ClassMethod IsValidSeparator(pChar As %String) [ CodeMode = expression ]
{
..#AllowedPunct[pChar||($A(pChar)<32)
}

/// This holds the base character set
Parameter AllowedChars As String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyzÀÁÂÄàáâäÈÉÊèéêëÌÍÎìíîïÒÓÔÖòóôöÙÚÛÜùúûüÇçÑñ";

ClassMethod IsValidChar(pChar As %String) [ CodeMode = expression ]
{
..#AllowedChars_..#AllowedPunct_$Char(9,10,13)[pChar
}

ClassMethod GetTA1Code(pSC As %Status = {$$$OK}, pInterchange As EnsLib.EDI.Document = {$$$NULLOREF}) As %String
{
	#dim tCode As %String = $$$CodeTA1I18NoError
	#dim tMatches As %Boolean = 1
	Do {
		If $$$ISERR(pSC) {
			Set tCode = $Case($System.Status.GetErrorCodes(pSC),
				"<EnsEDIX12>InvalidSegmentTerminator":$$$CodeTA1I18InvalidSegmentTerminator,
				"<EnsEDIX12>UnexpectedEOD":$$$CodeTA1I18UnexpectedEndOfFile,
				"<EnsEDIX12>TCPTerminatedReadTimeoutExpired":$$$CodeTA1I18UnexpectedEndOfFile,
				"<EnsEDIX12>ISATruncated":$$$CodeTA1I18UnexpectedEndOfFile,
				"<EnsErr>TCPReadTimeoutExpired":$$$CodeTA1I18UnexpectedEndOfFile,
				"<EnsErr>TCPTerminatedReadTimeoutExpired":$$$CodeTA1I18UnexpectedEndOfFile,
				"<EnsEDIX12>UnexpectedEODBinary":$$$CodeTA1I18InvalidContent,
				"<EnsEDIX12>InvalidSegmentName":$$$CodeTA1I18InvalidContent,
				"<EnsEDIX12>BinaryLeftover":$$$CodeTA1I18InvalidContent,
				"<EnsEDIX12>BadBINLength":$$$CodeTA1I18InvalidContent,
				"<EnsEDIX12>ExpectedSegment":$$$CodeTA1I18InvalidContent,
				:"999"
			)
			Quit:$Case(tCode,$$$CodeTA1I18InvalidSegmentTerminator:1,$$$CodeTA1I18UnexpectedEndOfFile:1,:0)
		}
			
		If $IsObject(pInterchange) {
			If (""=pInterchange.DocType)||(pInterchange.Name'="Interchange") {
				#; Invalid Control Structure
				Set tCode = $$$CodeTA1I18InvalidControlStructure
				Quit
			}
			If ""=pInterchange.ElementSeparator {
				#; Invalid Data Element Separator
				Set tCode = $$$CodeTA1I18InvalidDataElementSeparator
				Quit
			}
			If ($$$ISERR(pInterchange.%ParsingError)&&($System.Status.GetErrorCodes(pInterchange.%ParsingError)["<EnsEDIX12>InvalidComponentSeparator"))||(""=pInterchange.ComponentSeparator) {
				#; Invalid Component Element Separator
				Set tCode = $$$CodeTA1I18InvalidComponentElementSeparator
				Quit
			}
			If ""=pInterchange.SegmentTerminator {
				#; The Segment Terminator is invalid
				Set tCode = $$$CodeTA1I18InvalidSegmentTerminator
				Quit
			}
			#dim tISA As EnsLib.EDI.X12.Segment = pInterchange.GetSegmentAt(1)
			#dim tIEA As EnsLib.EDI.X12.Segment = pInterchange.GetSegmentAt(pInterchange.SegCount)
			Set tControlNum = tISA.GetValueAt($$$ISAInterchangeControlNumber)
			If ($L(tControlNum)'=9)||($zstrip(tControlNum,"<>W")'?1.9N) {
				#; Invalid Interchange Control Number Value
				Set tCode = $$$CodeTA1I18InvalidControlNumber
				Quit
			}
			If tControlNum '= tIEA.GetValueAt($$$IEAInterchangeControlNumber) {
				#; The Interchange Control Number In the Header and Trailer Do Not Match.  The Value From the Header is Used in the Acknowledgment
				Set tCode = $$$CodeTA1I18InterchangeControlNumberMismatch
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAAuthorizationInformationQual))'=2 {
				#; Invalid Authorization Information Qualifier Value
				Set tCode = $$$CodeTA1I18InvalidAuthorizationQualifier
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAAuthorizationInformation))'=10 {
				#; Invalid Authorization Information Value
				Set tCode = $$$CodeTA1I18InvalidAuthorizationInformation
				Quit
			}
			If $L(tISA.GetValueAt($$$ISASecurityInformationQualifier))'=2 {
				#; Invalid Security Information Qualifier Value
				Set tCode = $$$CodeTA1I18InvalidSecurityQualifier
				Quit
			}
			If $L(tISA.GetValueAt($$$ISASecurityInformation))'=10 {
				#; Invalid Security Information Value
				Set tCode = $$$CodeTA1I18InvalidSecurityInformation
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAInterchangeIDQualifier))'=2 {
				#; Invalid Interchange ID Qualifier for Sender
				Set tCode = $$$CodeTA1I18InvalidSenderIDQualifier
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAInterchangeSenderID))'=15 {
				#; Invalid Interchange Sender ID
				Set tCode = $$$CodeTA1I18InvalidSenderID
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAInterchangeIDQualifier2))'=2 {
				#; Invalid Interchange ID Qualifier for Receiver
				Set tCode = $$$CodeTA1I18InvalidReceiverIDQualifier
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAInterchangeReceiverID))'=15 {
				#; Invalid Interchange Receiver ID
				Set tCode = $$$CodeTA1I18InvalidReceiverID
				Quit
			}
			#dim tDate As %String = tISA.GetValueAt($$$ISAInterchangeDate)
			#; Interchange Date - YYMMDD
			If tDate'?6N {
				Set tMatches = 0
			} Else {
				#dim tMonth As %Integer = $E(tDate,3,4)
				If (tMonth < 1) || (tMonth > 12) {
					Set tMatches = 0
				} ElseIf (($E(tDate,5,6) < 1) || ($E(tDate,5,6)>$Case(tMonth,2:29,4:30,6:30,9:30,11:30,:31))) {
					Set tMatches = 0
				}
			}
			If 'tMatches {
				#; Invalid Interchange Date Value
				Set tCode = $$$CodeTA1I18InvalidDate
				Quit
			}	
			#dim tTime As %String = tISA.GetValueAt($$$ISAInterchangeTime)
			#; Interchange Time - HHMM
			If tTime'?4N {
				Set tMatches = 0
			} ElseIf ($E(tTime,1,2) > 23) {
				Set tMatches = 0
			} ElseIf ($E(tTime,3,4) > 59) {
				Set tMatches = 0
			}
			If 'tMatches {
				#; Invalid Interchange Time Value
				Set tCode = $$$CodeTA1I18InvalidTime
				Quit
			}
			#dim tVersionNum As %String = tISA.GetValueAt($$$ISAInterchangeControlVersionNum)
			If tVersionNum'?5N {
				#; Invalid Interchange Control Version ID Value
				Set tCode = $$$CodeTA1I18InvalidVersionID
				Quit
			}
			#; ISA11 is repetition separator instead for versions after 00401
			If (tVersionNum <= 00401) && ($L(tISA.GetValueAt($$$ISAInterchangeControlStandardsI))'=1) {
				#; Invalid Interchange Standards Identifier Value
				Set tCode = $$$CodeTA1I18InvalidStandardsID
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAAcknowledgmentRequested))'=1 {
				#; Invalid Acknowledgment Requested Value
				Set tCode = $$$CodeTA1I18InvalidAcknowledgmentRequested
				Quit
			}
			If $L(tISA.GetValueAt($$$ISAUsageIndicator))'=1 {
				#; Invalid Test Indicator Value
				Set tCode = $$$CodeTA1I18InvalidTestIndicator
				Quit
			}
			If tIEA.GetValueAt($$$IEANumberofIncludedFunctionalGr)'=pInterchange.ChildCount {
				#; Invalid Number of Included Groups Value
				Set tCode = $$$CodeTA1I18InvalidNumberOfIncludedGroups
				Quit
			}
		}
	} While 0
	
	Quit tCode
}

ClassMethod Get997GroupCodes(pSC As %Status = {$$$OK}, pGroup As EnsLib.EDI.X12.Document = {$$$NULLOREF}) As %String
{
	#dim tCodes As %String = $$$CodeAK9716NoSpecificErrorCode
	
	#; If no error or error is not at the functional group level, no error code should be sent
	If $$$ISERR(pSC) && '$System.Status.Equals(pSC,$$$EnsEDIX12AllChildrenFailedValidation,$$$EnsEDIX12ChildFailedValidation) {
		Set tCodes = "999"
	}
	
	If $IsObject(pGroup) {
		If pGroup.resolveChildDocType()="" {
			#; Functional Group Version Not Supported
			Set tCodes=tCodes_","_$$$CodeAK9716FunctionalGroupVersionNotSupported
		}
		
		Set tGS = pGroup.GetSegmentAt(1)
		If ('$IsObject(tGS) || (tGS.Name'="GS")) {
			#; This should never happen because missing GS triggers a TA1 error
			#; Adding an error code here as well just to be safe
			Set tCodes = tCodes_","_$$$CodeAK9716FunctionalGroupNotSupported
		}
		
		Set tGE = pGroup.GetSegmentAt(pGroup.SegCount)
		If ($IsObject(tGE) && (tGE.Name="GE")) {
			#; Number of included transaction sets doesn't match actual count
			Set:tGE.GetValueAt($$$GENumberofTransactionSetsInclu)'=pGroup.ChildCount tCodes = tCodes_","_$$$CodeAK9716InvalidNumberOfTransactionSets
			
			If ($IsObject(tGS) && (tGS.Name="GS")) {
				If tGS.GetValueAt($$$GSGroupControlNumber)'=tGE.GetValueAt($$$GEGroupControlNumber) {
					Set tCodes = tCodes_","_$$$CodeAK9716GroupControlNumberMismatch
				}
			}

		} Else {
			#; Functional Group Trailer Missing
			Set tCodes = tCodes_","_$$$CodeAK9716FunctionalGroupTrailerMissing
		}

		If ($P(tCodes,",")="999")&&($P(tCodes,",",2,*)'="") {
			#; Remove the meaningless 999 if we have any more useful error codes
			Set tCodes = $P(tCodes,",",2,*)
		} ElseIf ","=$E(tCodes) {
			Set tCodes = $E(tCodes,2,*)
		}
	}
	
	Quit tCodes
}

ClassMethod Get997Codes(pSC As %Status) As %String
{
	Quit:$$$ISERR(pSC) "999"
	Quit "000"
}

ClassMethod Validate(pDoc As EnsLib.EDI.X12.Document, pValSpec As %String) As %Status
{
	Quit:pValSpec["1" pDoc.BuildMap()
	Quit $$$OK
}

/*
from: 08/26/02 15 A White Paper Describing the Recommended Solutions
 For Compliance Testing and Certification of the HIPAA transactions
Version 3.0

Recommended Types of Testing:

Type 1: EDI syntax integrity testing - Testing of the EDI file for valid segments,
segment order, element attributes, testing for numeric values in numeric data elements,
validation of X12 or NCPDP syntax, and compliance with X12 and NCPDP rules. This
will validate the basic syntactical integrity of the EDI submission.

Type 2: HIPAA syntactical requirement testing - Testing for HIPAA Implementation
Guide-specific syntax requirements, such as limits on repeat counts, used and not
used qualifiers, codes, elements and segments. Also included in this type is testing for
HIPAA required or intra-segment situational data elements, testing for non-medical
code sets as laid out in the Implementation Guide, and values and codes noted in the
Implementation Guide via an X12 code list or table.

Type 3: Balancing - Testing the transaction for balanced field totals, financial
balancing of claims or remittance advice, and balancing of summary fields, if
appropriate. An example of this includes items such as all claim line item amounts
equal the total claim amount. (See pages 19-22, Healthcare Claim Payment/Advice -
835 Implementation Guide for balancing requirements of the 835 transaction.)

Type 4: Situation testing - The testing of specific inter-segment situations described
in the HIPAA Implementation Guides, such that: If A occurs then B must be populated.
This is considered to include the validation of situational fields given values or situations
present elsewhere in the file. Example: if the claim is for an accident, the accident date
must be present.

Type 5: External code set testing - Testing for valid Implementation Guide-specific
code set values and other code sets adopted as HIPAA standards. This level of testing
will not only validate the code sets but also make sure the usage is appropriate for any
particular transaction and appropriate with the coding guidelines that apply to the
specific code set. Validates external code sets and tables such as CPT, ICD9, CDT,
NDC, status codes, adjustment reason codes, and their appropriate use for the
transaction.

Type 6: Product types or line of services: This testing type is required to ensure that
the segments/records of data that differ based on certain healthcare services are
properly created and processed into claims data formats. These specific requirements
are described in the Implementation Guides for the different product types or lines of
service. For example, ambulance, chiropractic, podiatry, home health, parenteral and
enteral nutrition, durable medical equipment, psychiatry, and other specialized services
have specific requirements in the Implementation Guide that must be tested before
putting the transaction in production. This type of testing only applies to a trading
partner candidate that conducts transactions for the specific line of business or product
type.

Type 7: Implementation Guide-Specific Trading Partners: The Implementation
Guides contain some HIPAA requirements that are specific to Medicare, Medicaid, and
Indian Health. Compliance or testing with these payer specific requirements is not
required from all trading partners. If the trading partner candidate intends to exchange
transactions with one of these Implementation Guide special payers, this type of testing
is required. When a certification service certifies a trading partner for compliance, the
certification service must indicate whether these payer specific requirements were met
during the certification process. Other payers and trading partners may have their own
specific business requirements; but, unless they are listed in the HIPAA Implementation
Guides, they are not HIPAA requirements. These non-HIPAA trading partner specific
requirements must be tested as part of the business-to-business testing.

*/
}
