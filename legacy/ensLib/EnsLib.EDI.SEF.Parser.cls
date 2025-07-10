/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.Parser Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the scanner
Property Scanner As EnsLib.EDI.SEF.Scanner;

/// This holds the scanner stack
Property ScannerStack As EnsLib.EDI.SEF.Util.Stack;

/// This holds the 'Standard Variations' specification from the .STD section
Property STD As %String;

/// This holds the agency identifier
Property Agency As %String;

/// This holds the standard identifier
Property Standard As %String;

/// This holds the segment ordinal within the SET defintion
Property SetOrdinal As %Integer;

/// This holds the segment position withing the SET definition
Property SetPosition As %Integer;

/// This holds the set segment position increment value for the SET definition
Property SetIncrement As %Integer;

/// This holds the element/composite ordinal within SEG definition
Property SegOrdinal As %Integer;

/// This holds the element ordinal withing the COMS definition
Property ComOrdinal As %Integer;

/// This holds the document key
Property DocKey As %String;

/// This holds the table counter
Property TableCounter As %Integer;

/// This holds the calculated default standard requirement
Property DefaultStdRequirement As %String;

/// This holds already parsed elements, as elements may appear in multiple segments,composites
/// there is no point in parsing these multiple times
Property ParsedElements As array Of EnsLib.EDI.SEF.Element;

/// This holds already parsed elements, as elements may appear in multiple segments,composites
/// there is no point in parsing these multiple times
Property ParsedSegments As array Of EnsLib.EDI.SEF.Segment;

