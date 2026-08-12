##
## @file        ebaz4205.xdc
## @brief       Xilinx Design Constraints for EBAZ4205
## @author      Keitetsu
## @date        2021/03/21
## @copyright   Copyright (c) 2021 Keitetsu
## @par         License
##              This software is released under the MIT License.
##

# Clock for Ethernet Transceiver
#set_property IOSTANDARD LVCMOS33 [get_ports FCLK_CLK3_0]
#set_property PACKAGE_PIN U18 [get_ports FCLK_CLK3_0]

# Ethernet Transceiver
#set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_RX_CLK_0]
#set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_TX_CLK_0]
#set_property PACKAGE_PIN U14 [get_ports ENET0_GMII_RX_CLK_0]
#set_property PACKAGE_PIN U15 [get_ports ENET0_GMII_TX_CLK_0]

# IP101GA is a 100Mbit PHY, so its GMII clocks run at 25MHz (40ns period)
#create_clock -period 40.000 -name ENET0_GMII_RX_CLK_0 [get_ports ENET0_GMII_RX_CLK_0]
#create_clock -period 40.000 -name ENET0_GMII_TX_CLK_0 [get_ports ENET0_GMII_TX_CLK_0]

#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_rxd[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_rxd[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_rxd[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_rxd[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TX_EN_0[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_txd[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_txd[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_txd[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {enet0_gmii_txd[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_RX_DV_0]
#set_property IOSTANDARD LVCMOS33 [get_ports MDIO_ETHERNET_0_0_mdc]
#set_property IOSTANDARD LVCMOS33 [get_ports MDIO_ETHERNET_0_0_mdio_io]
#set_property PACKAGE_PIN Y17 [get_ports {enet0_gmii_rxd[3]}]
#set_property PACKAGE_PIN V17 [get_ports {enet0_gmii_rxd[2]}]
#set_property PACKAGE_PIN V16 [get_ports {enet0_gmii_rxd[1]}]
#set_property PACKAGE_PIN Y16 [get_ports {enet0_gmii_rxd[0]}]
#set_property PACKAGE_PIN W19 [get_ports {ENET0_GMII_TX_EN_0[0]}]
#set_property PACKAGE_PIN Y19 [get_ports {enet0_gmii_txd[3]}]
#set_property PACKAGE_PIN V18 [get_ports {enet0_gmii_txd[2]}]
#set_property PACKAGE_PIN Y18 [get_ports {enet0_gmii_txd[1]}]
#set_property PACKAGE_PIN W18 [get_ports {enet0_gmii_txd[0]}]
#set_property PACKAGE_PIN W16 [get_ports ENET0_GMII_RX_DV_0]
#set_property PACKAGE_PIN W15 [get_ports MDIO_ETHERNET_0_0_mdc]
#set_property PACKAGE_PIN Y14 [get_ports MDIO_ETHERNET_0_0_mdio_io]

# Green LED
#set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
#set_property PACKAGE_PIN W13 [get_ports {LED[1]}]

# Red LED
#set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
#set_property PACKAGE_PIN W14 [get_ports {LED[0]}]




# Expansion board

