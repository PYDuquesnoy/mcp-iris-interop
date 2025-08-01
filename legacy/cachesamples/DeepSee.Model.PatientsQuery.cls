/// This Data Connector uses a UNION query that combines the main DeepSee patient table with
/// the "extra" patient set (DeepSee.Study.PatientSet2).
Class DeepSee.Model.PatientsQuery Extends %DeepSee.DataConnector
{

XData SourceQuery [ XMLNamespace = "http://www.intersystems.com/deepsee/connector/query" ]
{
<sql>
SELECT %ID,PatientID,Gender,Age,HomeCity->Name AS "HomeCity",
PatientGroup,TestScore From DeepSee_Study.Patient 
UNION
SELECT %ID,PatientID,Gender,Age,HomeCity,
PatientGroup,TestScore From DeepSee_Study.PatientSet2
</sql>
}

/// This XData definition defines the output of this connector.
XData Output [ XMLNamespace = "http://www.intersystems.com/deepsee/connector/output" ]
{
<connector> 
<property name="ID" displayName="ID" idKey="true"
sourceProperty="%ID" /> 

<property name="PatientID" displayName="PatientID" 
sourceProperty="PatientID" /> 

<property name="Gender" displayName="Gender" 
sourceProperty="Gender" /> 

<property name="Age" displayName="Age" 
sourceProperty="Age" type="%ZEN.Datatype.integer"/>

<property name="HomeCity" displayName="Home City" 
sourceProperty="HomeCity"/>

<property name="PatientGroup" displayName="Patient Group" 
sourceProperty="PatientGroup" transform='$CASE(%val,"A":"Group A","B":"Group B",:%val)' />

<property name="TestScore" displayName="Test Score" 
sourceProperty="TestScore" type="%ZEN.Datatype.integer"/>

</connector>
}

}

