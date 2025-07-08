/// This class defines a listing group for the DeepSee HoleFoods sample. 
/// To see the definition of this listing group, use the DeepSee > Tools > Listing Group Manager menu option
/// or open this class in Studio.
Class HoleFoods.SampleListingGroup Extends %DeepSee.ListingGroupDefinition [ DependsOn = (HoleFoods.Cube, HoleFoods.SubjectAreaAsia) ]
{

/// Need this because we have another listing group class with the same short class name.
/// We use the XMLTYPE parameter to make sure these two classes project differently to XML.
Parameter XMLTYPE = "HoleFoodsSampleListingGroup";

Parameter DOMAIN = "HOLEFOODS";

/// This XData section provides the definition of the cube.
XData Listings [ XMLNamespace = "http://www.intersystems.com/deepsee/listinggroup" ]
{
<listingGroup name="Additional Listing for HoleFoods Sample" 
      targetCubes="Holefoods,HoleFoods Asia" >

<listing name="Another Sample Listing by Date" 
fieldList='%ID As "ID #",DateOfSale As "Sale Date"' 
 orderBy="DateOfSale,%ID"  />

<listing name="Another Sample Listing with Customer Info" 
listingType="map" 
 fieldList='%ID,Outlet->City "Store Location",Outlet->Country->Name Country,Product->Name Product,ZipCode "Customer ZipCode",Latitude,Longitude'/>

  </listingGroup>
}

}

