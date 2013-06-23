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
# Hubu Service-Orientation Extension
###

###*
 The Service Component class
 @class HUBU.ServiceComponent
 @classdesc This class represents _Service Components_. Service Components are one of the main concept of h-ubu. It
represents the published and required services for a specific h-ubu's component.

  The constructor.
  Initializes the service component. By default, there are no service dependencies and no provided services.
 @param {HUBU.AbstractComponent} component the underlying component.
###
HUBU.ServiceComponent = class ServiceComponent
  ###*
  _STOPPED_ state.
  A stopped service component does not published any services, and required services are not tracked and injected.
  It's also the initial state of service components.
  @type {Number}
  @memberOf HUBU.ServiceComponent
  @name STOPPED
  ###
  @STOPPED : 0
  ###*
  _INVALID_ state.
  A service component is invalid if a mandatory service dependency is not resolved.
  An invalid service component does not publish its services but required services are tracked.
  Once started, service component are in this state.
  @type {Number}
  @memberOf HUBU.ServiceComponent
  @name INVALID
  ###
  @INVALID : 1
  ###*
  _VALID_ state.
  A service component is valid if all mandatory service dependencies are resolved.
  A valid service component publishes its services, required services are tracked and injected.
  The service component stays in this state as long as all mandatory services dependencies are resolved.
  @type {Number}
  @memberOf HUBU.ServiceComponent
  @name VALID
  ###
  @VALID : 2

  ###*
  The underlying component.
  @type {HUBU.AbstractComponent}
  @memberOf HUBU.ServiceComponent
  @name #_component
  @private
  ###
  _component : null

  ###*
  The provided services.
  @type {HUBU.ProvidedService}
  @memberOf HUBU.ServiceComponent
  @name #_providedServices
  @private
  ###
  _providedServices : null

  ###*
  The required services.
  @type {HUBU.ServiceDependency}
  @memberOf HUBU.ServiceComponent
  @name #_requiredServices
  @private
  ###
  _requiredServices : null

  ###*
  The current state of the service component.
  @type {Number}
  @memberOf HUBU.ServiceComponent
  @name #_state
  @private
  ###
  _state : 0

  constructor : (component) ->
    @_component = component
    @_providedServices = []
    @_requiredServices = []
    @_state = ServiceComponent.STOPPED

  ###*
  Gets the underlying components
  @method
  @memberOf HUBU.ServiceComponent
  @name #getComponent
  @returns {HUBU.AbstractComponent} the underlying component
  ###
  getComponent : ->
    return @_component

  ###*
  Gets the current state
  @method
  @memberOf HUBU.ServiceComponent
  @name #getState
  @returns {Number} the current state
  ###
  getState : ->
    return @_state

  ###*
  Adds a provided service.
  Dependending on the current state the provided service is started, validated or invalidated
  @method
  @memberOf HUBU.ServiceComponent
  @name #addProvidedService
  @param {HUBU.ProvidedService} ps the provided service to add.
  ###
  addProvidedService : (ps) ->
    if HUBU.UTILS.indexOf(@_providedServices, ps) is -1
      @_providedServices.push(ps)
      ps.setServiceComponent(this)
      ps.onStart() if @_state > ServiceComponent.STOPPED
      ps.onValidation() if @_state is ServiceComponent.VALID
      ps.onInvalidation() if @_state is ServiceComponent.INVALID

  ###*
  Removes a provided service. Does nothing if the provided service is not found. If found the provided service is stopped.
  @method
  @memberOf HUBU.ServiceComponent
  @name #removeProvidedService
  @param {HUBU.ProvidedService} ps the provided service to add.
  ###
  removeProvidedService : (ps) ->
    if HUBU.UTILS.indexOf(@_providedServices, ps) isnt -1
      HUBU.UTILS.removeElementFromArray(@_providedServices, ps)
      ps.onStop()

  ###*
  Adds a required service.
  Depending on the current state, the dependency is started.
  @method
  @memberOf HUBU.ServiceComponent
  @name #addRequireService
  @param {HUBU.ServiceDependency} req the service dependency to add
  ###
  addRequiredService : (req) ->
    if HUBU.UTILS.indexOf(@_requiredServices, req) is -1
      @_requiredServices.push(req)
      req.setServiceComponent(this)
      if @_state > ServiceComponent.STOPPED  then req.onStart(); @computeState()

  ###*
  Removes a service dependency.
  The dependency is stopped, the current state is recomputed.
  If the dependency is not found, this method does nothing.
  @method
  @memberOf HUBU.ServiceComponent
  @name #removeRequiredService
  @param {HUBU.ProvidedService} ps the provided service to add.
  ###
  removeRequiredService : (req) ->
    if (HUBU.UTILS.indexOf(@_requiredServices, req) > -1)
      HUBU.UTILS.removeElementFromArray(@_requiredServices, req)
      req.onStop()
      @computeState() if @_state > ServiceComponent.STOPPED

  ###*
  Computes the state of the current service component.
  The state is valid if and only if all mandatory required services are fulfilled.
  If there is a transition the _validate_ and _invalidate_ callbacks are called.
  @method
  @memberOf HUBU.ServiceComponent
  @name #computeState
  @returns {Number} the new state
  ###
  computeState : ->
    isValid = true
    for req in @_requiredServices
      isValid = isValid  and req.isValid()
    oldState = @_state
    @_state = if isValid then ServiceComponent.VALID else ServiceComponent.INVALID
    if (@_state > oldState  && @_state is ServiceComponent.VALID)
      @_validate()
    else if (@_state < oldState  && @_state is ServiceComponent.INVALID)
      @_invalidate()
    return @_state

  ###*
  Validates the service component.
  Invokes _onValidation_ on all provided service.
  @method
  @memberOf HUBU.ServiceComponent
  @name #_validate
  @private
  ###
  _validate : ->
    HUBU.logger.debug("Validate instance " + @_component?.getComponentName())
    for prov in @_providedServices
      prov.onValidation()

  ###*
  Invalidates the service component.
  Invokes _onInvalidation_ on all provided service.
  @method
  @memberOf HUBU.ServiceComponent
  @name #_invalidate
  @private
  ###
  _invalidate : ->
    HUBU.logger.debug("Invalidate instance")
    for prov in @_providedServices
      prov.onInvalidation()

  ###*
  Starting callback.
  @method
  @memberOf HUBU.ServiceComponent
  @name #onStart
  ###
  onStart : ->
    # Start the dependencies first
    req.onStart() for req in @_requiredServices
    prov.onStart() for prov in @_providedServices
    @computeState()

  ###*
  Stopping callback.
  @method
  @memberOf HUBU.ServiceComponent
  @name #onStop
  ###
  onStop : ->
    prov.onStop() for prov in @_providedServices
    req.onStop() for req in @_requiredServices
    @_state = ServiceComponent.STOPPED

  ###*
  Gets a service dependency by name
  @method
  @memberOf HUBU.ServiceComponent
  @name #getServiceDependencyByName
  @param {String} name the dependency
  @return {HUBU.ServiceDependency} the service dependency, `null` if no service dependencies match the name
  ###
  getServiceDependencyByName : (name) ->
    return dep for dep in @_requiredServices when dep.getName() is name


