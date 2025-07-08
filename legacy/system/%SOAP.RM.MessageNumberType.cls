/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Message number is an unigned long that is > 0
Class %SOAP.RM.MessageNumberType Extends %xsd.unsignedLong [ System = 3 ]
{

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

Parameter MINVAL = 1;

}
