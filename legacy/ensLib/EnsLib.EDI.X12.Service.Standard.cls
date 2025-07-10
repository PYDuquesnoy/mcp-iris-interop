/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.Service.Standard Extends (Ens.BusinessService, EnsLib.EDI.X12.Util.IOFraming, EnsLib.EDI.ServiceInterface) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter DOCCLASS As %String = "EnsLib.EDI.X12.Document";

/// Colon-separated Local ID:Qualifier codes representing this (receiving) facility and application <br>
/// These are used in constructing reply document headers.<br>
/// The '@' symbol represents using the corresponding field from the incoming message.<br>
/// If your ID must contain a literal @ symbol, escape it with backslash: '\@'
Property LocalApplicationID As %String(MAXLEN = 1000) [ InitialExpression = "@:@" ];

/// Configuration items to which to send Documents
Property TargetConfigNames As %String(MAXLEN = 2000);

/// Store a set of searchable properties associated with each X12 TransactionSet processed.<br>
/// These records will be stored in the named SearchTable class, if any.
Property SearchTableClass As %String(MAXLEN = 128) [ InitialExpression = "EnsLib.EDI.X12.SearchTable" ];

/// Category to apply to incoming X12 document type names to produce a complete DocType specification.<p/>
/// Combines with the document type name to produce a DocType assignment.
/// This setting may also contain multiple comma-separated type names followed by = and then a
/// DocTypeCategory or full DocType value to apply to documents declared as that type.<br>
/// A trailing asterisk (*) at the end of a given partial type Name will match any types with that beginning part.<p/>
/// An example: DocSchemaCategory='837=837_X096, 850=850_X12-4010, Interchange=HIPAA_5010, Group=HIPAA_4010'; <br>
/// Note that a DocType assignment may be needed for Validation or SearchTableClass indexing.
Property DocSchemaCategory As %String(MAXLEN = 1000);

/// X12 Document outbound framing protocol; options: <br/>
/// - Flexible : Determine framing style from the content of received data of each message received<br/>
/// - Flexible! : Determine framing style from the content of received data of the first message and require subsequent messages to have that same framing style<br/>
/// - None : No framing - Each document is output without prefix or suffix characters <br/>
/// - Epic02/03 : same as Ascii02/03 : EPIC sometimes uses this for TCP. Frame documents with an Ascii(02) prefix character before each document and an Ascii(03) suffix character <br/>
/// - Ascii[nn]/[mm] : Frame documents with an Ascii(nn) prefix character before each document and an Ascii(mm) suffix character, but no trailing Ascii(13) as in MLLP <br/>
/// - Ascii[nn] : Frame documents with an Ascii(nn) suffix character separating each document from the subsequent one. <br/>
/// - AsciiLF : Frame documents with Ascii(10) (Linefeed) separating each document from the subsequent one <br/>
/// - AsciiCR : Frame documents with an extra Ascii(13) (Carriage Return) separating each document from the subsequent one <br/>
/// - MLLP : Minimal Lower Level Protocol (HL7 style) - Frame each X12 Document with Ascii(11) prefix and Ascii(28,13) suffix <br/>
/// - MLLP[nn]/[mm] : Minimal Lower Level Protocol - Frame each X12 Document with Ascii(nn) prefix and Ascii(mm),Ascii(13) suffix <br/>
/// - MsgEnvelope : Use the document's Envelope property verbatim if it is present. The string &lt;!--X12DOC--&gt; if present in the Envelope will be replaced with the document content. Otherwise the document will simply follow the 'Envelope' text <br/>
/// - MLLPMsgEnvelope : Same as 'MsgEnvelope', but with MLLP prefix and suffix also around the document inside the 'Envelope' <p/>
/// Note: All Ascii values should be given in decimal; Ascii(120) ('x') is not allowed as an Ascii framing character.
/// Also, if an asterisk (*) is appended to the framing specification, Flexible framing will be used in parsing received acknowledgement response messages. Otherwise the response messages will be expected with the same kind of framing as that specified here for outbound messages.
Property Framing As %String(DISPLAYLIST = ",Flexible,Flexible!,None,Epic02/03,Ascii11/28,Ascii11,AsciiLF,AsciiCR,MLLP,MLLP11/28,MsgEnvelope,MLLPMsgEnvelope") [ InitialExpression = "None" ];

/// String specifying types of Validation to perform if <parameter>ValMode</parameter> = 'Flags' <p>
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
/// 'e' - continue validating after errors are encountered - specify this to scan the entire document and report all errors. 
/// Note, however, that if <parameter>BatchErrorAction</parameter> is 'Reject With All Errors', the entire document will always be scanned. 
/// And if <parameter>BatchErrorAction</parameter> is 'Reject on First Error, then validation will always stop after the first error is encountered. <br/>
Property Validation As %String;

/// Mode to use in validating incoming messages <p>
/// If set to 'Flags', the flags specified in the <parameter>Validation</parameter> setting will be used. <br>
/// If set to 'SNIP', SNIP rules will be used in determining whether messages pass validation and in constructing Acknowledgement messages.  The <parameter>SNIPLevel</parameter> value will determine which SNIP rules are used. <br>
/// If set to 'None', do not perform validation. <br>
Property ValMode As %String(VALUELIST = ",None,Flags,SNIP") [ InitialExpression = "Flags", Required ];

/// Which level of SNIP validation to perform <p>
/// This is only used when <parameter>ValMode</parameter> is set to 'SNIP'. <br>
/// If set to 1, then only integrity testing is performed. <br>
/// If set to 2, then integrity testing and requirements testing are performed. <br> 
Property SNIPLevel As %Integer(VALUELIST = ",1,2") [ InitialExpression = 1 ];

/// ConfigName(s) of the operations or processes to which messages that fail validation should be forwarded.
Property BadMessageHandler As %String;

/// How should reply documents be generated? <p>
/// - Never : Do not send back any reply <br>
/// - Immediate : Send back reply message generated immediately in this Service <br>
/// - Application : If the Interchange passes immediate validation, wait for reply or replies from target config item and forward a reply back when it is complete. (If validation fails or some other error occurs, generate an immediate reply anyway, according to the option selected for 'BatchReplyType'
Property ReplyMode As %String(DISPLAYLIST = ",Never,Immediate,Application", VALUELIST = ",Never,Immed,App") [ InitialExpression = "Immed", Required ];

/// Ignore inbound Acknowledgement messages to avoid reply feedback loop.
Property IgnoreInboundAck As %Boolean [ InitialExpression = 1 ];

/// Add extra error-text field to TA1 & 997/999 AKx segments when generating error-status reply messages; otherwise do not embed internal error state information in 997 messages
Property AddNackErrText As %Boolean;

/// How to treat received batch Interchange documents: <br>
/// - Whole Batch : Don't process child documents individually; accumulate and send the whole batch as one composite document <br>
/// - Single-Session Batch : Forward all documents in the Interchange as part of a single session, including final parent document objects containing batch and group header and trailer segments <br>
/// - Multi-Session Batch : Forward each document in the Interchange in its own session, followed by final parent document objects containing the batch and group header and trailer segments <br>
/// - Individual : Forward each child document in the batch in its own session; do not forward parent batch document objects
Property BatchHandling As %String(DISPLAYLIST = ",Whole Batch,Single-Session Batch,Multi-Session Batch,Individual", VALUELIST = ",Whole,1Session,MSession,Indiv") [ InitialExpression = "1Session", Required ];

/// What to do when detecting a validation error in a batch Interchange document: <p>
/// (Note: If ReplyMode is 'Application' and BatchErrorAction is not 'Individual', then some documents in a batch may be forwarded and then the whole batch rejected after errors are encountered) <p>
/// - Reject With All Errors : Reject the whole batch if any error is found in any document within it. Enumerate all errors found if BatchReplyType allows for reporting them. This will prevent forwarding any documents in a batch until all have been read and validated.<br>
/// - Accept With Errors : Accept documents with errors, but do take note of all errors found if BatchReplyType allows for reporting them. This will prevent forwarding any documents in a batch until all have been read and validated.<br>
/// - Reject On First Error : Reject the whole batch when the first error is found in any document within it. Don't bother checking for more errors or parsing any further contents of the Interchange. This will prevent forwarding any documents in a batch until all have been read and validated. <br>
/// - Reject Individual Errors : Reject only those documents within the Interchange that have errors. Forward each acceptable child document to the target config item(s) as soon as it has been read and validated.
Property BatchErrorAction As %String(DISPLAYLIST = ",Reject With All Errors,Accept With Errors,Reject On First Error,Reject Individual Errors", VALUELIST = ",All,Note,First,Indiv") [ InitialExpression = "Indiv", Required ];

/// What kind of batch reply should we construct for an Interchange batch we have received? 
/// Note that all the options here that relate to TA1 segments are used to force a TA1 segment to be generated, often as the only body segment of the reply interchange.
/// This is used to represent the presence or absence of errors in the whole inbound Interchange.  However if an error is found in the incoming
/// ISA or IEA that can only be reported in a TA1 segment, then a TA1 will be generated even if the configured setting does not force a TA1 to appear. <p>
/// - None : Do not generate a batch reply - if an error occurs do not construct any immediate notification reply to the sender <br>
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
/// - Byte : Generate a reply consisting of a single character code : 'A' if the whole Interchange is accepted, 'R' if it is rejected due to one or more errors
Property BatchReplyType As %String(DISPLAYLIST = ",None,All,All+TA1,All+ISA14TA1,Errors,OnlyIfErrors,Successes,TA1,OnlyIfErrorTA1,ISA14-TA1,ISA14-OnlyIfErrorTA1,Byte", VALUELIST = ",None,All,AllTA1,AllI14TA1,Errs,OnlyErrs,Succ,TA1,ErrTA1,I14,I14Err,Byte") [ InitialExpression = "Errs", Required ];

