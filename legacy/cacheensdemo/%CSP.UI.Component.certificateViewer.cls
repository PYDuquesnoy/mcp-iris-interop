/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %CSP.UI.Component.certificateViewer
Class %CSP.UI.Component.certificateViewer Extends %ZEN.Component.component [ System = 3 ]
{

/// This is the XML namespace for this component.
Parameter NAMESPACE [ Internal ] = "http://www.intersystems.com/zen";

Property Certificate As %Binary(MAXLEN = "") [ Internal ];

Property SubjectOnly As %Boolean [ InitialExpression = 0, Internal ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.certlbl {
	text-align: right;
	vertical-align: top;
	font-weight: bold;
}
</style>
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML() [ Internal ]
{
	If ($length(..Certificate) = 0) {
		Quit $$$OK
	}
	
	set decoded = $SYSTEM.Encryption.Base64Decode(..Certificate)
	
	Set Fields = $lb()
	Set Fields("Subject") = $System.Encryption.X509GetField(decoded,"Subject")
	
	If ('..SubjectOnly) {
		Set Fields("Issuer") = $System.Encryption.X509GetField(decoded,"Issuer")
		Set Fields("SubjectKeyIdentifier") = ..StringToHex($System.Encryption.X509GetField(decoded,"SubjectKeyIdentifier"),1,0)
		Set Fields("Serial Number") = $System.Encryption.X509GetField(decoded,"SerialNumber")
	
		Set SHA1Thumbprint = $SYSTEM.Encryption.SHA1Hash(decoded) //Take SHA1 Hash
		Set SHA1ThumbprintHex = ..StringToHex(SHA1Thumbprint,1,0)
		Set ThumbprintSHA1Base64 = $SYSTEM.Encryption.Base64Encode(SHA1Thumbprint)
	
		Set Fields("Thumbprint(SHA1)") = SHA1ThumbprintHex
	}
	
	&html<<table style="font: 13px monospace;">>
	Set i = ""
	while 1 {
		Set i = $order(Fields(i)) q:i=""
		Set Fields(i) = $zcvt(Fields(i),"O","HTML")
		
		&html<<tr>>
		&html<<td style="text-align: right; vertical-align: top; font-weight: bold; padding-right:10px;">#(i)#:</td><td>>
		
		If ((i = "Issuer") || (i = "Subject")) {
			&html<<table style="border-collapse:collapse;">>
			Set subFields = $lfs(Fields(i),",")
			for j = 1:1:$ll(subFields) {
				&html<<tr><td style="text-align: right; vertical-align: top; font-weight: bold; padding-right: 10px;">>
				w $zconvert($p($lg(subFields,j),"=",1),"O","HTML")
				&html<</td><td style="padding-right: 10px;">>
				w " - "
				&html<</td><td>>
				w $zconvert($p($lg(subFields,j),"=",2),"O","HTML")
				&html<</tr>>
			}
			&html<</table>>
		} Else {
			&html<#($zconvert(Fields(i),"O","HTML"))#>
		}
		
		&html<</td></tr>>
	}
	&html<</table>>
}

ClassMethod StringToHex(Input As %String, indent As %Boolean = 0, printH As %Boolean = 1) As %String [ Internal ]
{
	Set wide=0
	If $ZISWIDE(Input) Set Input = $ZWUNPACK(Input),wide=1
	
	Set result = $Case(printH,1:"0x",0:"")
	
	Set ext=$Case(indent,1:" ",":":":",0:"")
	
	For i=1:1:$length(Input) {
		Set block = $ASCII($Extract(Input,i,i))
		Set first = ($Zboolean(block,240,1)/16) //Mask last 4 bits and shift right 4
		Set second = $Zboolean(block,15,1) //Mask first 4 bits
		
		Set first=$Case(first,
			10:"A",
			11:"B",
			12:"C",
			13:"D",
			14:"E",
			15:"F",
			:first
		)
		
		Set second=$Case(second,
			10:"A",
			11:"B",
			12:"C",
			13:"D",
			14:"E",
			15:"F",
			:second
		)
		
		If i=$l(Input) Set ext=""
		
		Set result = result_first_second_ext	
		
	}
	
	If wide Set result=$ZWPACK(result)
	
	Quit result
}

}
