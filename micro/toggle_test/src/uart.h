/*
 * uart.h
 *
 * Created: 2/17/2019 5:11:24 PM
 *  Author: Steven
 */ 
#ifndef __UART_H
#define __UART_H

#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #

void configure_usart(void);
void print(const uint8_t *str);
void servicer(void);


#endif