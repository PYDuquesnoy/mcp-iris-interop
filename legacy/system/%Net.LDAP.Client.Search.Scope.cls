/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.LDAP.Client.Search.Scope Extends %Integer [ ServerOnly = 1, System = 4 ]
{

Parameter DISPLAYLIST = ",Base,OneLevel,SubTree";

Parameter VALUELIST = ",0,1,2";

}
