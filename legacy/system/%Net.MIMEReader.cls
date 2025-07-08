/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.MIMEReader">MIME Messages</a>.</p>
/// %Net.MIMEReader inputs a MIME document and represents it by a top-level <class>%Net.MIMEPart</class>
/// with multiple parts specified.
Class %Net.MIMEReader Extends %RegisteredObject [ System = 4 ]
{

/// Stream containing the MIME message.
/// Declared as %RegisteredObject to prevent auto create of serial object.
Property inputStream As %RegisteredObject [ Private ];

/// Current buffer for stream input.
Property buffer As %String [ Private ];

/// Position of next input to process in the stream buffer
Property pos As %Integer [ Private ];

/// If true, previous line ended in CR which was discarded
Property previousCR As %Boolean [ Private ];

/// Open file that contains the MIME message.
Method OpenFile(source As %String) As %Status
{
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=source
	Set ..inputStream=stream
	Set ..buffer=""
	Set ..pos=1
	Set ..previousCR=0
	Quit $$$OK
}

/// Open stream that contains the MIME message.
Method OpenStream(source As %AbstractStream) As %Status
{
	Set ..inputStream=source
	Set ..buffer=""
	Set ..pos=1
	Set ..previousCR=0
	Quit $$$OK
}

/// <method>ReadMIMEMessage</method> parses the MIME message in previously opened
/// file or stream, and creates a %Net.MIMEPart based on this MIME message.
Method ReadMIMEMessage(Output message As %Net.MIMEPart) As %Status
{
	Try {
		Set sc=..readHeader(.message,0)
		If $$$ISOK(sc) Set sc=..readBody(message,"")
	} Catch error {
		Set sc=error.AsStatus()
	}
	
	Quit sc
}

/// <method>ReadMIMEBody</method> parses the MIME body in previously opened file or stream
/// and makes it the body the MIME message represented by <var>message</var> %Net.MIMEPart.
/// Headers for the MIME message are assumed to have been processed and included in <var>message</var>.
Method ReadMIMEBody(message As %Net.MIMEPart) As %Status
{
	// Just set the body if not multipart
	If $zcvt($piece(message.ContentType,"/",1),"L")'="multipart" {
		Set message.Body=..inputStream
		Quit $$$OK
	}
	
	// Parse multipart body
	Try {
		Set sc=..readBody(message,"")
	} Catch error {
		Set sc=error.AsStatus()
	}
	
	Quit sc
}

