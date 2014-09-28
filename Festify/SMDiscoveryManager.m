//
//  PGDiscoveryManager.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMDiscoveryManager.h"

@interface SMDiscoveryManager ()

@property (nonatomic, strong) CBCentralManager* centralManager;
@property (nonatomic, strong) CBPeripheralManager* peripheralManager;
@property (nonatomic, assign, getter = isAdvertising) BOOL advertising;
@property (nonatomic, assign, getter = isDiscovering) BOOL discovering;

// central manager objects
@property (nonatomic, strong) NSMutableArray* discoveredPeripherals;
@property (nonatomic, strong) NSMutableDictionary* peripheralData;

// peripheral manager objects
@property (nonatomic, strong) NSData* advertisedProperty;
@property (nonatomic, strong) NSMutableDictionary* subscribedCentralsInfo;
@property (nonatomic, strong) CBMutableCharacteristic* propertyCharacteristic;

@end

@implementation SMDiscoveryManager

// create a singleton instance of discovery manager
+(SMDiscoveryManager*)sharedInstance {
    static SMDiscoveryManager* _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void) {
        _sharedInstance = [[SMDiscoveryManager alloc] init];
    });
    
    return _sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        // create bluetooth manager and set self as their delegate
        dispatch_queue_t centralManagerQueue = dispatch_queue_create("com.patrikgebhardt.festify.centralManager", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t peripheralManagerQueue = dispatch_queue_create("com.patrikgebhardt.festify.peripheralManager", DISPATCH_QUEUE_SERIAL);
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralManagerQueue];
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:peripheralManagerQueue];

        // init properties
        self.discoveredPeripherals = [NSMutableArray array];
        self.subscribedCentralsInfo = [NSMutableDictionary dictionary];
        self.peripheralData = [NSMutableDictionary dictionary];
    }
    
    return self;
}

-(BOOL)advertiseProperty:(NSData*)property {
    self.advertisedProperty = property;
    
    // check the bluetooth state
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        return NO;
    }
    
    // stop advertisement, if already running to clear all services
    [self stopAdvertising];
    
    // init peripheral service to advertise playlist uri and device name
    self.propertyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SMDiscoveryManagerPropertyUUIDString]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
    
    CBMutableCharacteristic* devicenameCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SMDiscoveryManagerDevicenameUUIDString]
                                                                                    properties:CBCharacteristicPropertyRead
                                                                                         value:[[UIDevice currentDevice].name dataUsingEncoding:NSUTF8StringEncoding]
                                                                                   permissions:CBAttributePermissionsReadable];
    
    CBMutableService* service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SMDiscoveryManagerServiceUUIDString] primary:YES];
    service.characteristics = @[self.propertyCharacteristic, devicenameCharacteristic];
    [self.peripheralManager addService:service];
    
    // advertise service
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:SMDiscoveryManagerServiceUUIDString]],
                                               CBAdvertisementDataLocalNameKey: [UIDevice currentDevice].name}];
    self.advertising = YES;
    
    // post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:SMDiscoveryManagerDidUpdateAdvertisementState object:self];
    
    return YES;
}

-(void)stopAdvertising {
    if (self.isAdvertising) {
        [self.peripheralManager stopAdvertising];
    }
    [self.peripheralManager removeAllServices];
    self.advertising = NO;

    // post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:SMDiscoveryManagerDidUpdateAdvertisementState object:self];
}

-(BOOL)startDiscovering {
    // check the bluetooth state
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        return NO;
    }
    
    // scan for festify services
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SMDiscoveryManagerServiceUUIDString]]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
    self.discovering = YES;
    
    // post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:SMDiscoveryManagerDidUpdateDiscoveryState object:self];

    return YES;
}

-(void)stopDiscovering {
    if (self.isDiscovering) {
        [self.centralManager stopScan];
    }
    self.discovering = NO;

    // post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:SMDiscoveryManagerDidUpdateDiscoveryState object:self];
}

#pragma mark - CBPeripheralManagerDelegate

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state != CBPeripheralManagerStatePoweredOn && self.isAdvertising) {
        self.advertising = NO;
        [self stopAdvertising];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    // start sending advertised data to central
    if ([[characteristic.UUID.UUIDString lowercaseString] isEqualToString:SMDiscoveryManagerPropertyUUIDString]) {
        // save new central and data position to info dictionary
        NSMutableDictionary* centralInfo = [NSMutableDictionary dictionary];
        centralInfo[@"central"] = central;
        centralInfo[@"dataPosition"] = [NSNumber numberWithInteger:[self sendDataChunkToCentral:central fromPosition:0]];
        
        self.subscribedCentralsInfo[central.identifier.UUIDString] = centralInfo;
    }
}

-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    // send next data chunk to all subscribers
    for (NSMutableDictionary* centralInfo in self.subscribedCentralsInfo.allValues) {
        NSInteger newDataPosition = [self sendDataChunkToCentral:centralInfo[@"central"] fromPosition:[centralInfo[@"dataPosition"] integerValue]];
        centralInfo[@"dataPosition"] = [NSNumber numberWithInteger:newDataPosition];

        // remove info dictionary for specific central, if all data are send
        if (newDataPosition == -1) {
            CBCentral* central = centralInfo[@"central"];
            [self.subscribedCentralsInfo removeObjectForKey:central.identifier.UUIDString];
        }
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    [self.subscribedCentralsInfo removeObjectForKey:central.identifier.UUIDString];
}

