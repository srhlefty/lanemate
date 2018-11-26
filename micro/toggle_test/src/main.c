#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #

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
	config_usart.receiver_enable = false;
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


volatile bool handle_event = false;

void SysTick_Handler(void)
{
	handle_event = true;
}

static void config_test_pin(void)
{
	struct port_config pin_conf;
	port_get_config_defaults(&pin_conf);

	pin_conf.direction  = PORT_PIN_DIR_OUTPUT;
	port_pin_set_config(TEST_PIN, &pin_conf);
	port_pin_set_output_level(TEST_PIN, LOW);
}

int main (void)
{
	system_init();

	//SysTick_Config(system_gclk_gen_get_hz(GCLK_GENERATOR_0));
	
	config_test_pin();
	configure_usart();
	configure_i2c_master();

	handle_event = true;

	while(1) 
	{
		if(handle_event)
		{
			port_pin_toggle_output_level(TEST_PIN);

			uint8_t msg[] = "\r\n\n\nSoftware started\r\n";
			usart_write_buffer_wait(&usart_instance, msg, sizeof(msg));



			uint16_t hdmi_rx_address = 0x98 >> 1;
			uint16_t hdmi_tx_address = 0x72 >> 1;
			uint16_t sd_rx_address = 0x40 >> 1;
			uint8_t reg[1] = {0x00};
			uint8_t reply[1] = {0x00};

			struct i2c_master_packet packet = {
				.address     = sd_rx_address,
				.data_length = 1,
				.data        = reg,
				.ten_bit_address = false,
				.high_speed      = false,
				.hs_master_code  = 0x0,
			};

			for(unsigned int i=0;i<256;++i)
			{
				reg[0] = (uint8_t)i;
				packet.data = reg;

				if(i2c_master_write_packet_wait_no_stop(&i2c_master_instance, &packet) != STATUS_OK)
				{
					uint8_t string[] = "[Write] Error: slave did not ACK\r\n";
					usart_write_buffer_wait(&usart_instance, string, sizeof(string));
				}else
				{
					reply[0] = 0x00;
					packet.data = reply;
					uint8_t buf[4] = "    ";

					if(i2c_master_read_packet_wait(&i2c_master_instance, &packet) != STATUS_OK)
					{
						buf[0] = "N"; buf[1] = "A"; buf[2] = "K";
					}else
					{
						byte_to_string(buf, reply[0]);
					}

					usart_write_buffer_wait(&usart_instance, buf, 4);
					if((i+1)%16 == 0)
						usart_write_buffer_wait(&usart_instance, "\r\n", 2);
				}
			}

			
/*
			if(i2c_master_write_packet_wait_no_stop(&i2c_master_instance, &packet) != STATUS_OK)
			{
				uint8_t string[] = "[Write] Error: slave did not ACK\r\n";
				usart_write_buffer_wait(&usart_instance, string, sizeof(string));
			}else
			{
				uint8_t string[] = "[Write] Wrote register\r\n";
				usart_write_buffer_wait(&usart_instance, string, sizeof(string));


				packet.data = reply;

				if(i2c_master_read_packet_wait(&i2c_master_instance, &packet) != STATUS_OK)
				{
					uint8_t s[] = "[Read] Error: slave did not ACK\r\n";
					usart_write_buffer_wait(&usart_instance, s, sizeof(s));
				}else
				{
					uint8_t s[] = "[Read] Reply:\r\n";
					usart_write_buffer_wait(&usart_instance, s, sizeof(s));
					uint8_t str[2];
					byte_to_string(str, reply[0]);
					usart_write_buffer_wait(&usart_instance, str, 2);
					usart_write_buffer_wait(&usart_instance, "\r\n", 2);
				}
			}
*/
			handle_event = false;
		}
	}
}
