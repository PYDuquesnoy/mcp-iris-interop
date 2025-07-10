/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class to implement common code editor code to allow for code indentation and
/// similar functionality.
Class EnsPortal.Util.CodeEditorBase [ Abstract, System = 4 ]
{

/// Keypress handler for Zen textarea controls which automatically inserts the indentation
/// used on the previous line of the control when the user hits the Enter key.
/// Note that the actual whitespace determination is performed in <method>getPrevWhitespace</method>().
ClientMethod codeKeyPress(zenControl, evt, language = "") [ Language = javascript ]
{
	if (zenControl && evt) {
		var control = zenControl.findElement('control');
		var keyCode = (evt.keyCode ? evt.keyCode : evt.which);
		if (control && (keyCode == zenENTER)) {
			var value = control.value;
			var valBefore, valAfter;
			if ((typeof control.selectionStart == 'number') && (typeof control.selectionEnd == 'number')) {
				valBefore = value.substring(0,control.selectionStart);
				valAfter = value.substring(control.selectionStart);
				var whitespace = zenPage.getPrevWhitespace(valBefore,language);
				control.value = valBefore + '\n' + whitespace + valAfter;
				
				control.selectionStart = control.value.length - valAfter.length;
				control.selectionEnd = control.selectionStart;
				return false;
			}
			else {
				var range = document.selection.createRange();
				if (range && (range.parentElement() == control)) {
					var textRange = control.createTextRange();
					var startRange = control.createTextRange();
					textRange.moveToBookmark(range.getBookmark());
					startRange.setEndPoint('EndToStart',textRange);
					
					valBefore = value.substring(0,startRange.text.length);
					valAfter = value.substring(startRange.text.length);
					var whitespace = zenPage.getPrevWhitespace(valBefore,language);
					
					control.value = valBefore + '\r\n' + whitespace + valAfter;;
					textRange = control.createTextRange();
					var newPos = valBefore.length - (valBefore.split('\r\n').length - 1) + 1 + whitespace.length;
					textRange.move('character',newPos);
					textRange.select();
					return false;
				}
			}
			
		}
	}
	return true;
}

/// Helper method to supply anticipated indentiation required based on preceeding code input lines (<var>previousData</var>)</br>
/// <h2>Object Script and Basic</h2>
/// Continue previous indent or default to indent of two whitespace characters 
/// <h2>Python code entry conveniences</h2>
/// <h3>Feature Colon ":"</h3>
/// When the user types colon ":" ( ignoring trailing white space) + Enter key.
/// This will automatically increment indent for new or nested block
/// <example language="python">
/// for item in range(0,int(request.StringVaue)):
///   context.TheList.Insert(item+1)
/// </example>
/// Where indent of increment was automatically provided for new line starting "context.TheList ..."<br/>
/// <h3>Feature "pass" keyword</h3>
/// When a line only contains pass keyword anticipate placeholder for code block
/// and decrement indent on the following line
/// <example language="python">
/// if (x==1):
///   pass
/// else:
///   pass
/// </example>
/// Where indent was automatically decremented on new line after "pass" keyword
/// <h3>Feature Empty lines</h3>
/// Second empty line indicates end of block scope
/// When two sequential empty lines ( ignoring whitespace ) are typed,
/// the following new line will decrement the indent
/// <example>
/// for item in range(0,int(request.StringValue)):
///   context.TheList.Insert(item+1)
///   
///   
/// if (x==1):
///   pass
/// </example>
/// At end of line with "context ... " line, enter key was pressed three times.
/// The increment is automatically decremented so that the "if" command starts in a lower code block scope
/// In this example no indent was needed.
ClientMethod getPrevWhitespace(previousData, codelanguage = "") [ Language = javascript ]
{
	var whitespace = '  ';  // indent step
	if (typeof previousData == 'string') {
		// note that \r\n on IE is ignored - we only care about the data after the \n
		var previousDataLines=previousData.split('\n');
		var prevLine = previousDataLines.pop();
		var whitespaceMatch = prevLine.match(/^(\s+)/);
		if ('python'==codelanguage) {
			whitespace='  ' // in case default is changed for other language code maintenance
			/*	When the user types colon ":" ( ignoring trailing white space) + Enter key
				automatically add additional indent for new or nested block
				For example:
				--------------
				for item in range(0,int(request.StringVaue)):
					context.TheList.Insert(item+1)
				--------------
				where indent was automatically added to new line starting "context.TheList ..."
			*/
			if (prevLine.trimRight().endsWith(':')) {
				whitespace = (whitespaceMatch?whitespaceMatch[0]+whitespace:whitespace)
			/*	When a line only contains pass keyword anticipate placeholder for code block
			   	and decrement indent on the following line
				For example:
				--------------
				if (x==1):
				  pass
				else:
				  pass
				--------------
				where indent was automatically removed on new line after "pass" keyword
			*/
			} else if ('pass'==(prevLine.trim())) {
				whitespace=(whitespaceMatch?whitespaceMatch[0]:whitespace)
				whitespace=whitespace.slice(0,(whitespace.length-2))
			} 
			else if (''==prevLine.trim() && whitespaceMatch && whitespaceMatch[0].length>1) {
				/*  If second empty line anticipate change of block scope
					When two sequential empty lines ( ignoring whitespace ) are detected 
					decrement the indent to format ending a code block
				For example:
				------------------
				for item in range(0,int(request.StringValue)):
				  context.TheList.Insert(item+1)


				if (x==1):
				  pass
				------------------
				After the "context ... " line, enter key is pressed twice
				The increment is automatically decremented so that the "if" command starts in a lower code block scope
				*/
				var prevprevLine=previousDataLines.length>0?previousDataLines.pop():''
				if (''==prevprevLine.trim()) {
					whitespace=whitespaceMatch[0].slice(0,((whitespaceMatch[0].length)-2))
				} else {
					// No change in block scope anticipated so maintain existing block scope
					// Continue same indent
					whitespace=whitespaceMatch[0]
				}
			} else {
				// No change in block scope anticipated so maintain existing block scope
				// Where there was no block scope continue with NO indent
				whitespace=whitespaceMatch?whitespaceMatch[0]:''
			}
			// For other languages ObjectScript and Basic
			// Continue indent
		} else if (whitespaceMatch) {
			whitespace = whitespaceMatch[0];
		}
	}
	return whitespace;
}

}
