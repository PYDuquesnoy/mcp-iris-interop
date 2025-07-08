/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// Utilities used by Management Portal Audit.
Class %CSP.UI.System.AuditUtils Extends %RegisteredObject [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// Prepare EventData for Audit. The array of items may be classes/routines/globals/SQL tables/SQL cached queries, etc. 
/// Will insert carriege return and line feed for every 10 items for easier view audit data later.
ClassMethod PatEventDataRows(ByRef EventData As %String, ByRef pItems)
{
	Try {
		Set tTotal = 0
		Set tItem = $O(pItems(""))
		While tItem '= "" {
			Set tTotal = tTotal + 1
			Set EventData = EventData_$S(tTotal#10=0:$$$CRLF,1:"")_tItem_" "
			Set tItem = $O(pItems(tItem))
		}
		#; The maximum for EventData to pass to $system.Security.Audit is 16384
		#; So we will show the true total but will stop listing items before it reaches the limit
		#; (save few extra characters for other messages such loading background flag).
		If $L(EventData) > 16300 Set EventData = $E(EventData,1,16300)_"..."
		Set EventData = EventData_$$$CRLF_"Total: "_tTotal
		Quit
	}
	Catch {
		Do BACK^%ETN
	}
}

}
