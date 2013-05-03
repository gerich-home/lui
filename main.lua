require "iuplua"
lo = require "lockout"
lui = require "lui"

---------------------------------------------------------------------------------------------------------------
local mainViewModel = function(self)
    self.counter = lo.observable(1)
    
    self.change = function()
        self.counter(self.counter() + 1)
    end
    
    self.hello = lo.computed(function()
        return "Counter = " .. self.counter()
    end)
    
    self.items = {
        {x = 11, y = 24},
        {x = 15, y = 21},
        {x = 12, y = 23},
    }
    
    return self
end

---------------------------------------------------------------------------------------------------------------
local template = lui.dialog {
    databind = { title = "counter" },
    size = "QUARTERxQUARTER",
    
    lui.vbox{
        lui.button {
            databind = { action = "change", title = "hello" },
        },
        lui.vbox {
            databind = { foreach = "items" },
            
            lui.hbox {
                databind = { foreach = "items" },
                
                lui.vbox {
                    lui.hbox {
                        lui.label {
                            databind = { title = "x" },
                        },
                        lui.label {
                            title = " x ",
                        },
                        lui.label {
                            databind = { title = "y" },
                        },
                    },
                    lui.button {
                        databind = { action = "change", title = "_index * _parentContext._index" }
                    }
                }
            }
        }
    }
}

local dlg = lo.applyBindings(mainViewModel{}, template)

dlg:show()

iup.MainLoop()