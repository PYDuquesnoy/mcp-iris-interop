/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// OAuth2.JWKS extends %String to override default MAXLEN so that a JSON object may be stored as a string.
Class %OAuth2.JSONString Extends %String [ System = 4 ]
{

Parameter MAXLEN;

}
