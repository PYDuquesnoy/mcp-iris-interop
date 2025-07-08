/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A work list class that provides a list of favorite items within a User portal page.
Class %DeepSee.UserPortal.FavoritesList Extends %DeepSee.UserPortal.WorkList [ System = 4 ]
{

/// Icon (16x16) to display for this work list.
Parameter ICON = "deepsee/ds2_star_44.png";

/// Return the localized display name for this work list.
ClassMethod %GetName() As %String
{
	Quit $$$Text("Favorites","%DeepSee")
}

/// Return the localized title for this work list.
ClassMethod %GetTitle() As %String
{
	Quit $$$Text("Favorites","%DeepSee")
}

/// Return an optional tool tip to display.
ClassMethod %GetToolTip() As %String
{
	Quit $$$Text("Show list of favorite items","%DeepSee")
}

/// Draw the contents of the worklist.<br/>
/// <var>pPanelNo</var> is the worklist panel number.
ClassMethod %DrawWorkList(pPanelNo As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetFavoritesForUser(.tFavorites)
		If $$$ISERR(tSC) Quit

		Set hlpRemove = $$$Text("Remove item from favorites list","%DeepSee")
		Set tRemoveIcon = "deepsee/ds2_x_44.png"
		
		// list
		&html<<div id="worklist#(pPanelNo)#" class="worklist">>

		// JMD: show message if no favorites
		If '$D(tFavorites) {
			&html<<div style="color:#808080;padding:10px;">>
			Write $$$Text("You have no favorites.")
			&html<</div>>
		}
		Else {
			&html<<table class="worklistTable" width="100%" cellspacing="0" border="0" cellpadding="0">>
			Set r = 0
			Set n = $O(tFavorites(""))
			While (n'="") {
				Set r = r + 1
				Set tFullName = $LG(tFavorites(n),1)
				Set tName = $LG(tFavorites(n),2)
				Set tFolder = $LG(tFavorites(n),3)
				Set tTip = $LG(tFavorites(n),4)
				Set tType = $LG(tFavorites(n),5)
				Set tIcon = $LG(tFavorites(n),6)
				Set tDate = ##class(%DeepSee.UserPortal.Utils).%FormatDate($LG(tFavorites(n),7),1)
				Set tURL = $LG(tFavorites(n),8)
				Set tCls = $S(r#2:"worklistRowOdd",1:"worklistRowEven")
				&html<<tr title="#($zconvert(tTip,"O","HTML"))#" class="#(tCls)#" onmouseover="this.className='worklistRowHover';" onmouseout="this.className='#(tCls)#';">
					<td><img src="#(tIcon)#" style="height:32px;width:32px;padding:2px;" title="#(tType)#" onclick="zenPage.gotoFavorite('#($ZCVT(tURL,"O","JS"))#');"/></td>
					<td width="90%" onclick="zenPage.gotoFavorite('#($ZCVT(tURL,"O","JS"))#');">
					<div class="favFolder">#($zconvert(tFolder,"O","HTML"))#</div>
					<div class="favName">#($zconvert(tName,"O","HTML"))#</div>
					<div class="favDate">#(tDate)#</div></td>
					<td><img src="#(tRemoveIcon)#" style="height:12px;width:12px;padding:2px;" title="#(hlpRemove)#" onclick="zenPage.removeFromFavorites('#($zconvert($zconvert(tFullName,"O","JS"),"O","HTML"))#');"/></td>
					</tr>>
				Set n = $O(tFavorites(n))
			}
			&html<</table>>
		}
		&html<</div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
