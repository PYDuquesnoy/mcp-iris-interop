/// This class defines an example of a data connector.
/// The query for this connector uses a local table.
Class DeepSee.Model.ConnectorExample Extends %DeepSee.DataConnector
{

/// This connector supports "idlist" mode
Parameter SUPPORTSIDLIST = 1;

/// This connector supports "single" mode
Parameter SUPPORTSSINGLE = 1;

/// This XData definition defines the output of this connector.
XData Output [ XMLNamespace = "http://www.intersystems.com/deepsee/connector/output" ]
{
<connector> 
<property name="ID" displayName="ID" 
idKey="true"
 sourceProperty="%ID" /> 

<property name="PatientID" displayName="PatientID" 
sourceProperty="PatientID" /> 

<property name="Gender" displayName="Gender" 
sourceProperty="Gender" /> 

<property name="Age" displayName="Age" 
sourceProperty="Age" type="%Integer"/>

<property name="HomeCity" displayName="Home City" 
sourceProperty="HomeCity"/>

<property name="PatientGroup" displayName="Patient Group" 
sourceProperty="PatientGroup" 
 transform='$CASE(%val,"A":"Group A","B":"Group B",:%val)' />

<property name="TestScore" displayName="Test Score" 
sourceProperty="TestScore" type="%Integer"/>

</connector>
}

/// Implementation
Method %OnGetSourceResultSet(ByRef pParameters, Output pResultSet) As %Status
{
  set tSC = $$$OK
  set pResultSet = ""
  try {
      //write the basic SQL query
      set sql="SELECT %ID,PatientID,Gender,Age,HomeCity->Name AS ""HomeCity"""
             _",PatientGroup,TestScore From DeepSee_Study.Patient "

    if (..%mode="single") {
        set sql=sql_"WHERE %ID = ?"
    } elseif (..%mode="idlist") {
        set sql = sql _ "WHERE %ID in (select _DSsourceId from " 
                  _ ..%listingTable _ " where _DSqueryKey = ?)"
    }

    set tStatement = ##class(%SQL.Statement).%New()
    set tSC = tStatement.%Prepare(.sql)

    If $$$ISERR(tSC) {
        set ex = ##class(%Exception.StatusException).CreateFromStatus(tSC)
        throw ex
    }

    if (..%mode="single") {
        // pass the ID as a parameter
        set pResultSet = tStatement.%Execute(..%singleId)
    } elseif (..%mode="idlist") {
        // pass in the listing key as a parameter
        set pResultSet = tStatement.%Execute(..%listingKey)
    } else {
        set pResultSet = tStatement.%Execute()
    }

    //check %SQLCODE and report if there's an error
    If pResultSet.%SQLCODE {
        set sqlcode=pResultSet.%SQLCODE
        set message=pResultSet.%Message
        set ex = ##class(%Exception.SQL).CreateFromSQLCODE(sqlcode, message)
        throw ex
        } 

  }
  catch(ex) {
      Set tSC = ex.AsStatus()
  }

  Quit tSC
}

}

