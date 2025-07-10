/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

/// This is the X12 Interchange parser
Class EnsLib.EDI.X12.Parser Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Number of seconds to wait for the start of a document to be available on the input stream
Property StartTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 5 ];

/// Number of seconds to wait for each read of document data inside a started document to be available on the input stream
Property ReadTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 5 ];

/// Default Character Encoding to use when reading or writing X12 Documents. <p/>
/// Choices you can use for this setting include:<p/>
/// <ul>
/// <li>Native - use the default character encoding of the installed locale of the InterSystems IRIS server</li>
/// <li>latin1 - the ISO Latin1 8-bit encoding; this is the default</li>
/// <li>ISO-8859-1 - the ISO Latin1 8-bit encoding</li>
/// <li>UTF-8 - the Unicode 8-bit encoding</li>
/// <li>Unicode - the Unicode 16-bit encoding  (Little-Endian)</li>
/// <li>UnicodeBig - the Unicode 16-bit encoding (Big-Endian)</li>
/// <li>Any other NLS definitions installed on this InterSystems IRIS server</li>
/// <li>@&lt;ttable&gt; - &lt;ttable&gt; means a raw InterSystems character translation table name. A prefix of '@' means to use the named table.</li>
/// </ul>
Property DefCharEncoding As %String(MAXLEN = 20) [ InitialExpression = "latin1" ];

/// This property controls the skipping of whitespace in the data stream. Set it to a string of characters that should be 
/// considered whitespace and not part of the data
Property Whitespace As %String;

/// This remembers separators defined in the ISA, but you can pre-set it to read TransactionSets without an ISA
Property Separators As %String(MAXLEN = 3, MINLEN = 3);

/// This remembers the terminator defined in the ISA, but you can pre-set it to read TransactionSets without an ISA
Property SegmentTerminator As %String(MAXLEN = 1, MINLEN = 1);

/// This allows you to pre-set a ControlVersion to use when reading TransactionSets without an ISA or GS
Property ControlVersion As %String(MAXLEN = 5);

/// See your X12 Config Items for a description of accepted values.
Property Framing As %String;

/// Set this if you want to make an interface that is set to Framing='Flexible' continue with the Framing style it detects in the first message it receives.
/// This can increase performance, reduce latency due to timeouts and ensure consistent behavior after initialization.
/// However, it will also reduce the ability of the interface to interpret changing input formats in successive messages from the same source or from different sources on sequential connections.
Property RememberFlex As %Boolean [ InitialExpression = 0 ];

Property Done As %Boolean [ Calculated, ReadOnly ];

/// Should the parser skim the rest of the current batch without notifying us of any further child documents?
/// Gets automatically cleared when the end of each top-level document is encountered
Property FinishBatch As %Boolean;

// Private State Properties

Property %Stream As %IO.I.CharacterStream;

/* Implementation Notes:
    The properties ..%inFraming and ..%outFraming represent a parse of the ..Framing Setting value, and if it is 'Flexible' they represent the
     memory of the detected framing style.
    The local variables tInFraming or tOutFraming, tPrefix and tSuffix represent a decomposition of ..%inFraming or ..%outFraming.
    The composed form is [<prefix>][x<suffix>][xx<framing>]. <framing> can be "f" for 'flexible'. Thus for example standard MLLP framing is
     represented by ..%inFraming=$C(11)_"x"_$C(28,13) while AsciiLF framing is "x"_$C(10) and 'None' is represented by "".
*/
/// pre-parse of Framing setting
Property %inFraming As %String;

/// Framing to use on output if input framing is "Flexible"
Property %outFraming As %String;

/// Lookahead line left over from previous document parse
Property %LookaheadLine As %String;

/// Flag for whether lookahead buffer has had input conversion yet
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

