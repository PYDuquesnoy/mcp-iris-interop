/// Simple class used to test JavaScript classes.
Class ZENTest.customClass Extends %ZEN.Component.object
{

/// XML namespace for class
Parameter NAMESPACE = "http://www.intersystems.com/zentest";

/// test
ClientMethod test() [ Language = javascript ]
{
	alert('Hello from customClass.');
}

}