/// Parse a document
Method ParseDocument(pDocKey As %String, pFileType As %String, Output pDocument As EnsLib.EDI.SEF.Document) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Record the Keys
		Set ..DocKey=pDocKey
		
		Set tVer=+$Piece($Get(^IRIS.Temp.SEF(..DocKey,"VER"))," ",2)
		If tVer>1.6 {
			Set tSC=$$$ERROR($$$GeneralError,"Fatal Error - Version Mismatch,Expected 1.6 and lower, received "_tVer)
			Quit
		}
		#; Pick out the STD specification, this affects how the ordinals
		#; are calculated and used
		Set ..STD=$Get(^IRIS.Temp.SEF(..DocKey,"STD"))
		
		#; Create a Document to hold the parse tree
		Set pDocument=##class(EnsLib.EDI.SEF.Document).%New()
		$$$ASSERTNOLOG($IsObject(pDocument))
		
		#; INI section MUST be present	
		Set tINI=$Get(^IRIS.Temp.SEF(..DocKey,"INI"))	
		If tINI="" {
			Set tSC=$$$ERROR($$$GeneralError,"Fatal Error - INI Section Missing")
			Quit
		}
		Set tDocType=$Piece(tINI,",",3),tAgency=$Piece(tINI,",",4),tStandard=$Piece(tINI,",",5),tTitle=$Piece(tINI,",",6,99)
		If "|"_$$$GENDOD_"|"_$$$TDCC_"|"_$$$TRADACOMS_"|"_$$$UNEDIFACT_"|"_$$$ASCX12_"|"'[("|"_tAgency_"|") {
			Set tSC=$$$ERROR($$$GeneralError,"Fatal Error - Unrecognized Agency "_tAgency)
			Quit
		}
		Set ..Standard=tStandard,..Agency=tAgency,(..TableCounter,..SetOrdinal,..SetPosition)=0,..SetIncrement=10

		#; The document is named after the transaction set
		Set pDocument.Name=..DocKey,pDocument.Standard=..Standard,pDocument.Agency=..Agency
		Set pDocument.DocType=tDocType,pDocument.Title=tTitle,pDocument.Ref=pFileType
				
		#; Walk through the Sets for the named document
		Set tSetName="" For { Set tSetName=$Order(^IRIS.Temp.SEF(..DocKey,"SETS",tSetName))  Quit:""=tSetName
			#; Parse the Transaction Set 
			Set tSC=..ParseSet(tSetName,pDocument,.tSet)  Quit:$$$ISERR(tSC)
			
			#; set collection
			Do pDocument.Sets.Insert(tSet)
		}
		If $$$ISERR(tSC) Quit
		
		#; Parse the object variables
		Set tSC=..ParseObjectVariables(pDocument,.tObjVars)
		If $$$ISERR(tSC) Quit
		
		Set pDocument.ObjVars=tObjVars
		
		#; Parse the semantic references
		Set tSC=..ParseSemanticReferences(pDocument,.tSemRefs)
		If $$$ISERR(tSC) Quit
		
		Set pDocument.SemRefs=tSemRefs
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseCodeSet(pParent As EnsLib.EDI.SEF.Codes, Output pCodeSet As EnsLib.EDI.SEF.CodeSet) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokLBRACK)
		
		Set pCodeSet=##class(EnsLib.EDI.SEF.CodeSet).%New()
		$$$ASSERTNOLOG($IsObject(pCodeSet))
		
		#; Fix up parent
		Set pCodeSet.Parent=pParent
		
		#; Create the Used and Added code lists
		Set tUsed=##class(EnsLib.EDI.SEF.NodeList).%New()
		$$$ASSERTNOLOG($IsObject(tUsed))
		
		Set tAdded=##class(EnsLib.EDI.SEF.NodeList).%New()
		$$$ASSERTNOLOG($IsObject(tAdded))
		
		Set tExceptions=##class(EnsLib.EDI.SEF.NodeList).%New()
		$$$ASSERTNOLOG($IsObject(tExceptions))
		
		#; Create the CodeTransactionSet list
		Set tTransactionSetList=##class(EnsLib.EDI.SEF.CodeTransactionSetList).%New()
		$$$ASSERTNOLOG($IsObject(tTransactionSetList))
		
		#; Skip '['
		Do ..Scanner.NextToken()
		
		Set (tOrdinal,tReferBackPosition)="",(tUseDictionary,tUseExceptions)=0
	
		#; Refer back position?
		If ..Scanner.CurrentToken=$$$tokPOUND {
			#; Skip '#'
			Do ..Scanner.NextToken()
			Set tReferBackPosition=..Scanner.Integer()
			If tReferBackPosition="" {
				Set tSC=..ParserError("Expected Integer")
				Quit
			}
			
			If ..Scanner.CurrentToken'=$$$tokCOMMA {
				Set tSC=..ParserError("Expected delimiter ','")
				Quit
			}
			
			#; Skip ','
			Do ..Scanner.NextToken()
		}
		
		If ..Scanner.CurrentToken=$$$tokLPARN {
						
			#; Skip '('
			Do ..Scanner.NextToken()
			
			#; Ordinal
			Set tOrdinal=..Scanner.Integer()
			If tOrdinal="" {
				Set tSC=..ParserError("Expected Ordinal")
				Quit
			}
			
			If ..Scanner.CurrentToken'=$$$tokRPARN {
				Set tSC=..ParserError("Expected delimiter ')'")
				Quit
			}
			
			#; Skip ')'
			Do ..Scanner.NextToken()
		}
		
		If ..Scanner.CurrentChar="*" {
			#; Use all codes in the dictionary
			Set tUseDictionary=1 Do ..Scanner.NextToken()
		} Else {
		
			If ..Scanner.CurrentToken=$$$tokCOMMA || (..Scanner.CurrentToken=$$$tokVBAR) {
				
				#; Skip empty code
				Do ..Scanner.NextToken()
			}
			
			#; Use only selected codes
			While (..Scanner.CurrentToken=$$$tokDIGIT||(..Scanner.CurrentToken=$$$tokLETTER)||(..Scanner.CurrentToken=$$$tokMINUS)) {
				If ..Scanner.CurrentToken=$$$tokMINUS {
					#; Set exceptions flag, once on, all codes are exceptions
					Set tUseExceptions=1
					Do ..Scanner.NextToken()
				}
			
				Set tSC=..ParseCode($Case(tUseExceptions,1:tExceptions,:tUsed),.tCode)
				If $$$ISERR(tSC) Quit
						
				If tUseExceptions=1 {
					#; Add to the list of exception codes
					Do tExceptions.Insert(tCode)
				} Else {
					#; Add to the list of used codes
					Do tUsed.Insert(tCode)
				}
				
				If ..Scanner.CurrentToken'=$$$tokVBAR&&(..Scanner.CurrentToken'=$$$tokCOMMA) Quit
				
				#; Skip '|' or ','
				Do ..Scanner.NextToken()
			}
		}
		
		If $$$ISERR(tSC) Quit
		
		If ..Scanner.CurrentToken=$$$tokLBRACE {
			Do {
				#; Skip Delimiter
				Do ..Scanner.NextToken()
				
				If ..Scanner.CurrentToken=$$$tokVBAR {
					
					#; Skip leading VBAR, we are ignoring the partitioning of
					#; codes until we discover what the semantics are
					 Do ..Scanner.NextToken()
				}
				
				#; Empty list?
				If ..Scanner.CurrentToken=$$$tokRBRACE Quit
				
				Set tSC=..ParseCode(tAdded,.tCode)
				If $$$ISERR(tSC) Quit
				
				#; Add to the list of added codes
				Do tAdded.Insert(tCode)
				
			} While (..Scanner.CurrentToken=$$$tokCOMMA || (..Scanner.CurrentToken=$$$tokVBAR))
			
			If ..Scanner.CurrentToken'=$$$tokRBRACE {
				Set tSC=..ParserError("Expected delimiter '}'")
				Quit
			}
			
			#; Skip '}'
			Do ..Scanner.NextToken()
		}
		
		If ..Scanner.CurrentToken'=$$$tokRBRACK {
			Set tSC=..ParserError("Expected delimiter ']'")
			Quit
		}
		
		#; Skip ']'
		Do ..Scanner.NextToken()

		#; Parse any TransactionSets present
		While ..Scanner.CurrentToken=$$$tokPLUS {
			Set tSC=..ParseCodeTransactionSet(pCodeSet,.tTransactionSet)
			If $$$ISERR(tSC) Quit
			
			Do tTransactionSetList.Insert(tTransactionSet)
		}
		
		Set pCodeSet.Ordinal=tOrdinal
		Set pCodeSet.Used=tUsed
		Set pCodeSet.Added=tAdded
		Set pCodeSet.Exceptions=tExceptions
		Set pCodeSet.TransactionSets=tTransactionSetList
		Set pCodeSet.UseDictionary=tUseDictionary
		Set pCodeSet.ReferBackPosition=tReferBackPosition
	
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseCodeTransactionSet(pParent As EnsLib.EDI.SEF.CodeSet, Output pTransactionSet As EnsLib.EDI.SEF.CodeTransactionSet) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokPLUS)
		
		#; Create the transaction set
		Set pTransactionSet=##class(EnsLib.EDI.SEF.CodeTransactionSet).%New()
		$$$ASSERTNOLOG($IsObject(pTransactionSet))
		
		#; Fix up the parent
		Set pTransactionSet.Parent=pParent

		#; Skip '+'
		Do ..Scanner.NextToken()

		Set tID=..Scanner.Integer()
		If tID="" {

			#; Constructs like '+//GS//1' or '+//MEA//4-1' should not give error - they are "code set attached in segment dictionary"
			
			#; Look for '//'
			Set tFoundFirstToken=0
			If ..Scanner.CurrentToken=$$$tokSLASH {
				Do ..Scanner.NextToken()
				If ..Scanner.CurrentToken=$$$tokSLASH {
					Do ..Scanner.NextToken()
					Set tFoundFirstToken=1	
				}
			}
			If tFoundFirstToken {
				#; Find Segment Structure Name or Composite Structure Name
				Set tSegStruct = ..Scanner.Identifier()
				
				If tSegStruct'="" {
					#; Look for second set of '//'
					Set tFoundSecondToken=0
					If ..Scanner.CurrentToken=$$$tokSLASH {
						Do ..Scanner.NextToken()
						If ..Scanner.CurrentToken=$$$tokSLASH {
							Do ..Scanner.NextToken()
							Set tFoundSecondToken=1	
						}
					}
					If tFoundSecondToken {
						Set tItemOrdinal=..Scanner.Integer()
						If tItemOrdinal'="" {
							Set tSubElementOrdinal=""
							If ..Scanner.CurrentToken=$$$tokMINUS {
								
								#; Skip '-'
								Do ..Scanner.NextToken()
								
								Set tSubElementOrdinal=..Scanner.Integer()
								If tSubElementOrdinal'="" {
									#; Quit without error for construct like '//MEA//4-1'
									Quit  // if we want to use this info, we can't quit here
								}
							}
							Else {
								#; Quit without error for construct like '//GS//1'
								Quit
							}
						}
					}
				}
			}
			#; Give an error if what follows the '+' is neither a transaction set ID nor a construct like //GS//1
			Set tSC=..ParserError("Expected Transaction Set ID")
			Quit
		}
		
		If ..Scanner.CurrentToken'=$$$tokSLASH {
			Set tSC=..ParserError("Expected delimiter '/'")
			Quit
		}
		
		#; Skip '/'
		Do ..Scanner.NextToken()
		
		Set tSegmentOrdinal=..Scanner.Integer()
		If tSegmentOrdinal="" {
			Set tSC=..ParserError("Expected segment ordinal")
			Quit
		}
		
		#; Expecting "///"
		Set tFoundToken=0
		If ..Scanner.CurrentToken=$$$tokSLASH {
			Do ..Scanner.NextToken()
			If ..Scanner.CurrentToken=$$$tokSLASH {
				Do ..Scanner.NextToken()
				If ..Scanner.CurrentToken=$$$tokSLASH {
					Do ..Scanner.NextToken()
					Set tFoundToken=1
				}	
			}
		}
		
		If tFoundToken=0 {
			Set tSC=..ParserError("Expected token ""///""")
			Quit
		}
		Set tItemOrdinal=..Scanner.Integer()
		If tItemOrdinal="" {
			Set tSC=..ParserError("Expected (element/composite) ordinal")
			Quit
		}
		Set tSubElementOrdinal=""
		If ..Scanner.CurrentToken=$$$tokMINUS {
			
			#; Skip '-'
			Do ..Scanner.NextToken()
			
			Set tSubElementOrdinal=..Scanner.Integer()
			If tSubElementOrdinal="" {
				Set tSC=..ParserError("Expected sub-element ordinal")
				Quit
			}
		}
		
		Set pTransactionSet.ID=tID
		Set pTransactionSet.SegmentOrdinal=tSegmentOrdinal
		Set pTransactionSet.ItemOrdinal=tItemOrdinal
		Set pTransactionSet.SubElementOrdinal=tSubElementOrdinal
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// <composite> :- <composite_element_list> [ '+' <syntax_rule> ] [ ',' <mask> ]
Method ParseComposite(pName As %String, pParent As EnsLib.EDI.SEF.SegmentComposite, Output pComposite As EnsLib.EDI.SEF.Composite) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Pick out the specification for this composite
		Set tCompositeSource=$Get(^IRIS.Temp.SEF(..DocKey,"COMS",pName))
		If tCompositeSource="" {
			Set tSC=..ParserError("No definition for Composite "_pName)
			Quit
		}
		Set pComposite=##class(EnsLib.EDI.SEF.Composite).%New()
		$$$ASSERTNOLOG($IsObject(pComposite))
		
		#; Fix up the parent
		Set pComposite.Parent=pParent,pComposite.Name=pName
		
		#; Need a new scanner for the element definiton
		Do ..ScannerStack.Push(..Scanner) 
		
		Set ..Scanner=##class(EnsLib.EDI.SEF.Scanner).%New(tCompositeSource)
		$$$ASSERTNOLOG($IsObject(..Scanner))
		
		#; Initialize composite ordinal, each composite has its own ordinals for
		#; items contained therein
		Set ..ComOrdinal=0
		
		Set tTok=..Scanner.CurrentToken
		While (tTok'=$$$tokEOFL) {
			If tTok=$$$tokLBRACK {
				Set tTok=..Scanner.NextToken(),tUsrRequirement=""
				
				#; RULE: If the SEF file describes a convention (customized for a particular trading relationship) 
				#; rather than a published standard, the .COMS section can include the requirements specified by the
				#; particular convention, as well as the requirements specified by the published standard on which
				#; it is based. This information is indicated by a symbol before the element ID within the square brackets.
				If (tTok=$$$tokDOT||(tTok=$$$tokEXCLA)||(tTok=$$$tokDOLLAR)||(tTok=$$$tokMINUS)||(tTok=$$$tokAMPER)) {
					Set tUsrRequirement=..Scanner.CurrentChar,tTok=..Scanner.NextToken()
				}
				If tTok=$$$tokDIGIT {
					Set tSC=..ParseCompositeElement(tUsrRequirement,pComposite,.tNode)
				} Else {
					Set tSC=..ParserError("Expected element while parsing composite")
				}
				If $$$ISERR(tSC) Quit
			
				#; Add node to composite
				Do pComposite.Elements.Insert(tNode)
			} ElseIf tTok=$$$tokLBRACE {
				Set tSC=..ParseCompositeElementGroup(pComposite,.tNode)
				If $$$ISERR(tSC) Quit
				
				#; Add node to elements
				Do pComposite.Elements.Insert(tNode)
			} ElseIf tTok=$$$tokPLUS {
				#; Parse the relation
				Set tSC=..ParseRelations(pComposite,.tNodeList)
				If $$$ISERR(tSC) Quit
				
				Set pComposite.Relations=tNodeList
			} ElseIf tTok=$$$tokCOMMA {
				#; Parse the mask
				Set tSC=..ParseCompositeMask(pComposite,.tMaskList)
				If $$$ISERR(tSC) Quit
				
				Set pComposite.Masks=tMaskList
			} Else {
				Set tSC=..ParserError("Syntax Error while parsing Composite ")
			}
			
			If $$$ISERR(tSC) Quit
			
			Set tTok=..Scanner.CurrentToken
		}
		
		If $$$ISERR(tSC) Quit
		
		#; Put the old scanner back
		Set ..Scanner=..ScannerStack.Top() Do ..ScannerStack.Pop()
				
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse a composite element
Method ParseCompositeElement(pUsrRequirement As %String, pParent As EnsLib.EDI.SEF.Node, Output pCompositeElement As EnsLib.EDI.SEF.CompositeElement) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokDIGIT)
		
		#; Create an Element
		Set pCompositeElement=##class(EnsLib.EDI.SEF.CompositeElement).%New()
		$$$ASSERTNOLOG($IsObject(pCompositeElement))
		
		#; Fix up the parent
		Set pCompositeElement.Parent=pParent
		
		#; ID
		Set tID=..Scanner.ElementID()
		If tID="" {
			Set tSC=..ParserError("Expected Element ID")
			Quit
		}
		#; Ordinal?
		Set tTok=..Scanner.CurrentToken
		If tTok=$$$tokATSIGN {
			
			#; Skip '@'
			Set tTok=..Scanner.NextToken()
			If tTok=$$$tokDIGIT Set tOrdinal=..Scanner.Integer()
			If tOrdinal="" {
				Set tSC=..ParserError("Element: "_tID_",Expected Ordinal Number")
				Quit
			}
			#; Override the current ordinal
			Set ..ComOrdinal=tOrdinal
			
		} Else {
			
			#; Increment the current ordinal
			Set ..ComOrdinal=..ComOrdinal+1
		}
		Set (tMinLength,tMaxLength)="",tStdRequirement=..DefaultStdRequirement
		
		#; Compound definition?
		Set tTok=..Scanner.CurrentToken
		If tTok'=$$$tokRBRACK {
			
			#; Min/Max Definitions
			If tTok=$$$tokSEMI {
				
				Set tTok=..Scanner.NextToken()
				If tTok=$$$tokDIGIT {
				
					Set tMinLength=..Scanner.Integer()
					If tMinLength="" {
						Set tSC=..ParserError("Expected MinLength while parsing Composite element ")
						Quit
					}
				}
				If tTok=$$$tokCOLON {
					
					#; Skip ':'
					Set tTok=..Scanner.NextToken()
					Set tMaxLength=..Scanner.Integer()
					If tMaxLength="" {
						Set tSC=..ParserError("Expected MaxLength while parsing Composite element ")
						Quit
					}
				} 		
			}
			#; Delimiter
			If tTok'=$$$tokCOMMA {
				Set tSC=..ParserError("Expected Delimiter ','")
				Quit
			} Else {
				Set tTok=..Scanner.NextToken()
			}
			#; Requirement?
			If tTok=$$$tokLETTER {
				
				Set tStdRequirement=..Scanner.CurrentChar
				
				Set tSC=..ValidateSegRequirement(tStdRequirement)
				If $$$ISERR(tSC) Quit
				
				Set tTok=..Scanner.NextToken()
			}
			#; Some SEF Files have an extra , and a digit here. The standard does not
			#; define them, technically its a syntax error but we will accomodate this
			#; anomaly by parsing but not acting upon the token
			If tTok=$$$tokCOMMA {
				
				Set tTok=..Scanner.NextToken()
				If tTok=$$$tokDIGIT {
					Set tTok=..Scanner.NextToken()
				} Else {
					Set tSC=..ParserError("Expected Digit")
				}		
			}
			If tTok'=$$$tokRBRACK {
			
				Set tSC=..ParserError("Expected Delimiter ']'")
				Quit
			}	
		}
		#; Skip ']'
		Do ..Scanner.NextToken()
		
		Set tSC=..ParseElement(tID,pCompositeElement,.tElement)
		If $$$ISERR(tSC) Quit
		
		$$$ASSERTNOLOG($IsObject(tElement))
		
		Set pCompositeElement.ID=tID
		Set pCompositeElement.MinLength=tMinLength
		Set pCompositeElement.MaxLength=tMaxLength
		Set pCompositeElement.Ordinal=..ComOrdinal
		Set pCompositeElement.StdRequirement=tStdRequirement
		Set pCompositeElement.UsrRequirement=pUsrRequirement
		Set pCompositeElement.Element=tElement
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseCompositeElementMask(pParent As EnsLib.EDI.SEF.SegmentMask, Output pElementMask As EnsLib.EDI.SEF.CompositeElementMask) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$ASSERTNOLOG($$$MaskType[("|"_..Scanner.CurrentChar_"|"))
		
		Set pElementMask=##class(EnsLib.EDI.SEF.CompositeElementMask).%New()
		$$$ASSERTNOLOG($IsObject(pElementMask))
		
		#; Fix up parent
		Set pElementMask.Parent=pParent
		
		Set pElementMask.MaskType=..Scanner.CurrentChar
		
		Set tTok=..Scanner.NextToken()
		
		#; Requirement?
		If tTok=$$$tokLETTER {
			
			Set tStdRequirement=..Scanner.CurrentChar
			
			Set tSC=..ValidateSegRequirement(tStdRequirement)
			If $$$ISERR(tSC) Quit
			
			Set pElementMask.StdRequirement=tStdRequirement
			
			#; Skip requirement
			Set tTok=..Scanner.NextToken()
		}
		
		#; Min/Max/Repeat?
		If tTok=$$$tokLBRACK {
			
			Set tTok=..Scanner.NextToken()
			Set tMinLength=..Scanner.Integer()
			
			If tMinLength'="" {
				Set pElementMask.MinLength=tMinLength
				Set tTok=..Scanner.CurrentToken
			}
			
			If tTok=$$$tokCOLON {
			
				Set tTok=..Scanner.NextToken()
				Set tMaxLength=..Scanner.Integer()
				
				If tMaxLength'="" {
					Set pElementMask.MaxLength=tMaxLength
					Set tTok=..Scanner.CurrentToken
				}
				
				If tTok=$$$tokCOLON {
					Set tTok=..Scanner.NextToken()
					Set tRepeatCount=..Scanner.Integer()
					
					If tRepeatCount'="" {
						Set pElementMask.RepeatCount=tRepeatCount
						Set tTok=..Scanner.CurrentToken
					}	
				}
			}
			If tTok'=$$$tokRBRACK {
				
				Set tSC=..ParserError("Expected Delimiter ']'")
				Quit
			}
			
			#; Skip ']'
			Set tTok=..Scanner.NextToken()
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// <composite_group> :- '{' <integer> [ <element>]+ '}'
Method ParseCompositeElementGroup(pParent As EnsLib.EDI.SEF.Composite, Output pGroup As EnsLib.EDI.SEF.CompositeElementGroup) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokLBRACE)
		
		#; Create a group 
		Set pGroup=##class(EnsLib.EDI.SEF.CompositeElementGroup).%New()
		$$$ASSERTNOLOG($IsObject(pGroup))
		
		#; Fix up the parent
		Set pGroup.Parent=pParent
		 
		#; Skip '{'
		Do ..Scanner.NextToken()
		
		#; Get the mandatory repeat count
		Set tRepeatCount=..Scanner.Integer()
		If tRepeatCount="" {
			Set tSC=..ParserError("Expected repeat count while parsing composite element group ")
			Quit
		}
		
		Set pGroup.RepeatCount=tRepeatCount
		
		#; Remember the Ordinal
		Set tComOrdinal=..ComOrdinal
		
		While (..Scanner.CurrentToken=$$$tokLBRACK) {
				
				Set tTok=..Scanner.NextToken(),tUsrRequirement=""
				
				#; RULE: If the SEF file describes a convention (customized for a particular trading relationship) 
				#; rather than a published standard, the .SEGS section can include the requirements specified by the
				#; particular convention, as well as the requirements specified by the published standard on which
				#; it is based. This information is indicated by a symbolbefore the element ID within the square brackets.
				If (tTok=$$$tokDOT||(tTok=$$$tokEXCLA)||(tTok=$$$tokDOLLAR)||(tTok=$$$tokMINUS)||(tTok=$$$tokAMPER)) {
					Set tUsrRequirement=..Scanner.CurrentChar,tTok=..Scanner.NextToken()
				}
	
				If tTok=$$$tokDIGIT {
					Set tSC=..ParseCompositeElement(tUsrRequirement,pGroup,.tNode)
				} Else {
					Set tSC=..ParserError("Expected element while parsing composite element group")
				}
			
			If $$$ISERR(tSC) Quit
			
			Do pGroup.Nodes.Insert(tNode)
		}
		
		If $$$ISERR(tSC) Quit
	
		If ..Scanner.CurrentToken'=$$$tokRBRACE {
			Set tSC=..ParserError("Expected delimiter '}'")
			Quit
		}
		
		#; Skip '}'
		Do ..Scanner.NextToken()
	
		#; Now calculate the new ordinal
		Set ..ComOrdinal=tComOrdinal+((..ComOrdinal-tComOrdinal)*tRepeatCount)
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseCompositeMask(pParent As EnsLib.EDI.SEF.Node, Output pComMaskList As EnsLib.EDI.SEF.CompositeMaskList) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokCOMMA)
		
		#; Create the mask list
		Set pComMaskList=##class(EnsLib.EDI.SEF.CompositeMaskList).%New()
		$$$ASSERTNOLOG($IsObject(pComMaskList))
		
		#; Fix up the parent
		Set pComMaskList.Parent=pParent
		
		#; Parse the mask list
		Do {
			#; Create a new Mask
			Set tMask=##class(EnsLib.EDI.SEF.CompositeMask).%New()
			$$$ASSERTNOLOG($IsObject(tMask))
			
			#; Fix up the parent
			Set tMask.Parent=pComMaskList
			
			#; Skip ','
			Do ..Scanner.NextToken()
		
			while ($$$MaskType[("|"_..Scanner.CurrentChar_"|")) {
				
				Set tSC=..ParseCompositeElementMask(tMask,.tCompositeElementMask)
				If $$$ISERR(tSC) Quit
			
				Do tMask.CompositeElementMasks.Insert(tCompositeElementMask)	
			}
			
			If $$$ISERR(tSC) Quit
			
			Do pComMaskList.Insert(tMask)
			
		} while (..Scanner.CurrentToken=$$$tokCOMMA)
				
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// <element> :- <element_type> ',' <minlength> ',' <maxlength>
Method ParseElement(pElementID As %Integer, pParent As EnsLib.EDI.SEF.Node, Output pElement As EnsLib.EDI.SEF.Element) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		#; First Check to see if this has already been parsed
		Set pElement=..ParsedElements.GetAt(pElementID)
		If $IsObject(pElement) Quit
		
		#; Pick out the specification for this segment
		Set tElementSource=$Get(^IRIS.Temp.SEF(..DocKey,"ELMS",pElementID))
		If tElementSource="" {
			Set tSC=..ParserError("No definition for Element "_pElementID)
			Quit
		}
		
		Set pElement=##class(EnsLib.EDI.SEF.Element).%New()
		$$$ASSERTNOLOG($IsObject(pElement))
		
		#; Fix up the parent
		Set pElement.Parent=pParent
		
		#; Need a new scanner for the element definiton
		Do ..ScannerStack.Push(..Scanner) 
		
		Set ..Scanner=##class(EnsLib.EDI.SEF.Scanner).%New(tElementSource)
		$$$ASSERTNOLOG($IsObject(..Scanner))
		
		#; RULE: Element definitions consists of:-
		#; The type: R, ID, AN, A, DT, TM, B, N, N0, N1 - N9.
		#; The minimum length.
		#; The maximum length. If max length is specified as 0 it is understood 
		#; to mean not applicable, or no limit.
		Set tType=..Scanner.Identifier()
		If "|R|ID|AN|A|DT|TM|B|N|N0|N1|N2|N3|N4|N9|N6|N7|N8|N9|"'[("|"_tType_"|") {
			Set tSC=..ParserError("Unrecognized Element Type")
			Quit
		}
		
		If ..Scanner.CurrentToken'=$$$tokCOMMA {
			Set tSC=..ParserError("Expected Delimiter ','")
			Quit
		} Else {
			
			#; Skip ','
			Do ..Scanner.NextToken()
		}
		
		Set tMinLength=..Scanner.Integer()
		If tMinLength="" {
			Set tSC=..ParserError("Expected MinLength")
			Quit
		}
		
		If ..Scanner.CurrentToken'=$$$tokCOMMA {
			Set tSC=..ParserError("Expected Delimiter ','")
			Quit
		} Else {
			
			#; Skip ','
			Do ..Scanner.NextToken()
		}
		
		Set tMaxLength=..Scanner.Integer()
		If tMaxLength="" {
			Set tSC=..ParserError("Expected MinLength")
			Quit
		}
		
		If $Data(^IRIS.Temp.SEF(..DocKey,"CODES",pElementID))#2 {
			Set tSC=..ParseCodes(pElementID,pElement,.tCodes)
			If $$$ISERR(tSC) Quit
			
			Set pElement.Codes=tCodes
		}
		
		Set pElement.ID=pElementID,pElement.Type=tType,pElement.MinLength=tMinLength,pElement.MaxLength=tMaxLength
		
		#; Put the old scanner back
		Set ..Scanner=..ScannerStack.Top() Do ..ScannerStack.Pop()
				
		Do ..ParsedElements.SetAt(pElement,pElementID)
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseCodes(pElementID, pParent, Output pCodes As EnsLib.EDI.SEF.Codes)
{
	Set $ZT="Trap",tSC=$$$OK
	Do {

		#; Create a Codes node
		Set pCodes=##class(EnsLib.EDI.SEF.Codes).%New()
		$$$ASSERTNOLOG($IsObject(pCodes))
		
		#; Fix up the parent
		Set pCodes.Parent=pParent
		
		#; Pick out the specification for this element
		Set tCodesSource=$Get(^IRIS.Temp.SEF(..DocKey,"CODES",pElementID))
		If tCodesSource="" {
			Set tSC=..ParserError("No CODES definition for Element "_pElementID)
			Quit
		}
		
		#; Need a new scanner for the codes definiton
		Do ..ScannerStack.Push(..Scanner) 
		
		Set ..Scanner=##class(EnsLib.EDI.SEF.Scanner).%New(tCodesSource)
		$$$ASSERTNOLOG($IsObject(..Scanner))

		#; Create NodeList for Dictionary code definitions (Code/CodeRange)
		Set tDictionaryCodes=##class(EnsLib.EDI.SEF.NodeList).%New()
		$$$ASSERTNOLOG($IsObject(tDictionaryCodes))
		
		Set tCodeSets=##class(EnsLib.EDI.SEF.CodeSetList).%New()
		$$$ASSERTNOLOG($IsObject(tCodeSets))
	
		#; Parse the list of codes
		while ..Scanner.CurrentToken=$$$tokDIGIT||(..Scanner.CurrentToken=$$$tokLETTER) {
			
			Set tSC=..ParseCode(tDictionaryCodes,.tCode)
			If $$$ISERR(tSC) Quit
			
			If (tCode.%IsA("EnsLib.EDI.SEF.CodeRange")) {
				
				#; If its a code range, put it in the dictionary codes list
				Do tDictionaryCodes.Insert(tCode)
			} Else {

				#; Otherwise we can't afford the cost of a code object here
				#; so just stash the value in the codes array				
				Set pCodes.DictionaryCodes(tCode.Value)=""
				Kill tCode 
			}
			
			If ..Scanner.CurrentToken'=$$$tokVBAR&&(..Scanner.CurrentToken'=$$$tokCOMMA) Quit
			
			#; Skip '|' or ','
			Do ..Scanner.NextToken()
		}
		
		If $$$ISERR(tSC) Quit

		// Subset defined?		
		If ..Scanner.CurrentToken=$$$tokPERCENT {
			#; Skip '%'
			Do ..Scanner.NextToken()
			
			If ..Scanner.CurrentToken'=$$$tokLBRACK {
				Set tSC=..ParserError("Expecting Delimiter '['")
				Quit
			}
			
			Set tPosition=0
			Do {
				#; Parse the code set
				Set tSC=..ParseCodeSet(pCodes,.tCodeSet)
				If $$$ISERR(tSC) Quit
				
				#; Set its position
				Set tCodeSet.Position=$Increment(tPosition)
				
				#; put it in the list
				Do tCodeSets.Insert(tCodeSet)
				
			} while (..Scanner.CurrentToken=$$$tokLBRACK)
		}
		
		Set pCodes.ElementID=pElementID,pCodes.Dictionary=tDictionaryCodes,pCodes.CodeSets=tCodeSets
		
		#; Put the old scanner back
		Set ..Scanner=..ScannerStack.Top() Do ..ScannerStack.Pop()
				
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseCode(pParent As EnsLib.EDI.SEF.Node, Output pNode As EnsLib.EDI.SEF.Node)
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokDIGIT||(..Scanner.CurrentToken=$$$tokLETTER))
		
		Set tValue=..Scanner.CodeName()
		If tValue="" {
			Set tSC=..ParserError("Expected Code")
			Quit
		}
				
		If ..Scanner.CurrentToken=$$$tokCOLON {
		
			#; Skip ':'
			Do ..Scanner.NextToken()
				
			#; It's a Range
			Set tRangeEnd=..Scanner.CodeName()
			If tRangeEnd="" {
				Set tSC=..ParserError("Expected Code")
				Quit
			}
			
			#; Create a range
			Set pNode=##class(EnsLib.EDI.SEF.CodeRange).%New()
			$$$ASSERTNOLOG($IsObject(pNode))
			
			#; Fix up parent
			Set pNode.Parent=pParent
			
			Set pNode.RangeStart=tValue,pNode.RangeEnd=tRangeEnd
		
		} Else {
			
			#; Create a code
			Set pNode=##class(EnsLib.EDI.SEF.Code).%New()
			$$$ASSERTNOLOG($IsObject(pNode))
			
			#; Fix up parent
			Set pNode.Parent=pParent
			
			Set pNode.Value=tValue
		}
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSegmentComposite(pUsrRequirement As %String, pParent As EnsLib.EDI.SEF.Node, Output pSegmentComposite As EnsLib.EDI.SEF.SegmentComposite) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {

		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokLETTER)
		
		#; Create a Composite
		Set pSegmentComposite=##class(EnsLib.EDI.SEF.SegmentComposite).%New()
		$$$ASSERTNOLOG($IsObject(pSegmentComposite))
		
		#; Fix up the parent
		Set pSegmentComposite.Parent=pParent
		
		#; Name
		Set tName=..Scanner.CompositeName()
		If tName="" {
			Set tSC=..ParserError("Expected composite name")
			Quit
		}
		
		#; Set default requirement,repeat count and ordinal spec
		Set tStdRequirement=..DefaultStdRequirement,tRepeatCount=1,tOrdinalSpec=""
		
		Set tTok=..Scanner.CurrentToken
		If tTok=$$$tokATSIGN {
		
			#; Skip '@'
			Set tTok=..Scanner.NextToken()
			If tTok=$$$tokDIGIT Set tOrdinalSpec=..Scanner.Integer()
			If tOrdinalSpec="" {
				Set tSC=..ParserError("Composite: "_tName_",Expected Ordinal Number")
				Quit
			}
		
			#; Override the current ordinal
			Set ..SegOrdinal=tOrdinalSpec
			
		} Else {
			
			#; Increment the current ordinal
			Set ..SegOrdinal=..SegOrdinal+1
		}
		
		If ..Scanner.CurrentToken=$$$tokCOMMA {
			
			Set tTok=..Scanner.NextToken()
			
			#; Requirement?
			If tTok=$$$tokLETTER {
				Set tStdRequirement=..Scanner.CurrentChar
				
				Set tSC=..ValidateSegRequirement(tStdRequirement)
				If $$$ISERR(tSC) Quit
				
				Set tTok=..Scanner.NextToken()
			}
			
			If tTok'=$$$tokRBRACK {
				
				#; Delimiter
				If tTok'=$$$tokCOMMA {
					Set tSC=..ParserError("Expected Delimiter ','")
					Quit
				} Else {
					Set tTok=..Scanner.NextToken()
				}
				
				Set tCount=..Scanner.Count()
				If tCount'="" {
					Set tRepeatCount=tCount
				} Else {
					Set tSC=..ParserError("Expected Count")
					Quit
				}
				
				#; Establish current token
				Set tTok=..Scanner.CurrentToken
			}
			
			If tTok'=$$$tokRBRACK {
				Set tSC=..ParserError("Expected Delimiter ']'")
				Quit
			}	
		}
		
		#; Skip ']'
		Do ..Scanner.NextToken()
		Set tSC=..ParseComposite(tName,pSegmentComposite,.tComposite)
		If $$$ISERR(tSC) Quit
		
		$$$ASSERTNOLOG($IsObject(tComposite))
		
		Set pSegmentComposite.Name=tName
		Set pSegmentComposite.StdRequirement=tStdRequirement
		Set pSegmentComposite.RepeatCount=tRepeatCount
		Set pSegmentComposite.UsrRequirement=pUsrRequirement
		Set pSegmentComposite.Composite=tComposite
		Set pSegmentComposite.Ordinal=..SegOrdinal
		Set pSegmentComposite.OrdinalSpec=tOrdinalSpec
				
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseDependencyNote(pParent As EnsLib.EDI.SEF.Segment, Output pNote As EnsLib.EDI.SEF.DependencyNote) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
				
		$$$ASSERTNOLOG(..Scanner.CurrentChar="D")
		
		#; Create a Note
		Set tNote=##class(EnsLib.EDI.SEF.DependencyNote).%New()
		$$$ASSERTNOLOG($IsObject(tNote))
		
		#; Fix up Parent
		Set tNote.Parent=pParent
		
		Set tTok=..Scanner.NextToken()
		If tTok=$$$tokDIGIT {
			Set tNode.DependencyType=..Scanner.CurrentChar
		}
		
		Set tTok=..Scanner.NextToken()
		If tTok'=$$$tokLPARN {
			Set tSC=..ParserError("Expected delimiter '('")
			Quit
		}
		
		Set tOperands=""
		
		Set tTok=..Scanner.NextToken()
		While (tTok'=$$$tokRPARN) {
			Set tValue=""
			While (tTok=$$$tokDIGIT) {
				Set tValue=tValue_..Scanner.CurrentChar
				Set tTok=..Scanner.NextToken()
			}
			
			If tValue=""||($Length(tValue'=3)) {
				Set tSC=..ParserError("Expected numeric item")
				Quit
			}
			
			Set tOperands=tOperands_tValue_","
			
			If tTok=$$$tokCOMMA {
				
				#; Skip ','
				Set tTok=..Scanner.NextToken()
			}
		}
		
		If $$$ISERR(tSC) Quit
		
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokRPARN)
		
		#; Skip ')'
		Do ..Scanner.NextToken()
		
		#; Remove trailing comma
		Set $Extract(tOperands,$Length(tOperands))=""
		
		Set tNode.Operands=tOperands
				
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSegmentElement(pUsrRequirement As %String, pParent As EnsLib.EDI.SEF.Node, Output pSegmentElement As EnsLib.EDI.SEF.SegmentElement) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		#; Create an Element
		Set pSegmentElement=##class(EnsLib.EDI.SEF.SegmentElement).%New()
		$$$ASSERTNOLOG($IsObject(pSegmentElement))
		
		#; Fix up the parent
		Set pSegmentElement.Parent=pParent
		
		#; ID
		Set tID=..Scanner.ElementID()
		If tID="" {
			Set tSC=..ParserError("Expected Element ID")
			Quit
		}
		
		#; Ordinal?
		Set tTok=..Scanner.CurrentToken
		If tTok=$$$tokATSIGN {
			
			#; Skip '@'
			Set tTok=..Scanner.NextToken()
			If tTok=$$$tokDIGIT Set tOrdinal=..Scanner.Integer()
			If tOrdinal="" {
				Set tSC=..ParserError("Element: "_tID_",Expected Ordinal Number")
				Quit
			}
			
			#; Override the current ordinal
			Set ..SegOrdinal=tOrdinal
			
		} Else {
			
			#; Increment the current ordinal
			Set ..SegOrdinal=..SegOrdinal+1
		}
		
		#; Set defaults
		Set (tMinLength,tMaxLength)="",tRepeatCount=1,tStdRequirement=..DefaultStdRequirement
		
		#; Compound definition?
		Set tTok=..Scanner.CurrentToken
		If tTok'=$$$tokRBRACK {
			
			#; Min/Max Definitions
			If tTok=$$$tokSEMI {
				
				Set tTok=..Scanner.NextToken()
				If tTok=$$$tokDIGIT {
				
					Set tMinLength=..Scanner.Integer()
					If tMinLength="" {
						Set tSC=..ParserError("Expected MinLength while parsing segment element ")
						Quit
					}
				}
					
				If tTok=$$$tokCOLON {
					
					#; Skip ':'
					Set tTok=..Scanner.NextToken()
					Set tMaxLength=..Scanner.Integer()
					If tMaxLength="" {
						Set tSC=..ParserError("Expected MaxLength while parsing segment element ")
						Quit
					}
				} 		
			}
			
			#; Delimiter
			If tTok'=$$$tokCOMMA {
				Set tSC=..ParserError("Expected Delimiter ','")
				Quit
			} Else {
				Set tTok=..Scanner.NextToken()
			}
			
			#; Requirement?
			If tTok=$$$tokLETTER {
				
				Set tStdRequirement=..Scanner.CurrentChar
				
				Set tSC=..ValidateSegRequirement(tStdRequirement)
				If $$$ISERR(tSC) Quit
				
				Set tTok=..Scanner.NextToken()
			}
			
			If tTok'=$$$tokRBRACK {
				
				#; Delimiter
				If tTok'=$$$tokCOMMA {
					Set tSC=..ParserError("Expected Delimiter ','")
					Quit
				} Else {
					Set tTok=..Scanner.NextToken()
				}
				
				Set tCount=..Scanner.Count()
				If tCount'="" {
					Set tRepeatCount=tCount
				} Else {
					Set tSC=..ParserError("Expected Count")
					Quit
				}
				
				#; Establish current token
				Set tTok=..Scanner.CurrentToken
			}
			
			If tTok'=$$$tokRBRACK {
				Set tSC=..ParserError("Expected Delimiter ']'")
				Quit
			}	
		}
		
		#; Skip ']'
		Do ..Scanner.NextToken()
		
		Set tSC=..ParseElement(tID,pSegmentElement,.tElement)
		If $$$ISERR(tSC) Quit
		
		$$$ASSERTNOLOG($IsObject(tElement))
		
		Set pSegmentElement.ID=tID
		Set pSegmentElement.MinLength=tMinLength
		Set pSegmentElement.MaxLength=tMaxLength
		Set pSegmentElement.Ordinal=..SegOrdinal
		Set pSegmentElement.StdRequirement=tStdRequirement		
		Set pSegmentElement.UsrRequirement=pUsrRequirement
		Set pSegmentElement.RepeatCount=tRepeatCount
		Set pSegmentElement.Element=tElement
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSegmentItemMask(pParent As EnsLib.EDI.SEF.SegmentMask, Output pItemMask As EnsLib.EDI.SEF.SegmentItemMask) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		$$$ASSERTNOLOG($$$MaskType[("|"_..Scanner.CurrentChar_"|"))
		
		Set pItemMask=##class(EnsLib.EDI.SEF.SegmentItemMask).%New()
		$$$ASSERTNOLOG($IsObject(pItemMask))
		
		#; Fix up parent
		Set pItemMask.Parent=pParent
		
		Set pItemMask.MaskType=..Scanner.CurrentChar
		
		Set tTok=..Scanner.NextToken()
	
		#; Requirement?
		If tTok=$$$tokLETTER {
			
			Set tSC=..ValidateSegRequirement(..Scanner.CurrentChar)
			If $$$ISERR(tSC) Quit
			
			Set pItemMask.StdRequirement=..Scanner.CurrentChar
			
			#; Skip requirement
			Set tTok=..Scanner.NextToken()
		}
		
		#; Min/Max/Repeat?
		If tTok=$$$tokLBRACK {
			
			Set tTok=..Scanner.NextToken()
			Set tMinLength=..Scanner.Integer()
			
			If tMinLength'="" {
				Set pItemMask.MinLength=tMinLength
				Set tTok=..Scanner.CurrentToken
			}
			
			If tTok=$$$tokCOLON {
			
				Set tTok=..Scanner.NextToken()
				Set tMaxLength=..Scanner.Integer()
				
				If tMaxLength'="" {
					Set pItemMask.MaxLength=tMaxLength
					Set tTok=..Scanner.CurrentToken
				}
				
				If tTok=$$$tokCOLON {
					Set tTok=..Scanner.NextToken()
					Set tRepeatCount=..Scanner.Integer()
					
					If tRepeatCount'="" {
						Set pItemMask.RepeatCount=tRepeatCount
						Set tTok=..Scanner.CurrentToken
					}
				}
				
			}
			
			If tTok'=$$$tokRBRACK {
				
				Set tSC=..ParserError("Expected Delimiter ']'")
				Quit
			}
			
			#; Skip ']'
			Set tTok=..Scanner.NextToken()
		}
			
		#; Composite Mask Type?
		If ..Scanner.CurrentToken=$$$tokASTER {
	
			#; Skip '*'
			Set tTok=..Scanner.NextToken()
			
			Set tCompositeMaskIndex=..Scanner.Integer()
			If tCompositeMaskIndex="" {
				Set tSC=..ParserError("Expected composite mask index number")
				Quit
			}
			
			Set pItemMask.CompositeMaskIndex=tCompositeMaskIndex	
		}
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSegmentMask(pParent As EnsLib.EDI.SEF.Node, Output pSegMaskList As EnsLib.EDI.SEF.SegmentMaskList) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokCOMMA)
		
		#; Create the mask list
		Set pSegMaskList=##class(EnsLib.EDI.SEF.SegmentMaskList).%New()
		$$$ASSERTNOLOG($IsObject(pSegMaskList))
		
		#; Fix up the parent
		Set pSegMaskList.Parent=pParent
		
		#; Parse the mask list
		Do {
			#; Create a new Mask
			Set tMask=##class(EnsLib.EDI.SEF.SegmentMask).%New()
			$$$ASSERTNOLOG($IsObject(tMask))
			
			#; Fix up the parent
			Set tMask.Parent=pSegMaskList
			
			#; Skip ','
			Do ..Scanner.NextToken()
		
			while ($$$MaskType[("|"_..Scanner.CurrentChar_"|")) {
				
				Set tSC=..ParseSegmentItemMask(tMask,.tItemMask)
				If $$$ISERR(tSC) Quit
			
				Do tMask.ItemMasks.Insert(tItemMask)	
			}
			
			If $$$ISERR(tSC) Quit
			
			Do pSegMaskList.Insert(tMask)
			
		} while (..Scanner.CurrentToken=$$$tokCOMMA)
				
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Element relations may be X12 SyntaxRules or EDIFACT Dependency Notes
Method ParseRelations(pParent As EnsLib.EDI.SEF.Node, Output pNodeList As EnsLib.EDI.SEF.NodeList) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
	
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokPLUS)
		
		Set pNodeList=##class(EnsLib.EDI.SEF.NodeList).%New()
		$$$ASSERTNOLOG($IsObject(pNodeList))
		
		Set tTok=..Scanner.NextToken()
		If tTok'=$$$tokLETTER {
			Set tSC=..ParserError("Expected Letter")
			Quit
		}
		
		If ..Scanner.CurrentChar="D" {
			
			#; EDIFACT
			While (..Scanner.CurrentChar="D")
	        {
				Set tSC=..ParseDependencyNote(pParent,.tNote)
				If $$$ISERR(tSC) Quit
				
				Do pNodeList.Insert(tNote)
			}
			
		} ElseIf "|R|C|E|L|P|"[("|"_..Scanner.CurrentChar_"|") {
			
			#; X12
			While "|R|C|E|L|P|"[("|"_..Scanner.CurrentChar_"|") {
				
				Set tSC=..ParseSyntaxRule(pParent,.tRule)
				If $$$ISERR(tSC) Quit
				
				Do pNodeList.Insert(tRule)
			}
			
		} Else {
			Set tSC=..ParserError("Invalid Syntax Rule or Dependency Note introducer")
			Quit
		}
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSegmentItemGroup(pParent As EnsLib.EDI.SEF.Segment, Output pGroup As EnsLib.EDI.SEF.SegmentItemGroup) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokLBRACE)
		
		#; Create a group 
		Set pGroup=##class(EnsLib.EDI.SEF.SegmentItemGroup).%New()
		$$$ASSERTNOLOG($IsObject(pGroup))
		
		#; Fix up the parent
		Set pGroup.Parent=pParent
		 
		#; Skip '{'
		Do ..Scanner.NextToken()
		
		#; Get the mandatory repeat count
		Set tRepeatCount=..Scanner.Integer()
		If tRepeatCount="" {
			Set tSC=..ParserError("Expected repeat count while parsing segment group ")
			Quit
		}
		
		#; Remember the Segment Ordinal
		Set tSegOrdinal=..SegOrdinal
		
		Set pGroup.RepeatCount=tRepeatCount
		
		Set tTok=..Scanner.CurrentToken
		
		While ((tTok=$$$tokLBRACK)||(tTok=$$$tokLBRACE)) {
				
			If tTok=$$$tokLBRACK {
				
				Set tTok=..Scanner.NextToken(),tUsrRequirement=""
				If (tTok=$$$tokDOT||(tTok=$$$tokEXCLA)||(tTok=$$$tokDOLLAR)||(tTok=$$$tokMINUS)||(tTok=$$$tokAMPER)) {
					Set tUsrRequirement=..Scanner.CurrentChar,tTok=..Scanner.NextToken()
				}
				If tTok=$$$tokDIGIT||(tTok=$$$tokLETTER) {
					If ..Scanner.CurrentChar="C"||(..Scanner.CurrentChar="S") {
						#; Composites always begin with 'C' or 'S'
						Set tSC=..ParseSegmentComposite(tUsrRequirement,pGroup,.tNode)
					} Else {
						Set tSC=..ParseSegmentElement(tUsrRequirement,pGroup,.tNode)
					}
				} Else {
					Set tSC=..ParserError("Expected element or composite while parsing Segment ")
				}
			} Else {
				#; Nested SegmentItemGroup
				Set tSC=..ParseSegmentItemGroup(pGroup,.tNode)
			}
			If $$$ISERR(tSC) Quit
			
			Do pGroup.Nodes.Insert(tNode)
			
			#; Restablish current token
			Set tTok=..Scanner.CurrentToken
		}
		If $$$ISERR(tSC) Quit
	
		If ..Scanner.CurrentToken'=$$$tokRBRACE {
			Set tSC=..ParserError("Expected delimiter '}'")
			Quit
		}
		#; Skip '}'
		Do ..Scanner.NextToken()
				
		#; Now calculate the new ordinal
		Set ..SegOrdinal=tSegOrdinal+((..SegOrdinal-tSegOrdinal)*tRepeatCount)
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSegment(pSegmentName As %String, pParent As EnsLib.EDI.SEF.Node, Output pSegment As EnsLib.EDI.SEF.Segment) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; First Check to see if this has already been parsed
		Set pSegment=..ParsedSegments.GetAt(pSegmentName)
		If $IsObject(pSegment) Quit
		
		#; Initialize ordinal, each segment has its own ordinals for contained items
		Set ..SegOrdinal=0
		
		#; Create a Segment  
		Set pSegment=##class(EnsLib.EDI.SEF.Segment).%New()
		$$$ASSERTNOLOG($IsObject(pSegment))
		
		#; Fix up the parent
		Set pSegment.Parent=pParent
		
		#; Set the name
		Set pSegment.Name=pSegmentName
		
		#; Pick out the specification for this segment
		Set tSegmentSource=$Get(^IRIS.Temp.SEF(..DocKey,"SEGS",pSegmentName))
		If tSegmentSource="" {
			Set tSC=..ParserError("No definition for Segment "_pSegmentName)
			Quit
		}
		#; Push the old scanner
		Do ..ScannerStack.Push(..Scanner) 
		
		#; Need a new scanner for this segment definition
		Set ..Scanner=##class(EnsLib.EDI.SEF.Scanner).%New(tSegmentSource)
		$$$ASSERTNOLOG($IsObject(..Scanner))
		
		Set tTok=..Scanner.CurrentToken
		While (tTok'=$$$tokEOFL) {
			If tTok=$$$tokLBRACK {
				Set tTok=..Scanner.NextToken(),tUsrRequirement=""
				
				#; RULE: If the SEF file describes a convention (customized for a particular trading relationship) 
				#; rather than a published standard, the .SEGS section can include the requirements specified by the
				#; particular convention, as well as the requirements specified by the published standard on which
				#; it is based. This information is indicated by a symbolbefore the element ID within the square brackets
				#; and is known as the user requirement
				If (tTok=$$$tokDOT||(tTok=$$$tokEXCLA)||(tTok=$$$tokDOLLAR)||(tTok=$$$tokMINUS)||(tTok=$$$tokAMPER)) {
					Set tUsrRequirement=..Scanner.CurrentChar,tTok=..Scanner.NextToken()
				}
				If tTok=$$$tokDIGIT||(tTok=$$$tokLETTER) {
					If ..Scanner.CurrentChar="C"||(..Scanner.CurrentChar="S") {
						#; Composites always begin with 'C' or 'S'
						Set tSC=..ParseSegmentComposite(tUsrRequirement,pSegment,.tNode)
					} Else {
						Set tSC=..ParseSegmentElement(tUsrRequirement,pSegment,.tNode)
					}
				} Else {
					Set tSC=..ParserError("Expected element or composite while parsing Segment ")
				}
				If $$$ISERR(tSC) Quit
			
				#; Add node to segment
				Do pSegment.Nodes.Insert(tNode)
			} ElseIf tTok=$$$tokLBRACE {
				#; Group
				Set tSC=..ParseSegmentItemGroup(pSegment,.tNode)
				If $$$ISERR(tSC) Quit
				
				#; Add node to segment
				Do pSegment.Nodes.Insert(tNode)
			} ElseIf tTok=$$$tokPLUS {
				#; Parse the relation
				Set tSC=..ParseRelations(pSegment,.tNodeList)
				If $$$ISERR(tSC) Quit
				
				Set pSegment.Relations=tNodeList
			} ElseIf tTok=$$$tokCOMMA {
				#; Parse the mask
				Set tSC=..ParseSegmentMask(pSegment,.tMaskList)
				If $$$ISERR(tSC) Quit
				
				Set pSegment.Masks=tMaskList
			} Else {
				Set tSC=..ParserError("Syntax Error while parsing Segment ")
			}
			If $$$ISERR(tSC) Quit
			
			Set tTok=..Scanner.CurrentToken
		}
		If $$$ISERR(tSC) Quit
		
		Do ..ParsedSegments.SetAt(pSegment,pSegmentName)
		
		#; Put the old scanner back
		Set ..Scanner=..ScannerStack.Top() Do ..ScannerStack.Pop()
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSetItemGroup(pParent As EnsLib.EDI.SEF.Node, Output pGroup As EnsLib.EDI.SEF.SetItemGroup, pPositionModifier As %Integer = "") As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokLBRACE||(..Scanner.CurrentToken=$$$tokATSIGN))
		#; Create a SetItemGroup to hold the components
		Set pGroup=##class(EnsLib.EDI.SEF.SetItemGroup).%New()
		$$$ASSERTNOLOG($IsObject(pGroup))
		
		#; Fix up the parent
		Set pGroup.Parent=pParent
		
		#; Initialize property defaults
		Set tRepeatCount=1,(tName,tOrdinal,tOrdinalSpec,tPosition)="",tPositionModifier=pPositionModifier
		
		#; EDIFACT group ordinal specification?
		If ","_..STD_","[",LS," {
			Set tPosition=..SetPosition
			
			#; In EDIFACT groups participate in the Ordinal numbering
			#; of the SET  components	
			If ..Scanner.CurrentToken=$$$tokATSIGN {
				#; Skip '@'
				Do ..Scanner.NextToken()
				
				Set tOrdinalSpec=..Scanner.Integer()
				If tOrdinalSpec="" {
					Set tSC=..ParserError("Expected Integer")
					Quit
				}
				Set ..SetOrdinal=tOrdinalSpec
			} Else {
				Set ..SetOrdinal=..SetOrdinal+1
			}
			Set tOrdinal=..SetOrdinal
		}
		#; Skip '{'
		Set tTok=..Scanner.NextToken()
		
		#; Identifier?
		If tTok=$$$tokLETTER||(tTok=$$$tokDIGIT) {
			Set tName=..Scanner.GroupName()
			If tName="" {
				Set tSC=..ParserError("Expected name while parsing Set Group")
				Quit
			}
		}
		Set tTok=..Scanner.CurrentToken
		If tTok=$$$tokCOLON {
			
			#; Skip ':'
			Do ..Scanner.NextToken()
			
			Set tCount=..Scanner.Count()
			If tCount'="" {
				Set tRepeatCount=tCount
			} Else {
				Set tSC=..ParserError("Expected repeat count while parsing Set Group")
				Quit
			}
		}
		#; First segment is trigger 
		Set tTok=..Scanner.CurrentToken
		if tTok=$$$tokLBRACK||(tTok=$$$tokPLUS)||(tTok=$$$tokMINUS) {
			Set tSC=..ParseSetSegment(1,pGroup,.tTriggerSegment)
		} Else {
			Set tSC=..ParserError("Syntax Error - Expected segment  while parsing Set Group")
		}	
		If $$$ISERR(tSC) Quit

		#; Fill in the parsed details
		$$$ASSERTNOLOG($IsObject(tTriggerSegment))
		Set pGroup.Name=tName
		Set pGroup.TriggerSegment=tTriggerSegment
		Set pGroup.RepeatCount=tRepeatCount
		Set pGroup.Ordinal=tOrdinal
		Set pGroup.OrdinalSpec=tOrdinalSpec
		Set pGroup.Position=tPosition
		Set pGroup.PositionModifier=tPositionModifier
		
		#; Now parse the members of the group
		Set tTok=..Scanner.CurrentToken
		While (tTok'=$$$tokRBRACE) {
			If tTok=$$$tokLBRACK||(tTok=$$$tokPLUS)||(tTok=$$$tokMINUS) {
				Set tSC=..ParseSetSegment(0,pGroup,.tNode)
			} ElseIf tTok=$$$tokLBRACE||(tTok=$$$tokATSIGN) {
				Set tSC=..ParseSetItemGroup(pGroup,.tNode)
			} Else {
				Set tSC=..ParserError("Syntax Error - Expected Group or Segment ")
			}
			
			If $$$ISERR(tSC) Quit
	
			#; OK
			Do pGroup.Nodes.Insert(tNode)
			
			#; Move on
			Set tTok=..Scanner.CurrentToken
		}
		
		If $$$ISERR(tSC) Quit
		
		$$$ASSERTNOLOG(tTok=$$$tokRBRACE)
		
		#; Skip '}'
		Do ..Scanner.NextToken()
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse a single set, e.g for ASCX12 this could be 835
Method ParseSet(pSetName As %String, pParent As EnsLib.EDI.SEF.Node, Output pSet As EnsLib.EDI.SEF.Set) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set ..SetOrdinal=0,..SetPosition=0,..SetIncrement=10,..TableCounter=0
		
		#; Lets assume that this is never >32k
		Set tSetSource=^IRIS.Temp.SEF(..DocKey,"SETS",pSetName)
			
		#; Initialize the scanner with the SET specification
		Set ..Scanner=##class(EnsLib.EDI.SEF.Scanner).%New(tSetSource)
		$$$ASSERTNOLOG($IsObject(..Scanner))
		
		#; Create a Set
		Set pSet=##class(EnsLib.EDI.SEF.Set).%New()
		$$$ASSERTNOLOG($IsObject(pSet))
		
		#; Fix up the parent and name
		Set pSet.Parent=pParent, pSet.Name=pSetName
		
		#; Sets can consist of Tables, SetSegments and SetGroups
		Set tTok=..Scanner.CurrentToken
		While (tTok'=$$$tokEOFL) {
			Set tSC=$Case(tTok
				,$$$tokARROW: ..ParseTable(pSet,.tNode)
				,$$$tokLBRACK:..ParseSetSegment(0,pSet,.tNode)
				,$$$tokPLUS:  ..ParseSetSegment(0,pSet,.tNode)
				,$$$tokMINUS: ..ParseSetSegment(0,pSet,.tNode)
				,$$$tokLBRACE:..ParseSetItemGroup(pSet,.tNode)
				,$$$tokATSIGN:..ParseSetItemGroup(pSet,.tNode)
				,:..ParserError("Syntax Error in Set "))
			Quit:$$$ISERR(tSC)
				
			#; OK, add the individual node to the Transaction Set
			Do pSet.Nodes.Insert(.tNode)
			
			#; Move on
			Set tTok=..Scanner.CurrentToken
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse a segment. The loop trigger tells us whether this segment 
/// is a loop, i.e the first segment in a loop. There is special processing for 
/// loop triggers
Method ParseSetSegment(pGroupTrigger As %Boolean, pParent As EnsLib.EDI.SEF.Node, Output pSetSegDef As EnsLib.EDI.SEF.Segment) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		Set tTok=..Scanner.CurrentToken
		$$$ASSERTNOLOG(tTok=$$$tokLBRACK||(tTok=$$$tokPLUS)||(tTok=$$$tokMINUS))
	
		#; Initialize defaults
		Set tPositionModifer=""
	
		If tTok=$$$tokPLUS||(tTok=$$$tokMINUS) {
			
			Set tNegate=(tTok=$$$tokMINUS)
			
			#; Skip {'+'|'-'}
			Do ..Scanner.NextToken()
			Set tCount=..Scanner.Integer()
			If tCount="" {
				Set tSC=..ParserError("Expected Integer")
				Quit
			}
			If tNegate {
				Set (..SetIncrement,tPositionModifier)=-tCount
			} Else {
				Set (..SetIncrement,tPositionModifier)=+tCount
			}
		}
		Set ..SetPosition=..SetPosition+..SetIncrement

		Set tTok=..Scanner.CurrentToken
		If (tTok=$$$tokLBRACE||(tTok=$$$tokATSIGN)) {
			#; ? Should only see this in a EDIFACT / Later X12 spec
			//$$$ASSERTNOLOG(","_..STD_","[",LS,")
			
			#; It's really a SetItemGroup
			Set tSC=..ParseSetItemGroup(pParent,.pSetSegDef,tPositionModifer)
			Quit
		}
		#; Create a new Segment
		Set pSetSegDef=##class(EnsLib.EDI.SEF.SetSegment).%New()
		$$$ASSERTNOLOG($IsObject(pSetSegDef))
		
		#; Fix up the parent
		Set pSetSegDef.Parent=pParent
		
		#; Set defaults
		Set tStdRequirement=..DefaultStdRequirement,tRepeatCount=1
			
		#; Initialize other properties
		Set (tName,tUsrRequirement,tMask,tPositionModifier,tOrdinalSpec)=""
		
		#; Skip '[' | '+' | '-'
		Set tTok=..Scanner.NextToken()
		
		#; User requirement?
		If (tTok=$$$tokDOT||(tTok=$$$tokEXCLA)||(tTok=$$$tokDOLLAR)||(tTok=$$$tokMINUS)||(tTok=$$$tokAMPER)) {
			Set tUsrRequirement=..Scanner.CurrentChar,tTok=..Scanner.NextToken()
		}
		#; Name
		Set tName=..Scanner.SegmentName()
		If tName="" {
			Set tSC=..ParserError("Expected Segment Name")
			Quit
		}
		#; Mask?
		Set tTok=..Scanner.CurrentToken
		If tTok=$$$tokASTER {
			#; Skip '*'
			Set tTok=..Scanner.NextToken()
			If tTok=$$$tokDIGIT Set tMask=..Scanner.Integer()
			If tMask="" {
				Set tSC=..ParserError("Segment: "_tName_", Expected Mask Number (Integer)")
				Quit
			}
		}
		#; Ordinal?
		Set tTok=..Scanner.CurrentToken
		If tTok=$$$tokATSIGN {
			#; Skip '@'
			Set tTok=..Scanner.NextToken()
			If tTok=$$$tokDIGIT Set tOrdinal=..Scanner.Integer()
			If tOrdinal="" {
				Set tSC=..ParserError("Segment: "_tName_",Expected Ordinal Number (Integer)")
				Quit
			}
			#; Override the current ordinal
			Set (..SetOrdinal,tSetOrdinalSpec)=tOrdinal
		} Else {
			#; Increment the current ordinal
			Set ..SetOrdinal=..SetOrdinal+1
		}
		#; Compound ?
		Set tTok=..Scanner.CurrentToken
		If tTok'=$$$tokRBRACK {
			#; Delimiter
			If tTok'=$$$tokCOMMA {
				Set tSC=..ParserError("Expected Delimiter ','")
				Quit
			} Else {
				Set tTok=..Scanner.NextToken()
			}
			#; Requirement?
			If tTok=$$$tokLETTER {
				Set tSC=..ValidateSetRequirement(..Scanner.CurrentChar)
				If $$$ISERR(tSC) Quit
				
				Set tStdRequirement=..Scanner.CurrentChar
				Set tTok=..Scanner.NextToken()
			}
			If tTok'=$$$tokRBRACK {
				#; Delimiter
				If tTok'=$$$tokCOMMA {
					Set tSC=..ParserError("Expected Delimiter ','")
					Quit
				} Else {
					Set tTok=..Scanner.NextToken()
				}
				Set tCount=..Scanner.Count()
				If tCount'="" {
					Set tRepeatCount=tCount
				} Else {
					Set tSC=..ParserError("Expected Count")
					Quit
				}
				If pGroupTrigger=1 {
					#; RULE: The loop trigger's maximum repeat count is always 1. 
					#; If it is omitted, or coded as something else, it should
					#; always be interpreted as 1. This is true of EDIFACT groups also.
					Set tRepeatCount=1
				}
				#; Establish current token
				Set tTok=..Scanner.CurrentToken
			}
			If tTok'=$$$tokRBRACK {
				Set tSC=..ParserError("Expected Delimiter ']'")
				Quit
			}	
		}
		#; Skip ']'
		Do ..Scanner.NextToken()
		
		Set tSC=..ParseSegment(tName,pSetSegDef,.tSegDef)
		If $$$ISERR(tSC) Quit
		
		#; OK, fill in the definition
		Set pSetSegDef.PositionModifier=tPositionModifier
		Set pSetSegDef.Name=tName
		Set pSetSegDef.UsrRequirement=tUsrRequirement
		Set pSetSegDef.StdRequirement=tStdRequirement
		Set pSetSegDef.RepeatCount=tRepeatCount
		Set pSetSegDef.Mask=tMask
		Set pSetSegDef.GroupTrigger=pGroupTrigger
		Set pSetSegDef.OrdinalSpec=tOrdinalSpec
		Set pSetSegDef.Ordinal=..SetOrdinal
		Set pSetSegDef.Position=..SetPosition
		Set pSetSegDef.Segment=tSegDef
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSyntaxRule(pParent As EnsLib.EDI.SEF.Segment, Output pRule As EnsLib.EDI.SEF.SyntaxRule) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
				
		$$$ASSERTNOLOG("|R|C|E|L|P|"[("|"_..Scanner.CurrentChar_"|"))
		
		#; Create a Rule
		Set pRule=##class(EnsLib.EDI.SEF.SyntaxRule).%New()
		$$$ASSERTNOLOG($IsObject(pRule))
		
		#; Fix up Parent
		Set pRule.Parent=pParent
		
		Set pRule.RuleType=..Scanner.CurrentChar
		
		Set tTok=..Scanner.NextToken()
		While (tTok=$$$tokDIGIT) {
			Set pRule.Operands=pRule.Operands_..Scanner.CurrentChar
			Set tTok=..Scanner.NextToken()
		}
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseTable(pParent As EnsLib.EDI.SEF.Node, Output pTable As EnsLib.EDI.SEF.Table) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		$$$ASSERTNOLOG(..Scanner.CurrentToken=$$$tokARROW)
		
		Set tTok=..Scanner.CurrentToken
		While tTok=$$$tokARROW {
			#; RULE: Transaction sets or messages cannot have empty tables so two consecutive ^ are treated as one.
			Set tTok=..Scanner.NextToken()
		}
		#; Increment the table counter
		Set ..TableCounter=..TableCounter+1
		
		#; Reset the Counters
		If ","_..STD_","'[",LS," {
			#; RULE: In Older X12 and EDIFACT standards, sequence numbers start over
			#; in each new table (but not ordinals)
			Set ..SetPosition=0,..SetIncrement=10
		}
		Set pTable=##class(EnsLib.EDI.SEF.Table).%New()
		$$$ASSERTNOLOG($IsObject(pTable))
		
		#; Fix up the parent and set the number
		Set pTable.Parent=pParent,pTable.Number=..TableCounter
		
		#; There is no end-table delimiter, so must check EOF
		While (tTok'=$$$tokEOFL&&(tTok'=$$$tokARROW)) {
			If tTok=$$$tokLBRACK||(tTok=$$$tokPLUS)||(tTok=$$$tokMINUS) {
				Set tSC=..ParseSetSegment(0,pTable,.tNode)
			} ElseIf tTok=$$$tokLBRACE||(tTok=$$$tokATSIGN) {
				Set tSC=..ParseSetItemGroup(pTable,.tNode)	
			} Else {
				Set tSC=..ParserError("Syntax Error while parsing table")
			}
			If $$$ISERR(tSC) Quit
			
			#; OK
			Do pTable.Nodes.Insert(.tNode)
			Set tTok=..Scanner.CurrentToken
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Form an error message
Method ParserError(pError As %String) As %Status
{
	/// TO DO: Revisit, replace with localized error messages
	/// Use scanner to discover offset and context
	Quit $$$ERROR($$$GeneralError,pError_..Scanner.DisplayContext())
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; Create the scanner stack
	Set ..ScannerStack=##class(EnsLib.EDI.SEF.Util.Stack).%New()
	$$$ASSERTNOLOG($IsObject(..ScannerStack))
	
	Quit $$$OK
}

Method ValidateSegRequirement(pRequirement As %String) As %Status
{
	// TO DO: Distinguish between Edifact and X12 validation ?How
	Set tSC=$$$OK
	If $$$StdSegRequirement'[("|"_pRequirement_"|") {
		Set tSC=..ParserError("Invalid Requirement: "_pRequirement)
	}
	Quit tSC
}