#pragma mark - CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn && self.isDiscovering) {
        self.discovering = NO;
        [self stopDiscovering];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    // connect to peripheral to retrieve list of services and
    // prevent CoreBluetooth from deallocating peripheral
    [self.discoveredPeripherals addObject:peripheral];
    peripheral.delegate = self;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // discover our service
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SMDiscoveryManagerServiceUUIDString]]];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
    }
    
    // remove peripheral from list
    [self.discoveredPeripherals removeObject:peripheral];
    [self.peripheralData removeObjectForKey:peripheral.identifier.UUIDString];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
    }
    
    // remove peripheral from list
    [self.discoveredPeripherals removeObject:peripheral];
    [self.peripheralData removeObjectForKey:peripheral.identifier.UUIDString];
}

#pragma mark - CBPeripheralDelegate

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
        
        [self.centralManager cancelPeripheralConnection:peripheral];
        return;
    }
    
    // discover the playlist characteristic
    if (peripheral.services.count != 0) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:SMDiscoveryManagerPropertyUUIDString], [CBUUID UUIDWithString:SMDiscoveryManagerDevicenameUUIDString]]
                                 forService:peripheral.services[0]];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
        
        [self.centralManager cancelPeripheralConnection:peripheral];
        return;
    }
    
    // read devicename and subscribe to property characteristic
    for (CBCharacteristic* characteristic in service.characteristics) {
        if ([[characteristic.UUID.UUIDString lowercaseString] isEqualToString:SMDiscoveryManagerDevicenameUUIDString]) {
            [peripheral readValueForCharacteristic:characteristic];
        }
        else if ([[characteristic.UUID.UUIDString lowercaseString] isEqualToString:SMDiscoveryManagerPropertyUUIDString]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);

        [self.centralManager cancelPeripheralConnection:peripheral];
        return;
    }
    
    // add dictionary for current peripheral
    if (!self.peripheralData[peripheral.identifier.UUIDString]) {
        self.peripheralData[peripheral.identifier.UUIDString] = [NSMutableDictionary dictionary];
        self.peripheralData[peripheral.identifier.UUIDString][@"dataComplete"] = @NO;
    }

    // read out characteristic value
    NSString* characteristicValue = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    if ([[characteristic.UUID.UUIDString lowercaseString] isEqualToString:SMDiscoveryManagerDevicenameUUIDString]) {
        [self.peripheralData[peripheral.identifier.UUIDString] setValue:characteristicValue
                                                                 forKey:[characteristic.UUID.UUIDString lowercaseString]];
    }
    else if ([[characteristic.UUID.UUIDString lowercaseString] isEqualToString:SMDiscoveryManagerPropertyUUIDString]) {
        if (![characteristicValue isEqualToString:@"EOM"]) {
            if (!self.peripheralData[peripheral.identifier.UUIDString][SMDiscoveryManagerPropertyUUIDString]) {
                self.peripheralData[peripheral.identifier.UUIDString][SMDiscoveryManagerPropertyUUIDString] = [NSMutableData dataWithData:characteristic.value];
            }
            else {
                [self.peripheralData[peripheral.identifier.UUIDString][SMDiscoveryManagerPropertyUUIDString] appendData:characteristic.value];
            }
        }
        else {
            self.peripheralData[peripheral.identifier.UUIDString][@"dataComplete"] = @YES;
        }
    }
    
    // check if all data are collected
    if ([self.peripheralData[peripheral.identifier.UUIDString] allKeys].count == 3 &&
        [self.peripheralData[peripheral.identifier.UUIDString][@"dataComplete"] boolValue]) {
        // inform delegate about new playlist
        if (self.delegate) {
            NSData* property = self.peripheralData[peripheral.identifier.UUIDString][SMDiscoveryManagerPropertyUUIDString];
            NSString* devicename = self.peripheralData[peripheral.identifier.UUIDString][SMDiscoveryManagerDevicenameUUIDString];
            [self.delegate discoveryManager:self didDiscoverDevice:devicename withProperty:property];
        }
        
        // disconnect device
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark - Helper

-(NSInteger)sendDataChunkToCentral:(CBCentral*)central fromPosition:(NSInteger)position {
    // try to send EOM, if all data are allready send
    if (position >= self.advertisedProperty.length) {
        BOOL success = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding]
                                         forCharacteristic:self.propertyCharacteristic
                                      onSubscribedCentrals:@[central]];
        
        if (success) {
            return -1;
        }
        else {
            return position;
        }
    }

    // send chunk of property to central
    while (YES) {
        NSInteger amountToSend = self.advertisedProperty.length - position > central.maximumUpdateValueLength ?
            central.maximumUpdateValueLength : self.advertisedProperty.length - position;
        NSData* chunk = [NSData dataWithBytes:(self.advertisedProperty.bytes + position) length:amountToSend];
        
        if (![self.peripheralManager updateValue:chunk forCharacteristic:self.propertyCharacteristic onSubscribedCentrals:@[central]]) {
            return position;
        }
        
        // update current data position and send EOM, if neccessary
        position += amountToSend;
        
        // try to send EOM, if all data are allready send
        if (position >= self.advertisedProperty.length) {
            BOOL success = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding]
                                             forCharacteristic:self.propertyCharacteristic
                                          onSubscribedCentrals:@[central]];
            
            if (success) {
                return -1;
            }
            else {
                return position;
            }
        }
    }
}

@end