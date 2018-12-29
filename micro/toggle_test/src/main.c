#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #
#include <string.h>

#define TEST_PIN PIN_PA24

struct usart_module usart_instance;
struct i2c_master_module i2c_master_instance;

void configure_usart(void);
void configure_i2c_master(void);

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

void configure_i2c_master(void)
{
	struct i2c_master_config config_i2c_master;
	i2c_master_get_config_defaults(&config_i2c_master);

	config_i2c_master.buffer_timeout = 10000;
	config_i2c_master.run_in_standby = false;
	// The board connects the I2C bus to pins 6 (PA14) and 7 (PA15) on the SAM10D.
	// Those pins can mux between SERCOM0 and SERCOM2, but I'm already using SERCOM0
	// on pins 1-4 for the UART, thus I2C is being run on SERCOM2.
	// Pin 6 becomes SERCOM2, PAD0 (SDA)
	// Pin 7 becomes SERCOM2, PAD1 (SCL)
	config_i2c_master.pinmux_pad0 = PINMUX_PA14D_SERCOM2_PAD0;
	config_i2c_master.pinmux_pad1 = PINMUX_PA15D_SERCOM2_PAD1;

	i2c_master_init(&i2c_master_instance, SERCOM2, &config_i2c_master);

	i2c_master_enable(&i2c_master_instance);
}
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
static void config_test_pin(void)
{
	struct port_config pin_conf;
	port_get_config_defaults(&pin_conf);

	pin_conf.direction  = PORT_PIN_DIR_OUTPUT;
	port_pin_set_config(TEST_PIN, &pin_conf);
	port_pin_set_output_level(TEST_PIN, LOW);
}







const int SLAVE_OK = 0;
const int SLAVE_NO_ACK = -1;
const int SLAVE_NAK = -2;

const uint16_t hdmi_rx_address = 0x98 >> 1; // this is the 7-bit address. In the docs it's 0x98, which is the 8-bit address. Atmel API wants the 7-bit address.
const uint16_t hdmi_rx_cp_address = 0x08; // 7-bit addresses must be greater than 0x07 and less than 0x78
const uint16_t hdmi_rx_hdmi_address = 0x0A;
const uint16_t hdmi_rx_repeater_address = 0x0C;
const uint16_t hdmi_rx_edid_address = 0x0E;
const uint16_t hdmi_rx_infoframe_address = 0x10;
const uint16_t hdmi_rx_cec_address = 0x12;
const uint16_t hdmi_rx_dpll_address = 0x14;

const uint16_t hdmi_tx_address = 0x72 >> 1;
const uint16_t sd_rx_address = 0x40 >> 1;

const uint8_t rx_edid[256] = 
{
	0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0x04,0x72,0x12,0x03,0x46,0x99,0x20,0x71,
	0x0C,0x1B,0x01,0x03,0x80,0x35,0x1E,0x78,0xCA,0x92,0x65,0xA6,0x55,0x55,0x9F,0x28,
	0x0D,0x50,0x54,0xBF,0xEF,0x80,0x71,0x4F,0x81,0x40,0x81,0x80,0x81,0xC0,0x81,0x00,
	0x95,0x00,0xB3,0x00,0xD1,0xC0,0x02,0x3A,0x80,0x18,0x71,0x38,0x2D,0x40,0x58,0x2C,
	0x45,0x00,0x13,0x2B,0x21,0x00,0x00,0x1E,0x00,0x00,0x00,0xFD,0x00,0x37,0x4C,0x1E,
	0x50,0x11,0x00,0x0A,0x20,0x20,0x20,0x20,0x20,0x20,0x00,0x00,0x00,0xFC,0x00,0x53,
	0x32,0x34,0x31,0x48,0x4C,0x0A,0x20,0x20,0x20,0x20,0x20,0x20,0x00,0x00,0x00,0xFF,
	0x00,0x4C,0x57,0x56,0x41,0x41,0x30,0x30,0x31,0x38,0x35,0x35,0x43,0x0A,0x01,0x89,
	0x02,0x03,0x22,0xF1,0x4F,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x90,0x11,0x12,0x13,
	0x14,0x15,0x16,0x1F,0x23,0x09,0x07,0x07,0x83,0x01,0x00,0x00,0x65,0x03,0x0C,0x00,
	0x10,0x00,0x02,0x3A,0x80,0x18,0x71,0x38,0x2D,0x40,0x58,0x2C,0x45,0x00,0x13,0x2B,
	0x21,0x00,0x00,0x1F,0x01,0x1D,0x80,0x18,0x71,0x1C,0x16,0x20,0x58,0x2C,0x25,0x00,
	0x13,0x2B,0x21,0x00,0x00,0x9F,0x01,0x1D,0x00,0x72,0x51,0xD0,0x1E,0x20,0x6E,0x28,
	0x55,0x00,0x13,0x2B,0x21,0x00,0x00,0x1E,0x8C,0x0A,0xD0,0x8A,0x20,0xE0,0x2D,0x10,
	0x10,0x3E,0x96,0x00,0x13,0x2B,0x21,0x00,0x00,0x18,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xE7
};


