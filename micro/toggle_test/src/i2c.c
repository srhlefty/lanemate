/*
 * i2c.c
 *
 * Created: 2/17/2019 5:06:22 PM
 *  Author: Steven
 */ 
#include "i2c.h"

struct i2c_master_module i2c_master_instance;
const int SLAVE_OK = 0;
const int SLAVE_NO_ACK = -1;
const int SLAVE_NAK = -2;

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
