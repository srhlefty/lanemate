#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #
#include <string.h>
#include "utils.h"
#include "i2c.h"
#include "uart.h"
#include "hdmi_rx.h"

#define TEST_PIN PIN_PA24
void config_test_pin(void);
void config_test_pin(void)
{
	struct port_config pin_conf;
	port_get_config_defaults(&pin_conf);

	pin_conf.direction  = PORT_PIN_DIR_OUTPUT;
	port_pin_set_config(TEST_PIN, &pin_conf);
	port_pin_set_output_level(TEST_PIN, LOW);
}


const uint16_t hdmi_tx_address = 0x72 >> 1;
const uint16_t sd_rx_address = 0x40 >> 1;





void configure_sd_rx(void);
void configure_sd_rx(void)
{
	print("Setting up SD RX\r\n");
	i2c_write_reg(sd_rx_address, 0x58, 0x05); // 0x5 = output VS; 0x4 = output FIELD
}



void configure_hdmi_tx(void);
void configure_hdmi_tx(void)
{
	enum input_type {IN_HD=2, IN_SD};
	const int video_in = IN_HD;

	print("Setting up HDMI TX\r\n");
	uint8_t value;


	i2c_write_reg(hdmi_tx_address, 0x41, 0b01010000); // power down
	delay_cycles_ms(100);
	i2c_write_reg(hdmi_tx_address, 0x41, 0b00010010); // power up
	//delay_cycles_ms(1000);


	// fixed registers to be set upon power up
	i2c_write_reg(hdmi_tx_address, 0x98, 0x03);
	{
		// 0x9A[7:5] = 0b111
		i2c_read_reg(hdmi_tx_address, 0x9A, &value);
		value = value | 0b11100000;
		i2c_write_reg(hdmi_tx_address, 0x9A, value);
	}
	i2c_write_reg(hdmi_tx_address, 0x9C, 0x30);
	{
		// 0x9D[1:0] = 0b01
		i2c_read_reg(hdmi_tx_address, 0x9D, &value);
		value = value & 0b11111101;
		value = value | 0b00000001;
		i2c_write_reg(hdmi_tx_address, 0x9D, value);
	}
	i2c_write_reg(hdmi_tx_address, 0xA2, 0xA4);
	i2c_write_reg(hdmi_tx_address, 0xA3, 0xA4);
	i2c_write_reg(hdmi_tx_address, 0xE0, 0xD0);
	i2c_write_reg(hdmi_tx_address, 0xF9, 0x00);

	i2c_read_reg(hdmi_tx_address, 0xBA, &value);
	value = value & 0b01111111; // [7:5] = 0b011 for no clock input delay
	value = value | 0b01100000;
	i2c_write_reg(hdmi_tx_address, 0xBA, value);
	
	i2c_read_reg(hdmi_tx_address, 0x94, &value);
	value = value | 0b00000100; // turn on EDID Ready interrupt
	i2c_write_reg(hdmi_tx_address, 0x94, value);

	i2c_read_reg(hdmi_tx_address, 0xD6, &value);
	value = value | 0b11000000; // force HPD high always
	i2c_write_reg(hdmi_tx_address, 0xD6, value);


	//delay_cycles_ms(1000);

	if(video_in == IN_HD)
	{
		// HDMI input

		value = 0b00000000; // 24-bit 4:4:4 input with separate syncs
		i2c_write_reg(hdmi_tx_address, 0x15, value);

		i2c_read_reg(hdmi_tx_address, 0x16, &value);
		value = value | 0b00110000; // 8 bits per channel
		value = value & 0b01111111; // 4:4:4 output
		i2c_write_reg(hdmi_tx_address, 0x16, value);

		i2c_read_reg(hdmi_tx_address, 0x17, &value);
		value = value | 0b00000010; // 16:9 aspect input
		i2c_write_reg(hdmi_tx_address, 0x17, value);

		i2c_read_reg(hdmi_tx_address, 0xAF, &value);
		value = value & 0b11111101; // DVI mode
		i2c_write_reg(hdmi_tx_address, 0xAF, value);
	}else
	{
		//i2c_write_reg(hdmi_tx_address, 0x15, 0b00000000); // input format. 00=24-bit 4:4:4 (RGB or YCbCr)
		i2c_write_reg(hdmi_tx_address, 0x15, 0b00000011); // input format. 11=8-bit 4:2:2 YCbCr with separate syncs
		//i2c_write_reg(hdmi_tx_address, 0x15, 0b00000100); // input format. 11=8-bit 4:2:2 YCbCr with embedded syncs aka 8-bit ITU-R BT.656
		i2c_write_reg(hdmi_tx_address, 0x16, 0b00110100); // 4:4:4 output format, 8-bit color depth, input style 2

		i2c_write_reg(hdmi_tx_address, 0x17, 0b00000100);
		i2c_write_reg(hdmi_tx_address, 0x35, 0x1D);
		i2c_write_reg(hdmi_tx_address, 0x36, 0x92);
		i2c_write_reg(hdmi_tx_address, 0x37, 0x05);
		i2c_write_reg(hdmi_tx_address, 0x38, 0xA0);
		i2c_write_reg(hdmi_tx_address, 0x39, 0x0F);
		i2c_write_reg(hdmi_tx_address, 0x3A, 0x00);

		i2c_write_reg(hdmi_tx_address, 0xD5, 0);


		// YCbCr to RGB (Table 35)
		//i2c_write_reg(hdmi_tx_address, 0x18, 0x00);
		
		i2c_write_reg(hdmi_tx_address, 0x18, 0xE6);
		i2c_write_reg(hdmi_tx_address, 0x19, 0x69);
		i2c_write_reg(hdmi_tx_address, 0x1A, 0x04);
		i2c_write_reg(hdmi_tx_address, 0x1B, 0xAC);
		i2c_write_reg(hdmi_tx_address, 0x1C, 0x00);
		i2c_write_reg(hdmi_tx_address, 0x1D, 0x00);
		i2c_write_reg(hdmi_tx_address, 0x1E, 0x1C);
		i2c_write_reg(hdmi_tx_address, 0x1F, 0x81);
		i2c_write_reg(hdmi_tx_address, 0x20, 0x1C);
		i2c_write_reg(hdmi_tx_address, 0x21, 0xBC);
		i2c_write_reg(hdmi_tx_address, 0x22, 0x04);
		i2c_write_reg(hdmi_tx_address, 0x23, 0xAD);
		i2c_write_reg(hdmi_tx_address, 0x24, 0x1E);
		i2c_write_reg(hdmi_tx_address, 0x25, 0x6E);
		i2c_write_reg(hdmi_tx_address, 0x26, 0x02);
		i2c_write_reg(hdmi_tx_address, 0x27, 0x20);
		i2c_write_reg(hdmi_tx_address, 0x28, 0x1F);
		i2c_write_reg(hdmi_tx_address, 0x29, 0xFE);
		i2c_write_reg(hdmi_tx_address, 0x2A, 0x04);
		i2c_write_reg(hdmi_tx_address, 0x2B, 0xAD);
		i2c_write_reg(hdmi_tx_address, 0x2C, 0x08);
		i2c_write_reg(hdmi_tx_address, 0x2D, 0x1A);
		i2c_write_reg(hdmi_tx_address, 0x2E, 0x1B);
		i2c_write_reg(hdmi_tx_address, 0x2F, 0xA9);
		
		i2c_write_reg(hdmi_tx_address, 0xAF, 0b00000110); // hdmi mode
		//i2c_write_reg(hdmi_tx_address, 0xAF, 0b00000100); // dvi mode
	}

	

	print("  Finished.\r\n");
}

