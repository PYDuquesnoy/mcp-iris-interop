/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIEDIFACT

/// This is the EDIFACT Interchange parser
Class EnsLib.EDI.EDIFACT.Parser Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Number of seconds to wait for the start of a document to be available on the input stream
Property StartTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 5 ];

/// Number of seconds to wait for each read of document data inside a started document to be available on the input stream
Property ReadTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 5 ];

/// This property controls the skipping of whitespace in the data stream. Set it to a string of characters that should be 
/// considered whitespace and not part of the data
Property Whitespace As %String;

/// This remembers separators defined in the UNA, but you can pre-set it to read TransactionSets without an UNA
Property Separators As %String(MAXLEN = 4, MINLEN = 4);

/// This remembers the terminator defined in the UNA, but you can pre-set it to read TransactionSets without an UNA
Property SegmentTerminator As %String(MAXLEN = 1, MINLEN = 1);

/// This allows you to pre-set a ControlVersion to use when reading TransactionSets without an UNA or UNG
Property ControlVersion As %String(MAXLEN = 5);

Property Done As %Boolean [ Calculated, ReadOnly ];

// Private State Properties

Property %Stream As %IO.I.CharacterStream;

/// Lookahead line left over from previous document parse
Property %LookaheadLine As %String;

/// Lookahead buffer for line terminator of unframed MSH
Property %LookaheadLineTerminator As %String;

/// Lookahead buffer for line terminator of unframed MSH
Property %LookaheadLineIsNew As %Boolean;

/// Count of Segments tallied during parse of a TransactionSet
Property %SegmentCount As %Integer;

/// Count of TransactionSets in a Group
Property TransactionSetCount As %Integer;

Property %LineCount As %Integer;

Property %CharCount As %Integer;

/// The config provider
Property %ServiceInterface As EnsLib.EDI.ServiceInterface;

/// The current Document
Property %CurrentDocument As EnsLib.EDI.Document;

/// The segment position within the current parent Document
Property %CurrentParentSegIndex As %String;

/// List of enclosing parent objects ordered from outermost to immediate
///  As EnsLib.EDI.Document 
Property %CurrentParents [ InitialExpression = 0, MultiDimensional ];

/// List of enclosing parent objects ordered from immediate to outermost
Property %ParentIds As %String;

/// List of counts of nested documents, ordered from outer to innermost
Property %NumChildren As %Integer [ MultiDimensional ];

