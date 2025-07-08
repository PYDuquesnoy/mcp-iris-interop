/// This is the template for the ZM page <class>ZMbasics.Tutorial1.HomePage</class>.
/// The ZM page invokes its page method <method>getContent</method>, which in turn invokes the 
/// <method>onGetContent</method> method of this class (the associated template class).
/// Depending on the first argument (<var>pProviderName</var>), <method>onGetContent</method> either:
/// <ul>
/// <li>Invokes another client-side method of this class, and obtains a JSON layout object.</li>
/// <li>Returns null, so that ZM calls the server-side <method>%OnGetJSONContent</method> 
/// and obtains a JSON data object. In this case, onGetContent() always returns a JSON layout object,
/// and this sample does not contain an implementation of <method>%OnGetJSONContent</method>.
/// </li>
/// </ul>
/// <p>Next tutorial in the series: <class>ZMbasics.Tutorial2.HomePage</class>.
Class ZMbasics.Tutorial1.Template Extends %ZEN.Mojo.Component.contentTemplate
{

/// Each template class must have a unique combination of short class name and NAMESPACE parameter.
Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/ZMTutorial1";

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
/// <li>The available layout objects to use as children.</li>
/// <li>The properties that you can set for these layout objects.</li>
/// <li>The syntax for referring to the available data. (Not applicable here.)
/// </ul>
ClientMethod myGetMainViewLayout(key, criteria) [ Language = javascript ]
{
    var myLayoutGraph = {};

    //The standard technique is to have a switch/case construct based on the key argument.
    //In this case, the layout is not key-specific layout, so there is no need to branch.

    myLayoutGraph = {
        children: [
            { type: '$header', $content: 'Zen Mojo Tutorial 1'},
            { type: '$p',      $content: 'This page displays some simple text.'},
            { type: '$p',      $content: 'Here is another paragraph.' },
        ]
        

    }
    return myLayoutGraph;
}

}

