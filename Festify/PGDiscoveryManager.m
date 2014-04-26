//
//  PGDiscoveryManager.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGDiscoveryManager.h"

@interface PGDiscoveryManager ()

@property (nonatomic, strong) CBCentralManager* centralManager;
@property (nonatomic, strong) CBPeripheralManager* peripheralManager;
@property (nonatomic, strong) NSMutableArray* discoveredPeripherals;
@property (nonatomic, strong) NSMutableDictionary* peripheralData;
@property (nonatomic, assign) BOOL discovering;

@end

@implementation PGDiscoveryManager

// create a singleton instance of discovery manager
+(PGDiscoveryManager*)sharedInstance {
    static PGDiscoveryManager* _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void) {
        _sharedInstance = [[PGDiscoveryManager alloc] init];
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
        self.discovering = NO;
        
        self.discoveredPeripherals = [NSMutableArray array];
        self.peripheralData = [NSMutableDictionary dictionary];
    }
    
    return self;
}

-(BOOL)advertiseProperty:(NSData*)property {
    // check the bluetooth state
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        return NO;
    }
    
    // init peripheral service to advertise playlist uri and device name
    CBMutableCharacteristic* propertyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:PGDiscoveryManagerPropertyUUIDString]
                                                                                     properties:CBCharacteristicPropertyRead
                                                                                          value:property
                                                                                    permissions:CBAttributePermissionsReadable];
    
    CBMutableCharacteristic* devicenameCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:PGDiscoveryManagerDevicenameUUIDString]
                                                                                    properties:CBCharacteristicPropertyRead
                                                                                         value:[[UIDevice currentDevice].name dataUsingEncoding:NSUTF8StringEncoding]
                                                                                   permissions:CBAttributePermissionsReadable];
    
    CBMutableService* service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:PGDiscoveryManagerServiceUUIDString] primary:YES];
    service.characteristics = @[propertyCharacteristic, devicenameCharacteristic];
    [self.peripheralManager addService:service];
    
    // advertise service
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:PGDiscoveryManagerServiceUUIDString]],
                                               CBAdvertisementDataLocalNameKey: [UIDevice currentDevice].name}];
    
    return YES;
}

-(void)stopAdvertisingProperty {
    if (self.isAdvertisingProperty) {
        [self.peripheralManager stopAdvertising];
        [self.peripheralManager removeAllServices];
    }
}

-(BOOL)isAdvertisingProperty {
    return self.peripheralManager.isAdvertising;
}

-(BOOL)startDiscovering {
    // check the bluetooth state
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        return NO;
    }
    
    // scan for festify services
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:PGDiscoveryManagerServiceUUIDString]]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
    self.discovering = YES;
    
    return YES;
}

-(void)stopDiscovering {
    [self.centralManager stopScan];
    self.discovering = NO;
}

-(BOOL)isDiscovering {
    return self.discovering;
}

#pragma mark - CBPeripheralManagerDelegate

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
}

#pragma mark - CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {

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
    [peripheral discoverServices:@[[CBUUID UUIDWithString:PGDiscoveryManagerServiceUUIDString]]];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // remove peripheral from list
    [self.discoveredPeripherals removeObject:peripheral];
    [self.peripheralData removeObjectForKey:peripheral.identifier.UUIDString];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // remove peripheral from list
    [self.discoveredPeripherals removeObject:peripheral];
    [self.peripheralData removeObjectForKey:peripheral.identifier.UUIDString];
}

#pragma mark - CBPeripheralDelegate

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // discover the playlist characteristic
    if (peripheral.services.count != 0) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:PGDiscoveryManagerPropertyUUIDString], [CBUUID UUIDWithString:PGDiscoveryManagerDevicenameUUIDString]]
                                 forService:peripheral.services[0]];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // read playlist value of the characteristic
    for (CBCharacteristic* characteristic in service.characteristics) {
        [peripheral readValueForCharacteristic:characteristic];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // add dictionary for current peripheral
    if (!self.peripheralData[peripheral.identifier.UUIDString]) {
        self.peripheralData[peripheral.identifier.UUIDString] = [NSMutableDictionary dictionary];
    }

    // save received data to peripheral dictionary
    [self.peripheralData[peripheral.identifier.UUIDString] setValue:[characteristic.value copy]
                                                             forKey:[characteristic.UUID.UUIDString lowercaseString]];

    // check if all data are collected
    if ([self.peripheralData[peripheral.identifier.UUIDString] allKeys].count == 2) {
        // inform delegate about new playlist
        if (self.delegate) {
            NSData* property = [self.peripheralData[peripheral.identifier.UUIDString] objectForKey:PGDiscoveryManagerPropertyUUIDString];
            NSString* devicename = [[NSString alloc] initWithData:self.peripheralData[peripheral.identifier.UUIDString][PGDiscoveryManagerDevicenameUUIDString]
                                                         encoding:NSUTF8StringEncoding];
            [self.delegate discoveryManager:self didDiscoverDevice:devicename withProperty:property];
        }
        
        // disconnect device
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

@end