Method DoneGet() As %Boolean [ CodeMode = expression ]
{
""=..%LookaheadLine&&('$IsObject(..%Stream)||..%Stream.AtEnd)
}

/// Parse a complete EDIFACT interchange document from the stream, including any nested TransactionSet documents inside it.
/// An Interchange contains zero or more functional groups which in turn contain TransactionSets.
Method ParseIOStream(pIOStream As %IO.I.CharacterStream, Output pDocument As EnsLib.EDI.EDIFACT.Document, ByRef pControlVersion As %String = "", pInbound As %Boolean = 0) As %Status
{
	$$$ASSERT($IsObject(pIOStream))
	Set (tSC,tSC1)=$$$OK, (pDocument,tDoc)=$$$NULLOREF, ..%Stream=pIOStream, tLine=..%LookaheadLine, tZB=..%LookaheadLineTerminator, tExtra=""
	Set tUNALine="", tUNOSegs=-1, tNumGroups=0, tParentDoc=..%CurrentDocument, tParentDocPos=..%CurrentParentSegIndex, tGSControlVersion=""
	Set:'$IsObject(tParentDoc) tLine=tLine_tZB, tZB=""
	If ""'=tLine {
		Set tStartTimeout=..ReadTimeout
		If ..%LookaheadLineIsNew {
			Set ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)
			Set ..%LookaheadLineIsNew=0
		}
	} Else { Set tStartTimeout=..StartTimeout }
	Do { ; While 0
		#; Process any preceding stuff in the stream

		#; Let the interface event handler know we are about to process an interchange
		#; giving an opportunity to 'filter' extraneous header/trailer/filler which
		#; may be present in the stream.
		#; tLine contains any extra chars read that may be part of the beginning of the interchange.
		#; On exit, tLine must not be longer than 9 bytes, and it must not omit any terminator characters
		#; between its end and what will next be read from pIOStream
		Set tSC=..%ServiceInterface.OnPreDocument(pIOStream,.tLine)  Quit:$$$ISERR(tSC)||(""=tLine&&pIOStream.AtEnd)

		#; Count the documents we encounter, nested
		If $IsObject(tParentDoc) {
			#; child document
			Set tParentRef=tParentDoc.getId()_":"_tParentDocPos, tParentIds=$LB(tParentRef)_..%ParentIds
			Set tSubsc="",tLevels=1+$LL(tParentIds)  For i=1:1:tLevels-1  Set tSubsc=""""_$LI(tParentIds,i)_""","_tSubsc
			Set tRef=$S(""=tSubsc:"..%NumChildren",1:"..%NumChildren("_$E(tSubsc,1,*-1)_")")
			Set tLevelDocs=$G(@tRef)+1

			Set tComponentSeparator=$E(..Separators,1),
				tDataElementSeparator=$E(..Separators,2),
				tEscapeSeparator=$E(..Separators,3),
				tRepetitionSeparator=$E(..Separators,4),
				tSegTerminator=..SegmentTerminator
			Set:tSegTerminator=$E(tLine) tExtra=$P(tLine,tSegTerminator,3,99), tLine=$P(tLine,tSegTerminator,2)
			Set (tSegName,tFirstSeg)=$P($P(tLine,tDataElementSeparator),tComponentSeparator)
			If ""'=tZB&&(tZB=$E(tLine,*+1-$L(tZB),*)) { Set tLine=$E(tLine,1,*-$L(tZB)) }
			Else { Set tZB="" }
			Set tComplete=(""'=tZB)
		} Else {
			Set (tParentRef,tParentIds)="", tSubsc="", tLevels=1, tRef="..%NumChildren", tLevelDocs=$G(..%NumChildren)+1

			#; Set flags to keep track of what is seen in an interchange
			Set ..%SegmentCount=0

			#; Find the next potential fixed-length UNA segment
			Set tFresh=""  For {
				Set:""'=..Whitespace tLine=..StripWhitespace(tLine)
				Quit:$L(tLine)>=9||pIOStream.AtEnd
				$$$catTRACE("parse","Beginning header read for 9-byte header with timeout "_tStartTimeout_" on "_pIOStream.Name)
				Set tTimeout=tStartTimeout, tFresh=pIOStream.Read(9-$L(tLine),.tTimeout,.tSC), tLine=tLine_tFresh
				Set tTimedOut=(tStartTimeout&&(tTimeout=tStartTimeout))
				Set ..%CharCount=..%CharCount+$L(tFresh)
				Set:tTimedOut&&$$$ISOK(tSC) tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level 1, @Line "_..%LineCount,
											 tSC=$$$ERROR($$$EnsErrTCPReadTimeoutExpired,tStartTimeout,"9-char UNA header","binary")
				Quit:$$$ISERR(tSC)
				Set tStartTimeout=..ReadTimeout ; already started so go to read mode
			}
			Quit:""=tLine||$$$ISERR(tSC)
			
			Set tDataElementSeparator=$E($ZStrip(tLine,"<ANW")), tComponentSeparator=""
			If "UNA"=$P(tLine,tDataElementSeparator) {
				#; new UNA - Validate/Record the Separators/Terminator
				Set:""'=tFresh ..%LineCount=..%LineCount+1
				Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level 1, @Line "_..%LineCount

				Set tUNALine=$E(tLine,1,9)
				If $L(tUNALine)<6 {
					Set tExtra=..StripWhitespace($E(tLine,$L(tUNALine)+5,*)), tLine=$E(tLine,1,$L(tUNALine)+4) ; ES,CS,ST
					// $$$LOGSTATUS($$$ERROR($$$EnsEDIEDIFACTUNATruncated,$L(tLine),tLine,tDocPos))
				}
				Set tSegTerminator=$E(tLine,*)
				If tSegTerminator?1(1A,1N) { Set tSC=$$$ERROR($$$EnsEDIEDIFACTInvalidSegmentTerminator,$A(tSegTerminator),tLine,tDocPos), tLine=""  Quit }
				Set $E(tLine,$L(tLine))="" ; remove the terminator from the stored segment

				Set tComponentSeparator=tDataElementSeparator
				Set tDataElementSeparator=$E(tLine,5) Set:""=tDataElementSeparator tDataElementSeparator=tComponentSeparator
				#; skip obsolete decimal separator
				Set tEscapeSeparator=$E(tLine,7)
				Set tRepetitionSeparator=$E(tLine,8)

				#; At this point the separators are valid;  further processing can continue
				$$$catTRACE("parse","Got UNA header line #"_..%LineCount_" '"_tLine_"'")
				
				Set tUNALine=tLine, tLine=tExtra, tExtra=""
			} Else {
				#; not UNA
				If ""'=..SegmentTerminator { Set tSegTerminator=..SegmentTerminator }				
				Else { Set tSegTerminator=$$$EDIFACTDefSegTerminator }
				Set:""=tDataElementSeparator tDataElementSeparator=$$$EDIFACTDefElementSeparator				
				Set:""=tComponentSeparator tComponentSeparator=$$$EDIFACTDefComponentSeparator, tEscapeSeparator=$$$EDIFACTDefEscapeSeparator, tRepetitionSeparator=$$$EDIFACTDefRepetitionSeparator
			}
			; Make sure separators are valid and not colliding
			If tComponentSeparator?1(1A,1N)||$Case(tComponentSeparator,"":1," ":1,$C(0):1,$C(1):1,$C(2):1,$C(3):1,tDataElementSeparator:1,:0) Set tComponentSeparator=$C(17)
			#; skip obsolete decimal separator
			If tEscapeSeparator?1(1A,1N)||$Case(tEscapeSeparator,"":1," ":1,$C(0):1,$C(1):1,$C(2):1,$C(3):1,tDataElementSeparator:1,tComponentSeparator:1,:0) Set tEscapeSeparator=$C(19)
			If tRepetitionSeparator?1(1A,1N)||$Case(tRepetitionSeparator,"":1," ":1,$C(0):1,$C(1):1,$C(2):1,$C(3):1,tDataElementSeparator:1,tComponentSeparator:1,tEscapeSeparator:1,:0) Set tRepetitionSeparator=$C(20)

			Set ..Separators=tComponentSeparator_tDataElementSeparator_tEscapeSeparator_tRepetitionSeparator
		    Set:""=..SegmentTerminator ..SegmentTerminator=tSegTerminator
		    Set pIOStream.LineTerminator=tSegTerminator

			#; find next seg
		    Set tSegLine=$P(tLine,tSegTerminator)
		    If tSegLine'=tLine {
			    Set tExtra=..StripWhitespace($E(tLine,$L(tSegLine)+2,*)), tLine=tSegLine, tZB=tSegTerminator, tComplete=1, ..%LineCount=..%LineCount+1
		    } Else { ; finish the segment now that we have an assumed terminator
			    Set tTimedOut=0  While 'pIOStream.AtEnd {
				    Kill tZB  Set tTimeout=..ReadTimeout, tLine=tLine_pIOStream.ReadLine(32767-5-$L(tLine),.tTimeout,.tSC,.tZB)  ; No Quit; will break at end of loop
				    Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout)), tComplete=(""'=tZB)
				    If $E($Replace(tLine,tEscapeSeparator_tEscapeSeparator,""),*)=tEscapeSeparator && (tZB=tSegTerminator) Set tLine=tLine_tZB, tComplete=0  Continue:'$$$ISERR(tSC)
				    Set:""'=tLine||tComplete ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)+$L(tZB)
					
					#; Strip whitespace; quit if we got the line terminator, unless the line consisted only of whitespace
					Quit:..Whitespace=""
					Set tLine=..StripWhitespace(tLine)
					Quit:tTimedOut||$$$ISERR(tSC)||(""'=tLine&&tComplete)
			    }
				Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level 1, @Line "_..%LineCount
			    Set:tTimedOut&&$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)
			    If tTimedOut&&$$$ISOK(tSC) { Set tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)  Quit }
			    ElseIf $$$ISERR(tSC) { Set tSC=$$$ERROR($$$EnsEDIEDIFACTUnexpectedEOD,tLine,$$$StatusDisplayString(tSC),tDocPos), tLine=""  Quit }
		    }
			Set (tSegName,tFirstSeg)=$P($P(tLine,tDataElementSeparator),tComponentSeparator)
			If $Case(tSegName,"UNB":0,"UNO":0,"UNG":0,"UNH":0,"UIB":0,"UIH":0,:1) {
				Set tSC=$$$ERROR($$$EnsEDIEDIFACTExpectedSegment,"UNB",tLine,tDocPos), tLine=""
				Quit
			}
			#; Handle binary 'package' object
			If tSegName="UNO" {
				Set tUNO4=$P(tLine,tDataElementSeparator,6), tUNOBytes=$P(tUNO4,tComponentSeparator,1), tUNOSegs=$P(tUNO4,tComponentSeparator,2)
			}

		    $$$catTRACE("parse","Got "_tSegName_" segment line #"_..%LineCount_" '"_tLine_"'")
			
			#; finish the extra line (if any) out to the next terminator
			If ""'=tExtra && 'pIOStream.AtEnd && 'tUNOSegs {
				Set tTimedOut=0  While 'pIOStream.AtEnd {
					Kill tZB  Set tTimeout=..ReadTimeout, tExtra=tExtra_pIOStream.ReadLine(32767-5-$L(tLine),.tTimeout,.tSC,.tZB)_tZB  ; No Quit; will break at end of loop
					Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout))
					If tTimedOut&&$$$ISOK(tSC) { Set tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tExtra)  Quit }
					ElseIf $$$ISERR(tSC) { Set tSC=$$$ERROR($$$EnsEDIEDIFACTUnexpectedEOD,tExtra,$$$StatusDisplayString(tSC),tDocPos), tExtra=""  Quit }
				    If $E($Replace(tExtra,tEscapeSeparator_tEscapeSeparator,""),*-1)=tEscapeSeparator && (tZB=tSegTerminator) Continue:'$$$ISERR(tSC)
				    Quit
				}
			}
		}
		#; Store the data for the first segment
		Set tJK=$$$JobKey
		If '$D(%topSegIndex) {
			Set %topSegIndex=$G($$$vaSegmentGbl(tJK))
			#; Cleanup: kill any leftover uncommitted stored segments
			Set kSI=%topSegIndex For {Set kSI=$O($$$vaSegmentGbl(tJK,kSI)) Quit:""=kSI
			Kill $$$vaSegmentGbl(tJK,kSI) }
		}
		If ""'=tUNALine { Set tTempLine=tLine, tLine=tUNALine }
		Set tIndex=tJK_","_$I(%topSegIndex), $$$vaSegment(tIndex)=..Separators_tLine, $$$vaOpenSegmentPPG(tIndex) = 1, tLine="",tZB="", ..%SegmentCount=..%SegmentCount+1
		Set $$$vaSegmentExt(tIndex,"term")=tSegTerminator
		
		#; Instantiate a document to hold the segment and any to follow
		Set tDocPos=$S(""=tParentIds:pIOStream.Name,1:"")_$S(..%LineCount<=2:"", 1:$C(13,10)_" Document# "_tLevelDocs_", level "_tLevels_", @Line "_..%LineCount)
		Set tDoc=##class(EnsLib.EDI.EDIFACT.Document).%New($LB($LB(tIndex),..Separators_tSegTerminator,tDocPos,tParentRef))  If '$IsObject(tDoc) Set tSC=%objlasterror Quit
		If $IsObject(tParentDoc) {
			Set ..%CurrentParents=..%CurrentParents+1, ..%CurrentParents(..%CurrentParents)=tParentDoc
			Set ..%ParentIds=tParentIds
		}
		Set ..%CurrentDocument=tDoc, tSegNum=2 ; tSegNum is current segment of current document
		
		#; Add the second segment if first was UNA
		If ""'=tUNALine {
			Set tLine=tTempLine, tUNALine=""
			Set tIndex=tJK_","_$I(%topSegIndex)
			Set $$$vaSegment(tIndex)=..Separators_tLine
			Set $$$vaOpenSegmentPPG(tIndex) = 1
			Set $$$vaSegmentExt(tIndex,"term")=tSegTerminator
			Set tLine="", ..%SegmentCount=..%SegmentCount+1, tSegNum=3
			Set $$$vaMobj(tDoc,"runtimeIndex")=$$$vaMobj(tDoc,"runtimeIndex")+1, $$$vaMobja(tDoc,"runtimeIndex",$$$vaMobj(tDoc,"runtimeIndex"))=tIndex
		}
		#; Count the documents we encounter, nested
		Set tTypeName=tDoc.Name  Set:""=tTypeName tTypeName="?"
		Set tReft="..%NumChildren("_tSubsc_""""_tTypeName_""")"
		Set tLevelTypeDocs=$G(@tReft)+1
		Set @tRef=tLevelDocs, @tReft=tLevelTypeDocs

		#; Notify the Service of the new document beginning
		Set tSC1=..%ServiceInterface.OnDocumentStart(tDoc,tDocPos,tSC)  Quit:$$$ISERR(tSC1) // Fatal Error

		#; Parse the rest of the segments in the current document
		#;$$$catTRACE("parse","+ %CurrentParents="_..%CurrentParents_", tDoc="_tDoc_", tParentDoc="_tParentDoc)
		Set (iRef,iRefSegId)=0
		While $$$ISOK(tSC)&&(tLine_tExtra'=""||'pIOStream.AtEnd) { ; loop over segs in the doc
			If 'tUNOSegs {
				Set tExtra=..readBinary(tDoc,tUNOBytes,$S(""'=tLine:tLine_tZB,1:tExtra),tDataElementSeparator,tSegTerminator,.tSC)  Quit:$$$ISERR(tSC)
				Set tLine="",tZB=""
				Continue
			}
			If ""=tLine&&(""'=tExtra) {
				Set tLine=$P(tExtra,tSegTerminator), tZB=$S(tLine=tExtra:"",1:tSegTerminator), tComplete=(""'=tZB)
				Set tExtra=..StripWhitespace($E(tExtra,$L(tLine)+2,*))
			}
			If ""=tLine {
				#; Get new text; discard leading whitespace - this has the effect of removing Whitespace between segments while preserving Whitespace within them
				Set tTimedOut=0  While 'pIOStream.AtEnd {
					Kill tZB  Set tTimeout=..ReadTimeout, tLine=tLine_pIOStream.ReadLine(32767-5-$L(tLine),.tTimeout,.tSC,.tZB)  ; No Quit; will break at end of loop
					Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout)), tComplete=(""'=tZB)
				    If $E($Replace(tLine,tEscapeSeparator_tEscapeSeparator,""),*)=tEscapeSeparator && (tZB=tSegTerminator) Set tLine=tLine_tZB, tComplete=0  Continue:'$$$ISERR(tSC)
					Set:""'=tLine||tComplete ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)+$L(tZB)

					#; Strip whitespace; quit if we got the line terminator, unless the line consisted only of whitespace
					Quit:..Whitespace=""
					Set tLine=..StripWhitespace(tLine)
					Quit:tTimedOut||$$$ISERR(tSC)||(""'=tLine&&tComplete)
				}
				If tTimedOut&&$$$ISOK(tSC) { Set tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)  Quit }
				ElseIf tLine=""||$$$ISERR(tSC) { Set tSC=$$$ERROR($$$EnsEDIEDIFACTUnexpectedEOD,tLine,$$$StatusDisplayString(tSC),tDocPos), tLine=""  Quit }
				$$$catTRACE("parse","Got segment line #"_..%LineCount_" '"_tLine_"'")
			}
			Set tPrevSeg=tSegName, tSegName=$P(tLine,tDataElementSeparator)
			Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level "_tLevels_", segment "_tSegNum_", @Line "_..%LineCount
			If $ZStrip($P(tSegName,tComponentSeparator,2,*),"*N",tComponentSeparator)'="" {  ;Don't allow characters other than numbers and comp separator where level of repetition should be
				Set tSC=$$$ERROR($$$EnsEDIEDIFACTInvalidSegmentName,tSegName,tLine,tDocPos), tLine=""
				Quit
			}
			Set tSegName=$P(tSegName,tComponentSeparator) ;allow level of repetition to be explicit
			If ($L(tSegName)'=3)||(tSegName'=$ZCVT(tSegName,"U")) {
				Set tSC=$$$ERROR($$$EnsEDIEDIFACTInvalidSegmentName,tSegName,tLine,tDocPos), tLine=""
				Quit
			}
			#; Drill down & start a new doc, pop up, or keep adding segments to the current doc
			If $Case(tSegName,"UNG":1,"UNO":1,"UNH":1,"UIH":1,:0) { ; drill down
				Set tGroupName=tSegName_"DocsRef"
				If tPrevSeg'=tGroupName {
					If "UNG"=tSegName {
						If "UNB"'=tPrevSeg&&(tPrevSeg'["DocsRef") {
							$$$LOGSTATUS($$$ERROR($$$EnsEDIEDIFACTInvalidSegmentType,tSegName,tPrevSeg,tDocPos))
						}
						Set tNumGroups=tNumGroups+1
					} Else {
						If "UIH"=tSegName {
							If "UIB"'=tPrevSeg {
								$$$LOGSTATUS($$$ERROR($$$EnsEDIEDIFACTInvalidSegmentType,tSegName,tPrevSeg,tDocPos))
							}
						} Else {
							If "UIB"=tPrevSeg {
								$$$LOGSTATUS($$$ERROR($$$EnsEDIEDIFACTInvalidSegmentType,tSegName,tPrevSeg,tDocPos))
							}
						}
						Set ..TransactionSetCount=..TransactionSetCount+1, ..%SegmentCount=1
					}
					#; Create a placeholder segment for the child document(s)
					Set tIndex=tJK_","_$I(%topSegIndex)
					Set iRef=$$$vaMobj(tDoc,"runtimeIndex")+1, iRefSegId=tIndex, tSegNum=tSegNum+1
					Set $$$vaSegment(tIndex)=..Separators_tGroupName_tDataElementSeparator_iRef_tDataElementSeparator
					Set $$$vaSegmentExt(tIndex,"term")=tSegTerminator
					Set $$$vaOpenSegmentPPG(tIndex) = 1
					Set $$$vaMobj(tDoc,"runtimeIndex")=iRef, $$$vaMobja(tDoc,"runtimeIndex",iRef)=tIndex
					Set ..%CurrentParentSegIndex=iRef
				}
				Set tPrevSeg=tSegName, tSegName=tGroupName

				#; parse the nested child document
				Set $$$vaSegmentGbl(tJK)=%topSegIndex ; commit ahead of %Save
				Set tSC=tDoc.%Save()  Quit:$$$ISERR(tSC) ; save the doc-in-progress so children will have access to its content.
				Set ..%LookaheadLine=tLine, ..%LookaheadLineTerminator=tZB
				Set:""'=tExtra ..%LookaheadLine=tSegTerminator_tLine_tSegTerminator_tExtra, tExtra=""
				Set tSC=..ParseIOStream(pIOStream,,$S(""=tGSControlVersion:pControlVersion, 1:tGSControlVersion),pInbound)
				Set %topSegIndex=$$$vaSegmentGbl(tJK) ; restore after Kill in recursive call
				Set tLine=..%LookaheadLine, tZB=..%LookaheadLineTerminator
				Quit:$$$ISERR(tSC)
				Continue
			} ElseIf $Case(tSegName, "UNZ":"UNB"'=tFirstSeg, "UNE":"UNG"'=tFirstSeg, "UNT":"UNH"'=tFirstSeg, "UNP":"UNO"'=tFirstSeg, "UIZ":"UIB"'=tFirstSeg, "UIT":"UIH"'=tFirstSeg, :0) { ; UNZ,UNE,UNT,UNP,UIZ,UIT are normal end segs for Batch groups
				Set tSegName="" ; pop up if we see an out-of-context segment
				Quit
			} ElseIf $Case(tSegName,"UNB":1,"UNG":1,"UNH":1,"UNO":1,"UIB":1,"UIH":1,:0) { ; UNB,UNG,UNH,UNO,UIB,UIH should not appear within after position 1
				$$$LOGWARNING(tSegName_" segment "_tSegNum_" found not at start of document "_tDoc.%Id()_"; at "_tDocPos_" ("_tLine_")")
			}
			#; Store the data for the segment, reading more lines if it's >32k
			Set tChunk=0
			While ((""'=tLine) || 'pIOStream.AtEnd) {
				#; Get new text; discard leading whitespace - this has the effect of removing Whitespace between segments while preserving Whitespace within them
				If ""=tLine {
					Set tTimedOut=0  While 'pIOStream.AtEnd {
						Kill tZB  Set tTimeout=..ReadTimeout, tLine=tLine_pIOStream.ReadLine(32767-5-$L(tLine),.tTimeout,.tSC,.tZB)  ; No Quit; will break at end of loop
						Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout)), tComplete=(""'=tZB)
					    If $E($Replace(tLine,tEscapeSeparator_tEscapeSeparator,""),*)=tEscapeSeparator && (tZB=tSegTerminator) Set tLine=tLine_tZB, tComplete=0  Continue:'$$$ISERR(tSC)
						Set:""'=tLine||tComplete ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)+$L(tZB)
						If ""'=tLine $$$catTRACE("parse","Got segment line #"_..%LineCount_" '"_tLine_"'")
						
						#; Strip whitespace; quit if we got the line terminator, unless the line consisted only of whitespace
						Quit:..Whitespace=""
						Set tLine=..StripWhitespace(tLine)
						Quit:tTimedOut||$$$ISERR(tSC)||(""'=tLine&&tComplete)
					}
					Set:tTimedOut&&$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)
					If tLine=""||$$$ISERR(tSC) { Set tSC=$$$ERROR($$$EnsEDIEDIFACTUnexpectedEOD,tLine,$$$StatusDisplayString(tSC),tDocPos), tLine=""  Quit }
					$$$catTRACE("parse","Got segment line #"_..%LineCount_" '"_tLine_"'")
				}
				If (tChunk=0) {
					#; Store the data for the first chunk at top node
					Set tIndex=tJK_","_$I(%topSegIndex)
					Set $$$vaSegment(tIndex)=..Separators_tLine
					Set $$$vaOpenSegmentPPG(tIndex) = 1
					Set $$$vaSegmentExt(tIndex,"term")=tSegTerminator
					Set tLine="", ..%SegmentCount=..%SegmentCount+1, tSegNum=tSegNum+1, tUNOSegs=tUNOSegs-1
					Set $$$vaMobj(tDoc,"runtimeIndex")=$$$vaMobj(tDoc,"runtimeIndex")+1, $$$vaMobja(tDoc,"runtimeIndex",$$$vaMobj(tDoc,"runtimeIndex"))=tIndex
					Set tChunk=1
				} Else { ; Other Chunks go in subnodes
					Set $$$vaSegmentExt(tIndex,tChunk-1)=tLine, tLine="", tChunk=tChunk+1
				}
				Quit:tComplete
			} Quit:$$$ISERR(tSC)
			
			#; Add the child count to the reference placeholder segment - if we are on the next segment after the group
			If tPrevSeg["DocsRef" {
				Set tSubscx=tSubsc_""""_tDoc.%Id()_":"_..%CurrentParentSegIndex_""""
				Set tRefx="..%NumChildren("_tSubscx_")"
				Set $$$vaSegment(iRefSegId)=$$$vaSegment(iRefSegId)_$G(@tRefx)
			}
			Quit:$Case(tSegName, "UNZ":"UNB"=tFirstSeg, "UNE":"UNG"=tFirstSeg, "UNT":"UNH"=tFirstSeg, "UNP":"UNO"=tFirstSeg, "UIZ":"UIB"=tFirstSeg, "UIT":"UIH"=tFirstSeg, :0)
		} Quit:$$$ISERR(tSC) ; done doc
		
		#; Add the child count to the reference placeholder segment - if the file ended in the child document
		If tSegName["DocsRef" {
			Set tSubscx=tSubsc_tDoc.%Id()_","
			Set tRefx="..%NumChildren("_tSubscx_""""_$P(tSegName,"DocsRef")_""")"
			Set $$$vaSegment(iRefSegId)=$$$vaSegment(iRefSegId)_$G(@tRefx)
		}
		#; Save if child or re-save if has children
		If $G(%topSegIndex) Set $$$vaSegmentGbl(tJK)=%topSegIndex  Kill %topSegIndex ; commit ahead of %Save() and callbacks
		If $IsObject(tParentDoc)||$D(..%NumChildren) Do tDoc.%SetModified(1)  Set tSC1=tDoc.%Save()  Quit:$$$ISERR(tSC1) // Fatal Error
		Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level "_tLevels_", @Line "_..%LineCount
		Set tSC1=..%ServiceInterface.OnDocumentEnd(tDoc,tDocPos,tSC1)  Quit:$$$ISERR(tSC1) // Fatal Error
		
		#; Let the Service know we are done processing an interchange, giving an opportunity to 'filter'
		#; extraneous header/trailer/filler which may be present in the stream.
		#; tLine contains any extra chars read that may be part of the beginning of the interchange.
		#; On exit, tLine must not be longer than 9 bytes, and it must not omit any terminator characters
		#; between its end and what will next be read from pIOStream
		#; Check for End-Of-File; return the next potential fixed-length ISA segment if found
		Set tSC1=..%ServiceInterface.OnPostDocument(pIOStream,.tLine)
	} While 0
	Set:$$$ISERR(tSC1)&&(tSC'=tSC1) tSC=$$$ADDSC(tSC,tSC1)
	Set ..%LookaheadLine=tLine
	Set ..%LookaheadLineTerminator=$S(""=tLine:"",1:tZB)
	If $IsObject(tDoc) {
		Set ..%CurrentDocument=$G(..%CurrentParents(..%CurrentParents),$$$NULLOREF)
		Kill ..%CurrentParents(..%CurrentParents)
		Set ..%CurrentParents=..%CurrentParents-1
		$$$ASSERT('$IsObject(..%CurrentDocument)||(..%CurrentDocument.%Id()=$P($LI(..%ParentIds),":")))
		Set ..%ParentIds=$LI(..%ParentIds,2,$LL(..%ParentIds))
		Set pDocument=tDoc
		If $G(%topSegIndex) Set $$$vaSegmentGbl(tJK)=%topSegIndex  Kill %topSegIndex ; commit before exit
	}
	Set ..%CurrentParentSegIndex=tParentDocPos
	Quit tSC
}

Method readBinary(tDoc As EnsLib.EDI.EDIFACT.Document, pBytes As %Integer, pLine As %String, tDataElementSeparator As %String, tSegTerminator As %String, Output pSC As %Status) As %String [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	Do {	
		#; Get an index for the data
		Set tJK=$$$JobKey
		Set:'$D(%topSegIndex) %topSegIndex=$G($$$vaSegmentGbl(tJK)), tNoTop=1
		Set tIndex=tJK_","_$I(%topSegIndex), $$$vaSegment(tIndex)="BinRef", $$$vaOpenSegmentPPG(tIndex) = 1, $$$vaSegmentExt(tIndex,"term")=tSegTerminator
		Set $$$vaMobj(tDoc,"runtimeIndex")=$$$vaMobj(tDoc,"runtimeIndex")+1, $$$vaMobja(tDoc,"runtimeIndex",$$$vaMobj(tDoc,"runtimeIndex"))=tIndex
		
		If '$IsValidNum(pBytes) { Set pSC=$$$ERROR($$$EnsEDIEDIFACTBadBINLength,$A(tDataElementSeparator),pBytes) Quit }

		If pBytes>$L(pLine) {
			Set tPrefix=pLine, pLine=""
		} Else {
			Set tPrefix=$E(pLine,pBytes), $E(pLine,1,pBytes)=""
		}
	//	Set tPrefix=..Separators_$E(pLine,1,tPrefixLen), tData=$E(pLine_pZB,tPrefixLen+1,tPrefixLen+pBytes), tLeftover=$E(pLine,tPrefixLen+pBytes+1,*)

		Set tRemaining=pBytes-$L(tPrefix)
		Set tI=1  While tRemaining>0 && '..%Stream.AtEnd {
			Set tChunk=32767-($L(tPrefix)+$L(tData))
			Set:tChunk>tRemaining tChunk=tRemaining
			Set tData=tData_..%Stream.Read(.tChunk)
			Set tRemaining=tRemaining-tChunk
			If tRemaining<=0||..%Stream.AtEnd||($L(tPrefix)+$L(tData)>=32767) {
				If tI=1 {
					Set $$$vaSegment(tIndex)=tPrefix_tData, (tPrefix,tData,pLine)=""
				} Else {
					Set $$$vaSegmentExt(tIndex,tI-1)=tData, tData=""
				}
				Set tI=tI+1
			}
		}
		Set $$$vaSegmentGbl(tJK)=%topSegIndex Kill:$G(tNoTop) %topSegIndex
		If ..%Stream.AtEnd { Set tSC=$$$ERROR($$$EnsEDIEDIFACTUnexpectedEODBinary,tData)  Quit }
		#; Read the final segment terminator - should not get any more data
		If ""'=tLeftover { Set pLine=tLeftover }
		Else { Set tZB="" }
	} While 0
Exit
	Quit tExtra
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..%ServiceInterface=initvalue
	Do ..Reset()
	Quit $$$OK
}

/// Strip off leading whitespace from the line
Method StripWhitespace(pLine As %String) As %String
{
	For i=1:1 { Quit:i>$L(pLine)||(..Whitespace'[$E(pLine,i)) }
	Quit $E(pLine,i,*)
}

Method Reset()
{
	Set (..%LookaheadLine,..%LookaheadLineTerminator,..%LookaheadLineIsNew)=""
	Do ..ResetPosition()
	Set (..Separators,..SegmentTerminator)=""
	Set ..%Stream =$$$NULLOREF
}

Method ResetPosition()
{
	Kill ..%CurrentParents,..%NumChildren
	Set (..%CurrentParents,..%NumChildren,..%SegmentCount,..%LineCount,..%CharCount)=0
	Set:""'=..%LookaheadLine||(""'=..%LookaheadLineTerminator) ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(..%LookaheadLine)+$L(..%LookaheadLineTerminator)
	Set ..%CurrentDocument=$$$NULLOREF
	Set ..%ParentIds=""
}

}
