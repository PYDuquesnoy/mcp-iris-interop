/// This class is for use with DeepSee II. 
/// <p>It contains a subject area based on the patients cube (DeepSee.Model.PatientsCube). 
/// To view the subject area definition, open this class in Studio.
/// 
Class DeepSee.Model.SubjectAreas.DemoMDX Extends %DeepSee.SubjectArea [ DependsOn = DeepSee.Model.PatientsCube ]
{

/// This XData definition defines the SubjectArea.
XData SubjectArea [ XMLNamespace = "http://www.intersystems.com/deepsee/subjectarea" ]
{
<subjectArea name="DemoMDX" 
	baseCube="Patients" 
	countMeasureCaption="%COUNT" >
  <dimension name="AgeD" hidden="false">
    <hierarchy name="H1" hidden="false">
      <level name="Age" hidden="true"></level>
    </hierarchy>
  </dimension>

  <dimension name="AllerSevD" hidden="true">
  </dimension>

  <dimension name="BirthD" hidden="false">
    <hierarchy name="H1" hidden="false">
      <level name="Decade" hidden="true"></level>
      <level name="Period" hidden="true"></level>
      <level name="Date" hidden="true"></level>
    </hierarchy>
  </dimension>

  <dimension name="BirthTD" hidden="true">
  </dimension>

  <dimension name="DocD" hidden="false">
    <hierarchy name="H1" hidden="false">
      <level name="Doctor Group" hidden="true"></level>
    </hierarchy>
  </dimension>

  <dimension name="PatGrpD" hidden="true">
  </dimension>

  <dimension name="ProfD" hidden="true">
  </dimension>

<measure name="Encounter Count" hidden="true"/>

<measure name="Avg Enc Count" hidden="true"/>


</subjectArea>
}

}