int i2c_read_reg(uint16_t slave_addr, uint8_t slave_reg, uint8_t *value)
{
	uint8_t buf[1] = {0x00};

	struct i2c_master_packet packet = {
		.address     = slave_addr,
		.data_length = 1,
		.data        = buf,
		.ten_bit_address = false,
		.high_speed      = false,
		.hs_master_code  = 0x0,
	};

	// stage 1: tell slave what register to read
	buf[0] = slave_reg;
	if(i2c_master_write_packet_wait_no_stop(&i2c_master_instance, &packet) != STATUS_OK)
	{
		i2c_master_send_stop(&i2c_master_instance);
		return SLAVE_NO_ACK;
	}

	// stage 2: get reply from slave
	buf[0] = 0x00;
	if(i2c_master_read_packet_wait(&i2c_master_instance, &packet) != STATUS_OK)
		return SLAVE_NAK;

	if(value)
		*value = buf[0];

	return SLAVE_OK;
}

int i2c_write_reg(uint16_t slave_addr, uint8_t slave_reg, uint8_t value)
{
	uint8_t buf[2] = {0x00, 0x00};

	struct i2c_master_packet packet = {
		.address     = slave_addr,
		.data_length = 2,
		.data        = buf,
		.ten_bit_address = false,
		.high_speed      = false,
		.hs_master_code  = 0x0,
	};

	buf[0] = slave_reg;
	buf[1] = value;

	if(i2c_master_write_packet_wait(&i2c_master_instance, &packet) != STATUS_OK)
		return SLAVE_NO_ACK;

	return SLAVE_OK;
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
			usart_write_buffer_wait(&usart_instance, string, sizeof(string));
			break;
		}else
		{
			buf[0] = 'N'; buf[1] = 'A'; buf[2] = 'K';
		}

		usart_write_buffer_wait(&usart_instance, buf, 4);
		if((i+1)%16 == 0)
		usart_write_buffer_wait(&usart_instance, "\r\n", 2);
	}

}



void print(const uint8_t *str)
{
	usart_write_buffer_wait(&usart_instance, str, strlen(str));
}


void configure_hdmi_rx()
{
	print("Setting up HDMI RX\r\n");

	i2c_write_reg(hdmi_rx_address, 0xFF, 0b10000000);
	delay_cycles_ms(5);

	//print("Dumping IO slave\r\n");
	//register_dump(hdmi_rx_address);

	// The slave addresses occupy [7:1] so I must shift them to get the correct value in there
	i2c_write_reg(hdmi_rx_address, 0xF4, hdmi_rx_cec_address << 1);
	i2c_write_reg(hdmi_rx_address, 0xF5, hdmi_rx_infoframe_address << 1);
	i2c_write_reg(hdmi_rx_address, 0xF8, hdmi_rx_dpll_address << 1);
	i2c_write_reg(hdmi_rx_address, 0xF9, hdmi_rx_repeater_address << 1);
	i2c_write_reg(hdmi_rx_address, 0xFA, hdmi_rx_edid_address << 1);
	i2c_write_reg(hdmi_rx_address, 0xFB, hdmi_rx_hdmi_address << 1);
	i2c_write_reg(hdmi_rx_address, 0xFD, hdmi_rx_cp_address << 1);

	/*
	print("Dumping CP slave\r\n");
	register_dump(hdmi_rx_cp_address);
	print("Dumping HDMI slave\r\n");
	register_dump(hdmi_rx_hdmi_address);
	print("Dumping Repeater slave\r\n");
	register_dump(hdmi_rx_repeater_address);
	print("Dumping EDID slave\r\n");
	register_dump(hdmi_rx_edid_address);
	print("Dumping InfoFrame slave\r\n");
	register_dump(hdmi_rx_infoframe_address);
	print("Dumping CEC slave\r\n");
	register_dump(hdmi_rx_cec_address);
	print("Dumping DPLL slave\r\n");
	register_dump(hdmi_rx_dpll_address);
	*/

	i2c_write_reg(hdmi_rx_address, 0x0C, 0x00); // set POWER_DOWN to 0 (on)
	i2c_write_reg(hdmi_rx_address, 0x15, 0x11); // un-tristate the pixel data, pixel clock, and sync pins
	i2c_write_reg(hdmi_rx_address, 0x03, 0x40); // OP_FORMAT_SEL, 24-bit RGB with SDR clock
	i2c_write_reg(hdmi_rx_address, 0x01, 0x05); // PRIM_MODE = component, V_FREQ = 60Hz
	i2c_write_reg(hdmi_rx_address, 0x00, 0x13); // VID_STD = 1280x720
	i2c_write_reg(hdmi_rx_address, 0x02, 0xF2); // automatic input colorspace, RGB output space
	i2c_write_reg(hdmi_rx_cp_address, 0xC9, 0x01); // DIS_AUTO_PARAM_BUF (use above settings for free run)
	i2c_write_reg(hdmi_rx_cp_address, 0xC0, 0xFF); // free run color, R
	i2c_write_reg(hdmi_rx_cp_address, 0xC1, 0x00); // free run color, G
	i2c_write_reg(hdmi_rx_cp_address, 0xC2, 0xFF); // free run color, B
	i2c_write_reg(hdmi_rx_cp_address, 0xBF, 0x07); // force free run and specify manual color choice
	i2c_write_reg(hdmi_rx_hdmi_address, 0x01, 0x01); // enable automatic TMDS clock termination

	// Default polarity: HS and VS are negative; DE is positive.
	// If I want them all to be positive polarity this command will do it
	//i2c_write_reg(hdmi_rx_address, 0x06, 0x86); // make HS/VS positive

	// write edid ram
	for(int i=0;i<256;++i)
	{
		i2c_write_reg(hdmi_rx_edid_address, (uint8_t)i, rx_edid[i]);
	}
	// enable edid
	i2c_write_reg(hdmi_rx_repeater_address, 0x74, 0x01);
	delay_cycles_ms(1);
	// check whether edid was actually enabled
	uint8_t value;
	i2c_read_reg(hdmi_rx_repeater_address, 0x76, &value);
	if(value & 0b00000001)
		print("  EDID successfully enabled\r\n");
	else
		print("  EDID did not enable\r\n");

	print("  Finished.\r\n");
}

