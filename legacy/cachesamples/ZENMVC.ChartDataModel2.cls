/// Alternate Sample DataModel used by MVC Chart page.
/// This model defines a set of values that will be displayed 
/// by a set of charts (as well as a grid).
Class ZENMVC.ChartDataModel2 Extends %ZEN.DataModel.ObjectDataModel
{

Property Cars As %Integer;

Property Trucks As %Integer;

Property Trains As %Integer;

Property Airplanes As %Integer;

Property Ships As %Integer;

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As %RegisteredObject) As %Status
{
	Set scale = 100

	#; this model has multiple data series
	#; we set up the data series here

	Set ..%seriesCount = 4
	Set ..%seriesNames(1) = "USA"
	Set ..%seriesNames(2) = "Europe"
	Set ..%seriesNames(3) = "Asia"
	Set ..%seriesNames(4) = "Mars"


	#; now we provide data for each property within each series
	#; We use the %data array so that we can address multiple series

	For n = 1:1:..%seriesCount {
		Set ..%data(n,"Cars") = $R(100) * scale
		Set ..%data(n,"Trucks") = $R(100) * scale
		Set ..%data(n,"Trains") = $R(100) * scale
		Set ..%data(n,"Airplanes") = $R(100) * scale
		Set ..%data(n,"Ships") = $R(100) * scale
	}

	Quit $$$OK
}

}

