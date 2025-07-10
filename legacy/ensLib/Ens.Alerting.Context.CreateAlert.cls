/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Context for determining whether a ManagedAlert should be created.
Class Ens.Alerting.Context.CreateAlert Extends %RegisteredObject [ System = 4 ]
{

Property AlertRequest As Ens.AlertRequest;

Property AlertGroups As %String(MAXLEN = 2500);

Property BusinessPartner As %String(MAXLEN = 128);

Property Owner As %String(MAXLEN = 128);

}