/// Process the file without error even if to enhance readability newlines have been added after or in place of segment terminators. <br/>
/// Also causes tab and space characters to be ignored at the end or beginning of segments (i.e. adjacent to a segment terminator).
Property TolerateNewlines As %Boolean [ InitialExpression = 1 ];

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
Property DefCharEncoding As %String(MAXLEN = 20);

/// Default Repetition Separator to use for parsing any X12 Documents in which the Repetition Separator is not explicitly defined.
/// The Repetition Separator is specified in the Interchange header at ISA:11.
/// Empty string means use the system default value if the Repetition Separator is not explicitly defined in the document interchange.
Property DefRepSep As %String(MAXLEN = 1);

/// Default Component Element Separator to use for parsing any X12 Documents in which the Component Separator is not explicitly defined. 
/// The Component Separator is specified in the Interchange header at ISA:16.
/// Empty string means use the system default value if the Component Element Separator is not explicitly defined in the document interchange.
Property DefCompSep As %String(MAXLEN = 1);

/// Default Segment Terminator to use for parsing any X12 Documents in which the Segment Terminator is not explicitly defined. 
/// The Segment Terminator is specified as the byte immediately following the 105 byte Interchange header.
/// Empty string means use the system default value if the document interchange is missing.
Property DefSegTerm As %String(MAXLEN = 1);

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.X12.Service.Standard},DocSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.EDI.X12.Service.Standard},Framing:Connection:selector?context={Ens.ContextSearch/getDisplayList?host=@currHostId&prop=Framing},ValMode:Acknowledgement,Validation:Acknowledgement,SNIPLevel:Acknowledgement,LocalApplicationID:Acknowledgement,ReplyMode:Acknowledgement,BatchHandling:Basic,BatchErrorAction:Acknowledgement,BatchReplyType:Acknowledgement,BadMessageHandler:Acknowledgement:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},AddNackErrText:Acknowledgement,TolerateNewlines:Connection,DefCharEncoding::selector?context={Ens.ContextSearch/CharacterSets},DefRepSep,DefCompSep,DefSegTerm";

/* Used in AckIn... subclasses (aka ImmediateByteAck) */
/// In addition to forwarding a full reply message according to the ReplyMode and BatchReplyType settings, return a direct immediate Acknowledgement of this type on this Service's TCP connection as soon as we have committed the inbound document to our persistent storage
/// - None : Do not generate a batch reply - if an error occurs do not construct any immediate notification reply to the sender <br>
/// - TA1 : Generate a reply Interchange containing only a TA1 segment that indicates acceptance or error status for the whole Interchange we received <br>
/// - Byte : Generate a reply consisting of a single character code : 'A' if the whole Interchange is accepted, 'R' if it is rejected due to one or more errors
Property CommitAckType As %String(VALUELIST = ",None,TA1,Byte") [ InitialExpression = "None", Required ];

/// For batch documents, don't process contained documents individually; accumulate and send the whole batch at once;
/// Do not begin processing TransactionSets until after validating the end of group and end of interchange segments.
Property %ForwardBatchWhole As %Boolean [ Internal ];

/// When processing child documents individually, forward batch header/trailer segment shell documents in addition to the child Message documents they contain
Property %ForwardBatchHeaders As %Boolean [ InitialExpression = 1, Internal ];

/// For Batch documents, forward every child document in the batch as part of a single session.
Property %SingleBatchSession As %Boolean [ Internal ];

/// Should this Service forward child documents as soon as it encounters them, or store them up until we know if the batch contained any errors
Property %DeferChildSend As %Boolean [ Internal ];

/// Should a Batch Interchange response document include a top-level TA1 response segment?
Property %ForceTA1 As %Boolean [ Internal ];

/// Should a Batch Interchange response document include 997/999 FunctionalGroup- and TransactionSet- level acknowledgement segments?
Property %Do997s As %Boolean [ Internal ];

/// Stop processing a batch document if an error occurs. Otherwise accumulate all errors and report them as a group
Property %AbortBatchOnError As %Boolean [ InitialExpression = 0, Internal ];

/// Does the current BatchReplyType specify a reply only if Errors occur?
Property %ConditionalReply As %Boolean [ Internal ];

/* transient state properties */
/// Is the current document the first in a batch? (used for starting a new session on the first message in a batch; we reset it at the end of each batch)
Property %isNewBatch As %Boolean [ InitialExpression = 1, Internal ];

/// Does the current message belong to a batch Interchange whose ISA requests a TA1 reply?
Property %ISARequestsTA1 As %Boolean [ InitialExpression = 0, Internal ];

/// Keep track of whether the Interchange contained any errors or successes. Empty result means none of the selected-for statuses occurred (i.e. errors or successes).
Property %TopReplyCode As %String [ Internal ];

/// If SearchTableClass is set, use it to index any reply documents
Parameter IndexReplies As %Boolean [ Internal ] = 0;

Property %Parser As EnsLib.EDI.X12.Parser [ Internal ];

