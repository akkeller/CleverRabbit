#
#  RTKGroupDocument.py
#  CleverRabbit
#
#  Created by akk on 2006.08.26.
#  Copyright (c) 2006 __MyCompanyName__. All rights reserved.
#

from Foundation import *
import objc

class RTKGroupDocument (NSDocument):
	sourceTextField = objc.ivar(u"sourceTextField")
	destinationTextField = objc.ivar(u"destinationTextField")
	
	def duplicateAction_(self, action):
		destinationTextField.setStringValue_(sourceTextField.stringValue())
		
		pass
	
    pass
