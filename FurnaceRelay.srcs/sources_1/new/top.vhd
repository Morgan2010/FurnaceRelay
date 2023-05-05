----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.05.2023 06:20:14
-- Design Name: 
-- Module Name: top - Behavioral
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
use work.FurnaceRelayTypes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
port(
    clk: in std_logic;
    led: out std_logic_vector(3 downto 0)
);
end top;

architecture Behavioral of top is

    signal completed: std_logic;

    component FurnaceRelayKripkeGenerator is
    port(
        clk: in std_logic;
        initialRinglets: out Initial_Ringlets_t;
        frOffRinglets: out FROff_Ringlets_t;
        frOnRinglets: out FROn_Ringlets_t;
        completed: out std_logic := '0'
    );
    end component;

begin

    fr_inst: FurnaceRelayKripkeGenerator port map(
        clk => clk,
        completed => completed
    );
    
    led <= (others => completed);

end Behavioral;
