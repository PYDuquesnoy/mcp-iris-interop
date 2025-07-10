/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An Ensemble adapter wrapping up pipe functionality
Class EnsLib.Pipe.InboundAdapter Extends (Ens.InboundAdapter, Ens.Util.Pipe) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "%Stream.Object";

Property CommandLine As %String(MAXLEN = 2048);

Property Timer As %String;

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

Property PipeMode As %String [ InitialExpression = "WR" ];

Parameter SETTINGS As %String = "CommandLine,Timer,Charset::selector?context={Ens.ContextSearch/CharacterSets},PipeMode";

/// default InboundAdapter behavior: always call ProcessInput on CallInterval
Method OnTask() As %Status
{
	Set tSC = $$$OK,$ZT="Trap"
	do {
		// First, compute the number of seconds to wait
		Set tSC = ..CheckTimer(..Timer,.tSeconds) Quit:$$$ISERR(tSC)
		
		// If it's too long, or tSeconds is invalid, bail out
		If (tSeconds > ..CallInterval) || (tSeconds < 0) Quit
		
		// Wait ...
		If tSeconds > 0 Hang tSeconds

		Set pCommandLine = ..CommandLine

		// Now, we must run the command ...
		Set tSC = ..RunCommand(pCommandLine,..PipeMode,..Charset,$$$NULLOREF,.tOutput)
		Quit:$$$ISERR(tSC)
		
		// Next, send the command output to the business service
		Set tSC = ..BusinessHost.ProcessInput(tOutput)
		
	} while(0)
	
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
