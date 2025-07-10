/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.DT.AuthenticationMode Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

/// 'NoAuthentication' - Authentication not required
/// 'UddiAuthentication' - use UddiAuthentication
/// 'WindowsAuthentication' - use WindowsAuthentication	
Parameter VALUELIST = ",NoAuthentication,UddiAuthentication,WindowsAuthentication";

}