# GPIO Pins (left column - right column)(top - bottom)
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_GPIO[0]}]
#set_property PACKAGE_PIN K18 [get_ports {EB_GPIO[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_pwnn_0}]
set_property PACKAGE_PIN G19 [get_ports {cam_pwnn_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[0]}]
set_property PACKAGE_PIN J20 [get_ports {d_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[2]}]
set_property PACKAGE_PIN K19 [get_ports {d_0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[4]}]
set_property PACKAGE_PIN L20 [get_ports {d_0[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[6]}]
set_property PACKAGE_PIN L17 [get_ports {d_0[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mclk_0}]
set_property PACKAGE_PIN M20 [get_ports {mclk_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {href_0}]
set_property PACKAGE_PIN M19 [get_ports {href_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {IIC_0_0_sda_io}]
set_property PACKAGE_PIN P18 [get_ports {IIC_0_0_sda_io}]
set_property PULLUP true [get_ports IIC_0_0_sda_io]

#set_property IOSTANDARD LVCMOS33 [get_ports {EB_GPIO[9]}]
#set_property PACKAGE_PIN J18 [get_ports {EB_GPIO[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_rst_0}]
set_property PACKAGE_PIN G20 [get_ports {cam_rst_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[1]}]
set_property PACKAGE_PIN H20 [get_ports {d_0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[3]}]
set_property PACKAGE_PIN J19 [get_ports {d_0[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[5]}]
set_property PACKAGE_PIN L19 [get_ports {d_0[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {d_0[7]}]
set_property PACKAGE_PIN L16 [get_ports {d_0[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {pclk_0}]
set_property PACKAGE_PIN M18 [get_ports {pclk_0}]
create_clock -name pclk_0 -period 40.000 [get_ports pclk_0]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_fpga_0] -group [get_clocks pclk_0]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {pclk_0}]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {pclk_0_IBUF}]
#create_clock -period 40.000 -name pclk_0 [get_ports {pclk_0}]

set_property IOSTANDARD LVCMOS33 [get_ports {vsync_0}]
set_property PACKAGE_PIN N20 [get_ports {vsync_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {IIC_0_0_scl_io}]
set_property PACKAGE_PIN M17 [get_ports {IIC_0_0_scl_io}]
set_property PULLUP true [get_ports IIC_0_0_scl_io]

# Buttons
# KEY1
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_BUTTON[0]}]
#set_property PACKAGE_PIN T19 [get_ports {EB_BUTTON[0]}]
# KEY2
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_BUTTON[1]}]
#set_property PACKAGE_PIN P19 [get_ports {EB_BUTTON[1]}]
# KEY3
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_BUTTON[2]}]
#set_property PACKAGE_PIN U20 [get_ports {EB_BUTTON[2]}]
# KEY4
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_BUTTON[3]}]
#set_property PACKAGE_PIN U19 [get_ports {EB_BUTTON[3]}]
# KEY5
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_BUTTON[4]}]
#set_property PACKAGE_PIN V20 [get_ports {EB_BUTTON[4]}]

# LEDs
# LED1
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LED[0]}]
#set_property PACKAGE_PIN H18 [get_ports {EB_LED[0]}]
# LED2
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LED[1]}]
#set_property PACKAGE_PIN K17 [get_ports {EB_LED[1]}]
# LED3
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LED[2]}]
#set_property PACKAGE_PIN E19 [get_ports {EB_LED[2]}]

#hehe

# Buzzer
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_BUZZER}]
#set_property PACKAGE_PIN D18 [get_ports {EB_BUZZER}]

# LCD
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LCD_CS}]
#set_property PACKAGE_PIN T20 [get_ports {EB_LCD_CS}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LCD_DC}]
#set_property PACKAGE_PIN R18 [get_ports {EB_LCD_DC}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LCD_SCL}]
#set_property PACKAGE_PIN R19 [get_ports {EB_LCD_SCL}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LCD_SDA}]
#set_property PACKAGE_PIN P20 [get_ports {EB_LCD_SDA}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_LCD_RES}]
#set_property PACKAGE_PIN N17 [get_ports {EB_LCD_RES}]

# HDMI
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_HDMI_DAT0}]
#set_property PACKAGE_PIN D19 [get_ports {EB_HDMI_DAT0}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_HDMI_DAT1}]
#set_property PACKAGE_PIN C20 [get_ports {EB_HDMI_DAT1}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_HDMI_DAT2}]
#set_property PACKAGE_PIN B19 [get_ports {EB_HDMI_DAT2}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_HDMI_CLK}]
#set_property PACKAGE_PIN F19 [get_ports {EB_HDMI_CLK}]

# UART
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_RX}]
#set_property PACKAGE_PIN H16 [get_ports {EB_RX}]
#set_property IOSTANDARD LVCMOS33 [get_ports {EB_TX}]
#set_property PACKAGE_PIN H17 [get_ports {EB_TX}]