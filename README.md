# Arduino driver for nRF24L01 2.4GHz Wireless Transceiver

## Fork of manicbug code
I made this fork in order to port the library to the environment of Arduino. Here is a short list of changes from the original library:
* defined a STM32-version of printf_P function, to run a library and examples
* added a pingpair_stm32arduino sample, how to work with library in different hardware SPI's
* removed all PROGMEM (becouse STM32 Arduino environment not use this)
* added SPIClass parameter to class constructor

## About library
Design Goals: This library is designed to be...

* Maximally compliant with the intended operation of the chip
* Easy for beginners to use
* Consumed with a public interface that's similiar to other Arduino standard libraries
* Built against the standard SPI library.

Please refer to:

* [Documentation Main Page](http://github.com/markkharkov/RF24)
* [Source Code](https://github.com/markkharkov/RF24)
* [Downloads](https://github.com/markkharkov/RF24/archives/master)
* [Chip Datasheet](http://www.nordicsemi.com/files/Product/data_sheet/nRF24L01_Product_Specification_v2_0.pdf)

This chip uses the SPI bus, plus two chip control pins.
