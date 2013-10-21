/*
 * Copyright 2013 OW2 Nanoko Project
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

describe("H-UBU Service Extension Tests - Provided Services", function () {

    afterEach(function () {
        hub.reset();
    });

    it("should support adding provided services", function() {
        var contract = {
            doSomething : function() {}
        };

        var component = {
            hub : null,
            configure : function(hub) {
                this.hub = hub;
                this.hub.provideService({
                    component : this,
                    contract: contract
                });
            },
            start : function() {},
            stop : function() {},
            getComponentName : function() { return "my-component"},
            doSomething : function() {
                return "hello";
            }
        };

        hub.registerComponent(component).start();
        expect(hub.getServiceReferences(contract).length).toBe(1);
        hub.unregisterComponent(component);
        expect(hub.getServiceReferences(contract).length).toBe(0);

    });

    it("should support providing two services", function() {
        var contractA = {
            doSomethingA : function() {}
        };

        var contractB = {
            doSomethingB : function() {}
        };

        var component = {
            hub : null,
            configure : function(hub) {
                this.hub = hub;
                this.hub.provideService({
                    component : this,
                    contract: contractA
                });
                this.hub.provideService({
                    component : this,
                    contract: contractB
                });
            },
            start : function() {},
            stop : function() {},
            getComponentName : function() { return "my-component"},
            doSomethingA : function() {
                return "hello A";
            },
            doSomethingB : function() {
                return "hello B";
            }
        };

        hub.registerComponent(component).start();
        expect(hub.getServiceReferences(contractA).length).toBe(1);
        expect(hub.getServiceReferences(contractB).length).toBe(1);

        waitsFor(function() {
            return  hub.getServiceReference(contractA) !== null &&
                hub.getServiceReference(contractB) !== null;
        }, "Service lookup never completed", 10000);

        runs(function(){
            var refA = hub.getServiceReference(contractA);
            var refB = hub.getServiceReference(contractB);
            expect(refA).toBeTruthy();
            expect(refB).toBeTruthy();

            expect(hub.getService(hub,refA).doSomethingA()).toBe("hello A");
            expect(hub.getService(hub,refB).doSomethingB()).toBe("hello B");

            hub.unregisterComponent(component);
            expect(hub.getServiceReferences(contractA).length).toBe(0);
            expect(hub.getServiceReferences(contractB).length).toBe(0);
        });
    });

    it("should support providing two services whom share common methods", function() {
        var contractA = {
            doCommon : function() {}
        };

        var contractB = {
            doSomethingB : function() {},
            doCommon : function() {}
        };

        var component = {
            hub : null,
            configure : function(hub) {
                this.hub = hub;
                this.hub.provideService({
                    component : this,
                    contract: contractA
                });
                this.hub.provideService({
                    component : this,
                    contract: contractB
                });
            },
            start : function() {},
            stop : function() {},
            getComponentName : function() { return "my-component"},
            doSomethingB : function() {
                return "hello B";
            },
            doCommon : function() {
                return true;
            }

        };

        hub.registerComponent(component).start();
        expect(hub.getServiceReferences(contractA).length).toBe(1);
        expect(hub.getServiceReferences(contractB).length).toBe(1);

        waitsFor(function() {
            return  hub.getServiceReference(contractA) !== null &&
                hub.getServiceReference(contractB) !== null;
        }, "Service lookup never completed", 10000);

        runs(function(){
            var refA = hub.getServiceReference(contractA);
            var refB = hub.getServiceReference(contractB);
            expect(refA).toBeTruthy();
            expect(refB).toBeTruthy();

            expect(hub.getService(hub,refB).doCommon()).toBe(true);
            expect(hub.getService(hub,refA).doCommon()).toBe(true);
            expect(hub.getService(hub,refB).doSomethingB()).toBe("hello B");

            hub.unregisterComponent(component);
            expect(hub.getServiceReferences(contractA).length).toBe(0);
            expect(hub.getServiceReferences(contractB).length).toBe(0);
        });
    });

    it("should support adding provided services with properties", function() {
        var contract = {
            doSomething : function() {}
        };

        var component = {
            hub : null,
            configure : function(hub) {
                this.hub = hub;
                this.hub.provideService({
                    component : this,
                    contract: contract,
                    properties : {
                        "lg" : "en"
                    }
                });
            },
            start : function() {},
            stop : function() {},
            getComponentName : function() { return "my-component"},
            doSomething : function() {
                return "hello";
            }
        };

        hub.registerComponent(component).start();
        expect(hub.getServiceReferences(contract,
            function(ref) { return "en" === ref.getProperty("lg")}).length).toBe(1);
        hub.unregisterComponent(component);
        expect(hub.getServiceReferences(contract).length).toBe(0);

    });

    it("should support providing two services whom share common properties reference", function() {
        var props = {"toto" : true };

        var contractA = {
            doCommon : function() {}
        };

        var contractB = {
            doSomethingB : function() {},
            doCommon : function() {}
        };

        var component = {
            hub : null,
            configure : function(hub) {
                this.hub = hub;
                this.hub.provideService({
                    component : this,
                    contract: contractA,
                    properties: props
                });
                this.hub.provideService({
                    component : this,
                    contract: contractB,
                    properties: props
                });
            },
            start : function() {},
            stop : function() {},
            getComponentName : function() { return "my-component"},
            doSomethingB : function() {
                return "hello B";
            },
            doCommon : function() {
                return true;
            }
        };

        hub.registerComponent(component).start();
        expect(hub.getServiceReferences(contractA).length).toBe(1);
        expect(hub.getServiceReferences(contractB).length).toBe(1);
    });

    it("should not let access members not from the contract", function() {
        var contract = {
            doSomething : function() {}
        };

        var component = {
            hub : null,
            configure : function(hub) {
                this.hub = hub;
                this.hub.provideService({
                    component : this,
                    contract: contract,
                    properties : {
                        "lg" : "en"
                    }
                });
            },
            start : function() {},
            stop : function() {},
            getComponentName : function() { return "my-component"},
            doSomething : function() {
                return "hello";
            }
        };

        hub.registerComponent(component).start();
        var ref = hub.getServiceReference(contract);
        var svc = hub.getService(component, ref);

        expect(svc.doSomething()).toBe("hello");
        expect(svc.start).toBeUndefined();

        hub.unregisterComponent(component);
        expect(hub.getServiceReferences(contract).length).toBe(0);
    });

    it("should support the registration callbacks", function() {
        var contract = {
            doSomething : function() {}
        };

        var component = {
            hub : null,
            preRegCount : 0,
            postRegCount : 0,
            preUnRegCount : 0,
            postUnRegCount : 0,
            postRegRef : null,
            preUnRegRef : null,

            configure : function(hub) {
                this.hub = hub;
                this.hub.provideService({
                    component : this,
                    contract: contract,
                    preRegistration: this.preRegistration,
                    postRegistration: this.postRegistration,
                    preUnregistration: this.preUnregistration,
                    postUnregistration: this.postUnregistration
                });
            },
            start : function() {},
            stop : function() {},
            getComponentName : function() { return "my-component"},
            doSomething : function() {
                return "hello";
            },
            preRegistration : function() {
                this.preRegCount++;
            },
            postRegistration : function(ref) {
                this.postRegCount++;
                this.postRegRef = ref;
            },
            preUnregistration : function(ref) {
                this.preUnRegCount++;
                this.preUnRegRef = ref;
            },
            postUnregistration : function() {
                this.postUnRegCount++;
            }
        };

        hub.registerComponent(component).start();
        var ref = hub.getServiceReference(contract);
        var svc = hub.getService(component, ref);

        expect(svc.doSomething()).toBe("hello");
        expect(svc.postRegistration).toBeUndefined();

        // Check callbacks
        expect(component.preRegCount).toBe(1);
        expect(component.postRegCount).toBe(1);
        expect(component.postRegRef === null).toBe(false);

        hub.unregisterComponent(component);

        expect(component.preUnRegCount).toBe(1);
        expect(component.postUnRegCount).toBe(1);
        expect(component.preUnRegRef === null).toBe(false);

        expect(hub.getServiceReferences(contract).length).toBe(0);
    });


});