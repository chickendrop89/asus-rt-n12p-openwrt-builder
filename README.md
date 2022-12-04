# rt-n12p-openwrt-script

My small personal script for building openWRT for ASUS RT-N12+ (with the **MT7620N** CPU)

### Running the script

- Tested on Ubuntu 22.04 (Jammy Jellyfish) but should work on any linux distribution

##### 1) Chmod the script
```shell
$ chmod +x build-script.sh
```

##### 2) Edit the configuration with your favourite editor
```shell
$ vi build-script.sh
```

##### 3) Run the script with bash
```shell
$ bash build-script.sh
```

--------

### Device Specifications

| Device                  | ASUS RT-N12+                                                |
| ----------------------- | :---------------------------------------------------------- |
| CPU                     | MediaTek MT7620N (1 core, 580 MHz)                          |
| Target                  | ramips                                                      |
| Subtarget               | mt7620                                                      |
| Package Architecture    | mipsel_24kc                                                 |
| Bootloader              | U-Boot                                                      |
| Flash                   | 8 MB                                                        |
| RAM                     | 32 MB (EM63A165TS-6G)                                       |
| VLAN                    | Yes                                                         |
| Ethernet                | 100M ports: 5                                               |
| WLAN                    | 2.4GHz: b/g/n, 300 Mbps                                     |
| WLAN Driver             | [mt76](https://openwrt.org/docs/techref/driver.wlan/mt76)   |
| Fixed Antennas          | 2                                                           |
| Buttons & LEDs          | 1 Button, 4 LEDs                                            |
| Serial                  | 8-N-1, Baud Rate: 115200                                    |
| Power Supply            | 12 VDC, 0.5 A                                               |
| Flash/Recovery Method   | [U-BOOT TFTP](https://git.openwrt.org/?p=openwrt/openwrt.git;a=commit;h=58e0673900ea585b03d3cc2f8917667faa3f977f)