/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Breaks representation of query string into pieces to avoid MAXSTRING and client side errors
Class %DeepSee.Component.queryChunk Extends %ZEN.Component.object
{

/// This is the XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Name of the calculated member.
Property chunkText As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENENCRYPT = 1, ZENSETTING = 0);

/// Create a clone of this object.
ClientMethod clone(ascomp) [ Internal, Language = javascript ]
{
	// Method added by DTB782
	var clone;
	if (ascomp) {
		// create as a component
		clone = zenPage.createComponentNS('http://www.intersystems.com/deepsee','queryChunk');
	}
	else {
		// transient object
		clone = new Object();
		clone.clone = _DeepSee_Component_queryChunk_clone;
	}
	
	clone.chunkText = this.chunkText;
	
	return clone;
}

}
