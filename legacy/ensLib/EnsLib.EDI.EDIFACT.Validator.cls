/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIEDIFACT

/// Error processor, more error defs, index not in errors, 
/// This is the EDIFACT Interchange parser
Class EnsLib.EDI.EDIFACT.Validator Extends EnsLib.EDI.EDIFACT.Scanner [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter AllowedPunct As String = "!""&'()*+,-./:;?= %~@[]_{}\|<>^`#$";

ClassMethod IsValidSeparator(pChar As %String) [ CodeMode = expression ]
{
..#AllowedPunct[pChar||($A(pChar)<32)
}

/// This holds the base character set
Parameter AllowedChars As String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyzÀÁÂÄàáâäÈÉÊèéêëÌÍÎìíîïÒÓÔÖòóôöÙÚÛÜùúûüÇçÑñ";

ClassMethod IsValidChar(pChar As %String) [ CodeMode = expression ]
{
..#AllowedChars_..#AllowedPunct_$Char(9,10,13)[pChar
}

ClassMethod Validate(pDoc As EnsLib.EDI.EDIFACT.Document, pValSpec As %String) As %Status
{
	Quit $$$OK
}

}
