/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An Ensemble adapter wrapping up pipe functionality
Class EnsLib.Pipe.OutboundAdapter Extends (Ens.OutboundAdapter, Ens.Util.Pipe) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Command line that should be invoked
Property CommandLine As %String(MAXLEN = 2048);

/// Character encoding scheme used to translate output to the file. For no encoding, use 'Binary'.
/// Other choices include: <br/>
///  Native - the default character encoding of the installed locale of the InterSystems IRIS server <br/>
///  latin1 - the ISO Latin1 8-bit encoding <br/>
///  ISO-8859-1 - the ISO Latin1 8-bit encoding <br/>
///  UTF-8 - the Unicode 8-bit encoding <br/>
///  Unicode - the Unicode 16-bit encoding  (Little-Endian) <br/>
///  UnicodeBig - the Unicode 16-bit encoding (Big-Endian) <br/>
///  @&lt;ttable&gt; - &lt;ttable&gt; means a raw InterSystems character translation table name. A prefix of '@' means to use the named table.
Property Charset As %String [ InitialExpression = "Native" ];

Property PipeMode As %String [ InitialExpression = "R" ];

Parameter SETTINGS As %String = "CommandLine,Charset::selector?context={Ens.ContextSearch/CharacterSets},PipeMode";

Method Pipe(pExtraArgs As %String = "", pInput = "", ByRef pOutput = "") As %Status
{
	Set tSC = $$$OK,$ZT = "Trap"
	do {
		
		Set pCmd = ..CommandLine
		
		If pExtraArgs '= "" {
			If ($E(pCmd,$L(pCmd))'=" ") && ($E(pExtraArgs,1) '= " ") {
				Set pCmd = pCmd _ " "
			}
			Set pCmd = pCmd _ pExtraArgs
		}

		// Now, we must run the command ...
		Set tSC = ..RunCommand(pCmd,..PipeMode,..Charset,pInput,.pOutput)
		Quit:$$$ISERR(tSC)
		
	} while(0)
	
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