HUBU.ServiceDependency = class ServiceDependency
  @UNRESOLVED = 0
  @RESOLVED = 1

  _component : null

  _contract : null
  _filter : null
  _aggregate : false
  _optional : false
  _field : null
  _bind : null
  _unbind : null
  _name : null


  _hub : null

  _listener = null
  _state = null

  _refs = []

  _serviceComponent = null

  constructor: (component, contract, filter, aggregate, optional, field, bind, unbind, name, hub) ->
    @_component = component
    @_contract = contract
    @_filter = filter
    @_aggregate = aggregate
    @_optional = optional

    @_field = field

    @_name = name ? @_contract

    if bind?
      @_bind = if HUBU.UTILS.isFunction(bind) then bind else @_component[bind]
      if not @_bind? then throw new Exception("Bind method " + bind + " not found on component")

    if unbind?
      @_unbind = if HUBU.UTILS.isFunction(unbind) then unbind else @_component[unbind]
      if not @_unbind? then throw new Exception("Unbind method " + unbind + " not found on component")

    @_hub = hub
    @_state = HUBU.ServiceDependency.UNRESOLVED
    @_refs = []
    self = this
    @_listener = {
      contract: @_contract,
      filter : (ref) -> ref.getProperty("service.publisher") isnt self._component and (not self._filter? or self._filter(ref))
      listener : (event) ->
        switch event.getType()
          when SOC.ServiceEvent.REGISTERED then self._onServiceArrival(event.getReference())
          when SOC.ServiceEvent.MODIFIED then self._onServiceModified(event.getReference())
          when SOC.ServiceEvent.UNREGISTERING then self._onServiceDeparture(event.getReference())
          when SOC.ServiceEvent.MODIFIED_ENDMATCH then self._onServiceDeparture(event.getReference())
    }
  ### End Constructor ###

  setServiceComponent : (sc) -> @_serviceComponent = sc

  onStart : ->
    @_state = HUBU.ServiceDependency.UNRESOLVED
    @_startTracking()
    @_computeDependencyState()

  onStop : ->
    @_stopTracking()
    @_ungetAllServices()
    @_refs = []
    @_state = HUBU.ServiceDependency.UNRESOLVED

  _ungetAllServices : ->
    for entry in @_refs when entry.service?
      entry.service = null
      @_hub.ungetService(@_component, entry.reference)

  _startTracking : ->
    # Register service listener
    @_hub.registerServiceListener(@_listener)
    # Immediate / Defensive get
    refs = @_hub.getServiceReferences(@_contract, @_filter)
    @_onServiceArrival ref for ref in refs

  _stopTracking : ->
    # Remove listeners
    @_hub.unregisterServiceListener(@_listener)

  isValid : -> return @_state is HUBU.ServiceDependency.RESOLVED

  getName : -> return @_name

  getContract : -> return @_contract

  getFilter : -> return @_filter

  isAggregate : -> return @_aggregate

  isOptional : -> return @_optional

  _computeDependencyState : ->
     oldState = @_state
     if @_optional or @_refs.length > 0
        @_state = HUBU.ServiceDependency.RESOLVED
     else
       @_state = HUBU.ServiceDependency.UNRESOLVED
     @_serviceComponent.computeState() if oldState isnt @_state

  _onServiceArrival : (ref) ->
    HUBU.logger.debug("Service arrival detected for " + @_component.getComponentName());
    # Do we already have this reference
    refEntry = entry for entry in @_refs when entry.reference is ref
    if not refEntry?
      refEntry = {
        reference: ref,
        service: null
      }
      @_refs.push(refEntry)

      @_computeDependencyState()
      if @_aggregate
        @_inject(refEntry)
      else
        @_inject(refEntry) if @_refs.length is 1

  _onServiceDeparture : (ref) ->
    HUBU.logger.debug("Service departure detected for " + @_component.getComponentName());
    # Do we already have this reference
    refEntry = entry for entry in @_refs when entry.reference is ref
    if refEntry?
      HUBU.UTILS.removeElementFromArray(@_refs, refEntry)
      if refEntry.service? # Used service
        @_deinject(refEntry)
        @_hub.ungetService(@_component, ref)
        refEntry.service = null

      # Do we have another reference
      if (@_refs.length > 0)
        newRef = @_refs[0]
        # Inject the reference on non aggregated dependencies
        @_inject newRef if not @_aggregate
      else
        # No ref... we may be UNRESOLVED.
        @_computeDependencyState()

  _onServiceModified : (ref) ->
    # A service was modified, we now that we're matching. So, either we already have the ref, in that case we do nothing
    # or it's a new service, and we consider it as an arrival
    refEntry = entry for entry in @_refs when entry.reference is ref
    if not refEntry?
      @_onServiceArrival(ref)

  _inject : (entry) ->
    # Get the service
    svc = @_hub.getService(@_serviceComponent, entry.reference)
    entry.service = svc

    # Field injection first
    if @_field?  and @_aggregate
        if not @_component[@_field]? then @_component[@_field] = [svc] else @_component[@_field].push(svc)
    if @_field? and not @_aggregate then @_component[@_field] = svc

    # Bind
    if @_bind? then @_bind.apply(@_component, [svc, entry.reference])

  _deinject : (entry) ->
    if @_field?  and @_aggregate
      HUBU.UTILS.removeElementFromArray(@_component[@_field], entry.service)
    if @_field? and not @_aggregate then @_component[@_field] = null

    # Unbind
    if @_unbind? then @_unbind.apply(@_component, [entry.service, entry.reference])

  ###*
  Gets the current service object(s).
  This method returns an array of service objects.
  @method
  @memberOf HUBU.ServiceComponent
  @name #locateServices
  @returns {Array} The array of service objects. Contains only one element for scalar dependencies.
  ###
  locateServices : ->
    svc = []
    refs = @_hub.getServiceReferences(@_contract, @_filter)
    for ref in refs
      svc.push(@_hub.getService(@_component, ref))
    return svc


