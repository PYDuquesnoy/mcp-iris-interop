/// This is an alternative use of Zen templates. Runtime expressions are still allowed, however
/// templates are only instantiated at runtime (they can be thought of as a set of default children
/// for a Report Display group. Any Runtime expressions used in a template will be evaluated in the
/// context of the host - report or composite - that invokes the template.
/// Templates and composites can interact in a powerful way when using the parameterization made available
/// by Runtime expressions.
/// Note that a default value for the template argument is provided to cause the Display XData to be included
/// automatically in the host component.
Class ZENApp.CompositeReport.reportHeader Extends %ZEN.Report.Display.composite [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/report/display/2.0/sample";

Property infoSeparator As %ZEN.Datatype.string;

Property reportTitle As %ZEN.Datatype.string(XMLPROJECTION = "element");

Property reportSubtitle As %ZEN.Datatype.string(XMLPROJECTION = "element");

Property reportInfo As headerInfo;

XData Display [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<composite xmlns="http://www.intersystems.com/zen/report/display">
<header> 
<!-- REPORT HEADER -->
<p class="banner1">#(..reportTitle)#</p>
<fo id="infoSeparator"></fo>
<table orient="row" width="3.45in" class='table1'>
<item value="#(..reportSubtitle)#" width="2in">
<caption value="Title:" width="1.35in"/>
</item>
<item field="#(..reportInfo.month)#" caption="Month:"/>
<item field="#(..reportInfo.author)#" caption="Author:"/>
<item field="#(..reportInfo.runBy)#" caption="Prepared By:"/>
<item field="#(..reportInfo.runTime)#" caption="Time:"/>
</table>
</header>
</composite>
}

/// use this to parse the value for infoSeparator and create the proper fo objects.
/// for demo purposes we just defined that infoSeparator should be <displayComponent>:<repeat>
Method %OnAfterCreateComposite() As %Status
{
	set tSC=$$$OK
	set infoSeparator=##class(%ZEN.Report.reportPage).%GetComponentById("infoSeparator")
	set repeat=$piece(..infoSeparator,":",2)
	if repeat<1 { set repeat=1 }
	set type="%ZEN.Report.Display."_$piece(..infoSeparator,":",1)
	for i=1:1:repeat {
		set separator=$zobjclassmethod(type,"%New")
		if type="%ZEN.Report.Display.line" {
			s separator.pattern="empty"
		}
		set tSC=infoSeparator.children.Insert(separator)
	}
	quit tSC
}

}