volatile bool handle_event = false;

void SysTick_Handler(void)
{
	handle_event = true;
}

int main (void)
{
	system_init();
	configure_usart();

	print("\r\n\n\nSoftware started\r\n");
	delay_init();




	configure_i2c_master();
	configure_hdmi_rx();
	//configure_sd_rx();
	configure_hdmi_tx();


	config_test_pin();
	port_pin_toggle_output_level(TEST_PIN);


	//print("Waiting for FPGA to boot...\r\n");
	//delay_cycles_ms(1000);

	/*
	uint8_t str[5] = "XX\r\n";
	print("Slave addresses:\r\n");
	print("HDMI RX, IO:        "); byte_to_string(str, hdmi_rx_address); print(str);
	print("HDMI RX, CP:        "); byte_to_string(str, hdmi_rx_cp_address); print(str);
	print("HDMI RX, HDMI:      "); byte_to_string(str, hdmi_rx_hdmi_address); print(str);
	print("HDMI RX, Repeater:  "); byte_to_string(str, hdmi_rx_repeater_address); print(str);
	print("HDMI RX, EDID:      "); byte_to_string(str, hdmi_rx_edid_address); print(str);
	print("HDMI RX, InfoFrame: "); byte_to_string(str, hdmi_rx_infoframe_address); print(str);
	print("HDMI RX, CEC:       "); byte_to_string(str, hdmi_rx_cec_address); print(str);
	print("HDMI RX, DPLL:      "); byte_to_string(str, hdmi_rx_dpll_address); print(str);
	print("\r\n");
	print("HDMI TX, Main:      "); byte_to_string(str, hdmi_tx_address); print(str);
	print("HDMI TX, EDID:      "); byte_to_string(str, 0x7E >> 1); print(str);

	print("Entering event loop\r\n");
	servicer();
	*/

	uint32_t ticks_per_second = system_gclk_gen_get_hz(GCLK_GENERATOR_0);
	uint32_t ticks_between_interrupts = ticks_per_second / 1;
	SysTick_Config(ticks_between_interrupts);

	while(1)
	{
		if(handle_event)
		{
			handle_event = false;

			/*
			uint8_t vic, auxvic;
			int ok = i2c_read_reg(hdmi_tx_address, 0x3E, &vic);
			int ok2 = i2c_read_reg(hdmi_tx_address, 0x3F, &auxvic);
			uint8_t str[29] = "HDMI TX: input VIC = XX, XX\r\n";
			byte_to_string(str+21, vic >> 2);
			byte_to_string(str+25, auxvic);
			if(ok == SLAVE_OK && ok2 == SLAVE_OK)
				print(str);
			else
				print("No response\r\n");
			*/

			/*
			uint8_t status1, status2, status3;
			i2c_read_reg(sd_rx_address, 0x10, &status1);
			i2c_read_reg(sd_rx_address, 0x12, &status2);
			i2c_read_reg(sd_rx_address, 0x13, &status3);
			bool in_lock = status1 & 0x01;
			uint8_t ad_result = (status1 & 0x70) >> 4;
			if(in_lock)
			{
				print("SD RX: ");
				switch(ad_result)
				{
				case 0:
					print("NTSC M/J");
					break;
				case 1:
					print("NTSC 4.43");
					break;
				case 2:
					print("PAL M");
					break;
				case 3:
					print("PAL 60");
					break;
				case 4:
					print("PAL B/G/H/I/D");
					break;
				case 5:
					print("SECAM");
					break;
				case 6:
					print("PAL Combination M");
					break;
				case 7:
					print("SECAM 525");
					break;
				}
				print("\r\n");

				uint8_t vic, auxvic;
				i2c_read_reg(hdmi_tx_address, 0x3E, &vic);
				i2c_read_reg(hdmi_tx_address, 0x3F, &auxvic);
				uint8_t str[29] = "HDMI TX: input VIC = XX, XX\r\n";
				byte_to_string(str+21, vic >> 2);
				byte_to_string(str+25, auxvic);
				print(str);
			}
			*/



			/*
			// measure the input video stream, if it exists
			uint8_t reg7,reg8,reg9,regA,reg6F;
			i2c_read_reg(hdmi_rx_hdmi_address, 0x07, &reg7);
			i2c_read_reg(hdmi_rx_hdmi_address, 0x08, &reg8);
			i2c_read_reg(hdmi_rx_hdmi_address, 0x09, &reg9);
			i2c_read_reg(hdmi_rx_hdmi_address, 0x0A, &regA);
			i2c_read_reg(hdmi_rx_address, 0x6F, &reg6F);
			uint8_t str[18] = "XX  XX XX XX XX\r\n";
			byte_to_string(str+0, reg6F);
			byte_to_string(str+4, reg7);
			byte_to_string(str+7, reg8);
			byte_to_string(str+10, reg9);
			byte_to_string(str+13, regA);
			print(str);
			*/


			/*
			uint8_t reg51, reg52;
			i2c_read_reg(hdmi_rx_hdmi_address, 0x51, &reg51);
			i2c_read_reg(hdmi_rx_hdmi_address, 0x52, &reg52);
			uint8_t str[8] = "XX XX\r\n";
			byte_to_string(str, reg51);
			byte_to_string(str+3, reg52);
			print(str);
			*/


			/*
			if(CABLE_DET && DE_REGEN_FILTER_LOCKED && VERT_FILTER_LOCKED)
			{
				unsigned int width_high = (value & 0b000011111);	
				i2c_read_reg(hdmi_rx_hdmi_address, 0x08, &value);
				unsigned int LINE_WIDTH = (width_high << 5) | value;

				i2c_read_reg(hdmi_rx_hdmi_address, 0x09, &value);
				unsigned int height_high = (value & 0b00011111);
				i2c_read_reg(hdmi_rx_hdmi_address, 0x0A, &value);
				unsigned int FIELD0_HEIGHT = (height_high << 5) | value;

				uint8_t width_str[5] = "    ";
				uint8_t height_str[5] = "    ";
				int_to_string(width_str, LINE_WIDTH);
				int_to_string(height_str, FIELD0_HEIGHT);
				print("Locked on to input video: ");
				print(width_str); print("x"); print(height_str); print("\r\n");
			}
			*/
		}
	}
}
