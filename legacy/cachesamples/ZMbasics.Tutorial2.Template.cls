/// This is the template for the ZM page <class>ZMbasics.Tutorial2.HomePage</class>.
/// <p>The primary difference from Tutorial 1 is that *this* tutorial demonstrates 
/// the server-side method <method>%OnGetJSONContent</method>.
/// <p>Next tutorial in the series: <class>ZMbasics.Tutorial3.HomePage</class>.
Class ZMbasics.Tutorial2.Template Extends %ZEN.Mojo.Component.contentTemplate
{

/// Each template class must have a unique combination of short class name and NAMESPACE parameter.
Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/ZMTutorial2";

/// Localization domain; best practice is to always specify this
Parameter DOMAIN = "Zen Mojo Demo";

/// Implementation of callback.
/// This client-side method is called by the page method getContent(). 
/// If <var>providerName</var> is the name of a layout object, this method invokes 
/// <method>myGetMainViewLayout</method> and returns the result.
/// Otherwise, this method returns null, which means that ZM calls the 
/// <method>%OnGetJSONContent</method> of this template (thus going to the server instead).
ClientMethod onGetContent(providerName, key, criteria) [ Language = javascript ]
{
    var content = null;

    // dispatch to convenient methods
    // if content is null, then the %OnGetJSONContent method will be called

    switch(providerName) {
    case 'mainViewLayout':
        content = this.myGetMainViewLayout(key,criteria);
        break;
    }
    return content;
}

/// Method used to get layout information for the mainView component. 
ClientMethod myGetMainViewLayout(key, criteria) [ Language = javascript ]
{
    var myLayoutGraph = {};

    //The standard technique is to have a switch/case construct based on the key argument.
    //In this case, the layout is not key-specific layout, so there is no need to branch.

    myLayoutGraph = {
        children: [
            { type: '$header', $content:'Zen Mojo Tutorial 2'},
            { type: '$p',      $content:'Below are details for the first person in Sample.Person.'},
            { type: '$p',	   title:'Name', $content:'=[personName]' },
            { type: '$p',      title:'Birth Date', $content:'=[personDOB]' }
        ]

    }
    return myLayoutGraph;
}

/// Implementation of callback method. 
/// This method provides content for the ZM page that uses this template. Arguments:
/// <ul>
/// <li><var>pProviderName</var> is the name of the provider, as declared in the PROVIDERLIST parameter of the page.</li>
/// <li><var>pKey</var> is an application-defined key that is used to indicate which content is to be served. 
/// Not used in this implementation.</li>
/// <li><var>pCriteria</var> is an object containing search criteria. Not used in this implementation.</li>
/// <li><var>pParms</var> is an array of additional parameters from the JSON provider (not currently used).</li>
/// <li><var>pObject</var> is the object that will be served to the client in JSON format.</li>
/// <li><var>pLoad</var> is true if this is called when the page is first being served. In this case, this method will be 
/// called even though there may a client-side method used to load the content.</li>
/// </ul>
ClassMethod %OnGetJSONContent(pProviderName As %String, pKey As %String, ByRef pParms, Output pObject As %RegisteredObject, pCriteria As %RegisteredObject, pLoad As %Boolean = 0) As %Status
{
    // The standard technique is to have an outermost if/elseif construct  
    // based on the pProviderName argument; in this case there is only one 
    // possible value for pProviderName.
    if (pProviderName = "mainViewData") {
        
        // Within a pProviderName branch, the standard technique is to have an 
        // if/elseif construct based on the key argument.
        // In this case, there are no keys, so there is no need to branch

        //create proxy object that the ZM will convert to a JSON string and send to the client
        set pObject = ##class(%ZEN.proxyObject).%New()

        set tPerson = ##class(Sample.Person).%OpenId(1)
        set pObject.personName=tPerson.Name
        set pObject.personDOB=$zdate(tPerson.DOB,3)

    } ; additional pProviderName branches would go here
    quit $$$OK
}

}

