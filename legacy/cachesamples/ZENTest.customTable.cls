/// Simple custom component used for testing custom components.
Class ZENTest.customTable Extends %ZEN.Component.tablePane [ System = 4 ]
{

/// This is the XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zentest";

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	Write "<div>CUSTOM TABLE</div>"
	
	Do ..columns.Clear()

	Set column = ##class(%ZEN.Auxiliary.column).%New()
	Set column.colName="ID"
	Set column.width="1px"
	Do ..columns.Insert(column)
	Do:$IsObject(%page) %page.%AddComponent(column)

	Do ##super()
}

}

