/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Context for determining what actions should be taken for a Managed Alert that hasn't been updated within its action window.
Class Ens.Alerting.Context.OverdueAlert Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property ManagedAlert As Ens.Alerting.ManagedAlert;

Property CurrentTime As Ens.DataType.UTC;

Property NewNextActionTime As Ens.DataType.UTC;

Property NewEscalationLevel As %Integer;

}
