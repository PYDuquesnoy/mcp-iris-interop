/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a simple box that dispays a title and an optional
/// subtitle. It is useful for adding a title to a group or menu.
Class %ZEN.Component.titleBox Extends component [ Deprecated, System = 3 ]
{

/// Title of this menu
Property title As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// Optional subtitle of this menu
Property subtitle As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// Optional style used for titleBox for this menu
Property titleStyle As %ZEN.Datatype.style;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
div.titleBoxTitle {
	font-size: 1.0em;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	border-bottom: 1px solid black;
	white-space: nowrap;
}

div.titleBoxSubtitle {
	font-size: 0.8em;
	font-weight: normal;
	text-align: left;
	padding-top: 5px;
	text-indent: 10px;
}
</style>
}

Method %DrawHTML()
{
	Set tTitle = $$$ZENVAL(..title)
	Set tSubTitle = $$$ZENVAL(..subtitle)
	&html<
		<div class="titleBoxTitle" style="#(..titleStyle)#">#($ZCVT(tTitle,"O","HTML"))#&nbsp;>
		If (tSubTitle '= "") {
			&html<<div class="titleBoxSubtitle">#($ZCVT(tSubTitle,"O","HTML"))#&nbsp;</div>>
		}
	&html<</div>>
}

}
