/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a server-side class used to provide information about nodes 
/// displayed within a <class>%ZEN.SVGComponent.radialNavigator</class> component.
Class %ZEN.Auxiliary.radialNode Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// The caption displayed for this node.
Property caption As %ZEN.Datatype.string;

/// Optional value associated with this node.
Property value As %ZEN.Datatype.string;

/// onclick handler for this node.
Property onclick As %ZEN.Datatype.eventHandler;

/// Optional style used for displaying this node.
Property style As %ZEN.Datatype.svgStyle;

}
