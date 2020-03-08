/*
 * utils.c
 *
 * Created: 2/17/2019 5:00:22 PM
 *  Author: Steven
 */ 
/*
#include "utils.h"
#include "i2c.h"
#include "uart.h"

uint8_t nibble_to_char(uint8_t value)
{
	switch(value & 0x0F)
	{
		case 0x0:
		return '0';
		case 0x1:
		return '1';
		case 0x2:
		return '2';
		case 0x3:
		return '3';
		case 0x4:
		return '4';
		case 0x5:
		return '5';
		case 0x6:
		return '6';
		case 0x7:
		return '7';
		case 0x8:
		return '8';
		case 0x9:
		return '9';
		case 0xA:
		return 'A';
		case 0xB:
		return 'B';
		case 0xC:
		return 'C';
		case 0xD:
		return 'D';
		case 0xE:
		return 'E';
		case 0xF:
		return 'F';
	}
	return '?';
}
void byte_to_string(uint8_t *dst, uint8_t value)
{
	dst[0] = nibble_to_char(value >> 4);
	dst[1] = nibble_to_char(value);
}
*/
/*
void int_to_string(uint8_t *dst, unsigned int value)
{
	byte_to_string(dst, value >> 8);
	byte_to_string(dst+2, value);
}
uint8_t string_to_nibble(uint8_t src)
{
	switch(src)
	{
		case '0':
		return 0;
		case '1':
		return 1;
		case '2':
		return 2;
		case '3':
		return 3;
		case '4':
		return 4;
		case '5':
		return 5;
		case '6':
		return 6;
		case '7':
		return 7;
		case '8':
		return 8;
		case '9':
		return 9;
		case 'a':
		case 'A':
		return 10;
		case 'b':
		case 'B':
		return 11;
		case 'c':
		case 'C':
		return 12;
		case 'd':
		case 'D':
		return 13;
		case 'e':
		case 'E':
		return 14;
		case 'f':
		case 'F':
		return 15;
		default:
		return 0;
	}
}
uint8_t string_to_byte(uint8_t *src)
{
	uint8_t high, low;
	high = string_to_nibble(src[0]);
	low = string_to_nibble(src[1]);
	return (high << 4) | low;
}

void register_dump(uint16_t slave_addr)
{
	for(unsigned int i=0;i<256;++i)
	{
		uint8_t value = 0;
		uint8_t buf[4] = "    ";
		int code = i2c_read_reg(slave_addr, i, &value);

		if(code == SLAVE_OK)
		{
			// ok
			byte_to_string(buf, value);
		}else if(code == SLAVE_NO_ACK)
		{
			uint8_t string[] = "[Write] Error: slave did not ACK\r\n";
			print(string);
			break;
		}else
		{
			buf[0] = 'N'; buf[1] = 'A'; buf[2] = 'K';
		}

		print(buf);
		if((i+1)%16 == 0)
			print("\r\n");
	}

}
*/


