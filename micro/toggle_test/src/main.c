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

// Main map writeable registers
const int number_of_tx_registers = 179;
const uint8_t tx_register_table[179][3] = {
// To power down the part, set the power down bit in register 0x41.
// To power up the part, HDP must be high.
	// Reg		HDMI		SD			Default?	Description
{	0xD6	,	0xc0	,	0xc0	},	//	default	HPD Control, Fixed, TMDS CLK Soft Turn On, Fixed, Audio and Video Input Gating
{	0x41	,	0x10	,	0x10	}, // 0x10 = power up

{	0x01	,	0	,	0	},	//	default	20 bit N used with CTS to regenerate the audio clock in the receiver.
{	0x02	,	0	,	0	},	//	default	20 bit N used with CTS to regenerate the audio clock in the receiver.
{	0x03	,	0	,	0	},	//	default	20 bit N used with CTS to regenerate the audio clock in the receiver.
{	0x07	,	0	,	0	},	//	default	Cycle Time Stamp (CTS) Manually Entered This 20 bit value is used in the receiver with the N value to regenerate an audio clock. For remaining bits see 0x08 and 0x09.
{	0x08	,	0	,	0	},	//	default	Cycle Time Stamp (CTS) Manually Entered This 20 bit value is used in the receiver with the N value to regenerate an audio clock. For remaining bits see 0x08 and 0x09.
{	0x09	,	0	,	0	},	//	default	Cycle Time Stamp (CTS) Manually Entered This 20 bit value is used in the receiver with the N value to regenerate an audio clock. For remaining bits see 0x08 and 0x09.
{	0x0A	,	1	,	1	},	//	default	CTS select, Audio Select, Audio Mode, MCLK ratio
{	0x0B	,	0x0e	,	0x0e	},	//	default	SPDIF enable, Audio clock polarity, MCLK enable, Fixed
{	0x0C	,	0xbc	,	0xbc	},	//	default	Audio sampling frequency select, Channel status override, I2S3 enable, I2S2 enable, I2S1 enable, I2S0 enable, I2S format
{	0x0D	,	0x18	,	0x18	},	//	default	I2S bit width
{	0x0E	,	1	,	1	},	//	default	Subpacket 0 L source, Subpacket 0 R source
{	0x0F	,	0x13	,	0x13	},	//	default	Subpacket 1 L source, Subpacket 1 R source
{	0x10	,	0x25	,	0x25	},	//	default	Subpacket 2 L source, Subpacket 2 R source
{	0x11	,	0x37	,	0x37	},	//	default	Subpacket 3 L source, Subpacket 3 R source
{	0x12	,	0	,	0	},	//	default	Audio sample word (CS bit 1), Consumer Use (CS bit 0), Copyright Bit (CS bit 2), Additional Audio Info (CS bits 5-3), Audio Clock Accuracy (CS bits 29-28)
{	0x13	,	0	,	0	},	//	default	Category Code (CS bits 15-8)
{	0x14	,	0	,	0	},	//	default	Source Number (CS bits 19-16), Word Length (CS bits 35-32)
{	0x15	,	0	,	0x03	},	//	custom	I2S Sampling Frequency (CS bits 27-24), Input Video Format
{	0x16	,	0b00110100	,	0b00110100	},	//	custom	Output Format, Reserved, Color Depth, Input Style, DDR Input Edge, Output Colorspace for Black Image
{	0x17	,	0b00000110	,	0b01100100	},	//	custom	Fixed, Vsync Polarity, Hsync Polarity, Reserved, Interpolation Style, Aspect Ratio, DE Generator Enable
{	0x18	,	0x46	,	0xe6	},	//	custom	CSC Enable, CSC Scaling Factor, A1 (CSC)
{	0x19	,	0x69	,	0x69	},	//	custom	A1 (CSC)
{	0x1A	,	0x04	,	0x04	},	//	custom	Coefficient Update, A2 (CSC)
{	0x1B	,	0xac	,	0xac	},	//	custom	A2 (CSC)
{	0x1C	,	0x00	,	0x00	},	//	custom	A3 (CSC)
{	0x1D	,	0x00	,	0x00	},	//	custom	A3 (CSC)
{	0x1E	,	0x1c	,	0x1c	},	//	custom	A4 (CSC)
{	0x1F	,	0x81	,	0x81	},	//	custom	A4 (CSC)
{	0x20	,	0x1c	,	0x1c	},	//	custom	B1 (CSC)
{	0x21	,	0xbc	,	0xbc	},	//	custom	B1 (CSC)
{	0x22	,	0x04	,	0x04	},	//	custom	B2 (CSC)
{	0x23	,	0xad	,	0xad	},	//	custom	B2 (CSC)
{	0x24	,	0x1e	,	0x1e	},	//	custom	B3 (CSC)
{	0x25	,	0x63	,	0x63	},	//	custom	B3 (CSC)
{	0x26	,	0x02	,	0x02	},	//	custom	B4 (CSC)
{	0x27	,	0x20	,	0x20	},	//	custom	B4 (CSC)
{	0x28	,	0x1f	,	0x1f	},	//	custom	C1 (CSC)
{	0x29	,	0xfe	,	0xfe	},	//	custom	C1 (CSC)
{	0x2A	,	0x04	,	0x04	},	//	custom	C2 (CSC)
{	0x2B	,	0xad	,	0xad	},	//	custom	C2 (CSC)
{	0x2C	,	0x08	,	0x08	},	//	custom	C3 (CSC)
{	0x2D	,	0x1a	,	0x1a	},	//	custom	C3 (CSC)
{	0x2E	,	0x1b	,	0x1b	},	//	custom	C4 (CSC)
{	0x2F	,	0xa9	,	0xa9	},	//	custom	C4 (CSC)
{	0x30	,	0	,	0	},	//	default	Hsync Placement (Embedded Sync Decoder)
{	0x31	,	0	,	0	},	//	default	Hsync Placement, Hsync Duration
{	0x32	,	0	,	0	},	//	default	Vsync Placement
{	0x33	,	0	,	0	},	//	default	Vsync Placement, Vsync Duration
{	0x34	,	0	,	0	},	//	default	Vsync Duration
{	0x35	,	0	,	0	},	//	default	Hsync Delay
{	0x36	,	0	,	0	},	//	default	Hsync Delay, Vsync Delay
{	0x37	,	0	,	0	},	//	default	Interlace Offset, Active Width
{	0x38	,	0	,	0	},	//	default	Active Width
{	0x39	,	0	,	0	},	//	default	Active Height
{	0x3A	,	0	,	0	},	//	default	Active Height
{	0x3B	,	0x80	,	0x80	},	//	default	Reserved, PR Mode, PR PLL Manual, PR Value Manual, Reserved
{	0x3C	,	0	,	0	},	//	default	VIC Manual
{	0x40	,	0	,	0	},	//	default	GC Packet Enable, SPD Packet Enabled, MPEG Packet Enabled, ACP Packet Enable, ISRC Packet Enable, GM Packet Enable, Space Packet 2 Enable, Spare Packet 1 Enable
{	0x43	,	0x7e	,	0x7e	},	//	default	EDID Memory I2C Address
{	0x44	,	0x79	,	0x79	},	//	default	Reserved, N CTS Packet Enable, Audio Sample Packet Enable, AVI InfoFrame Enable, Audio InfoFrame Enable, Fixed, Packet Read Mode
{	0x45	,	0x70	,	0x70	},	//	default	Packet Memory I2C Address
{	0x46	,	0	,	0	},	//	default	Fixed
{	0x47	,	0	,	0	},	//	default	Fixed, PaPb Sync, Audio Sample 3 Valid, Audio Sample 2 Valid, Audio Sample 1 Valid, Audio Sample 0 Valid
{	0x48	,	0	,	0	},	//	default	Reserved, Video Input Bus Reverse, Fixed, Video Input Justification
{	0x49	,	0xa8	,	0xa8	},	//	default	Reserved
{	0x4A	,	0x80	,	0x80	},	//	default	Auto Checksum Enable, AVI Packet Update, Audio InfoFrame Packet Update, GC Packet Update
{	0x4B	,	0	,	0	},	//	default	Clear AV Mute, Set AV Mute
{	0x4C	,	0	,	0	},	//	default	Fixed
{	0x4D	,	0	,	0	},	//	default	GC Byte 2
{	0x4E	,	0	,	0	},	//	default	GC Byte 3
{	0x4F	,	0	,	0	},	//	default	GC Byte 4
{	0x50	,	0	,	0	},	//	default	GC Byte 5
{	0x51	,	0	,	0	},	//	default	GC Byte 6
{	0x52	,	0x02	,	0x02	},	//	default	AVI InfoFrame Version
{	0x53	,	0x0d	,	0x0d	},	//	default	AVI InfoFrame Length
{	0x54	,	0	,	0	},	//	default	AVI InfoFrame Checksum
{	0x55	,	0	,	0	},	//	default	AVI Byte 1 bit 7, Y1Y0, Active Format Information Status, Bar Information, Scan Information
{	0x56	,	0	,	0	},	//	default	Colorimetry, Picture Aspect Radio, Active Format Aspect Ratio
{	0x57	,	0	,	0	},	//	default	ITC, EC[2:0], Q[1:0], Non-Uniform Picture Scaling
{	0x58	,	0	,	0	},	//	default	Byte 4 Bit 7 (AVI InfoFrame)
{	0x59	,	0	,	0	},	//	default	Byte 5 bit [7:4] (AVI InfoFrame)
{	0x5A	,	0	,	0	},	//	default	Active Line Start LSB
{	0x5B	,	0	,	0	},	//	default	Active Line Start MSB
{	0x5C	,	0	,	0	},	//	default	Active Line End LSB
{	0x5D	,	0	,	0	},	//	default	Active Line End MSB
{	0x5E	,	0	,	0	},	//	default	Active Pixel Start LSB
{	0x5F	,	0	,	0	},	//	default	Active Pixel Start MSB
{	0x60	,	0	,	0	},	//	default	Active Pixel End LSB
{	0x61	,	0	,	0	},	//	default	Active Pixel End MSB
{	0x62	,	0	,	0	},	//	default	Byte 14 (AVI InfoFrame)
{	0x63	,	0	,	0	},	//	default	Byte 15 (AVI InfoFrame)
{	0x64	,	0	,	0	},	//	default	Byte 16 (AVI InfoFrame)
{	0x65	,	0	,	0	},	//	default	Byte 17 (AVI InfoFrame)
{	0x66	,	0	,	0	},	//	default	Byte 18 (AVI InfoFrame)
{	0x67	,	0	,	0	},	//	default	Byte 19 (AVI InfoFrame)
{	0x68	,	0	,	0	},	//	default	Byte 20 (AVI InfoFrame)
{	0x69	,	0	,	0	},	//	default	Byte 21 (AVI InfoFrame)
{	0x6A	,	0	,	0	},	//	default	Byte 22 (AVI InfoFrame)
{	0x6B	,	0	,	0	},	//	default	Byte 23 (AVI InfoFrame)
{	0x6C	,	0	,	0	},	//	default	Byte 24 (AVI InfoFrame)
{	0x6D	,	0	,	0	},	//	default	Byte 25 (AVI InfoFrame)
{	0x6E	,	0	,	0	},	//	default	Byte 26 (AVI InfoFrame)
{	0x6F	,	0	,	0	},	//	default	Byte 27 (AVI InfoFrame)
{	0x70	,	0x01	,	0x01	},	//	default	Audio InfoFrame Version
{	0x71	,	0x0a	,	0x0a	},	//	default	Audio InfoFrame Length
{	0x72	,	0	,	0	},	//	default	Audio InfoFrame Checksum
{	0x73	,	0	,	0	},	//	default	Coding Type, Byte 1 bit 3, CC
{	0x74	,	0	,	0	},	//	default	Byte 2 bit [7:5], Sampling Frequency, Sample Size
{	0x75	,	0	,	0	},	//	default	Byte 3
{	0x76	,	0	,	0	},	//	default	Speaker Mapping
{	0x77	,	0	,	0	},	//	default	DM_INH, Level Shift, Byte 5 bit [2], LFEPBL[1:0]
{	0x78	,	0	,	0	},	//	default	Byte 6 (Audio InfoFrame)
{	0x79	,	0	,	0	},	//	default	Byte 7 (Audio InfoFrame)
{	0x7A	,	0	,	0	},	//	default	Byte 8 (Audio InfoFrame)
{	0x7B	,	0	,	0	},	//	default	Byte 9 (Audio InfoFrame)
{	0x7C	,	0	,	0	},	//	default	Byte 10 (Audio InfoFrame)
{	0x92	,	0	,	0	},	//	default	Wake Up Opcode Interrupt 1-8 Enable
{	0x93	,	0	,	0	},	//	default	Wake Up Opcode Interrupt 1-8 detected
{	0x94	,	0xc0	,	0xc0	},	//	default	HPD Interrupt Enable, Monitor Sense Interrupt Enable, Vsync Interrupt Enable, Audio FIFO Full Interrupt Enable, Fixed, EDID Ready Interrupt Enable, HDCP Authenticated Interrupt Enable, Fixed
{	0x95	,	0	,	0	},	//	default	DDC Controller Error Interrupt Enable, BKSV Flag Interrupt Enable, CEC Tx Ready Interrupt Enable, CEC Tx Arbitration Lost Interrupt Enable, CEC Tx Retry Timeout Interrupt Enable, CEC Rx Ready 3 Interrupt Enable, CEC Rx Ready 2 Interrupt Enable, CEC Rx Ready 1 Interrupt Enable
{	0x96	,	0	,	0	},	//	default	HPD Interrupt, Monitor Sense Interrupt, Vsync Interrupt, Audio FIFO Full Interrupt, Fixed, EDID Ready Interrupt, HDCP Authenticated, Fixed
{	0x97	,	0	,	0	},	//	default	DDC Controller Error Interrupt, BKSV Flag Interrupt, Tx Ready Interrupt, Tx Arbitration Lost Interrupt, Tx Retry Timeout Interrupt, Rx Ready 3 Interrupt, Rx Ready 2 Interrupt, Rx Ready 1 Interrupt
{	0x98	,	0x03	,	0x03	},	//	custom	Fixed
{	0x99	,	0	,	0	},	//	default	Fixed
{	0x9A	,	0xe0	,	0xe0	},	//	custom	Fixed
{	0x9B	,	0x18	,	0x18	},	//	default	Fixed
{	0x9C	,	0x30	,	0x30	},	//	custom	Fixed
{	0x9D	,	0x61	,	0x61	},	//	custom	Fixed, Input Pixel Clock Divide, Fixed
{	0x9F	,	0	,	0	},	//	default	Fixed
{	0xA1	,	0x00	,	0	},	//	default	Fixed, Monitor Sense Power Down, Channel 0 PD, Channel 1 PD, Channel 2 PD, Clock Driver PD
{	0xA2	,	0xa4	,	0xa4	},	//	custom	Fixed
{	0xA3	,	0xa4	,	0xa4	},	//	custom	Fixed
{	0xA4	,	0x08	,	0x08	},	//	default	Fixed
{	0xA5	,	0x04	,	0x04	},	//	default	Fixed
{	0xA6	,	0	,	0	},	//	default	Fixed
{	0xA7	,	0	,	0	},	//	default	Fixed
{	0xA8	,	0	,	0	},	//	default	Fixed
{	0xA9	,	0	,	0	},	//	default	Fixed
{	0xAA	,	0	,	0	},	//	default	Fixed
{	0xAB	,	0x40	,	0x40	},	//	default	Fixed
{	0xAF	,	0x04	,	0x04	},	//	custom	HDCP Enable, Fixed, Frame Encryption, Fixed, HDMI/DVI Mode Select, Fixed
{	0xB9	,	0	,	0	},	//	default	Fixed
{	0xBA	,	0x08	,	0x08	},	//	default	Clock Delay, Internal/External HDCP EEPROM, Fixed, Display AKSV, R Two Point Check
{	0xBB	,	0	,	0	},	//	default	Fixed
{	0xC4	,	0	,	0	},	//	default	EDID Segment
{	0xC5	,	0	,	0	},	//	default	Fixed
{	0xC7	,	0	,	0	},	//	default	Fixed, BKSV Count
{	0xC9	,	0x03	,	0x03	},	//	default	EDID Reread, EDID Tries
{	0xCD	,	0	,	0	},	//	default	Fixed
{	0xCE	,	1	,	1	},	//	default	Fixed
{	0xCF	,	4	,	4	},	//	default	Fixed
{	0xD0	,	0x30	,	0x30	},	//	default	Enable DDR Negative Edge CLK Delay, DDR Negative Edge CLK Delay, Sync Pulse Select, Timing Generation Sequence, Fixed
{	0xD1	,	0xff	,	0xff	},	//	default	Fixed
{	0xD2	,	0x80	,	0x80	},	//	default	Fixed
{	0xD3	,	0x80	,	0x80	},	//	default	Fixed
{	0xD4	,	0x80	,	0x80	},	//	default	Fixed
{	0xD5	,	0	,	0	},	//	default	Fixed, High Refresh Rate Video, YCbCr Code Shift, Black Image
{	0xD7	,	0	,	0	},	//	default	Hsync Placement
{	0xD8	,	0	,	0	},	//	default	Hsync Placement, Hsync Duration
{	0xD9	,	0	,	0	},	//	default	Hsync Duration, Vsync Placement
{	0xDA	,	0	,	0	},	//	default	Vsync Placement, Vsync Duration
{	0xDB	,	0	,	0	},	//	default	Vsync Duration
{	0xDC	,	0	,	0	},	//	default	Offset
{	0xDD	,	0	,	0	},	//	default	Fixed
{	0xDE	,	0x10	,	0x10	},	//	default	Fixed, TMDS Clock Inversion, Fixed
{	0xDF	,	0	,	0	},	//	default	Fixed
{	0xE0	,	0xd0	,	0xd0	},	//	default	Fixed
{	0xE1	,	0x78	,	0x78	},	//	default	CEC Map I2C Address
{	0xE2	,	0	,	0	},	//	default	Fixed, CEC Power Down
{	0xE3	,	0	,	0	},	//	default	Fixed
{	0xE4	,	0x60	,	0x60	},	//	default	Fixed
{	0xF9	,	0	,	0	},	//	custom	Fixed
{	0xFA	,	0	,	0	},	//	default	Hsync Placement MSB, Fixed
{	0xFB	,	0	,	0	},	//	default	Hsync Delay MSB, Vsync Delay MSB, Width MSB, Height MSB, Low Refresh Rate (VIC Detection)
{	0xFC	,	0	,	0	},	//	default	R Checking Frequency, R Checking Position Delay, BCAPS Read Delay
{	0xFD	,	0	,	0	},	//	default	An Write Delay, AKSV Write Delay
{	0xFE	,	0	,	0	},	//	default	HDCP Start Delay
};	//	custom	Power Down, Fixed, Reserved, Fixed, Sync Adjustment Enable, Fixed




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
	int res;

