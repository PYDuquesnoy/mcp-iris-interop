/// This class defines a cube based on DeepSee.Study.City. 
/// <p>Where applicable, the dimension, hierarchy, and level definitions here use the same names
/// as in the Patients cube, so that these cubes can be used together.
/// 
Class DeepSee.Model.CityCube Extends %DeepSee.CubeDefinition [ DependsOn = DeepSee.Study.City ]
{

Parameter DOMAIN = "PATIENTSAMPLE";

XData Cube [ XMLNamespace = "http://www.intersystems.com/deepsee" ]
{
<cube 
name="Cities"  displayName="Cities"  
 owner="_SYSTEM"
 caption="Cities"
 sourceClass="DeepSee.Study.City"
 >

<measure name="City Count" displayName="City Count" 
sourceExpression="1" 
aggregate="SUM" />

<measure name="Population" displayName="Population" 
sourceProperty="Population" 
aggregate="SUM"/>

<measure name="Avg Population" displayName="Avg Population" 
sourceProperty="Population" 
aggregate="AVG"/>

<dimension name="HomeD" displayName="CityD" 
allCaption="All Cities" allDisplayName="All Cities">
<hierarchy name="H1">
<level name="ZIP" displayName="ZIP" 
sourceProperty="PostalCode" />
<level name="City" displayName="City" 
sourceProperty="Name" >
<property name="Population" displayName="Population" 
sourceProperty="Population" />
<property name="Principal Export" displayName="Principal Export" 
sourceProperty="PrincipalExport"  />
</level>
</hierarchy>
</dimension>

<listing name="Details" displayName="Details" 
fieldList='Name as "City",Population,PostalCode as "ZIP Code",PrincipalExport as "Principal Export"'>
</listing>

</cube>
}

}

