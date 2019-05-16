/*
 * hdmi_rx.c
 *
 * Created: 2/17/2019 5:20:00 PM
 *  Author: Steven
 */ 
#include "utils.h"
#include "i2c.h"
#include "uart.h"
#include "hdmi_rx.h"

const uint16_t hdmi_rx_address = 0x98 >> 1; // this is the 7-bit address. In the docs it's 0x98, which is the 8-bit address. Atmel API wants the 7-bit address.
const uint16_t hdmi_rx_cp_address = 0x08; // 7-bit addresses must be greater than 0x07 and less than 0x78
const uint16_t hdmi_rx_hdmi_address = 0x0A;
const uint16_t hdmi_rx_repeater_address = 0x0C;
const uint16_t hdmi_rx_edid_address = 0x0E;
const uint16_t hdmi_rx_infoframe_address = 0x10;
const uint16_t hdmi_rx_cec_address = 0x12;
const uint16_t hdmi_rx_dpll_address = 0x14;

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

void hdmi_rx_force_freerun()
{
	// [0] force CP to free run
	// [1] output default color when CP free runs
	// [2] use default color specified by registers C0, C1, C2
	i2c_write_reg(hdmi_rx_cp_address, 0xBF, 0x07);
}

void hdmi_rx_autofreerun()
{
	// [0] CP free runs when cable disconnected
	// [1] output default color when CP free runs
	// [2] use default color specified by registers C0, C1, C2
	i2c_write_reg(hdmi_rx_cp_address, 0xBF, 0x06);
}

void hdmi_rx_set_freerun_to_720p60()
{
	i2c_write_reg(hdmi_rx_address, 0x00, 0x13);
}
void hdmi_rx_set_freerun_to_1080p60()
{
	i2c_write_reg(hdmi_rx_address, 0x00, 0x1E);
}


void configure_hdmi_rx(void)
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
	hdmi_rx_set_freerun_to_720p60(); // VID_STD = 1280x720
	i2c_write_reg(hdmi_rx_address, 0x02, 0xF2); // automatic input colorspace, RGB output space
	i2c_write_reg(hdmi_rx_cp_address, 0xC9, 0x01); // DIS_AUTO_PARAM_BUF (use above settings for free run)
	i2c_write_reg(hdmi_rx_cp_address, 0xC0, 0xFF); // free run color, R
	i2c_write_reg(hdmi_rx_cp_address, 0xC1, 0x00); // free run color, G
	i2c_write_reg(hdmi_rx_cp_address, 0xC2, 0xFF); // free run color, B
	hdmi_rx_autofreerun();
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
