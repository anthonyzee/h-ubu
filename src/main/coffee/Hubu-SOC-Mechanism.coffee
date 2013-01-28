###
# Define the building block of the Service-Orientation of H-UBU
###

###
TODO Used by -> the usage graph
TODO Several contract within a registration
TODO Service Ranking
TODO Factories / Object creation strategy ?
###


getGlobal().SOC = getGlobal().SOC ? {}

SOC = getGlobal().SOC

###
# Service Registrations represents a published service from the publisher point of view.
###
SOC.ServiceRegistration = class ServiceRegistration
  # Static Id counter.
  @_nextId : 1

  # Instance id
  _id : -1

  # The component holding this registration
  _component : null

  # The contract
  _contract : null

  # The hub
  _hub : null

  # State
  _registered : false

  # Properties
  _properties : {}

  # The service reference
  _reference : null

  # The service registry in which the service mush be registered.
  _registry : null

  # Service object or function to create the service object.
  _svcObject : null


  @getAndIncId : ->
    id = SOC.ServiceRegistration._nextId
    SOC.ServiceRegistration._nextId = SOC.ServiceRegistration._nextId + 1
    return id

  constructor : (contract, component, svcObject, properties, hub, registry) ->
    @_id = -1 # Be don't have an id yet
    if not component? then throw new Exception "Cannot create a service registration without a valid component"
    if not svcObject? then throw new Exception "Cannot create a service registration without a valid service object"
    if not contract? then throw new Exception "Cannot create a service registration without a contract"
    if not hub? then throw new Exception "Cannot create a service registration without the hub"
    if not registry? then throw new Exception "Cannot create a service registration without the registry"

    @_component = component
    @_hub = hub
    @_contract = contract
    @_properties = properties ? {}
    @_registry = registry
    @_svcObject = svcObject

    # Extends properties
    @_properties["service.contract"] = @_contract
    @_properties["service.publisher"] = @_component

    # We don't have a service reference until we're published.

  register : ->
    throw new Exception("Invalid registration, the component is not plugged on the hub") unless HUBU.UTILS.isComponentPlugged(@_component, @_hub) or @_component is @_hub

    @_id = SOC.ServiceRegistration.getAndIncId()
    @_reference = new SOC.ServiceReference(@)
    # Add the id to the properties.
    @_properties["service.id"] = @_id
    @_registered = @_id isnt -1
    return @_id

  unregister : ->
    @_registered = false

  isRegistered : -> return @_registered

  getReference : ->
    throw new Exception("Invalid lookup, the component is not plugged on the hub") unless HUBU.UTILS.isComponentPlugged(@_component, @_hub) or @_component is @_hub

    return @_reference

  getProperties : -> return @_properties

  getService : (component) ->
    return @_svcObject unless HUBU.UTILS.isFunction(@_svcObject)
    return @_svcObject.apply(@_component, [component])

  setProperties : (properties) ->
    old = null
    if @isRegistered()
      # Generate the old service reference only if we are registered.
      # Clone the properties
      props = HUBU.UTILS.clone(@_properties, ["service.contract", "service.publisher"])
      # To recreate the service reference, we create a fake service registration copying the current one.
      old = new SOC.ServiceRegistration(@_contract, @_component,  @_svcObject, props, @_hub, @_registry)
      old._id = @_id
      old._reference = new SOC.ServiceReference(old)

    # Now we can modify the properties.
    @_properties = properties ? {}
    @_properties["service.contract"] = @_contract
    @_properties["service.publisher"] = @_component
    @_properties["service.id"] = @_id
    if @isRegistered()  and old?
      # Fire the MODIFIED service event
      event = new SOC.ServiceEvent(SOC.ServiceEvent.MODIFIED, @.getReference())
      @_registry.fireServiceEvent(event, old.getReference())


