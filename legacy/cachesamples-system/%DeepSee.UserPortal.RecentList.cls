/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A work list class that provides a list of recent items within a User portal page.
Class %DeepSee.UserPortal.RecentList Extends %DeepSee.UserPortal.WorkList [ System = 4 ]
{

/// Icon (16x16) to display for this work list.
Parameter ICON = "deepsee/ds2_clock_44.png";

/// Return the localized display name for this work list.
ClassMethod %GetName() As %String
{
	Quit $$$Text("Recent items","%DeepSee")
}

/// Return the localized title for this work list.
ClassMethod %GetTitle() As %String
{
	Quit $$$Text("Recent items","%DeepSee")
}

/// Return an optional tool tip to display.
ClassMethod %GetToolTip() As %String
{
	Quit $$$Text("Show list of recent items","%DeepSee")
}

/// Draw the contents of the worklist.<br/>
/// <var>pPanelNo</var> is the worklist panel number.
ClassMethod %DrawWorkList(pPanelNo As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetRecentItemsForUser(.tItems)
		If $$$ISERR(tSC) Quit

		Set hlpRemove = $$$Text("Remove item from recent items list","%DeepSee")
		Set tRemoveIcon = "deepsee/ds2_x_44.png"
		
		// list
		&html<<div id="worklist#(pPanelNo)#" class="worklist">
		<table class="worklistTable" width="100%" cellspacing="0" border="0" cellpadding="0">>
		Set r = 0
		Set n = $O(tItems(""),-1)
		While (n'="") {
			Set r = r + 1
			Set tFullName = $LG(tItems(n),1)
			Set tName = $LG(tItems(n),2)
			Set tFolder = $LG(tItems(n),3)
			Set tTip = $LG(tItems(n),4)
			Set tType = $LG(tItems(n),5)
			Set tIcon = $LG(tItems(n),6)
			Set tDate = ##class(%DeepSee.UserPortal.Utils).%FormatDate($LG(tItems(n),7))
			Set tURL = $LG(tItems(n),8)
			Set tCls = $S(r#2:"worklistRowOdd",1:"worklistRowEven")
			&html<<tr title="#($zconvert(tTip,"O","HTML"))#" class="#(tCls)#" onmouseover="this.className='worklistRowHover';" onmouseout="this.className='#(tCls)#';">
				<td><img src="#(tIcon)#" style="height:32px;width:32px;padding:2px;" title="#($zconvert(tType,"O","HTML"))#" onclick="zenPage.gotoFavorite('#($ZCVT(tURL,"O","JS"))#');"/></td>
				<td width="90%" onclick="zenPage.gotoFavorite('#($ZCVT(tURL,"O","JS"))#');">
				<div class="favFolder">#($zconvert(tFolder,"O","HTML"))#</div>
				<div class="favName">#($zconvert(tName,"O","HTML"))#</div>
				<div class="favDate">#($zconvert(tDate,"O","HTML"))#</div></td>
				<td><img src="#(tRemoveIcon)#" style="height:12px;width:12px;padding:2px;" title="#(hlpRemove)#" onclick="zenPage.removeFromRecentList('#($zconvert($zconvert(tFullName,"O","JS"),"O","HTML"))#');"/></td>
				</tr>>
			Set n = $O(tItems(n),-1)
		}
		&html<</table></div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
