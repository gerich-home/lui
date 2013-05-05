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
    
    self.items = lo.computed(function()
        print(1)
        items = {}
        for i = 1, self.counter() do
            items[i] = i * i
        end
        
        return items
    end)
    
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
            
            lui.label {
                databind = { title = "_data" }
            }
        }
    }
}

local dlg = lo.applyBindings(mainViewModel{}, template)

dlg:show()

iup.MainLoop()