/// Example of a custom Zen component.<br>
/// This defines a bullet point within a <class>sidebar</class>.<br>
/// Note that as this is an <em>object</em> and not a <em>component</em>
/// it will not be displayed; instead the <class>sidebar</class> class
/// will use this to define the items for it to display.
Class ZENDemo.Component.bullet Extends %ZEN.Component.object [ System = 4 ]
{

/// This is the XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zendemo";

/// Text for this bullet point.
Property text As %ZEN.Datatype.caption;

/// If provided, the URL of an image to show.
Property image As %ZEN.Datatype.uri;

}

