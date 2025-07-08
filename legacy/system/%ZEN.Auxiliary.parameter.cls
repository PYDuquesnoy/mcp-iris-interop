/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a parameter name/value pair for use by certain
/// data displaying components. Typically this is used by components, 
/// such as <class>%ZEN.Component.dynaView</class> or <class>%ZEN.Component.tablePane</class>, to let
/// users provide values that are, in turn, passed on to the
/// callback that provides the contents of the component.
Class %ZEN.Auxiliary.parameter Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Value of the parameter.
Property value As %ZEN.Datatype.string(ZENEXPRESSION = 1);

}
