/*
 * i2c.h
 *
 * Created: 2/17/2019 5:05:57 PM
 *  Author: Steven
 */ 

#ifndef __I2C_H
#define __I2C_H

#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #

extern const int SLAVE_OK;
extern const int SLAVE_NO_ACK;
extern const int SLAVE_NAK;


void configure_i2c_master(void);
int i2c_read_reg(uint16_t slave_addr, uint8_t slave_reg, uint8_t *value);
int i2c_write_reg(uint16_t slave_addr, uint8_t slave_reg, uint8_t value);

#endif