Include (%occSAX, %occXSLT)

/// jsl.COSBarChartPerson
Class ZENApp.ZenReportBarChart Extends %ZEN.Report.reportPage
{

/// Class name of application this report belongs to.
Parameter APPLICATION;

/// This is the default display mode for this report.
Parameter DEFAULTMODE = "html";

// Parameter XSLTMODE = "server";

Parameter EMBEDXSL As BOOLEAN = 0;

// Parameter REPORTDIR = "C:\perforce\Users\levinson\P57969";

/// This XML defines the logical contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
 name="test" sql="Select Top 10 Name,Age from Sample.Person">
<!-- add definition of the report here. -->
<group name="Person">
<attribute name="Name" field="Name" />
<attribute name="Age" field="Age" />
</group>
</report>
}

/// This XML defines the display for this report.
/// This is used to generate the XSLT stylesheets for both HTML and XSL-FO.
XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display"
 name="test" title="Bar Charts">
 <document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" marginTop="1.0in" marginBottom="1.0in" headerHeight="1in">
  </document>
<body>
<p>This is a sample</p>
  <cbarChart ongetData="getchartdata" title="My First Chart" height="400px" width="200px" axisLineStyle="stroke:red" appearance="3D" valueLabelsVisible="true">
  <xAxis majorGridLines="true" labelAngle="45" />
  <yAxis labelAngle="45"/>
  </cbarChart>  
  
    <cbarChart ongetData="getchartdata2" title="My Second Chart" height="400px" width="200px" axisLineStyle="stroke:red" appearance="3D" chartPivot="true" seriesColors="silver,gold" seriesColorsOverride="rgb(255,0,0)">
  
  </cbarChart>
    <cbarChart ongetData="getchartdata2" title="My Third Chart - 2D, pivot " height="400px" width="200px" axisLineStyle="stroke:red" appearance="2D" chartPivot="true">
  
  </cbarChart>
<cbarChart ongetData="getchartdata2" title="My Fourth Chart - 2D, no pivot" height="400px" width="200px" axisLineStyle="stroke:red" appearance="2D" chartPivot="false">
  
  </cbarChart>
    <cbarChart ongetData="getchartdata2" title="My Fifth Chart - 3D, stacked" height="400px" width="200px" axisLineStyle="stroke:red" appearance="3D" chartStacked="true">
  
  </cbarChart>  

  <cbarChart ongetData="getchartdata2" title="My Sixth Chart - 2D, stacked" height="400px" width="200px" axisLineStyle="stroke:red" appearance="2D" chartStacked="true">
  
  </cbarChart>  

</body>
</report>
}

Method getchartdata(ByRef var, chartObject)
{
	do {
		Set tSC=##class(%XML.XPATH.Document).CreateFromFile(..xmlfile,.tDoc)
		if $$$ISERR(tSC) quit
		Set tSC=tDoc.EvaluateExpression("/test","Person",.tResults)
		if $$$ISERR(tSC) quit
		For tI=1:1:tResults.Count()
		{
			Set tResult=tResults.GetAt(tI)
		
			if (tResult.Type=$$$XPATHDOM)
			{
				
			
				While tResult.Read() {
					do tResult.MoveToAttributeName("Age")
					Set var(0,$i(var(0))-1)=tResult.Value

				}
			
			}
		}
	} while (0) ;
}

Method getchartdata2(ByRef var, chartObject)
{
	for i=1:1:10 set var(0,i-1)=i
	for i=1:1:10 set var(1,i-1)=10-i+1
}

}

