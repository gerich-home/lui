lui
===

Lui is insipered with the Knockout MVVM framework for Javascript (see http://knockoutjs.com/).

Lui is aimed to bring facilities of this framework into lua.

Lui is built upon IUP gui library (http://www.tecgraf.puc-rio.br/iup/) to describe UI and uses Lockout framework (https://github.com/callin2/lockout.lua) to handle dependency tracking

Lui is distributed under the MIT license

Example
===
To see how to use Lui refer to main.lua file.
Here is a simplified example.

    ---------------------------------------------------------------------------------------------------------------
    require "iuplua"
    lo = require "lockout"
    lui = require "lui"
    
    ---------------------------------------------------------------------------------------------------------------
    -- define viewmodel constructor
    local viewModel = function(self)
        self.counter = lo.observable(1)
        
        self.increment = function()
            self.counter(self.counter() + 1)
        end
        
        return self
    end
    
    ---------------------------------------------------------------------------------------------------------------
    -- define ui template
    local template = lui.dialog {
        title = "Lui sample",
        size = "QUARTERxQUARTER",
        
        lui.vbox{
            lui.button {
                title = "Increment counter",
                databind = { action = "change"}
            },
            lui.label {
                databind = { title = "counter" }
            }
        }
    }
    
    -- create IUP controls by a template for the viewmodel instance 
    local dlg = lo.applyBindings(viewModel{}, template)
    
    --show it
    dlg:show()
    
    iup.MainLoop()
