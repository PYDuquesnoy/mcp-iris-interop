/// Example form page based on the CRUD (Create, Read, Update, Delete) base class.
Class ZENMVC.PatientForm Extends ZENMVC.CRUDTemplate
{

/// Title of this page.
Parameter PAGETITLE = "Patient Form";

/// Name of DataModel class that drives the form.
Parameter MODELCLASS = "ZENMVC.FormDataModel";

/// Name of SQL table that drives the pick list.
Parameter LOOKUPTABLE = "ZENDemo_Data.Patient";

/// Name of SQL column displayed in the pick list.
Parameter LOOKUPCOLUMN = "Name";

}

