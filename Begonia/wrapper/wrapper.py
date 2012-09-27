import objc
from AppKit import *
from PyObjCTools import AppHelper

app = NSApplication.sharedApplication()
rect = NSMakeRect(100, 100, 768, 1024)
window = NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(rect, NSTitledWindowMask, 2, 0)
window.makeKeyAndOrderFront_(None)
window.setTitle_("Begonia")

mainMenu = NSMenu.alloc().init()

fileItem = NSMenuItem.alloc().init()
fileItem.setTitle_("File")
mainMenu.addItem_(fileItem)

fileMenu = NSMenu.alloc().init()
fileMenu.addItemWithTitle_action_keyEquivalent_("Quit", objc.selector(app.terminate_, signature="v@:@"), "q")
fileItem.setSubmenu_(fileMenu)

app.setMainMenu_(mainMenu)


mainView = view.alloc()

AppHelper.runEventLoop()
