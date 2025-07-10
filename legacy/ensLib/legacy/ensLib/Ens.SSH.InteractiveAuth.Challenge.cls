/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to provide Interoperable SSH utilities
Class Ens.SSH.InteractiveAuth.Challenge Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

Property Username As %String(MAXLEN = 128);

Property Instructions As %String(MAXLEN = "");

Property Prompts As array Of %String(MAXLEN = "");

Property PromptFlags As array Of %String(MAXLEN = "");

}
