/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.Util.IOFraming [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// X12 Document outbound framing protocol; options: <br/>
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
Property Framing As %String(DISPLAYLIST = ",None,Epic02/03,Ascii11/28,Ascii11,AsciiLF,AsciiCR,MLLP,MLLP11/28,MsgEnvelope,MLLPMsgEnvelope") [ InitialExpression = "None" ];

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

Parameter SETTINGS As %String = "Framing:Connection:selector?context={Ens.ContextSearch/getDisplayList?host=@currHostId&prop=Framing}";

/// Framing to use on output if input framing is "Flexible"
Property %outFraming As %String [ InitialExpression = "uninitialized" ];

Method OutputFramedToDevice(pDoc As EnsLib.EDI.X12.Document, pSeparators As %String, pInbound As %Boolean = 0, ByRef pIOLogEntry As Ens.Util.IOLog = {$$$NULLOREF}, pDoFraming As %Integer) As %Status
{
	Set tDeviceStream=##class(%IO.DeviceStream).AttachNew(,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..OutputFramedToIOStream(tDeviceStream, .pDoc, .pSeparators, .pInbound, .pIOLogEntry, .pDoFraming)
}

/// Write an X12 Document to the given IO Stream
/// Returned %Status codes are not logged, except for Exceptions
/// pDoFraming: 0=no framing, 1=full framing, -1=prefix only, 2=suffix only
Method OutputFramedToIOStream(pIOStream As %IO.I.CharacterStream, pDoc As EnsLib.EDI.X12.Document, pSeparators As %String, pInbound As %Boolean = 1, ByRef pIOLogEntry As Ens.Util.IOLog = {$$$NULLOREF}, pDoFraming As %Integer = 1) As %Status
{
	#define MapCtlChars(%s)	$TR(%s,$C(1,2,3,9,10,11,13,28),"123tlsre")

	If "uninitialized"=..%outFraming {
		Set ..%outFraming=##class(EnsLib.EDI.X12.Parser).applyFraming(..Framing,"")
	}
	Set tPrefix=$P(..%outFraming,"xx"), tOutFraming=$E(..%outFraming,$L(tPrefix)+3,$L(..%outFraming)), tSuffix=$P(tPrefix,"x",2), tPrefix=$P(tPrefix,"x")
	If $IsObject(pDoc)&&pDoc.%Extends("%Persistent") {
		If $IsObject(pIOLogEntry)&&pIOLogEntry.%Extends("Ens.Util.IOLogObject") {
			Set pIOLogEntry.OutObject=pDoc  Do:""=pDoc.%Id() pDoc.%Save()
		}
		Set tDocId=pDoc.%Id()
	} Else {
		Set tDocId=""
	}
	Set tISAEncoding=$S("!"=$E(..DefCharEncoding):$E(..DefCharEncoding,2,*),1:..DefCharEncoding)
	If ""=tISAEncoding || (""=##class(%IO.I.TranslationDevice).GetCharEncodingTable(tISAEncoding)) {
		If ""'=tISAEncoding $$$LOGWARNING("No translation table found for specified character encoding '"_tISAEncoding_"'; Using 'ISO-8859-1' ('Latin1')")
		Set tISAEncoding="ISO-8859-1"
	}
	Set tDocInfo=$S('$IsObject(pDoc):"'"_pDoc_"'", 1:pDoc_" / "_tDocId_" with separators='"_$S(""=$G(pSeparators):pDoc.Separators,1:pSeparators)_"'")_" to "_pIOStream.Name_" using framing "_$$$MapCtlChars(..%outFraming)_$S(""=(tPrefix_tSuffix):"", 1:" (prefix '"_$$$MapCtlChars(tPrefix)_"' and suffix '"_$$$MapCtlChars(tSuffix)_"')"_" using encoding "_tISAEncoding)
	$$$sysTRACE("Writing "_$Case(+pDoFraming,0:"bare document",1:"document",2:"suffix",:"prefix")_" "_tDocInfo)
	Set pIOStream.CharEncoding=tISAEncoding
	Do {
		Set tFlush=(pDoFraming<0), tSC=$$$OK
		If "<->"=..%outFraming&&$IsObject(pDoc)&&pDoFraming&&(pDoFraming'=2) {
			Do pIOStream.Write($P(pDoc.Envelope,"<!--X12DOC-->"),tFlush&&'$L(tPrefix),.tSC)  Quit:$$$ISERR(tSC)
			Set tCloseFrame=$P(pDoc.Envelope,"<!--X12DOC-->",2)
		} Else { Set tCloseFrame="" }
		If $L(tPrefix)&&pDoFraming&&(pDoFraming'=2) Do pIOStream.Write(tPrefix,tFlush,.tSC)  Quit:$$$ISERR(tSC)
		If $Case(pDoFraming, 0:1, 1:1, :0) {
			Set tFlush='pDoFraming||((""=tSuffix)&&(""=tCloseFrame))
			If '$IsObject(pDoc) {
				Do pIOStream.Write(pDoc,tFlush,.tSC)  Quit:$$$ISERR(tSC)
			} ElseIf "ACK_1_"=$E(pDoc.Envelope,1,$L("ACK_1_")) {
				Do pIOStream.Write($P(pDoc.Envelope,":",2),tFlush,.tSC)  Quit:$$$ISERR(tSC)
			} Else {
				Set tSC=pDoc.OutputToIOStream(pIOStream,.pSeparators,tFlush)  Quit:$$$ISERR(tSC)
			}
		}
		If pDoFraming>0 {
			If ""'=tSuffix { Do pIOStream.Write(tSuffix,(""=tCloseFrame),.tSC)  Quit:$$$ISERR(tSC) }
			If ""'=tCloseFrame { Do pIOStream.Write(tCloseFrame,1,.tSC)  Quit:$$$ISERR(tSC) }
		}
	} While 0
	If $IsObject(pIOLogEntry) {
		Set pIOLogEntry.Annotation = $S(""=pIOLogEntry.Annotation:"",1:pIOLogEntry.Annotation_" | ")_"Wrote document "_tDocInfo
	}
	Quit tSC
}

/// Call this method after initializing or resetting the parser to force a particular output framing style different from the input framing style that is either specified or detected.
Method SetOutFraming(pFraming As %String)
{
	Set ..%outFraming=##class(EnsLib.EDI.X12.Parser).applyFraming(pFraming)
}

}
