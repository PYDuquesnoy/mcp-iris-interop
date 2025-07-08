/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A group designed to have its children positioned using CSS 
/// techniques rather than via HTML <table> elements.  By default
/// this group uses a positioning of 'relative' with top and left
/// offsets of 0 and 0 - meaning 'put this group whereever it would
/// land on the page, but establish a new origin for positioning any 
/// child of this group with a position of 'absolute' (where the 
/// top and left style properties indicate the desired location of
/// the child). <br/>
/// NOTE: Absolutely positioned elements are excempt from real estate
/// calculations (according to CSS standards) therefore explicitly setting
/// the size of the containing group is recommended to avoid accidental
/// over-printing when mixing CSS and table-based page layouts.
Class %ZEN.Component.cssGroup Extends group [ Deprecated, System = 3 ]
{

/// This is what differences a cssGroup from a vgroup or hgroup
/// With a layout of 'none' the system will generate an HTML DIV
/// element rather than a TABLE structure for managine layout  
Parameter DEFAULTLAYOUT = "none";

/// Subclasses can set this to change default css class for a group.
Parameter DEFAULTENCLOSINGCLASS As STRING = "cssGroup";

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for css group." */
.cssGroup {
	position:relative;
	top: 0px;
	left: 0px;
}

</style>
}

}