###
#  Service Reference represents a published service from the consumer point of view.
###
SOC.ServiceReference = class ServiceReference
  # The service registration
  _registration : null
  constructor: (registration) ->
    @_registration = registration

  getContract : -> return @_registration.getProperties()["service.contract"]

  getProperties : -> return @_registration.getProperties()

  getProperty : (key) -> return @_registration.getProperties()[key]

  getId : -> return @_registration.getProperties()["service.id"]

  isValid : -> return @_registration.isRegistered


SOC.ServiceEvent = class ServiceEvent
  @REGISTERED : 1
  @MODIFIED : 2
  @UNREGISTERING : 4
  @MODIFIED_ENDMATCH : 8

  _type : 0
  _reference : null

  constructor: (type, ref) ->
      @_type = type
      @_reference = ref

  getReference : -> return @_reference

  getType : -> return @_type


###
# The Service Registry class
###
SOC.ServiceRegistry = class ServiceRegistry
  # Store a list of `{Component, ServiceRegistration*}` objects.
  _registrations: null

  _hub : null

  _listeners : null

  constructor: (hub) ->
    @_registrations = []
    @_listeners = []
    if not hub? then throw new Exception "Cannot initialize the service registry without a hub"
    @_hub = hub

  ###
  # Gets all registered services.
  # @return the list of service references, empty if no services are registered
  ###
  getRegisteredServices: ->
    result = []
    for entry in @_registrations
      for reg in entry.registrations
        result.push(reg.getReference())
    return result

  ###
  # Adds a service registration
  ###
  _addRegistration : (component, reg) ->
    cmpEntry = entry for entry in @_registrations when entry.component is component
    if not cmpEntry? then cmpEntry = {'component' : component, 'registrations' : []}; @_registrations.push(cmpEntry)
    cmpEntry.registrations.push(reg)

  _removeRegistration : (reg) ->
    cmpEntry = entry for entry in @_registrations when HUBU.UTILS.indexOf(entry.registrations, reg) isnt -1
    if not cmpEntry? then return null
    HUBU.UTILS.removeElementFromArray(cmpEntry.registrations, reg)
    if cmpEntry.registrations.length is 0
      HUBU.UTILS.removeElementFromArray(@_registrations, cmpEntry)
    return cmpEntry.component


  ###
  # Registers a service
  # @return the service registration
  ###
  registerService: (component, contract, properties, svcObject) ->
    if not contract? then throw new Exception "Cannot register a service without a proper contract"
    if not component? then throw new Exception "Cannot register a service without a valid component"

    svcObject = svcObject ? component
    if not HUBU.UTILS.isFunction(svcObject) and not HUBU.UTILS.isObjectConformToContract(svcObject, contract)
      throw new Exception("Cannot register service - the service object does not implement the contract")
          .add("contract", contract).add("component", component)

    svcObject = svcObject ? component

    reg = new ServiceRegistration(contract, component, svcObject, properties, @_hub, @)

    # We add the registration to the map
    @_addRegistration(component, reg)

    # Actual registration
    reg.register()

    # As the service is actually registered, we can fire the REGISTERED event
    @fireServiceEvent(new SOC.ServiceEvent(SOC.ServiceEvent.REGISTERED, reg.getReference()))

    return reg

  ###
  # Unregisters a service
  ###
  unregisterService: (registration) ->
    if not registration? then throw new Exception "Cannot unregister the service - invalid registration"
    component = @_removeRegistration(registration)
    if (component?)
        # Callback
        ref = registration.getReference()
        registration.unregister();
        @fireServiceEvent(new SOC.ServiceEvent(SOC.ServiceEvent.UNREGISTERING, ref))
        return true;
    # Not found
    throw new Exception "Cannot unregister service - registration not found"

  unregisterServices: (component) ->
    if not component? then throw new Exception "Cannot unregister the services - invalid component"
    cmpEntry = entry for entry in @_registrations when entry.component is component
    if cmpEntry?
      regs = cmpEntry.registrations
      if regs?
        for reg in regs
          @unregisterService(reg)
      HUBU.UTILS.removeElementFromArray(@_registrations, cmpEntry)
    # Else nothing to do.

  getServiceReferences : (contract, filter) ->
     return @_match(@_buildFilter(contract, filter))

  ###
  # Traverses the registered services to select the ones matching with the given filter (method)
  # It returns an empty array if ne matching service can be found
  ###
  _match : (filter) ->
    refs = @getRegisteredServices()
    matching = (ref for ref in refs when filter.match(ref))
    return matching

  ###
  # Build an object with a `match` function built from the contract and the filter.
  ###
  _buildFilter : (contract, filter) ->
    if not contract? and not filter?
      # Return all services, to achieve that define an `accept all` filter
      return {
        match : (ref) -> return true
      }
    else if contract? and not filter?
      # Contract only, create a filter checking the contract only
      container = {}
      container.contract = contract
      container.match = (ref) => return ref.getProperty("service.contract") is container.contract
      return container
    else if contract? and filter?
      # Both are not null, be create an uber-filter
      container = {}
      container.contract = contract
      container.filter = filter # We're changing this.... this may be a problem, if the method is accessing 'this'
      container.match = (ref) =>
        return (ref.getProperty("service.contract") is container.contract) and container.filter(ref)
      return container
    else
      return {
        filter : filter
        match : (ref) -> return @filter(ref)
      }

  getService : (component, ref) ->
    # component is given in order to implement the usage graph (later)
    if not ref? then throw new Exception("Cannot get service - the reference is null")

    if (not ref.isValid())
      HUBU.logger.warn("Cannot retrieve service for " + ref + " - the reference is invalid")
      return null

    return ref._registration.getService(component)

  ungetService : (component, ref) ->
    # nothing to do yet.

  registerServiceListener : (listenerConfig) ->
    {contract, filter, listener} = listenerConfig
    if not listener? then throw new Exception("Can't register the service listener, the listener is not set")
      .add("listenerConfig", listenerConfig)

    newFilter = @_buildFilter(contract, filter)
    svcListener = {
      listener : listener
      filter : newFilter
      contract: contract
    }

    # Listener can be either be a function or an object
    if HUBU.UTILS.isObject(listener)
      if not HUBU.UTILS.isObjectConformToContract(listener, SOC.ServiceListener)
        throw new Exception("Can't register the service listener, the listener is not conform to the Service Listener contract")

    @_listeners.push(svcListener)


  unregisterServiceListener : (listenerConfig) ->
    {contract, filter, listener} = listenerConfig
    if not listener? then throw new Exception("Can't unregister the service listener, the listener is not set")
      .add("listenerConfig", listenerConfig)

    for list in @_listeners.slice() when list.contract is contract and list.listener is listener
        #As we're removing the element within the loop, we create a copy of the array, that's why we `slice` it.
        HUBU.UTILS.removeElementFromArray(@_listeners, list) # We modify the original array.

  ###
  # This method should be used by the extension only.
  ###
  fireServiceEvent : (event, oldRef) ->
    for listener in @_listeners
      matched = not listener.filter? or @_testAgainstFilter(listener, event.getReference())
      if (matched)
        @_invokeServiceListener(listener, event)
      else if (event.getType() is SOC.ServiceEvent.MODIFIED and oldRef?)
        # We need to send a MODIFIED_ENDMATCH event if the listener matched previously
        if @_testAgainstFilter(listener, oldRef)
          newEvent = new SOC.ServiceEvent(SOC.ServiceEvent.MODIFIED_ENDMATCH, event.getReference())
          @_invokeServiceListener(listener, newEvent)
  # End fireServiceEvent

  _testAgainstFilter : (listener, ref) ->
      return listener.filter.match(ref)

  _invokeServiceListener : (listener, event) ->
    if HUBU.UTILS.isFunction(listener.listener)
      # Invoke the function on the component object
      listener.listener(event)
    else if HUBU.UTILS.isObject(listener.listener)
      # Invoke `serviceChanged` on the object.
      # The conformity was checked before
      listener.serviceChanged(event)

