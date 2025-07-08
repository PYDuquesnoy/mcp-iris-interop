/// Example of a composite element.<br>
/// This displays a standard menu for pages within the Demo application.
Class ZENDemo.Component.demoMenu Extends %ZEN.Component.composite [ System = 4 ]
{

/// XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zendemo";

/// Contents of this composite component.
XData Contents
{
<composite>
<hmenu cellAlign="left">
<menuItem id="menuHome" caption="Home" 
					link="ZENDemo.Home.cls"
					help="Go to main demo page."
					/>
</hmenu>
</composite>
}

}

