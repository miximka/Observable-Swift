//
//  EventReference.swift
//  Observable-Swift
//
//  Created by Leszek Ślażyński on 23/06/14.
//  Copyright (c) 2014 Leszek Ślażyński. All rights reserved.
//

/// A class enclosing an Event struct. Thus exposing it as a reference type.
public class EventReference<T>: OwnableEvent {
    public typealias ValueType = T
    public typealias SubscriptionType = EventSubscription<T>
    public typealias HandlerType = EventSubscription<T>.HandlerType
    
    internal var event: Event<T>
    
    public func notify(_ value: T) {
        event.notify(value)
    }
    
    public func add(_ subscription: SubscriptionType) -> SubscriptionType {
        return event.add(subscription)
    }
    
    public func add(_ handler : (T) -> ()) -> EventSubscription<T> {
        return event.add(handler)
    }
    
    public func remove(_ subscription : SubscriptionType) {
        return event.remove(subscription)
    }
    
    public func removeAll() {
        event.removeAll()
    }
    
    public func add(owner : AnyObject, _ handler : HandlerType) -> SubscriptionType {
        return event.add(owner: owner, handler)
    }
    
    public convenience init() {
        self.init(event: Event<T>())
    }
    
    public init(event: Event<T>) {
        self.event = event
    }
    
}