Method ValidateSetRequirement(pRequirement As %String) As %Status
{
	#; TO DO: Distinguish between Edifact and X12 validation ?How
	Set tSC=$$$OK
	If $$$StdSetRequirement'[("|"_pRequirement_"|") {
		Set tSC=..ParserError("Invalid Requirement: "_pRequirement)
	}
	Quit tSC
}

/// The DefaultStdRequirement depends upon the standard inforce
Method DefaultStdRequirementGet() As %String
{
	#; TO DO: Expand to support other Agencies
	Quit $Case(..Agency,$$$ASCX12:"O",$$$UNEDIFACT:"C",:"")
}

/// Parse a Rule
Method ParseRule(pString As %String, Output pRule As Rule) As %Status
{
	Set tSC=$$$OK,pRule=$$$NULLOREF
	Do {
		#; Need a new scanner for the rule
		Do ..ScannerStack.Push(..Scanner) 
	
		Set ..Scanner=##class(EnsLib.EDI.SEF.Scanner).%New(pString)
		$$$ASSERTNOLOG($IsObject(..Scanner))
		
		If ..Scanner.CurrentToken'=$$$tokLBRACK Set tSC=..ParserError("Expected delimiter '['") Quit
		
		#; Skip '['
		Do ..Scanner.NextToken()
		
		#; Parse the conditional expression
		Set tSC=..ParseExpressionList(.tCondition) If $$$ISERR(tSC) Quit
		
		If ..Scanner.CurrentToken'=$$$tokCOLON {
		Set tSC=..ParserError("Expected delimiter ':'")
			Quit
		}
	
		#; Skip ':'
		Do ..Scanner.NextToken()
		
		Set tType=..Scanner.Identifier()
		
		If "|USAGE|LOCALCODE|APPVALUE|COMEXIT|"'[("|"_tType_"|") {
			Set tSC=..ParserError("Invalid Type, expected USAGE,LOCALCODE,APPVALUE OR COMEXIT") Quit
		}
		
		If ..Scanner.CurrentToken'=$$$tokCOLON {
		Set tSC=..ParserError("Expected delimiter ':'")
			Quit
		}
	
		#; Skip ':'
		Do ..Scanner.NextToken()
		
		Set tSetting=..Scanner.Piece($$$tokCOLON)
		
		If ..Scanner.CurrentToken'=$$$tokCOLON {
		Set tSC=..ParserError("Expected delimiter ':'")
			Quit
		}
	
		#; Skip ':'
		Do ..Scanner.NextToken()
		
		Set tParameter=..Scanner.Piece($$$tokRBRACK)
		
		If ..Scanner.CurrentToken'=$$$tokRBRACK Set tSC=..ParserError("Expected delimiter ']'") Quit
	
		Set pRule=##class(EnsLib.EDI.SEF.Rule).%New()
		If '$IsObject(pRule) Set tSC=%objlasterror Quit
		
		Set pRule.Condition=tCondition,pRule.Type=tType,pRule.Setting=tSetting,pRule.Parameter=tParameter
		
	} While 0
	
	Do ..ScannerStack.Pop()
	
	Quit tSC
}

