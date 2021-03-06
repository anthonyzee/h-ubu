###
#
# Copyright 2013 OW2 Nanoko Project
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

###
# Hubu Binding Extension
# This extension allows to bind components together using direct binding declaration
###

HUBU.Binding = class Binding
  _hub : null

  constructor : (hubu) ->
    @_hub  = hubu
    ### Injection  of the bind method ###
    myExtension = @
    @_hub.bind = (binding) ->
      myExtension.bind(binding)
      return this
  # End constructor

  ###
  # Helper method retriving a component object from the given argument.
  # If the argument is a String, it performs a lookup by name
  # If the argument is a component object, it just checks the conformity
  ###
  getComponent : (obj) ->
    component = null # The component object.
    if HUBU.UTILS.typeOf(obj) is "string"
      return @_hub.getComponent(obj)

    if HUBU.UTILS.isComponent(obj) then return obj

    return null

  getInjectedObject : (binding, component) ->
    # Determine what we need to inject : a direct reference of a proxy.
    if binding.contract?
      # A contract is set, check that the component is confirm to the contract
      # We cannot do this checking before, because the component was unkown.
      if not HUBU.UTILS.isObjectConformToContract(component, binding.contract)
        throw new Exception("Cannot bind components, the component is not conform to contract")
        .add("component", component.getComponentName())
        .add("contract", binding.contract)
      else
        if not binding.proxy? or binding.proxy
          # Create the proxy
          return HUBU.UTILS.createProxyForContract(binding.contract, component);
    # In all other cases, we do nothing.
    return component

  bind : (binding) ->
    if (not binding? || not binding?.to  || not binding?.component  || not binding?.into)
      throw new Exception "Cannot bind components - component, to and into must be defined"

    component = @getComponent(binding.component)
    if not component?
      throw new Exception("Cannot bind components - 'component' is invalid").add("component", binding.component)

    to = @getComponent(binding.to)
    if not to?
      throw new Exception("Cannot bind components - 'to' is invalid").add("component", binding.to)

    component = @getInjectedObject(binding, component)

    # Determine the injection method
    switch HUBU.UTILS.typeOf(binding.into)
    # Call the bind function
      when "function" then binding.into.apply(to, [component])
      when "string"
      # It can be the name of a function or a (scalar) field
      # If `[to[binding.into]` does not exist, inject it:
        if not to[binding.into]? then to[binding.into] = component
          # If `[to[binding.into]` is a function invoke it:
        else if HUBU.UTILS.isFunction(to[binding.into]) then to[binding.into].apply(to, [component])
          # If `[to[binding.into]` is a member, assign it:
        else to[binding.into] = component
      else
      # Unsupported injection type
        throw new Exception("Cannot bind components = 'into' must be either a function or a string")
        .add("into", binding.into)

# End of the bind method.

# Declare the extension
getHubuExtensions().binding =  Binding;
