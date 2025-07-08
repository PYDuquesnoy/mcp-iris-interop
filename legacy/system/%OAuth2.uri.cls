/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// OAuth2.uri extends %String to override default MAXLEN for uri.
Class %OAuth2.uri Extends %String [ System = 4 ]
{

Parameter MAXLEN = 1024;

}
