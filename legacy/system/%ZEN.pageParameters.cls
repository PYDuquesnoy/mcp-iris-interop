/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Property superclass used to define parameters available to
/// %ZEN page classes.
Class %ZEN.pageParameters Extends %ZEN.componentParameters [ Deprecated, System = 3 ]
{

/// Name of URL query parameter that will supply a value for this property. 
Parameter ZENURL As STRING;

}
