#include <asf.h>

#define TEST_PIN PIN_PA24

struct usart_module usart_instance;

void configure_usart(void);

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






void SysTick_Handler(void)
{
	port_pin_toggle_output_level(TEST_PIN);

	uint8_t string[] = "Hello World!\r\n";
	usart_write_buffer_wait(&usart_instance, string, sizeof(string));
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

	SysTick_Config(system_gclk_gen_get_hz(GCLK_GENERATOR_0));
	
	config_test_pin();
	
	configure_usart();


	while(1) {}
}
