/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.TCP.TextLineCommon Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Text Charset to use to decode incoming data and encode outgoing data
Property Charset As %String [ InitialExpression = "Default" ];

Parameter SETTINGS = "Charset::selector?context={Ens.ContextSearch/CharacterSets}";

Property %PartialLine As %String;

/// Write out lines with same terminator as lines we read
Property %HadCR As %Boolean;

Property %Table As %String;

Method WriteLine(pString As %String, pInbound As %Boolean = 0) As %Status
{
	Set $ZT="Trap"
	Set:""=..%Table ..%Table=##class(%IO.I.TranslationDevice).GetCharEncodingTable(..Charset)
	Set:"RAW"'=..%Table pString=$ZCVT(pString,"O",..%Table)
	Write pString_$S(..%HadCR:$C(13),1:"")_..Terminators, *-3
	$$$sysTRACE("Wrote terminated string '"_pString_"' to "_..IOAddr_" using Terminator "_$S(..%HadCR:"13,",1:"")_$A(..Terminators)_", charset '"_..Charset_"'")
	Quit $$$OK
Trap
	Set $ZT="", tZE=$ZE, tSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Quit tSC
}

Method Write(pString As %String, pInbound As %Boolean = 0) As %Status
{
	Set $ZT="Trap"
	Set:""=..%Table ..%Table=##class(%IO.I.TranslationDevice).GetCharEncodingTable(..Charset)
	Set:"RAW"'=..%Table pString=$ZCVT(pString,"O",..%Table)
	Write pString
	$$$sysTRACE("Wrote string '"_pString_"' to "_..IOAddr_" using charset '"_..Charset_"'")
	Quit $$$OK
Trap
	Set $ZT="", tZE=$ZE, tSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Quit tSC
}

Method ReadLine(Output pLine As %String = "", pTimeout As %Numeric = {..ReadTimeout}, pInbound As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, $ZT="Trap"
	If -1=pTimeout { Read tInStr  Set tTimedOut = 0 }
	Else { Read tInStr:pTimeout  Set tTimedOut = '$Test }
	Set tZB=$ZB
	Set $ZT=""
	If tTimedOut {
		Set ..%PartialLine=..%PartialLine_tInStr
		Quit $$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,pTimeout,$A(..Terminators)_$S($L(..Terminators)<2:"",1:","_$A($E(..Terminators,2))),tInStr)
	}
	Set tInStr=..%PartialLine_tInStr, ..%PartialLine=""
	Set:""=..%Table ..%Table=##class(%IO.I.TranslationDevice).GetCharEncodingTable(..Charset)
	If "RAW"'=..%Table { Set pLine=$ZCVT(tInStr,"I",..%Table) }
	Else { Set pLine = tInStr }
	Set ..%HadCR=(tZB=$C(13,10)||(tZB=$C(10)&&($C(13)=$E(pLine,$L(pLine)))))
	Set:..%HadCR&&(tZB=$C(10)) $E(pLine,$L(pLine))="" ; strip off $C(13) if it came before $C(10)
	$$$sysTRACE("Read terminated string '"_pLine_"' from :"_..Port_" using Terminator "_$A(..Terminators)_$S($L(..Terminators)>1:","_$A($E(..Terminators,2)),1:"")_", charset '"_..Charset_"'/"_..%Table_" with timeout="_pTimeout)
Exit
	Quit tSC
Trap
	Set $ZT="", tZE=$ZE, tSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	GoTo Exit
}

}