Method ParseExpressionList(Output pExpressionList As ExpressionList) As %Status
{
	Set tSC=$$$OK
	Do {
		Set pExpressionList=##class(EnsLib.EDI.SEF.ExpressionList).%New()
		If '$IsObject(pExpressionList) Set tSC=%objlasterror Quit
		
		While ..Scanner.CurrentToken'=$$$tokCOLON&&(..Scanner.CurrentToken'=$$$tokEOFL) {
			#; Read in the identifier
			Set tVariable=..Scanner.CodeName()
			
			#; Identifier is mandatory
			If tVariable="" Set tSC=..ParserError("Expected variable name") Quit
			
			#; Read the operator
			If ..Scanner.CurrentToken'=$$$tokSQUOTE Set tSC=..ParserError("Expected delimiter '''") Quit
			
			#; Skip '
			Do ..Scanner.NextToken()
			
			Set tOperator=..Scanner.Identifier()
			If "|EQ|NE|GT|GE|LT|LE|EXISTS|NEXIST|"'[("|"_tOperator_"|") {
				Set tSC=..ParserError("Expected Operator 'EQ','NE','GT','LT','LE','EXISTS' or 'NEXIST'") Quit
			}
			
			If ..Scanner.CurrentToken'=$$$tokSQUOTE Set tSC=..ParserError("Expected delimiter '''") Quit
			
			#; Skip '
			Set tToken=..Scanner.NextToken(),tValue="",tSeparator=""
			While tToken'=$$$tokCOLON&&(tToken'=$$$tokEOFL) {
				If tToken=$$$tokVBAR||(tToken=$$$tokAMPER) {
					Do ..Scanner.NextToken()
					Quit
				}
				Set tValue=tValue_..Scanner.CurrentChar
				Set tToken=..Scanner.NextToken()
			}
			Set tSeparator=$Case(tOperator,$$$tokVBAR:"|",$$$tokAMPER:"&",:"")
			
			Set tExpr=##class(EnsLib.EDI.SEF.Expression).%New()
			If '$IsObject(tExpr) Set tSC=%objlasterror Quit
			
			Set tExpr.Variable=tVariable,tExpr.Operator=tOperator,tExpr.Value=tValue,tExpr.Separator=tSeparator
			
			Do pExpressionList.Insert(tExpr)
		}
	} While 0
	Quit tSC
}

