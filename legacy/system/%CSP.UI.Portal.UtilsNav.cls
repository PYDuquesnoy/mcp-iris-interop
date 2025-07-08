/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class contains Properties and Methods in support of component tableNavBar in SMP. <br/>
/// The purpose is to remember the last Page size and Maximum rows of the tableNavBar
/// If you want to remember these, then do the following:<br/>
/// <ul>
/// <li>Extend your page to this class and add to the <tableNavBar>: </li>
/// <li>(1) saveSizeMax="true" </li>
/// <li>(2) onPageSizeChange="zenPage.navPageSizeChanged(value);" if you want to remember page size</li>
/// <li>(3) onMaxRowsChange="zenPage.navMaxRowsChanged(value);" if you want to remember max rows</li>
/// <li>In %OnAfterCreatePage() of your page, add: Do ..%GetNavTableState()</li>
/// </ul>
/// Example pages:<br/>
/// - use %CSP.UI.Portal.Utils as super class: %CSP.UI.Portal.Processes, %CSP.UI.Portal.ClassList<br/>
/// - use %CSP.UI.Portal.Template as super class: %CSP.UI.Portal.Namespaces, %CSP.UI.Portal.Users (with Filter=true)<br/>
/// 
Class %CSP.UI.Portal.UtilsNav [ Abstract, System = 4 ]
{

/// Filter value user entered into the "Filter" field in the table navigator. This value is saved and reloaded for this page.
Property Filter As %ZEN.Datatype.string [ InitialExpression = "*" ];

/// Page size value user entered into the "Page size" field in the table navigator. This value is saved and reloaded for this page.
Property TablePageSize As %Integer [ InitialExpression = "0" ];

/// Max rows value user entered into the "Max rows" field in the table navigator. This value is saved and reloaded for this page.
Property TableMaxRows As %Integer [ InitialExpression = "1000" ];

/// Used to Save TableNavigatorBar Values. 
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName(),"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

/// Maybe overriden by subclass.
ClientMethod navPageSizeChanged(value) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows);
}

/// Maybe overriden by subclass.
ClientMethod navMaxRowsChanged(value) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value);
}

/// Call this method from %OnAfterCreatePage to load the last saved values for tableNavBar. <br/>
/// Pass in a special name you used for this page if differ from ..%GetPageName. <br/>
/// For example Mappings is used for Global/Routine/Package Mappings, 
/// so the name used for save has MapType in it to distinguish.
/// If tableId is not "table" then pass it in as the second piece delimited by "^" (example: %CSP.UI.Portal.SQL.TuneTable).
Method %GetNavTableState(pPageName As %String = "") As %Status
{
	Try {
		Set tableId = "table"
		If pPageName = "" {
			Set pPageName = ..%GetPageName()
		} Else {
			Set:$P(pPageName,"^",2)'="" tableId=$P(pPageName,"^",2)
		}
		Set TableState = $G($$$IRISTempMgt($Username,pPageName,"TableNavState"))
		If TableState '= "" {
			Set ..Filter = $lg(TableState,1)
			Set ..TablePageSize = +$lg(TableState,2)
			Set ..TableMaxRows = $S(+$lg(TableState,3)=0:1000,1:$lg(TableState,3))
			Set ..%GetComponentById(tableId).pageSize = ..TablePageSize
			Set ..%GetComponentById(tableId).maxRows = ..TableMaxRows
			Set ..%GetComponentById(tableId).lastFilter = ..Filter
		}		
		} Catch {
			Set:pPageName="" pPageName = "PageNameUnknown"
			Set $$$IRISTempMgt($Username,pPageName,"error")=$ZE
		}
	Quit $$$OK
}

}