/*
	for(int i=0;i<number_of_tx_registers;++i)
	{
		i2c_write_reg(hdmi_tx_address, tx_register_table[i][0], tx_register_table[i][1]);
	}

	for(int i=0;i<number_of_tx_registers;++i)
	{
		value = 0xFF;
		i2c_read_reg(hdmi_tx_address, tx_register_table[i][0], &value);
		if(value != tx_register_table[i][1])
		{
			uint8_t str[38] = "Disagree! Reg XX, wanted XX, got XX\r\n";
			byte_to_string(str+14, tx_register_table[i][0]);
			byte_to_string(str+25, tx_register_table[i][1]);
			byte_to_string(str+33, value);
			print(str);
		}
	}
*/

	res = i2c_write_reg(hdmi_tx_address, 0xD6, 0xC0); if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0x41, 0x10); if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0x98, 0x03);if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0x9A, 0xE0);if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0x9C, 0x30);if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0x9D, 0x61);if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0xA2, 0xA4);if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0xA3, 0xA4);if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0xE0, 0xD0);if(res != SLAVE_OK) print("Error\r\n");
	res = i2c_write_reg(hdmi_tx_address, 0xF9, 0x00);if(res != SLAVE_OK) print("Error\r\n");

	//i2c_write_reg(hdmi_tx_address, 0x15, 0x00);
	//i2c_write_reg(hdmi_tx_address, 0x16, 0b00000000);
	//i2c_write_reg(hdmi_tx_address, 0x17, 0x02);
	//i2c_write_reg(hdmi_tx_address, 0x18, 0x46);

	//i2c_write_reg(hdmi_tx_address, 0xAF, 0x06); // 4 = DVI, 6 = HDMI

	//41[1] enable HS VS generation
	// FA, D8-DD HS VS params
	// 17 sets polarity
	i2c_write_reg(hdmi_tx_address, 0xD7, 0x1B);
	i2c_write_reg(hdmi_tx_address, 0xD8, 0x82);
	i2c_write_reg(hdmi_tx_address, 0xD9, 0x80);
	i2c_write_reg(hdmi_tx_address, 0xDA, 0x14);
	i2c_write_reg(hdmi_tx_address, 0xDB, 0x05);

	i2c_write_reg(hdmi_tx_address, 0x41, 0x12);

