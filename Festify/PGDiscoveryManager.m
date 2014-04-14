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
@property (nonatomic, strong) CBPeripheral* discoveredPeripheral;

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
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    
    return self;
}

-(void)startAdvertisingPlaylist:(SPTPartialPlaylist*)playlist withSession:(SPTSession *)session {
    // init peripheral service
    CBMutableCharacteristic* characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:self.appId] properties:CBCharacteristicPropertyRead value:[[playlist.uri absoluteString] dataUsingEncoding:NSUTF8StringEncoding] permissions:CBAttributePermissionsReadable];
    CBMutableService* service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:self.appId] primary:YES];
    service.characteristics = @[characteristic];
    [self.peripheralManager addService:service];
    
    // advertise service
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:self.appId]],
                                               CBAdvertisementDataLocalNameKey: session.canonicalUsername}];
}

-(void)stopAdvertising {
    [self.peripheralManager stopAdvertising];
}

-(void)discoverPlaylists {
    // scan for festify services
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:self.appId]]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
}

#pragma mark - CBPeripheralManagerDelegate

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"error starting advertising: %@", error);
        return;
    }
    
    NSLog(@"peripheral manager did start advertising: %d", peripheral.isAdvertising);
}

#pragma mark - CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    // connect to peripheral to retrieve list of services and
    // prevent CoreBluetooth from deallocating peripheral
    self.discoveredPeripheral = peripheral;
    self.discoveredPeripheral.delegate = self;
    [self.centralManager connectPeripheral:self.discoveredPeripheral options:nil];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // discover our service
    [peripheral discoverServices:@[[CBUUID UUIDWithString:self.appId]]];
}

#pragma mark - CBPeripheralDelegate

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // discover the playlist characteristic
    [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:self.appId]] forService:peripheral.services[0]];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // read playlist value of the characteristic
    [peripheral readValueForCharacteristic:service.characteristics[0]];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"Characteristic: %@", [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
}

@end
