/// This is the template for the ZM page <class>ZMbasics.Tutorial3.HomePage</class>.
/// <p>The primary difference from Tutorial 2 is that *this* tutorial demonstrates 
/// the <method>onselect</method> event handler.
/// <p>Next tutorial in the series: <class>ZMbasics.Tutorial4.HomePage</class>.
Class ZMbasics.Tutorial3.Template Extends %ZEN.Mojo.Component.contentTemplate
{

/// Each template class must have a unique combination of short class name and NAMESPACE parameter.
Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/ZMTutorial3";

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
/// <p>This method must create and return a JS object with layout information.
/// Specifically, the JS object has a set of children, each of which corresponds to a block on the page.
/// To create this JS object, it is necessary to know only the following:
/// <ul>
/// <li>Syntax to create a JS object.</li>
/// <li>The available ZM building blocks to use as children.</li>
/// <li>The properties that you can set for these building blocks.</li>
/// <li>The syntax for referring to the available data. 
/// The ongetdata callback, ultimately, creates a JSON string that includes a set of name/value pairs
/// with values obtained from the server.
/// When this JSON string arrives on the client, the name/value pairs are available to the client.
/// Then, in this method, you can use the syntax =[name] to access a value. 
/// For example, =[dateOfBirth] accesses the dateOfBirth value. 
/// </ul>
/// <p>ZM passes two values to this kind of callback in a &lt;mojo:documentView>:
/// <var>key</var> and <var>criteria</var>. 
/// Following best practices, this method uses these values as arguments so that they
/// are available if needed.
/// In this scenario, these values are not needed, and the method does not use them.
ClientMethod myGetMainViewLayout(key, criteria) [ Language = javascript ]
{
    var myLayoutGraph = {};

    //The standard technique is to have a switch/case construct based on the key argument.
    //In this case, the layout is not key-specific layout, so there is no need to branch.

    myLayoutGraph = {
        children: [
            { type: '$header', $content: 'Zen Mojo Tutorial 3'},
            { type: '$p'},
            { type: '$button', $content:'Show Person 1', key:'showPerson1'},
            { type: '$p'},
            { type: '$button', $content:'Show Person 2', key:'showPerson2'},
            { type: '$p'},

            { type: '$div', key:'person1',
               children:[
	            { type: '$p', title:'Name', $content:'=[person1Name]' },
    	        { type: '$p', title:'Birth Date', $content:'=[person1DOB]' }
                ]},
            
            { type: '$div', key:'person2', hidden:true,
               children:[
	            { type: '$p', title:'Name', $content:'=[person2Name]' },
    	        { type: '$p', title:'Birth Date', $content:'=[person2DOB]' }
                ]},



        ]
        

    }
    return myLayoutGraph;
}

/// Notification that a select event has happened
ClientMethod onselect(key, value, docViewId) [ Language = javascript ]
{
   console.log('in onselect(), docViewId: '+docViewId+ ' key: ' + key + ' value: ' + value);
   
   if (docViewId=='mainView') {
	   var person1=zen('mainView').getItemByKey('person1');
	   var person2=zen('mainView').getItemByKey('person2');

       if (key=='showPerson1') {
	       person1.$show();
	       person2.$hide();
	   } else if (key=='showPerson2') {
	       person1.$hide();
	       person2.$show();
	   }
   
   }
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

        set person1 = ##class(Sample.Person).%OpenId(1)
        set pObject.person1Name=person1.Name
        set pObject.person1DOB=$zdate(person1.DOB,3)
        
        set person2 = ##class(Sample.Person).%OpenId(2)
        set pObject.person2Name=person2.Name
        set pObject.person2DOB=$zdate(person2.DOB,3)
   
    } ; additional pProviderName branches would go here
    quit $$$OK
}

}