HUBU.ProvidedService = class ProvidedService
  @UNREGISTERED : 0
  @REGISTERED : 1

  _hub : null
  _contract : null
  _properties : null

  _registration : null
  _serviceComponent : null
  _component : null

  _preRegistration : null
  _postRegistration : null
  _preUnregistration : null
  _postUnRegistration : null

  constructor : (component, contract, properties, preRegistration, postRegistration, preUnregistration, postUnregistration, hub) ->
    @_component = component
    @_contract = contract
    @_hub = hub
    @_properties = properties

    if preRegistration?
      @_preRegistration = if HUBU.UTILS.isFunction(preRegistration) then preRegistration else @_component[preRegistration]
      if not @_preRegistration? then throw new Exception("preRegistration method " + preRegistration + " not found on component")

    if postRegistration?
      @_postRegistration = if HUBU.UTILS.isFunction(postRegistration) then postRegistration else @_component[postRegistration]
      if not @_postRegistration? then throw new Exception("postRegistration method " + postRegistration + " not found on component")

    if preUnregistration?
      @_preUnregistration = if HUBU.UTILS.isFunction(preUnregistration) then preUnregistration else @_component[preUnregistration]
      if not @_preUnregistration? then throw new Exception("preUnregistration method " + preUnregistration + " not found on component")

    if postUnregistration?
      @_postUnRegistration = if HUBU.UTILS.isFunction(postUnregistration) then postUnregistration else @_component[postUnregistration]
      if not @_postUnRegistration? then throw new Exception("postUnregistration method " + postUnregistration + " not found on component")

  setServiceComponent : (sc) -> @_serviceComponent = sc

  _register : ->
    # Already registered
    if @_registration? then return false

    if (@_preRegistration?) then @_preRegistration.apply(@_component, [])
    proxy = HUBU.UTILS.createProxyForContract(@_contract, @_component)
    @_registration = @_hub.registerService(@_component, @_contract, @_properties, proxy)
    HUBU.logger.debug("Service from " + @_component.getComponentName() + " registered");
    if (@_postRegistration?) then @_postRegistration.apply(@_component, [@_registration])

    return true

  _unregister : ->
    if not @_registration? then return false

    if @_preUnregistration? then @_preUnregistration.apply(@_component, [@_registration])

    @_hub.unregisterService(@_registration)
    @_registration = null

    if @_postUnRegistration? then @_postUnRegistration.apply(@_component, [])

  onStart : ->
    # Do nothing.

  onStop : ->
    @_unregister()

  onValidation : -> @_register()

  onInvalidation : -> @_unregister()

