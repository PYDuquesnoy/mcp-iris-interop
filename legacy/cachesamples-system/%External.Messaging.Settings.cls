/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.Settings Extends (%RegisteredObject, %JSON.Adaptor) [ Abstract ]
{

Method ToJSON() As %String
{
    Do ..%JSONExportToString(.json)
    Quit json
}

Method FromJSON(json As %String) As %Status
{
   Quit ..%JSONImport(json)
}

}