/// Parse a location
Method ParseLocation(pString As %String, Output pLocation As Location) As %Status
{
	Set tSC=$$$OK,pLocation=$$$NULLOREF
	Do {
		#; Need a new scanner for the location
		Do ..ScannerStack.Push(..Scanner) 
	
		Set ..Scanner=##class(EnsLib.EDI.SEF.Scanner).%New(pString)
		$$$ASSERTNOLOG($IsObject(..Scanner))
	
		#; Validate the location
		#; 
		Set tSet=..Scanner.Integer()
		If tSet="" {
			Set tSC=..ParserError("Expected Transaction Set ID")
			Quit
		}
		
		If ..Scanner.CurrentToken'=$$$tokSLASH {
			Set tSC=..ParserError("Expected delimiter '/'")
			Quit
		}
		
		#; Skip '/'
		Do ..Scanner.NextToken()
		
		Set tSegOrd=..Scanner.Integer()
		If tSegOrd="" {
			Set tSC=..ParserError("Expected segment ordinal")
			Quit
		}
		
		If ..Scanner.CurrentToken'=$$$tokSLASH {
			Set tSC=..ParserError("Expected delimiter '/'")
			Quit
		}
		
		#; Skip '/'
		Do ..Scanner.NextToken()
		
		Set tSegTag=""
		If ..Scanner.CurrentToken=$$$tokLETTER {
			Set tSegTag=..Scanner.SegmentName()
		}
		
		If ..Scanner.CurrentToken'=$$$tokSLASH {
			Set tSC=..ParserError("Expected delimiter '/'")
			Quit
		}
		
		#; Skip '/'
		Do ..Scanner.NextToken()
		
		Set tEleID=..Scanner.ElementID()
		If ..Scanner.CurrentToken'=$$$tokSLASH {
			Set tSC=..ParserError("Expected delimiter '/'")
			Quit
		}
		
		#; Skip '/'
		Do ..Scanner.NextToken()
		
		Set tEleOrd=..Scanner.Integer()
		If tEleOrd="" {
			Set tEleOrd=1
		}
		Set tSubEleOrd=""
		If ..Scanner.CurrentToken=$$$tokMINUS {
			
			#; Skip '-'
			Do ..Scanner.NextToken()
			
			Set tSubEleOrd=..Scanner.Integer()
			If tSubEleOrd="" {
				Set tSC=..ParserError("Expected sub-element ordinal")
				Quit
			}
		}
		#; Create the location
		Set pLocation=##class(EnsLib.EDI.SEF.Location).%New()
		If '$IsObject(pLocation) Set tSC=%objlasterror Quit
		
		Set pLocation.Set=tSet,pLocation.SegOrd=tSegOrd,pLocation.SegTag=tSegTag
		Set pLocation.EleID=tEleID,pLocation.EleOrd=tEleOrd,pLocation.SubEleOrd=tSubEleOrd
		
	} While 0
	
	Do ..ScannerStack.Pop()
	
	Quit tSC
}

