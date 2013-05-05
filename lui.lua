require "iuplua"
lo = require "lockout"

---------------------------------------------------------------------------------------------------------------
lo.utils = lo.utils or {}
lo.utils.unwrapObservable = function(observaleOrValue)
    if lo.isObservable(observaleOrValue) then
        return observaleOrValue()
    else
        return observaleOrValue
    end
end

---------------------------------------------------------------------------------------------------------------
lo.nestContext = function(bindingContext, parentContext)
    local bindingContext_mt = {
        __index = parentContext
    }
    setmetatable(bindingContext, bindingContext_mt)
    
    return bindingContext
end

---------------------------------------------------------------------------------------------------------------
lo.applyBindings = function(viewModel, template, bindingContext)
    if not bindingContext then
        bindingContext = lo.nestContext({
            _root = viewModel,
            _data = viewModel
        }, viewModel)
    end
    
    local controlsDescendantBindings = false
    local options = {}
    for k, v in pairs(template.options) do
        options[k] = v
    end
    
    local bindings = options.databind
    
    local control = {
        realControl = lo.observable()
    }
    local control_mt = {
        __index    = options,
        __newindex = options,
        __len      = function() return #options end
    }
    setmetatable(control, control_mt)
    
    if bindings then
        for bindingName, bindingValue in pairs(bindings) do
            local bindingHandler = lo.bindingHandlers[bindingName]
            if not bindingHandler then
                error("Unable to parse binding " .. bindingName)
            end
            
            local valueAccessorContext = lo.nestContext({
                _context = bindingContext,
                _element = control
            }, bindingContext)
            
            local valueAccessor = load("return " .. bindingValue, nil, nil, valueAccessorContext)
            if bindingHandler.init then
                local bindingOptions = bindingHandler:init(control, valueAccessor, viewModel, bindingContext)
                controlsDescendantBindings = controlsDescendantBindings or (bindingOptions and bindingOptions.controlsDescendantBindings)
            end
            
            if bindingHandler.update then
                lo.computed(function() bindingHandler:update(control, valueAccessor, viewModel, bindingContext) end)
            end
        end
    end
    
    if not controlsDescendantBindings then
        for i = 1, #options do
            options[i] = lo.applyBindings(viewModel, options[i], bindingContext)
        end
    end

    local realControl = lo.createControl(template.name, options)
    
    control_mt.__index    = realControl
    control_mt.__newindex = realControl
    control_mt.__len      = function() return iup.GetChildCount(realControl) end
    
    control.realControl(realControl)
    
    return realControl
end

---------------------------------------------------------------------------------------------------------------
lo.createControl = function(name, options)
    return iup[name](options)
end

---------------------------------------------------------------------------------------------------------------

lo.bindingHandlers = lo.bindingHandlers or {}

lo.bindingHandlers.title = {
    update = function(self, control, valueAccessor, viewModel)
        control.title = lo.utils.unwrapObservable(valueAccessor())
    end
}

lo.bindingHandlers.action = {
    update = function(self, control, valueAccessor, viewModel, bindingContext)
        local action = lo.utils.unwrapObservable(valueAccessor())
        control.action = function() action(bindingContext._data) end
    end
}

lo.bindingHandlers.foreach = {
    template = {},
    controls = {},
    
    init = function(self, control, valueAccessor, viewModel, bindingContext)
        local childCount = #control
        local template = {}
        
        self.controls[control] = {}
        self.template[control] = template
        
        for i = 1, childCount do
            template[i] = control[i]
            control[i] = nil
        end
        
        return { controlsDescendantBindings = true }
    end,
    update = function(self, control, valueAccessor, viewModel, bindingContext)
        local realControl = control.realControl()
        if not realControl then return end
        
        local items = lo.utils.unwrapObservable(valueAccessor())
        
        local newParents = { [1] = viewModel }
        if bindingContext._parents then
            for i, value in ipairs(bindingContext._parents) do
                newParents[i + 1] = value
            end
        end
        
        local commonBindingContext = lo.nestContext({
            _parent        = viewModel,
            _parents       = newParents,
            _parentContext = bindingContext
        }, bindingContext)
        
        local template = self.template[control]
        local controls = {}
        
        for _, controls in pairs(self.controls[control]) do
            for i = 1, #controls do
                iup.Destroy(controls[i])
            end
        end
        
        local index = 1
        for key, item in pairs(items) do
            local itemBindingContext = {
                _index = index,
                _key   = key,
                _data  = item,
            }
            local itemBindingContext_mt
            if type(item) == "table" or type(item) == "userdata" then
                itemBindingContext_mt = {
                    __index = function(t, k) return item[k] or commonBindingContext[k] end
                }
            else
                itemBindingContext_mt = {
                    __index = commonBindingContext
                }
            end
            setmetatable(itemBindingContext, itemBindingContext_mt)
            
            local newControls = {}
            for i = 1, #template do
                local newControl = lo.applyBindings(item, template[i], itemBindingContext)
                iup.Append(realControl, newControl)
                iup.Map(newControl)
                newControls[i] = newControl
            end
            
            controls[key] = newControls
            index = index + 1
        end
        
        self.controls[control] = controls
        
        iup.Refresh(realControl)
    end
}

---------------------------------------------------------------------------------------------------------------
local lui
do
    lui = {}
    local lui_mt = {
        __index = function(self, name)
            return function(options)
                return {
                    name = name,
                    options = options
                }
            end
        end
    }
    setmetatable(lui, lui_mt)
end

------------------------------------------------------------------------------------------------------------------
return lui