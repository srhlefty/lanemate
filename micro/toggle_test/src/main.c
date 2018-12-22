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
		return SLAVE_NO_ACK;

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

			print("\r\n\n\nSoftware started\r\n");

			delay_init();
			delay_cycles_ms(5); // ADV7611 says wait 5ms before attempting I2C communication

			print("Dumping IO slave\r\n");
			register_dump(hdmi_rx_address);

			print("\r\nWriting slave registers\r\n");

			// The slave addresses occupy [7:1] so I must shift them to get the correct value in there
			i2c_write_reg(hdmi_rx_address, 0xF4, hdmi_rx_cec_address << 1);
			i2c_write_reg(hdmi_rx_address, 0xF5, hdmi_rx_infoframe_address << 1);
			i2c_write_reg(hdmi_rx_address, 0xF8, hdmi_rx_dpll_address << 1);
			i2c_write_reg(hdmi_rx_address, 0xF9, hdmi_rx_repeater_address << 1);
			i2c_write_reg(hdmi_rx_address, 0xFA, hdmi_rx_edid_address << 1);
			i2c_write_reg(hdmi_rx_address, 0xFB, hdmi_rx_hdmi_address << 1);
			i2c_write_reg(hdmi_rx_address, 0xFD, hdmi_rx_cp_address << 1);

			print("\r\nNew IO slave dump:\r\n");

			register_dump(hdmi_rx_address);

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

			print("\r\nSetting up free run mode\r\n");

			i2c_write_reg(hdmi_rx_address, 0x0C, 0x00); // set POWER_DOWN to 0 (on)
			i2c_write_reg(hdmi_rx_address, 0x15, 0x11); // un-tristate the pixel data, pixel clock, and sync pins
			i2c_write_reg(hdmi_rx_address, 0x03, 0x40); // OP_FORMAT_SEL, 24-bit RGB with SDR clock
			i2c_write_reg(hdmi_rx_address, 0x01, 0x05); // PRIM_MODE = component, V_FREQ = 60Hz
			i2c_write_reg(hdmi_rx_address, 0x00, 0x13); // VID_STD = 1280x720
			i2c_write_reg(hdmi_rx_address, 0x02, 0xF2); // automatic input colorspace, RGB output space
			i2c_write_reg(hdmi_rx_cp_address, 0xC9, 0x01); // DIS_AUTO_PARAM_BUF (use above settings for free run)
			i2c_write_reg(hdmi_rx_cp_address, 0xC0, 0xFF); // free run color, channel A
			i2c_write_reg(hdmi_rx_cp_address, 0xC1, 0xFF); // free run color, channel B
			i2c_write_reg(hdmi_rx_cp_address, 0xC2, 0xFF); // free run color, channel C
			i2c_write_reg(hdmi_rx_cp_address, 0xBF, 0x07); // turn on free run and specify manual color choice

			// Default polarity: HS and VS are negative; DE is positive.
			// If I want them all to be positive polarity this command will do it
			//i2c_write_reg(hdmi_rx_address, 0x06, 0x86); // make HS/VS positive

			print("Output video enabled!\r\n");




			handle_event = false;
		}
	}
}