/// Parse a complete X12 interchange document from the stream, including any nested TransactionSet documents inside it.
/// An Interchange contains zero or more functional groups which in turn contain TransactionSets.
Method ParseIOStream(pIOStream As %IO.I.CharacterStream, Output pDocument As EnsLib.EDI.X12.Document, ByRef pControlVersion As %String = "", pInbound As %Boolean = 0, pFramed As %Boolean = 0, pDefaultRepSep As %String = "", pDefaultCompSep As %String = "", pDefaultSegTerminator As %String = "") As %Status
{
#define MapCtlChars(%s)	$TR(%s,$C(1,2,3,9,10,11,13,28),"123tlsre")
	#dim tDataElementSeparator,tComponentSeparator,tRepetitionSeparator,tSegTerminator As %String = ""
	#dim tParseError As %Status = $$$OK

	$$$ASSERT($IsObject(pIOStream))
	Set pDefaultRepSep=$E(pDefaultRepSep)
	Set:pDefaultRepSep?1(1A,1N) pDefaultRepSep=""
	Set pDefaultCompSep=$E(pDefaultCompSep)
	Set:pDefaultCompSep?1(1A,1N) pDefaultCompSep=""
	Set pDefaultSegTerminator=$E(pDefaultSegTerminator)
	Set:pDefaultSegTerminator?1(1A,1N) pDefaultSegTerminator=""

	If (""=$G(pDocument)) || $IsObject(pDocument) { Set tDocClass="EnsLib.EDI.X12.Document" }
	Else { Set tDocClass=pDocument }
	Set (tSC,tSC1)=$$$OK, (pDocument,tDoc)=$$$NULLOREF, ..%Stream=pIOStream, tLine=..%LookaheadLine, tZB="", tExtra=""
	Set:..SegmentTerminator=$E(tLine,*) $E(tLine,$L(tLine))="", tZB=..SegmentTerminator
	Set tParentDoc=..%CurrentDocument, tParentDocPos=..%CurrentParentSegIndex, tGSControlVersion=""
	If ""'=tLine {
		If ..%LookaheadLineIsNew {
			If ""'=$E(..DefCharEncoding) { ; fix line encoding if forced charset
				Set tEnc=$E(..DefCharEncoding,2,*)  If tEnc'=pIOStream.CharEncoding {
					Set tTab=##class(%IO.I.TranslationDevice).GetCharEncodingTable(tEnc)
					If tTab'=""&&(tTab'=##class(%IO.I.TranslationDevice).GetCharEncodingTable(pIOStream.CharEncoding)) {
						Set pIOStream.CharEncoding=tEnc
						Set tLine=$ZCVT(tLine,"I",tTab)
					}
				}
			}
			Set ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)
			Set ..%LookaheadLineIsNew=0
		}
		Set tStartTimeout=..ReadTimeout
	} Else { Set tStartTimeout=..StartTimeout }
	Do { ; While 0
		#; Process any preceding stuff in the stream

		#; Let the interface event handler know we are about to process an interchange
		#; giving an opportunity to 'filter' extraneous header/trailer/filler which
		#; may be present in the stream.
		#; tLine contains any extra chars read that may be part of the beginning of the interchange.
		#; On exit, tLine must not be longer than 106 bytes, and it must not omit any terminator characters
		#; between its end and what will next be read from pIOStream
		Set tSC=..%ServiceInterface.OnPreDocument(pIOStream,.tLine)  Quit:$$$ISERR(tSC)||(""=tLine&&pIOStream.AtEnd)

		#; Count the documents we encounter, nested
		If $IsObject(tParentDoc) {
			#; child document
			Set tParentRef=tParentDoc.getId()_":"_tParentDocPos, tParentIds=$LB(tParentRef)_..%ParentIds
			Set tSubsc="",tLevels=1+$LL(tParentIds)  For i=1:1:tLevels-1  Set tSubsc=""""_$LI(tParentIds,i)_""","_tSubsc
			Set tRef=$S(""=tSubsc:"..%NumChildren",1:"..%NumChildren("_$E(tSubsc,1,*-1)_")")
			Set tLevelDocs=$G(@tRef)+1

			Set tDataElementSeparator=$$$ELESEP(..Separators), tSegTerminator=..SegmentTerminator
			#; Segment Terminator was added as the first character of the %LookaheadLine prior to recursive call to ParseIOStream if tExtra not ""
			Set:tSegTerminator=$E(tLine) tExtra=$P(tLine,tSegTerminator,3,*)_tZB, tLine=$P(tLine,tSegTerminator,2)
			Set (tSegName,tFirstSeg)=$P(tLine,tDataElementSeparator)
			//Set tComplete=1
		} Else {
			Set (tParentRef,tParentIds)="", tSubsc="", tLevels=1, tRef="..%NumChildren", tLevelDocs=$G(..%NumChildren)+1

			#; Set flags to keep track of what is seen in an Interchange
			Set (tTA1Seen,tNumGroups,..%SegmentCount)=0

			#; Find the next potential fixed-length ISA segment
			Set tLine=tLine_tZB, tZB=""
			Set tIsNew=(""=tLine)
			For {
				Set:""'=..Whitespace tLine=..StripWhitespace(tLine)
				Quit:$L(tLine)>=106||pIOStream.AtEnd
				$$$catTRACE("parse","Beginning header read("_(106-$L(tLine))_") for 106-byte header with timeout "_tStartTimeout_" on "_pIOStream.Name)
				Set tTimeout=tStartTimeout, tFresh=pIOStream.Read(106-$L(tLine),.tTimeout,.tSC), tLine=tLine_tFresh
				Set tTimedOut=(tStartTimeout&&(tTimeout=tStartTimeout))
				Set ..%CharCount=..%CharCount+$L(tFresh)
				If tTimedOut&&$$$ISOK(tSC) {
					Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level 1, @Line "_..%LineCount
					Set tSC=$$$ERROR($$$EnsErrTCPReadTimeoutExpired,tStartTimeout,"106-char header","binary")
				}
				Quit:$$$ISERR(tSC)
				Set tStartTimeout=..ReadTimeout ; already started so go to read mode
			}
			Quit:""=tLine||$$$ISERR(tSC)||(""'=..Whitespace&&(""=..StripWhitespace($ZStrip(tLine,"<W"))))
			Set:tIsNew ..%LineCount=..%LineCount+1
			Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level 1, @Line "_..%LineCount

			Set tDataElementSeparator=$E($ZStrip(tLine,"<AN"))
			Set (tSegName,tFirstSeg)=$P(tLine,tDataElementSeparator)
			If "ISA"=tSegName {
				#; new ISA - Validate/Record the Separators/Terminator
				Set tISALine=$P(tLine,tDataElementSeparator,1,16)
				While ($L(tISALine,tDataElementSeparator) < 16) || ($L(tLine) < ($L(tISALine)+3)) {
					Quit:pIOStream.AtEnd
					$$$catTRACE("parse","Continuing read for header with timeout "_tStartTimeout_" on "_pIOStream.Name)
					Set tTimeout=tStartTimeout, tFresh=pIOStream.Read(10,.tTimeout,.tSC), tLine=tLine_tFresh
					Set tTimedOut=(tStartTimeout&&(tTimeout=tStartTimeout))
					Set ..%CharCount=..%CharCount+$L(tFresh)
					If tTimedOut&&$$$ISOK(tSC) {
						Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level 1, @Line "_..%LineCount
						Set tSC=$$$ERROR($$$EnsErrTCPReadTimeoutExpired,tStartTimeout,"header","binary")
					}
					Quit:$$$ISERR(tSC)
					Set:""'=..Whitespace tLine=..StripWhitespace(tLine)
					Set tISALine=$P(tLine,tDataElementSeparator,1,16)
				}
				Quit:$$$ISERR(tSC)
				
				If $L(tISALine,tDataElementSeparator) < 16 {
					#; Then we quit because pIOStream.AtEnd was true
					Set tSC=$$$ERROR($$$EnsEDIX12ISATruncated,$L(tLine),tLine,tDocPos)
					Set tRepetitionSeparator=$P(tLine,tDataElementSeparator,12)
					Set:tRepetitionSeparator?1(1A,1N)||(tRepetitionSeparator=tDataElementSeparator) tRepetitionSeparator=""
					Set tLine=""
					Quit
				}
				Set tExtra=..StripWhitespace($E(tLine,$L(tISALine)+4,*))
				Set tLine=$E(tLine,1,$L(tISALine)+3) ; ES,CS,Terminator
				Set tSegTerminator=$E(tLine,$L(tISALine)+3)
				
				Set tComponentSeparator= $E(tLine,$L(tISALine)+2)
				If tComponentSeparator?1(1A,1N)||$Case(tComponentSeparator,tDataElementSeparator:1,tSegTerminator:1,:0) {
					Set tParseError = $$$ADDSC(tParseError,$$$ERROR($$$EnsEDIX12InvalidComponentSeparator,$A(tComponentSeparator),tLine,tDocPos))
					Set tComponentSeparator=$Select($Case(pDefaultCompSep,"":0,tDataElementSeparator:0,tSegTerminator:0,:1):pDefaultCompSep,1:$Case($$$X12DefComponentSeparator,tDataElementSeparator:$C(17),:$$$X12DefComponentSeparator))
					Set $E(tLine,$L(tISALine)+2)=tComponentSeparator
				}
				
				#; In Control Version 00403 and higher, ISA 11 is defined as I65 (Repetition Separator) instead of I10 (Interchange Control Standards Identifier / "U")
				Set pControlVersion=$Piece(tLine,tDataElementSeparator,13)
				Set tRepetitionSeparator=$P(tLine,tDataElementSeparator,12)
				If tRepetitionSeparator?1(1A,1N)||$Case(tRepetitionSeparator,tComponentSeparator:1,tDataElementSeparator:1,tSegTerminator:1,:0) {
					Set:tRepetitionSeparator'?1(1A,1N) $P(tLine,tDataElementSeparator,12)="U"
					If (pControlVersion>=403) {
						Set tParseError = $$$ADDSC(tParseError,$$$ERROR($$$EnsEDIX12InvalidRepetitionSeparator,$A(tRepetitionSeparator),tLine,tDocPos))
						If $Case(pDefaultRepSep,"":0,tDataElementSeparator:0,tComponentSeparator:0,tSegTerminator:0,:1) {
							Set $P(tLine,tDataElementSeparator,12)=pDefaultRepSep
						}
					}
					Set tRepetitionSeparator=$Select($Case(pDefaultRepSep,"":0,tDataElementSeparator:0,tComponentSeparator:0,tSegTerminator:0,:1):pDefaultRepSep,1:$Case($$$X12DefRepetitionSeparator,tComponentSeparator:$C(18),tDataElementSeparator:$C(18),:$$$X12DefRepetitionSeparator))
				}
				
				If tSegTerminator?1(1A,1N) {
					Set tSC=$$$ERROR($$$EnsEDIX12InvalidSegmentTerminator,$A(tSegTerminator),tLine,tDocPos)
					#; Didn't find an appropriate segment terminator in the document. Use supplied default if not already used as one of the other separators.
					#; Otherwise use ~, or CRLF if ~ is being used as one of the other separators
					#; This applies only to the reply document, since processing of the original terminates here
					Set tSegTerminator = $Select($Case(pDefaultSegTerminator,"":0,tDataElementSeparator:0,tComponentSeparator:0,tRepetitionSeparator:0,:1):pDefaultSegTerminator,1:$Case($$$X12DefSegTerminator,tDataElementSeparator:$C(13,10),tComponentSeparator:$C(13,10),tRepetitionSeparator:$C(13,10),:$$$X12DefSegTerminator))
					Set tLine=""
					Quit
				}
				Set ..SegmentTerminator=tSegTerminator, pIOStream.LineTerminator=tSegTerminator
				Set $E(tLine,*)="" ; remove the terminator from the stored segment

				#; At this point the separators are valid;  further processing can continue
				$$$catTRACE1Sub("parse","Got ISA header line #"_..%LineCount_" '%1'",tLine)
				Set tComplete=1
			} Else {
				#; not ISA
				If $Case(tSegName,"GS":0,"ST":0,"TA1":0,:1) {
					Set tSC=$$$ERROR($$$EnsEDIX12ExpectedSegment,"ISA",tLine,tDocPos), tLine=""
					Quit
				}
				// Find SegmentTerminator - if not prescribed, try last non-alphanumeric char before newline
				If ""'=..SegmentTerminator {
					Set tSegTerminator=$E(..SegmentTerminator)
				} Else {
					If ..Whitespace'=$TR(..Whitespace,$C(13,10)) {
						Set fr=$F(tLine,$C(13)), fn=$F(tLine,$C(10))  Set:fn>fr&&fr fn=fr
					} Else { Set fn=0 }
					If fn {
						If $E(tLine,fn-2)'?1(1A,1N) Set tSegTerminator=$E(tLine,fn-2)
						Else  Set tSegTerminator=$E(tLine,fn-1)
					} Else {
						Set tSegTerminator= $Select($Case(pDefaultSegTerminator,"":0,tDataElementSeparator:0,:1):pDefaultSegTerminator,1:$Case($$$X12DefSegTerminator,tDataElementSeparator:$C(13,10),:$$$X12DefSegTerminator))
 					}
				}
				Set pIOStream.LineTerminator=tSegTerminator, ..SegmentTerminator=tSegTerminator
				Set tSegLine=$P(tLine,tSegTerminator)
				If tSegLine'=tLine {
					Set tExtra=..StripWhitespace($E(tLine,$L(tSegLine)+2,*)), tLine=tSegLine, tZB=tSegTerminator, tComplete=1, ..%LineCount=..%LineCount+1
				} Else { ; finish the segment now that we have an assumed terminator
					If 'pIOStream.AtEnd {
						Kill tZB  Set tTimeout=..ReadTimeout, tLine=tLine_pIOStream.ReadLine($$$X12MaxReadLen-$L(tLine),.tTimeout,.tSC,.tZB)  ; No Quit; will break at end of loop
						Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout)), tComplete=(""'=tZB)
						Set:""'=tLine||tComplete ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)+$L(tZB)
					} Else { Set tTimedOut=0 }
					Set:tTimedOut&&$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)
					If tTimedOut&&$$$ISOK(tSC) { Set tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)  Quit }
					ElseIf $$$ISERR(tSC) { Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEOD,tLine,$$$StatusDisplayString(tSC),tDocPos), tLine=""  Quit }
				}
				$$$catTRACE1Sub("parse","Got start segment line #"_..%LineCount_" '%1'",tLine)
				Set tComponentSeparator=$$$COMSEP(..Separators)
				If ""=tComponentSeparator {
					Set tComponentSeparator=$Select($Case(pDefaultCompSep,"":0,tDataElementSeparator:0,:1):pDefaultCompSep,1:$Case($$$X12DefComponentSeparator,tDataElementSeparator:$C(17),:$$$X12DefComponentSeparator))

				}
				Set tControlVersion=$S("GS"=tSegName:"00"_+$P(tLine,tDataElementSeparator,9), ""'=pControlVersion:pControlVersion, 1:..ControlVersion)
				Set:0=$E(tControlVersion,*) tControlVersion=$E(tControlVersion,1,*-1)
				Set:'+tControlVersion tControlVersion=$$$X12DefControlVersion
				Set tRepetitionSeparator=$$$REPSEP(..Separators)
				If ""=tRepetitionSeparator {
					Set tRepetitionSeparator=$Select($Case(pDefaultRepSep,"":0,tDataElementSeparator:0,tComponentSeparator:0,:1):pDefaultRepSep, tControlVersion<403:$C(0), 1:$Case($$$X12DefRepetitionSeparator,tComponentSeparator:$C(18),tDataElementSeparator:$C(18),:$$$X12DefRepetitionSeparator))
				}
			}
			Set ..Separators=tDataElementSeparator_tComponentSeparator_tRepetitionSeparator
			#; finish the extra line (if any) out to the next terminator
			If ""'=tExtra && 'pIOStream.AtEnd {
				Kill tZB  Set tTimeout=..ReadTimeout, tExtra=tExtra_pIOStream.ReadLine($$$X12MaxReadLen-$L(tLine),.tTimeout,.tSC,.tZB)_tZB  ; No Quit; will break at end of loop
				Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout))
				If tTimedOut&&$$$ISOK(tSC) { Set tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tExtra)  Quit }
				ElseIf $$$ISERR(tSC) { Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEOD,tExtra,$$$StatusDisplayString(tSC),tDocPos), tExtra=""  Quit }
			}
		}
		#; Store the data for the first segment
		If '$IsObject(tParentDoc) || '..FinishBatch {
			Set tIndex=$I($$$vaSegmentGbl), $$$vaSegmentGbl(tIndex)=..Separators_tLine, tLine="",tZB="", ..%SegmentCount=..%SegmentCount+1
			Set $$$vaOpenSegmentPPG(tIndex)=1
			Set $$$vaSegmentGbl(tIndex,"term")=tSegTerminator

			#; Instantiate a document to hold the segment and any to follow
			Set tDocPos=$S(""=tParentIds:pIOStream.Name,1:"")_$S(..%LineCount<=2:"", 1:$C(13,10)_" Document# "_tLevelDocs_", level "_tLevels_", @Line "_..%LineCount)
			Set tDoc=##class(EnsLib.EDI.X12.Document).%New($LB($LB(tIndex),..Separators_tSegTerminator,tDocPos,tParentRef))  If '$IsObject(tDoc) Set tSC=%objlasterror Quit
			If $IsObject(tParentDoc) {
				Set ..%CurrentParents=..%CurrentParents+1, ..%CurrentParents(..%CurrentParents)=tParentDoc
				Set ..%ParentIds=tParentIds
			}
			Set ..%CurrentDocument=tDoc, tSegNum=2 ; tSegNum is current segment of current document

			#; Count the documents we encounter, nested
			Set tTypeName=tDoc.Name  Set:""=tTypeName tTypeName="?"
			Set tReft="..%NumChildren("_tSubsc_""""_tTypeName_""")"
			Set tLevelTypeDocs=$G(@tReft)+1
			Set @tRef=tLevelDocs, @tReft=tLevelTypeDocs

			#; Notify the Service of the new document beginning
			Set tSC1=..%ServiceInterface.OnDocumentStart(tDoc,tDocPos,tSC)  Quit:$$$ISERR(tSC1) // Fatal Error
		}

		#; Parse the rest of the segments in the current document
		#;$$$catTRACE("parse","+ %CurrentParents="_..%CurrentParents_", tDoc="_$G(tDoc)_", tParentDoc="_tParentDoc)
		Set (iRef,iRefSegId)=0, (tPrevSeg,tWhite)=""
		While $$$ISOK(tSC)&&(tLine_tExtra'=""||'pIOStream.AtEnd) { ; loop over segs in the doc
			If ""=tLine&&(""'=tExtra) {
				Set tLine=$P(tExtra,tSegTerminator), tZB=$S(tSegTerminator=$E(tExtra,1+$L(tLine)):tSegTerminator,1:""), tComplete=(""'=tZB)
				Set tExtra=$E(tExtra,$L(tLine)+2,*)
				Set:""'=(tLine_tZB) ..%LineCount=..%LineCount+1
				Set tLine1=tLine, tLine=..StripWhitespace(tLine)
				Set:""=tPrevSeg&&(tLine1'=tLine) tWhite=$E(tLine1,1,$L(tLine1)-$L(tLine))
				$$$catTRACE3Subs("parse","Using pre-fetched segment line #"_..%LineCount_" '%1'", ($E($$$MapCtlChars(tLine1),1,$$$MaxLocalLength-2)_"%2") , ", extra='%3'" , $$$MapCtlChars(tExtra))
			}
			If ""=tLine {
				#; Get new text; discard leading whitespace - this has the effect of removing Whitespace between segments while preserving Whitespace within them
				Set tTimedOut=0  While 'pIOStream.AtEnd {
					Kill tZB  Set tTimeout=..ReadTimeout, tLine=tLine_pIOStream.ReadLine($$$X12MaxReadLen-$L(tLine),.tTimeout,.tSC,.tZB)  ; No Quit; will break at end of loop
					Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout)), tComplete=(""'=tZB)
					Set:""'=tLine||tComplete ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)+$L(tZB)
					#; Strip whitespace; quit if we got the line terminator, unless the line consisted only of whitespace
					Quit:..Whitespace=""
					Set tLine1=tLine, tLine=..StripWhitespace(tLine)
					Set:""=tPrevSeg&&(tLine1'=tLine) tWhite=$E(tLine1,1,$L(tLine1)-$L(tLine))
					Quit:tTimedOut||$$$ISERR(tSC)||(""'=tLine&&tComplete)
					#; Avoid infinite loop
					Quit:($L(tLine)=$$$X12MaxReadLen)
					#;Quit if reading loop if binary data stream
					If ($Piece(tLine,tDataElementSeparator)="BDS")|| ($Piece(tLine,tDataElementSeparator)="BIN") Quit
				}
				If tTimedOut&&$$$ISOK(tSC) { Set tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)  Quit }
				ElseIf tLine=""||$$$ISERR(tSC) {
					Set:(""=tLine)&&$IsObject(tDoc) tLine=tDoc.GetValueAt(tSegNum-1) ; display the previous segment in the error text
					Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEOD,tLine,$S($$$ISERR(tSC):$$$StatusDisplayString(tSC),1:""),tDocPos)
					Set tLine=""
					Quit
				}
				$$$catTRACE1Sub("parse","Got next segment line #"_..%LineCount_" '%1'",tLine)
			}
			Set:""=tPrevSeg tDoc.Separators=tDoc.Separators_$ZSTRIP(tWhite,"<>W") ; append found whitespace from second segment to Separators / SegTerminator of the document
			Set tPrevSeg=tSegName, tSegName=$P(tLine,tDataElementSeparator)
			Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level "_tLevels_", segment "_tSegNum_", @Line "_..%LineCount
			If '$$$X12ValidSegName(tSegName) {
				Set tSC=$$$ERROR($$$EnsEDIX12InvalidSegmentName,tSegName,tLine,tDocPos), tLine=""
				Quit
			}
			#; Drill down & start a new doc, pop up, or keep adding segments to the current doc
			If $Case(tSegName,"GS":1, "ST":1, :0) { ; drill down
				Set tGroupName=$Case(tSegName,"ST":"TransactionSetDocsRef", "GS":"GroupDocsRef", :tSegName_"DocsRef")
				If tPrevSeg'=tGroupName {
					If "GS"=tSegName {
						If $Case(tPrevSeg,"ISA":0,"TA1":0,:1)  {
							$$$LOGSTATUS($$$ERROR($$$EnsEDIX12InvalidSegmentType,tSegName,tPrevSeg,tDocPos))
						}
						Set tNumGroups=tNumGroups+1
					} Else {
						#; Seg name is ST
						If "GS"'=tPrevSeg {
							If $IsObject(tParentDoc) && (tParentDoc.Name = "Group") {
								#; This appears to be the start of a new Transaction Set, but the previous TS is missing its SE segment
								$$$LOGSTATUS($$$ERROR($$$EnsEDIX12ExpectedSegment,"SE",tLine,tDocPos))
								Set:""'=tExtra tLine = tLine_tSegTerminator_tExtra
								Set tSegName=""
								Quit
							} ElseIf $IsObject(tDoc) && (tDoc.Name = "Interchange") {
								#; This appears to be the start of a new Transaction Set, but the GS is missing...
								Set tSC = $$$ERROR($$$EnsEDIX12ExpectedSegment,"GS",tLine,tDocPos)
								Quit
							}

							$$$LOGSTATUS($$$ERROR($$$EnsEDIX12InvalidSegmentType,tSegName,tPrevSeg,tDocPos))
						}
						Set ..TransactionSetCount=..TransactionSetCount+1, ..%SegmentCount=1
					}
					#; Create a placeholder segment for the child document(s)
					Set tIndex=$I($$$vaSegmentGbl)
					Set iRef=$$$vaMobj(tDoc,"runtimeIndex")+1, iRefSegId=tIndex, tSegNum=tSegNum+1
					Set $$$vaSegmentGbl(tIndex)=..Separators_tGroupName_tDataElementSeparator_iRef_tDataElementSeparator
					Set $$$vaOpenSegmentPPG(tIndex)=1
					Set $$$vaSegmentGbl(tIndex,"term")=tSegTerminator
					Set $$$vaMobj(tDoc,"runtimeIndex")=iRef, $$$vaMobja(tDoc,"runtimeIndex",iRef)=tIndex
					Set ..%CurrentParentSegIndex=iRef
				}
				Set tPrevSeg=tSegName, tSegName=tGroupName
	
				#; parse the nested child document
				Set tSC=tDoc.%Save()  Quit:$$$ISERR(tSC) ; save the doc-in-progress so children will have access to its content.
				Set ..%LookaheadLine=tLine_tZB
				Set:""'=tExtra ..%LookaheadLine=tSegTerminator_tLine_tSegTerminator_tExtra, tExtra=""
				Set tSC=..ParseIOStream(pIOStream,,$S(""=tGSControlVersion:pControlVersion, 1:tGSControlVersion),pInbound)
				Set tLine=..%LookaheadLine
				If $Case($P(tLine,tDataElementSeparator),"GS":1, "ST":1,"GE":1,"IEA":1, :0)&&($E(tLine,*)=tZB) {
					#; We will end up looping back to this ParseIOStream() and want to avoid repeated line ending characters
					Set tLine = $E(tLine,1,*-1)
				}
				Quit:$$$ISERR(tSC)
				Continue
			} ElseIf tSegName="ISA" {
				If $IsObject(tDoc) && (tDoc.Name = "Interchange") {
					#; This appears to be the start of a new Interchange, but we failed to close out the last one
					$$$LOGSTATUS($$$ERROR($$$EnsEDIX12ExpectedSegment,"IEA",tLine,tDocPos))
					Set:""'=tExtra tLine = tLine_tSegTerminator_tExtra
					Set tSegName=""
					Quit
				} Else {
					$$$LOGWARNING(tSegName_" segment "_tSegNum_" found not at start of document "_tDoc.%Id()_"; at "_tDocPos_" ("_tLine_")")
				}
			} ElseIf $Case(tSegName, "SE":$Case(tFirstSeg,"GS":1,"ISA":1,:0), "GE":"GS"'=tFirstSeg, "IEA":"ISA"'=tFirstSeg, :0) { ; SE,GE,IEA are normal end segs for Batch groups
				$$$LOGSTATUS($$$ERROR($$$EnsEDIX12ExpectedSegment,$Case(tFirstSeg,"ST":"SE","GS":"GE","ISA":"IEA",:""),tLine,tDocPos))
				Set tSegName="" ; pop up if we see an out-of-context segment
				Quit
			} ElseIf ("GS"=tFirstSeg)&&(tSegName'="GE") {
				#; Should be the start of a new Transaction Set, and yet the SegName is not ST, so ST appears to be missing
				#; Log the error and then create the new Transaction Set so that we can continue parsing and can report the missing ST later
				$$$LOGSTATUS($$$ERROR($$$EnsEDIX12ExpectedSegment,"ST",tLine,tDocPos))
				
				Set ..TransactionSetCount=..TransactionSetCount+1, ..%SegmentCount=1
				If tPrevSeg'="TransactionSetDocsRef" {
					#; Create a placeholder segment for the child document(s)
					Set tIndex=$I($$$vaSegmentGbl)
					Set iRef=$$$vaMobj(tDoc,"runtimeIndex")+1, iRefSegId=tIndex, tSegNum=tSegNum+1
					Set $$$vaSegmentGbl(tIndex)=..Separators_"TransactionSetDocsRef"_tDataElementSeparator_iRef_tDataElementSeparator
					Set $$$vaOpenSegmentPPG(tIndex)=1
					Set $$$vaSegmentGbl(tIndex,"term")=tSegTerminator
					Set $$$vaMobj(tDoc,"runtimeIndex")=iRef, $$$vaMobja(tDoc,"runtimeIndex",iRef)=tIndex
					Set ..%CurrentParentSegIndex=iRef
				}
				Set tPrevSeg=tSegName, tSegName="TransactionSetDocsRef"
	
				#; parse the nested child document
				Set tSC=tDoc.%Save()  Quit:$$$ISERR(tSC) ; save the doc-in-progress so children will have access to its content.
				Set ..%LookaheadLine=tLine_tZB
				Set:""'=tExtra ..%LookaheadLine=tSegTerminator_tLine_tSegTerminator_tExtra, tExtra=""
				Set tSC=..ParseIOStream(pIOStream,,$S(""=tGSControlVersion:pControlVersion, 1:tGSControlVersion),pInbound)
				Set tLine=..%LookaheadLine
				If $Case($P(tLine,tDataElementSeparator),"GS":1, "ST":1, "GE":1, "IEA":1, :0)&&($E(tLine,*)=tZB) {
					#; We will end up looping back to this ParseIOStream() and want to avoid repeated line ending characters
					Set tLine = $E(tLine,1,*-1)
				}
				Quit:$$$ISERR(tSC)
				Continue
			}
			
			If "TA1"=tSegName {
				Set tTA1Seen=1
			}
			ElseIf "GS"=tSegName {
				Set tGSControlVersion=$P(tLine,tDataElementSeparator,$$$GSVersionReleaseIndustryIdenti), tNumGroups=tNumGroups+1, ..TransactionSetCount=0
			}
			#; Store the data for the segment, reading more lines if it's > X12MaxSegLen
			Set (tBinaryFlag,tChunk)=0
			While ""'=tLine || 'pIOStream.AtEnd {
				#; Get new text; discard leading whitespace - this has the effect of removing Whitespace between segments while preserving Whitespace within them
				If ""=tLine {
					Set tTimedOut=0  While 'pIOStream.AtEnd {
						Kill tZB  Set tTimeout=..ReadTimeout, tLine=tLine_pIOStream.ReadLine($$$X12MaxReadLen-$L(tLine),.tTimeout,.tSC,.tZB)  ; No Quit; will break at end of loop
						Set tTimedOut=(..ReadTimeout&&(tTimeout=..ReadTimeout)), tComplete=(""'=tZB)
						Set:""'=tLine||tComplete ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)+$L(tZB)
						If ""'=tLine $$$catTRACE1Sub("parse","Got following segment line #"_..%LineCount_" '%1'",tLine)
						Set tComplete=(""'=tZB)
						
						#; Strip whitespace; quit if we got the line terminator, unless the line consisted only of whitespace
						Quit:..Whitespace=""
						Set tLine=..StripWhitespace(tLine)
						Quit:tTimedOut||$$$ISERR(tSC)||(""'=tLine&&tComplete)
						Quit:($L(tLine)=$$$X12MaxReadLen)
					}
					Set:tTimedOut&&$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,..ReadTimeout,"SegTerminatorAscii="_$A(tSegTerminator)_",on "_pIOStream.Name,tLine)
					If tBinaryFlag {
						Set tBinaryFlag=0
						Set:""'=tLine tSC=$$$ERROR($$$EnsEDIX12BinaryLeftover,tLine), tLine=""
						Quit
					}
					If tLine=""||$$$ISERR(tSC) {
						Set:(""=tLine)&&$IsObject(tDoc) tLine=tDoc.GetValueAt(tSegNum-1) ; display the previous segment in the error text
						Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEOD,tLine,$S($$$ISERR(tSC):$$$StatusDisplayString(tSC),1:""),tDocPos)
						Set tLine=""
						Quit
					}
					$$$catTRACE1Sub("parse","Got dup segment line #"_..%LineCount_" '%1'",tLine)
				}
				#; Special handling for segments containing binary data
				If (tChunk=0) {
					If $Case(tSegName,"BIN":1,"BDS":1,:0) {
						Set tBinaryFlag=0, tSC=..readBinarySegment(tDoc,.tLine,.tZB,tDataElementSeparator,tSegTerminator)  Quit:$$$ISERR(tSC)
						If (""=tLine) {
							Quit
						} ElseIf ($E(tLine,*)=tSegTerminator) {
							Set tLine = $E(tLine,1,*-1)
							Set tComplete = 1
							Quit
						} Else {
							Set tSegName = $P(tLine,tDataElementSeparator)
							Continue
						}
					}
					#; Store the data for the first chunk at top node
					Set tIndex=$I($$$vaSegmentGbl)
					Set $$$vaSegmentGbl(tIndex)=..Separators_tLine
					Set $$$vaOpenSegmentPPG(tIndex)=1
					Set $$$vaSegmentGbl(tIndex,"term")=tSegTerminator
					Set tLine="", ..%SegmentCount=..%SegmentCount+1, tSegNum=tSegNum+1
					Set $$$vaMobj(tDoc,"runtimeIndex")=$$$vaMobj(tDoc,"runtimeIndex")+1, $$$vaMobja(tDoc,"runtimeIndex",$$$vaMobj(tDoc,"runtimeIndex"))=tIndex
					Set tChunk=1
				} Else { ; Other Chunks go in subnodes
					Set $$$vaSegmentGbl(tIndex,tChunk)=tLine, tLine="", tChunk=tChunk+1
				}
				Quit:tComplete
			} Quit:$$$ISERR(tSC)
			
			#; Add the child count to the reference placeholder segment - if we are on the next segment after the group
			If tPrevSeg["DocsRef" {
				Set tSubscx=tSubsc_""""_tDoc.%Id()_":"_..%CurrentParentSegIndex_""""
				Set tRefx="..%NumChildren("_tSubscx_")"
				Set $$$vaSegmentGbl(iRefSegId)=$$$vaSegmentGbl(iRefSegId)_$G(@tRefx)
			}
			Quit:$Case(tSegName, "SE":$Case(tFirstSeg,"GS":0,"ISA":0,:1), "GE":"GS"=tFirstSeg, "IEA":"ISA"=tFirstSeg, :0)
		} Quit:$$$ISERR(tSC) ; done doc
		
		#; Add the child count to the reference placeholder segment - if the file ended in the child document
		If tSegName["DocsRef" {
			Set tSubscx=tSubsc_tDoc.%Id()_","
			Set tRefx="..%NumChildren("_tSubscx_""""_$P(tSegName,"DocsRef")_""")"
			Set $$$vaSegmentGbl(iRefSegId)=$$$vaSegmentGbl(iRefSegId)_$G(@tRefx)
		}
		#; Save if child or re-save if has children
		If $IsObject(tParentDoc)||$D(..%NumChildren) Do tDoc.%SetModified(1)  Set tSC1=tDoc.%Save()  Quit:$$$ISERR(tSC1) // Fatal Error
		If 'pFramed { // otherwise ParseFramedIOStream will call it
			Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_tLevelDocs_", level "_tLevels_", @Line "_..%LineCount
			Set tSC1=..%ServiceInterface.OnDocumentEnd(tDoc,tDocPos,tSC1)  Quit:$$$ISERR(tSC1) // Fatal Error
		
			#; Let the Service know we are done processing an interchange, giving an opportunity to 'filter'
			#; extraneous header/trailer/filler which may be present in the stream.
			#; tLine contains any extra chars read that may be part of the beginning of the interchange.
			#; On exit, tLine must not be longer than 106 bytes, and it must not omit any terminator characters
			#; between its end and what will next be read from pIOStream
			#; Check for End-Of-File; return the next potential fixed-length ISA segment if found
			Set tSC1=..%ServiceInterface.OnPostDocument(pIOStream,.tLine)
		}
	} While 0
	Set:$$$ISERR(tSC1)&&(tSC'=tSC1) tSC=$$$ADDSC(tSC,tSC1)
	Set ..%LookaheadLine=tLine_$S(""=tLine:"",1:tZB)
	If '$IsObject(tDoc) || $System.Status.Equals(tSC,$$$EnsEDIX12ExpectedSegment) || $System.Status.Equals(tSC,$$$EnsEDIX12UnexpectedEOD) {
		#; Fatal error occurred and/or no Document was created, still may want to send reply
		Set:""=tDataElementSeparator tDataElementSeparator = $Select(..Separators'="":$$$ELESEP(..Separators),1:$$$X12DefElementSeparator)
		Set:""=tComponentSeparator tComponentSeparator = $Select($$$COMSEP(..Separators)'="":$$$COMSEP(..Separators),$Case(pDefaultCompSep,"":0,tDataElementSeparator:0,tRepetitionSeparator:0,tSegTerminator:0,:1):pDefaultCompSep,1:$Case($$$X12DefComponentSeparator,tDataElementSeparator:$C(17),:$$$X12DefComponentSeparator))
		Set:""=tRepetitionSeparator tRepetitionSeparator = $Select($$$REPSEP(..Separators)'="":$$$REPSEP(..Separators),$Case(pDefaultRepSep,"":0,tDataElementSeparator:0,tComponentSeparator:0,tSegTerminator:0,:1):pDefaultRepSep,1:$Case($$$X12DefRepetitionSeparator,tComponentSeparator:$C(18),tDataElementSeparator:$C(18),:$$$X12DefRepetitionSeparator))
		Set:""=tSegTerminator tSegTerminator = $Select(..SegmentTerminator'="":..SegmentTerminator,$Case(pDefaultSegTerminator,"":0,tDataElementSeparator:0,tComponentSeparator:0,tRepetitionSeparator:0,:1):pDefaultSegTerminator,1:$Case($$$X12DefSegTerminator,tDataElementSeparator:$C(13,10),tComponentSeparator:$C(13,10),tRepetitionSeparator:$C(13,10),:$$$X12DefSegTerminator))
		
		Set tSC = ..%ServiceInterface.OnParsingError(tSC,tDoc,tDataElementSeparator_tComponentSeparator_tRepetitionSeparator_tSegTerminator)
	} Else {
		$$$catTRACE1Sub("parse","Returning '"_tDoc.Name_"' doc '"_tDoc_"' with lookahead line ='%1'",..%LookaheadLine)
		Set ..%CurrentDocument=$G(..%CurrentParents(..%CurrentParents),$$$NULLOREF)
		Kill ..%CurrentParents(..%CurrentParents)
		Set ..%CurrentParents=..%CurrentParents-1
		$$$ASSERT('$IsObject(..%CurrentDocument)||(..%CurrentDocument.%Id()=$P($LI(..%ParentIds),":")))
		Set ..%ParentIds=$LI(..%ParentIds,2,$LL(..%ParentIds))
		Set tDoc.%ParsingError = tParseError
		Set pDocument=tDoc
	}
	Set ..%CurrentParentSegIndex=tParentDocPos
	Quit tSC
}

Method readBinarySegment(tDoc As EnsLib.EDI.X12.Document, ByRef pLine As %String, pZB As %String, pDataElementSeparator As %String, pSegTerminator As %String) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	Do {	
		#; Get an index for the data
		Set tIndex=$I($$$vaSegmentGbl), $$$vaSegmentGbl(tIndex)=pLine ; temporary; we'll overwrite it later if no error
		Set $$$vaOpenSegmentPPG(tIndex)=1
		Set $$$vaSegmentGbl(tIndex,"term")=pSegTerminator
		Set $$$vaMobj(tDoc,"runtimeIndex")=$$$vaMobj(tDoc,"runtimeIndex")+1, $$$vaMobja(tDoc,"runtimeIndex",$$$vaMobj(tDoc,"runtimeIndex"))=tIndex

		#dim tSegName = $Piece(pLine,pDataElementSeparator)
		#dim tBinLengthPiece = $Case(tSegName,"BDS":3,"BIN":2,:2)

		#; Get the number of bytes in the binary data block
		Set tBinLength=$P(pLine,pDataElementSeparator,tBinLengthPiece)
		If '$IsValidNum(tBinLength) { Set tSC=$$$ERROR($$$EnsEDIX12BadBINLength,$A(pDataElementSeparator),pLine), pLine="" Quit }
		Set tPrefixLen=3+1+$L(tBinLength)+1

		#; For BDS, need to skip over <filter_id> to position at binary data
		Set:"BDS"=tSegName tPrefixLen=tPrefixLen+$L($P(pLine,pDataElementSeparator,2))+1
		If tPrefixLen>$L(pLine) { Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEODBinary,pLine), pLine=""  Quit }

		Set tPrefix=..Separators_$E(pLine,1,tPrefixLen), tData=$E(pLine_pZB,tPrefixLen+1,tPrefixLen+tBinLength), tLeftover=$E((pLine_pZB),tPrefixLen+tBinLength+1,*)

		Set tRemaining=tBinLength-$L(tData)
		Set tI=1
		#dim tMultiRead = 0

		While ((tRemaining>0) && '..%Stream.AtEnd) {
			Set tMultiRead = 1
			Set tChunk=$$$X12MaxSegLen-($L(tPrefix)+$L(tData))
			Set:tChunk>tRemaining tChunk=tRemaining
			Set tData=tData_..%Stream.Read(.tChunk)
			Set tRemaining=tRemaining-tChunk
			If tRemaining<=0||..%Stream.AtEnd||($L(tPrefix)+$L(tData)>=$$$X12MaxSegLen) {
				If tI=1 {
					Set $$$vaSegmentGbl(tIndex)=tPrefix_tData, (tPrefix,tData,pLine)=""
				} Else {
					Set $$$vaSegmentGbl(tIndex,tI-1)=tData, tData=""
				}
				Set tI=tI+1
			}
		}
		If (..%Stream.AtEnd && (tRemaining > 0)) { Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEODBinary,tData)  Quit }

		#; Keep looking at what follows in case we have not actually reached the end of the data
		Set tDone = 0, tPossiblyShort = 0, tExtra = 0
		If $E(tData,*)=pSegTerminator {
			#; Count is short by one - just accept it
			Set tDone = 1, tExtra = -1
			Set tLeftover = ""
			Set tData = $E(tData,1,*-1), tLeftover = ""		
		} ElseIf tLeftover'="" {			
			Set tPossiblyShort = tData[pSegTerminator
			If (tLeftover=pSegTerminator) {
				Set tDone = 1
			} ElseIf tLeftover[pSegTerminator {
				Set tAdd = $P(tLeftover,pSegTerminator)
				Set tLeftover = pSegTerminator_$P(tLeftover,pSegTerminator,2,*)
				While 'tDone {
					Set tLeftover = $P(tLeftover,pSegTerminator,2,*)
					Quit:(""=tLeftover)
					If $$$X12ValidSegName($P(tLeftover,pDataElementSeparator)) {
						Set tDone = 1
						Quit
					}
					Set tAdd = tAdd_pSegTerminator_$P(tLeftover,pSegTerminator)
				}
				If 'tDone {
					#; Read 6 characters to allow for possible CR-LF, plus 2-3 character segname, plus data element separators
					Set tLeftover = ..%Stream.Read(6,,.tSC)	Quit:$$$ISERR(tSC)
					If $$$X12ValidSegName($P($zstrip(tLeftover,"<C"),pDataElementSeparator)) {
						Set tDone = 1
						Set tLeftover = $zstrip(tLeftover,"<C") ; strip out CR/LF if present
						Set tLeftover = tLeftover_..%Stream.ReadUntil($$$X12MaxSegLen-$L(tLeftover),,,,,,.tSC,pSegTerminator)	Quit:$$$ISERR(tSC)					
					}
				}
				Set tExtra = $L(tAdd_$S('tDone:pSegTerminator_tLeftover,1:""))
				Set tData = tData_tAdd_$S('tDone:pSegTerminator_tLeftover,1:""), tAdd=""
			} Else {
				Set tExtra = $L(tLeftover)
				Set tData = tData_tLeftover
			}
		}
		If 'tDone && '..%Stream.AtEnd {
			If tMultiRead {
				Set tI = tI-2
				Set tData = $$$vaSegmentGbl(tIndex,tI)
				#; Count is short by one - just accept it
				If $E(tData,*)=pSegTerminator {
					Set tDone = 1, tExtra = -1
					Set tLeftover = ""
					Set $$$vaSegmentGbl(tIndex,tI) = $E(tData,1,*-1), tLeftover = ""
				}
				Set tPossiblyShort = tData[pSegTerminator				
			} Else {
				Set $$$vaSegmentGbl(tIndex)=tPrefix_tData, (tPrefix,tData,pLine)=""
				Set tI=1
				Set tMultiRead = 1
			}

			While 'tDone && '..%Stream.AtEnd {
				Set tNext = ..%Stream.ReadUntil($$$X12MaxSegLen-$L(tData)-6,,,,,,.tSC,pSegTerminator)
				If tNext'[pSegTerminator {
					#; Reached EOD or max seg len
					Set tExtra = tExtra + $L(tNext)
					Set $$$vaSegmentGbl(tIndex,tI)=tData_tNext, tData=""
					Set tI=tI+1
					Continue			
				}
				If tNext=pSegTerminator {
					Set tDone = 1
					Set tLeftover = ""
					Quit
				}
				#; Read 6 characters to allow for possible CR/LF, plus 2-3 character segname, plus data element separators
				Set tLeftover = ..%Stream.Read(6,,.tSC)	Quit:$$$ISERR(tSC)
				If $$$X12ValidSegName($P($zstrip(tLeftover,"<C"),pDataElementSeparator)) {
					Set tDone = 1
					Set tNext = $E(tNext,1,*-1)
					Set tExtra = tExtra + $L(tNext)
					Set tLeftover = $zstrip(tLeftover,"<C") ; strip out CR/LF if present
					Set tLeftover = tLeftover_..%Stream.ReadUntil($$$X12MaxSegLen-$L(tLeftover),,,,,,.tSC,pSegTerminator)	Quit:$$$ISERR(tSC)
					Set:(""'=(tData_tNext)) $$$vaSegmentGbl(tIndex,tI)=tData_tNext
					Quit
				} Else {
					Set tExtra = tExtra + $L(tNext_tLeftover)
					Set tData = tData_tNext_tLeftover, tNext="", tLeftover=""
				}			

				If ..%Stream.AtEnd||($L(tData)>=$$$X12MaxSegLen)||(tDone && tMultiRead) {
					Set $$$vaSegmentGbl(tIndex,tI)=tData, tData=""
					Set tI=tI+1
				}
			}			
		}

		If (tPossiblyShort && ('tDone || $Case($P(tLeftover,pDataElementSeparator),"GE":1,"IEA":1,:0))) {
			Set tSC=$$$ERROR($$$EnsEDIX12BinaryDataShort,tSegName,tBinLength,$P(tData,pSegTerminator,1,*-1))
		} ElseIf 'tDone {
			Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEODBinary,tData)
		}

		#; If all binary data in original read then rewrite the global with separators
		If 'tMultiRead Set $$$vaSegmentGbl(tIndex)=tPrefix_tData

		If tExtra {
			Set $P($$$vaSegmentGbl(tIndex),pDataElementSeparator,tBinLengthPiece+1)=$P($$$vaSegmentGbl(tIndex),pDataElementSeparator,tBinLengthPiece+1)+tExtra
		}

		If tLeftover = pSegTerminator {
			Set pLine = ""
		} ElseIf ""'=tLeftover {
			Set pLine=tLeftover
		} Else {
			Set pZB="", pLine = ""
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Read an X12 document from the given IO Stream
/// Returned %Status codes are not logged, except for Exceptions
Method ParseFramedIOStream(pIOStream As %IO.I.CharacterStream, Output pDoc As EnsLib.EDI.X12.Document, pInbound As %Boolean = 0, ByRef pIOLogEntry As Ens.Util.IOLog = {$$$NULLOREF}, pDefaultRepSep As %String = "", pDefaultCompSep As %String = "", pDefaultSegTerminator As %String = "") As %Status
{
#define MapCtlChars(%s)	$TR(%s,$C(1,2,3,9,10,11,13,28),"123tlsre")
	
	If (""=$G(pDoc)) || $IsObject(pDoc) { Set tDocClass="EnsLib.EDI.X12.Document" }
	Else { Set tDocClass=pDoc }
	Set $ZT="Trap",$EC="", tSC=$$$OK, pDoc=$$$NULLOREF, tLine=..%LookaheadLine
	If ""'=tLine {
		If ..%LookaheadLineIsNew {
			If ""'=$E(..DefCharEncoding) { ; fix line encoding if forced charset
				Set tEnc=$E(..DefCharEncoding,2,*)  If tEnc'=pIOStream.CharEncoding {
					Set tTab=##class(%IO.I.TranslationDevice).GetCharEncodingTable(tEnc)
					If tTab'=""&&(tTab'=##class(%IO.I.TranslationDevice).GetCharEncodingTable(pIOStream.CharEncoding)) {
						Set pIOStream.CharEncoding=tEnc
						Set tLine=$ZCVT(tLine,"I",tTab)
					}
				}
			}
			Set ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tLine)
			Set ..%LookaheadLineIsNew=0, ..%LookaheadLine=""
		}
		Set tStartTimeout=..ReadTimeout
	} Else { Set tStartTimeout=..StartTimeout, ..%LookaheadLineIsNew=1 }
	
	If "uninitialized"=..%inFraming {
		Set ..%inFraming=..applyFraming(..Framing)
		Set:"uninitialized"=..%outFraming&&("xxf"'=..%inFraming) ..%outFraming=..%inFraming
	}
	Set tPrefix=$P(..%inFraming,"xx"), tInFraming=$E(..%inFraming,$L(tPrefix)+3,*), tSuffix=$P(tPrefix,"x",2), tPrefix=$P(tPrefix,"x")

	#; Find the next potential fixed-length ISA or other header segment
	If ""'=tLine {
		Set ..%LookaheadLine="", tTimedOut=0
		$$$catTRACE1Sub("parse","Trying pre-fetched header line #"_..%LineCount_" '%1'; framing='"_$$$MapCtlChars(..%inFraming)_"'",$$$MapCtlChars(tLine))
	}
	Set tIsNew=(""=tLine)
	Set (tPreJunk,tPreFound,tEffSuffix)=""
	Set:""'=..Whitespace tLine=..StripWhitespace(tLine)
	#; Read the first seg plus any prefix chars
	Set seg1pos=0  For { ; until we get a start segment or suffix or timeout or EOF
		If 'seg1pos {
			For tSegName="ISA","GS","ST","TA1" {
				Set seg1pos=$F(tLine,tSegName)
				If seg1pos {
					Set tSep = $E(tLine,seg1pos)
					#; character following name must be the data element separator, which must not be a letter or number
					If tSep?1(1A,1N) {
						Set seg1pos=0
					} Elseif tSegName'="ST" {   // very unlikely it would actually be missing, but ST:1 is not mandatory in HIPAA_4010 so we won't count on it being there
						Set tFirstFieldLen = $Case(tSegName,"ISA":2,"GS":2,"TA1":9)
						#; check same character appears appropriate distance later so we can be reasonably certain this is actually the data element separator
						If $E(tLine,seg1pos+tFirstFieldLen+1)'=tSep {
							Set seg1pos=0
						}
					}
				} 
				Quit:seg1pos
			}
			If seg1pos {
				Set tPreJunk=tPreJunk_$E(tLine,1,seg1pos-1-$L(tSegName)), tLine=$E(tLine,seg1pos-$L(tSegName),*), seg1pos=seg1pos-$L(tPreJunk)
				If ""'=tPrefix {
					If tPrefix=$E(tPreJunk,*+1-$L(tPrefix),*) { Set tPreFound=tPrefix, tPreJunk=$E(tPreJunk,1,*-$L(tPrefix))  $$$sysTRACE("Found framing prefix "_$$$MapCtlChars(tPreFound)_" before header line '"_tLine) }
					Else { Set tSC=$$$ERROR($$$EnsErrGeneral,"Framing prefix "_$$$MapCtlChars(tPrefix)_" not found preceding candidate header line '"_$$$MapCtlChars(tPreJunk)_tLine) }
				} ElseIf "f"=tInFraming && (tPreJunk'=($ZStrip(tPreJunk,">C"))) {
					Set (tPrefix,tPreFound)=$E(tPreJunk,1+$L($ZStrip(tPreJunk,">C")),*), tPreJunk=$E(tPreJunk,1,*-$L(tPreFound))
					$$$sysTRACE("Adopting found prefix "_$$$MapCtlChars(tPreFound)_" as Flexible framing prefix before header line '"_tLine)
				}
			}
		}
		Quit:$L(tLine)>=106||pIOStream.AtEnd||$$$ISERR(tSC)
		$$$catTRACE("parse","Beginning framing read("_(106-$L(tLine))_") for 106-byte header with timeout "_tStartTimeout_" on "_pIOStream.Name)
		Set tTimeout=tStartTimeout, tFresh=pIOStream.Read(106-$L(tLine),.tTimeout,.tSC)
		Set tTimedOut=(tStartTimeout&&(tTimeout=tStartTimeout))
		Set ..%CharCount=..%CharCount+$L(tFresh)
		Set:""'=..Whitespace&&(""=tLine) tFresh=..StripWhitespace(tFresh)
		Set tLine=tLine_tFresh
		Set:tTimedOut&&$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrTCPReadTimeoutExpired,tStartTimeout,"106-byte header","binary")
		Quit:$$$ISERR(tSC)
		Set tStartTimeout=..ReadTimeout ; already started so go to read mode
	}
	Quit:""=tLine||$$$ISERR(tSC)||(""'=..Whitespace&&(""=..StripWhitespace($ZStrip(tLine,"<W")))) tSC
	Set tDocPos=pIOStream.Name_$C(13,10)_" level 1, @Line "_..%LineCount

	If 'seg1pos {
		#; check for messages without a start seg such as 1-byte ACKs
		Set tSegName=""
		If "f"=tInFraming || $L(tPreFound) {
			Set tEnvelope=""
			If $L(tLine)>=2 { ; try for 1-byte ACK
				If ("f"=tInFraming) && ($L(tLine)>=3) {
					If $Case($E(tLine,2), $E(tLine,1):0, $E(tLine,3):0, $C($$$SingleByteAcceptAscii):1, $C($$$SingleByteErrorAscii):1, :0)
					 && $Case($E(tLine,4), "":1, $E(tLine,1):1, :0) {
						Set (tPrefix,tPreFound)=$E(tLine)
						Set tSuffix=$S($L(tLine)<=5:$E(tLine,3,*), 1:$E(tLine,3))
						Set tEnvelope="ACK_1_"_$A($E(tLine,2))_":"_$E(tLine,2), $E(tLine,1,2+$L(tSuffix))=""
					 }
				} Else {
					If $Case($E(tLine,2), $C($$$SingleByteAcceptAscii):1, $C($$$SingleByteErrorAscii):1, :0)
					 && (tSuffix=$E(tLine,3,2+$L(tSuffix))) {
						Set tPreFound=$E(tLine)
						Set tEnvelope="ACK_1_"_$A($E(tLine,2))_":"_$E(tLine,2), $E(tLine,1,2+$L(tSuffix))=""
					 }
				}

				Set:""'=tEnvelope tOK=($C($$$SingleByteAcceptAscii)=$E(tEnvelope,*)), tCode=##class(EnsLib.EDI.X12.Validator).GetTA1Code(tOK), tDesc="1-byte "_$S(tOK:"",1:"N")_"ACK '"_$A($E(tEnvelope,*))_"'"
			}
			If ""'=tEnvelope {
				#; Create a TA1 document object to represent the 1-byte ACK
				Set ..%NumChildren=..%NumChildren+1
				Set tDocPos=pIOStream.Name_$S(..%LineCount<=2:"", 1:$C(13,10)_" Document# "_..%NumChildren_", level 0, @Line "_..%LineCount)
				Kill %objlasterror
				Set pDoc=##class(EnsLib.EDI.X12.Document).%New($LB(,$$$X12DefSeparators_$$$X12DefSegTerminator,tDocPos))  If '$IsObject(pDoc) Set tSC=%objlasterror Quit // Fatal Error
				Set tReplyISA=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$$$X12DefSeparators_"ISA"))
				Do pDoc.AppendSegment(tReplyISA)
				Set tTA1=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$$$X12DefSeparators_"TA1"))
				Do tTA1.SetValueAt(tCode,$$$TA1InterchangeAcknowledgmentCod)
				Do tTA1.SetValueAt(tCode,$$$TA1InterchangeNoteCode)
				Do tTA1.SetValueAt(tDesc,$$$TA1InterchangeErrorText)
				Do pDoc.AppendSegment(tTA1)
				Set tReplyIEA=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$$$X12DefSeparators_"IEA"))
				Do pDoc.AppendSegment(tReplyIEA)
				Set pDoc.Envelope=tEnvelope
				Set tF=tPrefix_$S(""=tSuffix:"",1:"x"_tSuffix)
			}
		}
		Set:tTimedOut||pIOStream.AtEnd tPreJunk=$E(tPreJunk,*-($$$X12MaxSegLen-$L(tLine)),*)_tLine
		Set tLine=""
	} Else { ; seg1
		If tPreFound=tPrefix {
			Set tEffSuffix=$S(""'=tSuffix:tSuffix
			  , 1:$Case(tPreFound
				,$C($$$X12DefStartBlockAscii):$C($$$X12DefEndBlockAscii)
				,$C($$$HL7DefStartBlockAscii):$C($$$HL7DefEndBlockAscii)
				,$C(1):$C(2)
				,:""))
			Set:"uninitialized"=..%outFraming ..%outFraming=tPrefix_"x"_tEffSuffix, tOutTemp=1
		} Else { ; no match
			Set:"f"'=tInFraming tPreJunk=tPreJunk_tPreFound_tLine, tLine="" ; reject it - we require the correct StartBlock char (or lack of it)
		}
	}
	If ""'=tPreJunk {
		$$$LOGWARNING1Sub("Discarding received non-X12 data("_$L(tPreJunk)_") '%1'",$$$MapCtlChars(tPreJunk))
		If $IsObject(pIOLogEntry) {
			If '$$$IsdefObject(tDiscard) { Set tDiscard=##class(%GlobalCharacterStream).%New()  $$$ASSERT($IsObject(tDiscard)) }
			Do tDiscard.Write(tPreJunk)
		}
		Set tPreJunk=""
	}

	Do { ; while 0
		#; Deal with unexpected input before the Message
		If $$$IsdefObject(tDiscard) {
			Set tPreJunk=tDiscard.Read(1000) Do tDiscard.Rewind()
			Set tNote="Unexpected X12 read data ("_$S(tDiscard.Size>1000:"...",1:"")_tPreJunk_") before Message on "_pIOStream.Name
			Do ..%ServiceInterface.IOLogDiscard(tSC,tNote,tDiscard)
		}
		Quit:$$$ISERR(tSC)
		Set tOutTemp=0
		If '$IsObject(pDoc) { ; not single-byte ACK
			If tTimedOut || ((""=tLine)&&(""'=tPreJunk)) {
				Set tText=tPreJunk_tLine Set tText=$$$MapCtlChars($E(tText,*-1000,*))
				If tTimedOut { Set tSC=$$$ERROR($$$EnsErrTCPReadTimeoutExpired,tTimedOutTime,"on "_pIOStream.Name, tText) }
				Else { Set tSC=$$$ERROR($$$EnsEDIX12ErrStartBlock,$$$MapCtlChars(tPreFound),$$$MapCtlChars(tPrefix)_", on "_pIOStream.Name,tText) }
				Quit
			}
			#; Read Message from device using ParseIOStream()
			Set ..%LookaheadLine=tLine
			Set pDoc=tDocClass
			Set tSC=..ParseIOStream(pIOStream,.pDoc,,pInbound,1,pDefaultRepSep,pDefaultCompSep,pDefaultSegTerminator)
			Quit:'$IsObject(pDoc) ; Leave everything else for the next time around
			Set tTimedOut=$$$StatusEquals(tSC,$$$EnsErrTCPTerminatedReadTimeoutExpired)  Set:tTimedOut tSC=$$$OK
			Set tLine=..%LookaheadLine
	
			#; read suffix char/block if any
			If ""'=tEffSuffix {
				Set tSuffFound="", tExtraLen=$L(..Whitespace)+$L(tEffSuffix) ; allow for possible whitespace termination of previous segment
				For {
					Set tFound=$F($E(tLine,1,tExtraLen),tEffSuffix)
					If tFound {
						Set tSuffFound=tEffSuffix, tLine=$E(tLine,tFound,*)
						Quit
					}
					Quit:$L(tLine)>=tExtraLen||(""'=$TR(tLine,..Whitespace))

					#; read one more char
					Set ch=pIOStream.Read($L(tEffSuffix),0.1,.tSC)  Quit:$$$ISERR(tSC)||(""=ch)
					Set tLine=tLine_ch
					Continue:""=$TR(ch,..Whitespace)
					Quit:tEffSuffix'[ch 
				}
			} ElseIf "f"=tInFraming {
				#; We had no guess for the expected Suffix ; just get everything up to length 5 or the first alpha char
				Set:$L(tLine<5) tLine=tLine_pIOStream.Read(5-$L(tLine),0.1,.tSC)  Quit:$$$ISERR(tSC)
				Set tFound=0 
				If ""'=tPrefix {
					Set tFound=$F(tLine,tPrefix)
					If tFound Set tFound=tFound-$L(tPrefix)
				}
				If 'tFound {
					For i=1:1:$L(tLine) { Continue:..Whitespace[$E(tLine,i)||(""=$ZStrip($E(tLine,i),"*E'A"))  Set tFound=i  Quit }
				}
				If tFound {
					Set tSuffFound=..StripWhitespace($E(tLine,1,tFound-1)), tLine=$E(tLine,tFound,*)
				} Else {
					Set tSuffFound=..StripWhitespace(tLine), tLine="", tFound=1
				}
				Set tEffSuffix=tSuffFound
			} Else {
				Set tFound=1 ; empty EndBlock is OK
				Set tSuffFound=""
			}

			If tFound {
				If ""'=tEffSuffix {
					If "f"=tInFraming {
						$$$catTRACE1Sub("parse","detected EndBlock '"_$$$MapCtlChars(tEffSuffix)_"'%1'",$$$MapCtlChars(tLine))
					} Else {
						$$$catTRACE1Sub("parse","found framing EndBlock '"_$$$MapCtlChars(tEffSuffix)_"' with following line '%1'",$$$MapCtlChars(tLine))
					}
				}
				Set tF=tPrefix_$S(""=tEffSuffix:"",1:"x"_tEffSuffix)
			} Else {
				$$$LOGWARNING1Sub("Did not find expected EndBlock '"_$$$MapCtlChars(tEffSuffix)_"' in post-document line '%1'; continuing",$$$MapCtlChars(tLine))
				Set tF=tPrefix
			}
			Set ..%LookaheadLine=tLine
			If tSuffFound=tEffSuffix {
				Set:$$$ISERR(tSC)&&$$$StatusEquals(tSC,$$$EnsErrDocImport) tSC=$$$OK
			} Else {
				#; Quit with error; leave everything else for the next time around
				Set:$$$ISOK(tSC) tSC=$$$ERROR($$$EnsEDIX12ErrEndBlock,$$$MapCtlChars(tSuffFound),$$$MapCtlChars(tEffSuffix),$$$MapCtlChars(tLine))
				Quit
			}
		} ; '$IsObject(pDoc) ; not single-byte ACK

		If "f"=tInFraming {
			Set:..RememberFlex ..%inFraming=tF
			Set:"uninitialized"=..%outFraming||tOutTemp ..%outFraming=tF
			$$$catTRACE("parse","Detected Framing style '"_$$$MapCtlChars(tF)_"'")
		} Else {
			Set tF=..%inFraming
		}
		If $IsObject(pDoc) {
			Do { ; while 0
				Set tDocPos=pIOStream.Name_$C(13,10)_" Document# "_..%NumChildren_", level 0, @Line "_..%LineCount
				Set tSC1=..%ServiceInterface.OnDocumentEnd(pDoc,tDocPos,tSC)  Quit:$$$ISERR(tSC1) // Fatal Error

				#; Process any trailing stuff in the stream
				#; Read any blank lines to end, just to see if there is another document beginning there
				Set tLine=..%LookaheadLine, tExtra=""
				While ""=tLine && 'pIOStream.AtEnd {
					Kill tZB  Set tFresh=pIOStream.Read(100,0,.tSC1)  Quit:$$$ISERR(tSC1)
					Quit:""=tFresh
					Set tExtra=tExtra_tFresh
					Set tLine=..StripWhitespace(tFresh)
					Continue:""=tLine
					Set ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(tFresh)
					$$$catTRACE1Sub("parse","Got trailing extra line '%1'",$$$MapCtlChars(tFresh))
				}
				Quit:$$$ISERR(tSC1)&&($$$StatusText(tSC1)'["<READ>") ; swallow disconnect error- save the data we got
				Set tExtraMod=tExtra, tSC1=..%ServiceInterface.OnPostDocument(pIOStream,.tExtraMod)
				Set ..%LookaheadLine=$S(tExtraMod'=tExtra:tExtraMod, ""=tLine:"", 1:tExtra)
			} While 0
			Set:$$$ISERR(tSC1)&&(tSC'=tSC1) tSC=$$$ADDSC(tSC,tSC1)
		}
		If $IsObject(pIOLogEntry) {
			Set pIOLogEntry.InObject=pDoc  Do:$IsObject(pDoc) pDoc.%Save()
			Set pIOLogEntry.Annotation = $S(""=pIOLogEntry.Annotation:"",1:pIOLogEntry.Annotation_" | ")_"Received "_$S($IsObject(pDoc):"message "_pDoc.%Id(),1:"no message")_" with Framing style '"_$$$MapCtlChars(tF)_"'"
			Set:$$$ISERR(tSC) pIOLogEntry.Status=$$$ADDSC(pIOLogEntry.Status,tSC)
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	If $tlevel>0 Trollback
	Goto Exit
}

ClassMethod applyFraming(pFraming As %String, pFlexDefault As %String = "xxf") As %String
{
	Set tFramLC=$ZCVT(pFraming,"L")
	Quit $Case($E(tFramLC,1,5),
		"none":"x",
		"flexi":pFlexDefault,
		"mllp":$C($$$HL7DefStartBlockAscii)_"x"_$C($$$HL7DefEndBlockAscii,$$$X12DefEndDataCRAscii),
		"epic":$C($$$X12DefStartBlockAscii)_"x"_$C($$$X12DefEndBlockAscii),
		"msgen":"xx<->", "mllpm":$C($$$HL7DefStartBlockAscii)_"x"_$C($$$HL7DefEndBlockAscii,$$$X12DefEndDataCRAscii)_"xx<->",
		"ascii":$Case(tFramLC,"asciicr":"x"_$C(13),"asciilf":"x"_$C(10),"asciicrlf":"x"_$C(10),:$$framchars($E(tFramLC,6,*))),
		:$Case($E(tFramLC,1,4),
			"mllp":$$framchars($E(tFramLC,5,*))_$C($$$X12DefEndDataCRAscii),
			"epic":$$framchars($E(tFramLC,5,*)),
			:$$framchars(tFramLC)))
framchars(str)
	#; Transform a string of the form nn/mm into $C(nn)_"x"_$C(mm) as before- and after- framing chars
	#; If it is just nn, make it "x"_nn because a lone framing char comes after.
	Set tPiece=$P(str,"/")
	Set tStr="" For i=1:1:$L(tPiece,",") { Set tItem=$P(tPiece,",",i)  Continue:""=tItem
		Set tStr=tStr_$C(+tItem)
	}
	Set tPiece=$P(str,"/",2)
	If ""=tPiece&&("/"'=$E(str,*)) {
		If (tStr=$C(0)) && (0'=$E(str)) { Set tStr=pFlexDefault }
		Else { Set tStr="x"_tStr }
	}
	Else {
		Set tStr=tStr_"x"
		For i=1:1:$L(tPiece,",") { Set tItem=$P(tPiece,",",i)  Continue:""=tItem
			Set tStr=tStr_$C(+tItem)
		}
		Set:"x"=$E(tStr,*) $E(tStr,$L(tStr))=""
	}
	Quit tStr
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
	Set (..%LookaheadLine,..%LookaheadLineIsNew)=""
	Do ..ResetPosition()
	Set ..%Stream =$$$NULLOREF
	Set (..%inFraming,..%outFraming) = "uninitialized"
	Set ..SegmentTerminator=""
}

Method ResetPosition()
{
	Kill ..%CurrentParents,..%NumChildren
	Set (..%CurrentParents,..%NumChildren,..%SegmentCount,..%LineCount,..%CharCount)=0
	Set:""'=..%LookaheadLine ..%LineCount=..%LineCount+1, ..%CharCount=..%CharCount+$L(..%LookaheadLine)
	Set ..%CurrentDocument=$$$NULLOREF
	Set ..%ParentIds=""
	Set ..FinishBatch=0
}

}
