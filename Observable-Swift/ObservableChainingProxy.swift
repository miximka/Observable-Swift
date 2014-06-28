//
//  Chaining.swift
//  Observable-Swift
//
//  Created by Leszek Ślażyński on 23/06/14.
//  Copyright (c) 2014 Leszek Ślażyński. All rights reserved.
//

class ObservableChainingProxy<O1: AnyObservable, O2: AnyObservable>: OwnableObservable {
    
    typealias ValueType = O2.ValueType?
    
    var value : ValueType { get { return nil } }
    
    func ownableSelf() -> AnyObject {
        return self;
    }
    
    @conversion func __conversion () -> ValueType {
        return nil
    }
    
    var _beforeChange : () -> EventReference<ValueChange<ValueType>>? = { nil }
    var _afterChange : () -> EventReference<ValueChange<ValueType>>? = { nil }
    
    var beforeChange : EventReference<ValueChange<ValueType>> {
        if let event = _beforeChange() {
            return event
        } else {
            let event = OwningEventReference<ValueChange<ValueType>>()
            event.owned = { self }
            _beforeChange = { [weak event] in event }
            return event
        }
    }
    
    var afterChange : EventReference<ValueChange<ValueType>> {
        if let event = _afterChange() {
            return event
        } else {
            let event = OwningEventReference<ValueChange<ValueType>>()
            event.owned = { self }
            _afterChange = { [weak event] in event }
            return event
        }
    }
    
    let _base: () -> O1

    init(base: O1, path: O1.ValueType -> O2?) {
        _base = { base }

        func targetChangeToValueChange(vc: ValueChange<O2.ValueType>) -> ValueChange<ValueType> {
            let oldValue = Optional.Some(vc.oldValue)
            let newValue = Optional.Some(vc.newValue)
            return ValueChange(oldValue, newValue)
        }
        
        func objectChangeToValueChange(oc: ValueChange<O1.ValueType>) -> ValueChange<ValueType> {
            let oldValue = path(oc.oldValue)?.value
            let newValue = path(oc.newValue)?.value
            return ValueChange(oldValue, newValue)
        }
        
        var beforeSubscription = EventSubscription(owner: self) { [weak self] in
            self!.beforeChange.notify(targetChangeToValueChange($0))
        }
        
        var afterSubscription = EventSubscription(owner: self) { [weak self] in
            self!.afterChange.notify(targetChangeToValueChange($0))
        }
        
        base.beforeChange.add(owner: self) { [weak self] oc in
            let oldTarget = path(oc.oldValue)
            oldTarget?.beforeChange.remove(beforeSubscription)
            oldTarget?.afterChange.remove(afterSubscription)
            self!.beforeChange.notify(objectChangeToValueChange(oc))
        }
        
        base.afterChange.add(owner: self) { [weak self] oc in
            self!.afterChange.notify(objectChangeToValueChange(oc))
            let newTarget = path(oc.newValue)
            newTarget?.beforeChange.add(beforeSubscription)
            newTarget?.afterChange.add(afterSubscription)
        }
    }
    
    func to<O3: AnyObservable>(path f: O2.ValueType -> O3?) -> ObservableChainingProxy<ObservableChainingProxy<O1, O2>, O3> {
        func cascadeNil(oOrNil: ValueType) -> O3? {
            if let o = oOrNil {
                return f(o)
            } else {
                return nil
            }
        }
        return ObservableChainingProxy<ObservableChainingProxy<O1, O2>, O3>(base: self, path: cascadeNil)
    }
    
    func to<O3: AnyObservable>(path f: O2.ValueType -> O3) -> ObservableChainingProxy<ObservableChainingProxy<O1, O2>, O3> {
        func cascadeNil(oOrNil: ValueType) -> O3? {
            if let o = oOrNil {
                return f(o)
            } else {
                return nil
            }
        }
        return ObservableChainingProxy<ObservableChainingProxy<O1, O2>, O3>(base: self, path: cascadeNil)
    }
    
}

struct ObservableChainingBase<O1: AnyObservable> {
    let base: O1
    func to<O2: AnyObservable>(path: O1.ValueType -> O2?) -> ObservableChainingProxy<O1, O2> {
        return ObservableChainingProxy(base: base, path: path)
    }
    func to<O2: AnyObservable>(path: O1.ValueType -> O2) -> ObservableChainingProxy<O1, O2> {
        return ObservableChainingProxy(base: base, path: { .Some(path($0)) })
    }
}

func chain<O: AnyObservable>(o: O) -> ObservableChainingBase<O> {
    return ObservableChainingBase(base: o)
}

@infix func / <O1: AnyObservable, O2: AnyObservable, O3: AnyObservable> (o: ObservableChainingProxy<O1, O2>, f: O2.ValueType -> O3?) -> ObservableChainingProxy<ObservableChainingProxy<O1, O2>, O3> {
    return o.to(f)
}


@infix func / <O1: AnyObservable, O2: AnyObservable> (o: O1, f: O1.ValueType -> O2?) -> ObservableChainingProxy<O1, O2> {
    return ObservableChainingProxy(base: o, path: f)
}