/// Read the headers of the current message part and create the %Net.MIMEPart.
Method readHeader(Output message As %Net.MIMEPart, isMultiPart As %Boolean) As %Status
{
	Set sc=$$$OK
	Set name=""
	Set message=##class(%Net.MIMEPart).%New()
	
	For {
		Set sc=..getLine(.line)
		If $$$ISERR(sc) || (line=$c(13,10)) || ('isMultiPart && (line="")) Quit
		If line="" Set sc=$$$ERROR($$$MIMEUnexpectedEnd) Quit
		If $extract(line,*-1,*)'=$c(13,10) Set sc=$$$ERROR($$$MIMEBadHeader) Quit
		Set line=$zstrip(line,">W",$c(13,10))
		
		If $case($extract(line),$c(9):1," ":1,:0) {
			If name="" Set sc=$$$ERROR($$$MIMEBadHeader) Quit
			Set line=$zstrip(line,"<W")
			Set sep=" "
			If ($extract(line,1,2)="=?") {
				Set word=$piece($tr(line,$c(9)," ")," ",1)
				If ($length(word,"?=")>1) && $extract($piece(word,"?",5))'="=" {
					Set sep=""
				}
			}
			Set value=value_sep_line
		} Else {
			If name'="" Do message.SetHeader(name,..DecodeHeader(value))
			Set name=$piece(line,":",1)
			Set value=$extract(line,$length(name)+2,*)
		}
	}

	If $$$ISOK(sc) && (name'="") Do message.SetHeader(name,..DecodeHeader(value))

	Quit sc
}

/// Read the body of the current message part.
Method readBody(message As %Net.MIMEPart, messageBoundary As %String, ByRef lastPart As %Boolean) As %Status
{
	Set sc=$$$OK
	Set lastPart=0
	Set encoding=$zconvert(message.ContentTransferEncoding,"L")
	Set boundary=$select(messageBoundary="":"",1:"--"_messageBoundary)
	Set blen=$length(boundary)

	// Just set the body if not multipart
	If $zcvt($piece(message.ContentType,"/",1),"L")'="multipart" {
		Set crlf=1
		Set prevcrlf=0
		Set stream=##class(%GlobalBinaryStream).%New()
		For {
			Set sc=..getLine(.line)
			If $$$ISERR(sc) Quit

			If boundary="" {
				If line="" {
					Set lastPart=1
					Quit
				}
			} Else {
				If line="" {
					Set sc=$$$ERROR($$$MIMEUnexpectedEnd)
					Quit
				}
				If crlf {
					If line=(boundary_$c(13,10)) {
						Quit
					} ElseIf $extract(line,1,$length(boundary)+2)=(boundary_"--") {
						Set lastPart=1
						Quit
					}
				}
			}

			If encoding="base64" {
				Set line=..DecodeBase64(line)
			} Else{ 
				If encoding="quoted-printable" {
					Set line=..DecodeQP(line)
				}
				Set crlf=($extract(line,*-1,*)=$c(13,10))
				If crlf Set line=$extract(line,1,*-2)
				If prevcrlf Set line=$c(13,10)_line
				Set prevcrlf=crlf
			}
			Set sc=stream.Write(line)
			If $$$ISERR(sc) Quit
		}
		
		If $$$ISOK(sc) {
			Do stream.SaveStream()
			Set message.Body=stream
			Set message.PartOwnedStream=1
		}

	} Else {
	
		// Parse multipart body
		Set boundary=message.GetContentTypeAttribute("boundary")
		If boundary="" {
			Set sc=$$$ERROR($$$MIMENoBoundary)
		} Else {
			// Verify that boundary is next.
			For {
				Set sc=..getLine(.boundaryLine)
				If $$$ISERR(sc) Quit
				If boundaryLine="" Quit
				If $extract(boundaryLine,1,$length(boundary)+2)=("--"_boundary) Quit
			}
			If $$$ISERR(sc) || ($extract(boundaryLine,1,$length(boundary)+4)=("--"_boundary_"--")) {
			} ElseIf boundaryLine=("--"_boundary_$c(13,10)) {
				Set last=0
				While $$$ISOK(sc) && 'last {
					Set sc=..readHeader(.messagePart,1)
					If $$$ISOK(sc) Set sc=..readBody(messagePart,boundary,.last)
					If $$$ISOK(sc) Do message.Parts.Insert(messagePart)
				}
			} Else {
				Set sc=$$$ERROR($$$MIMEBadBoundary)
			}

			If $$$ISOK(sc) {
				If messageBoundary="" {
					If '..inputStream.AtEnd Set sc=$$$ERROR($$$MIMEUnexpectedEnd)
					Set lastPart=1
				} Else {
					Set sc=..getLine(.boundaryLine)
					While $$$ISOK(sc) && (boundaryLine=$c(13,10)) {
						Set sc=..getLine(.boundaryLine)
					}
					If $$$ISOK(sc) {
						If boundaryLine=("--"_messageBoundary_$c(13,10)) {
							Set lastPart=0
						} ElseIf $extract(boundaryLine,1,$length(messageBoundary)+4)=("--"_messageBoundary_"--") {
							Set lastPart=1
						} Else {
							Set sc=$$$ERROR($$$MIMEUnexpectedEnd)
						}
					}
				}
			}
		}
	}
	
	Quit sc
}

/// Get the next header line.  Return false if no more lines.
Method getLine(ByRef line As %String) As %Status [ Internal, Private ]
{
	Set stream=..inputStream
	If stream="" Quit $$$ERROR($$$MIMENoSource)
	Set pos=..pos
	If ..previousCR {
		Set ..buffer=$c(13)
		Set ..pos=1
		Set newpos=0
	} Else {
		Set newpos=$find(..buffer,$c(13,10),pos)
	}
	If newpos=0 {
		Set line=$extract(..buffer,..pos,*)
		If 'stream.AtEnd {
			Set len=16384-$length(line)
			If len>0 {
				Set line=line_stream.Read(len,.sc)
				If $$$ISERR(sc) Quit sc
				Set ..pos=1
				Set ..buffer=line
				Set newpos=$find(line,$c(13,10))
			}
		}
	}

	If newpos=0 {
		Set ..pos=1
		Set ..buffer=""
		Set ..previousCR=($extract(line,*)=$c(13))
		If ..previousCR Set line=$extract(line,1,*-1)
	} Else {
		Set line=$extract(..buffer,..pos,newpos-1)
		Set ..pos=newpos
		Set ..previousCR=0
	}

	Quit $$$OK
}

