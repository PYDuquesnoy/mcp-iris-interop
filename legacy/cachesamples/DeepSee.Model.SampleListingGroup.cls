/// This class defines a listing group for the DeepSee Patients sample. 
/// To see the definition of this listing group, use the DeepSee > Tools > Listing Group Manager menu option
/// or open this class in Studio.
Class DeepSee.Model.SampleListingGroup Extends %DeepSee.ListingGroupDefinition [ DependsOn = (DeepSee.Model.PatientsCube, DeepSee.Model.RelCubes.RPatients, DeepSee.Model.SubjectAreas.AsthmaPatients, DeepSee.Model.SubjectAreas.YoungPatients), Not ProcedureBlock ]
{

/// Need this because we have another listing group class with the same short class name.
/// We use the XMLTYPE parameter to make sure these two classes project differently to XML.
Parameter XMLTYPE = "PatientsSampleListingGroup";

Parameter DOMAIN = "PATIENTSAMPLE";

XData Listings [ XMLNamespace = "http://www.intersystems.com/deepsee/listinggroup" ]
{
<listingGroup xmlns="http://www.intersystems.com/deepsee/listinggroup" name="Additional Listings for Patients Sample" disabled="false" targetCubes="PATIENTS,RELATEDCUBES/PATIENTS,ASTHMAPATIENTS,YOUNGPATIENTS">
  <listing name="Sample Listing 1" displayName="Sample Listing 1" disabled="false" listingType="table" fieldList="PatientID,Gender,BirthDate,Age,HomeCity-&gt;PostalCode ZIP,HomeCity-&gt;Name City,PatientGroup"></listing>
  <listing name="Sample Listing 2" disabled="false" listingType="table" fieldList="PatientID,PatientGroup,DiagnosesAsString,TestScore"></listing>
</listingGroup>
}

}

