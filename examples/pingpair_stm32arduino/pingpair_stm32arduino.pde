/*
 Copyright (C) 2017 Mark <mark.kharkov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

/**
 * Example RF Radio Ping Pair ... for STM32 Maple Arduino
 * Changed:
 * 1) add work with different SPI (1 or 2 or 3)
 * 2) write a own function toggleLED
 * 3) example, how to work with channel, speed, etc
 *
 * This is an example of how to use the RF24 class.  Write this sketch to two different nodes,
 * connect the role_pin to ground on one.  The ping node sends the current time to the pong node,
 * which responds by sending the value back.  The ping node can then see how long the whole cycle
 * took.
 */

#include "WProgram.h"
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>
#include <stdio.h>

//
// Hardware configuration
//

int CE_PIN = 11;
int CSN_PIN = 7;
int IRQ_PIN = 10;

// SPI Class for communication with SPI

SPIClass SPI_1(1);

// Set up nRF24L01 radio on SPI bus plus pins 11 & 7
// (This works for the Getting Started board plugged into the
// Maple Native backwards.)

RF24 radio(SPI_1, CE_PIN, CSN_PIN);

// sets the role of this unit in hardware.  Connect to GND to be the 'pong' receiver
// Leave open to be the 'ping' transmitter
const int role_pin = 12;

//
// Topology
//

// Radio pipe addresses for the 2 nodes to communicate.
const uint64_t pipes[2] = { 0xC2C2C2C2C2, 0xC2C2C2C2C2 };

//
// Role management
//
// Set up role.  This sketch uses the same software for all the nodes
// in this system.  Doing so greatly simplifies testing.  The hardware itself specifies
// which node it is.
//
// This is done through the role_pin
//

// The various roles supported by this sketch
typedef enum { role_ping_out = 1, role_pong_back } role_e;

// The debug-friendly names of those roles
const char* role_friendly_name[] = { "invalid", "Ping out", "Pong back"};

// The role of the current running sketch
role_e role;

void setup(void)
{
  delay(5000);

  Serial.begin(9600);

  pinMode(LED_BUILTIN, OUTPUT);

  SPI_1.begin();
  SPI_1.setDataMode(SPI_MODE0);
  SPI_1.setBitOrder(MSBFIRST);

  //
  // Role
  //

  // set up the role pin
  pinMode(role_pin, INPUT);
  digitalWrite(role_pin,HIGH);
  delay(20); // Just to get a solid reading on the role pin

  // read the address pin, establish our role
  if ( digitalRead(role_pin))
    role = role_ping_out;
  else
    role = role_pong_back;

  //
  // Print preamble
  //

  Serial.print("\n\rRF24/examples/pingpair/\n\r");
  printf_P("ROLE: %s\n\r",role_friendly_name[role]);

  //
  // Setup and configure rf radio
  //

  radio.begin();

  radio.setChannel(0x60);
  radio.setDataRate(RF24_2MBPS);

  // optionally, increase the delay between retries & # of retries
  radio.setRetries(15,15);

  // optionally, reduce the payload size.  seems to
  // improve reliability
  radio.setPayloadSize(8);

  //
  // Open pipes to other nodes for communication
  //

  // This simple sketch opens two pipes for these two nodes to communicate
  // back and forth.
  // Open 'our' pipe for writing
  // Open the 'other' pipe for reading, in position #1 (we can have up to 5 pipes open for reading)

  if ( role == role_ping_out )
  {
    radio.openWritingPipe(pipes[0]);
    radio.openReadingPipe(1,pipes[1]);
  }
  else
  {
    radio.openWritingPipe(pipes[1]);
    radio.openReadingPipe(1,pipes[0]);
  }

  //
  // Start listening
  //

  radio.startListening();

  //
  // Dump the configuration of the rf unit for debugging
  //

  radio.printDetails();
}

void toggleLED(){
  digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
}

void loop(void)
{
  //
  // Ping out role.  Repeatedly send the current time
  //

  if (role == role_ping_out)
  {
    toggleLED();

    // First, stop listening so we can talk.
    radio.stopListening();

    // Take the time, and send it.  This will block until complete
    unsigned long time = millis();
    printf_P("Now sending %lu...", time);
    bool ok = radio.write( &time, sizeof(unsigned long) );

    if (ok)
      Serial.println("ok...\r\n");
    else
      Serial.println("failed.\r\n");

    // Now, continue listening
    radio.startListening();

    // Wait here until we get a response, or timeout (250ms)
    unsigned long started_waiting_at = millis();
    bool timeout = false;
    while ( ! radio.available() && ! timeout )
      if (millis() - started_waiting_at > 200 )
        timeout = true;

    // Describe the results
    if ( timeout )
    {
      Serial.println("Failed, response timed out.\r\n");
    }
    else
    {
      // Grab the response, compare, and send to debugging spew
      unsigned long got_time;
      radio.read( &got_time, sizeof(unsigned long) );

      // Spew it
      printf_P("Got response %lu, round-trip delay: %lu\r\n", got_time, millis()-got_time);
    }

    toggleLED();

    // Try again 1s later
    delay(1000);
  }

  //
  // Pong back role.  Receive each packet, dump it out, and send it back
  //

  if ( role == role_pong_back )
  {
    // if there is data ready
    if ( radio.available() )
    {
      // Dump the payloads until we've gotten everything
      unsigned long got_time;
      bool done = false;
      while (!done)
      {
        // Fetch the payload, and see if this was the last one.
        done = radio.read( &got_time, sizeof(unsigned long) );

        // Spew it
        printf_P("Got payload %lu...", got_time);

        // Delay just a little bit to let the other unit
        // make the transition to receiver
        delay(20);
      }

      // First, stop listening so we can talk
      radio.stopListening();

      // Send the final one back.
      radio.write( &got_time, sizeof(unsigned long) );
      Serial.println("Sent response.\r\n");

      // Now, resume listening so we catch the next packets.
      radio.startListening();
    }
  }
}
