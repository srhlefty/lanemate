/*
 * uart.c
 *
 * Created: 2/17/2019 5:11:53 PM
 *  Author: Steven
 */ 
/*
#include <string.h>
#include "uart.h"
#include "utils.h"
#include "i2c.h"

struct usart_module usart_instance;

void configure_usart(void)
{
	struct usart_config config_usart;
	usart_get_config_defaults(&config_usart);

	config_usart.use_external_clock = false;
	config_usart.baudrate    = 9600;
	config_usart.transfer_mode = USART_TRANSFER_ASYNCHRONOUSLY;
	config_usart.receiver_enable = true;
	config_usart.transmitter_enable = true;
	config_usart.stopbits = USART_STOPBITS_1;
	config_usart.mux_setting = USART_RX_1_TX_0_XCK_1; // TX on PAD0, RX on PAD1, PAD2 unused, PAD3 unused
	// pin 1 = PA05 -> SERCOM0[3]
	// pin 2 = PA06 -> SERCOM0[0]
	// pin 3 = PA07 -> SERCOM0[1]
	// pin 4 = PA08 -> SERCOM0[2]
	config_usart.pinmux_pad0 = PINMUX_PA06C_SERCOM0_PAD0;
	config_usart.pinmux_pad1 = PINMUX_PA07C_SERCOM0_PAD1;
	config_usart.pinmux_pad2 = PINMUX_PA08D_SERCOM0_PAD2;
	config_usart.pinmux_pad3 = PINMUX_PA05C_SERCOM0_PAD3;

	while (usart_init(&usart_instance, SERCOM0, &config_usart) != STATUS_OK) {
	}

	usart_enable(&usart_instance);
}

void print(const uint8_t *str)
{
	usart_write_buffer_wait(&usart_instance, str, strlen(str));
}
*/
/*
void servicer(void)
{
	uint8_t buffer[64];
	uint8_t ptr = 0;
	print("> ");
	while(1)
	{
		uint8_t *tail = buffer + ptr;
		int code = usart_read_buffer_wait(&usart_instance, tail, 1);
		if(code == STATUS_OK)
		{
			usart_write_buffer_wait(&usart_instance, tail, 1);
			if(*tail == '\r' || *tail == '\n')
			{
				print("\r\n");
				// message complete, process
				if(buffer[0] == 'R')
				{
					// R [slave address] [register]
					uint8_t slave = string_to_byte(buffer+2);
					uint8_t reg = string_to_byte(buffer+5);
					uint8_t value;
					int code = i2c_read_reg(slave, reg, &value);
					if(code == SLAVE_OK)
					{
						uint8_t str[5] = "XX\r\n";
						byte_to_string(str, value);
						print(str);
					}else if(code == SLAVE_NAK)
					{
						print("Slave: NAK\r\n");
					}else if(code == SLAVE_NO_ACK)
					{
						print("Slave: no response\r\n");
					}
					
				}else if(buffer[0] == 'W')
				{
					// W [slave address] [register] [value]
					uint8_t slave = string_to_byte(buffer+2);
					uint8_t reg = string_to_byte(buffer+5);
					uint8_t value = string_to_byte(buffer+8);
					int code = i2c_write_reg(slave, reg, value);
					if(code == SLAVE_OK)
					{
						print("OK\r\n");
					}else if(code == SLAVE_NAK)
					{
						print("NAK\r\n");
					}else if(code == SLAVE_NO_ACK)
					{
						print("No response\r\n");
					}
				}else if(buffer[0] == 'd' && buffer[1] == 'u' && buffer[2] == 'm' && buffer[3] == 'p')
				{
					// dump [slave address] [starting register] [count]
					uint8_t slave = string_to_byte(buffer+5);
					uint8_t reg = string_to_byte(buffer+8);
					unsigned int count = string_to_byte(buffer+11);
					for(int i=0;i<count;++i)
					{
						uint8_t value;
						int code = i2c_read_reg(slave, reg+i, &value);
						if(code == SLAVE_OK)
						{
							uint8_t str[5] = "XX ";
							byte_to_string(str, value);
							print(str);
						}else if(code == SLAVE_NAK)
						{
							print("NAK");
							break;
						}else if(code == SLAVE_NO_ACK)
						{
							print("?? ");
						}
						if((i+1) % 16 == 0) print("\r\n");
						delay_cycles_ms(1);
					}
					print("\r\n");
				}
				else
				{
					print("Usage:\r\n  R <slave> <register>\r\n  W <slave> <register> <value>\r\n  dump <slave> <start register> <count>\r\n(all values are in hex)\r\n");
				}
				print("> ");
				ptr = 0;
				continue;
			}else
			{
				if(ptr < 62)
				{
					++ptr;
					continue;
				}else
				{
					print("Input overflow, resetting\r\n");
					print("> ");
					ptr = 0;
					continue;
				}
			}
		}
	}
}
*/