/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Handshake message for initializing a connection to the archive server - goes both ways
Class Ens.Enterprise.MsgBank.Handshake Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLNAME = "SHAKE";

Parameter XMLIGNORENULL = 1;

/// The archive protocol version(s) the client proposes / the Server accepts
Property Version As %String(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "1.0" ];

/// The node the Client remembers / the node the Server prescribes
Property Node As %String(MAXLEN = "");

/// The node the Client would be if starting fresh
Property RawNode As %String(MAXLEN = "");

/// The node's IP Address and port
Property IPAddress As %String(MAXLEN = "");

/// The node's webserver IP Address, port, and URL root
Property WebServer As %String(MAXLEN = "");

/// The top Id on the client of Ens.MsgHeader that we archived
Property LastHdrId As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// The current top Id on the client of Ens.MessageHeader
Property CurrHdrId As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// The top Id on the client of Ens.Util.Log (the Event Log) that we archived
Property LastEvtId As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// The current top Id on the client of Ens.Util.Log (the Event Log)
Property CurrEvtId As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// If not empty then this is a mirrored instance
Property MirrorName As %String(XMLPROJECTION = "ATTRIBUTE");

}
