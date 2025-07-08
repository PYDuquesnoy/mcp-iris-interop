Class Demo.JMS.HL7toJMS Extends Ens.DataTransformDTL [ DependsOn = (EnsLib.HL7.Message, EnsLib.JMS.Message) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='EnsLib.HL7.Message' targetClass='EnsLib.JMS.Message' sourceDocType='2.7.1' create='new' language='objectscript' >
<annotation>Transform HL7 message to JMS message</annotation>
<assign value='source.OutputToString()' property='target.text' action='set' />
<assign value='"TextMessage"' property='target.type' action='set' />
<assign value='target.setStringProperty("Receiving_Application",source.GetValueAt("MSH:5.1"))' property='status' action='set' />
<assign value='target.setStringProperty("Receiving_Site",source.GetValueAt("MSH:6.1"))' property='status' action='set' />
</transform>
}

}
