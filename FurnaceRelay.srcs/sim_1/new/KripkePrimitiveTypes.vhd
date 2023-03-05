----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.03.2023 04:29:18
-- Design Name: 
-- Module Name: KripkePrimitiveTypes - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package KripkePrimitiveTypes is
    type stdLogicTypes_t is array(0 to 8) of std_logic;
    constant stdLogicTypes: stdLogicTypes_t := (
        0 => 'U',
        1 => 'X',
        2 => '0',
        3 => '1',
        4 => 'Z',
        5 => 'W',
        6 => 'L',
        7 => 'H',
        8 => '-'
    );
end package KripkePrimitiveTypes;
