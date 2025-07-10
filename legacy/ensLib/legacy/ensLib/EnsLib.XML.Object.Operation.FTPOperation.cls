/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.XML.Object.Operation.FTPOperation is the FTP based operation class which writes an XML document
/// based on a persistent object.
Class EnsLib.XML.Object.Operation.FTPOperation Extends EnsLib.XML.Object.Operation.FileOperation [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.OutboundAdapter";

Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q.xml", Required ];

}
