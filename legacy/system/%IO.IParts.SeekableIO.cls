/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Aggregation holder class for methods implemented in Seekable stream classes
/// The methods of this class work for both Byte and Character streams
Class %IO.IParts.SeekableIO [ Abstract, System = 2 ]
{

Property Position As %Integer [ InitialExpression = 0, ReadOnly ];

Property Size As %Integer [ Calculated, ReadOnly ];

Method Rewind(Output pSC As %Status)
{
	Do ..Seek(1,.pSC)
}

Method Seek(pPosition As %Integer = 1, Output pSC As %Status) As %Boolean [ Abstract ]
{
	Quit 0
}

Method SizeGet() As %Integer
{
	Quit 0
}

Method TruncateAt(pPosition As %Integer, Output pSC As %Status) As %Boolean
{
	Set pSC=$$$ERROR($$$NotImplemented)
	Quit 0
}

Method Clear(Output pSC As %Status) As %Boolean
{
	Quit ..TruncateAt(1,.pSC)
}

Method Find(pMatch As %String, pPosition As %Integer = 1, pEndPosition As %Integer = -1, Output pSC As %Status, pReadLines As %Boolean = 0) As %Integer
{
	Set pSC=$$$OK
	If pPosition<1 {
		Set pPosition=1
	} ElseIf '..Seek(pPosition) {
		Quit 0
	}
	Set tStr="",tFind=0,tTargetlen=$L(pMatch),tMaxTmpLen=$$$MaxLocalLength-$L(pMatch)-2
	While (pEndPosition=-1||(..Position<pEndPosition)) && '..AtEnd {
		Set tTmpSize=$S((pEndPosition=-1||(..Position+tMaxTmpLen<pEndPosition)):tMaxTmpLen, 1:pEndPosition-..Position)
		Set tStrlen=$L(tStr)
		Set tTmp=..Read(tTmpSize,,.pSC),tStr=$E(tStr,tStrlen-tTargetlen+2,tStrlen)_tTmp Quit:$$$ISERR(pSC)
		Set tFind=$Find(tStr,pMatch)
		If tFind Set tFind=tFind+pPosition-1 Do ..Seek(tFind,.pSC) Quit
		Set pPosition=pPosition+$L(tTmp)-tTargetlen+1
	}
	Quit tFind
}

}
