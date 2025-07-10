/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Util.Trace [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod SetTraceDevice(pDevice As %String = "") As %Status
{
	If $Data($$$EnsJobStatus($$$SystemName,$Job))=0 Quit $$$ERROR($$$EnsErrGeneral,"Can not set trace device in a non-Interoperability job.")
	Set tTraceDevice=$S($ZCVT(pDevice,"L")["nul":"", 1:pDevice), $$$JobTraceDevice=tTraceDevice
	Set tJobConfigName=$$$JobConfigName  Set tLogTrace=$S(""=tJobConfigName:0, 1:$G($$$ConfigTrace(tJobConfigName),0))
	Set $$$EnsJobLocal("DoTrace") = (tLogTrace || (""'=tTraceDevice))
	Set x=$$$EnsMirrorIndexInc ; force new call to SetTraceOptimizer()
	$$$catTRACE("mirror","Updated mirror index to #"_$$$EnsMirrorIndex_" to trigger Trace device optimizer")
	Quit $$$OK
}

ClassMethod SetTraceOptimizer(pConfigName As %String)
{
	Set tJobConfigName=$S(""'=$G(pConfigName):pConfigName,1:$$$JobConfigName), tLogTrace=$G($$$ConfigTrace(tJobConfigName),0)
	Set $$$EnsJobLocal("LogSystemTrace")=tLogTrace
	Set tTraceDevice=$G($$$JobTraceDevice,0)
	Set $$$EnsJobLocal("DoTrace") = $S(tLogTrace:1, (0'=tTraceDevice):(""'=tTraceDevice), 1:$$$IsTerminalDevice($IO))
	Set nBankCfg=$$$EnsMsgBankIndex  If nBankCfg'=$G($$$EnsJobLocal("ArchiveFlags",tJobConfigName,"iCfg")) {
		#; init archive flags once per job and active host after each config change
		$$$catTRACE("BankCfg","Setting update #"_nBankCfg_" of local MsgBank config archive flags for host '"_tJobConfigName_"'")
		Set $$$EnsJobLocal("ArchiveFlags",tJobConfigName,"iCfg")=nBankCfg
		Do ##class(Ens.Enterprise.MsgBankOperation).InitArchiveFlags(tJobConfigName)
		Set:$D($$$EnsJobLocal("ArchiveFlags"),tFlags)#2 $$$EnsJobLocal("ArchiveFlags",tJobConfigName)=tFlags
	} Else  {
		Set:$D($$$EnsJobLocal("ArchiveFlags",tJobConfigName),tFlags)#2 $$$EnsJobLocal("ArchiveFlags")=tFlags
	}
}

ClassMethod DoTrace()
{
	Set tJobConfigName=$$$JobConfigName
	Quit $G($$$ConfigTrace(tJobConfigName),0)||(""'=$G($$$JobTraceDevice))||$$$IsTerminalDevice($IO)
}

ClassMethod WriteTrace(pTraceCategory As %String, pSourceClass, pSourceMethod, pMessage, Output pShowCat As %Boolean, pMsgSubstitutes...)
{
	#; Output pShowCat to help prevent repetitive calls
	#; we are never called for non-user messages unless they are getting displayed or logged.
	Set tJobConfigName=$$$JobConfigName  Set:""=tJobConfigName tJobConfigName="%Production"

	If $D($$$EnsJobLocal("Debug")) {
		Set pShowCat=$G($$$EnsDebug("TraceCat",tJobConfigName,pTraceCategory)
					,$G($$$EnsDebug("TraceCat",tJobConfigName)
					,$G($$$EnsDebug("TraceCat",pTraceCategory)
					,$G($$$EnsDebug("TraceCat")
					,$Case(pTraceCategory,"user":1,"nolog":1,:0)))))
	} Else {
		Set pShowCat=$G(^Ens.Debug("TraceCat",tJobConfigName,pTraceCategory)
					,$G(^Ens.Debug("TraceCat",tJobConfigName)
					,$G(^Ens.Debug("TraceCat",pTraceCategory)
					,$G(^Ens.Debug("TraceCat")
					,$Case(pTraceCategory,"user":1,"nolog":1,:0)))))
	}
	Quit:'pShowCat
	Set tLog=(("nolog"'=pTraceCategory) && $G($$$EnsJobLocal("LogSystemTrace"),$G($$$ConfigTrace(tJobConfigName),0)))
	Set:pTraceCategory="system" pTraceCategory=""
	Do:tLog ##class(Ens.Util.Log).LogTrace(pSourceClass,pSourceMethod,$G(pMessage),pTraceCategory,.pMsgSubstitutes)

	Quit:$g(%QUIET)
	
	Set tIO=$IO, tTraceDevice=$G($$$JobTraceDevice,0)
	Quit:$S((0'=tTraceDevice):(""=tTraceDevice), 1:'$$$IsTerminalDevice($IO))
	
	#;  format a $$$TRACE() message
	Use:""'=tTraceDevice tTraceDevice
	Set str=$P($$$timeLocal," ",2)
	Set str=$P(str,".",1)_"."_$e($p(str,".",2)_"000",1,3)
	Set str=$TR($Justify(str,12)," ","0")
	Set str=str_":"_..trail(pSourceClass,20)
	If ($G(pMessage)'="") {
		Set tTotalLen = $L(str)+2+$L(pMessage)
		For i=1:1:$G(pMsgSubstitutes) {
			Set tMsgPart = pMsgSubstitutes(i)
			If pMessage [ ("%"_i) {
				If tTotalLen = $$$MaxLocalLength {
					Set tMsgPart = ".."
				} ElseIf (tTotalLen - 2 + $L(tMsgPart)) > $$$MaxLocalLength {
					Set tAppend = "...Warning: string truncated!"
					Set tMsgPart = $E(tMsgPart,1,$$$MaxLocalLength - tTotalLen + 2 - $L(tAppend))_tAppend
				}
				Set pMessage = $Replace(pMessage,("%"_i),tMsgPart)
				Set tTotalLen = tTotalLen - 2 + $L(tMsgPart)
			}
		}
		Set str = str_": "_$G(pMessage)
	}
	If '$$$IsdefObject(%response) { Write !,str }
	Else { Write !,$ZCVT(str,"O","HTML")  Do %response.Flush() }
	Use:""'=tTraceDevice tIO
}

/// Get the stack trace at the point of the last error
ClassMethod GetErrorTrace(pIgnoreTop As %Integer = 0) As %List
{
	#dim tStack, tRef, tCode As %String = ""
	#dim tLevel As %Integer

	#dim tFoundECODE As %Boolean = ($ECODE="")
	#;If there is a $ECODE then we ignore pIgnoreTop 
	#dim tIgnored As %Integer = $S(tFoundECODE:-1,1:pIgnoreTop)

	For tLevel=$STACK(-1):-1:1 {
		If tFoundECODE {
			If tIgnored < pIgnoreTop {
				// Ignore topmost elements
				Set tIgnored = tIgnored + 1
				Continue
			}
		} Else {
			If $STACK(tLevel,"ECODE")'="",$ECODE[$STACK(tLevel,"ECODE") {
				Set tFoundECODE = 1
			} Else {
				Continue
			}
		}
		Set tRef = $STACK(tLevel)_"^"_$STACK(tLevel,"PLACE")
		Set tCode = $STACK(tLevel,"MCODE")

		// Note: tCode is nice, but really too long ...
		Set tStack = tStack _ $LB(tRef_":")
	}
	
	Quit tStack
}

/// Retrieve the current stack trace
ClassMethod GetStackTrace(pIgnoreTop As %Integer = 0) As %List
{
	Set tStack = ""
	Set tIgnored = -1
	
	For tLevel=$ZU(41):-1:1 {
		Set tInfo = $ZU(41,tLevel)
		Set tType = $P(tInfo,"^")
		Set tFlag = $P(tInfo,"^",4)
		If tFlag > 0 {
			If tIgnored < pIgnoreTop {
				// Ignore topmost elements
				Set tIgnored = tIgnored + 1
				Continue
			}
			Set tRef = $P(tInfo,"^",2,3)
			Set tCode = $ZSTRIP($P(tInfo,"^",5,$L(tInfo,"^")),"<>W")
			
			// Note: tCode is nice, but really too long ...
			Set tStack = tStack _ $LB(tRef_":")
		}
	}
	
	Quit tStack
}

ClassMethod trail(string, width)
{
	Set len=$l(string)
	If len'>width Quit string
	Quit "..."_$e(string,len-width+4,len)
}

/// Internal method to obtain stack trace info from embedded errors in
/// in a %Status value.
/// Return empty collection if not an error status value.
/// First find the namespace as the error status, for example, could
/// have been passed from another system.
/// Add a blank line.
/// Then decompose for the stack looking at each error in the status
/// for a stack entry in each embeddedstatus, falling back to first embeddederror
/// and then to the errors stack entry.
ClassMethod GetStackInfoAsCollection(pStatus As %Status) As %ListOfDataTypes [ Internal ]
{
	#dim tCollection = ##class(%ListOfDataTypes).%New()

	#dim tErrorList,tError,tEmbeddedStatus
	#dim tEmbeddedErrorList,tEmbeddedError,tEmbeddedErrorStack
	#dim tErrorStack
	#dim tNamespace
	#dim tFoundStackInfo As %Boolean = 0
	#dim tListPointer, tListValue

	If $$$ISERR(pStatus) {
		Try {
			Do $System.Status.DecomposeStatus( pStatus, .tErrorList)
			If $Get(tErrorList) {
				For tError = 1:1:tErrorList {
					Set tNamespace = $Get(tErrorList(tError,"namespace"))
					If (tNamespace'="") {
						Do tCollection.Insert("Reported in namespace "_tNamespace)
						Do tCollection.Insert("")
					}
					If ($Data(tErrorList(tError,"embeddedstatus"),tEmbeddedStatus)#2)||($Data(tErrorList(tError,"embeddederror",1),tEmbeddedStatus)#2) {
						Do $System.Status.DecomposeStatus(tEmbeddedStatus, .tEmbeddedErrorList)
						If $Get(tEmbeddedErrorList) {
							For tEmbeddedError = 1:1:tEmbeddedErrorList {
								If $Data(tEmbeddedErrorList(tEmbeddedError,"stack"),tEmbeddedErrorStack) {
									Set tListPointer = 0
									While $ListNext(tEmbeddedErrorStack,tListPointer,tListValue) {Do tCollection.Insert(tListValue)}
								}
							}
						}
					} ElseIf $Data(tErrorList(tError,"stack"),tErrorStack) {
						Set tListPointer = 0
						While $ListNext(tErrorStack,tListPointer,tListValue) {Do tCollection.Insert(tListValue)}
					}
				}
			}
		} Catch {
			/* do not cause error failing to convert */
			Set tCollection = ##class(%ListOfDataTypes).%New()
		}
	}
	Return tCollection
}

}
