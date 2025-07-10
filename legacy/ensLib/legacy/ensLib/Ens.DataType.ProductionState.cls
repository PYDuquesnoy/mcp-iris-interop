/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class is DEPRECATED. Refer to the Ens.Constants include file for the set of state values,
/// and the <code>ProductionStateToText</code> method in <class>Ens.Config.Production</class> for the 
/// preferred way to convert a production state to a text string.
/// Encapsulate a standard Production State value.
Class Ens.DataType.ProductionState Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",Running,Stopped,Suspended,Troubled,NetworkStopped";

Parameter VALUELIST = ",1,2,3,4,5";

}