/*
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

//	if(video_in == IN_HD)
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
	}
//	else
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
*/
	
	print("  Finished.\r\n");
}

volatile bool handle_event = false;

void SysTick_Handler(void)
{
	handle_event = true;
}

int main_lanemate (void)
{
	system_init();
	configure_usart();

	print("\r\n\n\nSoftware started\r\n");
	delay_init();


	//print("Waiting for FPGA to boot...\r\n");
	delay_cycles_ms(1000);


	configure_i2c_master();
	configure_hdmi_rx();
	//configure_sd_rx();
	configure_hdmi_tx();


	config_test_pin();
	port_pin_toggle_output_level(TEST_PIN);



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

			uint8_t vic, auxvic, victx, pll;
			// 3D?? 9E??
			int ok = i2c_read_reg(hdmi_tx_address, 0x3E, &vic);
			int ok2 = i2c_read_reg(hdmi_tx_address, 0x3F, &auxvic);
			int ok3 = i2c_read_reg(hdmi_tx_address, 0x3D, &victx);
			int ok4 = i2c_read_reg(hdmi_tx_address, 0x9E, &pll);
			uint8_t str[44] = "detected VIC: 3E=XX, 3F=XX, 3D=XX, pll=XX\r\n";
			byte_to_string(str+17, vic >> 2);
			byte_to_string(str+24, auxvic);
			byte_to_string(str+31, victx);
			byte_to_string(str+39, pll & 0x10);
			str[43] = '\0';
			if(ok == SLAVE_OK && ok2 == SLAVE_OK && ok3 == SLAVE_OK)
				print(str);
			else
				print("No response\r\n");

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



int mainRTCTest()
{
	system_init();
	configure_usart();
	configure_i2c_master();
	delay_init();

	delay_cycles_ms(1000);
	print("Main application start\r\n");

	const uint16_t DS1307_address = 0b1101000;

	i2c_write_reg(DS1307_address, 0x07, 0b00010000); // set SQWE
	
	i2c_write_reg(DS1307_address, 0x06, 0b00000000);
	i2c_write_reg(DS1307_address, 0x05, 0b00000000);
	i2c_write_reg(DS1307_address, 0x04, 0b00000000);
	i2c_write_reg(DS1307_address, 0x03, 0b00000000);
	i2c_write_reg(DS1307_address, 0x02, 0b00000000);
	i2c_write_reg(DS1307_address, 0x01, 0b00000000);
	i2c_write_reg(DS1307_address, 0x00, 0b00000000); // after this write, clock should begin

	while(1)
	{
		uint8_t b;
		int ok = i2c_read_reg(DS1307_address, 0x00, &b);
		if(ok == SLAVE_OK)
		{
			uint8_t buf[3];
			byte_to_string(buf, b);
			buf[2] = '\0';
			print(buf);
		}else if(ok == SLAVE_NAK)
			print("NAK");
		else if(ok == SLAVE_NO_ACK)
			print("NO ACK");
		print("\r\n");

		delay_cycles_ms(1000);
	}
	
}

int main_slavetest()
{
	system_init();
	configure_usart();
	configure_i2c_master();
	delay_init();

	delay_cycles_ms(1000);
	print("Main application start\r\n");

	const uint16_t lanemate_address = 0b0101100;
	const uint16_t regs[8] = {0,1,2,3,4,5,6,7};
	for(int i=0;i<8;++i)
	{
		uint8_t b;
		int ok = i2c_read_reg(lanemate_address, regs[i], &b);
		if(ok == SLAVE_OK)
		{
			uint8_t buf[3];
			byte_to_string(buf, b);
			buf[2] = '\0';
			print(buf);
		}else if(ok == SLAVE_NAK)
		print("NAK");
		else if(ok == SLAVE_NO_ACK)
		print("NO ACK");
		print("\r\n");

		delay_cycles_ms(100);
	}
}

int main()
{
	//main_lanemate();
	//mainRTCTest();
	main_slavetest();
	while(1);
}