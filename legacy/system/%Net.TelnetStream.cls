/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class emulates the handshaking behavior of Windows NT Telnet.exe
Class %Net.TelnetStream Extends (%IO.MetaCharacterStream, %IO.IParts.SocketIO) [ Inheritance = right, System = 3 ]
{

Parameter DEFAWSWIDTH As INTEGER = 105;

Property AWSWidth As %Integer [ InitialExpression = {..#DEFAWSWIDTH} ];

Parameter DEFAWSHEIGHT As INTEGER = 45;

Property AWSHeight As %Integer [ InitialExpression = {..#DEFAWSHEIGHT} ];

Parameter DEFTERMTYPES As STRING = "ANSI; VT-100; IBM-3278-2";

/// List of terminal types to claim to support, semicolon separated
Property TermTypes As %String(TRUNCATE = 1) [ InitialExpression = {..#DEFTERMTYPES} ];

/// Name of the translation table to use for importing and exporting character text.
/// See <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.
Property TranslationTable As %String(TRUNCATE = 1);

Parameter DEFAULTPORT As INTEGER = 23;

/// If this is set, don't re-acknowledge options we have already acknowledged once
Property NoReacknowledgements As %Boolean [ InitialExpression = 0 ];

Parameter OpENDSCR = 239;

Parameter OpSE = 240;

Parameter OpNOP = 241;

Parameter OpSB = 250;

Parameter OpWill = 251;

Parameter OpWont = 252;

Parameter OpDo = 253;

Parameter OpDont = 254;

Parameter OpIAC = 255;

Parameter OptBINX = 0;

Parameter OptECHO = 1;

Parameter OptSGA = 3;

Parameter OptSTATUS = 5;

Parameter OptTIMING = 6;

Parameter OptTERMTYPE = 24;

Parameter OptENDREC = 25;

Parameter OptNAWS = 31;

Parameter OptTERMSPEED = 32;

Parameter OptTOGGLEFLOW = 33;

Parameter OptLINEMODE = 34;

Parameter OptXDISPLAY = 35;

Parameter OptENVVAR = 36;

Parameter OptENV = 39;

/// Private Properties
Property Options As %String(TRUNCATE = 1) [ MultiDimensional, Private ];

Property OptNames As %String(TRUNCATE = 1) [ MultiDimensional, Private ];

Property OptTable As %String(TRUNCATE = 1) [ MultiDimensional, Private ];

/// record of responses so that we can support NoReacknowledgements option
Property AcksSent As %String(TRUNCATE = 1) [ MultiDimensional, Private ];

Property State As %Integer [ InitialExpression = 0, Private ];

/// Current option
Property Op As %String(TRUNCATE = 1) [ Private ];

/// Current subnegotiation option string
Property SBOp As %String(TRUNCATE = 1) [ Private ];

/// Index of current option request from host
Property iOpt As %Integer [ InitialExpression = 0, Private ];

Property iTermType As %Integer [ InitialExpression = 0, Private ];

/// Current Header block for 3270E data
Property Curr3270Header As %String(TRUNCATE = 1) [ InitialExpression = "xxxxx" ];

/// integer for response count in 3270E header response mode
Property ResponseID As %Integer;

Method %OnNew(pBaseStream As %IO.I.Stream = "%IO.Socket") As %Status
{
	Set tSC = ##class(%IO.IParts.MetaIO)$this.%OnNew(pBaseStream)
	Set:$$$ISOK(tSC)&&'$IsObject(pBaseStream)&&$IsObject(..StreamIn)&&..StreamIn.%Extends("%IO.IParts.SocketIO") ..StreamIn.Port=..#DEFAULTPORT
	Do ..init()
	Quit tSC
}

Method init() [ Private ]
{
	#; set up names table
	Set ..OptNames(1)="ECHO"			// x01 
	Set ..OptNames(3)="SGA"				// x03
	Set ..OptNames(5)="STATUS"			// x05
	Set ..OptNames(6)="TIMING"			// x06
	Set ..OptNames(24)="TERMTYPE"		// x18
	Set ..OptNames(31)="NAWS"			// x1F
	Set ..OptNames(32)="TERMSPEED"		// x20
	Set ..OptNames(33)="TOGGLEFLOW"		// x21
	Set ..OptNames(34)="LINEMODE"		// x22
	Set ..OptNames(35)="XDISPLAY"		// x23
	Set ..OptNames(36)="ENVVAR"			// x24
	Set ..OptNames(39)="ENV"			// x27
	Set ..OptNames(40)="TN3270E"		// x28

	#; set up table
	Kill ..OptTable
	Set ..OptTable(..#OpDo,24)="24;31"
	Set ..OptTable(..#OpDo,32)=""
	Set ..OptTable(..#OpDo,35)=""
	Set ..OptTable(..#OpDo,39)=39
	Set ..OptTable(..#OpDo,40)=40
	Set ..OptTable(..#OpDo,31)="+,aws"
	Set ..OptTable(..#OpSB,39,$C(1))="+,0"
	// <<<<<  IAC SB TN3270E SEND DEVICE-TYPE IAC SE
	// >>>>>  IAC SB TN3270E DEVICE-TYPE REQUEST <device-type> IAC SE
	Set ..OptTable(..#OpSB,40,$C(8,2))="="_$C(2,7)_"IBM-3278-2"
	// <<<<<  IAC SB TN3270E DEVICE-TYPE IS <device-type> CONNECT <device-name> IAC SE
	// >>>>>  IAC SB TN3270E FUNCTIONS REQUEST <function-list> IAC SE
	Set ..OptTable(..#OpSB,40,$C(2,4)_"IBM-3278-2"_$C(1)_$C(0))="="_$C(3,7,0,2,4) ; trailing $C(0) on subscript is wildcard
	Set ..OptTable(..#OpSB,40,$C(3,4,0))="#" ; wildcard for functions confirmed; send no reply
	#;Set ..OptTable(..#OpSB,24,$C(1))="+,0,ANSI"  // taken care of explicitly under OpSB
	Set ..OptTable(..#OpDo,0)=0
	Set ..OptTable(..#OpWill,0)=0
	Set ..OptTable(..#OpDo,1)=1
	Set ..OptTable(..#OpWill,1)=1
	Set ..OptTable(..#OpDo,3)=3
	Set ..OptTable(..#OpWill,3)=3
	Set ..OptTable(..#OpWill,5)=""
	Set ..OptTable(..#OpDo,25)=25
	Set ..OptTable(..#OpWill,25)=25
	Set ..OptTable(..#OpDo,33)=""
	Set ..OptTable(..#OpDont,31)="-"
	
	Kill ..Options
	Do ..SetOption("NAWS",31,.pSC) ; always have this one
	Do ..SetOption("ENV",39,.pSC) ; always have this one (unless AS/400 asks for it first (?))	
	Kill ..AcksSent

	Set (..State,..iOpt,..iTermType)=0, (..Op,..SBOp,..ResponseID)=""
}

/// In in 3270(e) mode, writes out a record with header and terminator (IAC-EOR)
/// Otherwise, writes out the line followed by the standard ..LineTerminator character(s)
Method WriteLine(pLine As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	If ""'=..ResponseID||(""'=..GetOption(40)) {
		If ""'=..ResponseID {
			Set tHdr=$C(0,0,0,..ResponseID\256#256,..ResponseID#256)
			Set ..ResponseID=..ResponseID+1
		} Else { Set tHdr=$C(0,0,0,0,0)	}
	} Else { Set tHdr="" }
	Set tEOR=$S(..GetOption("OpSB_"_24_"_"_$C(1))["IBM-327":$C(255,239),1:..LineTerminator)
	Do ##class(%IO.MetaCharacterStream)$this.Write(tHdr_..escape(..CharExport(pLine))_tEOR,.pFlush,.pSC)
}

Method Write(pData As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	Do ##class(%IO.MetaCharacterStream)$this.Write(..escape(..CharExport(pData)),.pFlush,.pSC)
}

Method WriteRaw(pData As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	Do ##class(%IO.MetaCharacterStream)$this.Write(pData,.pFlush,.pSC)
}

Method ReadRaw(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric, Output pSC As %Status) As %String
{
	Quit ##class(%IO.MetaCharacterStream)$this.Read(.pMaxReadLen,.pTimeout,.pSC)
}

Method ReadLine(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status, pLineTerminator As %String = {..LineTerminator}) As %String
{
	#; loop reading and looking for IACs until timeout or enough data found; manage interval so as not to hang when IACs are needed to continue
	Set pSC=$$$OK, tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Set (tTimeRemaining,tTimeout)=pTimeout,pTimeout=0,tReadLen=pMaxReadLen,tData="",tPosition=..Position,tDone=0
	Quit:pMaxReadLen<=0 ""
	Set:tTimeout>0 tStartTime=$zh
	Set:'tTimeRemaining tTimeRemaining=0.1
	Set tWaitForMore = 1
	Do {
		#;  Wait for 1 char w/ full timeout; quit if timed out
		Set tRead=##class(%IO.MetaCharacterStream)$this.ReadLine(1,.tTimeRemaining,.pSC,pLineTerminator)	Quit:$$$ISERR(pSC)
		Quit:""=tRead ; quit if that was the EOL, or timed out with nothing
		#;  Wait for remaining chars (if any) w/ zero timeout
		Set tZero=0.1
		Set:tReadLen>1&&'..AtEnd tRead=tRead_##class(%IO.MetaCharacterStream)$this.ReadLine(tReadLen-1,.tZero,.pSC,pLineTerminator)	Quit:$$$ISERR(pSC)
		Set tDone=$L(tRead)<tReadLen&&'tZero ; got a partial buffer without timing out
		#;  Process chars
		Set tRead=..processIACs(tRead,.tReplied,.pSC)  Quit:$$$ISERR(pSC)
		Set tData=tData_tRead
		Quit:$L(tData)>=pMaxReadLen||tDone
		Set tReadLen=tReadLen-$L(tRead)
		If tTimeout>0 Set tTimeRemaining=tTimeout-($zh-tStartTime) Set:tTimeRemaining<0 tTimeRemaining=0
		else  Set tTimeRemaining=$S(tTimeout<0:tTimeout,1:0)
		#;  If no time remains and data not complete and responded, give a little more time for only one loop
		Set:'tTimeRemaining&&($L(tData)<pMaxReadLen)&&$G(tReplied)&&tWaitForMore tTimeRemaining=0.1,tWaitForMore=0
		#; Loop if time remains and more data wanted
	} While tTimeRemaining
	Set:$L(tData)<pMaxReadLen&&'tDone pTimeout=tTimeout
	Set i%Position=tPosition+$L(tData)+(tDone&&'..AtEnd)
	Quit:""'=..TranslationTable ..CharImport(tData)
	Quit tData
}

Method Read(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String
{
	#; loop reading and looking for IACs until timeout or enough data found; manage interval so as not to hang when IACs are needed to continue
	Set pSC=$$$OK, tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Set (tTimeRemaining,tTimeout)=pTimeout,pTimeout=0,tReadLen=pMaxReadLen,tData="",tPosition=..Position
	Quit:pMaxReadLen<=0 ""
	Set:tTimeout>0 tStartTime=$zh
	Set:'tTimeRemaining tTimeRemaining=0.1
	Do {
		#;  Wait for 1 char w/ full timeout; quit if timed out
		Set tRead=##class(%IO.MetaCharacterStream)$this.Read(1,.tTimeRemaining,.pSC)	Quit:$$$ISERR(pSC)
		Quit:""=tRead&&tTimeRemaining ; quit if timed out with nothing
		#;  Wait for remaining chars (if any) w/ zero timeout
		Set:tReadLen>1&&'..AtEnd tRead=tRead_##class(%IO.MetaCharacterStream)$this.Read(tReadLen-1,0,.pSC)	Quit:$$$ISERR(pSC)
		#;  Process chars
		Set tRead=..processIACs(tRead,.tReplied,.pSC)  Quit:$$$ISERR(pSC)
		Set tData=tData_tRead
		Quit:$L(tData)>=pMaxReadLen||..AtEnd
		Set tReadLen=tReadLen-$L(tRead)
		#;  If no time remains and data not complete and responded, give a little more time
		If tTimeout>0 Set tTimeRemaining=tTimeout-($zh-tStartTime) Set:tTimeRemaining<0 tTimeRemaining=0
		else  Set tTimeRemaining=$S(tTimeout<0:tTimeout,1:0)
		Set:'tTimeRemaining&&$G(tReplied) tTimeRemaining=0.1
		#; Loop if time remains and more data wanted
	} While tTimeRemaining
	Set:$L(tData)<pMaxReadLen pTimeout=tTimeout
	Set i%Position=tPosition+$L(tData)
	Quit:""'=..TranslationTable ..CharImport(tData)
	Quit tData
}

Method processIACs(pData As %String, Output pReplied As %Boolean, Output pSC As %Status) As %String
{
	Set pSC=$$$OK
	Set pReplied=0
	Set tBuf="",tOutData=""
	For iC=1:1:$L(pData) {
		Set c=$E(pData,iC)
	//w !,"doing state "_..State_", ..Op='"_$G(..Op,0)_"'"_", c='"_$G(c)_"'/("_$A($G(c,$C(0)))_")"
		If ..State=0 {
			if $A(c)=..#OpIAC { Set ..State=..#OpIAC }
			else { Do addChar(c) }
		}
		ElseIf ..State=..#OpIAC {
			if $A(c)=..#OpIAC { Set ..State=0 do addChar(c) } ; Process Escaped IAC
			ElseIf $A(c)=..#OpENDSCR && (..GetOption("OpSB_"_24_"_"_$C(1))["IBM-327") { Set ..State=0, tOutData=tOutData_$C(30), ..Curr3270Header="" } ; ASCII RS - "End of Record" marker represents IAC-EOR in user-level data stream
			else { Set ..State=$A(c), ..Op="", ..iOpt=..iOpt+1 }
		}
		ElseIf ..State=..#OpDo {
			Set ..Op=$A(c), action=$G(..OptTable(..State,..Op))
			Set ..State=0
			Set:(action=39)&&(..Op=39)&&(..iOpt=1) action="" ; special hack for AS400 (but why?)
			Set tActionList=action,tOpDone=0
			For iPA=1:1:$L(tActionList,";") { Set action=$P(tActionList,";",iPA)
				//w !,"OpDo action="_action_",..Op="_..Op
				If action=..Op { // Just say 'Will'
					Set:'..NoReacknowledgements||(..Op'=$G(..AcksSent(..#OpDo,..Op))) tBuf=tBuf_$C(..#OpIAC,..#OpWill,..Op)
					Do ..SetOption(..Op,action,.pSC) Quit:$$$ISERR(pSC)
					Set ..AcksSent(..#OpDo,..Op)=..Op
					Set tOpDone=1
				} ElseIf $E(action)="+" {
					Set tBuf=tBuf_$C(..#OpIAC,..#OpSB,..Op)
					For i=2:1:$L(action,",") Set ..Op=$P(action,",",i), tBuf=tBuf_$Case(..Op,"aws":$C(..AWSWidth\256,..AWSWidth#256,..AWSHeight\256,..AWSHeight#256),1:$C(..Op))
					Set tBuf=tBuf_$C(..#OpIAC,..#OpSE)
					Do ..SetOption(..Op,action,.pSC) Quit:$$$ISERR(pSC)					
				} else {
					If 'tOpDone { // If not already done, just say 'Wont' for requested option
						Set tBuf=tBuf_$C(..#OpIAC,..#OpWont,..Op),tOpDone=1  Do ..SetOption(..Op,"",.pSC) Quit:$$$ISERR(pSC)
					}
					if action'="" { // Then say 'Will' for alternate option, if any
						Set tBuf=tBuf_$C(..#OpIAC,..#OpWill,action) Do ..SetOption(action,action,.pSC) Quit:$$$ISERR(pSC)
					}
				}
			}
		}
		ElseIf ..State=..#OpDont {
			Set ..Op=$A(c), action=$G(..OptTable(..State,..Op))
			Set ..State=0
			If action=..Op||(action="") {
				Set:'..NoReacknowledgements||(-..Op'=$G(..AcksSent(..#OpDont,..Op))) tBuf=tBuf_$C(..#OpIAC,..#OpWont,..Op)
				Do ..SetOption(..Op,"",.pSC) Quit:$$$ISERR(pSC)
				Set ..AcksSent(..#OpDont,..Op)=-..Op
			} ElseIf action="-" {
				Set:'..NoReacknowledgements||(..Op'=$G(..AcksSent(..#OpDont,..Op))) tBuf=tBuf_$C(..#OpIAC,..#OpWill,..Op)
				Do ..SetOption(..Op,..Op,.pSC) Quit:$$$ISERR(pSC)
				Set ..AcksSent(..#OpDont,..Op)=..Op
			}
		}
		ElseIf ..State=..#OpWill {
			Set ..Op=$A(c), action=$G(..OptTable(..State,..Op))
			Set ..State=0
			If action=..Op {
				Set:'..NoReacknowledgements||(..Op'=$G(..AcksSent(..#OpWill,..Op))) tBuf=tBuf_$C(..#OpIAC,..#OpDo,..Op)
				Set ..AcksSent(..#OpWill,..Op)=..Op
			} ElseIf action="" {
				Set:'..NoReacknowledgements||(-..Op'=$G(..AcksSent(..#OpWill,..Op))) tBuf=tBuf_$C(..#OpIAC,..#OpDont,..Op)
				Set ..AcksSent(..#OpWill,..Op)=-..Op
			}
		}
		ElseIf ..State=..#OpSB {
			If ..Op="" {
				Set ..Op=$A(c),..SBOp=""
			} ElseIf ..SBOp="" {
				Set ..SBOp=c
			} else {
				#; Scan to end
				If $A(c)'=..#OpIAC {
					Set ..SBOp=..SBOp_c
				} else {
					Set ..State=..#OpSE
					//w !,"got OpSB op="_..Op_", SBOp="_..toAscii(..SBOp)_", action list='"_$G(..OptTable(..#OpSB,..Op,..SBOp))_"'"
					If (..#OptTERMTYPE=..Op)&&(..SBOp=$C(1)) {
						#; return one term type after the next on successive queries
						Set ..iTermType=$S(..iTermType<$L(..TermTypes,";"):..iTermType+1,1:..iTermType)
						Set tBuf=tBuf_$C(..#OpIAC,..#OpSB,..Op)_$S(""=..GetOption(39):" ",1:$C(0))_$ZSTRIP($P(..TermTypes,";",..iTermType),"<>W")_$C(..#OpIAC,..#OpSE)
						Do ..SetOption("OpSB_"_..Op_"_"_$C(1),$ZSTRIP($P(..TermTypes,";",..iTermType),"<>W"),.pSC) Quit:$$$ISERR(pSC)
					} else {
						Set tOpDone=0 
						Set tActionList=$G(..OptTable(..#OpSB,..Op,..SBOp))
						If ""=tActionList {
							#; Look up wildcard option match from table. (Wildcard string must end with $C(0))
							Set tWildSBOp=$O(..OptTable(..#OpSB,..Op,..SBOp),-1,tActionList)
							If $E(tWildSBOp,$L(tWildSBOp))'=$C(0) || ($E(..SBOp,1,$L(tWildSBOp)-1)'=$E(tWildSBOp,1,$L(tWildSBOp)-1)) {
								Set tActionList=""  ; wasn't a true match
							}
						} Else { Set tWildSBOp="" }
						
						For iPA=1:1:$L(tActionList,";") {
							Set action=$P(tActionList,";",iPA)
							If action=..Op { // Just say 'Will'
								Set tBuf=tBuf_$C(..#OpIAC,..#OpWill,..Op)
								Do ..SetOption(..Op,action,.pSC) Quit:$$$ISERR(pSC)
								Set tOpDone=1
							} else {
								If $E(action)="+" { // Return concatenation of comma-separated subneg codes
									Set tBuf=tBuf_$C(..#OpIAC,..#OpSB,..Op)
									For i=2:1:$L(action,",") Set tBuf=tBuf_$C($P(action,",",i))
									Set tBuf=tBuf_$C(..#OpIAC,..#OpSE)
									Do ..SetOption("OpSB_"_..Op_"_"_..SBOp,action,.pSC) Quit:$$$ISERR(pSC)
									Do:..SBOp'=tWildSBOp ..SetOption("OpSB_"_..Op_"_"_tWildSBOp,action,.pSC) Quit:$$$ISERR(pSC)
								} ElseIf $E(action)="=" { // Add literal ascii subneg string
									Set tBuf=tBuf_$C(..#OpIAC,..#OpSB,..Op)_$E(action,2,*)_$C(..#OpIAC,..#OpSE)
									Do ..SetOption("OpSB_"_..Op_"_"_..SBOp,action,.pSC) Quit:$$$ISERR(pSC)
									Do:..SBOp'=tWildSBOp ..SetOption("OpSB_"_..Op_"_"_tWildSBOp,action,.pSC) Quit:$$$ISERR(pSC)
									Do:..Op=40&&(..SBOp=$C(8,2)) ..SetOption("OpSB_"_24_"_"_$C(1),$E(action,3,$L(action)),.pSC) Quit:$$$ISERR(pSC) ; set standard terminal type suboption too
								} ElseIf $E(action)="#" { // return nothing
									If ..Op=40&&($E(..SBOp,1,2)=$C(3,4)) {
										Set tOpts=$E(..SBOp,3,$L(..SBOp)) ; record confirmed 3270 options
										Set:tOpts[$C(2) ..ResponseID=0
										Set ..Curr3270Header=""
										Do ..SetOption("OpSB_"_40_"_"_$C(3,4),tOpts,.pSC) Quit:$$$ISERR(pSC)
									}
								} else {
									If 'tOpDone { // If not already done, just say 'Wont' for requested option
										Set tBuf=tBuf_$C(..#OpIAC,..#OpWont,..Op),tOpDone=1  Do ..SetOption(..Op,"",.pSC) Quit:$$$ISERR(pSC)
									}
									if action'="" { // Then say 'Will' for alternate option, if any
										Set tBuf=tBuf_$C(..#OpIAC,..#OpWill,action)  Do ..SetOption(action,action,.pSC) Quit:$$$ISERR(pSC)
									}
								}
							}
						}
					}
				}
			}
		}
		ElseIf ..State=..#OpSE {
			if $A(c)'=..#OpSE {
				Set pSC=$$$ERROR($$$ErrTelnetBadState, ..State, $A(c))
				Quit
			}
			Set ..State=0
		}
		else {
			Set pSC=$$$ERROR($$$ErrTelnetBadState, ..State, $A(c)),..State=0
		}
	}
	If tBuf'="" Do ##class(%IO.MetaCharacterStream)$this.Write(tBuf,1,.pSC)  Set:$$$ISOK(pSC) pReplied=1
	Quit tOutData

addChar(c)
	If $L(..Curr3270Header)<5 {
		Set ..Curr3270Header=..Curr3270Header_c
		Set:$C(0)'=$E(..Curr3270Header) tOutData=tOutData_c
	} Else {
		Set tOutData=tOutData_c
	}
	Quit
}

ClassMethod toAscii(pStr) As %String
{
	Set tOutStr="" For i=1:1:$L(pStr) Set tOutStr=tOutStr_","_$A($E(pStr,i))
	Quit $E(tOutStr,2,*)
}

Method Open(pHost As %String = "", pPort As %String = "", ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Boolean
{
	If '$IsObject(..StreamIn)||'..StreamIn.%Extends("%IO.IParts.SocketIO") Set pSC=$$$ERROR($$$ErrIONoDelegatedStream),pTimeout=0 Quit 0
	#; Must close before calling Open() again
	If ..IsOpen Set pSC = $$$ERROR($$$FileAlreadyOpen,..StreamIn.Name_"/"_..StreamIn.Host_":"_..StreamIn.Port) Quit 0
	Set tOK = ..StreamIn.Open(pHost,pPort,pTimeout,.pSC)
	Set:""=..Name&&tOK ..Name=..StreamIn.Name
	Quit tOK
}

Method Reset(pStream As %IO.I.Stream, pTimeout As %Numeric = 10, Output pSC As %Status)
{
	Do ##super(.pStream,.pTimeout,.pSC)
	Do ..init()
	
	Set ..TermTypes = ..#DEFTERMTYPES
	Set ..AWSWidth = ..#DEFAWSWIDTH
	Set ..AWSHeight = ..#DEFAWSHEIGHT

	// !!! tell the server we're resetting
}

Method Close(Output pSC As %Status) As %Boolean
{
	If '$IsObject(..StreamIn)||'..StreamIn.%Extends("%IO.IParts.SocketIO") Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..StreamIn.Name_"/"_..StreamIn.Host_":"_..StreamIn.Port) Quit 0
	Do ..init()
	Quit ..StreamIn.Close(.pSC)
}

Method SetOption(pName As %String, pVal As %String, Output pSC As %Status)
{
	Kill pSC  Set pSC=$$$OK
	Set:+pName=pName pName = $G(..OptNames(pName),pName)
	Set ..Options(pName)=pVal
}

Method GetOption(pName As %String, Output pSC As %Status) As %String
{
	Kill pSC  Set pSC=$$$OK
	Set:+pName=pName pName = $G(..OptNames(pName),pName)
	if $D(..Options(pName))#2=0 Set pSC=$$$ERROR($$$ErrTelnetOptionNotSet,pName)
	Quit $G(..Options(pName))
}

ClassMethod escape(str As %String) As %String [ CodeMode = expression ]
{
$Replace($Replace(str, $C(255), $C(255,255)), $C(30), $C(255,239))
}

Method CharImport(pData As %String) As %String
{
	Quit $Case($ZCVT(..TranslationTable,"L"),"":pData, "cp037":..CP037ToLatin1(pData), :$ZCVT(pData,"I",..TranslationTable))
}

Method CharExport(pData As %String) As %String
{
	Quit $Case($ZCVT(..TranslationTable,"L"),"":pData, "cp037":..Latin1ToCP037(pData), :$ZCVT(pData,"O",..TranslationTable))
}

ClassMethod Latin1ToCP037(pData As %String)
{
	Set tDataOut=pData
	For i=1:1:$L(pData) {
		Set ca=$A(tDataOut,i)
		Continue:ca<32
		Set $E(tDataOut,i)=$S(ca>255:$C(111) /* ? */
							, 1:$E($C(
		64,  /* SP */
		90,  /* ! */
		127, /* " */
		123, /* Nb */
		91,  /* DO */
		108, /* % */
		80,  /* & */
		125, /* ' */
		77,  /* ( */
		93,  /* ) */
		92,  /* * */
		78,  /* + */
		107, /* , */
		96,  /* - */
		75,  /* . */
		97,  /* / */
		240, /* 0 */
		241, /* 1 */
		242, /* 2 */
		243, /* 3 */
		244, /* 4 */
		245, /* 5 */
		246, /* 6 */
		247, /* 7 */
		248, /* 8 */
		249, /* 9 */
		122, /* : */
		94,  /* ; */
		76,  /* < */
		126, /* = */
		110, /* > */
		111, /* ? */
		124, /* At */
		193, /* A */
		194, /* B */
		195, /* C */
		196, /* D */
		197, /* E */
		198, /* F */
		199, /* G */
		200, /* H */
		201, /* I */
		209, /* J */
		210, /* K */
		211, /* L */
		212, /* M */
		213, /* N */
		214, /* O */
		215, /* P */
		216, /* Q */
		217, /* R */
		226, /* S */
		227, /* T */
		228, /* U */
		229, /* V */
		230, /* W */
		231, /* X */
		232, /* Y */
		233, /* Z */
		186, /* <( */
		224, /* // */
		187, /* )> */
		176, /* '> */
		109, /* _ */
		121, /* '! */
		129, /* a */
		130, /* b */
		131, /* c */
		132, /* d */
		133, /* e */
		134, /* f */
		135, /* g */
		136, /* h */
		137, /* i */
		145, /* j */
		146, /* k */
		147, /* l */
		148, /* m */
		149, /* n */
		150, /* o */
		151, /* p */
		152, /* q */
		153, /* r */
		162, /* s */
		163, /* t */
		164, /* u */
		165, /* v */
		166, /* w */
		167, /* x */
		168, /* y */
		169, /* z */
		192, /* (! */
		79,  /* !! */
		208, /* !) */
		161, /* '? */
		255, /* DT */
		92,  /* -PA */
		92,  /* -HO */
		92,  /* -BH */
		92,  /* -NH */
		92,  /* -IN */
		92,  /* -NL */
		92,  /* -SA */
		92,  /* -ES */
		92,  /* -HS */
		92,  /* -HJ */
		92,  /* -VS */
		92,  /* -PD */
		92,  /* -PU */
		92,  /* -RI */
		92,  /* -S2 */
		92,  /* -S3 */
		92,  /* -DC */
		92,  /* -P1 */
		92,  /* -P2 */
		92,  /* -TS */
		92,  /* -CC */
		92,  /* -MW */
		92,  /* -SG */
		92,  /* -EG */
		92,  /* -SS */
		92,  /* -GC */
		92,  /* -SC */
		92,  /* -CI */
		92,  /* -ST */
		92,  /* -OC */
		92,  /* -PM */
		92,  /* -AC */
		65,  /* NS */
		170, /* !I */
		74,  /* Ct */
		177, /* Pd */
		159, /* Cu */
		178, /* Ye */
		106, /* BB */
		181, /* SE */
		189, /* ': */
		180, /* Co */
		154, /* -a */
		138, /* << */
		95,  /* NO */
		202, /* -- */
		175, /* Rg */
		188, /* '- */
		144, /* DG */
		143, /* +- */
		234, /* 2S */
		250, /* 3S */
		190, /* '' */
		160, /* My */
		182, /* PI */
		179, /* .M */
		157, /* ', */
		218, /* 1S */
		155, /* -o */
		139, /* >> */
		183, /* 14 */
		184, /* 12 */
		185, /* 34 */
		171, /* ?I */
		100, /* A! */
		101, /* A' */
		98,  /* A> */
		102, /* A? */
		99,  /* A: */
		103, /* AA */
		158, /* AE */
		104, /* C, */
		116, /* E! */
		113, /* E' */
		114, /* E> */
		115, /* E: */
		120, /* I! */
		117, /* I' */
		118, /* I> */
		119, /* I: */
		172, /* D- */
		105, /* N? */
		237, /* O! */
		238, /* O' */
		235, /* O> */
		239, /* O? */
		236, /* O: */
		191, /* *X */
		128, /* O/ */
		253, /* U! */
		254, /* U' */
		251, /* U> */
		252, /* U: */
		173, /* Y' */
		174, /* TH */
		89,  /* ss */
		68,  /* a! */
		69,  /* a' */
		66,  /* a> */
		70,  /* a? */
		67,  /* a: */
		71,  /* aa */
		156, /* ae */
		72,  /* c, */
		84,  /* e! */
		81,  /* e' */
		82,  /* e> */
		83,  /* e: */
		88,  /* i! */
		85,  /* i' */
		86,  /* i> */
		87,  /* i: */
		140, /* d- */
		73,  /* n? */
		205, /* o! */
		206, /* o' */
		203, /* o> */
		207, /* o? */
		204, /* o: */
		225, /* -: */
		112, /* o/ */
		221, /* u! */
		222, /* u' */
		219, /* u> */
		220, /* u: */
		141, /* y' */
		142, /* th */
		223 /* y: */
					),ca-31))
	}
	Quit tDataOut
}

ClassMethod CP037ToLatin1(pData As %String)
{
	#; NB: this method does not account for any Unicode characters in the input string.
	#;  It assumes that the pData contains genuine EBCDIC and does not check for multibyte characters.
	#;  If multibyte characters are present, they will be copied verbatim to the output as well.
	Quit $Translate(pData
		,$C(32,
		33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,
		65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,
		97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,
		129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,
		161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,
		193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,
		225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255)
		
		,"********************************"_
		  $C(32, /* SP */
			160, /* NS */
			226, /* a> */
			228, /* a: */
			224, /* a! */
			225, /* a' */
			227, /* a? */
			229, /* aa */
			231, /* c, */
			241, /* n? */
			162, /* Ct */
			46,  /* . */
			60,  /* < */
			40,  /* ( */
			43,  /* + */
			124, /* !! */
			38,  /* & */
			233, /* e' */
			234, /* e> */
			235, /* e: */
			232, /* e! */
			237, /* i' */
			238, /* i> */
			239, /* i: */
			236, /* i! */
			223, /* ss */
			33,  /* ! */
			36,  /* DO */
			42,  /* * */
			41,  /* ) */
			59,  /* ; */
			172, /* NO */
			45,  /* - */
			47,  /* / */
			194, /* A> */
			196, /* A: */
			192, /* A! */
			193, /* A' */
			195, /* A? */
			197, /* AA */
			199, /* C, */
			209, /* N? */
			166, /* BB */
			44,  /* , */
			37,  /* % */
			95,  /* _ */
			62,  /* > */
			63,  /* ? */
			248, /* o/ */
			201, /* E' */
			202, /* E> */
			203, /* E: */
			200, /* E! */
			205, /* I' */
			206, /* I> */
			207, /* I: */
			204, /* I! */
			96,  /* '! */
			58,  /* : */
			35,  /* Nb */
			64,  /* At */
			39,  /* ' */
			61,  /* = */
			34,  /* " */
			216, /* O/ */
			97,  /* a */
			98,  /* b */
			99,  /* c */
			100, /* d */
			101, /* e */
			102, /* f */
			103, /* g */
			104, /* h */
			105, /* i */
			171, /* << */
			187, /* >> */
			240, /* d- */
			253, /* y' */
			254, /* th */
			177, /* +- */
			176, /* DG */
			106, /* j */
			107, /* k */
			108, /* l */
			109, /* m */
			110, /* n */
			111, /* o */
			112, /* p */
			113, /* q */
			114, /* r */
			170, /* -a */
			186, /* -o */
			230, /* ae */
			184, /* ', */
			198, /* AE */
			164, /* Cu */
			181, /* My */
			126, /* '? */
			115, /* s */
			116, /* t */
			117, /* u */
			118, /* v */
			119, /* w */
			120, /* x */
			121, /* y */
			122, /* z */
			161, /* !I */
			191, /* ?I */
			208, /* D- */
			221, /* Y' */
			222, /* TH */
			174, /* Rg */
			94,  /* '> */
			163, /* Pd */
			165, /* Ye */
			183, /* .M */
			169, /* Co */
			167, /* SE */
			182, /* PI */
			188, /* 14 */
			189, /* 12 */
			190, /* 34 */
			91,  /* <( */
			93,  /* )> */
			175, /* '- */
			168, /* ': */
			180, /* '' */
			215, /* *X */
			123, /* (! */
			65,  /* A */
			66,  /* B */
			67,  /* C */
			68,  /* D */
			69,  /* E */
			70,  /* F */
			71,  /* G */
			72,  /* H */
			73,  /* I */
			173, /* -- */
			244, /* o> */
			246, /* o: */
			242, /* o! */
			243, /* o' */
			245, /* o? */
			125, /* !) */
			74,  /* J */
			75,  /* K */
			76,  /* L */
			77,  /* M */
			78,  /* N */
			79,  /* O */
			80,  /* P */
			81,  /* Q */
			82,  /* R */
			185, /* 1S */
			251, /* u> */
			252, /* u: */
			249, /* u! */
			250, /* u' */
			255, /* y: */
			92,  /* // */
			247, /* -: */
			83,  /* S */
			84,  /* T */
			85,  /* U */
			86,  /* V */
			87,  /* W */
			88,  /* X */
			89,  /* Y */
			90,  /* Z */
			178, /* 2S */
			212, /* O> */
			214, /* O: */
			210, /* O! */
			211, /* O' */
			213, /* O? */
			48,  /* 0 */
			49,  /* 1 */
			50,  /* 2 */
			51,  /* 3 */
			52,  /* 4 */
			53,  /* 5 */
			54,  /* 6 */
			55,  /* 7 */
			56,  /* 8 */
			57,  /* 9 */
			179, /* 3S */
			219, /* U> */
			220, /* U: */
			217, /* U! */
			218, /* U' */
			127 /* DT */
		)
	)
}

}
