//
//  Epidemic.swift
//  AlleyOop
//
//  Created by Corey Baker on 7/1/15.
//  Copyright (c) 2015 One Degree Technologies LLC. All rights reserved.
//
import Foundation


public class Epidemic: RoutingProtocolDelegate {
    
    public var routingProtocolManager: RoutingProtocol!
    fileprivate lazy var nameOfRoutingProtocol :String = {
        let description = Epidemic.getDescriptionInformation()
        return description[kSOSRoutingProtocolTypeKey]!
    }()
    
    public init(nameOfMyAppService: String, myAppReverseDomainName: String, myObjectId: String, myInstallationId: String, myKeyType: KeyType, myKeyBitSize: Int, mySignType: SignType, classToBecomeDelegateOfSOSMiddleware: SOSMiddlewareDelegate) {
        
        //Map types into types that SOSMiddleware understands
        let myKeyAlgorithm = SOSMiddlewareUtility.mapKeyAlgorithmType(myKeyType, mySignType)
       
        
        //Required, DO NOT CHANGE THE TWO LINES BELOW
        self.routingProtocolManager = RoutingProtocol(nameOfMyAppService: nameOfMyAppService, myAppReverseDomainName: myAppReverseDomainName, nameOfRoutingProtocol: nameOfRoutingProtocol, myObjectId: myObjectId, myInstallationId: myInstallationId, myKeyAlgorithm: myKeyAlgorithm, myKeyBitSize: myKeyBitSize, classToBecomeDelegateOfSOSMiddleware: classToBecomeDelegateOfSOSMiddleware)
        self.routingProtocolManager.delegate = self
    }
    
    //Public description of routing protocol
    public class func getDescriptionInformation()->[String:String] {
        let routingDescriptionObject = [
            kSOSRoutingProtocolNameKey : "Epidemic",
            kSOSRoutingProtocolTypeKey : RoutingType.Epidemic.rawValue,
            kSOSRoutingProtocolDescriptionKey : "Every user you come in contact with will become a message forwarder"
        ]
        return routingDescriptionObject
    }
    
    
    // MARK: RoutingProtocol delegate methods implementation
    
    func nodesImSubscribedToHasBeenUpdated(_ nodesImSubscribedTo: [String : String]?) {
        //Do nothing, epidemic routing doesn't depend on who you are subscribed to
    }
    
    //**** NOTE routing occurs here. Determining how to connect to a peer based on routing information*/
    func discoveredNewPeerInSurroundings(_ peerID: String, peersAdvertisingDict:[String: String]?) {
        
        var sendToPeerInformationImInterestedIn:[String:String]?
        var localInformationImInterestedIn:[String:String]?
        
        //Check user list to see if there is any new information we are interested in
        guard let peersAdvertisingInfo = peersAdvertisingDict else{
            return
        }
        
        for (objectId, messageNumber) in peersAdvertisingInfo{
            let messageNumberFromPeer = Int(messageNumber)!
            
            if let messageNumberIHave = routingProtocolManager.advertisingInformation?[objectId] {
                if Int(messageNumberIHave)! < messageNumberFromPeer{
                    
                    let newInterestedMessageNumber = routingProtocolManager.calculateMessageNumberInterestedIn(Int(messageNumberIHave)!, numberPeerHas: messageNumberFromPeer)
                    
                    //I'm interested in this infomation
                    if sendToPeerInformationImInterestedIn == nil {
                        localInformationImInterestedIn = [objectId: String(messageNumberFromPeer)]
                        sendToPeerInformationImInterestedIn = [objectId:String(newInterestedMessageNumber)]
                    }else{
                        localInformationImInterestedIn![objectId] = String(messageNumberFromPeer)
                        sendToPeerInformationImInterestedIn![objectId] = String(newInterestedMessageNumber)
                    }
                    
                }else{
                    print("I'm up-to-date with messages from peer \(peerID) for user \(objectId)")
                }
            }else{
                
                //I'm interested in this infomation, I don't have any messages so I need the number 1 first
                if sendToPeerInformationImInterestedIn == nil {
                    localInformationImInterestedIn = [objectId: String(messageNumberFromPeer)]
                    sendToPeerInformationImInterestedIn = [objectId: String(1)]
                }else{
                    localInformationImInterestedIn![objectId] = String(messageNumberFromPeer)
                    sendToPeerInformationImInterestedIn![objectId] = String(1)
                }
            }
        }
        
        routingProtocolManager.tellPeerImInterestedInConnecting(peerID, sendToPeerInformationImInterestedIn: sendToPeerInformationImInterestedIn, localInformationImInterestedIn: localInformationImInterestedIn)
    }
}
