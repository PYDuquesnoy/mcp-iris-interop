/// Sample DataModel used by MVC Chart page.
/// This model defines a set of values that will be displayed 
/// by a set of charts (as well as a grid).
Class ZENMVC.ChartDataModel Extends %ZEN.DataModel.ObjectDataModel
{

Property P1 As %Integer;

Property P2 As %Integer;

Property P3 As %Integer;

Property P4 As %Integer;

Property P5 As %Integer;

Property P6 As %Integer;

Property P7 As %Integer;

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As %RegisteredObject) As %Status
{
	Set scale = 1
	
	Set ..P1 = $R(100) * scale
	Set ..P2 = $R(100) * scale
	Set ..P3 = $R(100) * scale
	Set ..P4 = $R(100) * scale
	Set ..P5 = $R(100) * scale
	Set ..P6 = $R(100) * scale
	Set ..P7 = $R(100) * scale

	Quit $$$OK
}

}