###*
@class
@classdesc The service oriented extension. This extension handles service components, so manage provided and required services.
@param {HUBU.Hub} the hub
###
HUBU.ServiceOrientation = class ServiceOrientation

  ###*
  The hub
  @private
  @name HUBU.ServiceOrientation#_hub
  @type {HUBU.Hub}
  ###
  _hub : null

  ###*
  The service registry
  @private
  @name HUBU.ServiceOrientation#_registry
  @type SOC.ServiceRegistry
  ###
  _registry : null

  ###*
  An array of { component -> service component }.
  To keep things simple, a component can have only one service component
  @type {Array}
  @private
  @name HUBU.ServiceOrientation#_components
  ###
  _components : []

  constructor : (hubu) ->
    @_hub  = hubu
    @_registry = new SOC.ServiceRegistry(@_hub)
    @_components = []
    registry = @_registry # Just created a variable put in the closure of the hub function.
    self = this

    # Populate the hub object

    ###*
    Gets the service registry of the hub.
    @method
    @name HUBU.Hub#getServiceRegistry
    @return {SOC.ServiceRegistry} the service registry
    ###
    @_hub.getServiceRegistry = -> return registry

    ###*
    Registers a service in the hub's service registry.
    @method
    @name HUBU.Hub#registerService
    @param {HUBU.AbstractComponent} component the component registering the service
    @param {Object} contract the published contract
    @param {Object} properties the service properties (optional)
    @param {Object} svcObject either the service object, or the contruction method
    @return {SOC.ServiceRegistration} the service registration
    ###
    @_hub.registerService = (component, contract, properties, svcObject) -> return registry.registerService(component, contract, properties, svcObject)

    ###*
    Unregisters a service.
    @method
    @name HUBU.Hub#unregisterService
    @param {SOC.ServiceRegistration} registration the service registration of the service to unpublish.
    ###
    @_hub.unregisterService = (registration) -> return registry.unregisterService(registration)

    ###*
    Looks for service references
    @method
    @name HUBU.Hub#getServiceReferences
    @param {Object} contract the service contract
    @param {Function} filter the filter method that the provider must match
    @return {Array} an array of all matching service references, empty if no services match
    ###
    @_hub.getServiceReferences = (contract, filter) -> return registry.getServiceReferences(contract, filter)

    ###*
    Looks for a service reference
    @method
    @name HUBU.Hub#getServiceReference
    @param {Object} contract the service contract
    @param {Function} filter the filter method that the provider must match
    @return {SOC.ServiceReference} a matching service reference or `null` if no services match
    ###
    @_hub.getServiceReference = (contract, filter) ->
      refs = registry.getServiceReferences(contract, filter)
      if refs.length isnt 0 then return refs[0]
      return null

    ###*
    Gets the service object of the given service reference.
    @method
    @name HUBU.Hub#getService
    @param {HUBU.AbstractComponent} component the component getting the service
    @param {SOC.ServiceReference} reference the service reference
    @return {Object} the service object
    ###
    @_hub.getService = (component, reference) -> return registry.getService(component, reference)

    ###*
    Releases an used service.
    @method
    @name HUBU.Hub#ungetService
    @param {HUBU.AbstractComponent} component the component that got the service
    @param {SOC.ServiceReference} reference the service reference
    ###
    @_hub.ungetService = (component, reference) -> return registry.ungetService(component, reference)

    ###*
    Registers a service listener on the service registry of the hub.
    The parameter specifies the _listener_. This parameter must contain a key `listener`  with a function as value.
    This function receives a `SOC.ServiceEvent`. The listener is called everytime a matching service event is fired.
    the parameter must also contain the `contract` specifying the targeted service contract and/or a `filter`, i.e. a
    method validating a service reference (given as parameter). For example, the following snippet illustrates a valid
    service listener registrations:

      var listenAllContractService = {
            bindCount: 0,
            unbindCount : 0,
            contract : contract,
            // no filter
            listener : function(event) {
                if (event.getType() === SOC.ServiceEvent.REGISTERED) {
                    listenAllContractService.bindCount = listenAllContractService.bindCount +1;
                } else if (event.getType() === SOC.ServiceEvent.UNREGISTERING) {
                    listenAllContractService.unbindCount = listenAllContractService.unbindCount +1;
                }
            }
        };

        var listenFrContractService = {
            bindCount: 0,
            unbindCount : 0,
            contract : contract,
            filter : function(ref) {
                return ref.getProperty("lg") === "fr";
            },
            listener : function(event) {
                if (event.getType() === SOC.ServiceEvent.REGISTERED) {
                    listenFrContractService.bindCount = listenFrContractService.bindCount +1;
                } else if (event.getType() === SOC.ServiceEvent.UNREGISTERING) {
                    listenFrContractService.unbindCount = listenFrContractService.unbindCount +1;
                }
            }
        };

        hub.registerServiceListener(listenAllContractService);
        hub.registerServiceListener(listenFrContractService);

    @method
    @name HUBU.Hub#registerServiceListener
    @param {Object} listenerConfiguration the listener configuration.

    ###
    @_hub.registerServiceListener = (listenerConfiguration) -> return registry.registerServiceListener(listenerConfiguration)

    ###*
    Unregisters a service listener.
    @method
    @name HUBU.Hub#unregisterServiceListener
    @param {Object} listenerConfiguration The service listener to unregister.
    ###
    @_hub.unregisterServiceListener = (listenerConfiguration) -> return registry.unregisterServiceListener(listenerConfiguration)

    # Service-oriented component model methods

    ###*
    Defines a service dependency. This method is used to declare a service dependency injected automatically within the
    component. Please refer to the documentation.
    @method
    @name HUBU.Hub#requireService
    @param {Object} the service dependency description.
    @return {HUBU.Hub} the current hub
    ###
    @_hub.requireService = (description) ->
      self.requireService(description);
      return this

    ###*
    Defines a provided service. The service is managed by h-ubu. Please refer to the documentation
    @method
    @name HUBU.Hub#provideService
    @param {Object} the provided service description.
    @return {HUBU.Hub} the current hub
    ###
    @_hub.provideService = (description) ->
      self.provideService(description);
      return this

    ###*
    Locates a service dependency. This method returns only the first service object on aggregate dependencies.
    @method
    @name HUBU.Hub#locateService
    @param {HUBU.AbstractComponent} component the component holding the dependency.
    @param {String} name the dependency name, or the contract is the name was omitted in the service dependency.
    @return {Object} the service object, `null` if there are no service provider.
    ###
    @_hub.locateService = (component, name) ->
      cmpEntry = entry for entry in self._components when entry.component is component
      if ! cmpEntry? then return null
      dep = cmpEntry.serviceComponent.getServiceDependencyByName(name)
      if ! dep? then throw new Exception("No dependency " + name + " on component " + cmpEntry.component.getComponentName());
      svc = dep.locateServices()
      if svc == null  || svc.length == 0 then return null
      return svc[0]

    ###*
    Locates a service dependency. This method returns all service object on aggregate dependencies, but an array of one
    element on scalar dependencies.
    @method
    @name HUBU.Hub#locateServices
    @param {HUBU.AbstractComponent} component the component holding the dependency.
    @param {String} name the dependency name, or the contract is the name was omitted in the service dependency.
    @return {Array} the service objects, empty if there are no service provider, with only one element on fulfilled scalar
    service dependencies.
    ###
    @_hub.locateServices = (component, name) ->
      cmpEntry = entry for entry in self._components when entry.component is component
      if ! cmpEntry? then return null
      dep = cmpEntry.serviceComponent.getServiceDependencyByName(name)
      if ! dep? then throw new Exception("No dependency " + name + " on component " + cmpEntry.component.getComponentName());
      svc = dep.locateServices()
      if svc == null  || svc.length == 0 then return []
      return svc

  ### End of constructor  ###

  ###
  # The given component is unregistered from the hub. We needs to unregisters all services.
  ###
  unregisterComponent : (cmp) ->
    # We must start by the service components, as they may unregister the service themselves
    # and do some cleanup.
    # Stops all service components
    #TODO Why do we have to check for null here... Looks suspicious
    for entry in @_components when entry? && entry.component is cmp
      entry.serviceComponent.onStop()
      HUBU.UTILS.removeElementFromArray(@_components, entry)
    # Basics management
    @_registry.unregisterServices(cmp)


  requireService : (description) ->
    {component, contract, filter, aggregate, optional, field, bind, unbind, name} = description
    if not component? then throw new Exception("Cannot require a service without a valid component")
    aggregate = false unless aggregate?
    optional = false unless optional?
    contract = null unless contract?
    filter = null unless filter?
    if not field? and not bind? and not name? then throw new Exception("Cannot require a service - field or bind must be set")
    field = null unless field?
    bind = null unless bind?
    unbind = null unless unbind?
    name = contract unless name?

    if not field? and not bind? then optional = true


    req = new HUBU.ServiceDependency(component, contract, filter, aggregate, optional, field, bind, unbind, name, @_hub)
    @_addServiceDependencyToComponent(component, req)

  provideService : (description) ->
    {component, contract, properties, preRegistration, postRegistration, preUnregistration, postUnregistration} = description
    if not component? then throw new Exception("Cannot provided a service without a valid component")
    if not contract? then throw new Exception("Cannot provided a service without a valid contract")


    properties = {} unless properties?
    ps = new HUBU.ProvidedService(component, contract, properties, preRegistration, postRegistration, preUnregistration, postUnregistration, @_hub)
    @_addProvidedServiceToComponent(component, ps)



  _addServiceDependencyToComponent : (comp, req) ->
    newComponent = false
    cmpEntry = entry for entry in @_components when entry.component is comp
    if not cmpEntry?
      cmpEntry = {'component' : comp, 'serviceComponent' : new HUBU.ServiceComponent(comp)}
      @_components.push(cmpEntry)
      newComponent = true
    cmpEntry.serviceComponent.addRequiredService(req)
    if newComponent and @_hub.isStarted() then cmpEntry.serviceComponent.onStart()

  _addProvidedServiceToComponent : (comp, ps) ->
    newComponent = false
    cmpEntry = entry for entry in @_components when entry.component is comp
    if not cmpEntry?
      cmpEntry = {'component' : comp, 'serviceComponent' : new HUBU.ServiceComponent(comp)}
      @_components.push(cmpEntry)
      newComponent = true
    cmpEntry.serviceComponent.addProvidedService(ps)
    if @_hub.isStarted() and newComponent
      cmpEntry.serviceComponent.onStart()

  start : ->
    # Starts all service component
    entry.serviceComponent.onStart() for entry in @_components

  stop : ->
    # Stops all service component
    entry.serviceComponent.onStop() for entry in @_components



### End of the Service Orientation Extension class  ###

# Declare the extension
getHubuExtensions().service =  ServiceOrientation
