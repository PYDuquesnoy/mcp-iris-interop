/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a server-side class used to provide information about nodes 
/// displayed within a <class>%ZEN.Component.dynaTree</class> tree control component.
Class %ZEN.Auxiliary.NodeInfo Extends %RegisteredObject [ Deprecated, System = 3 ]
{

/// Display value associated with this node. This is what
/// is displayed within the control.
Property text As %ZEN.Datatype.string;

/// Optional logical value associated with this node.
Property value As %ZEN.Datatype.string;

/// Optional URL associated with this node. If provided,
/// then clicking on this node will cause the browser to
/// go to this new link.
Property link As %ZEN.Datatype.uri;

/// Set this value to true if this node has children and it
/// should be initially displayed as expanded.
Property expanded As %ZEN.Datatype.boolean;

/// Set this value to true if the current node has subnodes.
Property hasChildren As %ZEN.Datatype.boolean;

/// Optional URL for an icon to display for this node.
/// If provided this overrides the general icons provided by the
/// tree component. Note that if this node has children, then open and
/// closed icons will not be used if this value is supplied.<br>
/// For best results, this should be a 16x16 gif file with a transparent
/// background.
Property icon As %ZEN.Datatype.uri;

/// Optional tooltip displayed for this item.
Property title As %ZEN.Datatype.string;

/// Optional CSS style applied to this item.
Property style As %ZEN.Datatype.style;

}