void configure_hdmi_tx()
{
	print("Setting up HDMI TX\r\n");
	uint8_t value;


	// power up: set bit 6 of 0x41 to 0
	i2c_read_reg(hdmi_tx_address, 0x41, &value);
	value = value & 0b10111111;
	i2c_write_reg(hdmi_tx_address, 0x41, value);

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
	}
	i2c_write_reg(hdmi_tx_address, 0xA2, 0xA4);
	i2c_write_reg(hdmi_tx_address, 0xA3, 0xA4);
	i2c_write_reg(hdmi_tx_address, 0xE0, 0xD0);
	i2c_write_reg(hdmi_tx_address, 0xF9, 0x00);

	i2c_read_reg(hdmi_tx_address, 0x15, &value);
	value = value & 0b11110000; // 4:4:4 input
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


	print("  Finished.\r\n");
}

volatile bool handle_event = false;

void SysTick_Handler(void)
{
	handle_event = true;
}

void servicer()
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
				if(buffer[0] == 'r' && buffer[1] == 'e' && buffer[2] == 'a' && buffer[3] == 'd')
				{
					// read [slave address] [register]
					uint8_t slave = string_to_byte(buffer+5);
					uint8_t reg = string_to_byte(buffer+8);
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
					
				}else if(buffer[0] == 'w' && buffer[1] == 'r' && buffer[2] == 'i' && buffer[3] == 't' && buffer[4] == 'e')
				{

				}else if(buffer[0] == 'd' && buffer[1] == 'u' && buffer[2] == 'm' && buffer[3] == 'p')
				{
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
				}else if(buffer[0] == 'r' && buffer[1] == 's' && buffer[2] == 't')
				{
					i2c_master_reset(&i2c_master_instance);
					configure_i2c_master();
				}
				else
				{
					print("Usage:\r\n  read <slave> <register>\r\n  write <slave> <register> <value>\r\n  dump <slave> <start register> <count>\r\n(all values are in hex)\r\n");
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
int main (void)
{
	system_init();
	configure_usart();

	print("\r\n\n\nSoftware started\r\n");
	delay_init();


	print("Waiting for FPGA to boot...\r\n");
	delay_cycles_ms(7000);


	configure_i2c_master();
	configure_hdmi_rx();
	configure_hdmi_tx();


	config_test_pin();
	port_pin_toggle_output_level(TEST_PIN);




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

	uint32_t ticks_per_second = system_gclk_gen_get_hz(GCLK_GENERATOR_0);
	uint32_t ticks_between_interrupts = ticks_per_second / 1;
	SysTick_Config(ticks_between_interrupts);

	while(1)
	{
		if(handle_event)
		{
			handle_event = false;

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