Method OnInit() As %Status
{
	Set ..%Parser=##class(EnsLib.EDI.X12.Parser).%New($this)
	If "!"=$E(..Framing,*) { Set ..%Parser.Framing=$E(..Framing,1,*-1), ..%Parser.RememberFlex=1}
	Else { Set ..%Parser.Framing=..Framing }
	Set:..TolerateNewlines ..%Parser.Whitespace=$C(13,10,9,32)
	Set ..%Parser.DefCharEncoding=..DefCharEncoding
	
	#; Apply default initializers (same as InitialExpression values)
	Set:""=..ReplyMode ..ReplyMode="Immed"
	Set:""=..BatchHandling ..BatchHandling="1Session"
	Set:""=..BatchErrorAction ..BatchErrorAction="Indiv"
	Set:""=..BatchReplyType ..BatchReplyType="Errs"
	Set:""=..ValMode ..ValMode="Flags"
	Set:"1"=$ZStrip(..Validation,"<>W") ..Validation="dm"

	#; Populate control flags
	Set ..%ForwardBatchWhole=$Case(..BatchHandling, "Whole":1, :0)
	Set ..%ForwardBatchHeaders=(..BatchHandling'="Indiv")
	Set ..%SingleBatchSession=$Case(..BatchHandling, "1Session":1, :0)
	Set ..%AbortBatchOnError=$Case(..BatchErrorAction, "Indiv":0, :1)
	Set ..%DeferChildSend=$Case(..BatchHandling, "Whole":1, :$Case(..ReplyMode,"Never":0, "App":0,:1))
	Set ..%ForceTA1=$Case(..BatchReplyType, "AllTA1":1, "TA1":1, "ErrTA1":1, "AllI14TA1":-1, "I14":-1, "I14Err":-1, :0)
	Set ..%Do997s=$Case(..BatchReplyType, "None":0, "All":3, "AllTA1":3, "AllI14TA1":3, "Errs":1, "OnlyErrs":1, "Succ":2, "TA1":0, "ErrTA1":0, "I14":0, "I14Err":0, "Byte":0, :0)
	Set ..%ConditionalReply=$Case(..BatchReplyType, "OnlyErrs":1, "ErrTA1":1, "I14Err":1, :0)
	If ..ReplyMode="App" && (..BatchErrorAction'="Indiv") $$$LOGWARNING("ReplyMode is 'Application' and BatchErrorAction is not 'Reject Individual Errors'; this means a partial batch may be forwarded to the target application and then the sender notified that the whole batch is rejected")

	If ""=..DocSchemaCategory {
		$$$LOGWARNING("DocSchemaCategory is empty. This means the DocType of incoming documents cannot be set and validation cannot be performed.")
	}
	Quit $$$OK
}

/// Note: pDocIn is not declared as EnsLib.EDI.X12.Document so that subclasses can handle other types and transform them before calling ##super().
Method OnProcessInput(pDocIn As %RegisteredObject, Output pDocOut As %RegisteredObject) As %Status
{
	$$$ASSERT(0_"Subclass Responsibility")
}

/// Override this method to implement your own custom method for handling an incoming ACK Message
/// Returning nonzero means you are handling it and the normal framework should ignore it
Method OnInboundAck(pDoc As EnsLib.EDI.Document, ByRef pSC As %Status) As %Boolean
{
	If ..IgnoreInboundAck {
		$$$LOGWARNING("Not processing inbound "_pDoc.Name_" message "_pDoc_"/"_pDoc.getId())
		Set pDoc.IsMutable=0
		Quit 1
	}
	Quit 0
}

/// Override this method to implement your own custom method for validating an incoming Document
/// Return non-zero to prevent default validation of the message (if any);
Method OnValidate(pDoc As EnsLib.EDI.Document, pValSpec As %String, Output pStatus As %Status) As %Boolean
{
	Quit 0
}

/// Override this method to implement your own custom method for resolving the DocType of an incoming Message
/// Returning nonzero means you are overriding the framework's standard DocType resolution.
Method OnResolveDocType(pDoc As EnsLib.EDI.Document, ByRef pDocType As %String) As %Boolean
{
	Quit 0
}

Method standardOnProcessInput(pDocIn As EnsLib.EDI.X12.Document, Output pDocOut As EnsLib.EDI.X12.Document, pParseStatus As %Status = {$$$OK}) As %Status
{
	#dim tSC As %Status = pParseStatus
	#dim tSCVal As %Status = $$$OK
	#dim tSent As %Boolean = 0
	Set pDocOut=$$$NULLOREF, tReplyCode1=$S("None"=..CommitAckType:"",1:"A"), tDocID = pDocIn.getId()
	Set tReplyCode = ""
	Set:(..BatchHandling="Indiv") pDocIn.HandledIndividually = 1
	#; Important to set this here to avoid mis-processing an errored child document later on because of its ParentId having been set to ""
	Set tHasParent = (pDocIn.ParentId'="")
	$$$ASSERT($$$IsdefObject(pDocIn) && pDocIn.%IsA("EnsLib.EDI.X12.Document"))
	$$$sysTRACE("Got Document "_pDocIn_" / "_tDocID)
	If 'tHasParent && ("ISA"=pDocIn.GetValueAt("1:0")) {
		Set tName2=pDocIn.GetValueAt("2:0")
		If "TA1"=tName2 || ("GS"=tName2 && (("997"=pDocIn.GetValueAt("3:1")||("999"=pDocIn.GetValueAt("3:1"))))) {
			Quit:..OnInboundAck(pDocIn,.tSC) tSC
		}
	}
	Set tSCVal=..resolveAndIndex(pDocIn,tSC)
	Set tResponse=$$$NULLOREF

	#; Control whether batch messages appear in a single session together
	If '..%PreserveSession && (..%isNewBatch || '..%SingleBatchSession) {
		#; We do not want to clean %SuperSession if set before %SessionId
		If '..%SuperSessionCreatedBeforeSession  Set ..%SuperSession = ""
		Set ..%SessionId=""  Kill $$$JobSessionId
	}
	#; Forward the document in the appropriate way (sync, async, or not at all)
	If $$$ISOK(tSC)&&$$$ISOK(tSCVal)&&(""'=..TargetConfigNames) {
		If ..ReplyMode'="App" { ; 'Immediate' or 'None'
			#; Send Async; no reply required
			Set tReplyCode=..getReplyCode(pDocIn,tSC,tSCVal,0)
			If "Succ"=..BatchReplyType { Set:"A"=tReplyCode ..%TopReplyCode=tReplyCode }
			Else { Set:$Case(tReplyCode,"":0,"A":0,:1) ..%TopReplyCode=tReplyCode }
			If 'tHasParent || '..%DeferChildSend {
				If 'tHasParent && ..%DeferChildSend && '..%ForwardBatchWhole {
					If '..%ForwardBatchHeaders {
						#; Not sending pDocIn; save DocType & IsMutable updates
						$$$SyncCommitSet(tSyncCommit)
						Set tSC = pDocIn.%Save()
						$$$SyncCommitClear(tSyncCommit)
						If $$$ISERR(tSC) $$$LOGERROR("Failed to save message "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
					}
					#; loop through the batch and send them all
					Set $$$X12ValInfo(tDocID,"Code")=..%TopReplyCode ; set the top node to avoid error due to undefined
					Set tCode=..sendBatchChildren(pDocIn)
					Set tSent = 1
					If "Succ"=..BatchReplyType { Set:""'=tCode ..%TopReplyCode=tCode }
					Else { Set:$Case(tCode,"":0,"A":0,:1) ..%TopReplyCode=tCode }
					Set:""'=..%TopReplyCode tReplyCode=..%TopReplyCode
				} ElseIf ..%ForwardBatchHeaders || $Case(pDocIn.Name,"Interchange":0,"Group":0,:1) {
					If ((..BatchErrorAction="Indiv") && $Case(..ValMode,"SNIP":1,"Flags":..Validation'="",:0)) {
						If (pDocIn.Name = "Group") {
							Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).SplitGroup(.pDocIn,,.tBadBatch,..ValMode,$S(..ValMode="SNIP":..SNIPLevel,1:..Validation),1,(""'=..BadMessageHandler),0)
							If $$$ISERR(tSC) $$$LOGERROR("Failed to split group "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
						} ElseIf (pDocIn.Name = "Interchange") {
							Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).SplitBatch(.pDocIn,,.tBadBatch,..ValMode,$S(..ValMode="SNIP":..SNIPLevel,1:..Validation),1,(""'=..BadMessageHandler),0)
							If $$$ISERR(tSC) $$$LOGERROR("Failed to split batch "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
						}
					}
					$$$SyncCommitSet(tSyncCommit)
					For iTarget=1:1:$L(..TargetConfigNames,",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
						$$$sysTRACE("Sending X12 document "_pDocIn_" / "_tDocID_" from "_pDocIn.Source_" to '"_tOneTarget_"'")
						Set tSC1=..SendRequestAsync(tOneTarget,pDocIn)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
					}
					Set tSent = 1
					If $IsObject($G(tBadBatch)) {
						For iTarget=1:1:$L(..BadMessageHandler,",") { Set tOneTarget=$ZStrip($P(..BadMessageHandler,",",iTarget),"<>W")  Continue:""=tOneTarget
							$$$sysTRACE("Sending X12 document "_tBadBatch_" / "_tDocID_" from "_tBadBatch.Source_" to '"_tOneTarget_"'")
							Set tSC1=..SendRequestAsync(tOneTarget,tBadBatch)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
						}
					}
					$$$SyncCommitClear(tSyncCommit)
					If $$$ISOK(tSC) { $$$sysTRACE("After async forwarding X12 document "_tDocID_", reply code='"_tReplyCode_"'") }
					Else { Set tReplyCode=..getReplyCode(pDocIn,tSC,tSCVal,0) } ; get a new code since we have a new error
				} Else { ; Not sending; save DocType & IsMutable updates
					$$$SyncCommitSet(tSyncCommit)
					Set tSC = pDocIn.%Save()
					$$$SyncCommitClear(tSyncCommit)
					If $$$ISERR(tSC) $$$LOGERROR("Failed to save message "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
				}
			} Else { ; ""'=pDocIn.ParentId && ..%DeferChildSend
				#; Not sending yet; save DocType & IsMutable updates
				$$$SyncCommitSet(tSyncCommit)
				Set tSC = pDocIn.%Save()
				$$$SyncCommitClear(tSyncCommit)
				If $$$ISERR(tSC) $$$LOGERROR("Failed to save message "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
			}
		} Else { ; 'Application' mode
			#; Send Synchronous; reply required - for Application ACK mode
			If tHasParent && ..%DeferChildSend && ..%ForwardBatchWhole
			 || ('..%ForwardBatchHeaders && $Case(pDocIn.Name,"Interchange":1,"Group":1,:0)) {
				#; Just get code but don't send/forward child docs yet; save DocType & IsMutable updates
				#; note - ..%DeferChildSend not honored for non-Whole App mode (see warning in OnInit())
				$$$SyncCommitSet(tSyncCommit)
				Set tSC = pDocIn.%Save()
				$$$SyncCommitClear(tSyncCommit)
				If $$$ISERR(tSC) $$$LOGERROR("Failed to save message "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
				Set tReplyCode=..getReplyCode(pDocIn,tSC,tSCVal,0)
			} Else {
				If ""'=tReplyCode1 {
					$$$sysTRACE("sending immediate-Commit OK Ack; waiting for Application reply")
					$$$SyncCommitSet(tSyncCommit)
					Set tSC=pDocIn.%Save() ; save the message because we're going to ACK it.
					$$$SyncCommitClear(tSyncCommit)
					If $$$ISERR(tSC) $$$LOGERROR("Failed to save message "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
					Set tReplyCode1=..getReplyCode(pDocIn,tSC,tSCVal,-1)
					Do ..reportReply(pDocIn,tReplyCode1,.tSC,1)
					Set tReplyCode1="" ; done; suppress later send of commit reply
				}
				If $$$ISOK(tSC) {
					If ((..BatchErrorAction="Indiv") && $Case(..ValMode,"SNIP":1,"Flags":..Validation'="",:0)) {
						If (pDocIn.Name = "Group") {
							Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).SplitGroup(.pDocIn,,.tBadBatch,..ValMode,$S(..ValMode="SNIP":..SNIPLevel,1:..Validation),1,(""'=..BadMessageHandler),0)
							If $$$ISERR(tSC) $$$LOGERROR("Failed to split group "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
						} ElseIf (pDocIn.Name = "Interchange") {
							Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).SplitBatch(.pDocIn,,.tBadBatch,..ValMode,$S(..ValMode="SNIP":..SNIPLevel,1:..Validation),1,(""'=..BadMessageHandler),0)
							If $$$ISERR(tSC) $$$LOGERROR("Failed to split batch "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
						}
					}
					If 1'=$L(..TargetConfigNames,",") $$$LOGWARNING("More than one target config name specified for synchronous forwarding: "_..TargetConfigNames)
					$$$sysTRACE("Sending "_pDocIn_"/"_tDocID_" from "_pDocIn.Source_" to '"_..TargetConfigNames_"'")
					Set tSC=..SendRequestSync(..TargetConfigNames,pDocIn,.tResponse)
					Set tSent =1
					If $IsObject($G(tBadBatch)) {
						$$$SyncCommitSet(tSyncCommit)
						For iTarget=1:1:$L(..BadMessageHandler,",") { Set tOneTarget=$ZStrip($P(..BadMessageHandler,",",iTarget),"<>W")  Continue:""=tOneTarget
							$$$sysTRACE("Sending X12 document "_tBadBatch_" / "_tDocID_" from "_tBadBatch.Source_" to '"_tOneTarget_"'")
							Set tSC1=..SendRequestAsync(tOneTarget,tBadBatch)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
						}
						$$$SyncCommitClear(tSyncCommit)
					}
				}
				If '$IsObject(tResponse) { ; no reply message - we must construct one
					Set tReplyCode=..getReplyCode(pDocIn,tSC,tSCVal,1) ; get an App reply code to construct
					Set tTxt="Constructing reply with code '"_tReplyCode_"' because SendRequestSync() of "_pDocIn_"/"_tDocID_" returned with no response object and status: "_$$$StatusDisplayString(tSC)
					If $$$ISERR(tSC) { $$$LOGWARNING(tTxt) } ElseIf tReplyCode'="" { $$$sysTRACE(tTxt) }
				} Else {
					$$$sysTRACE("Returning reply document "_tResponse.getId()_" ("_tResponse.Name_") received from document "_tDocID_" forwarded to "_..TargetConfigNames)
				}
			}
		}
	} Else { ; not forwarding due to error or no target
		If tHasParent && ..%DeferChildSend {
			#; Not sending yet; save DocType & IsMutable updates
			$$$SyncCommitSet(tSyncCommit)
			Set tSC = pDocIn.%Save()
			$$$SyncCommitClear(tSyncCommit)
			If $$$ISERR(tSC) $$$LOGERROR("Failed to save message "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
		} Else {
			Set tReplyCode=..getReplyCode(pDocIn,tSC,tSCVal,0)
			If (""'=tReplyCode||("None"'=..CommitAckType))&&$$$ISOK(tSC)&&$$$ISOK(tSCVal) {
				$$$SyncCommitSet(tSyncCommit)
				Set pDocIn.IsMutable=0, tSC=pDocIn.%Save() ; save the document because we're going to reply that we got it.
				$$$SyncCommitClear(tSyncCommit)
				If $$$ISERR(tSC) {
					$$$LOGERROR("Failed to save document "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
					Set tReplyCode=..getReplyCode(pDocIn,tSC,tSCVal,-1) ; get a new code since we have a new error
				}
			}
			If $$$ISERR(tSCVal)&&(""'=..BadMessageHandler) {
				If 'tHasParent && ..%DeferChildSend && '..%ForwardBatchWhole {
					If '..%ForwardBatchHeaders {
						#; Not sending pDocIn; save DocType & IsMutable updates
						$$$SyncCommitSet(tSyncCommit)
						Set tSC = pDocIn.%Save()
						$$$SyncCommitClear(tSyncCommit)
						If $$$ISERR(tSC) $$$LOGERROR("Failed to save message "_pDocIn_" / "_tDocID_" : "_$$$StatusDisplayString(tSC))
					}
					#; loop through the batch and send them all to the Bad Message Handler
					Set tCode=..sendBatchChildren(pDocIn,1)
					Set tSent = 1
				} ElseIf ..%ForwardBatchHeaders || $Case(pDocIn.Name,"Interchange":0,"Group":0,:1) {
					$$$SyncCommitSet(tSyncCommit)
					For iTarget=1:1:$L(..BadMessageHandler,",") { Set tOneTarget=$ZStrip($P(..BadMessageHandler,",",iTarget),"<>W")  Continue:""=tOneTarget
						$$$sysTRACE("Sending X12 document "_pDocIn_" / "_tDocID_" from "_pDocIn.Source_" to '"_tOneTarget_"'")
						Set tSC1=..SendRequestAsync(tOneTarget,pDocIn)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
					}
					$$$SyncCommitClear(tSyncCommit)
					Set tSent = 1
				}
			}
			If ""=tReplyCode { $$$sysTRACE("Not returning reply for document "_pDocIn_"/"_tDocID_"; ReplyMode="_..ReplyMode_"; tReplyCode='"_tReplyCode_"'"_$S($$$ISERR(tSC):" status "_$$$StatusDisplayString(tSC),1:"")) }
			Else { $$$sysTRACE("Returning reply code "_tReplyCode_" but not forwarding document "_pDocIn_"/"_tDocID_$S($$$ISERR(tSC):" status "_$$$StatusDisplayString(tSC),1:"")_$S($$$ISERR(tSCVal):" validation status "_$$$StatusDisplayString(tSCVal),1:"")) }
		}
	}
	#; Send early/immediate Commit acknowledgement
	If ""'=tReplyCode1 {
		Set tReplyCode1=$S(""'=tReplyCode:tReplyCode, 1:..getReplyCode(pDocIn,tSC,tSCVal,-1)) ; force a code
		$$$sysTRACE("sending immediate-Commit Ack; code='"_tReplyCode1_"'")
		Do ..reportReply(pDocIn,tReplyCode1,.tSC,1)
	}
	#; Abort the current batch by telling the parser to just scan without notifying from here until the end of the current group and interchange
	Set:tHasParent&&$$$ISERR(tSC)&&..%AbortBatchOnError ..%Parser.FinishBatch=1

	#; Take the appropriate reply action for this document (construct/save/send)
	If $IsObject(tResponse) {
		Set pDocOut=..reportReply(pDocIn,tResponse,.tSC)
	} ElseIf ""'=tReplyCode {
		Set tSC=$$$ADDSC(tSC,tSCVal)
		Set pDocOut=..reportReply(pDocIn,tReplyCode,.tSC)
	}

	If 'tHasParent || ( ($P(pDocIn.ParentId,":",2)="") && (..%Parser.%CurrentParents = 0)) {
		If (tSent && (..BatchErrorAction="Indiv") && (""=..BadMessageHandler)) {
			// Loop though and delete individual children that failed validation.
			Set tChild = ""
			For {
				Set tChild = $O($$$X12ChildDoc(tDocID,tChild)) Quit:""=tChild
				Set tGrandchild = ""
				For {
					Set tGrandchild = $O($$$X12ChildDoc(tChild,tGrandchild)) Quit:""=tGrandchild
					If (($$$X12ValInfo(tGrandchild,"Code")="R") && ##class(EnsLib.EDI.X12.Document).%ExistsId(tGrandchild)) {
						Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(tGrandchild))
					}
					Kill $$$X12ValData(tGrandchild)
				}
				If (($$$X12ValInfo(tChild,"Code")="R")&&##class(EnsLib.EDI.X12.Document).%ExistsId(tChild)) {
					Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(tChild))
				}
				Kill $$$X12ValData(tChild)
			}
		}
		Else {
			// Loop through everything to at least kill the temporary validation data.
			// If the document was not sent anywhere, delete it and its children.
			If 'tSent {
				// No part of this batch was sent - delete all of it.

				// Make sure reply document does not get deleted when we delete the original.
				&sql(UPDATE EnsLib_EDI_X12.Document Set OriginalDocId = '' Where OriginalDocId=:tDocID)

				// If we ended up here because of a parsing error that prevented us from processing the parents,
				// make sure to delete temp data for the parents too
				If tHasParent {
					If $D($$$X12ValData($P(pDocIn.ParentId,":"))) {	
						If ((""'=$LG(pDocIn.ParentIds,2)) && $D($$$X12ValData($P($LG(pDocIn.ParentIds,2),":")))) {
							Set tDocID = $P($LG(pDocIn.ParentIds,2),":")
						} Else {
							Set tDocID = $P(pDocIn.ParentId,":")
						}
					}
				}
			}
			// Loop through everything in case children were saved even though the parent wasn't.
			Set tChild = ""
			For {
				Set tChild = $O($$$X12ChildDoc(tDocID,tChild)) Quit:""=tChild
				Set tGrandchild = ""
				For {
					Set tGrandchild = $O($$$X12ChildDoc(tChild,tGrandchild)) Quit:""=tGrandchild
					If ('tSent && ##class(EnsLib.EDI.X12.Document).%ExistsId(tGrandchild)) {
						Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(tGrandchild))
					}
					Kill $$$X12ValData(tGrandchild)
				}
				If ('tSent && ##class(EnsLib.EDI.X12.Document).%ExistsId(tChild)) {
					Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(tChild))
				}
				Kill $$$X12ValData(tChild)
			}
			If ('tSent && ##class(EnsLib.EDI.X12.Document).%ExistsId(tDocID)) {
				Set tSC = $$$ADDSC(tSC,##class(EnsLib.EDI.X12.Document).%DeleteId(tDocID))
			}
		} 
		Kill $$$X12ValData(tDocID)
	}
	Quit tSC
}

Method OnParsingError(pStatus As %Status, pDocument As EnsLib.EDI.X12.Document, pSeparators As %String = "") As %Status
{
	#dim tSC As %Status = pStatus
	#dim tSC1 As %Status = $$$OK
	Quit:'$$$ISERR(pStatus) tSC ; this should not happen

	#dim tDefaultSeparators As %String = pSeparators
	Set:""=$$$COMSEP(tDefaultSeparators) $$$COMSEP(tDefaultSeparators) = $Select(..DefCompSep'="":..DefCompSep,1:$$$X12DefComponentSeparator)
	Set:""=$$$REPSEP(tDefaultSeparators) $$$REPSEP(tDefaultSeparators) = $Select(..DefRepSep'="":..DefRepSep,1:$$$X12DefRepetitionSeparator)
	Set:""=$E(tDefaultSeparators,4) tDefaultSeparators = tDefaultSeparators_$Select(..DefSegTerm'="":..DefSegTerm,1:$$$X12DefSegTerminator)

	#dim tCode,tLine,tISA,tDataElementSeparator,tSegName,tNoteCode,tDocType As %String = ""
	#dim tReplyISA,tReplyIEA,tReplyTA1 As EnsLib.EDI.X12.Segment
	#dim tReplyDoc As EnsLib.EDI.X12.Document
	#dim tFinished,tCreateReplyDoc As %Boolean = 0

	Set tSC1 = $System.Status.DecomposeStatus(pStatus,.tErrList)
	Quit:$$$ISERR(tSC1) $$$ADDSC(tSC1,tSC)

	If $D(tErrList) {
		Set tCode = $G(tErrList(tErrList,"code"))
		Set tLine = $Case(tCode,
			"<EnsEDIX12>InvalidSegmentTerminator":$G(tErrList(tErrList,"param",2)),
			"<EnsEDIX12>UnexpectedEOD":$G(tErrList(tErrList,"param",1)),
			"<EnsEDIX12>TCPTerminatedReadTimeoutExpired":$S($D(tErrList(tErrList,"param",3),val)&&(val'="binary"):val,1:""),
			"<EnsEDIX12>ExpectedSegment":$G(tErrList(tErrList,"param",2)),
			"<EnsEDIX12>ISATruncated":$G(tErrList(tErrList,"param",2)),
			"<EnsErr>TCPReadTimeoutExpired":$G(tErrList(tErrList,"param",3)),
			"<EnsErr>TCPTerminatedReadTimeoutExpired":$G(tErrList(tErrList,"param",3)),
			"<EnsEDIX12>UnexpectedEODBinary":$G(tErrList(tErrList,"param",1)),
			"<EnsEDIX12>InvalidSegmentName":$G(tErrList(tErrList,"param",2)),
			"<EnsEDIX12>BinaryLeftover":$G(tErrList(tErrList,"param",1)),
			"<EnsEDIX12>BadBINLength":$G(tErrList(tErrList,"param",2)),
			:"")

		Set tDataElementSeparator=$E($ZStrip(tLine,"<AN"))
		Set:""'=tDataElementSeparator $$$ELESEP(tDefaultSeparators)=tDataElementSeparator
		Set tSegName = $P(tLine,tDataElementSeparator)
		If (tSegName = "ISA") {
			Set tISA = tLine
			Set tCreateReplyDoc = 1
		}
		If (tSegName'="ISA") && (tCode = "<EnsEDIX12>ExpectedSegment") && ($Case($G(tErrList(tErrList,"param",1)),"ISA":1,"GS":1,:0)) {
			Set tCreateReplyDoc = 1
			Set tISA = pDocument.GetValueAt(1)
			Set tDataElementSeparator=$E($ZStrip(tISA,"<AN"))
			Set:""'=tDataElementSeparator $$$ELESEP(tDefaultSeparators)=tDataElementSeparator
			Set:"ISA"'=$P(tISA,tDataElementSeparator) tISA=""
		}
		#; If this is an error which is caused entirely by the incoming document being poorly formatted (eg. missing GS, but no TCP timeout)
		#; then log it now instead of returning the error to OnProcessInput()
		If $Case(tCode,"<EnsEDIX12>InvalidSegmentTerminator":1,"<EnsEDIX12>ISATruncated":1,"<EnsEDIX12>ExpectedSegment":1,
			"<EnsEDIX12>UnexpectedEOD":$Select($G(tErrList(tErrList,"param",2))="":1,1:0),:0)&&tCreateReplyDoc {
				Set tFinished = 1
				$$$LOGSTATUS(pStatus)
		}
		
		Do {
			#; wait until here to quit, so we can still take appropriate actions with respect to what status to return and whether to delete the document
			Quit:((..ReplyMode="Never")||(..BatchReplyType="None"))
	
			If ..BatchReplyType="Byte" {
				$$$sysTRACE("Returning reply code R but not forwarding document due to errors parsing input")
				Set tSC1 = ..SendReply("R")
			} ElseIf tCreateReplyDoc {
				Set tReplyDoc=##class(EnsLib.EDI.X12.Document).%New($LB("",tDefaultSeparators))
				If '$IsObject(tReplyDoc) {
					Set tSC1=$$$ERROR($$$EnsEDIX12ErrGeneral,"Failed to instantiate reply document after receiving poorly formed input")
					Quit
				}
				
				#; Find the appropriate schema category to use - borrowed from ResolveDocType()
				Set tAcceptTypes=..DocSchemaCategory
				Set nTypes=$S(""=$ZStrip(tAcceptTypes,"<>W"):0, 1:$L(tAcceptTypes,","))
				Set (tVal,tDef)=""
				For i=1:1:nTypes {
					Set tType=$P(tAcceptTypes,",",i) Continue:""=tType
					Set tVal=$ZStrip($P(tType,"=",2),"<>W")
					Set tName=$ZStrip($P(tType,"=",1),"<>W"), tNameLen=$L(tName), tUName=$ZCVT(tName,"U")
					If ""=tVal {
						Set:""=tDef tDef=tName
					} Else {
						#; Quit on match; accept trailing wildcard also
						If "INTERCHANGE"=tUName || ("*"=$E(tName,tNameLen) && ($E(tUName,1,tNameLen-1)=$E("INTERCHANGE",1,tNameLen-1))) {
							If tVal[":" { Set tDocType=tVal }
							Else { Set tDocType=##class(EnsLib.EDI.X12.Schema).ResolveSchemaTypeToDocType(tVal,"Interchange") }
							Quit
						}
						Set tVal=""
					}
				}
				If (tDocType="") && (tDef'="") {
					Set tDocType=##class(EnsLib.EDI.X12.Schema).ResolveSchemaTypeToDocType($P(tDef,":"),"Interchange")
				}
				Do:""'=tDocType tReplyDoc.PokeDocType(tDocType)
				
				Set tReplyISA=##class(EnsLib.EDI.X12.Document).NewReplyHeaderSegsFromString(tISA,..LocalApplicationID,.tReplyIEA,.tSC1, tDefaultSeparators, tDocType)	Quit:$$$ISERR(tSC1)
				Set tSC1 = tReplyDoc.AppendSegment(tReplyISA)	Quit:$$$ISERR(tSC1)
				
				Set tNoteCode = $Case(tCode,
					"<EnsEDIX12>InvalidSegmentTerminator":$$$CodeTA1I18InvalidSegmentTerminator, ; The Segment Terminator is Invalid
					"<EnsEDIX12>UnexpectedEOD":$$$CodeTA1I18UnexpectedEndOfFile, ; Improper (Premature Ens-of-File (Transmission)
					"<EnsEDIX12>TCPTerminatedReadTimeoutExpired":$$$CodeTA1I18UnexpectedEndOfFile,
					"<EnsEDIX12>ISATruncated":$$$CodeTA1I18UnexpectedEndOfFile,
					"<EnsErr>TCPReadTimeoutExpired":$$$CodeTA1I18UnexpectedEndOfFile,
					"<EnsErr>TCPTerminatedReadTimeoutExpired":$$$CodeTA1I18UnexpectedEndOfFile,
					:$$$CodeTA1I18InvalidContent ; Invalid Interchange Content (e.g., Invalid GS Segment)
				)

				Set tReplyTA1 = ##class(EnsLib.EDI.X12.Document).NewReplyTA1SegFromString(tISA, tNoteCode, .tSC1, 1, tDefaultSeparators)	Quit:$$$ISERR(tSC1)
				If $IsObject(tReplyTA1) {
					Set tSC1 = tReplyDoc.AppendSegment(tReplyTA1)	Quit:$$$ISERR(tSC1)
				}
				
				If $IsObject(tReplyIEA) {
					#; No Functional Groups included - set IEA01 accordingly
					Set tSC1 = tReplyIEA.SetValueAt(0,$$$IEANumberofIncludedFunctionalGr)	Quit:$$$ISERR(tSC1)
					Set tSC1 = tReplyDoc.AppendSegment(tReplyIEA)	Quit:$$$ISERR(tSC1)
				}
				$$$sysTRACE("Constructed batch reply document '"_tReplyDoc_" / "_tReplyDoc.getId()_"' after receiving poorly formed input")
				
				Set tSC1 = ..SendReply(tReplyDoc)
			}
		} While 0
		
		#; If the actions we took here are sufficient to report the error, then don't block the file from being deleted, and do make sure the partial document object is deleted
		If tFinished {
			Set tSC = tSC1
		} Else {
			Set tSC = $$$ADDSC(tSC1,tSC)
		}
	}

	Quit tSC
}

/// Return ReplyCode 'R' if any Send errors occurred (Validation errors are already logged in ^IRIS.Temp)
Method sendBatchChildren(pDocIn As EnsLib.EDI.Document, pIsBad As %Boolean = 0) As %String [ Internal ]
{
	#; Send the children first, if any, then the current document
	Set tReplyCode="",tChildren="", tSC=$$$OK
	Set tID = pDocIn.getId()

	If 'pIsBad {
		If ((pDocIn.ParentId = "") && (..BatchErrorAction="Indiv") && $Case(..ValMode,"SNIP":1,"Flags":..Validation'="",:0)) {
			If (pDocIn.Name = "Group") {
				Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).SplitGroup(.pDocIn,,.tBadBatch,..ValMode,$S(..ValMode="SNIP":..SNIPLevel,1:..Validation),1,(""'=..BadMessageHandler),0)
				If $$$ISERR(tSC) $$$LOGERROR("Failed to split group "_pDocIn_" / "_tID_" : "_$$$StatusDisplayString(tSC))
			} ElseIf (pDocIn.Name = "Interchange") {
				Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).SplitBatch(.pDocIn,,.tBadBatch,..ValMode,$S(..ValMode="SNIP":..SNIPLevel,1:..Validation),1,(""'=..BadMessageHandler),0)
				If $$$ISERR(tSC) $$$LOGERROR("Failed to split batch "_pDocIn_" / "_tID_" : "_$$$StatusDisplayString(tSC))
			}
		}
		Set tChild=$$$NULLOREF
		For {
			Set tChild=pDocIn.NextChild(tChild)  Quit:tChild=$$$NULLOREF
			Set tCode=..sendBatchChildren(tChild)
			If "Succ"=..BatchReplyType { Set:"A"=tCode tReplyCode=tCode }
			ElseIf ("Indiv"'=..BatchErrorAction) { Set:$Case(tCode,"":0,"A":0,:1) tReplyCode=tCode }
		}
		If $IsObject($G(tBadBatch)) {
			For {
				Set tChild=tBadBatch.NextChild(tChild)  Quit:tChild=$$$NULLOREF
				Set tCode=..sendBatchChildren(tChild,1)
			}
		}
		
		#; Send the current document now, if it wasn't errored and it isn't filtered out
		Set tCode=$G($$$X12ValInfo(tID,"Code"),"")
		Set:""'=tCode tReplyCode=tCode
		Quit:$Case(tCode,"A":0, "":"Succ"=..BatchReplyType,"R":1, :0) tCode 
	} Else {
		Set tChild=$$$NULLOREF
		For {
			Set tChild=pDocIn.NextChild(tChild)  Quit:tChild=$$$NULLOREF
			Set tCode=..sendBatchChildren(tChild,1)
		}
	}

	If ..%ForwardBatchHeaders || $Case(pDocIn.Name,"Interchange":0,"Group":0,:1) {
		#; Send Async; no reply required
		$$$SyncCommitSet(tSyncCommit)
		If 'pIsBad {
			For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
				$$$sysTRACE("Sending X12 document "_pDocIn_" / "_tID_" from "_pDocIn.Source_" to '"_tOneTarget_"'")
				Set tSC1=..SendRequestAsync(tOneTarget,pDocIn)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
			}
		} Else {
			For iTarget=1:1:$L(..BadMessageHandler, ",") { Set tOneTarget=$ZStrip($P(..BadMessageHandler,",",iTarget),"<>W")  Continue:""=tOneTarget
				$$$sysTRACE("Sending X12 document "_pDocIn_" / "_tID_" from "_pDocIn.Source_" to Bad Message Handler '"_tOneTarget_"'")
				Set tSC1=..SendRequestAsync(tOneTarget,pDocIn)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
			}
		}
		If $IsObject($G(tBadBatch)) {
			For iTarget=1:1:$L(..BadMessageHandler, ",") { Set tOneTarget=$ZStrip($P(..BadMessageHandler,",",iTarget),"<>W")  Continue:""=tOneTarget
				$$$sysTRACE("Sending X12 document "_tBadBatch_" / "_tBadBatch.getId()_" from "_tBadBatch.Source_" to Bad Message Handler '"_tOneTarget_"'")
				Set tSC1=..SendRequestAsync(tOneTarget,tBadBatch)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
			}
		}
		$$$SyncCommitClear(tSyncCommit)
	}
	If $$$ISOK(tSC) {
		$$$sysTRACE("After async forwarding X12 document "_tID_", reply code='"_tReplyCode_"'")
		Quit $S("Succ"=..BatchReplyType:"A",1:tReplyCode)
	} Else {
		Set $$$X12ValInfo(tID,"SendErr")=tSC
		Quit $S("Succ"=..BatchReplyType:tReplyCode,1:"R")
	}
}

/// Accept only specified document names; resolve DocType and perform requested validation if any
Method resolveAndIndex(pDoc As EnsLib.EDI.X12.Document, pSC As %Status = {$$$OK}) As %Status
{
	#dim tSC As %Status =$$$OK
	Set tDocType=..resolveDocType(pDoc)
	Do pDoc.PokeDocType(tDocType)

	Set tDoValidate = 1

	If (pDoc.ParentId'="") && ("First"=..BatchErrorAction) {
		For i=1:1:$LL(pDoc.ParentIds) {
			If $G($$$X12ValInfo($P($LG(pDoc.ParentIds,i),":"),"HasError"),0) {
				Set tDoValidate = 0
			}
		}
	}

	#; Do further validation if required
	If tDoValidate {
		If "Flags"=..ValMode {
			Set tDocID = pDoc.getId()
			If (..BatchErrorAction="First")&&(($G($$$X12ValInfo(tDocID,"Code"))="R")||((pDoc.ParentId'="")&&($G($$$X12ValInfo($P(pDoc.ParentId,":"),"Code"))="R"))) {
				Quit $$$ERROR($$$EnsEDIX12ErrGeneral,$$$FormatText($$$Text("Skipping validation of document %1 due to earlier validation failure."),tDocID))
			}
			Set tValSpec=..Validation
			Set:tValSpec=1 tValSpec="dm"
			Set tValSpec=##class(EnsLib.MsgRouter.RoutingEngine).normalizeValSpec(tValSpec)
			If ""'=..Validation&&'..OnValidate(pDoc,tValSpec,.tSC) {
				If ..Validation["," {
					// for backwards compatibility - if using commas, probably left-over from when description said string should be comma-separated and when we only provided d and m as ValSpec options
					Set tTempValSpec = $S((tValSpec["d"):"d", 1:"")
					Set:(tValSpec["m") tTempValSpec = tTempValSpec_"m"
					Set tValSpec = tTempValSpec	
				}
				If ..BatchErrorAction="First" {
					#; If Reject On First Error, then don't continue beyond first error
					Set tValSpec = $Translate(tValSpec,"eE")
				} ElseIf $Case(..BatchErrorAction,"All":1,"Indiv":1,:0) && (tValSpec'["e") {
					#; If Reject With All Errors or Individual, then find all errors
					Set tValSpec = tValSpec_"e"
				}
				Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).Validate(pDoc,tValSpec,0,1,..BatchErrorAction)
			}
			Set:($$$ISERR(tSC)&&(""=pDoc.ParentId)&&(..BatchErrorAction'="Note")) ..%TopReplyCode = "R"
		} ElseIf "SNIP"=..ValMode {
			Set tSC = ##class(EnsLib.EDI.X12.Util.Validator).PerformSNIPValidation(pDoc,..SNIPLevel,..BatchErrorAction,pSC,0)
			Set:($$$ISERR(tSC)&&(""=pDoc.ParentId)) ..%TopReplyCode = "R"
		}
		If $$$ISERR(tSC)&&'$$$ISERR(pSC) {
			$$$LOGSTATUS(tSC)
			Quit tSC
		}
	}
	If (""'=..SearchTableClass) {
		try {
			Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",pDoc)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_pDoc_"/"_pDoc.getId()_" with DocType='"_pDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} catch { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_pDoc_"/"_pDoc.getId()_" with DocType='"_pDoc.DocType_"' : "_$$$StatusDisplayString($$$SystemError)) }
	}
	Quit tSC
}

/// Return the DocType that this service will assign to this document
Method resolveDocType(pDoc As EnsLib.EDI.X12.Document) As %String
{
	Set tDocType=pDoc.DocType
	If ""=tDocType {
		#; Match with the DocType specified if any in DocSchemaCategory for the received Document's type name
		Set tAcceptTypes=..DocSchemaCategory, tNameFound=pDoc.Name, tUNameFound=$ZCVT(tNameFound,"U")
		Set tImplGuide=""
		If "ST"=pDoc.GetValueAt("1:0") {
			Set tImplGuide=pDoc.GetValueAt("1:3")
			Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
			If ""=tImplGuide {
				Set tGroup=pDoc.Parent
				Set:$IsObject(tGroup) tImplGuide=tGroup.GetValueAt("1:8")
				Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
				If ""=tImplGuide {
					Set tRef=pDoc.FindSegment("REF")
					Set:$IsObject(tRef) tImplGuide=tRef.GetValueAt(2)
					Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
				}
			}
		}
		Set tPurpose=$S("BHT"=pDoc.GetValueAt("2:0"):pDoc.GetValueAt("2:2"),1:"")
		Set nTypes=$S(""=$ZStrip(tAcceptTypes,"<>W"):0, 1:$L(tAcceptTypes,","))
		Set (tVal,tDef)=""
		For i=1:1:nTypes { Set tType=$P(tAcceptTypes,",",i) Continue:""=tType
			Set tVal=$ZStrip($P(tType,"=",2),"<>W")
			Set tName=$ZStrip($P(tType,"=",1),"<>W"), tNameLen=$L(tName), tUName=$ZCVT(tName,"U")
			If ""=tVal {
				Set:""=tDef tDef=tName
			} Else {
				#; Quit on match; accept trailing wildcard also
				If tUNameFound=tUName
				 || ("*"=$E(tName,tNameLen) && ($E(tUName,1,tNameLen-1)=$E(tUNameFound,1,tNameLen-1))) {
					If tVal[":" { Set tDocType=tVal }
					Else { Set tDocType=##class(EnsLib.EDI.X12.Schema).ResolveSchemaTypeToDocType(tVal,tNameFound,,tImplGuide,tPurpose) }
					Quit
				}
				Set tVal=""
			}
		}
		If ""'=tDocType {
			If tVal[":" {
				$$$sysTRACE("Using DocType='"_tDocType_"' for type name '"_tNameFound_"' matching '"_tUName_"' in DocSchemaCategory list; calling OnResolveDocType()")
			} Else {
				$$$sysTRACE("Using DocType='"_tDocType_"' from schema category '"_tVal_"' for type name '"_tNameFound_"' matching '"_tUName_"' in DocSchemaCategory list; calling OnResolveDocType()")
			}
		} ElseIf ""'=tVal {
			$$$sysTRACE("No DocType returned from ResolveSchemaTypeToDocType() using schema category "_tVal_" found for type name '"_tNameFound_"' matching '"_tUName_"' in DocSchemaCategory list '"_tAcceptTypes_"'; calling OnResolveDocType()")
		} ElseIf ""'=tDef {
			If tDef[":" {
				Set tDocType=tDef
				$$$sysTRACE("Using default DocType='"_tDocType_"' from DocSchemaCategory list '"_tAcceptTypes_"'; type name '"_tNameFound_"' not matched specifically; calling OnResolveDocType()")
			} Else {
				Set tDocType=##class(EnsLib.EDI.X12.Schema).ResolveSchemaTypeToDocType(tDef,tNameFound,,tImplGuide,tPurpose)
				If ""'=tDocType {
					$$$sysTRACE("Using DocType='"_tDocType_"' returned from ResolveSchemaTypeToDocType() using default schema category in DocSchemaCategory list '"_tAcceptTypes_"'; type name '"_tNameFound_"' not matched specifically; calling OnResolveDocType()")
				} Else {
					$$$sysTRACE("No DocType returned from ResolveSchemaTypeToDocType() using default schema category '"_tDef_"' in DocSchemaCategory list '"_tAcceptTypes_"'; type name '"_tNameFound_"' not matched specifically; calling OnResolveDocType()")
				}
			}
		} Else {
			$$$sysTRACE("No match or default DocType found for type name '"_tNameFound_"' in DocSchemaCategory list '"_tAcceptTypes_"'; calling OnResolveDocType()")
		}
	} Else {
		$$$sysTRACE("Accepted document with DocType='"_tDocType_"'; calling OnResolveDocType()")
	}
	Set ttDocType=tDocType  If ..OnResolveDocType(pDoc,.ttDocType) {
		Set tDocType=$G(ttDocType)
		$$$sysTRACE("OnResolveDocType returned DocType="_tDocType)
	}
	Quit tDocType
}

/// pEarlyReply=0 means normal reply, -1 means "Immediate Commit Ack", 1 means Application reply
/// Return the appropriate reply code, or empty string if no Ack needed for the specified mode
Method getReplyCode(pDoc As EnsLib.EDI.Document, pSC As %Status, pSCVal As %Status, pEarlyReply As %Boolean) As %String
{
	If '($D($$$X12ValInfo(pDoc.getId(),"Code"),tCode)#2)||(""=tCode) { 
		#; Choose the appropriate Status character
		Set tCode=$S(($$$ISERR(pSC)||$$$ISERR(pSCVal)):"R", 1:"A")
	}
	#; "HasError" subscript used for tracking batches in which envelope passed, but some Transaction Set had a validation error
	Set tHasError = $G($$$X12ValInfo(pDoc.getId(),"HasError"),0)

	If pEarlyReply=-1 {
		Quit:"None"=..CommitAckType ""
	} Else {
		Set tCode=$Case(..ReplyMode,"Never":""
						, :$Case(..BatchReplyType
								,"None"    :""
								,"Errs"    :$S("A"'=tCode:tCode, ""=pDoc.ParentId:"A", 1:"")
								,"OnlyErrs":$S("A"'=tCode:tCode,tHasError:"R",1:"")
								,"Succ"    :$S(""=pDoc.ParentId:$S(""=..%TopReplyCode:"R",1:..%TopReplyCode), "A"'=tCode:"", 1:tCode)
								,"ErrTA1"  :$S("A"'=tCode:tCode,tHasError:"R",1:"")
								,"I14Err"  :$S("A"'=tCode:tCode,tHasError:"R",1:"")
								,:tCode))
		Quit:""=tCode ""
	}
	If "Succ"=..BatchReplyType { Set:"A"=tCode ..%TopReplyCode=tCode }
	Else { Set:$Case(tCode,"":0,"A":0,:1) ..%TopReplyCode=tCode }
	Quit:pDoc.ParentId=""&&(""'=..%TopReplyCode) ..%TopReplyCode
	Quit tCode
}

Method reportReply(pOriginalDoc As EnsLib.EDI.Document, pReplyCode As %String = "", ByRef pSC As %Status, pEarlyReply As %Integer = 0) As EnsLib.EDI.Document
{
	Set tSC=pSC, tID=pOriginalDoc.getId()
	Set tReplyDoc=..constructReply(pOriginalDoc,.pReplyCode,.pSC,pEarlyReply)
	
	If $$$ISERR(pSC) {
		$$$LOGSTATUS(pSC)
		Quit $$$NULLOREF
	}
	If ""=pOriginalDoc.ParentId {
		If $IsObject(tReplyDoc) {
			Set pSC=$$$OK
			If ""'=..SearchTableClass && ..#IndexReplies && tReplyDoc.%Extends("EnsLib.EDI.Document") {
				Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",tReplyDoc)
				If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for reply document "_tReplyDoc_" / "_tReplyDoc.getId()_" with DocType='"_tReplyDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
			}
		} ElseIf ""=tReplyDoc { Quit "" }
		$$$sysTRACE("Reporting reply document '"_tReplyDoc_"' for document "_pOriginalDoc_" / "_tID)
		Set:$Case(..%outFraming,"uninitialized":(..%Parser.%outFraming'="xxf"),"xxf":1,:0) ..%outFraming=..%Parser.%outFraming

		Set pSC=..SendReply(tReplyDoc,pOriginalDoc)
	} Else {
		#; Remember individual reply docs for final batch reply
		If $IsObject(tReplyDoc) {
			Set pSC=$$$OK
			Set:$IsObject(pReplyCode) pReplyCode=..getReplyChildDocCode(tReplyDoc) ; get code from app reply object
			$$$sysTRACE("Deferring reply document "_tReplyDoc_" for document "_pOriginalDoc_" / "_tID)
			Set $$$X12ValInfo(tID,"ID")=tReplyDoc.getId() ; TODO: make use of this reply doc

			If ""'=..SearchTableClass && ..#IndexReplies && tReplyDoc.%Extends("EnsLib.EDI.Document") {
				Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",tReplyDoc)
				If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for reply document "_tReplyDoc_" / "_tReplyDoc.getId()_" with DocType='"_tReplyDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
			}
		} Else {
			Set pReplyCode=tReplyDoc
			$$$sysTRACE("Deferring reply code "_pReplyCode_" for document "_pOriginalDoc_" / "_tID_"; status: "_$$$StatusDisplayString(tSC))
		}
		Quit:""=tReplyDoc $$$NULLOREF
	}
	If $$$ISERR(pSC) $$$LOGSTATUS(pSC)
	Quit $$$NULLOREF ; default behavior is not to return the reply doc from OnProcessInput()
}

/// get code from app reply object
Method getReplyChildDocCode(pAppReplyDoc As EnsLib.EDI.Document) As %String
{
	Quit "A" ; !! fish it out from the object...
}

Method constructReply(pOriginalDoc As EnsLib.EDI.Document, ByRef pReplyCode As %String, ByRef pSC As %Status, pEarlyReply As %Integer) As EnsLib.EDI.Document
{
	Set tReplyType=$S(pEarlyReply:..CommitAckType, 1:..BatchReplyType)
	Quit:'..%ISARequestsTA1&&$Case(tReplyType,"I14":1,"I14Err":1,:0) $$$NULLOREF
	Quit:""=..%TopReplyCode&&..%ConditionalReply $$$NULLOREF

	Set tSC=pSC, tOldCode=pReplyCode, pSC=..OnConstructReply(.tReplyDoc, pOriginalDoc,.pReplyCode,tSC,pEarlyReply)  If $$$ISERR(pSC) $$$LOGSTATUS(pSC) Quit $$$NULLOREF
	Set tOriginalDocID = pOriginalDoc.getId()
	Set:'$D(tReplyDoc) tReplyDoc=pReplyCode
	If $IsObject(tReplyDoc) {
		#; Customer-built reply; Quit with what we have
		If '$IsObject(tOldCode) $$$sysTRACE("OnConstructReply created batch reply document '"_tReplyDoc_" / "_tReplyDoc.getId()_"' for original document "_pOriginalDoc_" / "_tOriginalDocID_"; status: "_$$$StatusDisplayString(pSC))
		Set tReplyDoc.OriginalDocId=tOriginalDocID
		Quit tReplyDoc
	}
	Quit:pOriginalDoc.ParentId'="" tReplyDoc ; child doc; quit with what we have
	If pOriginalDoc.Name'="Interchange" {
		#; Non-Interchange parent doc - we should never be asked to reply to such a thing; this will be a strange result
		Set tReplyDoc=pOriginalDoc.NewReplyDocument("",..LocalApplicationID,.pSC)
		$$$sysTRACE("Constructed non-interchange reply document '"_tReplyDoc_"' for original document "_pOriginalDoc_" / "_tOriginalDocID_"; status: "_$$$StatusDisplayString(pSC))
		Set:$IsObject(tReplyDoc) tReplyDoc.OriginalDocId=tOriginalDocID
		Quit tReplyDoc
	}
	If tReplyType="Byte" {
		Quit:(""'=..%TopReplyCode) ..%TopReplyCode
		If $$$ISERR(tSC) || ($$$CodeTA1I18NoError '= ##class(EnsLib.EDI.X12.Validator).GetTA1Code(,pOriginalDoc)) {
			Quit "R"
		}
		Quit "A"
	}

	#; Create new Interchange document with the configured reply segments
	#; for each of the original doc's children
	Set pSC=tSC, tReplyDoc=..constructBatchReply(pOriginalDoc,.pSC,pEarlyReply)

	$$$sysTRACE("Constructed reply document '"_tReplyDoc_$S('$$$IsdefObject(tReplyDoc):"'",1:"' of type '"_tReplyDoc.Name_"'")_" for original document "_pOriginalDoc_" / "_tOriginalDocID_"; code: "_..%TopReplyCode_"; status: "_$$$StatusDisplayString(pSC))
	Quit tReplyDoc
}

/// Override this method to construct a customized reply document. Inputs are the original document and
///  the reply code and the status code that the framework produced in processing the original document.
///  If you change the status code but do not construct a reply document, the framework will use the new value to construct a standard reply document.
Method OnConstructReply(Output pReplyDoc As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document, ByRef pReplyCode As %String, ByRef pSC As %Status, pEarlyReply As %Boolean) As %Status
{
	Quit $$$OK
}

Method constructBatchReply(pOriginalDoc As EnsLib.EDI.X12.Document, ByRef pSC As %Status, pEarlyReply As %Boolean) As EnsLib.EDI.Document
{
	#dim tDoc As EnsLib.EDI.X12.Document
	#dim tSeg As EnsLib.EDI.X12.Segment
	#dim tOriginalDocID = pOriginalDoc.getId()
	#dim tEncounteredFirstErr As %Boolean = 0
	#dim tForceTA1,tInterchangeLevelErr As %Boolean = 0
	
	#dim tIncludeReplyBody As %Boolean = (..%Do997s && 'pEarlyReply && (""'=..%TopReplyCode))  ; %TopReplyCode is non-empty if we found any TS to report
	
	#; Include TA1 even if no Interchange-level error if BatchReplyType and/or ISA14 calls for it
	Set tReplyType=$S(pEarlyReply:..CommitAckType, 1:..BatchReplyType)
	Set tForceTA1 = $Select(tReplyType="TA1":1,1:$Case(..%ForceTA1, -1:''..%ISARequestsTA1, :(..%ForceTA1>0)))
	
	Kill %objlasterror
	
	If tIncludeReplyBody {
		Set tReplyDoc = ##class(EnsLib.EDI.X12.Util.Validator).ConstructBatchReply(pOriginalDoc,.pSC,..BatchReplyType,tForceTA1,..BatchErrorAction,..ValMode_":"_..SNIPLevel,..LocalApplicationID,..AddNackErrText,0)
	} Else {
		Set tReplyDoc = ##class(EnsLib.EDI.X12.Util.Validator).ConstructReplyEnvelope(pOriginalDoc,.pSC,tForceTA1,..AddNackErrText,..LocalApplicationID,,.tReplyIEA)
		If $IsObject(tReplyDoc)&&$IsObject(tReplyIEA) {
			Do tReplyDoc.AppendSegment(tReplyIEA)
		}
	}

	$$$sysTRACE("Constructed batch reply document '"_tReplyDoc_" / "_tReplyDoc.getId()_"' for original document "_pOriginalDoc_" / "_tOriginalDocID_"; status: "_$$$StatusDisplayString(pSC))
	Quit tReplyDoc
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document) As %Status
{
	Quit $$$EnsError($$$EnsEDIX12ErrGeneral, "Service does not support Reply; Document "_pReplyDocument)
}

/// Callbacks from Parser:
/// 
Method OnDocumentStart(pDocument As EnsLib.EDI.Document, pSource As %String, pStatus As %Status) As %Status
{
	#dim tSC As %Status = $$$OK
	#; top parent ; Interchange
	If ""=pDocument.ParentId {
		Set ..%ISARequestsTA1=("ISA"=pDocument.GetValueAt("1:0")&&pDocument.GetValueAt("1:14"))
		Set ..%TopReplyCode=$Case(..BatchReplyType,"All":"A","AllTA1":"A","AllI14TA1":"A","TA1":"A","I14":"A","Byte":"A",:"")
		$$$sysTRACE("New top document "_pDocument_" / "_pDocument.getId()_" received, setting %ISARequestsTA1="_..%ISARequestsTA1_", %TopReplyCode='"_..%TopReplyCode_"'")
	} Else {
		$$$sysTRACE("New child document "_pDocument_" / "_pDocument.getId()_" received")
	}
	If $$$ISERR(tSC) {
		$$$LOGERROR(tSC)
	}
	Quit $$$OK
}

Method OnDocumentEnd(pDocument As EnsLib.EDI.Document, pSource As %String, pStatus As %Status) As %Status
{
	#; Ignore errors; we use the default Reply Document object not this return value
	Do:..%ForwardBatchWhole<=1 ..standardOnProcessInput(pDocument,.tDocOut,pStatus)
	#; Else (If ..%ForwardBatchWhole>1) do nothing; this value means don't let Service process the document; we're in ImportFrom...()
	Set ..%isNewBatch=(""=pDocument.ParentId)
	Quit $$$OK
}

/// Return the segment terminator string that the Parser and the document.ImportFromIOStream() method will use.
Method GetSegmentTerminator() As %String
{
	Quit $Select((""'=..DefSegTerm)&&($E(..DefSegTerm)'?1(1A,1N)):$E(..DefSegTerm),1:$$$X12DefSegTerminator)
}

ClassMethod GetRequestClassList() As %String [ CodeMode = objectgenerator, GenerateAfter = OnProcessInput ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"standardOnProcessInput",$$$cMETHformalspecparsed)
	Set tClass=$lg($lg(tSignature,1),2)
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnProcessInput",$$$cMETHformalspecparsed)
	Set tClass=tClass_""","""_$lg($lg(tSignature,1),2)
	Do %code.WriteLine(" Quit $lb("""_tClass_""")")
	Quit $$$OK
}

ClassMethod GetResponseClassList(pRequest As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = OnProcessInput ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"standardOnProcessInput",$$$cMETHformalspecparsed)
	Set tRequest1=$lg($lg(tSignature,1),2)
	Set tClass1=$lg($lg(tSignature,2),2)
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnProcessInput",$$$cMETHformalspecparsed)
	Set tRequest2=$lg($lg(tSignature,1),2)
	Set tClass2=$lg($lg(tSignature,2),2)

	Set tClass12=tClass1_$S(tClass1=tClass2:"",1:""","""_tClass2)
	If tRequest1=tRequest2 {
		Set (tClass1,tClass2)=tClass12
	}
	Do %code.WriteLine(" Quit:pRequest="""" $lb("""_tClass12_""")")
	Do %code.WriteLine(" Quit:pRequest="""_tRequest1_""" $lb("""_tClass1_""")")
	Do %code.WriteLine(" Quit:pRequest="""_tRequest2_""" $lb("""_tClass2_""")")
	Do %code.WriteLine(" Quit $lb("""")")
	Quit $$$OK
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
	If pItem.GetModifiedSetting("BadMessageHandler",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

/// Add discarded characters to IO Archive
Method IOLogDiscard(pSC As %Status, pNote As %String, pDiscard As %GlobalCharacterStream)
{
	Set tIOLogEntry = ..IOLogEntry, ..IOLogEntry=$$$NULLOREF ; Save a separate entry for the unexpected input
	$$$NEWINIOLOGENTRY(pSC,pNote,pDiscard)
	$$$CLOSEIOLOGENTRY($$$OK,"",$$$NULLOREF)
	Set ..IOLogEntry = tIOLogEntry
}

}
