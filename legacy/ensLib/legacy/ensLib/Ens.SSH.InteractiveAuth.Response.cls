/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to provide Interoperable SSH utilities
Class Ens.SSH.InteractiveAuth.Response Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

Property Responses As array Of %String(MAXLEN = "");

Property UseCredentialsPasswordAt As %Integer [ InitialExpression = 0 ];

Property UseSFTPPassphraseCredentialsPasswordAt As %Integer [ InitialExpression = 0 ];

}