/// Decode a line of the base64 encoded body.
/// The length of the input must be a multiple of 4.
ClassMethod DecodeBase64(input As %String) As %String [ CodeMode = expression ]
{
$System.Encryption.Base64Decode($piece(input,$c(13,10)))
}

/// Decode a line of the quoted printable encoded body
ClassMethod DecodeQP(input As %String) As %String
{
	Set line=$zstrip(input,">W",$c(13,10))
	If $extract(input,*-1,*)=$c(13,10) {
		If $extract(line,*)="=" {
			Set line=$extract(line,1,*-1)
		} Else {
			Set line=line_$c(13,10)
		}
	}
	
	If line'["=" Quit line
	
	Set out=$piece(line,"=")
	For i=2:1:$length(line,"=") {
		Set p=$piece(line,"=",i)
		Set h=$extract(p,1,2)
		If ($length(h)=2) && ($translate(h,"0123456789abcdefABCDEF")="") {
			Set out=out_$char($zhex(h))_$extract(p,3,*)
		} Else {
			Set out=out_"="_p
		}
	}
	
	Quit out
}

/// Decode and return the MIME header value passed in <var>input</var> argument
/// according to RFC 2047.
ClassMethod DecodeHeader(input As %String) As %String
{
 set numparts=0
 set pos=$find(input,"=?")
 while pos>0 {
	if pos>3 {
		set numparts=numparts+1
		set parts(numparts)=$extract(input,1,pos-3)
		set charsets(numparts)=""  ; no translation required
		set $extract(input,1,pos-3)=""
	}
	set word=$piece($tr(input,$c(9)," ")," ",1)
	if ($length(word,"?=")>1) && ($extract($piece(word,"?",5))="=") {
		// An encoded work found, convert
		set charset=$zcvt($piece(word,"?",2),"L")
		set encoding=$zcvt($piece(word,"?",3),"L")
		set text=$piece(word,"?",4)
		set $extract(input,1,6+$length(charset)+$length(encoding)+$length(text))=""
		
			if encoding="b" {
				set text=$system.Encryption.Base64Decode(text)
			} elseif encoding="q" {
				set in=$tr(text,"_",$c(32))
				set text=$piece(in,"=") 
				for k=2:1:$length(in,"=") {
					set p=$piece(in,"=",k)
					set h=$extract(p,1,2)
					if ($length(h)=2)&&($tr(h,"0123456789abcdefABCDEF")="") {
						set text=text_$char($zhex(h))_$extract(p,3,$length(p))
					} else {
						set text=text_"="_p
					}
				}
			}
	
		// Combine touching strings with the same charset in case
		// the string was broken in the middle of a multibyte
		// character set such as utf-8 or shift-jis.
		if (numparts>0)&&(charsets(numparts)=charset) {
			set parts(numparts)=parts(numparts)_text
		} else {
			set numparts=numparts+1
			set parts(numparts)=text
			set charsets(numparts)=charset
		}

	} Else {
		// If not an encoded word copy "=?" to result and continue
		set numparts=numparts+1
		set parts(numparts)="=?"
		set charsets(numparts)=""  ; no translation required
		set $extract(input,1,2)=""
	}
	set pos=$find(input,"=?")
 }

 if input'="" {
	set numparts=numparts+1
	set parts(numparts)=input
	set charsets(numparts)=""  ; no translation required
 }

 set header=""
 for k=1:1:numparts {
	set charset=charsets(k)
	if (charset'="") && ##class(%Net.Charset).TranslateTableExists(charset) {
		set table=##class(%Net.Charset).GetTranslateTable(charset)
		set header=header_$zcvt(parts(k),"I",table)
	} else {
		set header=header_parts(k)
	}
 }

 quit header
}

}
