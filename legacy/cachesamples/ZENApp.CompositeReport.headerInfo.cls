/// This is an example of how to create a user "auxiliary" class as
/// to structure information in user defined xml formats. This is used
/// by the composite class: <class>reportHeader</class>. 
/// Note that <class>%ZEN.Report.Display.node</class> is used for Report Display objects;
/// In Zen UI component design, this corresponds to the use of <class>%ZEN.Component.object</class>
/// This is *not* a composite display component, although it is
/// easy to turn it into one and is a great excercise for the reader.
Class ZENApp.CompositeReport.headerInfo Extends %ZEN.Report.Display.node [ System = 4 ]
{

Property month As %ZEN.Datatype.string;

Property author As %ZEN.Datatype.string;

Property runBy As %ZEN.Datatype.string;

Property runTime As %ZEN.Datatype.string;

}

