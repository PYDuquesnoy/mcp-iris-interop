/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Config.CredentialsList Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Property CredentialsItems As list Of Ens.Config.Credentials(XMLNAME = "Item", XMLPROJECTION = "ELEMENT");

ClassMethod OpenAll() As Ens.Config.CredentialsList
{
	Set tObj=..%New()
	&SQL( DECLARE cL CURSOR FOR
		SELECT SystemName INTO :tSysName FROM Ens_Config.Credentials)
	&SQL(OPEN cL)
	For { &SQL(FETCH cL)  Quit:SQLCODE
		set tCred = ##class(Ens.Config.Credentials).%OpenId(tSysName)
		do tObj.CredentialsItems.Insert(tCred)
	}
	&SQL(CLOSE cL)
	Quit tObj
}

}
