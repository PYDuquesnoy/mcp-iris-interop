/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple title pane
Class %ZEN.Component.titlePane Extends component [ Deprecated, System = 3 ]
{

/// Title displayed within this pane.
Property title As %ZEN.Datatype.caption;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
.titlePane {
	color: darkblue;
	background: #FFFAE7;
	width: 100%;
	padding: 3px;
	border-bottom: 1px solid darkblue;
	font-size: 1.4em;
	font-family: verdana;
	text-align: center;
}
</style>
}

/// Static HTML display method
Method %DrawHTML()
{
	&html<<div class="titlePane">#($ZCVT(..title,"O","HTML"))#</div>>
}

}
