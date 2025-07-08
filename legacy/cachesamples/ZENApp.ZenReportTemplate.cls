Class ZENApp.ZenReportTemplate Extends %ZEN.Report.Display.reportTemplate
{

XData Header1 [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<template>
<header>
<!-- REPORT HEADER -->
<p class="banner1">HelpDesk Sales1 Report</p>
<fo><line pattern="empty"/><line pattern="empty"/></fo>
<table orient="row" width="3.45in" class='table1'>
<item value="Sales by Sales Rep" width="2in">
<caption value="Title:" width="1.35in"/>
</item>
<item field="@month" caption="Month:"/>
<item field="@author" caption="Author:"/>
<item field="@runBy" caption="Prepared By:"/>
<item field="@runTime" caption="Time:"/>
</table>
</header>
</template>
}

XData Footer1 [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<template>
<table orient="row" class="table1" width="2.5in">
<item caption="Grand Total:" field="grandTotal" />
</table>
</template>
}

XData Image1
{
<template>
	<img height="50pt" width="50pt" src="images/folder.gif" />
	</template>
}

}

