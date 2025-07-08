/// A sample subclass of %XML.DataSet that implements a .Net typed dataset.
Class SOAP.ByNameDataSet Extends %XML.DataSet [ ProcedureBlock ]
{

/// The XML namespace for typed DataSets
Parameter NAMESPACE = "http://tempuri.org/ByNameDataSet";

/// The class name that contains the query for typed DataSet
Parameter CLASSNAME = "Sample.Person";

/// The query name for typed DataSet
Parameter QUERYNAME = "ByName";

}

