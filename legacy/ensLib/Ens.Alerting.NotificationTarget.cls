/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class used in specifying an operation which should receive a given Notification, as well as the
/// Alert Destinations that should be passed through to the operation.
Class Ens.Alerting.NotificationTarget Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property TargetConfigName As %String(MAXLEN = 128) [ Required ];

Property AlertDestinations As list Of %String(MAXLEN = "");

}
