/*
 * utils.h
 *
 * Created: 2/17/2019 5:01:33 PM
 *  Author: Steven
 */ 

#ifndef __UTILS_H
#define __UTILS_H

#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #

uint8_t nibble_to_char(uint8_t value);
void byte_to_string(uint8_t *dst, uint8_t value);
void int_to_string(uint8_t *dst, unsigned int value);
uint8_t string_to_nibble(uint8_t src);
uint8_t string_to_byte(uint8_t *src);
void register_dump(uint16_t slave_addr);


#endif