Method ParseObjectVariables(pParent As Document, Output pObjVars As ObjectVariableList) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set pObjVars=##class(ObjectVariableList).%New() 
		If '$IsObject(pObjVars) Set tSC=%objlasterror Quit
		
		Set tKey="" For {
			
			Set tKey=$Order(^IRIS.Temp.SEF(..DocKey,"OBJVARS",tKey),1,tID) If tKey="" Quit
			
			Set tSC=..ParseLocation(tKey,.tLocation)
			If $$$ISERR(tSC) Quit
			
			Set tObjVar=##class(EnsLib.EDI.SEF.ObjectVariable).%New()
			If '$IsObject(tObjVar) Set tSC=%objlasterror Quit
			
			Set tObjVar.Location=tLocation,tObjVar.Identifier=tID
			
			#; Append it to the list
			Set tSC=pObjVars.Insert(tObjVar)
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseSemanticReferences(pParent As Document, Output pSemRefs As SemanticReferenceList) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set pSemRefs=##class(SemanticReferenceList).%New() 
		If '$IsObject(pSemRefs) Set tSC=%objlasterror Quit
		
		Set tKey="" For {
			
			Set tKey=$Order(^IRIS.Temp.SEF(..DocKey,"SEMREFS",tKey),1,tRef) If tKey="" Quit
			
			Set tSC=..ParseLocation(tKey,.tLocation)
			If $$$ISERR(tSC) Quit
			
			Set tSC=..ParseRule(tRef,.tRule) If $$$ISERR(tSC) Quit
			
			Set tSemRef=##class(EnsLib.EDI.SEF.SemanticReference).%New()
			If '$IsObject(tSemRef) Set tSC=%objlasterror Quit
			
			Set tSemRef.Location=tLocation,tSemRef.Rule=tRule
			
			#; Append it to the list
			Set tSC=pSemRefs.Insert(tSemRef)
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
